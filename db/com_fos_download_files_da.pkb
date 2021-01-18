create or replace package body com_fos_download_files_da
as

-- =============================================================================
--
--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)
--
-- =============================================================================

-- globals & contants
c_plugin_name                constant varchar2(100) := 'FOS - Download File(s)';
c_cookie_name                constant varchar2(100) := 'FOS_DOWNLOAD_FILE';
c_download_request           constant varchar2(100) := 'DOWNLOAD_FILES';

g_in_error_handling_callback boolean := false;

procedure p
  ( p_str in varchar2
  )
as
begin
    sys.htp.p(p_str);
end p;

-- helper function for converting clob to blob
function clob_to_blob
  ( p_clob in clob
  )
return blob
as
    l_blob         blob;
    l_clob         clob   := empty_clob();
    l_dest_offset  number := 1;
    l_src_offset   number := 1;
    l_lang_context number := dbms_lob.default_lang_ctx;
    l_warning      number := dbms_lob.warn_inconvertible_char;
begin

    if p_clob is null or dbms_lob.getlength(p_clob) = 0
    then
        dbms_lob.createtemporary
          ( lob_loc => l_clob
          , cache   => true
          );
    else
        l_clob := p_clob;
    end if;

    dbms_lob.createtemporary
      ( lob_loc => l_blob
      , cache   => true
      );

    dbms_lob.converttoblob
      ( dest_lob      => l_blob
      , src_clob      => l_clob
      , amount        => dbms_lob.lobmaxsize
      , dest_offset   => l_dest_offset
      , src_offset    => l_src_offset
      , blob_csid     => dbms_lob.default_csid
      , lang_context  => l_lang_context
      , warning       => l_warning
      );

   return l_blob;
end clob_to_blob;

-- helper function for raising errors
procedure raise_error
  ( p_message in varchar2
  , p0        in varchar2 default null
  , p1        in varchar2 default null
  , p2        in varchar2 default null
  )
as
begin
    raise_application_error(-20001, apex_string.format(c_plugin_name || ' - ' || p_message, p0, p1, p2));
end raise_error;

--------------------------------------------------------------------------------
-- private function to include the apex error handling function, if one is
-- defined on application or page level
--------------------------------------------------------------------------------
function error_function_callback
  ( p_error in apex_error.t_error
  )  return apex_error.t_error_result
is
  l_error_handling_function apex_application_pages.error_handling_function%type;
  l_statement               varchar2(32767);
  l_result                  apex_error.t_error_result;

  procedure log_value
    ( p_attribute_name in varchar2
    , p_old_value      in varchar2
    , p_new_value      in varchar2
    )
  is
  begin
      if    p_old_value <> p_new_value
         or (p_old_value is not null and p_new_value is null)
         or (p_old_value is null     and p_new_value is not null)
      then
          apex_debug.info('%s: %s', p_attribute_name, p_new_value);
      end if;
  end log_value;

begin
    if not g_in_error_handling_callback
    then
        g_in_error_handling_callback := true;

        begin
            select /*+ result_cache */
                   coalesce(p.error_handling_function, f.error_handling_function)
              into l_error_handling_function
              from apex_applications f,
                   apex_application_pages p
             where f.application_id     = apex_application.g_flow_id
               and p.application_id (+) = f.application_id
               and p.page_id        (+) = apex_application.g_flow_step_id
            ;
        exception
            when no_data_found then null;
        end;
    end if;

    if l_error_handling_function is not null
    then

        l_statement := 'declare '||
                           'l_error apex_error.t_error; '||
                       'begin '||
                           'l_error := apex_error.g_error; '||
                           'apex_error.g_error_result := '||l_error_handling_function||' ( '||
                               'p_error => l_error ); '||
                       'end;';

        apex_error.g_error := p_error;

        begin
            apex_exec.execute_plsql (
                p_plsql_code      => l_statement );
        exception when others then
            apex_debug.error('error in error handler: %s', sqlerrm);
            apex_debug.error('backtrace: %s', dbms_utility.format_error_backtrace);
        end;

        l_result := apex_error.g_error_result;

        if l_result.message is null
        then
            l_result.message          := nvl(l_result.message,          p_error.message);
            l_result.additional_info  := nvl(l_result.additional_info,  p_error.additional_info);
            l_result.display_location := nvl(l_result.display_location, p_error.display_location);
            l_result.page_item_name   := nvl(l_result.page_item_name,   p_error.page_item_name);
            l_result.column_alias     := nvl(l_result.column_alias,     p_error.column_alias);
        end if;
    else
        l_result.message          := p_error.message;
        l_result.additional_info  := p_error.additional_info;
        l_result.display_location := p_error.display_location;
        l_result.page_item_name   := p_error.page_item_name;
        l_result.column_alias     := p_error.column_alias;
    end if;

    if l_result.message = l_result.additional_info
    then
        l_result.additional_info := null;
    end if;

    g_in_error_handling_callback := false;

    return l_result;

