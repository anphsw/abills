<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='chg' value='%ID%'>
<table class=form>
<!--- 
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_ADDRESS:</td><td><input type='text' name='ADDRESS' value='%ADDRESS%'></td></tr>
<tr><td>$_PHONE:</td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>
-->


<tr><th colspan=2 bgcolor=$_COLORS[0]>$_DILLERS</th></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TARIF_PLAN_SEL%</td></tr>
<tr><td>$_PERCENTAGE:</td><td><input type='text' name='PERCENTAGE' value='%PERCENTAGE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1' %DISABLE%></td></tr>
<tr><td>$_REGISTRATION:</td><td>%REGISTRATION%</td></tr>
<tr><th colspan='2' class=titel_color>$_COMMENTS</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' cols='60' rows='6'>%COMMENTS%</textarea></th></tr>

<tr><th class=even>
%DEL_BUTTON%</th>
<th><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
