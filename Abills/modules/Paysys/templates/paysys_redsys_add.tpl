<FORM name=compra METHOD=POST action='$conf{PAYSYS_REDSYS_URL}'>

<input type=hidden name='Ds_Merchant_MerchantCode' value='$conf{PAYSYS_REDSYS_MERCHANT_ID}'>
<input type=hidden name='Ds_Merchant_MerchantURL' value='$conf{PAYSYS_REDSYS_CALLBACK_URL}'>
<input type=hidden name='Ds_Merchant_UrlOK' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&OPERATION_ID=$FORM{OPERATION_ID}&TRUE=1'>
<input type=hidden name='Ds_Merchant_UrlKO' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&OPERATION_ID=$FORM{OPERATION_ID}&TRUE=1'>
<input type=hidden name='Ds_Merchant_MerchantName' value='$conf{PAYSYS_REDSYS_NAME}'>
<input type=hidden name='Ds_Merchant_Order' value='$FORM{OPERATION_ID}'>
<input type=hidden name='Ds_Merchant_Amount' value='$FORM{TOTAL_SUM}'>
<input type=hidden name='Ds_Merchant_Currency' value='$conf{PAYSYS_REDSYS_CURRENCY}'>
<input type=hidden name='Ds_Merchant_ProductDescription' value='%LOGIN% $FORM{DESCRIBE}'>
<input type=hidden name='Ds_Merchant_ConsumerLanguage' value='002'>
<input type=hidden name='Ds_Merchant_Terminal' value='1'>
<input type=hidden name='Ds_Merchant_TransactionType' value='0'>
<input type=hidden name='Ds_MerchantData' value='%UID%'>
<input type=hidden name='Ds_Merchant_MerchantSignature' value='%SIGN%'>

<table width=400 class=form>
<tr><th colspan=2 class=form_title>RedSYS</th></tr>
<tr><td>$_ORDER:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><td>$_DESCRIBE:</td><td>%LOGIN% $FORM{DESCRIBE}</td></tr>
<tr><th colspan=2 class=even><input type='submit' value='$_PAY'></th></tr>
</table>

</FORM>