exception
    when others then
        l_result.message             := 'custom apex error handling function failed !!';
        l_result.additional_info     := null;
        l_result.display_location    := apex_error.c_on_error_page;
        l_result.page_item_name      := null;
        l_result.column_alias        := null;
        g_in_error_handling_callback := false;
        return l_result;
end error_function_callback;

-- file download handler
procedure download_files
  ( p_dynamic_action    in apex_plugin.t_dynamic_action
  , p_preview_download  in boolean default false
  )
as
    --attributes
    l_source_type           p_dynamic_action.attribute_01%type := p_dynamic_action.attribute_01;
    l_is_mode_plsql         boolean                            := (l_source_type = 'plsql');

    l_sql_query             p_dynamic_action.attribute_02%type := p_dynamic_action.attribute_02;
    l_plsql_code            p_dynamic_action.attribute_03%type := p_dynamic_action.attribute_03;
    l_archive_name          p_dynamic_action.attribute_04%type := p_dynamic_action.attribute_04;
    l_always_zip            boolean                            := (p_dynamic_action.attribute_15 like '%always-zip%');
    l_additional_plsql_code p_dynamic_action.attribute_06%type := p_dynamic_action.attribute_06;
    l_content_disposition   p_dynamic_action.attribute_09%type := case when p_preview_download then 'attachment' else nvl(p_dynamic_action.attribute_09, 'attachment') end;

    -- used by the sql mode
    l_context               apex_exec.t_context;

    l_pos_name              number;
    l_pos_mime              number;
    l_pos_blob              number;
    l_pos_clob              number;

    l_blob_col_exists       boolean := false;
    l_clob_col_exists       boolean := false;

    l_temp_file_name        varchar2(1000);
    l_temp_mime_type        varchar2(1000);
    l_temp_blob             blob;
    l_temp_clob             clob;

    -- column names expected in the sql mode
    c_alias_file_name       constant varchar2(20) := 'FILE_NAME';
    c_alias_mime_type       constant varchar2(20) := 'FILE_MIME_TYPE';
    c_alias_blob            constant varchar2(20) := 'FILE_CONTENT_BLOB';
    c_alias_clob            constant varchar2(20) := 'FILE_CONTENT_CLOB';

    -- used by the plsql mode
    c_collection_name       constant varchar2(20) := 'FOS_DOWNLOAD_FILES';

    -- both modes
    l_final_file            blob;
    l_final_mime_type       varchar2(1000);
    l_final_file_name       varchar2(1000);

    l_file_count            number;
    l_zipping               boolean;

    procedure show_invalid_file_type_html
    is
      l_image_prefix varchar2(4000);
      l_theme_prefix varchar2(4000);
      --
      function get_translated_message
          ( p_id         in varchar2
          , p_null_value in varchar2
          ) return varchar2
      is
          l_message varchar2(4000);
      begin
          l_message := apex_lang.message(p_name => p_id, p_application_id => nv('APP_ID'));
          return case when l_message = p_id then p_null_value else nvl(l_message, p_null_value) end;
      end get_translated_message;

    begin
        l_image_prefix := apex_plugin_util.replace_substitutions('#IMAGE_PREFIX#');
        l_theme_prefix := apex_plugin_util.replace_substitutions('#THEME_IMAGES#');
        p('<html><head>');
        p('<meta http-equiv="x-ua-compatible" content="IE=edge" />');
        p('<meta charset="utf-8">');
        p('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
        p('<meta http-equiv="Pragma" content="no-cache" />');
        p('<meta http-equiv="Expires" content="-1" />');
        p('<meta http-equiv="Cache-Control" content="no-cache" />');
        p('<meta name="viewport" content="width=device-width, initial-scale=1.0" />');
        p('<link rel="stylesheet" href="'||l_image_prefix||'libraries/font-apex/2.1/css/font-apex.min.css" type="text/css" />');
        p('<link rel="stylesheet" href="'||l_theme_prefix||'css/core/Alert.css" type="text/css" />');
        p('<link rel="stylesheet" href="'||l_theme_prefix||'css/core/Icon.css" type="text/css" />');
        p('<style>body {font: 500 13px/19px "Open Sans", "Helvetica Neue", helvetica, arial, verdana, sans-serif;}');
        p('.t-Alert--warning .t-Alert-icon .fa-Icon {color: #FBCE4A;font-size:64px;}');
        p('.t-Alert--defaultIcons.t-Alert--warning .t-Alert-icon .fa-Icon:before{content: "\f071";}');
        p('.t-Alert--wizard .t-Alert-body{text-align:center}');
        p('.t-Alert--horizontal, .t-Alert--wizard {border: none !important;box-shadow:none}</style>');
        p('</head><body>');
        p('<div class="t-Alert t-Alert--wizard t-Alert--defaultIcons t-Alert--warning">');
        p('<div class="t-Alert-wrap">');
        p('<div class="t-Alert-icon">');
        p('<span class="fa-Icon fa fa-warning"></span>');
        p('</div>');
        p('<div class="t-Alert-content"><div class="t-Alert-header">');
        p('<h2 class="t-Alert-title">'||get_translated_message(p_id => 'FOS.DOWNLOAD.PREVIEW_NA.TITLE', p_null_value => 'Preview not available!')||'</h2>');
        p('</div>');
        p('<div class="t-Alert-body">'||get_translated_message(p_id => 'FOS.DOWNLOAD.PREVIEW_NA.MESSAGE', p_null_value => 'The file cannot be previewed. Please download and open it on your device.')||'</div>');
        p('</div><div class="t-Alert-buttons"></div></div></div></body></html>');
        p('');
    end show_invalid_file_type_html;

    function is_allowed_preview_type
      ( p_mime_type in varchar2
      ) return boolean
    is
    begin
        return p_mime_type in ('application/pdf','application/json','application/xml') or p_mime_type like 'image/%' or p_mime_type like 'text/%';
    end is_allowed_preview_type;

begin
    -- When we open in a new window the disposition must be inline
    if l_content_disposition = 'window'
    then
        l_content_disposition := 'inline';
    end if;

    -- creating a sql query based on the collection so we can reuse the logic for the sql mode
    if l_is_mode_plsql
    then
        apex_collection.create_or_truncate_collection(c_collection_name);
        apex_exec.execute_plsql(l_plsql_code);
        l_sql_query := '
            select c001    as file_name
                 , c002    as file_mime_type
                 , blob001 as file_content_blob
                 , clob001 as file_content_clob
              from apex_collections
             where collection_name = ''' || c_collection_name || '''';
    end if;

    l_context := apex_exec.open_query_context
                   ( p_location          => apex_exec.c_location_local_db
                   , p_sql_query         => l_sql_query
                   , p_total_row_count   => true
                   )
    ;

    l_file_count := apex_exec.get_total_row_count(l_context);

    if l_file_count = 0
    then
        raise_error('At least 1 file must be provided');
    end if;

    -- we zip if there are more than 1 file or if always zip is turned on
    l_zipping := ((l_file_count > 1) or l_always_zip);

    -- result set sanity checks
    begin
        l_pos_name := apex_exec.get_column_position
                        ( p_context     => l_context
                        , p_column_name => c_alias_file_name
                        , p_is_required => true
                        , p_data_type   => apex_exec.c_data_type_varchar2
                        );
    exception
        when others then
            raise_error('A %s column must be defined', c_alias_file_name);
    end;

    begin
        l_pos_mime := apex_exec.get_column_position
                        ( p_context     => l_context
                        , p_column_name => c_alias_mime_type
                        , p_is_required => true
                        , p_data_type   => apex_exec.c_data_type_varchar2
                        );
    exception
        when others then
            raise_error('A %s column must be defined', c_alias_mime_type);
    end;

    -- looping through all columns as opposed to using get_column_position
    -- as get_column_position writes an error to the logs if the column is not found
    -- even if the exception is handled
    l_blob_col_exists := false;
    l_clob_col_exists := false;
    for idx in 1 .. apex_exec.get_column_count(l_context)
    loop
        if apex_exec.get_column(l_context, idx).name = c_alias_blob
        then
            l_pos_blob := idx;
            l_blob_col_exists := true;
        end if;

        if apex_exec.get_column(l_context, idx).name = c_alias_clob
        then
            l_pos_clob := idx;
            l_clob_col_exists := true;
        end if;
    end loop;

    -- raise an error if neither a blob nor a clob source was provided
    if not (l_blob_col_exists or l_clob_col_exists)
    then
        raise_error('Either a %s or a %s column must be defined', c_alias_blob, c_alias_clob);
    end if;

    -- looping through all files
    while apex_exec.next_row(l_context)
    loop
        if l_blob_col_exists
        then
            l_temp_blob := apex_exec.get_blob(l_context, l_pos_blob);
            if l_temp_blob is null
            then
              l_temp_blob := empty_blob();
            end if;
        end if;

        if l_clob_col_exists
        then
            l_temp_clob := apex_exec.get_clob(l_context, l_pos_clob);
            if l_temp_clob is null
            then
              l_temp_clob := empty_clob();
            end if;
        end if;

        l_temp_file_name := apex_exec.get_varchar2(l_context, l_pos_name);
        l_temp_mime_type := apex_exec.get_varchar2(l_context, l_pos_mime);

        -- logic for choosing between the blob an clob
        if    (l_blob_col_exists and not l_clob_col_exists)
           or (l_blob_col_exists and     l_clob_col_exists and dbms_lob.getlength(l_temp_blob) > 0)
        then
            if apex_application.g_debug
            then
                apex_debug.message('%s - BLOB - %s bytes', l_temp_file_name, dbms_lob.getlength(l_temp_blob));
            end if;

            if l_zipping
            then
                apex_zip.add_file
                  ( p_zipped_blob => l_final_file
                  , p_file_name   => l_temp_file_name
                  , p_content     => l_temp_blob
                  );
            else
                -- there's only 1 file in the result set
                l_final_file_name := l_temp_file_name;
                l_final_mime_type := l_temp_mime_type;
                l_final_file      := l_temp_blob;
            end if;
        else
            if apex_application.g_debug
            then
                apex_debug.message('%s - CLOB - %s bytes', l_temp_file_name, dbms_lob.getlength(l_temp_clob));
            end if;

            if l_zipping
            then
                apex_zip.add_file
                  ( p_zipped_blob => l_final_file
                  , p_file_name   => l_temp_file_name
                  , p_content     => clob_to_blob(l_temp_clob)
                  );
            else
                -- there's only 1 file in the result set
                l_final_file_name := l_temp_file_name;
                l_final_mime_type := l_temp_mime_type;
                l_final_file      := clob_to_blob(l_temp_clob);
            end if;
        end if;
    end loop;

    apex_exec.close(l_context);

    if l_is_mode_plsql
    then
        apex_collection.delete_collection(c_collection_name);
    end if;

    if l_zipping
    then
        apex_zip.finish(l_final_file);
        if l_file_count = 1
        then
            l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, l_temp_file_name || '.zip'));
        else
            l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, 'files.zip'));
        end if;

        l_final_mime_type := 'application/zip';

        if l_final_file_name not like '%.zip'
        then
            l_final_file_name := l_final_file_name || '.zip';
        end if;
    end if;

    if l_additional_plsql_code is not null
    then
        apex_exec.execute_plsql('begin '||l_additional_plsql_code||' commit; end;');
    end if;

    if          l_content_disposition = 'inline'
        and not is_allowed_preview_type(l_final_mime_type)
    then
        show_invalid_file_type_html;
    else
        sys.htp.init;
        sys.owa_util.mime_header(l_final_mime_type, false);
        --
        -- We send a cookie so we can determine when a file has been downloaded
        -- https://stackoverflow.com/questions/1106377/detect-when-browser-receives-file-download
        owa_cookie.send
          ( name    => apex_application.g_x10
          , value   => '{"count":'||l_file_count||',"name":"'||apex_escape.json(l_final_file_name)||'","mimeType":"'||apex_escape.json(l_final_mime_type)||'","size":"'||trim(apex_escape.json(apex_util.filesize_mask(dbms_lob.getlength(l_final_file))))||'"}'
          , expires => sysdate + 2/1440
          );
        p('Content-Length: ' || dbms_lob.getlength(l_final_file));
        p('Content-Disposition: '||l_content_disposition||'; filename="' || l_final_file_name || '";');
        sys.owa_util.http_header_close;

        sys.wpg_docload.download_file(l_final_file);
        apex_application.stop_apex_engine;
    end if;
