<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{ACTION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %SELECT_TYPE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>_{ADMINS}_:</label>
        <div class='col-md-8'>
          %SELECT_ADMINS%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>