
<div class='panel panel-default panel-form'>
<div class='panel-body'>

<form action=$SELF_URL method=post class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=chg value='$FORM{chg}'>
<input type=hidden name=ID value='$FORM{chg}'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=TP_IDS value='%TP_IDS%'>
<input type=hidden name='step' value='$FORM{step}'>
<input type=hidden name='MAC' value='%MAC%'>
<input type=hidden name='SERIAL_NUMBER' value='%SERIAL_NUMBER%'>
<input type=hidden name='list' value='$FORM{list}'>

<fieldset>

<div class='form-group'>
  <label class='control-label col-md-12' for='DEVICE'>_{DEVICE}_</label>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='ID'>ID</label>
  <div class='col-md-3'>
    %ID%
  </div>

  <label class='control-label col-md-3' for='ID'>_{DATE}_</label>
  <div class='col-md-3'>
    %date_added%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='serial_number'>_{SERIAL}_</label>
  <div class='col-md-9 text-left'>
    %serial_number%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='MAC'>MAC</label>
  <div class='col-md-9 text-left'>
    %MAC%
  </div>
</div>

<!--
<div class='form-group'>
  <label class='control-label col-md-3' for='DEVICE_MODEL'>_{DEVICE}_ _{MODEL}_</label>
  <div class='col-md-8'>
    %DEVICE_MODEL%
  </div>
  <div class='col-md-1'>
    %DEVICE_DEL%
  </div>
</div>
-->

<div class='form-group'>
  <label class='control-label col-md-3' for='DEVICE_TYPE'>_{DEL}_ _{TYPE}_</label>
  <div class='col-md-9'>
    %DEL_TYPE_SEL%
  </div>
</div>


<div class='col-sm-offset-2 col-sm-8'>
 	%BACK_BUTTON%
  <input type='submit' class='btn btn-primary' name='del_device' value='_{DEL}_'>
</div>


</fieldset>

</form>

</div>
</div>
