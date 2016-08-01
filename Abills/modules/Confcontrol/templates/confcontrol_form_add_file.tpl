<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>_{CONFIG}_ _{FILE}_</h4></div>
  <div class='panel-body'>

    <form name='CONF_CONTROL_CONTROLLED_FILES' id='form_CONF_CONTROL_CONTROLLED_FILES' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='ID' value='%ID%' />

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>$lang{NAME}</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' check_for_pattern='(?![/])' required='required' name='NAME' value='%NAME%'  id='NAME_id'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PATH_id'>$lang{PATH}</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' check_for_pattern='\/\$' required='required' name='PATH' value='%PATH%'  id='PATH_id'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>$lang{COMMENTS}</label>
        <div class='col-md-9'>
          <textarea class='form-control'  rows='5'  name='COMMENTS' id='COMMENTS_id' >%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='panel-footer text-center'>
    <input type='submit' form='form_CONF_CONTROL_CONTROLLED_FILES' class='btn btn-primary' name='%SUBMIT_BTN_ACTION%' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

