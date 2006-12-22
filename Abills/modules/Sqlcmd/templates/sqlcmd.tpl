<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=MAIL_ACCESS_ID value=%MAIL_ACCESS_ID%>
<table>
<tr><th colspan=2>SQL QUERY:</th><tr>
<tr><th colspan=2><textarea name='QUERY' cols=70 rows=10>%QUERY%</textarea></th><tr>
<tr><td>$_ROWS:</td><td><input type=text name=%ROWS% value='%ROWS%'></td></tr>
</table>
<input type=submit name=show value='QUERY'>
</form>
