
<form action='https://secure.payu.ua/order/lu.php' method='POST' accept-charset='utf-8'>
%FIELDS%

<input type=text name=BACK_REF value='https://demo.abills.net.ua:9443/index.cgi'>

<table width=400 class=form>
<tr><th class='form_title' colspan=2>PayU</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_BALANCE_RECHARCHE_SUM:</td><td>$FORM{SUM}</td></tr>

<tr><th colspan=2 class=even><input type=submit name=add value='$_PAY'>
</table>
</form>



