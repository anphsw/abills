<form action='$SELF_URL'>
  <input type=hidden name='index' value='$index'/>
  <input type=hidden name='UID' value='%UID%'/>
  <input type=hidden name='COMPANY_ID' value='$FORM{COMPANY_ID}'/>

  <div class='card card-form card-outline card-primary'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{BILL}_: %BILL_TYPE%</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{BILL}_:</label>
        <div class='col-md-8'>%BILL_ID%:%LOGIN%</div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 text-right' for='CREATE'>_{CREATE}_:</label>
        <div class='col-md-8'>
          <div class='form-check text-left'>
            <input type='checkbox' class='form-check-input' id='CREATE' name='%CREATE_BILL_TYPE%' %CREATE_BILL% checked>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{TO}_:</label>
        <div class='col-md-8'>
          %SEL_BILLS%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary float-left' name='change' value='_{CHANGE}_' class='button'/>
    </div>
  </div>
</form>