exception
  -- this is the exception thrown by stop_apex_engine
  -- catching it here so it won't be handled by the others handlers
  when apex_application.e_stop_apex_engine then
      raise;
  when others then
      -- delete the collection in case the error occurred between opening and closing it
      if apex_collection.collection_exists(c_collection_name)
      then
          apex_collection.delete_collection(c_collection_name);
      end if;
      -- always close the context in case of an error
      apex_exec.close(l_context);
      raise;
end download_files;

--------------------------------------------------------------------------------
-- Main plug-in render function
--------------------------------------------------------------------------------
function render
  ( p_dynamic_action in apex_plugin.t_dynamic_action
  , p_plugin         in apex_plugin.t_plugin
  )
return apex_plugin.t_dynamic_action_render_result
as
    l_result                 apex_plugin.t_dynamic_action_render_result;

    --general attributes
    l_ajax_identifier        varchar2(4000)                     := apex_plugin.get_ajax_identifier;
    l_static_id              varchar2(4000)                     := nvl(p_dynamic_action.attribute_07, p_dynamic_action.id);
    l_suppress_errors        boolean                            := (p_dynamic_action.attribute_15 like '%suppress-error-messages%');
    l_content_disposition    p_dynamic_action.attribute_09%type := nvl(p_dynamic_action.attribute_09, 'download');

    -- spinner settings
    l_show_spinner           boolean                            := instr(p_dynamic_action.attribute_15, 'show-spinner') > 0;
    l_show_spinner_overlay   boolean                            := instr(p_dynamic_action.attribute_15, 'show-spinner-overlay') > 0;
    l_show_spinner_on_region boolean                            := instr(p_dynamic_action.attribute_15, 'spinner-position') > 0;

    -- page items to submit settings
    l_items_to_submit        varchar2(4000)                     := apex_plugin_util.page_item_names_to_jquery(p_dynamic_action.attribute_05);

    -- Javascript Initialization Code
    l_init_js_fn             varchar2(32767)                    := nvl(apex_plugin_util.replace_substitutions(p_dynamic_action.init_javascript_code), 'undefined');

