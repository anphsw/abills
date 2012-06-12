<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name=TP_ID value=$FORM{TP_ID}>
<table class=form>
<tr><td>$_TARIF_PLAN:</td><td>$FORM{TP_ID}</td></tr>
<tr><td>$_NAME:</td><td><input type=text name='NAME' value='%NAME%'></td></tr>
<tr><td>$_STATE:</td><td><input type=checkbox name='STATE' value='1' %STATE%></td></tr>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_COMMENTS</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' rows='5' cols='40'>%COMMENTS%</textarea></th></tr>
<tr><th colspan='2' class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
