<form action='https://www.portmone.com.ua/gateway/' method='post'>
    <input type='hidden' name='payee_id' value='%PAYEE_ID%'/>
    <input type='hidden' name='shop_order_number' value='%SHOP_ORDER_NUMBER%'/>
    <input type='hidden' name='bill_amount' value='%BILL_AMOUNT%'/>
    <input type='hidden' name='bill_currency' value='%BILL_CURRENCY%'/>
    <input type='hidden' name='description' value='%DESCRIBE%'/>
    <input type='hidden' name='success_url' value='%URL_SUCCESS%'/>
    <input type='hidden' name='failure_url' value='%URL_FAILED%'/>
    <input type='hidden' name='attribute1' value='%UID%'/>

    <div class='container-fluid'>
        <div class='card box-primary'>
            <div class='card-header with-border text-center'>
                <h4 class='card-title'>Portmone</h4>
            </div>
            <div class='card-body'>

                <div class='form-group'>
                    <img class='col-xs-8 col-xs-offset-2'
                         src='/styles/default_adm/img/paysys_logo/portmone-logo.png'>
                </div>

                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
                    <label class='font-weight-bold col-md-6 form-control-label'>%SHOP_ORDER_NUMBER%</label>
                </div>

                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%SUM%</label>
                </div>

                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{COMMISSION}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%COMMISSION%</label>
                </div>

                <div class='form-group'>
                    <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{SUM}_:</label>
                    <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%BILL_AMOUNT%</label>
                </div>

            </div>
            <div class='card-footer'>
                <input class='btn btn-primary' type='submit' value='_{PAY}_'>
            </div>

        </div>
    </div>


</form>