begin
    if apex_application.g_debug
    then
        apex_plugin_util.debug_dynamic_action
          ( p_dynamic_action => p_dynamic_action
          , p_plugin         => p_plugin
          );
    end if;

    -- create a json object holding the dynamic action settings
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('id'                   , p_dynamic_action.id);
    apex_json.write('staticId'             , l_static_id);
    apex_json.write('ajaxIdentifier'       , l_ajax_identifier);
    apex_json.write('itemsToSubmit'        , l_items_to_submit);
    apex_json.write('suppressErrorMessages', l_suppress_errors);
    apex_json.write('previewMode'          , l_content_disposition = 'inline');
    apex_json.write('newWindow'            , l_content_disposition = 'window');

    apex_json.open_object('spinnerSettings');
    apex_json.write('showSpinner'          , l_show_spinner);
    apex_json.write('showSpinnerOverlay'   , l_show_spinner_overlay);
    apex_json.write('showSpinnerOnRegion'  , l_show_spinner_on_region);
    apex_json.close_object;

    -- close JSON settings
    apex_json.close_object;

    -- defines the function that will be run each time the dynamic action fires
    l_result.javascript_function := 'function() { FOS.utils.download(this, '|| apex_json.get_clob_output||', '||l_init_js_fn||'); }';

    apex_json.free_output;
    return l_result;
