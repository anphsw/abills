<form action='%URL%' method='get' target='_blank'>
    <input type='hidden' name='merchant_id' value='%MERCHANT_ID%' />
    <input type='hidden' name='merchant_user_id' value='%UID%' />
    <input type='hidden' name='service_id' value='%SERVICE_ID%' />
    <input type='hidden' name='transaction_param' value='%TRANSACTION_ID%' />
    <input type='hidden' name='amount' value='%AMOUNT%' />

    <div class='card box-primary '>
        <div class='card-header with-border'><h4>_{BALANCE_RECHARCHE}_</h4></div>

        <div class='card-body'>
            <div class='form-group'>
                <label class='col-md-6 control-label text-right'>_{ORDER}_:</label>
                <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
            </div>

            <div class='form-group'>
                <label class='col-md-6 control-label text-right'> _{PAY_SYSTEM}_:</label>
                <label class='col-md-6 control-label'>Click</label>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-6 text-right'>_{SUM}_:</label>
                <label class='control-label col-md-6'> $FORM{SUM} </label>
            </div>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type=submit value=_{PAY}_>
        </div>
    </div>
</form>