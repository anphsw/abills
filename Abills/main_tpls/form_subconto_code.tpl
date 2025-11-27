<form action='%SELF_URL%' id='form_code_subconto' class='form form-horizontal'>
  <input type='hidden' name='index' value='%index%' />
  <input type='hidden' name='chg' value='$FORM{chg}' />

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SUBCONTO}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='CODE'>_{CODE}_</label>
        <div class='input-group col-md-9'>
          <input type='text' class='form-control' value='%CODE%'  name='CODE' id='CODE' required/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='NAME'>_{NAME}_</label>
        <div class='input-group col-md-9'>
          <input type='text' class='form-control' value='%NAME%'  name='NAME'  id='NAME' required/>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>