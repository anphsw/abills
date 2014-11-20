<div class='panel panel-default'>
  <div class='panel-body'>

<form action='$SELF_URL' method='post' class='form-horizontal'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>

<fieldset>
%MENU%

<div class='form-group'>
  <label class='control-label col-md-6' for='TP_ID'>$_TARIF_PLAN</label>
  <div class='col-md-3'>
    %TP_ID% %TP_NAME% %CHANGE_TP_BUTTON%
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-6' for='TYPE'>$_TYPE</label>
  <div class='col-md-2'>
    %TYPE_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-6' for='DESTINATION'>$_DESTINATION</label>
  <div class='col-md-3'>
    <input type='text' name='DESTINATION' id='DESTINATION' value='%DESTINATION%' placeholder='%DESTINATION%' class='form-control' >
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-6' for='STATUS'>$_STATUS</label>
  <div class='col-md-2'>
    %STATUS_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-6' for=''>$_REGISTRATION</label>
  <div class='col-md-2'>
    %REGISTRATION%
  </div>
</div>


<div>%REPORTS_LIST%</div>


<div class='col-sm-offset-2 col-sm-8'>
  <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
</div>


</fieldset>
</form>

</div></div>
