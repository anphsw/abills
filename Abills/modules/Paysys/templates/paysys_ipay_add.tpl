<form id=pay name=pay method='POST' action='https://api.ipay.ua/simple/'>
    <input type='hidden' name='good'
           value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=%IPAY_PAYMENT_NO%'>
    <input type='hidden' name='bad'
           value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=FALSE&trans_num=%IPAY_PAYMENT_NO%'>
    <input type='hidden' name='IPAY_PAYMENT_NO' value='%IPAY_PAYMENT_NO%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='sid' value='%sid%'>
    <input type='hidden' name='IP' value='%IP%'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='id' value='%MERCHANT_ID%'>
    <input type='hidden' name='amount' value='%amount%'>
    <input type='hidden' name='desc' value='%desc%'>
    <input type='hidden' name='info' value='%info%'>

    <div class='card box-primary'>
        <div class='card-header with-border text-center'>IPAY: _{BALANCE_RECHARCHE}_</div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-6 control-label'>_{ORDER}_:</label>
                <label class='col-md-6 control-label'>%IPAY_PAYMENT_NO%</label>
            </div>

            <div class='form-group row'>
                <label class='col-md-6 control-label'>_{DESCRIBE}_:</label>
                <label class='col-md-6 control-label'>%desc%</label>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-6'>_{SUM}_:</label>
                <label class='control-label col-md-6'> %SUM% %amount_with_point%</label>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-12'>
                    <a href=https://ipay.ua/ua/menu/questions_and_answers/ target=_new
                       class='btn btn-default'>_{HELP}_</a></label>
            </div>

        </div>
        <div class='card-footer row'>
            <input class='btn btn-primary' type=submit value='_{PAY}_'>
        </div>
    </div>

</form>
