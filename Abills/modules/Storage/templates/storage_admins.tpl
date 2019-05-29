<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>


  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{ADMINS}_</h4></div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{ADMINS}_</label>
        <div class='col-md-9'>
          %ADMINS_SELECT%
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{PERCENT}_, %</label>
        <div class='col-md-9'>
          <input name='PERCENT' value='%PERCENT%' class='form-control'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>