<div class='card card-primary card-outline'>
    <form action='%URL%' method='get' target='_blank'>
        <input type='hidden' name='merchant_id' value='%MERCHANT_ID%'/>
        <input type='hidden' name='merchant_user_id' value='%UID%'/>
        <input type='hidden' name='service_id' value='%SERVICE_ID%'/>
        <input type='hidden' name='transaction_param' value='%TRANSACTION_ID%'/>
        <input type='hidden' name='amount' value='%AMOUNT%'/>

        <div class='card-header with-border text-center'>
            <h4>_{BALANCE_RECHARCHE}_</h4>
        </div>
        <div class='card-body'>
            <div class='form-group text-center'>
                <img src='/styles/default/img/paysys_logo/click-logo.png'
                     style='width: auto; max-height: 200px;'
                     alt='click'>
            </div>

            <table style='min-width:350px;' width='auto'>
                <tr>
                    <td>_{PAY_SYSTEM}_:</td>
                    <td>Click</td>
                </tr>
                <tr>
                    <td>_{ORDER}_:</td>
                    <td>$FORM{OPERATION_ID}</td>
                </tr>
                <tr>
                    <td>_{SUM}_:</td>
                    <td>$FORM{SUM}</td>
                </tr>
                <tr>
                    <td>_{DESCRIBE}_:</td>
                    <td>$FORM{DESCRIBE}</td>
                </tr>
            </table>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type=submit value=_{PAY}_>
        </div>
    </form>
</div>