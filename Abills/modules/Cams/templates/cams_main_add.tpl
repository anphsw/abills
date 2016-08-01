<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>%PANEL_HEADING%</h4></div>
  <div class='panel-body'>

    <form name='CAMS_USER_ADD' id='form_CAMS_USER_ADD' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='UID' value='%UID%' />

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='TP_ID'>_{TP_ID}_</label>
        <div class='col-md-9'>
          %TP_ID_SELECT%
        </div>
      </div>
    </form>

  </div>
  <div class='panel-footer text-center'>
    <input type='submit' form='form_CAMS_USER_ADD' class='btn btn-primary' name='action' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>