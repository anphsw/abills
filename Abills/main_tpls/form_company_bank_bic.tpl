<form id='form_company_bank_bic' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='chg' value='$FORM{chg}' />
  <input type='hidden' name='BANK_BIC' value='%BANK_BIC%' />

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{BANK}_ _{BIC}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='BANK_NAME'>_{BANK_NAME}_</label>
        <div class='input-group col-md-9'>
          <input type='text' class='form-control' value='%BANK_NAME%'  name='BANK_NAME'  id='BANK_NAME' required/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='BANK_BIC'>_{BANK_BIC}_</label>
        <div class='input-group col-md-9'>
          <input type='text' maxlength='8' class='form-control' value='%BANK_BIC%'  name='BANK_BIC' id='BANK_BIC' %DISABLED%/>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>