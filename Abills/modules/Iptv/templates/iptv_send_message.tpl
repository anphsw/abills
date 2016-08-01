<form action=$SELF_URL METHOD=post class='form-horizontal'>
<input type=hidden name=index value='$index'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=send_message value='1'>
<fieldset>
	<legend>_{SEND}_ _{MESSAGE}_ 		</legend>


	<div class='form-group'>
  <label class='control-label col-md-6' for='PIN'>_{NUM}_:</label>
  <div class='col-md-3'>
    <textarea  name='PIN'  class='form-control' type='password'>
  </div>
 </div>

 	<div class='form-group'>
  <label class='control-label col-md-6' for='REBOOT_AFTER_OK'>_{REBOOT}_: </label>
  <div class='col-md-3'>
    <input  name='REBOOT_AFTER_OK'  class='form-control' type='checkbox' value=1>
  </div>
 </div>
 <input class='btn btn-primary btn-sm' type=submit name=send value='_{SEND}_'>


	</fieldset>
<!--
<table class=form>
<tr><th colspan=2 class=form_title>_{SEND}_ _{MESSAGE}_</th></tr>
<tr><th  colspan=2><textarea cols=60 rows=10 name=MESSAGE>%MESSAGE%</textarea></th></tr>
<tr><td>_{REBOOT}_: </td><td><input type=checkbox name=REBOOT_AFTER_OK value=1></td></tr>

<tr><td>_{NEED_CONFIRM}_: </td><td><input type=checkbox name=NEED_CONFIRM value=1></td></tr>
<tr><td>_{PRIORITY}_:</td><td><select name=PRIORITY>
<option value=0>_{NORMAL}_</option>
<option value=1>_{HIGH}_</option>
</select>
</td></tr>

<tr><th  colspan=2 class=even><input type=submit name=send value='_{SEND}_'></th></tr>
</table>-->
</form>
