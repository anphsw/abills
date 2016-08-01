
<form action='$SELF_URL' class='form-horizontal'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='TI_ID' value='%TI_ID%'>

<fieldset>
	<div class='form-group'>
  <label class='control-label col-md-6' for='SEL_DAYS'>_{DAY}_:</label>
  <div class='col-md-3'>
   %SEL_DAYS%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-6' for='TI_BEGIN'>_{BEGIN}_:</label>
  <div class='col-md-3'>
    <input id='TI_BEGIN' name='TI_BEGIN' value='%TI_BEGIN%' placeholder='%TI_BEGIN%' class='form-control' type='text'>
  </div>
</div>
<div class='form-group'>
  <label class='control-label col-md-6' for='TI_END'>_{END}_:</label>
  <div class='col-md-3'>
    <input id='TI_END' name='TI_END' value='%TI_END%' placeholder='%TI_END%' class='form-control' type='text'>
  </div>
</div>

<input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>


</fieldset>

</form>

