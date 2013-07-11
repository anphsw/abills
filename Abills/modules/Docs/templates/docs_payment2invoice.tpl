
<form action='$SELF_URL' method='post' name='account_add'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='UNINVOICED' value='1'>

<Table class=form>
<tr><th class='form_title' colspan=2>$_PAYMENTS</th></tr>
<tr><td colspan=2>%PAYMENTS_LIST%</td></tr>
<tr><td>$_SUM:</td><td><input type=text name=SUM value='%SUM%' size=8></td></tr>
<tr><td>$_INVOICE:</td><td>%INVOICE_SEL%</td></tr>

<tr><td colspan=2>&nbsp;</td></tr>

<tr><th class='even' colspan=2><input type=submit name=apply value='$_APPLY'></th></tr>
</table>


</form>
