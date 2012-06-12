<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<table class=form>

<tr><th colspan='2' class=form_title>$_BONUS Turbo</th></tr>
<tr><td>$_SERVICE $_PERIOD ($_MONTH):</td><td><input type=text name='SERVICE_PERIOD' value='%SERVICE_PERIOD%'></td></tr>
<tr><td>$_REGISTRATION ($_DAYS):</td><td><input type=text name='REGISTRATION_DAYS' value='%REGISTRATION_DAYS%'></td></tr>
<tr><td>$_TURBO $_COUNT:</td><td><input type=text name='TURBO_COUNT' value='%TURBO_COUNT%'></td></tr>
<tr><th color=form_title>$_DESCRIBE</th></tr>
<tr><th colspan=2><textarea name=COMMENTS rows=6 cols=45>%COMMENTS%</textarea></th></tr>


<tr><th colspan='3' class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
