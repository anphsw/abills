<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value='$index'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=send_message value='1'>
<table class=form>
<tr><th colspan=2 class=form_title>$_SEND $_MESSAGE</th></tr>
<tr><th  colspan=2><textarea cols=60 rows=10 name=MESSAGE>%MESSAGE%</textarea></th></tr>
<tr><td>$_REBOOT: </td><td><input type=checkbox name=REBOOT_AFTER_OK value=1></td></tr>
<!-- 
<tr><td>$_NEED_CONFIRM: </td><td><input type=checkbox name=NEED_CONFIRM value=1></td></tr>
<tr><td>$_PRIORITY:</td><td><select name=PRIORITY> 
<option value=0>$_NORMAL</option>
<option value=1>$_HIGH</option>
</select>
</td></tr>
-->
<tr><th  colspan=2 class=even><input type=submit name=send value='$_SEND'></th></tr>
</table>
</form>
