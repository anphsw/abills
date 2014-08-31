<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<table width=450 class=form>
<tr><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>%TP_ID% %TP_NAME% %CHANGE_TP_BUTTON%</th></tr>
<tr class=total><td>$_TYPE:</td><td>%TYPE_SEL%</td></tr>
<tr class=total><td>$_DESTINATION:</td><td><input type=text name=DESTINATION value='%DESTINATION%'></td></tr>
<tr><td>$_STATUS:</td><td>%STATUS_SEL%</td></tr>
<tr><td>$_REGISTRATION:</td><td>%REGISTRATION%</td></tr>

<tr><th colspan=2>%REPORTS_LIST%</th></tr>

<tr><th colspan=2 class=even><input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint'></th></tr>
</table>

</form>
