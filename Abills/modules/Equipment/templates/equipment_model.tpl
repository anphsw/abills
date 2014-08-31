<div class='noprint'>
<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>
<table width='400' class=form>
<tr><td>$_TYPE:  </td><td>%TYPE_SEL%</td></tr>
<tr><td>$_VENDOR:</td><td>%VENDOR_SEL%</td></tr>
<tr><td>$_MODEL: </td><td><input type='text' name='MODEL_NAME' value='%MODEL_NAME%'></td></tr>
<tr><td>$_PORT: </td><td><input type='text' name='PORTS' value='%PORTS%'></td></tr>
<tr><td>URL: </td><td><input type='text' name='SITE' value='%SITE%'></td></tr>
<tr><th colspan=2>$_MANAGE:</th></tr>
<tr><td>WEB: </td><td><input type='text' name='MANAGE_WEB' value='%MANAGE_WEB%'></td></tr>
<tr><td>telnet/ssh: </td><td><input type='text' name='MANAGE_SSH' value='%MANAGE_SSH%'></td></tr>
<tr><th colspan=2>$_COMMENTS:</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' rows='6' cols='60'>%COMMENTS%</textarea></th></tr>
<tr><th colspan='2' class=even><input type='submit' name='%ACTION%' value='%ACTION_LNG%'></th></tr>
</table>

</FORM>
</div>
