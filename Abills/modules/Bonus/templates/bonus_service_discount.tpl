<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name=TP_ID value=$FORM{TP_ID}>
<table class=form>


<tr><th colspan='3' class=title_color>$_RULES</th></tr>
<tr><td colspan=2>$_SERVICE $_PERIOD ($_MONTH):</td><td><input type=text name='SERVICE_PERIOD' value='%SERVICE_PERIOD%'></td></tr>
<tr><td colspan=2>$_REGISTRATION ($_DAYS):</td><td><input type=text name='REGISTRATION_DAYS' value='%REGISTRATION_DAYS%'></td></tr>
<tr><td colspan=2>$_TOTAL $_PAYMENTS ($_SUM):</td><td><input type=text name='TOTAL_PAYMENTS_SUM' value='%TOTAL_PAYMENTS_SUM%'></td></tr>
<tr><th colspan='3' class=title_color>$_RESULT</th></tr>
<tr class=even><td rowspan=2>$_REDUCTION </td><td>%:</td><td><input type=text name='DISCOUNT' value='%DISCOUNT%'></td></tr>
<tr class=even><td> ($_DAYS):</td><td><input type=text name='DISCOUNT_DAYS' value='%DISCOUNT_DAYS%'></td></tr>
<tr><td colspan=2>$_BONUS $_SUM: </td></td><td><input type=text name='BONUS_SUM' value='%BONUS_SUM%'></td></tr>
<tr><td colspan=2>$_BONUS_PERCENT:</td><td><input type=text name='BONUS_PERCENT' value='%BONUS_PERCENT%'></td></tr>
<tr><td colspan=2>$_EXTRA $_ACCOUNT: </td></td><td><input type=checkbox name='EXT_ACCOUNT' value='1' %EXT_ACCOUNT%></td></tr>


<tr><th colspan='3' class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
