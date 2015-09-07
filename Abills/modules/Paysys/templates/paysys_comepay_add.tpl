<form action='%PAYSYS_URL%' method='get' target='_self'>
<input type='hidden' name='shop' value='$conf{PAYSYS_COMEPAY_PRV_ID}'>
<input type='hidden' name='transaction' value='%TRANSACTION_ID%'>
<input type='hidden' name='successUrl' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&TRUE=1&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='failUrl' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&TRUE=0&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}'>

%PARAMS%

<table width=400 class=form>

<tr><th colspan=2 class='form_title'>ComePay</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td><br>PHONE (79000000000):</td><td>%PHONE_ERR%<br><input type=text name=PHONE value='%PHONE%'></td></tr>  
<tr><td>$_BALANCE_RECHARCHE_SUM:</td><td>$FORM{SUM}</td></tr>


<tr><th colspan=2><input type=submit value='$_PAY'>

</th></tr>
</table>
</form>