end render;

--------------------------------------------------------------------------------
-- Main plug-in AJAX function
--------------------------------------------------------------------------------
function ajax
  ( p_dynamic_action in apex_plugin.t_dynamic_action
  , p_plugin         in apex_plugin.t_plugin
  )
return apex_plugin.t_dynamic_action_ajax_result
as
    -- error handling
    l_apex_error               apex_error.t_error;
    l_result                   apex_error.t_error_result;

    -- return type
    l_return                   apex_plugin.t_dynamic_action_ajax_result;

    --general attributes
    l_ajax_identifier          varchar2(4000)                     := replace(coalesce(apex_application.g_request, apex_plugin.get_ajax_identifier), 'PLUGIN=', '');
    l_static_id                varchar2(4000)                     := nvl(p_dynamic_action.attribute_07, p_dynamic_action.id);
    l_suppress_errors          boolean                            := (p_dynamic_action.attribute_15 like '%suppress-error-messages%');
    l_content_disposition      p_dynamic_action.attribute_09%type := nvl(p_dynamic_action.attribute_09, 'download');

    -- preview mode, we can alos download the file in preview mode so we need to be able to switch the download type dynamically (settings are static)
    l_preview_download         varchar2(255)                      := nvl(apex_application.g_x02, 'NO');
    l_preview_mode             boolean                            := case when l_preview_download = 'YES' then false else l_content_disposition = 'inline' end;
    l_preview_new_window       boolean                            := case when l_preview_download = 'YES' then false else l_content_disposition = 'window' end;

    -- preview settings
    l_prv_close_on_escape      boolean                            := instr(p_dynamic_action.attribute_10, 'close-on-escape')           > 0;
    l_prv_draggable            boolean                            := instr(p_dynamic_action.attribute_10, 'draggable')                 > 0;
    l_prv_modal                boolean                            := instr(p_dynamic_action.attribute_10, 'modal')                     > 0;
    l_prv_resizable            boolean                            := instr(p_dynamic_action.attribute_10, 'resizable')                 > 0;
    l_prv_show_file_info       boolean                            := instr(p_dynamic_action.attribute_10, 'show-file-info')            > 0;
    l_prv_show_download_btn    boolean                            := instr(p_dynamic_action.attribute_10, 'show-download-button')      > 0;
    l_prv_custom_file_info_tpl boolean                            := instr(p_dynamic_action.attribute_10, 'custom-file-info-template') > 0;

    l_prv_file_info_template   p_dynamic_action.attribute_12%type := p_dynamic_action.attribute_12;
    l_prv_title                p_dynamic_action.attribute_11%type := p_dynamic_action.attribute_11;

    -- spinner settings
    l_show_spinner             boolean                            := instr(p_dynamic_action.attribute_15, 'show-spinner')              > 0;
    l_show_spinner_overlay     boolean                            := instr(p_dynamic_action.attribute_15, 'show-spinner-overlay')      > 0;
    l_show_spinner_on_region   boolean                            := instr(p_dynamic_action.attribute_15, 'spinner-position')          > 0;

    -- page items to submit settings
    l_items_to_submit          varchar2(4000)                     := apex_plugin_util.page_item_names_to_jquery(p_dynamic_action.attribute_05);

    function get_preview_url
    return varchar2
    as
    begin
        return 'wwv_flow.show?p_flow_id='||v('app_id')||'&p_flow_step_id='||v('app_page_id')||'&p_instance='||v('app_session')||
               '&p_debug='||v('debug')||'&p_request=PLUGIN='||l_ajax_identifier||'&p_widget_name='||p_plugin.name||'&p_widget_action='||c_download_request||
               '&x02='||apex_application.g_x02||'&x10='||apex_application.g_x10
        ;
    end get_preview_url;
