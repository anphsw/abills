<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<table width='300'>
<tr><th colspan='2' bgcolor='$_COLORS[0]'>$_CREATE</th></tr>
<tr><td>$_SERIAL:</td><td><input type='text' name='SERIAL' value='%SERIAL%'></td></tr>
<tr><td>$_BEGIN:</td><td><input type='text' name='BEGIN' value='%BEGIN%'></td></tr>
<tr><td>$_COUNT:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>PIN</th></tr>
<tr><td>$_SYMBOLS:</td><td><input type='text' name='PASSWD_SYMBOLS' value='%PASSWD_SYMBOLS%'></td></tr>
<tr><td>$_SIZE:</td><td><input type='text' name='PASSWD_LENGTH' value='%PASSWD_LENGTH%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>-</th></tr>
<tr><td>$_EXPIRE:</td><td><input type='text' name='EXPIRE' value='%EXPIRE%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>EXPORT:</th></tr>
<tr><td colspan='2'>
<input type='radio' name='EXPORT' value='TEXT'> Text<br/>
<input type='radio' name='EXPORT' value='XML'> XML<br/>
<input type='checkbox' name='qindex' value='$index'> $_DOWNLOAD
</td></tr>

<tr bgcolor='$_COLORS[0]'><th colspan=2>-</th></tr>
<tr><td>$_DILLERS:</td><td>%DILLERS_SEL%</td></tr>

</table>
<input type=submit  name=add value='$_CREATE'>
</form>
</div>