<form action='https://paymaster.ru/Payment/Init' method='POST'>

<input type='hidden' name='LMI_MERCHANT_ID'    value='%LMI_MERCHANT_ID%'>
<input type='hidden' name='LMI_PAYMENT_AMOUNT' value='%SUM%'>
<input type='hidden' name='LMI_CURRENCY'       value='%CURRENCY%'>
<input type='hidden' name='LMI_PAYMENT_NO'     value='%ORDER_ID%'>
<input type='hidden' name='LMI_SIM_MODE'       value='%SIM_MOD%'>
<input type='hidden' name='LMI_PAYMENT_DESC'   value='Internet'>
<input type='hidden' name='LMI_PAYMENT_NOTIFICATION_URL'   value='%NOTIFICATION_URL%'>
<input type='hidden' name='LMI_SUCCESS_URL'   value='%SUCCESS_URL%'>
<input type='hidden' name='LMI_FAILURE_URL'   value='%FAILURE_URL%'>
<input type='hidden' name='USER'               value='%USER%'>
<input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].NAME'  value='%NAME%'>
<input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].QTY'  value='%QTY%'>
<input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].PRICE'  value='%PRICE%'>
<input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].TAX'  value='%TAX%'>
<input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].METHOD'  value='%METHOD%'>
<input type='hidden' name='LMI_SHOPPINGCART.ITEMS[0].SUBJECT'  value='%SUBJECT%'>
<input type='hidden' name='LMI_PAYER_EMAIL' value='%LMI_PAYER_EMAIL%' >

<div class='card box-primary'>
    <div class='card-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='card-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>%ORDER_ID%</label>
    </div>

    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>Paymaster Ru</label>
    </div>

    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> %SUM% </label>
    </div>
%Checkbox%
</div>
    <div class='card-footer'>
        <input class='btn btn-primary' type=submit value='_{PAY}_'>
    </div>
</div>

</form>
