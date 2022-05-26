<form action='$SELF_URL' METHOD='post' class='form hidden-print form-main'>
  <input type='hidden' name='index' value='27' />
  <input type='hidden' name='chg' value='%GID%' />

  <div class='card card-primary card-outline container'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{GROUPS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-4 required' for='GID'>GID:</label>
        <div class='input-group col-md-8'>
          <input id='GID' name='GID' value='%GID%' required placeholder='%GID%' class='form-control'
                 type='number' %GID_DISABLE% pattern='[0-9]{,9}'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='NAME'>_{NAME}_:</label>
        <div class='input-group col-md-8'>
          <input id='NAME' type='text' name='NAME' value='%NAME%' class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='DESCR'>_{DESCRIBE}_:</label>
        <div class='input-group col-md-8'>
          <input id='DESCR' type='text' name='DESCR' value='%DESCR%' class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ALLOW_CREDIT'>_{ALLOW}_ _{CREDIT}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='ALLOW_CREDIT' name='ALLOW_CREDIT' %ALLOW_CREDIT% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLE_PAYSYS'>_{DISABLE}_ PAYSYS:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='DISABLE_PAYSYS' name='DISABLE_PAYSYS' %DISABLE_PAYSYS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLE_PAYMENTS'>_{DISABLE}_ _{PAYMENTS}_ _{CASHBOX}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='DISABLE_PAYMENTS' name='DISABLE_PAYMENTS' %DISABLE_PAYMENTS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLE_CHG_TP'>_{DISABLE}_: _{USER_CHG_TP}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='DISABLE_CHG_TP' name='DISABLE_CHG_TP' %DISABLE_CHG_TP% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SEPARATE_DOCS'>_{SEPARATE_DOCS}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='SEPARATE_DOCS' name='SEPARATE_DOCS' %SEPARATE_DOCS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='BONUS'>_{BONUS}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='BONUS' name='BONUS' %BONUS% value='1'>
          </div>
        </div>
      </div>

      %DOMAIN_FORM%
      %SMS_FORM%
    </div>
    <div class='card-footer'>
      <input type='submit' name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
    </div>
  </div>
</form>
