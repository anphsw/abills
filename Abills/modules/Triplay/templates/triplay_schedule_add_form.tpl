<form action='%SELF_URL%' method='post' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='SCHEDULE' value='%SCHEDULE%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SHEDULE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='DATE' class='control-label col-md-3'>_{FROM}_:</label>
        <div class='col-md-9'>
          %DATE_PICKER%
        </div>
      </div>

      <div class='form-group row'>
        <label for='ACTION' class='control-label col-md-3'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SEL%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='add' value='_{ADD}_'>
    </div>
  </div>
</form>
