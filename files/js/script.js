/* globals apex */

var FOS = window.FOS || {};
FOS.utils = window.FOS.utils || {};

/**
 * This function sets up the download file handler Javascript
 *
 * @param {object}   daContext                      Dynamic Action context as passed in by APEX
 * @param {object}   config                         Configuration object holding the download file config
*/
(function ($) {

	var downloadTimers = {};
	var downloadSpinners = {};
	var fileInfo = {};
	var attempts = {};
	var FORM_PREFIX = 'form-';
	var IFRAME_PREFIX = 'iframe-';
	var PREVIEW_PREFIX = 'preview-';
	var TOKEN_PREFIX = 'FOS';

	function cleanUp(downloadFnName, previewMode) {
		var preview$ = $('#' + PREVIEW_PREFIX + downloadFnName),
			iframe$ = $('#' + IFRAME_PREFIX + downloadFnName),
			form$ = $('#' + FORM_PREFIX + downloadFnName);

		if (typeof downloadSpinners[downloadFnName] === "function") {
			downloadSpinners[downloadFnName](); // this function removes the spinner
			delete downloadSpinners[downloadFnName];
		}
		if (form$) form$.remove();

		// We don't remove the preview/iframe in preview mode for obvious reasons i.e. as they are viewing it
		if (!previewMode) {
			if (iframe$) iframe$.remove();
			if (preview$) preview$.remove();
		}
	}

	function setCursor(el$, style) {
		//el$.css("cursor", style); // we have disabled this for now
	}

	// Cookie handling comes from: https://stackoverflow.com/questions/1106377/detect-when-browser-receives-file-download
	function getCookie(name) {
		var parts = document.cookie.split(name + "=");
		if (parts.length == 2) return { name: name, value: parts[1].split(";").shift() };
	}

	function expireCookie(cookieName) {
		document.cookie =
			encodeURIComponent(cookieName) + "=deleted; expires=" + new Date(0).toUTCString();
	}

	// Track when we receieve cookie from the server to determine file is downloading
	function trackDownload(config, downloadFnName) {
		setCursor(config.triggeringElement$, "wait");
		attempts[downloadFnName] = 30;
		downloadTimers[downloadFnName] = window.setInterval(function () {
			var token = getCookie(downloadFnName);

			if ((token && token.name == downloadFnName) || (attempts[downloadFnName] == 0)) {
				if (token) {
					config.fileInfo = JSON.parse(token.value);
					fileInfo[downloadFnName] = config.fileInfo;
				}
				stopTrackingDownload(config, downloadFnName);
			}

			attempts[downloadFnName]--;
		}, 1000);

		return downloadFnName;
	}

	function stopTrackingDownload(config, downloadFnName) {
		var eventName = (config.previewMode) ? 'fos-download-preview-complete' : 'fos-download-file-complete';
		cleanUp(downloadFnName, config.previewMode);
		window.clearInterval(downloadTimers[downloadFnName]);
		expireCookie(downloadFnName);
		delete downloadTimers[downloadFnName];
		delete attempts[downloadFnName];
		if (config.fileInfo) {
			apex.event.trigger(document.body, eventName, config);
			delete config.fileInfo;
		}
		setCursor(config.triggeringElement$, 'pointer');
	}

	// Main plug-in entry point
	FOS.utils.download = function (daContext, options, initFn) {
		var config, pluginName = 'FOS - Download File(s)',
			me = this,
			downloadFnName = getDownloadId(options.id),
			afElements = daContext.affectedElements,
			triggeringElement = daContext.triggeringElement;

		config = $.extend({}, options);

		apex.debug.info(pluginName, config);

		function getDownloadId(id) {
			return TOKEN_PREFIX + id + new Date().getTime();
		}

		// generate a dynamic form with our file download context info
		function getFormTpl(data) {
			return '<form action="wwv_flow.show" method="post" enctype="multipart/form-data" id="' + data.formId + '" target="' + data.iframeId + '" onload="">' +
				'<input type="hidden" name="p_flow_id" value="' + data.appId + '" id="pFlowId2" />' +
				'<input type="hidden" name="p_flow_step_id" value="' + data.pageId + '" id="pFlowStepId2" />' +
				'<input type="hidden" name="p_instance" value="' + data.sessionId + '" id="pInstance2" />' +
				'<input type="hidden" name="p_request" value="PLUGIN=' + data.request + '" id="pRequest2" />' +
				'<input type="hidden" name="p_debug" value="' + (data.debug || '') + '" id="pDebug2" />' +
				'<input type="hidden" name="p_widget_name" value="' + (data.widgetName || '') + '" id="pWidgetName2" />' +
				'<input type="hidden" name="p_widget_action" value="' + (data.action || '') + '" id="pWidgetAction2" />' +
				'<input type="hidden" name="p_widget_action_mod" value="' + (data.actionMod || '') + '" id="pWidgetActionMod2" />' +
				'<input type="hidden" name="x01" value="' + (data.x01 || '') + '" id="x01" />' +
				'<input type="hidden" name="x02" value="' + (data.previewDownload || 'NO') + '" id="x02" />' +
				'<input type="hidden" name="x03" value="' + (data.x03 || '') + '" id="x03" />' +
				'<input type="hidden" name="x04" value="' + (data.x04 || '') + '" id="x04" />' +
				'<input type="hidden" name="x05" value="' + (data.x05 || '') + '" id="x05" />' +
				'<input type="hidden" name="x06" value="' + (data.x06 || '') + '" id="x06" />' +
				'<input type="hidden" name="x07" value="' + (data.x07 || '') + '" id="x07" />' +
				'<input type="hidden" name="x08" value="' + (data.x08 || '') + '" id="x08" />' +
				'<input type="hidden" name="x09" value="' + (data.x09 || '') + '" id="x09" />' +
				'<input type="hidden" name="x10" value="' + (data.token || '') + '" id="x10" />' +
				'<input type="hidden" name="f10" value="' + (data.f10 || '') + '" id="f10" />' +
				'</form>';
		}

		// generate a dynamic iframe based on our download context info and provide a unique onload handler function
		function getIframeTpl(config, downloadFnName) {
			var tpl;
			if (config.previewMode) {
				tpl = '<iframe id="' + config.iframeId + '" name="' + config.iframeId + '" width="100%" height="100%" style="min-width: 95%;height:100%;" scrolling="auto" class="fos-preview-mode u-hidden" onload="FOS.utils.download.' + downloadFnName + '(this)"></iframe>';
			} else {
				tpl = '<iframe id="' + config.iframeId + '" name="' + config.iframeId + '" class="u-hidden" onload="FOS.utils.download.' + downloadFnName + '(this)"></iframe>';
			}
			return tpl;
		}

		// regular file download
		function attachmentDownload(formData) {
			var formTpl, iframeTpl, form, iframe$,
				cancelResume = false;

			formData.triggeringElement$ = $(triggeringElement);
			formData.token = trackDownload(formData, downloadFnName);
			formTpl = getFormTpl(formData);
			iframeTpl = getIframeTpl(formData, downloadFnName);

			if ($('#' + formData.formId).length) {
				$('#' + formData.formId).remove()
			}
			form = $(document.body).append(formTpl) && $('#' + formData.formId)[0];
			iframe$ = $('#' + formData.iframeId);
			if (iframe$.length === 0) {
				$(document.body).append(iframeTpl);
			} else {
				iframe$.attr('onload', 'FOS.utils.download.' + downloadFnName + '(this)');
			}
			// submit our form to download the file
			if (form && form.submit) {
				form.submit();
			} else {
				cancelResume = true;
			}
			// this is required for when we are opening modal dialogs, for actual redirects the page unloads making this redundant
			if (config.previewDownload != 'YES') {
				apex.da.resume(daContext.resumeCallback, cancelResume);
			}
		}

		// file preview in a dialog with optional download button
		function previewInDialog(config) {
			var preview$ = $('#' + config.previewId),
				iframe$ = $('#' + config.iframeId),
				previewButtons = [],
				previewOptions = config.previewOptions;

			// Allow the developer to perform any last (centralized) changes using Javascript Initialization Code setting
			// in addition to our plugin config we will pass in a 2nd object for configuring the FOS notifications
			if (initFn instanceof Function) {
				initFn.call(daContext, config);
			}

			function getFileInfo() {
				var fileDetails = fileInfo[downloadFnName];
				return (fileDetails) ? (previewOptions.fileInfoTpl || '<strong>Name:</strong> #NAME#<br />' +
					'<strong>Size:</strong> #SIZE#<br />' +
					'<strong>Mime Type:</strong> #MIME_TYPE#')
					.replace(/\#NAME\#/, fileDetails.name)
					.replace(/\#SIZE\#/, fileDetails.size)
					.replace(/\#MIME_TYPE\#/, fileDetails.mimeType)
					: (previewOptions.loadingMsg || 'The file information is still loading....');
			}

			if (preview$.length === 0) {
				$(document.body).append('<div id="' + config.previewId + '">' + getIframeTpl(config, downloadFnName) + '</div>');
				iframe$ = $('#' + config.iframeId);
				preview$ = $('#' + config.previewId);
			}
			iframe$.removeClass('u-hidden');

			// Firefox postMessage handler for cross origin security exceptions showing PDF files
			$(window).on("message", function (e) {
				var data = e.originalEvent.data;
				if (data && data.iframeId === config.iframeId) {
					$(this).off(e); // unbind the event handler as it matches
					delete FOS.utils.download[downloadFnName]; // delete our function handler
					apex.da.resume(daContext.resumeCallback, false); // resume following actions
				}
			});

			preview$.on("dialogresize", function () {
				var h = preview$.height(),
					w = preview$.width();
				// resize iframe so that apex dialog page gets window resize event
				// use width and height of dialog content rather than ui.size so that dialog title is taken in to consideration
				preview$.children("iframe").width(w).height(h);
			});

			if (previewOptions.showFileInfo) {
				previewButtons.push({
					text: " ",
					icon: "fa fa-info fos-dialog-file-info",
					click: function (e) {
						$(e.target).tooltip({
							items: e.target,
							content: getFileInfo(),
							position: {
								my: "center bottom", // the "anchor point" in the tooltip element
								at: "center top-10", // the position of that anchor point relative to selected element
							},
							classes: {
								"ui-tooltip": "fos-dialog-file-info-tooltip top ui-corner-all ui-widget-shadow"
							}
						});
						$(e.target).tooltip("open");
					}
				});
			}
			if (previewOptions.showDownloadBtn) {
				previewButtons.push({
					text: "Download",
					icon: "fa fa-download",
					click: function () {
						FOS.utils.download(daContext,
							$.extend({},
								config, {
								previewMode: false,
								previewDownload: 'YES' // to indicate we are downloading from within preview mode
							})
						);
					},
					classes: {
						"ui-tooltip": "fos-dialog-file-download-btn u-hot ui-corner-all ui-widget-shadow"
					}
				});
			}
			// initialize the preview dialog
			preview$.dialog($.extend({
				title: 'File Preview',
				classes: {
					"ui-dialog": "fos-file-preview-dialog"
				},
				height: '600',
				width: '720',
				//maxWidth: '960',
				modal: true,
				autoOpen: true,
				dialog: null,
				buttons: previewButtons
			}, previewOptions || {}));
			// hide scrollbars in case of any height mismatch with the iframe & dialog
			preview$.css('overflow', 'hidden');
			// change the icons to font-apex
			preview$.parent().find('.ui-button .fa').removeClass('ui-button-icon ui-icon');
			// show the file preview
			iframe$.attr('src', config.previewSrc);
		}

		// iframe onload event handler, it fires only if there is an error or if we are in preview mode
		// we have to track a cookie for regular file download events as the onload event does not fire
		FOS.utils.download[downloadFnName] = function (iframe) {
			var result,
				response,
				cancelResume = false,
				failureJSON = {},
				win = (iframe.contentWindow || iframe.contentDocument);
			try {
				// We want to add some styling to the HTML for images e.g. center them horizontally & vertically
				if (config.previewMode) {
					(function (win, doc) {
						var css1 = 'img{ width: ' + Math.max(doc.documentElement.clientWidth || 0, win.innerWidth || 0) + 'px; }',
							css = 'img{margin-left: auto; margin-right: auto; width: 50%; vertical-align: middle;height: auto;} ' +
								'span.fos-img-helper{display: inline-block;height: 100%;vertical-align: middle;width: 25%;}',
							head = doc.head || doc.getElementsByTagName('head')[0],
							body = doc.body || doc.getElementsByTagName('body')[0],
							isImage = doc.getElementsByTagName('img').length > 0,
							style = doc.createElement('style'),
							span = doc.createElement('span');

						// we need to add a class to make sure any styling we apply is only for this element
						span.classList.add('fos-img-helper');

						if (head) {
							head.append(style);

							style.type = 'text/css';
							if (style.styleSheet) {
								// This is required for IE8 and below.
								style.styleSheet.cssText = css;
							} else {
								style.appendChild(doc.createTextNode(css));
							}

							// Add a span tag placeholder to center the image in the middle of the dialog
							if (isImage) body.prepend(span);
						}
					})(win, win.document);
				}
				// clone the config
				result = $.extend({}, config);
				if (win.document.location.href === "about:blank") {
					return false;
				}
				// check our response, if it's our own exception it will be a JSON object
				try {
					response = win.document.getElementsByTagName("pre")[0].innerHTML;
					failureJSON = JSON.parse(response);
				} catch (e) {
					result.response = win.document;
				}

				result.error = failureJSON.message;

				if (result.error && !result.suppressErrorMessages) {
					apex.message.showErrors({
						type: 'error',
						location: ['page'],
						pageItem: undefined,
						message: result.error,
						//any escaping is assumed to have been done by now
						unsafe: false
					});
					cancelResume = true;
				}
				// remove any spinner and remove tracking info
				cleanUp(downloadFnName, config.previewMode);
				// trigger the event so developers can respond to it
				apex.event.trigger(document.body, 'fos-download-file-error', result);
				if (config.previewDownload != 'YES') {
					apex.da.resume(daContext.resumeCallback, cancelResume);
				}
				delete FOS.utils.download[downloadFnName];
			} catch (e) {
				// code 18 = cross origin issue (for firefox)
				if (e.code == 18) {
					win.parent.postMessage({ iframeId: iframe.id });
				}
			}
		};
		/**
		 * Main Processing Section
		 */

		// Allow the developer to perform any last (centralized) changes using Javascript Initialization Code setting
		// in addition to our plugin config we will pass in a 2nd object for configuring the FOS notifications
		if (initFn instanceof Function) {
			initFn.call(daContext, config);
		}

		var loadingIndicatorFn,
			requestData = { "x01": downloadFnName, "x02": config.previewDownload },
			spinnerSettings = config.spinnerSettings;

		// In preview mode we need to send the token as the AJAX call returns the iframe URL for the preview and it needs the token
		if (config.previewMode) {
			config.token = trackDownload(config, downloadFnName);
			requestData.x10 = config.token;
		}

		// Add page items to submit to request
		if (config.itemsToSubmit) {
			requestData.pageItems = config.itemsToSubmit
		}

		//configures the showing and hiding of a possible spinner
		if (spinnerSettings.showSpinner) {

			// work out where to show the spinner
			spinnerSettings.spinnerElement = (spinnerSettings.showSpinnerOnRegion) ? afElements : 'body';
			loadingIndicatorFn = (function (element, showOverlay) {
				var fixedOnBody = element == 'body';
				return function (pLoadingIndicator) {
					var overlay$;
					var spinner$ = apex.util.showSpinner(element, { fixed: fixedOnBody });
					if (showOverlay) {
						overlay$ = $('<div class="fos-region-overlay' + (fixedOnBody ? '-fixed' : '') + '"></div>').prependTo(element);
					}
					// define our spinner removal function
					function removeSpinner() {
						if (overlay$) {
							overlay$.remove();
						}
						spinner$.remove();
					}
					// return a function which handles the removing of the spinner as per apex guidelines
					return removeSpinner;
				};
			})(spinnerSettings.spinnerElement, spinnerSettings.showSpinnerOverlay);
		}

		// track the spinner in a global variable to remove later
		if (typeof loadingIndicatorFn === "function") {
			downloadSpinners[downloadFnName] = loadingIndicatorFn.call(me);
		}

		// Submit any page items before performing our form submit & download
		// we don't submit the page items ourselves in the dynamic form
		// as there's quite a bit of logic to do it
		var promise = apex.server.plugin(config.ajaxIdentifier, requestData, {
			dataType: 'json',
			target: daContext.browserEvent.target
		});

		// Download after submitting any items, we return the config required to download in the apex.server.plugin call
		promise.done(function (response) {
			if (config.previewMode) {
				previewInDialog(response.data);
			} else if (config.newWindow) {
				apex.navigation.openInNewWindow(response.data.previewSrc);
				apex.da.resume(daContext.resumeCallback, false);
			} else {
				attachmentDownload(response.data);
			}
		}).catch(function (err) {
			config.error = err;
			cleanUp(downloadFnName, config.previewMode);
			apex.event.trigger(document.body, 'fos-download-file-error', config);
		});
	};
})(apex.jQuery);

