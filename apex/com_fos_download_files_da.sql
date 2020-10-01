

prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_190200 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2019.10.04'
,p_release=>'19.2.0.00.18'
,p_default_workspace_id=>1620873114056663
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'FOS_MASTER_WS'
);
end;
/

prompt APPLICATION 102 - FOS Dev - Plugin Master
--
-- Application Export:
--   Application:     102
--   Name:            FOS Dev - Plugin Master
--   Exported By:     FOS_MASTER_WS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 61118001090994374
--     PLUGIN: 134108205512926532
--     PLUGIN: 168413046168897010
--     PLUGIN: 13235263798301758
--     PLUGIN: 37441962356114799
--     PLUGIN: 1846579882179407086
--     PLUGIN: 8354320589762683
--     PLUGIN: 50031193176975232
--     PLUGIN: 34175298479606152
--     PLUGIN: 35822631205839510
--     PLUGIN: 2674568769566617
--     PLUGIN: 14934236679644451
--     PLUGIN: 2600618193722136
--     PLUGIN: 2657630155025963
--     PLUGIN: 284978227819945411
--     PLUGIN: 56714461465893111
--   Manifest End
--   Version:         19.2.0.00.18
--   Instance ID:     250144500186934
--

begin
  -- replace components
  wwv_flow_api.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/dynamic_action/com_fos_download_files_da
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(61118001090994374)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'COM.FOS.DOWNLOAD_FILES_DA'
,p_display_name=>'FOS - Download File(s)'
,p_category=>'EXECUTE'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/script#MIN#.js'
,p_css_file_urls=>'#PLUGIN_FILES#css/style#MIN#.css'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- =============================================================================',
'--',
'--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)',
'--',
'-- =============================================================================',
'',
'-- globals & contants ',
'c_plugin_name                constant varchar2(100) := ''FOS - Download File(s)'';',
'c_cookie_name                constant varchar2(100) := ''FOS_DOWNLOAD_FILE'';',
'c_download_request           constant varchar2(100) := ''DOWNLOAD_FILES'';',
'',
'g_in_error_handling_callback boolean := false;',
'',
'-- helper function for converting clob to blob',
'function clob_to_blob',
'    ( p_clob clob',
'    )',
'return blob',
'as',
'    l_blob         blob;',
'    l_clob         clob   := empty_clob();',
'    l_dest_offset  number := 1;',
'    l_src_offset   number := 1;',
'    l_lang_context number := dbms_lob.default_lang_ctx;',
'    l_warning      number := dbms_lob.warn_inconvertible_char;',
'begin',
'',
'    if p_clob is null or dbms_lob.getlength(p_clob) = 0 then',
'        dbms_lob.createtemporary',
'            ( lob_loc => l_clob',
'            , cache   => true',
'            );',
'    else',
'        l_clob := p_clob;',
'    end if;',
'',
'    dbms_lob.createtemporary',
'        ( lob_loc => l_blob',
'        , cache   => true',
'        );',
'',
'    dbms_lob.converttoblob',
'        ( dest_lob      => l_blob',
'        , src_clob      => l_clob',
'        , amount        => dbms_lob.lobmaxsize',
'        , dest_offset   => l_dest_offset',
'        , src_offset    => l_src_offset',
'        , blob_csid     => dbms_lob.default_csid',
'        , lang_context  => l_lang_context',
'        , warning       => l_warning',
'        );',
'',
'   return l_blob;',
'end;',
'',
'-- helper function for raising errors',
'procedure raise_error',
'    ( p_message varchar2',
'    , p0        varchar2 default null',
'    , p1        varchar2 default null',
'    , p2        varchar2 default null',
'    )',
'as',
'begin',
'    raise_application_error(-20001, apex_string.format(c_plugin_name || '' - '' || p_message, p0, p1, p2));',
'end;',
'',
'--------------------------------------------------------------------------------',
'-- private function to include the apex error handling function, if one is',
'-- defined on application or page level',
'--------------------------------------------------------------------------------',
'function error_function_callback',
'  ( p_error in apex_error.t_error',
'  )  return apex_error.t_error_result',
'is',
'  c_cr constant varchar2(1) := chr(10);',
'',
'  l_error_handling_function apex_application_pages.error_handling_function%type;',
'  l_statement               varchar2(32767);',
'  l_result                  apex_error.t_error_result;',
'',
'  procedure log_value (',
'      p_attribute_name in varchar2,',
'      p_old_value      in varchar2,',
'      p_new_value      in varchar2 )',
'  is',
'  begin',
'      if   p_old_value <> p_new_value',
'        or (p_old_value is not null and p_new_value is null)',
'        or (p_old_value is null     and p_new_value is not null)',
'      then',
'          apex_debug.info(''%s: %s'', p_attribute_name, p_new_value);',
'      end if;',
'  end log_value;',
'begin',
'  if not g_in_error_handling_callback ',
'  then',
'    g_in_error_handling_callback := true;',
'',
'    begin',
'      select /*+ result_cache */',
'             coalesce(p.error_handling_function, f.error_handling_function)',
'        into l_error_handling_function',
'        from apex_applications f,',
'             apex_application_pages p',
'       where f.application_id     = apex_application.g_flow_id',
'         and p.application_id (+) = f.application_id',
'         and p.page_id        (+) = apex_application.g_flow_step_id;',
'    exception when no_data_found then',
'        null;',
'    end;',
'  end if;',
'',
'  if l_error_handling_function is not null',
'  then',
'',
'    l_statement := ''declare''||c_cr||',
'                       ''l_error apex_error.t_error;''||c_cr||',
'                   ''begin''||c_cr||',
'                       ''l_error := apex_error.g_error;''||c_cr||',
'                       ''apex_error.g_error_result := ''||l_error_handling_function||'' (''||c_cr||',
'                           ''p_error => l_error );''||c_cr||',
'                   ''end;'';',
'',
'    apex_error.g_error := p_error;',
'',
'    begin',
'        apex_exec.execute_plsql (',
'            p_plsql_code      => l_statement );',
'    exception when others then',
'        apex_debug.error(''error in error handler: %s'', sqlerrm);',
'        apex_debug.error(''backtrace: %s'', dbms_utility.format_error_backtrace);',
'    end;',
'',
'    l_result := apex_error.g_error_result;',
'',
'    if l_result.message is null',
'    then',
'        l_result.message          := nvl(l_result.message,          p_error.message);',
'        l_result.additional_info  := nvl(l_result.additional_info,  p_error.additional_info);',
'        l_result.display_location := nvl(l_result.display_location, p_error.display_location);',
'        l_result.page_item_name   := nvl(l_result.page_item_name,   p_error.page_item_name);',
'        l_result.column_alias     := nvl(l_result.column_alias,     p_error.column_alias);',
'    end if;',
'  else',
'    l_result.message          := p_error.message;',
'    l_result.additional_info  := p_error.additional_info;',
'    l_result.display_location := p_error.display_location;',
'    l_result.page_item_name   := p_error.page_item_name;',
'    l_result.column_alias     := p_error.column_alias;',
'  end if;',
'',
'  if l_result.message = l_result.additional_info',
'  then',
'    l_result.additional_info := null;',
'  end if;',
'',
'  g_in_error_handling_callback := false;',
'',
'  return l_result;',
'',
'exception',
'  when others then',
'    l_result.message             := ''custom apex error handling function failed !!'';',
'    l_result.additional_info     := null;',
'    l_result.display_location    := apex_error.c_on_error_page;',
'    l_result.page_item_name      := null;',
'    l_result.column_alias        := null;',
'    g_in_error_handling_callback := false;',
'    return l_result;',
'',
'end error_function_callback;',
'',
'-- file download handler',
'procedure download_files',
'  ( p_dynamic_action    apex_plugin.t_dynamic_action',
'  , p_plugin            apex_plugin.t_plugin',
'  , p_preview_download  boolean default false',
'  )',
'as',
'  --attributes',
'  l_source_type             p_dynamic_action.attribute_01%type := p_dynamic_action.attribute_01;',
'  l_is_mode_sql             boolean := (l_source_type = ''sql'');',
'  l_is_mode_plsql           boolean := (l_source_type = ''plsql'');',
'  ',
'  l_sql_query               p_dynamic_action.attribute_02%type := p_dynamic_action.attribute_02;',
'  l_plsql_code              p_dynamic_action.attribute_03%type := p_dynamic_action.attribute_03;',
'  l_archive_name            p_dynamic_action.attribute_04%type := p_dynamic_action.attribute_04;',
'  l_always_zip              boolean := (p_dynamic_action.attribute_15 like ''%always-zip%'');',
'  l_additional_plsql_code   p_dynamic_action.attribute_06%type := p_dynamic_action.attribute_06;',
'  l_content_disposition     p_dynamic_action.attribute_09%type := case when p_preview_download then ''attachment'' else nvl(p_dynamic_action.attribute_09, ''attachment'') end;',
'',
'  -- used by the sql mode',
'  l_context    apex_exec.t_context;',
'  ',
'  l_pos_name   number;',
'  l_pos_mime   number;',
'  l_pos_blob   number;',
'  l_pos_clob   number;',
'  ',
'  l_blob_col_exists boolean := false;',
'  l_clob_col_exists boolean := false;',
'  ',
'  l_temp_file_name varchar2(1000);',
'  l_temp_mime_type varchar2(1000);',
'  l_temp_blob blob;',
'  l_temp_clob clob;',
'  ',
'  -- column names expected in the sql mode',
'  c_alias_file_name constant varchar2(20) := ''FILE_NAME'';',
'  c_alias_mime_type constant varchar2(20) := ''FILE_MIME_TYPE'';',
'  c_alias_blob      constant varchar2(20) := ''FILE_CONTENT_BLOB'';',
'  c_alias_clob      constant varchar2(20) := ''FILE_CONTENT_CLOB'';',
'',
'  -- used by the plsql mode',
'  c_collection_name constant varchar2(20) := ''FOS_DOWNLOAD_FILES'';',
'  ',
'  -- both modes',
'  l_final_file      blob;',
'  l_final_mime_type varchar2(1000);',
'  l_final_file_name varchar2(1000);',
'  ',
'  l_file_count      number;',
'  l_zipping         boolean;',
'  ',
'  procedure show_invalid_file_type_html',
'  ( p_file_name in varchar2 default null',
'  , p_mime_type in varchar2 default null',
'  )',
'  is',
'    l_image_prefix VARCHAR2(4000);',
'    l_theme_prefix VARCHAR2(4000);',
'    --',
'    function get_translated_message',
'        ( p_id in varchar2',
'        , p_null_value in varchar2',
'        ) return varchar2',
'    is',
'        l_message varchar2(4000);',
'    begin',
'        l_message := apex_lang.message(p_name => p_id, p_application_id => nv(''APP_ID''));',
'        return case when l_message = p_id then p_null_value else nvl(l_message, p_null_value) end;',
'    end get_translated_message;',
'    ',
'  begin',
'    l_image_prefix := apex_plugin_util.replace_substitutions(''#IMAGE_PREFIX#'');',
'    l_theme_prefix := apex_plugin_util.replace_substitutions(''#THEME_IMAGES#'');',
'    sys.htp.p(''<html>'');',
'    sys.htp.p(''<head>'');',
'    sys.htp.p(''<meta http-equiv="x-ua-compatible" content="IE=edge" />'');',
'    sys.htp.p(''<meta charset="utf-8">'');',
'    sys.htp.p(''<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />'');',
'    sys.htp.p(''<meta http-equiv="Pragma" content="no-cache" />'');',
'    sys.htp.p(''<meta http-equiv="Expires" content="-1" />'');',
'    sys.htp.p(''<meta http-equiv="Cache-Control" content="no-cache" />'');',
'    sys.htp.p(''<meta name="viewport" content="width=device-width, initial-scale=1.0" />'');',
'    sys.htp.p(''<link rel="stylesheet" href="''||l_image_prefix||''libraries/font-apex/2.1/css/font-apex.min.css" type="text/css" />'');',
'    sys.htp.p(''<link rel="stylesheet" href="''||l_theme_prefix||''css/core/Alert.css" type="text/css" />'');',
'    sys.htp.p(''<link rel="stylesheet" href="''||l_theme_prefix||''css/core/Icon.css" type="text/css" />'');',
'    sys.htp.p(''<style>body {font: 500 13px/19px "Open Sans", "Helvetica Neue", helvetica, arial, verdana, sans-serif;}'');',
'    sys.htp.p(''.t-Alert--warning .t-Alert-icon .fa-Icon {color: #FBCE4A;font-size:64px;}'');',
'    sys.htp.p(''.t-Alert--defaultIcons.t-Alert--warning .t-Alert-icon .fa-Icon:before{content: "\f071";}'');',
'    sys.htp.p(''.t-Alert--wizard .t-Alert-body{text-align:center}'');',
'    sys.htp.p(''.t-Alert--horizontal, .t-Alert--wizard {border: none !important;box-shadow:none}</style>'');',
'    sys.htp.p(''</head>'');',
'    sys.htp.p(''<body>'');',
'    sys.htp.p(''<div class="t-Alert t-Alert--wizard t-Alert--defaultIcons t-Alert--warning">'');',
'    sys.htp.p(''<div class="t-Alert-wrap">'');',
'    sys.htp.p(''<div class="t-Alert-icon">'');',
'    sys.htp.p(''<span class="fa-Icon fa fa-warning"></span>'');',
'    sys.htp.p(''</div>'');',
'    sys.htp.p(''<div class="t-Alert-content">'');',
'    sys.htp.p(''<div class="t-Alert-header">'');',
'    sys.htp.p(''<h2 class="t-Alert-title">''||get_translated_message(p_id => ''FOS.DOWNLOAD.PREVIEW_NA.TITLE'', p_null_value => ''Preview not available!'')||''</h2>'');',
'    sys.htp.p(''</div>'');',
'    sys.htp.p(''<div class="t-Alert-body">''||get_translated_message(p_id => ''FOS.DOWNLOAD.PREVIEW_NA.MESSAGE'', p_null_value => ''The file cannot be previewed. Please download and open it on your device.'')||''</div>'');',
'    sys.htp.p(''</div>'');',
'    sys.htp.p(''<div class="t-Alert-buttons"></div>'');',
'    sys.htp.p(''</div>'');',
'    sys.htp.p(''</div>'');',
'    sys.htp.p(''</body>'');',
'    sys.htp.p(''</html>'');',
'    sys.htp.p('''');',
'  end show_invalid_file_type_html;',
'  ',
'  function is_allowed_preview_type',
'  ( p_mime_type in varchar2',
'  ) return boolean',
'  is',
'  begin',
'    return p_mime_type in (''application/pdf'',''application/json'',''application/xml'') or p_mime_type like ''image/%'' or p_mime_type like ''text/%'';',
'  end is_allowed_preview_type;',
'  ',
'begin',
'  ',
'  --',
'  -- When we open in a new window the disposition must be inline',
'  --',
'  if l_content_disposition = ''window'' then',
'    l_content_disposition := ''inline'';',
'  end if;',
'  ',
'  -- creating a sql query based on the collection so we can reuse the logic for the sql mode',
'  if l_is_mode_plsql',
'  then',
'    apex_collection.create_or_truncate_collection(c_collection_name);',
'    apex_exec.execute_plsql(l_plsql_code);',
'    l_sql_query := ''',
'        select c001    as file_name',
'             , c002    as file_mime_type',
'             , blob001 as file_content_blob',
'             , clob001 as file_content_clob',
'          from apex_collections',
'         where collection_name = '''''' || c_collection_name || '''''''';',
'  end if;',
'',
'  l_context := apex_exec.open_query_context',
'      ( p_location          => apex_exec.c_location_local_db',
'      , p_sql_query         => l_sql_query',
'      , p_total_row_count   => true',
'      );',
'',
'  l_file_count := apex_exec.get_total_row_count(l_context);',
'',
'  if l_file_count = 0',
'  then',
'      raise_error(''At least 1 file must be provided'');',
'  end if;',
'',
'  -- we zip if there are more than 1 file or if always zip is turned on',
'  l_zipping := ((l_file_count > 1) or l_always_zip);',
'',
'  -- result set sanity checks',
'  begin',
'    l_pos_name := apex_exec.get_column_position',
'      ( p_context     => l_context',
'      , p_column_name => c_alias_file_name',
'      , p_is_required => true',
'      , p_data_type   => apex_exec.c_data_type_varchar2',
'      );',
'  exception',
'      when others then',
'          raise_error(''A %s column must be defined'', c_alias_file_name);',
'  end;',
'',
'  begin',
'    l_pos_mime := apex_exec.get_column_position',
'      ( p_context     => l_context',
'      , p_column_name => c_alias_mime_type',
'      , p_is_required => true',
'      , p_data_type   => apex_exec.c_data_type_varchar2',
'      );',
'  exception',
'      when others then',
'          raise_error(''A %s column must be defined'', c_alias_mime_type);',
'  end;',
'',
'  -- looping through all columns as opposed to using get_column_position',
'  -- as get_column_position writes an error to the logs if the column is not found',
'  -- even if the exception is handled',
'  l_blob_col_exists := false;',
'  l_clob_col_exists := false;',
'  for idx in 1 .. apex_exec.get_column_count(l_context)',
'  loop',
'    if apex_exec.get_column(l_context, idx).name = c_alias_blob',
'    then',
'      l_pos_blob := idx;',
'      l_blob_col_exists := true;',
'    end if;',
'    if apex_exec.get_column(l_context, idx).name = c_alias_clob',
'    then',
'      l_pos_clob := idx;',
'      l_clob_col_exists := true;',
'    end if;',
'  end loop;',
'',
'  -- raise an error if neither a blob nor a clob source was provided',
'  if not (l_blob_col_exists or l_clob_col_exists)',
'  then',
'    raise_error(''Either a %s or a %s column must be defined'', c_alias_blob, c_alias_clob);',
'  end if;',
'',
'  -- looping through all files',
'  while apex_exec.next_row(l_context)',
'  loop',
'',
'    if l_blob_col_exists',
'    then',
'      l_temp_blob := apex_exec.get_blob(l_context, l_pos_blob);',
'      if l_temp_blob is null',
'      then',
'        l_temp_blob := empty_blob();',
'      end if;',
'    end if;',
'',
'    if l_clob_col_exists',
'    then',
'      l_temp_clob := apex_exec.get_clob(l_context, l_pos_clob);',
'      if l_temp_clob is null',
'      then',
'        l_temp_clob := empty_clob();',
'      end if;',
'    end if;',
'    ',
'    l_temp_file_name := apex_exec.get_varchar2(l_context, l_pos_name);',
'    l_temp_mime_type := apex_exec.get_varchar2(l_context, l_pos_mime);',
'',
'    -- logic for choosing between the blob an clob',
'    if (l_blob_col_exists and not l_clob_col_exists)',
'    or (l_blob_col_exists and l_clob_col_exists and dbms_lob.getlength(l_temp_blob) > 0) ',
'    then',
'      if apex_application.g_debug',
'      then',
'        apex_debug.message(''%s - BLOB - %s bytes'', l_temp_file_name, dbms_lob.getlength(l_temp_blob));',
'      end if;',
'      if l_zipping',
'      then',
'        apex_zip.add_file',
'          ( p_zipped_blob => l_final_file',
'          , p_file_name   => l_temp_file_name',
'          , p_content     => l_temp_blob',
'          );',
'      else',
'        -- there''s only 1 file in the result set',
'        l_final_file_name := l_temp_file_name;',
'        l_final_mime_type := l_temp_mime_type;',
'        l_final_file      := l_temp_blob;',
'      end if;',
'    else',
'      if apex_application.g_debug',
'      then',
'        apex_debug.message(''%s - CLOB - %s bytes'', l_temp_file_name, dbms_lob.getlength(l_temp_clob));',
'      end if;',
'      if l_zipping',
'      then',
'        apex_zip.add_file',
'          ( p_zipped_blob => l_final_file',
'          , p_file_name   => l_temp_file_name',
'          , p_content     => clob_to_blob(l_temp_clob)',
'          );',
'      else',
'        -- there''s only 1 file in the result set',
'        l_final_file_name := l_temp_file_name;',
'        l_final_mime_type := l_temp_mime_type;',
'        l_final_file      := clob_to_blob(l_temp_clob);',
'      end if;',
'    end if;',
'  end loop;',
'',
'  apex_exec.close(l_context);',
'  ',
'  if l_is_mode_plsql',
'  then',
'      apex_collection.delete_collection(c_collection_name);',
'  end if;',
'',
'  if l_zipping',
'  then',
'    apex_zip.finish(l_final_file);',
'    if l_file_count = 1 then',
'      l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, l_temp_file_name || ''.zip''));',
'    else',
'      l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, ''files.zip''));',
'    end if;',
'    ',
'    l_final_mime_type := ''application/zip'';',
'    ',
'    if l_final_file_name not like ''%.zip'' then',
'      l_final_file_name := l_final_file_name || ''.zip'';',
'    end if;',
'  end if;',
'',
'  if l_additional_plsql_code is not null then',
'    apex_exec.execute_plsql(''begin ''||l_additional_plsql_code||'' commit; end;'');',
'  end if;',
'',
'  if  l_content_disposition = ''inline'' and not is_allowed_preview_type(l_final_mime_type) then',
'    show_invalid_file_type_html;',
'  else',
'    sys.htp.init;',
'    sys.owa_util.mime_header(l_final_mime_type, false);',
'    --',
'    -- We send a cookie so we can determine when a file has been downloaded',
'    -- https://stackoverflow.com/questions/1106377/detect-when-browser-receives-file-download',
'    owa_cookie.send',
'      ( name    => apex_application.g_x10',
'      , value   => ''{"count":''||l_file_count||'',"name":"''||apex_escape.json(l_final_file_name)||''","mimeType":"''||apex_escape.json(l_final_mime_type)||''","size":"''||trim(apex_escape.json(apex_util.filesize_mask(dbms_lob.getlength(l_final_file))))||''"'
||'}''',
'      , expires => sysdate + 2/1440',
'      );',
'    sys.htp.p(''Content-Length: '' || dbms_lob.getlength(l_final_file));',
'    sys.htp.p(''Content-Disposition: ''||l_content_disposition||''; filename="'' || l_final_file_name || ''";'');',
'    sys.owa_util.http_header_close;',
'',
'    sys.wpg_docload.download_file(l_final_file);',
'    apex_application.stop_apex_engine;',
'  end if;',
'exception',
'  -- this is the exception thrown by stop_apex_engine',
'  -- catching it here so it won''t be handled by the others handlers',
'  when apex_application.e_stop_apex_engine then',
'    raise;',
'  when others then',
'    -- delete the collection in case the error occurred between opening and closing it',
'    if apex_collection.collection_exists(c_collection_name)',
'    then',
'        apex_collection.delete_collection(c_collection_name);',
'    end if;',
'    -- always close the context in case of an error',
'    apex_exec.close(l_context);',
'    raise;',
'end download_files;',
'',
'--------------------------------------------------------------------------------',
'-- Main plug-in render function',
'--------------------------------------------------------------------------------',
'function render',
'  ( p_dynamic_action apex_plugin.t_dynamic_action',
'  , p_plugin         apex_plugin.t_plugin',
'  )',
'return apex_plugin.t_dynamic_action_render_result',
'as',
'  l_result apex_plugin.t_dynamic_action_render_result;',
'',
'  --general attributes',
'  l_ajax_identifier          varchar2(4000)                     := apex_plugin.get_ajax_identifier;',
'  l_static_id                varchar2(4000)                     := nvl(p_dynamic_action.attribute_07, p_dynamic_action.id);',
'  l_suppress_errors          boolean                            := (p_dynamic_action.attribute_15 like ''%suppress-error-messages%'');',
'  l_content_disposition      p_dynamic_action.attribute_09%type := nvl(p_dynamic_action.attribute_09, ''download'');',
'  ',
'  -- spinner settings',
'  l_show_spinner             boolean                            := instr(p_dynamic_action.attribute_15, ''show-spinner'') > 0;',
'  l_show_spinner_overlay     boolean                            := instr(p_dynamic_action.attribute_15, ''show-spinner-overlay'') > 0;',
'  l_show_spinner_on_region   boolean                            := instr(p_dynamic_action.attribute_15, ''spinner-position'') > 0;',
'      ',
'  -- page items to submit settings',
'  l_items_to_submit          varchar2(4000)                    := apex_plugin_util.page_item_names_to_jquery(p_dynamic_action.attribute_05);',
'',
'  -- Javascript Initialization Code',
'  l_init_js_fn               varchar2(32767)                    := nvl(apex_plugin_util.replace_substitutions(p_dynamic_action.init_javascript_code), ''undefined'');',
'  ',
'begin',
'',
'  if apex_application.g_debug then',
'    apex_plugin_util.debug_dynamic_action',
'      ( p_dynamic_action => p_dynamic_action',
'      , p_plugin         => p_plugin',
'      );',
'  end if;        ',
'  ',
'  -- create a json object holding the dynamic action settings',
'  apex_json.initialize_clob_output;',
'  apex_json.open_object;',
'  apex_json.write(''id''                   , p_dynamic_action.id);',
'  apex_json.write(''staticId''             , l_static_id);',
'  apex_json.write(''ajaxIdentifier''       , l_ajax_identifier);',
'  apex_json.write(''itemsToSubmit''        , l_items_to_submit);',
'  apex_json.write(''suppressErrorMessages'', l_suppress_errors);    ',
'  apex_json.write(''previewMode''          , l_content_disposition = ''inline'');',
'  apex_json.write(''newWindow''            , l_content_disposition = ''window'');',
'',
'  apex_json.open_object(''spinnerSettings'');',
'  apex_json.write(''showSpinner''          , l_show_spinner);',
'  apex_json.write(''showSpinnerOverlay''   , l_show_spinner_overlay);',
'  apex_json.write(''showSpinnerOnRegion''  , l_show_spinner_on_region);',
'  apex_json.close_object;',
'',
'  -- close JSON settings',
'  apex_json.close_object;',
'',
'  -- defines the function that will be run each time the dynamic action fires',
'  l_result.javascript_function := ''function() { FOS.utils.download(this, ''|| apex_json.get_clob_output||'', ''||l_init_js_fn||''); }'';',
'  ',
'  apex_json.free_output;',
'  return l_result;',
'end;',
'',
'--------------------------------------------------------------------------------',
'-- Main plug-in AJAX function',
'--------------------------------------------------------------------------------',
'function ajax',
'  ( p_dynamic_action apex_plugin.t_dynamic_action',
'  , p_plugin         apex_plugin.t_plugin',
'  )',
'return apex_plugin.t_dynamic_action_ajax_result',
'as',
'  -- error handling',
'  l_apex_error               apex_error.t_error;',
'  l_result                   apex_error.t_error_result;',
'  ',
'  -- return type',
'  l_return                   apex_plugin.t_dynamic_action_ajax_result;',
'  ',
'  --general attributes',
'  l_ajax_identifier          varchar2(4000)                     := replace(coalesce(apex_application.g_request, apex_plugin.get_ajax_identifier), ''PLUGIN='', '''');',
'  l_static_id                varchar2(4000)                     := nvl(p_dynamic_action.attribute_07, p_dynamic_action.id);',
'  l_suppress_errors          boolean                            := (p_dynamic_action.attribute_15 like ''%suppress-error-messages%'');',
'  l_content_disposition      p_dynamic_action.attribute_09%type := nvl(p_dynamic_action.attribute_09, ''download'');',
'  ',
'  -- preview mode, we can alos download the file in preview mode so we need to be able to switch the download type dynamically (settings are static)',
'  l_preview_download         varchar2(255)                      := nvl(apex_application.g_x02, ''NO'');',
'  l_preview_mode             boolean                            := case when l_preview_download = ''YES'' then false else l_content_disposition = ''inline'' end;',
'  l_preview_new_window       boolean                            := case when l_preview_download = ''YES'' then false else l_content_disposition = ''window'' end;',
'  ',
'  -- preview settings',
'  l_prv_close_on_escape      boolean                            := instr(p_dynamic_action.attribute_10, ''close-on-escape'')           > 0;',
'  l_prv_draggable            boolean                            := instr(p_dynamic_action.attribute_10, ''draggable'')                 > 0;',
'  l_prv_modal                boolean                            := instr(p_dynamic_action.attribute_10, ''modal'')                     > 0;',
'  l_prv_resizable            boolean                            := instr(p_dynamic_action.attribute_10, ''resizable'')                 > 0;',
'  l_prv_show_file_info       boolean                            := instr(p_dynamic_action.attribute_10, ''show-file-info'')            > 0;   ',
'  l_prv_show_download_btn    boolean                            := instr(p_dynamic_action.attribute_10, ''show-download-button'')      > 0; ',
'  l_prv_custom_file_info_tpl boolean                            := instr(p_dynamic_action.attribute_10, ''custom-file-info-template'') > 0;   ',
'  ',
'  l_prv_file_info_template   p_dynamic_action.attribute_12%type := p_dynamic_action.attribute_12;',
'  l_prv_title                p_dynamic_action.attribute_11%type := p_dynamic_action.attribute_11;',
'',
'  -- spinner settings',
'  l_show_spinner             boolean                            := instr(p_dynamic_action.attribute_15, ''show-spinner'')              > 0;',
'  l_show_spinner_overlay     boolean                            := instr(p_dynamic_action.attribute_15, ''show-spinner-overlay'')      > 0;',
'  l_show_spinner_on_region   boolean                            := instr(p_dynamic_action.attribute_15, ''spinner-position'')          > 0;',
'      ',
'  -- page items to submit settings',
'  l_items_to_submit          varchar2(4000)                     := apex_plugin_util.page_item_names_to_jquery(p_dynamic_action.attribute_05);',
'',
'  -- Javascript Initialization Code',
'  l_init_js_fn               varchar2(32767)                    := nvl(apex_plugin_util.replace_substitutions(p_dynamic_action.init_javascript_code), ''undefined'');',
'  ',
'  ',
'  function get_preview_url',
'  return varchar2',
'  as',
'',
'  begin',
'',
'    return ''wwv_flow.show?p_flow_id=''||v(''app_id'')||''&p_flow_step_id=''||v(''app_page_id'')||''&p_instance=''||v(''app_session'')||',

'           ''&p_debug=''||v(''debug'')||''&p_request=PLUGIN=''||l_ajax_identifier||''&p_widget_name=''||p_plugin.name||''&p_widget_action=''||c_download_request||',
'           ''&x02=''||apex_application.g_x02||''&x10=''||apex_application.g_x10;',
'',
'  end get_preview_url;    ',
'begin',
'  -- standard debugging intro, but only if necessary',
'  if apex_application.g_debug',
'  then',
'    apex_plugin_util.debug_dynamic_action',
'      ( p_plugin         => p_plugin',
'      , p_dynamic_action => p_dynamic_action',
'      );',
'  end if;    ',
'',
'  if apex_application.g_widget_action = c_download_request then',
'    --',
'    -- Hand off to our download routine',
'    --',
'    download_files',
'      ( p_dynamic_action   => p_dynamic_action',
'      , p_plugin           => p_plugin',
'      , p_preview_download => apex_application.g_x02 = ''YES''',
'      );',
'  else',
'    apex_json.open_object;',
'    apex_json.write(''status''                 , ''success'');',
'    apex_json.open_object(''data'');',
'    apex_json.write(''previewMode''            , l_preview_mode);',
'    if l_preview_mode or l_preview_new_window then',
'        -- settings for download button in preview dialog',
'        apex_json.write(''id''                 , p_dynamic_action.id);',
'        apex_json.write(''staticId''           , l_static_id);',
'        apex_json.write(''ajaxIdentifier''     , l_ajax_identifier);',
'        apex_json.write(''itemsToSubmit''      , l_items_to_submit);',
'        apex_json.write(''suppressErrorMessages'', l_suppress_errors);',
'',
'        -- preview settings',
'        apex_json.write(''previewSrc''         , get_preview_url);',
'        apex_json.write(''previewId''          , ''preview-''||apex_application.g_x01);',
'',
'        -- preview dialog settings',
'        apex_json.open_object(''previewOptions'');',
'        apex_json.write(''closeOnEscape''      , l_prv_close_on_escape);',
'        apex_json.write(''draggable''          , l_prv_draggable);',
'        apex_json.write(''modal''              , l_prv_modal);',
'        apex_json.write(''resizable''          , l_prv_resizable);',
'        apex_json.write(''showFileInfo''       , l_prv_show_file_info);',
'        apex_json.write(''showDownloadBtn''    , l_prv_show_download_btn);',
'        apex_json.write(''title''              , l_prv_title);',
'        if l_prv_custom_file_info_tpl then',
'            apex_json.write(''fileInfoTpl''    , l_prv_file_info_template);',
'        end if;',
'        ',
'        apex_json.close_object;',
'',
'        -- spinner settings',
'        apex_json.open_object(''spinnerSettings'');',
'        apex_json.write(''showSpinner''        , l_show_spinner);',
'        apex_json.write(''showSpinnerOverlay'' , l_show_spinner_overlay);',
'        apex_json.write(''showSpinnerOnRegion'', l_show_spinner_on_region);',
'        apex_json.close_object;',
'      end if;',
'      apex_json.write(''formId''                 , ''form-''||apex_application.g_x01);',
'      apex_json.write(''iframeId''               , ''iframe-''||apex_application.g_x01);',
'      apex_json.write(''appId''                  , v(''APP_ID''));',
'      apex_json.write(''pageId''                 , v(''APP_PAGE_ID''));',
'      apex_json.write(''sessionId''              , v(''APP_SESSION''));',
'      apex_json.write(''debug''                  , v(''DEBUG''));',
'      apex_json.write(''request''                , l_ajax_identifier);',
'      apex_json.write(''widgetName''             , p_plugin.name);',
'      apex_json.write(''action''                 , c_download_request);',
'      apex_json.write(''previewDownload''        , l_preview_download);',
'      apex_json.close_object;',
'      apex_json.close_object;',
'    end if;',
'    ',
'    return l_return;',
'    ',
'exception',
'    -- this is the exception thrown by stop_apex_engine',
'    -- we catch it here because we are catching all errors',
'    -- but we allow/ignore the stop engine error',
'    when apex_application.e_stop_apex_engine then',
'      return l_return;',
'    -- for any other error we must return an error message',
'    when others then',
'      apex_json.initialize_output;',
'      l_apex_error.message             := sqlerrm;',
'      --l_apex_error.additional_info     := ;',
'      --l_apex_error.display_location    := ;',
'      --l_apex_error.association_type    := ;',
'      --l_apex_error.page_item_name      := ;',
'      --l_apex_error.region_id           := ;',
'      --l_apex_error.column_alias        := ;',
'      --l_apex_error.row_num             := ;',
'      --l_apex_error.is_internal_error   := ;',
'      --l_apex_error.apex_error_code     := ;',
'      l_apex_error.ora_sqlcode         := sqlcode;',
'      l_apex_error.ora_sqlerrm         := sqlerrm;',
'      l_apex_error.error_backtrace     := dbms_utility.format_error_backtrace;',
'      --l_apex_error.component           := ;',
'      --',
'      l_result := error_function_callback(l_apex_error);',
'',
'      apex_json.open_object;',
'      apex_json.write(''status'' , ''error'');',
'      apex_json.write(''message''         , l_result.message);',
'      apex_json.write(''additional_info'' , l_result.additional_info);',
'      apex_json.write(''display_location'', l_result.display_location);',
'      apex_json.write(''page_item_name''  , l_result.page_item_name);',
'      apex_json.write(''column_alias''    , l_result.column_alias);',
'      apex_json.close_object; ',
'      return l_return;',
'end ajax;'))
,p_api_version=>2
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_execution_function=>'execution'
,p_standard_attributes=>'ITEM:BUTTON:REGION:JQUERY_SELECTOR:JAVASCRIPT_EXPRESSION:TRIGGERING_ELEMENT:WAIT_FOR_RESULT:INIT_JAVASCRIPT_CODE'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Use the <strong>FOS - Download File(s)</strong> dynamic-action plug-in to start the browser download of files stored in the database. The files can be compiled via a SQL query or procedurally in a PL/SQL code block. If multiple files are returned,'
||' they will be zipped automatically. A single file can optionally be zipped as well. The files can be BLOBs or CLOBs.</p>',
'<p>The plug-in supports "Wait for Result" so you can continue following actions once the file has been downloaded, or listen to the download completed event to perform further actions.</p>'))
,p_version_identifier=>'20.1.1'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'@fos-auto-return-to-page',
'@fos-auto-open-files:js/script.js'))
,p_files_version=>665
);
end;
/
begin
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61118228573994412)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Source Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'sql'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Choose how you wish to compile the list of files to download.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(61118582489994414)
,p_plugin_attribute_id=>wwv_flow_api.id(61118228573994412)
,p_display_sequence=>10
,p_display_value=>'SQL Query'
,p_return_value=>'sql'
,p_help_text=>'<p>The files should be based on a SQL query.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(61119039500994415)
,p_plugin_attribute_id=>wwv_flow_api.id(61118228573994412)
,p_display_sequence=>20
,p_display_value=>'PL/SQL Code'
,p_return_value=>'plsql'
,p_help_text=>'<p>The files should procedurally be added to an APEX collection in a PL/SQL code block.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61119595760994416)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'SQL Query'
,p_attribute_type=>'SQL'
,p_is_required=>true
,p_sql_min_column_count=>3
,p_sql_max_column_count=>4
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(61118228573994412)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'sql'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre>',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , blob_content as file_content_blob',
'  from some_table',
'</pre>',
'<pre>',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , clob_content as file_content_clob',
'  from some_table',
'</pre>',
'<pre>',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , blob_content as file_content_blob',
'     , null         as file_content_clob',
'  from some_table',
'',
' union all',
'',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , null         as file_content_blob',
'     , clob_content as file_content_clob',
'  from some_table',
'</pre>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Provide the SQL query source for the files to be downloaded.</p>',
'<p>Columns <strong><code>file_name</code></strong> and <strong><code>file_mime_type</code></strong> are mandatory. Additionally, either <strong><code>file_content_blob</code></strong> or <strong><code>file_content_clob</code></strong> must be provide'
||'d. If both are provided, the first non-null one will be picked. This allows you to mix and match files from various sources.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61119953669994416)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'PL/SQL Code'
,p_attribute_type=>'PLSQL'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(61118228573994412)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'plsql'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre>',
'apex_collection.add_member',
'    ( p_collection_name => ''FOS_DOWNLOAD_FILES''',
'    , p_c001            => ''README.md''',
'    , p_c002            => ''text/plain''',
'    , p_clob001         => ''This zip contains *all* application files!''',
'    );',
'',
'for f in (',
'    select *',
'      from apex_application_static_files',
'     where application_id = :APP_ID',
') loop',
'    apex_collection.add_member',
'        ( p_collection_name => ''FOS_DOWNLOAD_FILES''',
'        , p_c001            => f.file_name',
'        , p_c002            => f.mime_type',
'        , p_blob001         => f.file_content',
'        );',
'end loop;',
'',
'-- pro tip: you can override the zip file name by assigning it to the apex_application.g_x01 global variable',
'apex_application.g_x01 := ''all_files.zip'';',
'</pre>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Provide the PL/SQL code block that compiles the files to be downloaded.</p>',
'<p>The files should be added one by one to the <strong><code>FOS_DOWNLOAD_FILES</code></strong> collection via the <code>apex_collection</code> API.</p>',
'<p>This special collection will be created and removed automatically.</p>',
'<p>Parameter <strong><code>p_c001</code></strong> is the file name, <strong><code>p_c002</code></strong> is the mime_type, <strong><code>p_blob001</code></strong> is the BLOB source and <strong><code>p_clob001</code></strong> is the CLOB source. <cod'
||'e>p_c001</code> and <code>p_c002</code> are both mandatory, and either <code>p_blob001</code> or <code>p_clob001</code> must be provided as well.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61120378541994416)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Zip File Name'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
,p_examples=>'<code>db_files_export.zip</code>'
,p_help_text=>'<p>Enter the zip file name to be used in case multiple files are returned.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61161989117308568)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>35
,p_prompt=>'Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Enter the uppercase page items submitted to the server, and therefore, available for use within your <strong>PL/SQL Code</strong>.</p>',
'<p>You can type in the item name or pick from the list of available items.',
'If you pick from the list and there is already text entered then a comma is placed at the end of the existing text, followed by the item name returned from the list.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61402249969974901)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>160
,p_prompt=>'PL/SQL (Executed Before Download)'
,p_attribute_type=>'PLSQL'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'execute-plsql'
,p_help_text=>'<p>Enter the PL/SQL code you would like to execute just prior to the download e.g. perhaps you want to track the download count in a table etc.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61589375293042965)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>170
,p_prompt=>'Static ID'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_unit=>'(no spaces or punctuation)'
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Enter the static ID which you would like to identify this particular download which can be used within a dynamic action client-side condition when listening to the plug-in events e.g.</p>',
'<pre>this.data.staticId === ''MY_UNIQUE_ID''</pre>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(62386938406324701)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>5
,p_prompt=>'File Mode'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'attachment'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Select the file mode, you currently have 2 options:</p>',
'<ul>',
'<li>Download - the file will be downloaded as an attachment</li>',
'<li>Preview - the file will be downloaded and shown inline in a modal dialog</li>',
'<li>New Window - the file will be downloaded and shown in a new browser window/tab (depends on the browser implementation for window.open)</li>',
'</ul>'))
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(62387216341325455)
,p_plugin_attribute_id=>wwv_flow_api.id(62386938406324701)
,p_display_sequence=>10
,p_display_value=>'Download'
,p_return_value=>'attachment'
,p_help_text=>'<p>Download the file to the file system</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(62387645742326461)
,p_plugin_attribute_id=>wwv_flow_api.id(62386938406324701)
,p_display_sequence=>20
,p_display_value=>'Preview'
,p_return_value=>'inline'
,p_help_text=>'<p>Preview the file in a dialog window. <strong>Note:</strong> only a limited number of file types are supported e.g. text files, images, and PDF files. If the file cannot be previewed a warning message will be shown. You still have the option to dow'
||'nload a file when using preview mode.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(64069565268462178)
,p_plugin_attribute_id=>wwv_flow_api.id(62386938406324701)
,p_display_sequence=>30
,p_display_value=>'Preview in New Window'
,p_return_value=>'window'
,p_help_text=>'<p>Preview the file in a new browser window/tab. <strong>Note:</strong> only a limited number of file types are supported e.g. text files, images, and PDF files. If the file cannot be previewed a it will be automatically downloaded instead.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(64065407992382037)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>7
,p_prompt=>'Preview Options'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'close-on-escape:draggable:modal:resizable:show-file-info:show-download-button'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(62386938406324701)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'inline'
,p_lov_type=>'STATIC'
,p_help_text=>'<p>When previewing a file you have a number of settings you can customize.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(64067813590410277)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>10
,p_display_value=>'Close on Escape'
,p_return_value=>'close-on-escape'
,p_help_text=>'<p>Check this option to close the dialog window when the "ESC" key is pressed.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(65500507915726212)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>20
,p_display_value=>'Custom File Info Tooltip Template'
,p_return_value=>'custom-file-info-template'
,p_help_text=>'<p>Check this option if you would like to override the default file information tooltip e.g. if you want to translate the English labels.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(64067429593407459)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>30
,p_display_value=>'Draggable'
,p_return_value=>'draggable'
,p_help_text=>'<p>Check this option to allow the user to be able to drag the window around and reposition it.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(64067013655405225)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>40
,p_display_value=>'Modal'
,p_return_value=>'modal'
,p_help_text=>'<p>Check this option to make the preview dialog window modal.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(64068247545414180)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>50
,p_display_value=>'Resizable'
,p_return_value=>'resizable'
,p_help_text=>'<p>Check this option to allow the user to resize the preview dialog window.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(65001800794112895)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>60
,p_display_value=>'Show Download Button'
,p_return_value=>'show-download-button'
,p_help_text=>'<p>Check this option to show a download button that allows the user to download the file from within the preview window/dialog.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(64068637601417242)
,p_plugin_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_display_sequence=>70
,p_display_value=>'Show File Info'
,p_return_value=>'show-file-info'
,p_help_text=>'<p>Check this option to show a button that will show the file information within a tooltip on button click.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(64069250834459315)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>8
,p_prompt=>'Preview Title'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_default_value=>'File Preview'
,p_is_translatable=>true
,p_depending_on_attribute_id=>wwv_flow_api.id(62386938406324701)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'inline'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Enter the name of the dialog title. This setting is translatable.</p>',
'<p><strong>Note:</strong> if you would like to change the preview title and message when a file cannot be previewed you can create the following text messages for your application language(s)</p>',
'<pre>',
'FOS.DOWNLOAD.PREVIEW_NA.TITLE',
'FOS.DOWNLOAD.PREVIEW_NA.MESSAGE',
'</pre>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(65029838703125676)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>9
,p_prompt=>'File Info Tooltip Template'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_default_value=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<strong>Name:</strong> #NAME#<br />',
'<strong>Size:</strong> #SIZE#<br />',
'<strong>Mime Type:</strong> #MIME_TYPE#'))
,p_is_translatable=>true
,p_depending_on_attribute_id=>wwv_flow_api.id(64065407992382037)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'custom-file-info-template'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>You can provide a custom HTML template for the file information button. The following substitutions are supported:</p>',
'<ul>',
'<li><strong>#NAME#</strong> - the file name</li>',
'<li><strong>#SIZE#</strong> - the file size (it is already pre-formatted)</li>',
'<li><strong>#MIME_TYPE#</strong> - the file mime type e.g. image/png</li>',
'</ul>',
'<p><strong>Note:</strong> The default template is:</p>',
'<pre>',
'<strong>Name:</strong> #NAME#<br />',
'<strong>Size:</strong> #SIZE#<br />',
'<strong>Mime Type:</strong> #MIME_TYPE#',
'</pre>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(61120708539994417)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>150
,p_prompt=>'Extra Options'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Choose from the following available options:</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(61121176841994417)
,p_plugin_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_display_sequence=>10
,p_display_value=>'Always Zip'
,p_return_value=>'always-zip'
,p_help_text=>'If the result set contains multiple files they will always be zipped. By default, if the result set contains only one file, it will not be zipped. Choose this option if a single file should be zipped as well.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(61401864119964733)
,p_plugin_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_display_sequence=>20
,p_display_value=>'Execute PL/SQL Prior to Download'
,p_return_value=>'execute-plsql'
,p_help_text=>'<p>Check this option to run some PL/SQL code e.g. to track download counts. <strong>Note:</strong> it will be wrapped in an autonomous transaction and automatically committed or rolled back if an exception is detected.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(62293874255024836)
,p_plugin_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_display_sequence=>50
,p_display_value=>'Show Spinner/Processing Icon'
,p_return_value=>'show-spinner'
,p_help_text=>'<p>Check this option if you want to have a Spinner/Processing Icon to be displayed while waiting the execution to complete.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(62294295936027888)
,p_plugin_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_display_sequence=>60
,p_display_value=>'Show Spinner with Modal Overlay Mask'
,p_return_value=>'show-spinner-overlay'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Shows the spinner with a modal overlay stopping the user from interacting with the content behind the overlay mask.</p>',
'<p><strong>Note:</strong> this setting has no effect if you do not check "Show Spinner"</p>'))
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(62294603492030359)
,p_plugin_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_display_sequence=>70
,p_display_value=>'Show Spinner on Region'
,p_return_value=>'spinner-position'
,p_help_text=>'<p>Check this option to only show the spinner on a particular region. If you do not check this option then it will be shown at the page level. If you have also checked the "Show Spinner Overlay Mask" it will only mask the region you have defined in t'
||'he "Affected Elements".</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(61929577894845313)
,p_plugin_attribute_id=>wwv_flow_api.id(61120708539994417)
,p_display_sequence=>80
,p_display_value=>'Suppress Error Messages'
,p_return_value=>'suppress-error-messages'
,p_help_text=>'<p>Select "Yes" to hide any notification messages when errors are encountered downloading the file. You would most likely only check this option when you want to display your own custom error notifications.</p>'
);
wwv_flow_api.create_plugin_std_attribute(
 p_id=>wwv_flow_api.id(61192244012541914)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_name=>'INIT_JAVASCRIPT_CODE'
,p_is_required=>false
,p_depending_on_has_to_exist=>true
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<h3>Changing the Preview Dialog Settings</h3>',
'<p>You may want to change the preview dialog height/width or whether it''s modal e.g.</p>',
'<code>',
'function(options) {',
'   options.previewOptions = {',
'      height: ''800'',',
'      width: ''1020'',',
'      maxWidth: ''1500'',',
'      modal: false',
'   }',
'   return options;',
'}',
'</code>'))
,p_help_text=>'<p>You can use this attribute to define a function that will allow you to change/override the plugin settings. This gives you added flexibility of controlling the settings from a single Javascript function defined in an "Static Application File"</p>'
);
wwv_flow_api.create_plugin_event(
 p_id=>wwv_flow_api.id(62076093850886373)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_name=>'fos-download-file-complete'
,p_display_name=>'FOS - Download File(s) - File Downloaded'
);
wwv_flow_api.create_plugin_event(
 p_id=>wwv_flow_api.id(61466744463803501)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_name=>'fos-download-file-error'
,p_display_name=>'FOS - Download File(s) - Download Error'
);
wwv_flow_api.create_plugin_event(
 p_id=>wwv_flow_api.id(64663627013402236)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_name=>'fos-download-preview-complete'
,p_display_name=>'FOS - Download File(s) - Preview Downloaded'
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A20676C6F62616C732061706578202A2F0A0A76617220464F53203D2077696E646F772E464F53207C7C207B7D3B0A464F532E7574696C73203D2077696E646F772E464F532E7574696C73207C7C207B7D3B0A0A2F2A2A0A202A20546869732066756E';
wwv_flow_api.g_varchar2_table(2) := '6374696F6E20736574732075702074686520646F776E6C6F61642066696C652068616E646C6572204A6176617363726970740A202A0A202A2040706172616D207B6F626A6563747D2020206461436F6E7465787420202020202020202020202020202020';
wwv_flow_api.g_varchar2_table(3) := '20202020202044796E616D696320416374696F6E20636F6E746578742061732070617373656420696E20627920415045580A202A2040706172616D207B6F626A6563747D202020636F6E6669672020202020202020202020202020202020202020202020';
wwv_flow_api.g_varchar2_table(4) := '2020436F6E66696775726174696F6E206F626A65637420686F6C64696E672074686520646F776E6C6F61642066696C6520636F6E6669670A2A2F0A2866756E6374696F6E20282429207B0A0A0976617220646F776E6C6F616454696D657273203D207B7D';
wwv_flow_api.g_varchar2_table(5) := '3B0A0976617220646F776E6C6F61645370696E6E657273203D207B7D3B0A097661722066696C65496E666F203D207B7D3B0A0976617220617474656D707473203D207B7D3B0A0976617220464F524D5F505245464958203D2027666F726D2D273B0A0976';
wwv_flow_api.g_varchar2_table(6) := '617220494652414D455F505245464958203D2027696672616D652D273B0A0976617220505245564945575F505245464958203D2027707265766965772D273B0A0976617220544F4B454E5F505245464958203D2027464F53273B0A0A0966756E6374696F';
wwv_flow_api.g_varchar2_table(7) := '6E20636C65616E557028646F776E6C6F6164466E4E616D652C20707265766965774D6F646529207B0A0909766172207072657669657724203D202428272327202B20505245564945575F505245464958202B20646F776E6C6F6164466E4E616D65292C0A';
wwv_flow_api.g_varchar2_table(8) := '090909696672616D6524203D202428272327202B20494652414D455F505245464958202B20646F776E6C6F6164466E4E616D65292C0A090909666F726D24203D202428272327202B20464F524D5F505245464958202B20646F776E6C6F6164466E4E616D';
wwv_flow_api.g_varchar2_table(9) := '65293B0A0A090969662028747970656F6620646F776E6C6F61645370696E6E6572735B646F776E6C6F6164466E4E616D655D203D3D3D202266756E6374696F6E2229207B0A090909646F776E6C6F61645370696E6E6572735B646F776E6C6F6164466E4E';
wwv_flow_api.g_varchar2_table(10) := '616D655D28293B202F2F20746869732066756E6374696F6E2072656D6F76657320746865207370696E6E65720A09090964656C65746520646F776E6C6F61645370696E6E6572735B646F776E6C6F6164466E4E616D655D3B0A09097D0A09096966202866';
wwv_flow_api.g_varchar2_table(11) := '6F726D242920666F726D242E72656D6F766528293B0A0A09092F2F20576520646F6E27742072656D6F76652074686520707265766965772F696672616D6520696E2070726576696577206D6F646520666F72206F6276696F757320726561736F6E732069';
wwv_flow_api.g_varchar2_table(12) := '2E652E2061732074686579206172652076696577696E672069740A09096966202821707265766965774D6F646529207B0A09090969662028696672616D65242920696672616D65242E72656D6F766528293B0A0909096966202870726576696577242920';
wwv_flow_api.g_varchar2_table(13) := '70726576696577242E72656D6F766528293B0A09097D0A097D0A0A0966756E6374696F6E20736574437572736F7228656C242C207374796C6529207B0A09092F2F656C242E6373732822637572736F72222C207374796C65293B202F2F20776520686176';

wwv_flow_api.g_varchar2_table(14) := '652064697361626C6564207468697320666F72206E6F770A097D0A0A092F2F20436F6F6B69652068616E646C696E6720636F6D65732066726F6D3A2068747470733A2F2F737461636B6F766572666C6F772E636F6D2F7175657374696F6E732F31313036';
wwv_flow_api.g_varchar2_table(15) := '3337372F6465746563742D7768656E2D62726F777365722D72656365697665732D66696C652D646F776E6C6F61640A0966756E6374696F6E20676574436F6F6B6965286E616D6529207B0A0909766172207061727473203D20646F63756D656E742E636F';
wwv_flow_api.g_varchar2_table(16) := '6F6B69652E73706C6974286E616D65202B20223D22293B0A09096966202870617274732E6C656E677468203D3D2032292072657475726E207B206E616D653A206E616D652C2076616C75653A2070617274735B315D2E73706C697428223B22292E736869';
wwv_flow_api.g_varchar2_table(17) := '66742829207D3B0A097D0A0A0966756E6374696F6E20657870697265436F6F6B696528636F6F6B69654E616D6529207B0A0909646F63756D656E742E636F6F6B6965203D0A090909656E636F6465555249436F6D706F6E656E7428636F6F6B69654E616D';
wwv_flow_api.g_varchar2_table(18) := '6529202B20223D64656C657465643B20657870697265733D22202B206E657720446174652830292E746F555443537472696E6728293B0A097D0A0A092F2F20547261636B207768656E20776520726563656965766520636F6F6B69652066726F6D207468';
wwv_flow_api.g_varchar2_table(19) := '652073657276657220746F2064657465726D696E652066696C6520697320646F776E6C6F6164696E670A0966756E6374696F6E20747261636B446F776E6C6F616428636F6E6669672C20646F776E6C6F6164466E4E616D6529207B0A0909736574437572';
wwv_flow_api.g_varchar2_table(20) := '736F7228636F6E6669672E74726967676572696E67456C656D656E74242C20227761697422293B0A0909617474656D7074735B646F776E6C6F6164466E4E616D655D203D2033303B0A0909646F776E6C6F616454696D6572735B646F776E6C6F6164466E';
wwv_flow_api.g_varchar2_table(21) := '4E616D655D203D2077696E646F772E736574496E74657276616C2866756E6374696F6E202829207B0A09090976617220746F6B656E203D20676574436F6F6B696528646F776E6C6F6164466E4E616D65293B0A0A0909096966202828746F6B656E202626';
wwv_flow_api.g_varchar2_table(22) := '20746F6B656E2E6E616D65203D3D20646F776E6C6F6164466E4E616D6529207C7C2028617474656D7074735B646F776E6C6F6164466E4E616D655D203D3D20302929207B0A0909090969662028746F6B656E29207B0A0909090909636F6E6669672E6669';
wwv_flow_api.g_varchar2_table(23) := '6C65496E666F203D204A534F4E2E706172736528746F6B656E2E76616C7565293B0A090909090966696C65496E666F5B646F776E6C6F6164466E4E616D655D203D20636F6E6669672E66696C65496E666F3B0A090909097D0A0909090973746F70547261';
wwv_flow_api.g_varchar2_table(24) := '636B696E67446F776E6C6F616428636F6E6669672C20646F776E6C6F6164466E4E616D65293B0A0909097D0A0A090909617474656D7074735B646F776E6C6F6164466E4E616D655D2D2D3B0A09097D2C2031303030293B0A0A090972657475726E20646F';
wwv_flow_api.g_varchar2_table(25) := '776E6C6F6164466E4E616D653B0A097D0A0A0966756E6374696F6E2073746F70547261636B696E67446F776E6C6F616428636F6E6669672C20646F776E6C6F6164466E4E616D6529207B0A0909766172206576656E744E616D65203D2028636F6E666967';
wwv_flow_api.g_varchar2_table(26) := '2E707265766965774D6F646529203F2027666F732D646F776E6C6F61642D707265766965772D636F6D706C65746527203A2027666F732D646F776E6C6F61642D66696C652D636F6D706C657465273B0A0909636C65616E557028646F776E6C6F6164466E';
wwv_flow_api.g_varchar2_table(27) := '4E616D652C20636F6E6669672E707265766965774D6F6465293B0A090977696E646F772E636C656172496E74657276616C28646F776E6C6F616454696D6572735B646F776E6C6F6164466E4E616D655D293B0A0909657870697265436F6F6B696528646F';
wwv_flow_api.g_varchar2_table(28) := '776E6C6F6164466E4E616D65293B0A090964656C65746520646F776E6C6F616454696D6572735B646F776E6C6F6164466E4E616D655D3B0A090964656C65746520617474656D7074735B646F776E6C6F6164466E4E616D655D3B0A090969662028636F6E';
wwv_flow_api.g_varchar2_table(29) := '6669672E66696C65496E666F29207B0A090909617065782E6576656E742E7472696767657228646F63756D656E742E626F64792C206576656E744E616D652C20636F6E666967293B0A09090964656C65746520636F6E6669672E66696C65496E666F3B0A';
wwv_flow_api.g_varchar2_table(30) := '09097D0A0909736574437572736F7228636F6E6669672E74726967676572696E67456C656D656E74242C2027706F696E74657227293B0A097D0A0A092F2F204D61696E20706C75672D696E20656E74727920706F696E740A09464F532E7574696C732E64';
wwv_flow_api.g_varchar2_table(31) := '6F776E6C6F6164203D2066756E6374696F6E20286461436F6E746578742C206F7074696F6E732C20696E6974466E29207B0A090976617220636F6E6669672C20706C7567696E4E616D65203D2027464F53202D20446F776E6C6F61642046696C65287329';
wwv_flow_api.g_varchar2_table(32) := '272C0A0909096D65203D20746869732C0A090909646F776E6C6F6164466E4E616D65203D20676574446F776E6C6F61644964286F7074696F6E732E6964292C0A0909096166456C656D656E7473203D206461436F6E746578742E6166666563746564456C';
wwv_flow_api.g_varchar2_table(33) := '656D656E74732C0A09090974726967676572696E67456C656D656E74203D206461436F6E746578742E74726967676572696E67456C656D656E743B0A0A0909636F6E666967203D20242E657874656E64287B7D2C206F7074696F6E73293B0A0A09096170';
wwv_flow_api.g_varchar2_table(34) := '65782E64656275672E696E666F28706C7567696E4E616D652C20636F6E666967293B0A0A090966756E6374696F6E20676574446F776E6C6F6164496428696429207B0A09090972657475726E20544F4B454E5F505245464958202B206964202B206E6577';
wwv_flow_api.g_varchar2_table(35) := '204461746528292E67657454696D6528293B0A09097D0A0A09092F2F2067656E657261746520612064796E616D696320666F726D2077697468206F75722066696C6520646F776E6C6F616420636F6E7465787420696E666F0A090966756E6374696F6E20';
wwv_flow_api.g_varchar2_table(36) := '676574466F726D54706C286461746129207B0A09090972657475726E20273C666F726D20616374696F6E3D227777765F666C6F772E73686F7722206D6574686F643D22706F73742220656E63747970653D226D756C7469706172742F666F726D2D646174';
wwv_flow_api.g_varchar2_table(37) := '61222069643D2227202B20646174612E666F726D4964202B202722207461726765743D2227202B20646174612E696672616D654964202B202722206F6E6C6F61643D22223E27202B0A09090909273C696E70757420747970653D2268696464656E22206E';
wwv_flow_api.g_varchar2_table(38) := '616D653D22705F666C6F775F6964222076616C75653D2227202B20646174612E6170704964202B2027222069643D2270466C6F7749643222202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22705F666C6F';
wwv_flow_api.g_varchar2_table(39) := '775F737465705F6964222076616C75653D2227202B20646174612E706167654964202B2027222069643D2270466C6F775374657049643222202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22705F696E73';
wwv_flow_api.g_varchar2_table(40) := '74616E6365222076616C75653D2227202B20646174612E73657373696F6E4964202B2027222069643D2270496E7374616E63653222202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22705F726571756573';
wwv_flow_api.g_varchar2_table(41) := '74222076616C75653D22504C5547494E3D27202B20646174612E72657175657374202B2027222069643D2270526571756573743222202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22705F646562756722';
wwv_flow_api.g_varchar2_table(42) := '2076616C75653D2227202B2028646174612E6465627567207C7C20272729202B2027222069643D227044656275673222202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22705F7769646765745F6E616D65';
wwv_flow_api.g_varchar2_table(43) := '222076616C75653D2227202B2028646174612E7769646765744E616D65207C7C20272729202B2027222069643D22705769646765744E616D653222202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22705F';
wwv_flow_api.g_varchar2_table(44) := '7769646765745F616374696F6E222076616C75653D2227202B2028646174612E616374696F6E207C7C20272729202B2027222069643D2270576964676574416374696F6E3222202F3E27202B0A09090909273C696E70757420747970653D226869646465';
wwv_flow_api.g_varchar2_table(45) := '6E22206E616D653D22705F7769646765745F616374696F6E5F6D6F64222076616C75653D2227202B2028646174612E616374696F6E4D6F64207C7C20272729202B2027222069643D2270576964676574416374696F6E4D6F643222202F3E27202B0A0909';
wwv_flow_api.g_varchar2_table(46) := '0909273C696E70757420747970653D2268696464656E22206E616D653D22783031222076616C75653D2227202B2028646174612E783031207C7C20272729202B2027222069643D2278303122202F3E27202B0A09090909273C696E70757420747970653D';
wwv_flow_api.g_varchar2_table(47) := '2268696464656E22206E616D653D22783032222076616C75653D2227202B2028646174612E70726576696577446F776E6C6F6164207C7C20274E4F2729202B2027222069643D2278303222202F3E27202B0A09090909273C696E70757420747970653D22';
wwv_flow_api.g_varchar2_table(48) := '68696464656E22206E616D653D22783033222076616C75653D2227202B2028646174612E783033207C7C20272729202B2027222069643D2278303322202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D2278';
wwv_flow_api.g_varchar2_table(49) := '3034222076616C75653D2227202B2028646174612E783034207C7C20272729202B2027222069643D2278303422202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22783035222076616C75653D2227202B20';
wwv_flow_api.g_varchar2_table(50) := '28646174612E783035207C7C20272729202B2027222069643D2278303522202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22783036222076616C75653D2227202B2028646174612E783036207C7C202727';
wwv_flow_api.g_varchar2_table(51) := '29202B2027222069643D2278303622202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22783037222076616C75653D2227202B2028646174612E783037207C7C20272729202B2027222069643D2278303722';
wwv_flow_api.g_varchar2_table(52) := '202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D22783038222076616C75653D2227202B2028646174612E783038207C7C20272729202B2027222069643D2278303822202F3E27202B0A09090909273C696E';
wwv_flow_api.g_varchar2_table(53) := '70757420747970653D2268696464656E22206E616D653D22783039222076616C75653D2227202B2028646174612E783039207C7C20272729202B2027222069643D2278303922202F3E27202B0A09090909273C696E70757420747970653D226869646465';
wwv_flow_api.g_varchar2_table(54) := '6E22206E616D653D22783130222076616C75653D2227202B2028646174612E746F6B656E207C7C20272729202B2027222069643D2278313022202F3E27202B0A09090909273C696E70757420747970653D2268696464656E22206E616D653D2266313022';
wwv_flow_api.g_varchar2_table(55) := '2076616C75653D2227202B2028646174612E663130207C7C20272729202B2027222069643D2266313022202F3E27202B0A09090909273C2F666F726D3E273B0A09097D0A0A09092F2F2067656E657261746520612064796E616D696320696672616D6520';
wwv_flow_api.g_varchar2_table(56) := '6261736564206F6E206F757220646F776E6C6F616420636F6E7465787420696E666F20616E642070726F76696465206120756E69717565206F6E6C6F61642068616E646C65722066756E6374696F6E0A090966756E6374696F6E20676574496672616D65';
wwv_flow_api.g_varchar2_table(57) := '54706C28636F6E6669672C20646F776E6C6F6164466E4E616D6529207B0A0909097661722074706C3B0A09090969662028636F6E6669672E707265766965774D6F646529207B0A0909090974706C203D20273C696672616D652069643D2227202B20636F';
wwv_flow_api.g_varchar2_table(58) := '6E6669672E696672616D654964202B202722206E616D653D2227202B20636F6E6669672E696672616D654964202B2027222077696474683D223130302522206865696768743D223130302522207374796C653D226D696E2D77696474683A203935253B68';
wwv_flow_api.g_varchar2_table(59) := '65696768743A313030253B22207363726F6C6C696E673D226175746F2220636C6173733D22666F732D707265766965772D6D6F646520752D68696464656E22206F6E6C6F61643D22464F532E7574696C732E646F776E6C6F61642E27202B20646F776E6C';
wwv_flow_api.g_varchar2_table(60) := '6F6164466E4E616D65202B2027287468697329223E3C2F696672616D653E273B0A0909097D20656C7365207B0A0909090974706C203D20273C696672616D652069643D2227202B20636F6E6669672E696672616D654964202B202722206E616D653D2227';
wwv_flow_api.g_varchar2_table(61) := '202B20636F6E6669672E696672616D654964202B20272220636C6173733D22752D68696464656E22206F6E6C6F61643D22464F532E7574696C732E646F776E6C6F61642E27202B20646F776E6C6F6164466E4E616D65202B2027287468697329223E3C2F';
wwv_flow_api.g_varchar2_table(62) := '696672616D653E273B0A0909097D0A09090972657475726E2074706C3B0A09097D0A0A09092F2F20726567756C61722066696C6520646F776E6C6F61640A090966756E6374696F6E206174746163686D656E74446F776E6C6F616428666F726D44617461';
wwv_flow_api.g_varchar2_table(63) := '29207B0A09090976617220666F726D54706C2C20696672616D6554706C2C20666F726D2C20696672616D65242C0A0909090963616E63656C526573756D65203D2066616C73653B0A0A090909666F726D446174612E74726967676572696E67456C656D65';
wwv_flow_api.g_varchar2_table(64) := '6E7424203D20242874726967676572696E67456C656D656E74293B0A090909666F726D446174612E746F6B656E203D20747261636B446F776E6C6F616428666F726D446174612C20646F776E6C6F6164466E4E616D65293B0A090909666F726D54706C20';
wwv_flow_api.g_varchar2_table(65) := '3D20676574466F726D54706C28666F726D44617461293B0A090909696672616D6554706C203D20676574496672616D6554706C28666F726D446174612C20646F776E6C6F6164466E4E616D65293B0A0A090909696620282428272327202B20666F726D44';
wwv_flow_api.g_varchar2_table(66) := '6174612E666F726D4964292E6C656E67746829207B0A090909092428272327202B20666F726D446174612E666F726D4964292E72656D6F766528290A0909097D0A090909666F726D203D202428646F63756D656E742E626F6479292E617070656E642866';
wwv_flow_api.g_varchar2_table(67) := '6F726D54706C29202626202428272327202B20666F726D446174612E666F726D4964295B305D3B0A090909696672616D6524203D202428272327202B20666F726D446174612E696672616D654964293B0A09090969662028696672616D65242E6C656E67';
wwv_flow_api.g_varchar2_table(68) := '7468203D3D3D203029207B0A090909092428646F63756D656E742E626F6479292E617070656E6428696672616D6554706C293B0A0909097D20656C7365207B0A09090909696672616D65242E6174747228276F6E6C6F6164272C2027464F532E7574696C';
wwv_flow_api.g_varchar2_table(69) := '732E646F776E6C6F61642E27202B20646F776E6C6F6164466E4E616D65202B202728746869732927293B0A0909097D0A0909092F2F207375626D6974206F757220666F726D20746F20646F776E6C6F6164207468652066696C650A09090969662028666F';
wwv_flow_api.g_varchar2_table(70) := '726D20262620666F726D2E7375626D697429207B0A09090909666F726D2E7375626D697428293B0A0909097D20656C7365207B0A0909090963616E63656C526573756D65203D20747275653B0A0909097D0A0909092F2F20746869732069732072657175';
wwv_flow_api.g_varchar2_table(71) := '6972656420666F72207768656E20776520617265206F70656E696E67206D6F64616C206469616C6F67732C20666F722061637475616C2072656469726563747320746865207061676520756E6C6F616473206D616B696E67207468697320726564756E64';
wwv_flow_api.g_varchar2_table(72) := '616E740A09090969662028636F6E6669672E70726576696577446F776E6C6F616420213D20275945532729207B0A09090909617065782E64612E726573756D65286461436F6E746578742E726573756D6543616C6C6261636B2C2063616E63656C526573';
wwv_flow_api.g_varchar2_table(73) := '756D65293B0A0909097D0A09097D0A0A09092F2F2066696C65207072657669657720696E2061206469616C6F672077697468206F7074696F6E616C20646F776E6C6F616420627574746F6E0A090966756E6374696F6E2070726576696577496E4469616C';
wwv_flow_api.g_varchar2_table(74) := '6F6728636F6E66696729207B0A090909766172207072657669657724203D202428272327202B20636F6E6669672E707265766965774964292C0A09090909696672616D6524203D202428272327202B20636F6E6669672E696672616D654964292C0A0909';
wwv_flow_api.g_varchar2_table(75) := '090970726576696577427574746F6E73203D205B5D2C0A09090909707265766965774F7074696F6E73203D20636F6E6669672E707265766965774F7074696F6E733B0A0A0909092F2F20416C6C6F772074686520646576656C6F70657220746F20706572';
wwv_flow_api.g_varchar2_table(76) := '666F726D20616E79206C617374202863656E7472616C697A656429206368616E676573207573696E67204A61766173637269707420496E697469616C697A6174696F6E20436F64652073657474696E670A0909092F2F20696E206164646974696F6E2074';
wwv_flow_api.g_varchar2_table(77) := '6F206F757220706C7567696E20636F6E6669672077652077696C6C207061737320696E206120326E64206F626A65637420666F7220636F6E6669677572696E672074686520464F53206E6F74696669636174696F6E730A09090969662028696E6974466E';
wwv_flow_api.g_varchar2_table(78) := '20696E7374616E63656F662046756E6374696F6E29207B0A09090909696E6974466E2E63616C6C286461436F6E746578742C20636F6E666967293B0A0909097D0A0A09090966756E6374696F6E2067657446696C65496E666F2829207B0A090909097661';
wwv_flow_api.g_varchar2_table(79) := '722066696C6544657461696C73203D2066696C65496E666F5B646F776E6C6F6164466E4E616D655D3B0A0909090972657475726E202866696C6544657461696C7329203F2028707265766965774F7074696F6E732E66696C65496E666F54706C207C7C20';
wwv_flow_api.g_varchar2_table(80) := '273C7374726F6E673E4E616D653A3C2F7374726F6E673E20234E414D45233C6272202F3E27202B0A0909090909273C7374726F6E673E53697A653A3C2F7374726F6E673E202353495A45233C6272202F3E27202B0A0909090909273C7374726F6E673E4D';
wwv_flow_api.g_varchar2_table(81) := '696D6520547970653A3C2F7374726F6E673E20234D494D455F545950452327290A09090909092E7265706C616365282F5C234E414D455C232F2C2066696C6544657461696C732E6E616D65290A09090909092E7265706C616365282F5C2353495A455C23';
wwv_flow_api.g_varchar2_table(82) := '2F2C2066696C6544657461696C732E73697A65290A09090909092E7265706C616365282F5C234D494D455F545950455C232F2C2066696C6544657461696C732E6D696D6554797065290A09090909093A2028707265766965774F7074696F6E732E6C6F61';
wwv_flow_api.g_varchar2_table(83) := '64696E674D7367207C7C20275468652066696C6520696E666F726D6174696F6E206973207374696C6C206C6F6164696E672E2E2E2E27293B0A0909097D0A0A0909096966202870726576696577242E6C656E677468203D3D3D203029207B0A0909090924';
wwv_flow_api.g_varchar2_table(84) := '28646F63756D656E742E626F6479292E617070656E6428273C6469762069643D2227202B20636F6E6669672E707265766965774964202B2027223E27202B20676574496672616D6554706C28636F6E6669672C20646F776E6C6F6164466E4E616D652920';
wwv_flow_api.g_varchar2_table(85) := '2B20273C2F6469763E27293B0A09090909696672616D6524203D202428272327202B20636F6E6669672E696672616D654964293B0A090909097072657669657724203D202428272327202B20636F6E6669672E707265766965774964293B0A0909097D0A';
wwv_flow_api.g_varchar2_table(86) := '090909696672616D65242E72656D6F7665436C6173732827752D68696464656E27293B0A0A0909092F2F2046697265666F7820706F73744D6573736167652068616E646C657220666F722063726F7373206F726967696E20736563757269747920657863';
wwv_flow_api.g_varchar2_table(87) := '657074696F6E732073686F77696E67205044462066696C65730A090909242877696E646F77292E6F6E28226D657373616765222C2066756E6374696F6E20286529207B0A090909097661722064617461203D20652E6F726967696E616C4576656E742E64';
wwv_flow_api.g_varchar2_table(88) := '6174613B0A09090909696620286461746120262620646174612E696672616D654964203D3D3D20636F6E6669672E696672616D65496429207B0A0909090909242874686973292E6F66662865293B202F2F20756E62696E6420746865206576656E742068';
wwv_flow_api.g_varchar2_table(89) := '616E646C6572206173206974206D6174636865730A090909090964656C65746520464F532E7574696C732E646F776E6C6F61645B646F776E6C6F6164466E4E616D655D3B202F2F2064656C657465206F75722066756E6374696F6E2068616E646C65720A';
wwv_flow_api.g_varchar2_table(90) := '0909090909617065782E64612E726573756D65286461436F6E746578742E726573756D6543616C6C6261636B2C2066616C7365293B202F2F20726573756D6520666F6C6C6F77696E6720616374696F6E730A090909097D0A0909097D293B0A0A09090970';
wwv_flow_api.g_varchar2_table(91) := '726576696577242E6F6E28226469616C6F67726573697A65222C2066756E6374696F6E202829207B0A090909097661722068203D2070726576696577242E68656967687428292C0A090909090977203D2070726576696577242E776964746828293B0A09';
wwv_flow_api.g_varchar2_table(92) := '0909092F2F20726573697A6520696672616D6520736F20746861742061706578206469616C6F67207061676520676574732077696E646F7720726573697A65206576656E740A090909092F2F2075736520776964746820616E6420686569676874206F66';
wwv_flow_api.g_varchar2_table(93) := '206469616C6F6720636F6E74656E7420726174686572207468616E2075692E73697A6520736F2074686174206469616C6F67207469746C652069732074616B656E20696E20746F20636F6E73696465726174696F6E0A0909090970726576696577242E63';
wwv_flow_api.g_varchar2_table(94) := '68696C6472656E2822696672616D6522292E77696474682877292E6865696768742868293B0A0909097D293B0A0909090A09090969662028707265766965774F7074696F6E732E73686F7746696C65496E666F29207B0A09090909707265766965774275';
wwv_flow_api.g_varchar2_table(95) := '74746F6E732E70757368287B0A0909090909746578743A202220222C0A090909090969636F6E3A202266612066612D696E666F20666F732D6469616C6F672D66696C652D696E666F222C0A0909090909636C69636B3A2066756E6374696F6E2028652920';
wwv_flow_api.g_varchar2_table(96) := '7B0A0909090909092428652E746172676574292E746F6F6C746970287B0A090909090909096974656D733A20652E7461726765742C0A09090909090909636F6E74656E743A2067657446696C65496E666F28292C0A09090909090909706F736974696F6E';
wwv_flow_api.g_varchar2_table(97) := '3A207B0A09090909090909096D793A202263656E74657220626F74746F6D222C202F2F207468652022616E63686F7220706F696E742220696E2074686520746F6F6C74697020656C656D656E740A090909090909090961743A202263656E74657220746F';
wwv_flow_api.g_varchar2_table(98) := '702D3130222C202F2F2074686520706F736974696F6E206F66207468617420616E63686F7220706F696E742072656C617469766520746F2073656C656374656420656C656D656E740A090909090909097D2C0A09090909090909636C61737365733A207B';
wwv_flow_api.g_varchar2_table(99) := '0A09090909090909092275692D746F6F6C746970223A2022666F732D6469616C6F672D66696C652D696E666F2D746F6F6C74697020746F702075692D636F726E65722D616C6C2075692D7769646765742D736861646F77220A090909090909097D0A0909';
wwv_flow_api.g_varchar2_table(100) := '090909097D293B0A0909090909092428652E746172676574292E746F6F6C74697028226F70656E22293B0A09090909097D0A090909097D293B0A0909097D0A09090969662028707265766965774F7074696F6E732E73686F77446F776E6C6F616442746E';
wwv_flow_api.g_varchar2_table(101) := '29207B0A0909090970726576696577427574746F6E732E70757368287B0A0909090909746578743A2022446F776E6C6F6164222C0A090909090969636F6E3A202266612066612D646F776E6C6F6164222C0A0909090909636C69636B3A2066756E637469';
wwv_flow_api.g_varchar2_table(102) := '6F6E202829207B0A090909090909464F532E7574696C732E646F776E6C6F6164286461436F6E746578742C0A09090909090909242E657874656E64287B7D2C0A0909090909090909636F6E6669672C207B0A0909090909090909707265766965774D6F64';
wwv_flow_api.g_varchar2_table(103) := '653A2066616C73652C0A090909090909090970726576696577446F776E6C6F61643A202759455327202F2F20746F20696E6469636174652077652061726520646F776E6C6F6164696E672066726F6D2077697468696E2070726576696577206D6F64650A';
wwv_flow_api.g_varchar2_table(104) := '090909090909097D290A090909090909293B0A09090909097D2C0A0909090909636C61737365733A207B0A0909090909092275692D746F6F6C746970223A2022666F732D6469616C6F672D66696C652D646F776E6C6F61642D62746E20752D686F742075';
wwv_flow_api.g_varchar2_table(105) := '692D636F726E65722D616C6C2075692D7769646765742D736861646F77220A09090909097D0A090909097D293B0A0909097D0A0909092F2F20696E697469616C697A65207468652070726576696577206469616C6F670A09090970726576696577242E64';
wwv_flow_api.g_varchar2_table(106) := '69616C6F6728242E657874656E64287B0A090909097469746C653A202746696C652050726576696577272C0A09090909636C61737365733A207B0A09090909092275692D6469616C6F67223A2022666F732D66696C652D707265766965772D6469616C6F';
wwv_flow_api.g_varchar2_table(107) := '67220A090909097D2C0A090909096865696768743A2027363030272C0A0909090977696474683A2027373230272C0A090909092F2F6D617857696474683A2027393630272C0A090909096D6F64616C3A20747275652C0A090909096175746F4F70656E3A';
wwv_flow_api.g_varchar2_table(108) := '20747275652C0A090909096469616C6F673A206E756C6C2C0A09090909627574746F6E733A2070726576696577427574746F6E730A0909097D2C20707265766965774F7074696F6E73207C7C207B7D29293B0A0909092F2F2068696465207363726F6C6C';
wwv_flow_api.g_varchar2_table(109) := '6261727320696E2063617365206F6620616E7920686569676874206D69736D6174636820776974682074686520696672616D652026206469616C6F670A09090970726576696577242E63737328276F766572666C6F77272C202768696464656E27293B0A';
wwv_flow_api.g_varchar2_table(110) := '0909092F2F206368616E6765207468652069636F6E7320746F20666F6E742D617065780A09090970726576696577242E706172656E7428292E66696E6428272E75692D627574746F6E202E666127292E72656D6F7665436C617373282775692D62757474';
wwv_flow_api.g_varchar2_table(111) := '6F6E2D69636F6E2075692D69636F6E27293B0A0909092F2F2073686F77207468652066696C6520707265766965770A090909696672616D65242E617474722827737263272C20636F6E6669672E70726576696577537263293B0A09097D0A0A09092F2F20';
wwv_flow_api.g_varchar2_table(112) := '696672616D65206F6E6C6F6164206576656E742068616E646C65722C206974206669726573206F6E6C7920696620746865726520697320616E206572726F72206F722069662077652061726520696E2070726576696577206D6F64650A09092F2F207765';
wwv_flow_api.g_varchar2_table(113) := '206861766520746F20747261636B206120636F6F6B696520666F7220726567756C61722066696C6520646F776E6C6F6164206576656E747320617320746865206F6E6C6F6164206576656E7420646F6573206E6F7420666972650A0909464F532E757469';
wwv_flow_api.g_varchar2_table(114) := '6C732E646F776E6C6F61645B646F776E6C6F6164466E4E616D655D203D2066756E6374696F6E2028696672616D6529207B0A09090976617220726573756C742C0A09090909726573706F6E73652C0A0909090963616E63656C526573756D65203D206661';
wwv_flow_api.g_varchar2_table(115) := '6C73652C0A090909096661696C7572654A534F4E203D207B7D2C0A0909090977696E203D2028696672616D652E636F6E74656E7457696E646F77207C7C20696672616D652E636F6E74656E74446F63756D656E74293B0A090909747279207B0A09090909';
wwv_flow_api.g_varchar2_table(116) := '2F2F2057652077616E7420746F2061646420736F6D65207374796C696E6720746F207468652048544D4C20666F7220696D6167657320652E672E2063656E746572207468656D20686F72697A6F6E74616C6C79202620766572746963616C6C790A090909';
wwv_flow_api.g_varchar2_table(117) := '0969662028636F6E6669672E707265766965774D6F646529207B0A09090909092866756E6374696F6E202877696E2C20646F6329207B0A0909090909097661722063737331203D2027696D677B2077696474683A2027202B204D6174682E6D617828646F';
wwv_flow_api.g_varchar2_table(118) := '632E646F63756D656E74456C656D656E742E636C69656E745769647468207C7C20302C2077696E2E696E6E65725769647468207C7C203029202B202770783B207D272C0A09090909090909637373203D2027696D677B6D617267696E2D6C6566743A2061';
wwv_flow_api.g_varchar2_table(119) := '75746F3B206D617267696E2D72696768743A206175746F3B2077696474683A203530253B20766572746963616C2D616C69676E3A206D6964646C653B6865696768743A206175746F3B7D2027202B0A0909090909090909277370616E2E666F732D696D67';
wwv_flow_api.g_varchar2_table(120) := '2D68656C7065727B646973706C61793A20696E6C696E652D626C6F636B3B6865696768743A20313030253B766572746963616C2D616C69676E3A206D6964646C653B77696474683A203235253B7D272C0A0909090909090968656164203D20646F632E68';
wwv_flow_api.g_varchar2_table(121) := '656164207C7C20646F632E676574456C656D656E747342795461674E616D6528276865616427295B305D2C0A09090909090909626F6479203D20646F632E626F6479207C7C20646F632E676574456C656D656E747342795461674E616D652827626F6479';
wwv_flow_api.g_varchar2_table(122) := '27295B305D2C0A090909090909096973496D616765203D20646F632E676574456C656D656E747342795461674E616D652827696D6727292E6C656E677468203E20302C0A090909090909097374796C65203D20646F632E637265617465456C656D656E74';
wwv_flow_api.g_varchar2_table(123) := '28277374796C6527292C0A090909090909097370616E203D20646F632E637265617465456C656D656E7428277370616E27293B0A0A0909090909092F2F207765206E65656420746F20616464206120636C61737320746F206D616B65207375726520616E';
wwv_flow_api.g_varchar2_table(124) := '79207374796C696E67207765206170706C79206973206F6E6C7920666F72207468697320656C656D656E74090A0909090909097370616E2E636C6173734C6973742E6164642827666F732D696D672D68656C70657227293B0A0A09090909090969662028';
wwv_flow_api.g_varchar2_table(125) := '6865616429207B0A09090909090909686561642E617070656E64287374796C65293B0A0A090909090909097374796C652E74797065203D2027746578742F637373273B0A09090909090909696620287374796C652E7374796C65536865657429207B0A09';
wwv_flow_api.g_varchar2_table(126) := '090909090909092F2F205468697320697320726571756972656420666F722049453820616E642062656C6F772E0A09090909090909097374796C652E7374796C6553686565742E63737354657874203D206373733B0A090909090909097D20656C736520';
wwv_flow_api.g_varchar2_table(127) := '7B0A09090909090909097374796C652E617070656E644368696C6428646F632E637265617465546578744E6F64652863737329293B0A090909090909097D0A0A090909090909092F2F204164642061207370616E2074616720706C616365686F6C646572';
wwv_flow_api.g_varchar2_table(128) := '20746F2063656E7465722074686520696D61676520696E20746865206D6964646C65206F6620746865206469616C6F670A09090909090909696620286973496D6167652920626F64792E70726570656E64287370616E293B0A0909090909097D0A090909';
wwv_flow_api.g_varchar2_table(129) := '09097D292877696E2C2077696E2E646F63756D656E74293B0A090909097D0A090909092F2F20636C6F6E652074686520636F6E6669670A09090909726573756C74203D20242E657874656E64287B7D2C20636F6E666967293B0A09090909696620287769';
wwv_flow_api.g_varchar2_table(130) := '6E2E646F63756D656E742E6C6F636174696F6E2E68726566203D3D3D202261626F75743A626C616E6B2229207B0A090909090972657475726E2066616C73653B0A090909097D0A090909092F2F20636865636B206F757220726573706F6E73652C206966';
wwv_flow_api.g_varchar2_table(131) := '2069742773206F7572206F776E20657863657074696F6E2069742077696C6C2062652061204A534F4E206F626A6563740A09090909747279207B0A0909090909726573706F6E7365203D2077696E2E646F63756D656E742E676574456C656D656E747342';
wwv_flow_api.g_varchar2_table(132) := '795461674E616D65282270726522295B305D2E696E6E657248544D4C3B0A09090909096661696C7572654A534F4E203D204A534F4E2E706172736528726573706F6E7365293B0A090909097D20636174636820286529207B0A0909090909726573756C74';
wwv_flow_api.g_varchar2_table(133) := '2E726573706F6E7365203D2077696E2E646F63756D656E743B0A090909097D0A0A09090909726573756C742E6572726F72203D206661696C7572654A534F4E2E6D6573736167653B0A0A0909090969662028726573756C742E6572726F72202626202172';
wwv_flow_api.g_varchar2_table(134) := '6573756C742E73757070726573734572726F724D6573736167657329207B0A0909090909617065782E6D6573736167652E73686F774572726F7273287B0A090909090909747970653A20276572726F72272C0A0909090909096C6F636174696F6E3A205B';
wwv_flow_api.g_varchar2_table(135) := '2770616765275D2C0A090909090909706167654974656D3A20756E646566696E65642C0A0909090909096D6573736167653A20726573756C742E6572726F722C0A0909090909092F2F616E79206573636170696E6720697320617373756D656420746F20';
wwv_flow_api.g_varchar2_table(136) := '68617665206265656E20646F6E65206279206E6F770A090909090909756E736166653A2066616C73650A09090909097D293B0A090909090963616E63656C526573756D65203D20747275653B0A090909097D0A090909092F2F2072656D6F766520616E79';
wwv_flow_api.g_varchar2_table(137) := '207370696E6E657220616E642072656D6F766520747261636B696E6720696E666F0A09090909636C65616E557028646F776E6C6F6164466E4E616D652C20636F6E6669672E707265766965774D6F6465293B0A090909092F2F2074726967676572207468';

wwv_flow_api.g_varchar2_table(138) := '65206576656E7420736F20646576656C6F706572732063616E20726573706F6E6420746F2069740A09090909617065782E6576656E742E7472696767657228646F63756D656E742E626F64792C2027666F732D646F776E6C6F61642D66696C652D657272';
wwv_flow_api.g_varchar2_table(139) := '6F72272C20726573756C74293B0A0909090969662028636F6E6669672E70726576696577446F776E6C6F616420213D20275945532729207B0A0909090909617065782E64612E726573756D65286461436F6E746578742E726573756D6543616C6C626163';
wwv_flow_api.g_varchar2_table(140) := '6B2C2063616E63656C526573756D65293B0A090909097D0A0909090964656C65746520464F532E7574696C732E646F776E6C6F61645B646F776E6C6F6164466E4E616D655D3B0A0909097D20636174636820286529207B0A090909092F2F20636F646520';
wwv_flow_api.g_varchar2_table(141) := '3138203D2063726F7373206F726967696E2069737375652028666F722066697265666F78290A0909090969662028652E636F6465203D3D20313829207B0A090909090977696E2E706172656E742E706F73744D657373616765287B20696672616D654964';
wwv_flow_api.g_varchar2_table(142) := '3A20696672616D652E6964207D293B0A090909097D0A0909097D0A09097D3B0A09092F2A2A0A0909202A204D61696E2050726F63657373696E672053656374696F6E0A0909202A2F0A0A09092F2F20416C6C6F772074686520646576656C6F7065722074';
wwv_flow_api.g_varchar2_table(143) := '6F20706572666F726D20616E79206C617374202863656E7472616C697A656429206368616E676573207573696E67204A61766173637269707420496E697469616C697A6174696F6E20436F64652073657474696E670A09092F2F20696E20616464697469';
wwv_flow_api.g_varchar2_table(144) := '6F6E20746F206F757220706C7567696E20636F6E6669672077652077696C6C207061737320696E206120326E64206F626A65637420666F7220636F6E6669677572696E672074686520464F53206E6F74696669636174696F6E730A090969662028696E69';
wwv_flow_api.g_varchar2_table(145) := '74466E20696E7374616E63656F662046756E6374696F6E29207B0A090909696E6974466E2E63616C6C286461436F6E746578742C20636F6E666967293B0A09097D0A0A0909766172206C6F6164696E67496E64696361746F72466E2C0A09090972657175';
wwv_flow_api.g_varchar2_table(146) := '65737444617461203D207B2022783031223A20646F776E6C6F6164466E4E616D652C2022783032223A20636F6E6669672E70726576696577446F776E6C6F6164207D2C0A0909097370696E6E657253657474696E6773203D20636F6E6669672E7370696E';
wwv_flow_api.g_varchar2_table(147) := '6E657253657474696E67733B0A0A09092F2F20496E2070726576696577206D6F6465207765206E65656420746F2073656E642074686520746F6B656E2061732074686520414A41582063616C6C2072657475726E732074686520696672616D652055524C';
wwv_flow_api.g_varchar2_table(148) := '20666F7220746865207072657669657720616E64206974206E656564732074686520746F6B656E0A090969662028636F6E6669672E707265766965774D6F646529207B0A090909636F6E6669672E746F6B656E203D20747261636B446F776E6C6F616428';
wwv_flow_api.g_varchar2_table(149) := '636F6E6669672C20646F776E6C6F6164466E4E616D65293B0A09090972657175657374446174612E783130203D20636F6E6669672E746F6B656E3B0A09097D0A0A09092F2F204164642070616765206974656D7320746F207375626D697420746F207265';
wwv_flow_api.g_varchar2_table(150) := '71756573740A090969662028636F6E6669672E6974656D73546F5375626D697429207B0A09090972657175657374446174612E706167654974656D73203D20636F6E6669672E6974656D73546F5375626D69740A09097D0A0A09092F2F636F6E66696775';
wwv_flow_api.g_varchar2_table(151) := '726573207468652073686F77696E6720616E6420686964696E67206F66206120706F737369626C65207370696E6E65720A0909696620287370696E6E657253657474696E67732E73686F775370696E6E657229207B0A0A0909092F2F20776F726B206F75';
wwv_flow_api.g_varchar2_table(152) := '7420776865726520746F2073686F7720746865207370696E6E65720A0909097370696E6E657253657474696E67732E7370696E6E6572456C656D656E74203D20287370696E6E657253657474696E67732E73686F775370696E6E65724F6E526567696F6E';
wwv_flow_api.g_varchar2_table(153) := '29203F206166456C656D656E7473203A2027626F6479273B0A0909096C6F6164696E67496E64696361746F72466E203D202866756E6374696F6E2028656C656D656E742C2073686F774F7665726C617929207B0A090909097661722066697865644F6E42';
wwv_flow_api.g_varchar2_table(154) := '6F6479203D20656C656D656E74203D3D2027626F6479273B0A0909090972657475726E2066756E6374696F6E2028704C6F6164696E67496E64696361746F7229207B0A0909090909766172206F7665726C6179243B0A0909090909766172207370696E6E';
wwv_flow_api.g_varchar2_table(155) := '657224203D20617065782E7574696C2E73686F775370696E6E657228656C656D656E742C207B2066697865643A2066697865644F6E426F6479207D293B0A09090909096966202873686F774F7665726C617929207B0A0909090909096F7665726C617924';
wwv_flow_api.g_varchar2_table(156) := '203D202428273C64697620636C6173733D22666F732D726567696F6E2D6F7665726C617927202B202866697865644F6E426F6479203F20272D666978656427203A20272729202B2027223E3C2F6469763E27292E70726570656E64546F28656C656D656E';
wwv_flow_api.g_varchar2_table(157) := '74293B0A09090909097D0A09090909092F2F20646566696E65206F7572207370696E6E65722072656D6F76616C2066756E6374696F6E0A090909090966756E6374696F6E2072656D6F76655370696E6E65722829207B0A090909090909696620286F7665';
wwv_flow_api.g_varchar2_table(158) := '726C61792429207B0A090909090909096F7665726C6179242E72656D6F766528293B0A0909090909097D0A0909090909097370696E6E6572242E72656D6F766528293B0A09090909097D0A09090909092F2F2072657475726E20612066756E6374696F6E';
wwv_flow_api.g_varchar2_table(159) := '2077686963682068616E646C6573207468652072656D6F76696E67206F6620746865207370696E6E65722061732070657220617065782067756964656C696E65730A090909090972657475726E2072656D6F76655370696E6E65723B0A090909097D3B0A';
wwv_flow_api.g_varchar2_table(160) := '0909097D29287370696E6E657253657474696E67732E7370696E6E6572456C656D656E742C207370696E6E657253657474696E67732E73686F775370696E6E65724F7665726C6179293B0A09097D0A0A09092F2F20747261636B20746865207370696E6E';
wwv_flow_api.g_varchar2_table(161) := '657220696E206120676C6F62616C207661726961626C6520746F2072656D6F7665206C617465720A090969662028747970656F66206C6F6164696E67496E64696361746F72466E203D3D3D202266756E6374696F6E2229207B0A090909646F776E6C6F61';
wwv_flow_api.g_varchar2_table(162) := '645370696E6E6572735B646F776E6C6F6164466E4E616D655D203D206C6F6164696E67496E64696361746F72466E2E63616C6C286D65293B0A09097D0A0A09092F2F205375626D697420616E792070616765206974656D73206265666F72652070657266';
wwv_flow_api.g_varchar2_table(163) := '6F726D696E67206F757220666F726D207375626D6974202620646F776E6C6F61640A09092F2F20776520646F6E2774207375626D6974207468652070616765206974656D73206F757273656C76657320696E207468652064796E616D696320666F726D20';
wwv_flow_api.g_varchar2_table(164) := '0A09092F2F2061732074686572652773207175697465206120626974206F66206C6F67696320746F20646F2069740A09097661722070726F6D697365203D20617065782E7365727665722E706C7567696E28636F6E6669672E616A61784964656E746966';
wwv_flow_api.g_varchar2_table(165) := '6965722C2072657175657374446174612C207B0A09090964617461547970653A20276A736F6E272C0A0909097461726765743A206461436F6E746578742E62726F777365724576656E742E7461726765740A09097D293B0A0A09092F2F20446F776E6C6F';
wwv_flow_api.g_varchar2_table(166) := '6164206166746572207375626D697474696E6720616E79206974656D732C2077652072657475726E2074686520636F6E66696720726571756972656420746F20646F776E6C6F616420696E2074686520617065782E7365727665722E706C7567696E2063';
wwv_flow_api.g_varchar2_table(167) := '616C6C0A090970726F6D6973652E646F6E652866756E6374696F6E2028726573706F6E736529207B0A09090969662028636F6E6669672E707265766965774D6F646529207B0A0909090970726576696577496E4469616C6F6728726573706F6E73652E64';
wwv_flow_api.g_varchar2_table(168) := '617461293B0A0909097D20656C73652069662028636F6E6669672E6E657757696E646F7729207B0A09090909617065782E6E617669676174696F6E2E6F70656E496E4E657757696E646F7728726573706F6E73652E646174612E70726576696577537263';
wwv_flow_api.g_varchar2_table(169) := '293B0A09090909617065782E64612E726573756D65286461436F6E746578742E726573756D6543616C6C6261636B2C2066616C7365293B0A0909097D20656C7365207B0A090909096174746163686D656E74446F776E6C6F616428726573706F6E73652E';
wwv_flow_api.g_varchar2_table(170) := '64617461293B0A0909097D0A09097D292E63617463682866756E6374696F6E202865727229207B0A090909636F6E6669672E6572726F72203D206572723B0A090909636C65616E557028646F776E6C6F6164466E4E616D652C20636F6E6669672E707265';
wwv_flow_api.g_varchar2_table(171) := '766965774D6F6465293B0A090909617065782E6576656E742E7472696767657228646F63756D656E742E626F64792C2027666F732D646F776E6C6F61642D66696C652D6572726F72272C20636F6E666967293B0A09097D293B0A097D3B0A7D2928617065';
wwv_flow_api.g_varchar2_table(172) := '782E6A5175657279293B';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(61129150099059332)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_file_name=>'js/script.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '76617220464F533D77696E646F772E464F537C7C7B7D3B464F532E7574696C733D77696E646F772E464F532E7574696C737C7C7B7D2C66756E6374696F6E2865297B76617220693D7B7D2C6E3D7B7D2C743D7B7D2C6F3D7B7D3B66756E6374696F6E2061';
wwv_flow_api.g_varchar2_table(2) := '28692C74297B766172206F3D65282223707265766965772D222B69292C613D65282223696672616D652D222B69292C643D65282223666F726D2D222B69293B2266756E6374696F6E223D3D747970656F66206E5B695D2626286E5B695D28292C64656C65';
wwv_flow_api.g_varchar2_table(3) := '7465206E5B695D292C642626642E72656D6F766528292C747C7C28612626612E72656D6F766528292C6F26266F2E72656D6F76652829297D66756E6374696F6E206428652C6E297B72657475726E20652E74726967676572696E67456C656D656E74242C';
wwv_flow_api.g_varchar2_table(4) := '6F5B6E5D3D33302C695B6E5D3D77696E646F772E736574496E74657276616C282866756E6374696F6E28297B76617220643D66756E6374696F6E2865297B76617220693D646F63756D656E742E636F6F6B69652E73706C697428652B223D22293B696628';
wwv_flow_api.g_varchar2_table(5) := '323D3D692E6C656E6774682972657475726E7B6E616D653A652C76616C75653A695B315D2E73706C697428223B22292E736869667428297D7D286E293B28642626642E6E616D653D3D6E7C7C303D3D6F5B6E5D2926262864262628652E66696C65496E66';
wwv_flow_api.g_varchar2_table(6) := '6F3D4A534F4E2E706172736528642E76616C7565292C745B6E5D3D652E66696C65496E666F292C66756E6374696F6E28652C6E297B76617220743D652E707265766965774D6F64653F22666F732D646F776E6C6F61642D707265766965772D636F6D706C';
wwv_flow_api.g_varchar2_table(7) := '657465223A22666F732D646F776E6C6F61642D66696C652D636F6D706C657465223B61286E2C652E707265766965774D6F6465292C77696E646F772E636C656172496E74657276616C28695B6E5D292C643D6E2C766F696428646F63756D656E742E636F';
wwv_flow_api.g_varchar2_table(8) := '6F6B69653D656E636F6465555249436F6D706F6E656E742864292B223D64656C657465643B20657870697265733D222B6E657720446174652830292E746F555443537472696E672829292C64656C65746520695B6E5D2C64656C657465206F5B6E5D2C65';
wwv_flow_api.g_varchar2_table(9) := '2E66696C65496E666F262628617065782E6576656E742E7472696767657228646F63756D656E742E626F64792C742C65292C64656C65746520652E66696C65496E666F293B76617220643B652E74726967676572696E67456C656D656E74247D28652C6E';
wwv_flow_api.g_varchar2_table(10) := '29292C6F5B6E5D2D2D7D292C316533292C6E7D464F532E7574696C732E646F776E6C6F61643D66756E6374696F6E28692C6F2C72297B766172206C2C703D22464F53222B6F2E69642B286E65772044617465292E67657454696D6528292C733D692E6166';
wwv_flow_api.g_varchar2_table(11) := '666563746564456C656D656E74732C753D692E74726967676572696E67456C656D656E743B66756E6374696F6E206D28652C69297B72657475726E20652E707265766965774D6F64653F273C696672616D652069643D22272B652E696672616D6549642B';
wwv_flow_api.g_varchar2_table(12) := '2722206E616D653D22272B652E696672616D6549642B27222077696474683D223130302522206865696768743D223130302522207374796C653D226D696E2D77696474683A203935253B6865696768743A313030253B22207363726F6C6C696E673D2261';
wwv_flow_api.g_varchar2_table(13) := '75746F2220636C6173733D22666F732D707265766965772D6D6F646520752D68696464656E22206F6E6C6F61643D22464F532E7574696C732E646F776E6C6F61642E272B692B27287468697329223E3C2F696672616D653E273A273C696672616D652069';
wwv_flow_api.g_varchar2_table(14) := '643D22272B652E696672616D6549642B2722206E616D653D22272B652E696672616D6549642B272220636C6173733D22752D68696464656E22206F6E6C6F61643D22464F532E7574696C732E646F776E6C6F61642E272B692B27287468697329223E3C2F';
wwv_flow_api.g_varchar2_table(15) := '696672616D653E277D6C3D652E657874656E64287B7D2C6F292C617065782E64656275672E696E666F2822464F53202D20446F776E6C6F61642046696C65287329222C6C292C464F532E7574696C732E646F776E6C6F61645B705D3D66756E6374696F6E';
wwv_flow_api.g_varchar2_table(16) := '286E297B76617220742C6F2C643D21312C723D7B7D2C733D6E2E636F6E74656E7457696E646F777C7C6E2E636F6E74656E74446F63756D656E743B7472797B6966286C2E707265766965774D6F6465262666756E6374696F6E28652C69297B4D6174682E';
wwv_flow_api.g_varchar2_table(17) := '6D617828692E646F63756D656E74456C656D656E742E636C69656E7457696474687C7C302C652E696E6E657257696474687C7C30293B766172206E3D22696D677B6D617267696E2D6C6566743A206175746F3B206D617267696E2D72696768743A206175';
wwv_flow_api.g_varchar2_table(18) := '746F3B2077696474683A203530253B20766572746963616C2D616C69676E3A206D6964646C653B6865696768743A206175746F3B7D207370616E2E666F732D696D672D68656C7065727B646973706C61793A20696E6C696E652D626C6F636B3B68656967';
wwv_flow_api.g_varchar2_table(19) := '68743A20313030253B766572746963616C2D616C69676E3A206D6964646C653B77696474683A203235253B7D222C743D692E686561647C7C692E676574456C656D656E747342795461674E616D6528226865616422295B305D2C6F3D692E626F64797C7C';
wwv_flow_api.g_varchar2_table(20) := '692E676574456C656D656E747342795461674E616D652822626F647922295B305D2C613D692E676574456C656D656E747342795461674E616D652822696D6722292E6C656E6774683E302C643D692E637265617465456C656D656E7428227374796C6522';
wwv_flow_api.g_varchar2_table(21) := '292C723D692E637265617465456C656D656E7428227370616E22293B722E636C6173734C6973742E6164642822666F732D696D672D68656C70657222292C74262628742E617070656E642864292C642E747970653D22746578742F637373222C642E7374';
wwv_flow_api.g_varchar2_table(22) := '796C6553686565743F642E7374796C6553686565742E637373546578743D6E3A642E617070656E644368696C6428692E637265617465546578744E6F6465286E29292C6126266F2E70726570656E64287229297D28732C732E646F63756D656E74292C74';
wwv_flow_api.g_varchar2_table(23) := '3D652E657874656E64287B7D2C6C292C2261626F75743A626C616E6B223D3D3D732E646F63756D656E742E6C6F636174696F6E2E687265662972657475726E21313B7472797B6F3D732E646F63756D656E742E676574456C656D656E747342795461674E';
wwv_flow_api.g_varchar2_table(24) := '616D65282270726522295B305D2E696E6E657248544D4C2C723D4A534F4E2E7061727365286F297D63617463682865297B742E726573706F6E73653D732E646F63756D656E747D742E6572726F723D722E6D6573736167652C742E6572726F7226262174';
wwv_flow_api.g_varchar2_table(25) := '2E73757070726573734572726F724D65737361676573262628617065782E6D6573736167652E73686F774572726F7273287B747970653A226572726F72222C6C6F636174696F6E3A5B2270616765225D2C706167654974656D3A766F696420302C6D6573';
wwv_flow_api.g_varchar2_table(26) := '736167653A742E6572726F722C756E736166653A21317D292C643D2130292C6128702C6C2E707265766965774D6F6465292C617065782E6576656E742E7472696767657228646F63756D656E742E626F64792C22666F732D646F776E6C6F61642D66696C';
wwv_flow_api.g_varchar2_table(27) := '652D6572726F72222C74292C2259455322213D6C2E70726576696577446F776E6C6F61642626617065782E64612E726573756D6528692E726573756D6543616C6C6261636B2C64292C64656C65746520464F532E7574696C732E646F776E6C6F61645B70';
wwv_flow_api.g_varchar2_table(28) := '5D7D63617463682865297B31383D3D652E636F64652626732E706172656E742E706F73744D657373616765287B696672616D6549643A6E2E69647D297D7D2C7220696E7374616E63656F662046756E6374696F6E2626722E63616C6C28692C6C293B7661';
wwv_flow_api.g_varchar2_table(29) := '7220632C662C672C772C763D7B7830313A702C7830323A6C2E70726576696577446F776E6C6F61647D2C683D6C2E7370696E6E657253657474696E67733B6C2E707265766965774D6F64652626286C2E746F6B656E3D64286C2C70292C762E7831303D6C';
wwv_flow_api.g_varchar2_table(30) := '2E746F6B656E292C6C2E6974656D73546F5375626D6974262628762E706167654974656D733D6C2E6974656D73546F5375626D6974292C682E73686F775370696E6E6572262628682E7370696E6E6572456C656D656E743D682E73686F775370696E6E65';
wwv_flow_api.g_varchar2_table(31) := '724F6E526567696F6E3F733A22626F6479222C663D682E7370696E6E6572456C656D656E742C673D682E73686F775370696E6E65724F7665726C61792C773D22626F6479223D3D662C633D66756E6374696F6E2869297B766172206E2C743D617065782E';
wwv_flow_api.g_varchar2_table(32) := '7574696C2E73686F775370696E6E657228662C7B66697865643A777D293B72657475726E20672626286E3D6528273C64697620636C6173733D22666F732D726567696F6E2D6F7665726C6179272B28773F222D6669786564223A2222292B27223E3C2F64';
wwv_flow_api.g_varchar2_table(33) := '69763E27292E70726570656E64546F286629292C66756E6374696F6E28297B6E26266E2E72656D6F766528292C742E72656D6F766528297D7D292C2266756E6374696F6E223D3D747970656F6620632626286E5B705D3D632E63616C6C28746869732929';
wwv_flow_api.g_varchar2_table(34) := '2C617065782E7365727665722E706C7567696E286C2E616A61784964656E7469666965722C762C7B64617461547970653A226A736F6E222C7461726765743A692E62726F777365724576656E742E7461726765747D292E646F6E65282866756E6374696F';
wwv_flow_api.g_varchar2_table(35) := '6E286E297B766172206F2C612C732C632C662C672C773B6C2E707265766965774D6F64653F66756E6374696F6E286E297B766172206F3D65282223222B6E2E707265766965774964292C613D65282223222B6E2E696672616D654964292C643D5B5D2C6C';
wwv_flow_api.g_varchar2_table(36) := '3D6E2E707265766965774F7074696F6E733B7220696E7374616E63656F662046756E6374696F6E2626722E63616C6C28692C6E292C303D3D3D6F2E6C656E6774682626286528646F63756D656E742E626F6479292E617070656E6428273C646976206964';
wwv_flow_api.g_varchar2_table(37) := '3D22272B6E2E7072657669657749642B27223E272B6D286E2C70292B223C2F6469763E22292C613D65282223222B6E2E696672616D654964292C6F3D65282223222B6E2E70726576696577496429292C612E72656D6F7665436C6173732822752D686964';
wwv_flow_api.g_varchar2_table(38) := '64656E22292C652877696E646F77292E6F6E28226D657373616765222C2866756E6374696F6E2874297B766172206F3D742E6F726967696E616C4576656E742E646174613B6F26266F2E696672616D6549643D3D3D6E2E696672616D6549642626286528';
wwv_flow_api.g_varchar2_table(39) := '74686973292E6F66662874292C64656C65746520464F532E7574696C732E646F776E6C6F61645B705D2C617065782E64612E726573756D6528692E726573756D6543616C6C6261636B2C213129297D29292C6F2E6F6E28226469616C6F67726573697A65';
wwv_flow_api.g_varchar2_table(40) := '222C2866756E6374696F6E28297B76617220653D6F2E68656967687428292C693D6F2E776964746828293B6F2E6368696C6472656E2822696672616D6522292E77696474682869292E6865696768742865297D29292C6C2E73686F7746696C65496E666F';
wwv_flow_api.g_varchar2_table(41) := '2626642E70757368287B746578743A2220222C69636F6E3A2266612066612D696E666F20666F732D6469616C6F672D66696C652D696E666F222C636C69636B3A66756E6374696F6E2869297B766172206E3B6528692E746172676574292E746F6F6C7469';
wwv_flow_api.g_varchar2_table(42) := '70287B6974656D733A692E7461726765742C636F6E74656E743A286E3D745B705D2C6E3F286C2E66696C65496E666F54706C7C7C223C7374726F6E673E4E616D653A3C2F7374726F6E673E20234E414D45233C6272202F3E3C7374726F6E673E53697A65';
wwv_flow_api.g_varchar2_table(43) := '3A3C2F7374726F6E673E202353495A45233C6272202F3E3C7374726F6E673E4D696D6520547970653A3C2F7374726F6E673E20234D494D455F545950452322292E7265706C616365282F5C234E414D455C232F2C6E2E6E616D65292E7265706C61636528';
wwv_flow_api.g_varchar2_table(44) := '2F5C2353495A455C232F2C6E2E73697A65292E7265706C616365282F5C234D494D455F545950455C232F2C6E2E6D696D6554797065293A6C2E6C6F6164696E674D73677C7C225468652066696C6520696E666F726D6174696F6E206973207374696C6C20';
wwv_flow_api.g_varchar2_table(45) := '6C6F6164696E672E2E2E2E22292C706F736974696F6E3A7B6D793A2263656E74657220626F74746F6D222C61743A2263656E74657220746F702D3130227D2C636C61737365733A7B2275692D746F6F6C746970223A22666F732D6469616C6F672D66696C';
wwv_flow_api.g_varchar2_table(46) := '652D696E666F2D746F6F6C74697020746F702075692D636F726E65722D616C6C2075692D7769646765742D736861646F77227D7D292C6528692E746172676574292E746F6F6C74697028226F70656E22297D7D292C6C2E73686F77446F776E6C6F616442';
wwv_flow_api.g_varchar2_table(47) := '746E2626642E70757368287B746578743A22446F776E6C6F6164222C69636F6E3A2266612066612D646F776E6C6F6164222C636C69636B3A66756E6374696F6E28297B464F532E7574696C732E646F776E6C6F616428692C652E657874656E64287B7D2C';
wwv_flow_api.g_varchar2_table(48) := '6E2C7B707265766965774D6F64653A21312C70726576696577446F776E6C6F61643A22594553227D29297D2C636C61737365733A7B2275692D746F6F6C746970223A22666F732D6469616C6F672D66696C652D646F776E6C6F61642D62746E20752D686F';
wwv_flow_api.g_varchar2_table(49) := '742075692D636F726E65722D616C6C2075692D7769646765742D736861646F77227D7D292C6F2E6469616C6F6728652E657874656E64287B7469746C653A2246696C652050726576696577222C636C61737365733A7B2275692D6469616C6F67223A2266';
wwv_flow_api.g_varchar2_table(50) := '6F732D66696C652D707265766965772D6469616C6F67227D2C6865696768743A22363030222C77696474683A22373230222C6D6F64616C3A21302C6175746F4F70656E3A21302C6469616C6F673A6E756C6C2C627574746F6E733A647D2C6C7C7C7B7D29';
wwv_flow_api.g_varchar2_table(51) := '292C6F2E63737328226F766572666C6F77222C2268696464656E22292C6F2E706172656E7428292E66696E6428222E75692D627574746F6E202E666122292E72656D6F7665436C617373282275692D627574746F6E2D69636F6E2075692D69636F6E2229';
wwv_flow_api.g_varchar2_table(52) := '2C612E617474722822737263222C6E2E70726576696577537263297D286E2E64617461293A6C2E6E657757696E646F773F28617065782E6E617669676174696F6E2E6F70656E496E4E657757696E646F77286E2E646174612E7072657669657753726329';
wwv_flow_api.g_varchar2_table(53) := '2C617065782E64612E726573756D6528692E726573756D6543616C6C6261636B2C213129293A286F3D6E2E646174612C773D21312C6F2E74726967676572696E67456C656D656E74243D652875292C6F2E746F6B656E3D64286F2C70292C613D273C666F';
wwv_flow_api.g_varchar2_table(54) := '726D20616374696F6E3D227777765F666C6F772E73686F7722206D6574686F643D22706F73742220656E63747970653D226D756C7469706172742F666F726D2D64617461222069643D22272B28673D6F292E666F726D49642B2722207461726765743D22';
wwv_flow_api.g_varchar2_table(55) := '272B672E696672616D6549642B2722206F6E6C6F61643D22223E3C696E70757420747970653D2268696464656E22206E616D653D22705F666C6F775F6964222076616C75653D22272B672E61707049642B27222069643D2270466C6F7749643222202F3E';
wwv_flow_api.g_varchar2_table(56) := '3C696E70757420747970653D2268696464656E22206E616D653D22705F666C6F775F737465705F6964222076616C75653D22272B672E7061676549642B27222069643D2270466C6F775374657049643222202F3E3C696E70757420747970653D22686964';
wwv_flow_api.g_varchar2_table(57) := '64656E22206E616D653D22705F696E7374616E6365222076616C75653D22272B672E73657373696F6E49642B27222069643D2270496E7374616E63653222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22705F726571756573';
wwv_flow_api.g_varchar2_table(58) := '74222076616C75653D22504C5547494E3D272B672E726571756573742B27222069643D2270526571756573743222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22705F6465627567222076616C75653D22272B28672E646562';
wwv_flow_api.g_varchar2_table(59) := '75677C7C2222292B27222069643D227044656275673222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22705F7769646765745F6E616D65222076616C75653D22272B28672E7769646765744E616D657C7C2222292B27222069';
wwv_flow_api.g_varchar2_table(60) := '643D22705769646765744E616D653222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22705F7769646765745F616374696F6E222076616C75653D22272B28672E616374696F6E7C7C2222292B27222069643D22705769646765';
wwv_flow_api.g_varchar2_table(61) := '74416374696F6E3222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22705F7769646765745F616374696F6E5F6D6F64222076616C75653D22272B28672E616374696F6E4D6F647C7C2222292B27222069643D22705769646765';
wwv_flow_api.g_varchar2_table(62) := '74416374696F6E4D6F643222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783031222076616C75653D22272B28672E7830317C7C2222292B27222069643D2278303122202F3E3C696E70757420747970653D226869646465';
wwv_flow_api.g_varchar2_table(63) := '6E22206E616D653D22783032222076616C75653D22272B28672E70726576696577446F776E6C6F61647C7C224E4F22292B27222069643D2278303222202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783033222076616C7565';
wwv_flow_api.g_varchar2_table(64) := '3D22272B28672E7830337C7C2222292B27222069643D2278303322202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783034222076616C75653D22272B28672E7830347C7C2222292B27222069643D2278303422202F3E3C696E';
wwv_flow_api.g_varchar2_table(65) := '70757420747970653D2268696464656E22206E616D653D22783035222076616C75653D22272B28672E7830357C7C2222292B27222069643D2278303522202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783036222076616C75';
wwv_flow_api.g_varchar2_table(66) := '653D22272B28672E7830367C7C2222292B27222069643D2278303622202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783037222076616C75653D22272B28672E7830377C7C2222292B27222069643D2278303722202F3E3C69';
wwv_flow_api.g_varchar2_table(67) := '6E70757420747970653D2268696464656E22206E616D653D22783038222076616C75653D22272B28672E7830387C7C2222292B27222069643D2278303822202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783039222076616C';
wwv_flow_api.g_varchar2_table(68) := '75653D22272B28672E7830397C7C2222292B27222069643D2278303922202F3E3C696E70757420747970653D2268696464656E22206E616D653D22783130222076616C75653D22272B28672E746F6B656E7C7C2222292B27222069643D2278313022202F';
wwv_flow_api.g_varchar2_table(69) := '3E3C696E70757420747970653D2268696464656E22206E616D653D22663130222076616C75653D22272B28672E6631307C7C2222292B27222069643D2266313022202F3E3C2F666F726D3E272C733D6D286F2C70292C65282223222B6F2E666F726D4964';
wwv_flow_api.g_varchar2_table(70) := '292E6C656E677468262665282223222B6F2E666F726D4964292E72656D6F766528292C633D6528646F63756D656E742E626F6479292E617070656E64286129262665282223222B6F2E666F726D4964295B305D2C303D3D3D28663D65282223222B6F2E69';
wwv_flow_api.g_varchar2_table(71) := '6672616D65496429292E6C656E6774683F6528646F63756D656E742E626F6479292E617070656E642873293A662E6174747228226F6E6C6F6164222C22464F532E7574696C732E646F776E6C6F61642E222B702B2228746869732922292C632626632E73';
wwv_flow_api.g_varchar2_table(72) := '75626D69743F632E7375626D697428293A773D21302C2259455322213D6C2E70726576696577446F776E6C6F61642626617065782E64612E726573756D6528692E726573756D6543616C6C6261636B2C7729297D29292E6361746368282866756E637469';
wwv_flow_api.g_varchar2_table(73) := '6F6E2865297B6C2E6572726F723D652C6128702C6C2E707265766965774D6F6465292C617065782E6576656E742E7472696767657228646F63756D656E742E626F64792C22666F732D646F776E6C6F61642D66696C652D6572726F72222C6C297D29297D';
wwv_flow_api.g_varchar2_table(74) := '7D28617065782E6A5175657279293B0A2F2F2320736F757263654D617070696E6755524C3D7363726970742E6A732E6D6170';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(61129940934059888)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_file_name=>'js/script.min.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227363726970742E6A73225D2C226E616D6573223A5B22464F53222C2277696E646F77222C227574696C73222C2224222C22646F776E6C6F616454696D657273222C22646F776E6C6F616453';
wwv_flow_api.g_varchar2_table(2) := '70696E6E657273222C2266696C65496E666F222C22617474656D707473222C22636C65616E5570222C22646F776E6C6F6164466E4E616D65222C22707265766965774D6F6465222C227072657669657724222C22696672616D6524222C22666F726D2422';
wwv_flow_api.g_varchar2_table(3) := '2C2272656D6F7665222C22747261636B446F776E6C6F6164222C22636F6E666967222C2274726967676572696E67456C656D656E7424222C22736574496E74657276616C222C22746F6B656E222C226E616D65222C227061727473222C22646F63756D65';
wwv_flow_api.g_varchar2_table(4) := '6E74222C22636F6F6B6965222C2273706C6974222C226C656E677468222C2276616C7565222C227368696674222C22676574436F6F6B6965222C224A534F4E222C227061727365222C226576656E744E616D65222C22636C656172496E74657276616C22';
wwv_flow_api.g_varchar2_table(5) := '2C22636F6F6B69654E616D65222C22656E636F6465555249436F6D706F6E656E74222C2244617465222C22746F555443537472696E67222C2261706578222C226576656E74222C2274726967676572222C22626F6479222C2273746F70547261636B696E';
wwv_flow_api.g_varchar2_table(6) := '67446F776E6C6F6164222C22646F776E6C6F6164222C226461436F6E74657874222C226F7074696F6E73222C22696E6974466E222C226964222C2267657454696D65222C226166456C656D656E7473222C226166666563746564456C656D656E7473222C';
wwv_flow_api.g_varchar2_table(7) := '2274726967676572696E67456C656D656E74222C22676574496672616D6554706C222C22696672616D654964222C22657874656E64222C226465627567222C22696E666F222C22696672616D65222C22726573756C74222C22726573706F6E7365222C22';
wwv_flow_api.g_varchar2_table(8) := '63616E63656C526573756D65222C226661696C7572654A534F4E222C2277696E222C22636F6E74656E7457696E646F77222C22636F6E74656E74446F63756D656E74222C22646F63222C224D617468222C226D6178222C22646F63756D656E74456C656D';
wwv_flow_api.g_varchar2_table(9) := '656E74222C22636C69656E745769647468222C22696E6E65725769647468222C22637373222C2268656164222C22676574456C656D656E747342795461674E616D65222C226973496D616765222C227374796C65222C22637265617465456C656D656E74';
wwv_flow_api.g_varchar2_table(10) := '222C227370616E222C22636C6173734C697374222C22616464222C22617070656E64222C2274797065222C227374796C655368656574222C2263737354657874222C22617070656E644368696C64222C22637265617465546578744E6F6465222C227072';
wwv_flow_api.g_varchar2_table(11) := '6570656E64222C226C6F636174696F6E222C2268726566222C22696E6E657248544D4C222C2265222C226572726F72222C226D657373616765222C2273757070726573734572726F724D65737361676573222C2273686F774572726F7273222C22706167';
wwv_flow_api.g_varchar2_table(12) := '654974656D222C22756E646566696E6564222C22756E73616665222C2270726576696577446F776E6C6F6164222C226461222C22726573756D65222C22726573756D6543616C6C6261636B222C22636F6465222C22706172656E74222C22706F73744D65';
wwv_flow_api.g_varchar2_table(13) := '7373616765222C2246756E6374696F6E222C2263616C6C222C226C6F6164696E67496E64696361746F72466E222C22656C656D656E74222C2273686F774F7665726C6179222C2266697865644F6E426F6479222C227265717565737444617461222C2278';
wwv_flow_api.g_varchar2_table(14) := '3031222C22783032222C227370696E6E657253657474696E6773222C22783130222C226974656D73546F5375626D6974222C22706167654974656D73222C2273686F775370696E6E6572222C227370696E6E6572456C656D656E74222C2273686F775370';

wwv_flow_api.g_varchar2_table(15) := '696E6E65724F7665726C6179222C22704C6F6164696E67496E64696361746F72222C226F7665726C617924222C227370696E6E657224222C227574696C222C226669786564222C2270726570656E64546F222C2274686973222C22736572766572222C22';
wwv_flow_api.g_varchar2_table(16) := '706C7567696E222C22616A61784964656E746966696572222C226461746154797065222C22746172676574222C2262726F777365724576656E74222C22646F6E65222C22666F726D44617461222C22666F726D54706C222C22696672616D6554706C222C';
wwv_flow_api.g_varchar2_table(17) := '22666F726D222C2264617461222C22707265766965774964222C2270726576696577427574746F6E73222C22707265766965774F7074696F6E73222C2272656D6F7665436C617373222C226F6E222C226F726967696E616C4576656E74222C226F666622';
wwv_flow_api.g_varchar2_table(18) := '2C2268222C22686569676874222C2277222C227769647468222C226368696C6472656E222C2273686F7746696C65496E666F222C2270757368222C2274657874222C2269636F6E222C22636C69636B222C2266696C6544657461696C73222C22746F6F6C';
wwv_flow_api.g_varchar2_table(19) := '746970222C226974656D73222C22636F6E74656E74222C2266696C65496E666F54706C222C227265706C616365222C2273697A65222C226D696D6554797065222C226C6F6164696E674D7367222C22706F736974696F6E222C226D79222C226174222C22';
wwv_flow_api.g_varchar2_table(20) := '636C6173736573222C2275692D746F6F6C746970222C2273686F77446F776E6C6F616442746E222C226469616C6F67222C227469746C65222C2275692D6469616C6F67222C226D6F64616C222C226175746F4F70656E222C22627574746F6E73222C2266';
wwv_flow_api.g_varchar2_table(21) := '696E64222C2261747472222C2270726576696577537263222C2270726576696577496E4469616C6F67222C226E657757696E646F77222C226E617669676174696F6E222C226F70656E496E4E657757696E646F77222C22666F726D4964222C2261707049';
wwv_flow_api.g_varchar2_table(22) := '64222C22706167654964222C2273657373696F6E4964222C2272657175657374222C227769646765744E616D65222C22616374696F6E222C22616374696F6E4D6F64222C22783033222C22783034222C22783035222C22783036222C22783037222C2278';
wwv_flow_api.g_varchar2_table(23) := '3038222C22783039222C22663130222C227375626D6974222C226361746368222C22657272222C226A5175657279225D2C226D617070696E6773223A22414145412C49414149412C4941414D432C4F41414F442C4B41414F2C4741437842412C49414149';
wwv_flow_api.g_varchar2_table(24) := '452C4D414151442C4F41414F442C49414149452C4F4141532C47415168432C53414157432C474145562C49414149432C45414169422C4741436A42432C4541416D422C4741436E42432C454141572C47414358432C454141572C47414D662C5341415343';
wwv_flow_api.g_varchar2_table(25) := '2C45414151432C4541416742432C47414368432C49414149432C45414157522C454141452C59414175424D2C4741437643472C45414155542C454141452C57414173424D2C4741436C43492C45414151562C454141452C5341416F424D2C47414569422C';
wwv_flow_api.g_varchar2_table(26) := '6D42414172434A2C4541416942492C4B414333424A2C4541416942492C594143564A2C4541416942492C4941457242492C4741414F412C4541414D432C5341475A4A2C49414341452C47414153412C45414151452C5341436A42482C47414155412C4541';
wwv_flow_api.g_varchar2_table(27) := '4153472C55416F427A422C53414153432C45414163432C45414151502C4741694239422C4F416842554F2C4541414F432C6D4241436A42562C45414153452C4741416B422C47414333424C2C454141654B2C4741416B42522C4F41414F69422C61414159';
wwv_flow_api.g_varchar2_table(28) := '2C5741436E442C49414149432C4541664E2C5341416D42432C4741436C422C49414149432C45414151432C53414153432C4F41414F432C4D41414D4A2C4541414F2C4B41437A432C4741416F422C4741416842432C4541414D492C4F4141612C4D41414F';
wwv_flow_api.g_varchar2_table(29) := '2C434141454C2C4B41414D412C4541414D4D2C4D41414F4C2C4541414D2C47414147472C4D41414D2C4B41414B472C5341613144432C434141556E422C4941456A42552C47414153412C4541414D432C4D414151582C47414167442C4741413542462C45';
wwv_flow_api.g_varchar2_table(30) := '414153452C4D41437044552C49414348482C4541414F562C5341415775422C4B41414B432C4D41414D582C4541414D4F2C4F41436E4370422C45414153472C4741416B424F2C4541414F562C55415774432C5341413842552C45414151502C4741437243';
wwv_flow_api.g_varchar2_table(31) := '2C4941414973422C45414161662C4541416B422C594141492C674341416B432C364241437A45522C45414151432C45414167424F2C4541414F4E2C6141432F42542C4F41414F2B422C6341416335422C454141654B2C494137426677422C454138425278';
wwv_flow_api.g_varchar2_table(32) := '422C4F41374262612C53414153432C4F414352572C6D4241416D42442C474141632C7142414175422C49414149452C4B41414B2C47414147432C7342413642394468432C454141654B2C55414366462C45414153452C4741435A4F2C4541414F562C5741';
wwv_flow_api.g_varchar2_table(33) := '43562B422C4B41414B432C4D41414D432C514141516A422C534141536B422C4B41414D542C45414157662C5541437443412C4541414F562C55416E4368422C494141734232422C45417143586A422C4541414F432C6D424170426677422C43414171427A';
wwv_flow_api.g_varchar2_table(34) := '422C45414151502C4941473942462C45414153452C4F4143502C4B414549412C45416B4252542C49414149452C4D41414D77432C534141572C53414155432C45414157432C45414153432C4741436C442C4941414937422C45414548502C454131456942';
wwv_flow_api.g_varchar2_table(35) := '2C4D413045636D432C45414151452C4941535A2C49414149582C4D41414F592C5541527443432C454141614C2C454141554D2C694241437642432C4541416F42502C454141554F2C6B42416F432F422C53414153432C454141616E432C45414151502C47';
wwv_flow_api.g_varchar2_table(36) := '414F37422C4F414C494F2C4541414F4E2C5941434A2C65414169424D2C4541414F6F432C534141572C5741416170432C4541414F6F432C534141572C6B4A41416F4A33432C45414169422C6F424145764F2C65414169424F2C4541414F6F432C53414157';
wwv_flow_api.g_varchar2_table(37) := '2C5741416170432C4541414F6F432C534141572C694441416D4433432C45414169422C6F4241764339494F2C45414153622C454141456B442C4F41414F2C47414149542C4741457442502C4B41414B69422C4D41414D432C4B4152632C79424151477643';
wwv_flow_api.g_varchar2_table(38) := '2C4741794C354268422C49414149452C4D41414D77432C534141536A432C4741416B422C534141552B432C47414339432C49414149432C45414348432C45414341432C474141652C45414366432C454141632C47414364432C4541414F4C2C4541414F4D';
wwv_flow_api.g_varchar2_table(39) := '2C65414169424E2C4541414F4F2C6742414376432C49416B43432C47416843492F432C4541414F4E2C614143562C534141576D442C4541414B472C47414361432C4B41414B432C49414149462C45414149472C674241416742432C614141652C45414147';
wwv_flow_api.g_varchar2_table(40) := '502C45414149512C594141632C47414137462C49414343432C4541414D2C304C41454E432C4541414F502C454141494F2C4D414151502C45414149512C7142414171422C514141512C474143704468432C4541414F77422C4541414978422C4D41415177';
wwv_flow_api.g_varchar2_table(41) := '422C45414149512C7142414171422C514141512C4741437044432C45414155542C45414149512C7142414171422C4F41414F2F432C4F4141532C4541436E4469442C45414151562C45414149572C634141632C5341433142432C4541414F5A2C45414149';
wwv_flow_api.g_varchar2_table(42) := '572C634141632C5141473142432C4541414B432C55414155432C494141492C6B42414566502C49414348412C4541414B512C4F41414F4C2C4741455A412C4541414D4D2C4B41414F2C574143544E2C4541414D4F2C57414554502C4541414D4F2C574141';
wwv_flow_api.g_varchar2_table(43) := '57432C514141555A2C4541453342492C4541414D532C594141596E422C454141496F422C65414165642C4941496C43472C474141536A432C4541414B36432C51414151542C49417A4235422C4341324247662C4541414B412C4541414976432C55414762';
wwv_flow_api.g_varchar2_table(44) := '6D432C4541415374442C454141456B442C4F41414F2C4741414972432C474143612C674241412F4236432C4541414976432C5341415367452C53414153432C4B41437A422C4F41414F2C454147522C4941434337422C45414157472C4541414976432C53';
wwv_flow_api.g_varchar2_table(45) := '4141536B442C7142414171422C4F41414F2C4741414767422C554143764435422C454141632F422C4B41414B432C4D41414D34422C47414378422C4D41414F2B422C4741435268432C4541414F432C53414157472C4541414976432C53414776426D432C';
wwv_flow_api.g_varchar2_table(46) := '4541414F69432C4D41415139422C454141592B422C51414576426C432C4541414F69432C514141556A432C4541414F6D432C77424143334276442C4B41414B73442C51414151452C574141572C4341437642622C4B41414D2C5141434E4D2C534141552C';
wwv_flow_api.g_varchar2_table(47) := '434141432C51414358512C63414155432C454143564A2C514141536C432C4541414F69432C4D414568424D2C514141512C4941455472432C474141652C47414768426E442C45414151432C45414167424F2C4541414F4E2C6141452F4232422C4B41414B';
wwv_flow_api.g_varchar2_table(48) := '432C4D41414D432C514141516A422C534141536B422C4B41414D2C30424141324269422C4741432F422C4F414131427A432C4541414F69462C694241435635442C4B41414B36442C47414147432C4F41414F78442C4541415579442C65414167427A432C';
wwv_flow_api.g_varchar2_table(49) := '5541456E4333442C49414149452C4D41414D77432C534141536A432C4741437A422C4D41414F67462C4741454D2C49414156412C45414145592C4D41434C78432C4541414979432C4F41414F432C594141592C434141456E442C53414155492C4541414F';
wwv_flow_api.g_varchar2_table(50) := '562C4F41557A43442C6141416B4232442C554143724233442C4541414F34442C4B41414B39442C4541415733422C47414778422C4941414930462C45416F423642432C45414153432C4541437043432C454170424C432C454141632C43414145432C4941';
wwv_flow_api.g_varchar2_table(51) := '414F74472C454141674275472C4941414F68472C4541414F69462C69424143724467422C4541416B426A472C4541414F69472C6742414774426A472C4541414F4E2C634143564D2C4541414F472C4D4141514A2C45414163432C45414151502C47414372';
wwv_flow_api.g_varchar2_table(52) := '4371472C45414159492C4941414D6C472C4541414F472C4F41497442482C4541414F6D472C67424143564C2C454141594D2C5541415970472C4541414F6D472C6541493542462C4541416742492C6341476E424A2C45414167424B2C6541416B424C2C45';
wwv_flow_api.g_varchar2_table(53) := '41416D432C6F424141496A452C454141612C4F4143744432442C45416B4237424D2C45414167424B2C65416C427342562C45416B424E4B2C45414167424D2C6D42416A423943562C45414179422C51414158462C4541446E42442C454145512C53414155';
wwv_flow_api.g_varchar2_table(54) := '632C47414368422C49414149432C45414341432C4541415772462C4B41414B73462C4B41414B4E2C59414159562C454141532C4341414569422C4D41414F662C49415976442C4F415849442C49414348612C4541415774482C454141452C6B4341416F43';
wwv_flow_api.g_varchar2_table(55) := '30472C454141632C534141572C4941414D2C5941415967422C554141556C422C49414776472C5741434B632C47414348412C4541415333472C5341455634472C4541415335472C59415371422C6D424141764234462C4941435672472C4541416942492C';
wwv_flow_api.g_varchar2_table(56) := '4741416B4269472C4541416D42442C4B4170556A4471422C4F413055517A462C4B41414B30462C4F41414F432C4F41414F68482C4541414F69482C65414167426E422C454141612C43414370456F422C534141552C4F414356432C4F41415178462C4541';
wwv_flow_api.g_varchar2_table(57) := '415579462C61414161442C5341497842452C4D41414B2C5341415533452C4741395276422C494141344234452C4541437642432C45414153432C45414157432C4541414D37482C454172435838482C454173436C422F452C454136524733432C4541414F';
wwv_flow_api.g_varchar2_table(58) := '4E2C59412F505A2C53414179424D2C47414378422C494141494C2C45414157522C454141452C4941414D612C4541414F32482C57414337422F482C45414155542C454141452C4941414D612C4541414F6F432C5541437A4277462C45414169422C474143';
wwv_flow_api.g_varchar2_table(59) := '6A42432C454141694237482C4541414F36482C654149724268472C6141416B4232442C554143724233442C4541414F34442C4B41414B39442C4541415733422C474163412C49414170424C2C45414153632C5341435A74422C454141456D422C53414153';
wwv_flow_api.g_varchar2_table(60) := '6B422C4D41414D75432C4F41414F2C594141632F442C4541414F32482C554141592C4B41414F78462C454141616E432C45414151502C4741416B422C5541437647472C45414155542C454141452C4941414D612C4541414F6F432C5541437A427A432C45';
wwv_flow_api.g_varchar2_table(61) := '414157522C454141452C4941414D612C4541414F32482C59414533422F482C454141516B492C594141592C594147704233492C45414145462C5141415138492C474141472C574141572C5341415574442C4741436A432C4941414969442C4541414F6A44';
wwv_flow_api.g_varchar2_table(62) := '2C4541414575442C634141634E2C4B41437642412C47414151412C4541414B74462C5741416170432C4541414F6F432C57414370436A442C4541414532482C4D41414D6D422C4941414978442C5541434C7A462C49414149452C4D41414D77432C534141';
wwv_flow_api.g_varchar2_table(63) := '536A432C474143314234422C4B41414B36442C47414147432C4F41414F78442C4541415579442C6742414167422C4F414933437A462C454141536F492C474141472C6742414167422C57414333422C49414149472C4541414976492C4541415377492C53';
wwv_flow_api.g_varchar2_table(64) := '41436842432C454141497A492C4541415330492C5141476431492C4541415332492C534141532C55414155442C4D41414D442C47414147442C4F41414F442C4D41477A434C2C45414165552C6341436C42582C45414165592C4B41414B2C4341436E4243';
wwv_flow_api.g_varchar2_table(65) := '2C4B41414D2C4941434E432C4B41414D2C6B4341434E432C4D41414F2C534141556C452C474178436E422C4941434B6D452C45417743467A4A2C4541414573462C4541414530432C5141415130422C514141512C4341436E42432C4D41414F72452C4541';
wwv_flow_api.g_varchar2_table(66) := '414530432C4F41435434422C5341314343482C45414163744A2C45414153472C47414370422C47414169426F492C454141656D422C614141652C694841477044432C514141512C574141594C2C4541415978492C4D4143684336492C514141512C574141';
wwv_flow_api.g_varchar2_table(67) := '594C2C454141594D2C4D41436843442C514141512C6742414169424C2C454141594F2C5541436E4374422C4541416575422C594141632C3643416F433942432C534141552C43414354432C474141492C674241434A432C474141492C694241454C432C51';
wwv_flow_api.g_varchar2_table(68) := '4141532C43414352432C614141632C714541476842744B2C4541414573462C4541414530432C5141415130422C514141512C5741496E4268422C4541416536422C694241436C4239422C45414165592C4B41414B2C4341436E42432C4B41414D2C574143';
wwv_flow_api.g_varchar2_table(69) := '4E432C4B41414D2C694241434E432C4D41414F2C5741434E334A2C49414149452C4D41414D77432C53414153432C4541436C4278432C454141456B442C4F41414F2C4741435272432C454141512C434143524E2C614141612C4541436275462C67424141';
wwv_flow_api.g_varchar2_table(70) := '69422C554149704275452C514141532C43414352432C614141632C7545414B6A42394A2C45414153674B2C4F41414F784B2C454141456B442C4F41414F2C434143784275482C4D41414F2C654143504A2C514141532C434143524B2C594141612C324241';
wwv_flow_api.g_varchar2_table(71) := '456431422C4F4141512C4D414352452C4D41414F2C4D41455079422C4F41414F2C45414350432C554141552C454143564A2C4F4141512C4B4143524B2C5141415370432C47414350432C4741416B422C4B414572426C492C4541415332442C494141492C';
wwv_flow_api.g_varchar2_table(72) := '574141592C5541457A4233442C4541415332462C5341415332452C4B41414B2C6B4241416B426E432C594141592C3042414572446C492C45414151734B2C4B41414B2C4D41414F6C4B2C4541414F6D4B2C5941754A3142432C434141674231482C454141';
wwv_flow_api.g_varchar2_table(73) := '5367462C4D41436631482C4541414F714B2C5741436A42684A2C4B41414B694A2C57414157432C67424141674237482C4541415367462C4B41414B79432C594143394339492C4B41414B36442C47414147432C4F41414F78442C4541415579442C674241';
wwv_flow_api.g_varchar2_table(74) := '4167422C4B416E53666B432C454171535035452C4541415367462C4B416E5335422F452C474141652C454145684232452C4541415372482C6D4241417142642C454141452B432C47414368436F462C454141536E482C4D4141514A2C4541416375482C45';
wwv_flow_api.g_varchar2_table(75) := '41415537482C4741437A4338482C45417A434F2C6946414459472C45413043454A2C47417A4379456B442C4F4141532C6141416539432C4541414B74462C53414170482C34444143344373462C4541414B2B432C4D41446A442C7545414569442F432C45';
wwv_flow_api.g_varchar2_table(76) := '41414B67442C4F414674442C75454147364368442C4541414B69442C5541486C442C324541496D446A442C4541414B6B442C51414A78442C6B45414B32436C442C4541414B70462C4F4141532C49414C7A442C7345414D69446F462C4541414B6D442C59';
wwv_flow_api.g_varchar2_table(77) := '4141632C49414E70452C3645414F6D446E442C4541414B6F442C514141552C4941506C452C6D464151754470442C4541414B71442C574141612C4941527A452C73454153754372442C4541414B33422C4B41414F2C4941546E442C77444155754332422C';
wwv_flow_api.g_varchar2_table(78) := '4541414B7A432C694241416D422C4D41562F442C77444157754379432C4541414B73442C4B41414F2C4941586E442C77444159754374442C4541414B75442C4B41414F2C49415A6E442C77444161754376442C4541414B77442C4B41414F2C4941626E44';
wwv_flow_api.g_varchar2_table(79) := '2C77444163754378442C4541414B79442C4B41414F2C4941646E442C7744416575437A442C4541414B30442C4B41414F2C4941666E442C7744416742754331442C4541414B32442C4B41414F2C494168426E442C7744416942754333442C4541414B3444';
wwv_flow_api.g_varchar2_table(80) := '2C4B41414F2C49416A426E442C7744416B42754335442C4541414B76482C4F4141532C49416C4272442C7744416D42754375482C4541414B36442C4B41414F2C49416E426E442C7542413043502F442C4541415972462C454141616D462C454141553748';
wwv_flow_api.g_varchar2_table(81) := '2C4741452F424E2C454141452C4941414D6D492C454141536B442C514141512F4A2C514143354274422C454141452C4941414D6D492C454141536B442C51414151314B2C534145314232482C4541414F74492C454141456D422C534141536B422C4D4141';
wwv_flow_api.g_varchar2_table(82) := '4D75432C4F41414F77442C4941415970492C454141452C4941414D6D492C454141536B442C514141512C47414537432C4B41447642354B2C45414155542C454141452C4941414D6D492C454141536C462C5741436633422C4F41435874422C454141456D';
wwv_flow_api.g_varchar2_table(83) := '422C534141536B422C4D41414D75432C4F41414F79442C474145784235482C45414151734B2C4B41414B2C534141552C7342414177427A4B2C45414169422C554147374467492C47414151412C4541414B2B442C4F414368422F442C4541414B2B442C53';
wwv_flow_api.g_varchar2_table(84) := '41454C37492C474141652C454147632C4F4141314233432C4541414F69462C694241435635442C4B41414B36442C47414147432C4F41414F78442C4541415579442C65414167427A432C4F413451784338492C4F41414D2C53414155432C4741436C4231';
wwv_flow_api.g_varchar2_table(85) := '4C2C4541414F30452C4D41415167482C454143666C4D2C45414151432C45414167424F2C4541414F4E2C6141432F4232422C4B41414B432C4D41414D432C514141516A422C534141536B422C4B41414D2C30424141324278422C4F41396168452C434169';
wwv_flow_api.g_varchar2_table(86) := '624771422C4B41414B734B222C2266696C65223A227363726970742E6A73227D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(61130367644059889)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_file_name=>'js/script.js.map'
,p_mime_type=>'application/json'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E75692D746F6F6C746970207B0A202020206261636B67726F756E643A20233165323332383B0A20202020636F6C6F723A2077686974653B0A20202020626F726465723A206E6F';
wwv_flow_api.g_varchar2_table(2) := '6E653B0A2020202070616464696E673A20303B0A202020206F7061636974793A20313B0A7D0A2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C746970202E75692D746F6F6C7469702D636F6E74656E74207B0A20202020706F73697469';
wwv_flow_api.g_varchar2_table(3) := '6F6E3A2072656C61746976653B0A2020202070616464696E673A2031656D3B0A7D0A2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C746970202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B0A20202020636F6E';
wwv_flow_api.g_varchar2_table(4) := '74656E743A2027273B0A20202020706F736974696F6E3A206162736F6C7574653B0A20202020626F726465722D7374796C653A20736F6C69643B0A20202020646973706C61793A20626C6F636B3B0A2020202077696474683A20303B0A7D0A2E666F732D';
wwv_flow_api.g_varchar2_table(5) := '6469616C6F672D66696C652D696E666F2D746F6F6C7469702E7269676874202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B0A20202020746F703A20313870783B0A202020206C6566743A202D313070783B0A20202020626F7264';
wwv_flow_api.g_varchar2_table(6) := '65722D636F6C6F723A207472616E73706172656E7420233165323332383B0A20202020626F726465722D77696474683A20313070782031307078203130707820303B0A7D0A2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E6C';
wwv_flow_api.g_varchar2_table(7) := '656674202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B0A20202020746F703A20313870783B0A2020202072696768743A202D313070783B0A20202020626F726465722D636F6C6F723A207472616E73706172656E742023316532';
wwv_flow_api.g_varchar2_table(8) := '3332383B0A20202020626F726465722D77696474683A20313070782030203130707820313070783B0A7D0A2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E746F70202E75692D746F6F6C7469702D636F6E74656E743A3A6166';
wwv_flow_api.g_varchar2_table(9) := '746572207B0A20202020626F74746F6D3A202D313070783B0A202020206C6566743A203435253B0A20202020626F726465722D636F6C6F723A2023316532333238207472616E73706172656E743B0A20202020626F726465722D77696474683A20313070';
wwv_flow_api.g_varchar2_table(10) := '78203130707820303B202020200A7D0A2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E626F74746F6D202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B0A20202020746F703A202D313070783B0A2020';
wwv_flow_api.g_varchar2_table(11) := '20206C6566743A20373270783B0A20202020626F726465722D636F6C6F723A2023316532333238207472616E73706172656E743B0A20202020626F726465722D77696474683A2030203130707820313070783B0A7D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(64298389086878439)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_file_name=>'css/style.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E75692D746F6F6C7469707B6261636B67726F756E643A233165323332383B636F6C6F723A236666663B626F726465723A303B70616464696E673A303B6F7061636974793A317D';
wwv_flow_api.g_varchar2_table(2) := '2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C746970202E75692D746F6F6C7469702D636F6E74656E747B706F736974696F6E3A72656C61746976653B70616464696E673A31656D7D2E666F732D6469616C6F672D66696C652D696E66';
wwv_flow_api.g_varchar2_table(3) := '6F2D746F6F6C746970202E75692D746F6F6C7469702D636F6E74656E743A3A61667465727B636F6E74656E743A27273B706F736974696F6E3A6162736F6C7574653B626F726465722D7374796C653A736F6C69643B646973706C61793A626C6F636B3B77';
wwv_flow_api.g_varchar2_table(4) := '696474683A307D2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E7269676874202E75692D746F6F6C7469702D636F6E74656E743A3A61667465727B746F703A313870783B6C6566743A2D313070783B626F726465722D636F6C';
wwv_flow_api.g_varchar2_table(5) := '6F723A7472616E73706172656E7420233165323332383B626F726465722D77696474683A313070782031307078203130707820307D2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E6C656674202E75692D746F6F6C7469702D';
wwv_flow_api.g_varchar2_table(6) := '636F6E74656E743A3A61667465727B746F703A313870783B72696768743A2D313070783B626F726465722D636F6C6F723A7472616E73706172656E7420233165323332383B626F726465722D77696474683A313070782030203130707820313070787D2E';
wwv_flow_api.g_varchar2_table(7) := '666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E746F70202E75692D746F6F6C7469702D636F6E74656E743A3A61667465727B626F74746F6D3A2D313070783B6C6566743A3435253B626F726465722D636F6C6F723A2331653233';
wwv_flow_api.g_varchar2_table(8) := '3238207472616E73706172656E743B626F726465722D77696474683A31307078203130707820307D2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E626F74746F6D202E75692D746F6F6C7469702D636F6E74656E743A3A6166';
wwv_flow_api.g_varchar2_table(9) := '7465727B746F703A2D313070783B6C6566743A373270783B626F726465722D636F6C6F723A23316532333238207472616E73706172656E743B626F726465722D77696474683A30203130707820313070787D0A2F2A2320736F757263654D617070696E67';
wwv_flow_api.g_varchar2_table(10) := '55524C3D7374796C652E6373732E6D61702A2F';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(64299183838884807)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_file_name=>'css/style.min.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '7B2276657273696F6E223A332C22736F7572636573223A5B227374796C652E637373225D2C226E616D6573223A5B5D2C226D617070696E6773223A22414141412C77432C434143492C6B422C434143412C552C434143412C512C434143412C532C434143';
wwv_flow_api.g_varchar2_table(2) := '412C532C4341454A2C69442C434143492C69422C434143412C572C4341454A2C77442C434143492C552C434143412C69422C434143412C6B422C434143412C612C434143412C4F2C4341454A2C38442C434143492C512C434143412C552C434143412C67';
wwv_flow_api.g_varchar2_table(3) := '432C434143412C36422C4341454A2C36442C434143492C512C434143412C572C434143412C67432C434143412C36422C4341454A2C34442C434143492C592C434143412C512C434143412C67432C434143412C77422C4341454A2C2B442C434143492C53';
wwv_flow_api.g_varchar2_table(4) := '2C434143412C532C434143412C67432C434143412C7742222C2266696C65223A227374796C652E637373222C22736F7572636573436F6E74656E74223A5B222E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E75692D746F6F6C';
wwv_flow_api.g_varchar2_table(5) := '746970207B5C6E202020206261636B67726F756E643A20233165323332383B5C6E20202020636F6C6F723A2077686974653B5C6E20202020626F726465723A206E6F6E653B5C6E2020202070616464696E673A20303B5C6E202020206F7061636974793A';
wwv_flow_api.g_varchar2_table(6) := '20313B5C6E7D5C6E2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C746970202E75692D746F6F6C7469702D636F6E74656E74207B5C6E20202020706F736974696F6E3A2072656C61746976653B5C6E2020202070616464696E673A2031';
wwv_flow_api.g_varchar2_table(7) := '656D3B5C6E7D5C6E2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C746970202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B5C6E20202020636F6E74656E743A2027273B5C6E20202020706F736974696F6E3A20';
wwv_flow_api.g_varchar2_table(8) := '6162736F6C7574653B5C6E20202020626F726465722D7374796C653A20736F6C69643B5C6E20202020646973706C61793A20626C6F636B3B5C6E2020202077696474683A20303B5C6E7D5C6E2E666F732D6469616C6F672D66696C652D696E666F2D746F';
wwv_flow_api.g_varchar2_table(9) := '6F6C7469702E7269676874202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B5C6E20202020746F703A20313870783B5C6E202020206C6566743A202D313070783B5C6E20202020626F726465722D636F6C6F723A207472616E7370';
wwv_flow_api.g_varchar2_table(10) := '6172656E7420233165323332383B5C6E20202020626F726465722D77696474683A20313070782031307078203130707820303B5C6E7D5C6E2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E6C656674202E75692D746F6F6C74';
wwv_flow_api.g_varchar2_table(11) := '69702D636F6E74656E743A3A6166746572207B5C6E20202020746F703A20313870783B5C6E2020202072696768743A202D313070783B5C6E20202020626F726465722D636F6C6F723A207472616E73706172656E7420233165323332383B5C6E20202020';
wwv_flow_api.g_varchar2_table(12) := '626F726465722D77696474683A20313070782030203130707820313070783B5C6E7D5C6E2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E746F70202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B5C6E';
wwv_flow_api.g_varchar2_table(13) := '20202020626F74746F6D3A202D313070783B5C6E202020206C6566743A203435253B5C6E20202020626F726465722D636F6C6F723A2023316532333238207472616E73706172656E743B5C6E20202020626F726465722D77696474683A20313070782031';
wwv_flow_api.g_varchar2_table(14) := '30707820303B202020205C6E7D5C6E2E666F732D6469616C6F672D66696C652D696E666F2D746F6F6C7469702E626F74746F6D202E75692D746F6F6C7469702D636F6E74656E743A3A6166746572207B5C6E20202020746F703A202D313070783B5C6E20';
wwv_flow_api.g_varchar2_table(15) := '2020206C6566743A20373270783B5C6E20202020626F726465722D636F6C6F723A2023316532333238207472616E73706172656E743B5C6E20202020626F726465722D77696474683A2030203130707820313070783B5C6E7D225D7D';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(64299527673884809)
,p_plugin_id=>wwv_flow_api.id(61118001090994374)
,p_file_name=>'css/style.css.map'
,p_mime_type=>'application/json'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done




