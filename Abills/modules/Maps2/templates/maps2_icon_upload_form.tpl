<div class='row'>
  <div class='box-header with-border text-center'>
    <h4>_{NEW}_ _{ICON}_</h4>
  </div>

  <div class='box-body' id='ajax_upload_modal_body'>

    <form class='form form-inline' name='ajax_upload_form' id='ajax_upload_form' data-timeout='%TIMEOUT%' method='post'>
      <input type='hidden' name='get_index' value='%CALLBACK_FUNC%'/>
      <input type='hidden' name='IN_MODAL' value='1'/>
      <input type='hidden' name='header' value='2'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='UPLOAD_FILE'>_{FILE}_</label>
        <div class='col-md-9'>
          <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' class='control-element' required/>
        </div>
      </div>

    </form>

  </div>
  <div class='box-footer text-right'>
    <button type='submit' class='btn btn-primary' id='ajax_upload_submit' form='ajax_upload_form'>
      _{ADD}_
    </button>
  </div>
</div>

<script src='/styles/default_adm/js/ajax_upload.js'></script>

<script>
  jQuery('#ajax_upload_submit').on('click', function () {
    setTimeout(function() {
      jQuery('.modal').modal('hide');
      if (updateIcons)
        updateIcons();

    }, 2000);
  });

</script>
