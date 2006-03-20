<form action="$SELF_URL" METHOD="POST">
<table>
<tr><td>$_BEGIN:</td><td><input type=text name=BEGIN value='%BEGIN%'></td></tr>
<tr><td>$_COUNT:</td><td><input type=text name=COUNT value='%COUNT%'></td></tr>

<tr><th colspan=2>$_LOGINS</td></tr>
<tr><td>$_BEGIN:</td><td><input type=text name=BEGIN value='%BEGIN%'></td></tr>
<tr><td>$_COUNT:</td><td><input type=text name=COUNT value='%COUNT%'></td></tr>
<tr><td>$_FILE:</td><td><input type=file name=FILE value='%FILE%'></td></tr>
<tr><td>$_GROUP:</td><td>%SELGROUPS%</td></tr>
%EXPARAMS%

<tr><th colspan=2>$_PASSWORD</td></tr>
<tr><td>$_SYMBOLS:</td><td><input type=text name=PASSWS_SYMBOLS value='%PASSWS_SYMBOLS%'></td></tr>
<tr><td>$_LENGTH:</td><td><input type=text name=COUNT value='%COUNT%'></td></tr>


<tr><th colspan=2>$_EXPORT:</th></tr>
<tr><td colspna=2><input type=radio name=EXPORT value='%TEXT%'><br>
<input type=text name=EXPORT value='%XML%'>
</td></tr>
</table>
<input type=submit name=EXPORT value='%XML%'>
</form>
