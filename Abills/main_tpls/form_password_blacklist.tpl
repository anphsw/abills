<form action='%SELF_URL%' method='POST'>
  <input type='hidden' name='index' value='%index%' />

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{FORBIDDEN_PASSWORDS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='PASSWORD'>_{PASSWD}_</label>
        <div class='input-group col-md-9'>
          <input type='text' class='form-control' value='%PASSWORD%'  name='PASSWORD'  id='PASSWORD' required/>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>