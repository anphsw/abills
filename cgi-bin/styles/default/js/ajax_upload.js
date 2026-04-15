/**
 * Created by Anykey on 28.03.2016.
 *
 * Binds AJAX upload for form
 */
'use strict';
jQuery(function () {
  var _ajax_body = jQuery('#ajax_upload_modal_body');
  var _ajax_form = _ajax_body.find('#ajax_upload_form');
  var _add_btn   = jQuery('#ajax_upload_submit');
  
  var add_btn_text    = _add_btn.text();
  var ajax_clear_body = '';
  var self_close      = true;
  
  var timeout = _ajax_form.data('timeout');

  if (timeout == 0) {
    self_close = false;
  }
  else if (typeof timeout === 'undefined') {
    timeout = 10000;
  }
  
  console.log('Ajax Form Upload logic defined');
  
  bindAjaxFormSubmit();
  
  function uploadForm(context) {
    var url = '/admin/index.cgi';
    
    _add_btn.html('<span class="fa fa-spinner fa-pulse"></span>');
    _add_btn.addClass('disabled');

    jQuery('#upload-pre-button').hide();
    ajax_clear_body = _ajax_body.html();

    jQuery.ajax({
      url        : url,                         // Url to which the request is send
      type       : 'POST',                      // Type of request to be send, called as method
      data       : new FormData(context),       // Data sent to server, a set of key/value pairs (i.e. form fields and values)
      contentType: false,                       // The content type used when sending data to the server.
      cache      : false,                       // To unable request pages to be cached
      processData: false,                       // To send DOMDocument or non processed data file it is set to false
      success    : function (data)
      {
        _ajax_body.empty().html(data);

        if (self_close) setTimeout(renewForm, timeout);
      }
    });
  }
  
  function renewForm() {
    aModal.hide();
    
    _ajax_body.html(ajax_clear_body);
    _add_btn.text(add_btn_text);
    _add_btn.removeClass('disabled');
    _ajax_form = jQuery('#form_ajax_upload');
    
    bindAjaxFormSubmit();
    
    location.reload()
  }
  
  function bindAjaxFormSubmit() {
    _ajax_form.on('submit', function (e) {
      e.preventDefault();
    
      uploadForm(this);
    });

    jQuery('#upload-pre-button').on('click', function (e) {
      e.preventDefault();

      const form = document.getElementById('ajax_upload_form');
      const formData = new FormData(form);
      formData.append('UPLOAD_PRE', 1);

      jQuery.ajax({
        url: '/admin/index.cgi',
        type: 'POST',
        data: formData,
        contentType: false,
        cache: false,
        processData: false,
        success: function (data) {
          jQuery('#preview-container').html(data);
        }
      });
    });
  }
});