begin
    -- standard debugging intro, but only if necessary
    if apex_application.g_debug
    then
      apex_plugin_util.debug_dynamic_action
        ( p_plugin         => p_plugin
        , p_dynamic_action => p_dynamic_action
        );
    end if;

    if apex_application.g_widget_action = c_download_request
    then
        -- Hand off to our download routine
        download_files
          ( p_dynamic_action   => p_dynamic_action
          , p_preview_download => apex_application.g_x02 = 'YES'
          );
    else
        apex_json.open_object;
        apex_json.write('status'                 , 'success');
        apex_json.open_object('data');
        apex_json.write('previewMode'            , l_preview_mode);

        if l_preview_mode or l_preview_new_window
        then
            -- settings for download button in preview dialog
            apex_json.write('id'                 , p_dynamic_action.id);
            apex_json.write('staticId'           , l_static_id);
            apex_json.write('ajaxIdentifier'     , l_ajax_identifier);
            apex_json.write('itemsToSubmit'      , l_items_to_submit);
            apex_json.write('suppressErrorMessages', l_suppress_errors);

            -- preview settings
            apex_json.write('previewSrc'         , get_preview_url);
            apex_json.write('previewId'          , 'preview-'||apex_application.g_x01);

            -- preview dialog settings
            apex_json.open_object('previewOptions');
            apex_json.write('closeOnEscape'      , l_prv_close_on_escape);
            apex_json.write('draggable'          , l_prv_draggable);
            apex_json.write('modal'              , l_prv_modal);
            apex_json.write('resizable'          , l_prv_resizable);
            apex_json.write('showFileInfo'       , l_prv_show_file_info);
            apex_json.write('showDownloadBtn'    , l_prv_show_download_btn);
            apex_json.write('title'              , l_prv_title);

            if l_prv_custom_file_info_tpl
            then
                apex_json.write('fileInfoTpl'    , l_prv_file_info_template);
            end if;

            apex_json.close_object;

            -- spinner settings
            apex_json.open_object('spinnerSettings');
            apex_json.write('showSpinner'        , l_show_spinner);
            apex_json.write('showSpinnerOverlay' , l_show_spinner_overlay);
            apex_json.write('showSpinnerOnRegion', l_show_spinner_on_region);
            apex_json.close_object;
        end if;


        apex_json.write('formId'                 , 'form-'||apex_application.g_x01);
        apex_json.write('iframeId'               , 'iframe-'||apex_application.g_x01);
        apex_json.write('appId'                  , v('APP_ID'));
        apex_json.write('pageId'                 , v('APP_PAGE_ID'));
        apex_json.write('sessionId'              , v('APP_SESSION'));
        apex_json.write('debug'                  , v('DEBUG'));
        apex_json.write('request'                , l_ajax_identifier);
        apex_json.write('widgetName'             , p_plugin.name);
        apex_json.write('action'                 , c_download_request);
        apex_json.write('previewDownload'        , l_preview_download);
        apex_json.close_object;
        apex_json.close_object;
    end if;

    return l_return;

exception
    -- this is the exception thrown by stop_apex_engine
    -- we catch it here because we are catching all errors
    -- but we allow/ignore the stop engine error
    when apex_application.e_stop_apex_engine then
      return l_return;
    -- for any other error we must return an error message
    when others then
      apex_json.initialize_output;
      l_apex_error.message             := sqlerrm;
      l_apex_error.ora_sqlcode         := sqlcode;
      l_apex_error.ora_sqlerrm         := sqlerrm;
      l_apex_error.error_backtrace     := dbms_utility.format_error_backtrace;

      l_result := error_function_callback(l_apex_error);

      apex_json.open_object;
      apex_json.write('status' , 'error');
      apex_json.write('message'         , l_result.message);
      apex_json.write('additional_info' , l_result.additional_info);
      apex_json.write('display_location', l_result.display_location);
      apex_json.write('page_item_name'  , l_result.page_item_name);
      apex_json.write('column_alias'    , l_result.column_alias);
      apex_json.close_object;
      return l_return;
end ajax;

end;
/


