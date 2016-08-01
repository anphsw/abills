<form action='$SELF_URL'>
<input type=hidden name='index' value='$index'/>
<input type=hidden name='UID' value='%UID%'/>
<input type=hidden name='COMPANY_ID' value='$FORM{COMPANY_ID}'/>

<div class='panel panel-form panel-primary form-horizontal'>
<div class='panel-heading'>_{BILL}_: %BILL_TYPE%</div>
<div class='panel-body'>
  <div class='form-group'>
    <label class='col-md-4 control-label'>_{BILL}_:</label>
    <label class='col-md-8 control-label'>%BILL_ID%:%LOGIN%</label>
  </div>
  <div class='form-group'>
    <div class='checkbox'>
      <label>
      <input type='checkbox' name='%CREATE_BILL_TYPE%' value='1' %CREATE_BILL% />_{CREATE}_:
      </label>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-4 control-label'>_{TO}_:</label>
    <div class='col-md-8'>
      %SEL_BILLS%
    </div>
  </div>
</div>
<div class='panel-footer'>
<input type='submit' class='btn btn-primary' name='change' value='_{CHANGE}_' class='button'/>
</div>
</div>
</form>
