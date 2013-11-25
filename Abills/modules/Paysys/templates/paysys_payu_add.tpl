
<form action='https://secure.payu.ua/order/lu.php' method='POST' accept-charset='utf-8'>
<input type='hidden' name='MERCHANT' value='$conf{PAYSYS_UPAY_MERCHANT}'>
<input type='hidden' name='ORDER_REF' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='ORDER_DATE' value='$DATE $TIME'>
<input type='hidden' name='ORDER_PNAME' value='$_PAYMENTS $FORM{OPERATION_ID'>
<input type='hidden' name='ORDER_PINFO' value=''>
<input type='hidden' name='ORDER_PCODE' value=''>
<input type='hidden' name='ORDER_PRICE' value='$FORM{SUM}'>
<input type='hidden' name='ORDER_QTY' value='1'>
<input type='hidden' name='ORDER_VAT' value='0'>
<input type='hidden' name='ORDER_SHIPPING' value='0'>
<input type='hidden' name='PRICES_CURRENCY' value='UAH'>
<input type='hidden' name='LANGUAGE' value='RU'>
<input type='hidden' name='TESTORDER' value='%TESTORDER%'>
<input type='hidden' name='DEBUG' value='$conf{PAYSYS_UPAY_DEBUG}'>
<input type='hidden' name='ORDER_HASH' value='%ORDER_HASH%'>
<table width=400 class=form>
<tr><th class='form_title' colspan=2>PayU</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_BALANCE_RECHARCHE_SUM:</td><td>$FORM{SUM}</td></tr>

<tr><th colspan=2 class=even><input type=submit name=add value='$_PAY'>
</table>
</form>



