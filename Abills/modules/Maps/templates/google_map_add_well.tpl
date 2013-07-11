<br />
<br />
<form action=$SELF_URL name=well_add_form align=center>
<input type=hidden name=index value=$index>
<input type=hidden name=COORDX value=%DCOORDX%>
<input type=hidden name=COORDY value=%DCOORDY%>
<table style=\'width:200\'>
<tr>
<th colspan=\"2\" class=\"form_title\">$_ADD_WELL</th>
</tr>
<tr>
	<td bgcolor=\"#eeeeee\">$_NAME:</td>
	<td bgcolor=\"#eeeeee\"><input type=text name=NAME size=33></td>
</tr>
<tr>
	<td bgcolor=\"#eeeeee\">$_DESCRIBE:</td>
	<td bgcolor=\"#eeeeee\"><textarea name=DESCRIBE cols=30 rows=5></textarea></td>
</tr>
<tr>
	<td align='center' colspan=\"2\" bgcolor=\"#eeeeee\"><input type=submit name=add_well value=$_ADD></td>
</tr>	
</table>
</form>
