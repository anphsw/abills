<form id='liqpay_form' method='post' action='$SELF_URL' accept-charset='utf-8'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
    <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'>
    <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'>
    <input type='hidden' name='SUM' value='%SUM%'>
    <input type='hidden' name='TOTAL_SUM' value='%TOTAL_SUM%'>
    <input type='hidden' name='PHONE' value='%PHONE%'>
    <input type='hidden' name='SUBSCRIBE_FORM' value='1'>
    %DATA%
    <div class='container-fluid'>
        <div class='box box-primary'>
            <div class='box-header with-border text-center'><img class='col-xs-8 col-xs-offset-2' src='https://www.liqpay.ua/static/img/logo.png' /></div>
            <div class='box-body'>
                <div class='form-group'>
                    _{SUBSCRIBE_LIQPAY}_
                </div>
                <div class='form-group row'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label' for='checkbox'>_{SUBSCRIBE_ACTION}_:</label>
                    <div class='col-md-6'>
                        <input type='checkbox' %SUBSCRIBE% class='pull-left text-muted' data-return='1' id='checkbox' name='SUBSCRIBE'
                               value='1'/>
                    </div>
                </div>
                <div class='form-group row'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'>_{SUBSCRIBE_DETAILS}_</label>
                    <div class='col-md-6'>
                            <a href='https://www.liqpay.ua/ru'>_{READ_HERE}_</a>
                    </div>
                </div>
            </div>
            <div class='box-footer'>
                <input class='btn btn-primary center-block' type='submit' value='_{PAY}_' name='cancel_button'>
            </div>

        </div>
    </div>
</form>
