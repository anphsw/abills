<form action='$SELF_URL' METHOD='post' class='form form-horizontal hidden-print form-main'>
  <input type='hidden' name='index' value='27' />
  <input type='hidden' name='chg' value='%GID%' />

  <div class='card card-primary card-outline col-md-6 container'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{GROUPS}_</h4>
    </div>
    <div class='card-body'>
      <div class="form-group row">
        <label class='control-label col-md-3 required' for='GID'>GID:</label>
        <div class="input-group col-md-9">
          <input id='GID' name='GID' value='%GID%' required placeholder='%GID%' class='form-control' type='number' %GID_DISABLE% pattern='[0-9]{,9}'>
        </div>
      </div>

      <div class="form-group row">
        <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
        <div class="input-group col-md-9">
          <input id='NAME' type='text' name='NAME' value='%NAME%' class='form-control'>
        </div>
      </div>

      <div class="form-group row">
        <label class='control-label col-md-3' for='DESCR'>_{DESCRIBE}_:</label>
        <div class="input-group col-md-9">
          <input id='DESCR' type='text' name='DESCR' value='%DESCR%' class='form-control'>
        </div>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" id='ALLOW_CREDIT' name='ALLOW_CREDIT' value='1' %ALLOW_CREDIT% type='checkbox'>
        <label class='custom-control-label' for='ALLOW_CREDIT'>_{ALLOW}_ _{CREDIT}_</label>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" id='DISABLE_PAYSYS' name='DISABLE_PAYSYS' value='1' %DISABLE_PAYSYS% type='checkbox'>
        <label class='custom-control-label' for='DISABLE_PAYSYS'>_{DISABLE}_ PAYSYS</label>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" id='DISABLE_PAYMENTS' name='DISABLE_PAYMENTS' value='1' %DISABLE_PAYMENTS% type='checkbox'>
        <label class='custom-control-label' for='DISABLE_PAYMENTS'>_{DISABLE}_ _{PAYMENTS}_ _{CASHBOX}_</label>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" id='DISABLE_CHG_TP' name='DISABLE_CHG_TP' value='1' %DISABLE_CHG_TP% type='checkbox'>
        <label class='custom-control-label' for='DISABLE_CHG_TP'>_{DISABLE}__{USER_CHG_TP}_</label>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" id='SEPARATE_DOCS' name='SEPARATE_DOCS' value='1' %SEPARATE_DOCS% type='checkbox'>
        <label class='custom-control-label' for='SEPARATE_DOCS'>_{SEPARATE_DOCS}_</label>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" id='BONUS' name='BONUS' value='1' %BONUS% type='checkbox'>
        <label class='custom-control-label' for='BONUS'>_{BONUS}_</label>
      </div>

      %DOMAIN_FORM%
    </div>
    <div class='card-footer'>
      <input type='submit' name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
    </div>
  </div>

</form>
