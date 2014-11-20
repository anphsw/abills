<form method='POST' action='https://api.privatbank.ua:9083/p24api/ishop'>

<table width=400 class=form>

<tr><th colspan=2 class='form_title'>Privat Bank - Privat 24</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>

<tr><td>$_BALANCE_RECHARCHE_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><td>$_COMMISSION:</td><td>%COMMISSION_SUM%</td></tr>
<tr><td>$_TOTAL $_SUM:</td><td>$FORM{TOTAL_SUM}</td></tr>

<input type='hidden' name='amt' value='$FORM{TOTAL_SUM}' />
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='ccy' value='$conf{PAYSYS_P24_MERCHANT_CURRENCY}' />
<input type='hidden' name='merchant' value='$conf{PAYSYS_P24_MERCHANT_ID}' />
<input type='hidden' name='order' value='$FORM{OPERATION_ID}' />
<input type='hidden' name='details' value='%LOGIN% $FORM{DESCRIBE} # $FORM{OPERATION_ID}' />
<input type='hidden' name='ext_details' value='%FIO% %CONTRACT_ID% %CONTRACT_DATE%' />
<input type='hidden' name='pay_way' value='privat24' />
<input type='hidden' name='return_url' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi' />
<input type='hidden' name='server_url' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi' />


<tr><th colspan=2><input type=submit value='$_ADD'>
<!-- <button type='submit'><img src='https://privat24.privatbank.ua/p24/img/buttons/api_logo_2.jpg' border='0' /></button> -->

</th></tr>
</table>
</form>
