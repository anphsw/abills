<form action='%SELF_URL%' method='post' name='invoice_add'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='UID' value='%UID%'>
    <input type='hidden' name='DOC_ID' value='%DOC_ID%'>
    <input type='hidden' name='sid' value='$FORM{sid}'>
    <input type='hidden' name='step' value='%step%'>
    <input type='hidden' name='OP_SID' value='%OP_SID%'>
    <input type='hidden' name='VAT' value='%VAT%'>
    <input type='hidden' name='SEND_EMAIL' value='1'>
    <input type='hidden' name='ALL_SERVICES' value='1'>

    <div class='card container-md'>
        <div class='card-header with-border'>
            <h3 class='card-title'>%CAPTION%</h3>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='DATE'>_{DATE}_:</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        %DATE%
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3'
                       for='CURENT_BILLING_PERIOD'>_{CURENT_BILLING_PERIOD}_:</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        <input type='text' readonly id='CURENT_BILLING_PERIOD' name='CUSTOMER'
                               value='%CURENT_BILLING_PERIOD_START% - %CURENT_BILLING_PERIOD_STOP%'
                               placeholder='%CUSTOMER%'
                               class='form-control'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='PERIOD'>_{PERIOD}_:</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        %PERIOD_DATE%
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='INCLUDE_CUR_BILLING_PERIOD1'>_{INCLUDE_CUR_BILLING_PERIOD}_:</label>
                <div class='col-sm-12 col-md-9 p-1'>
                    <div class='form-check'>
                        <input type='radio' class='form-check-input' id='INCLUDE_CUR_BILLING_PERIOD1'
                               name='INCLUDE_CUR_BILLING_PERIOD' value='0'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='INCLUDE_CUR_BILLING_PERIOD2'>_{NOT_INCLUDE_CUR_BILLING_PERIOD}_:</label>
                <div class='col-sm-12 col-md-9 p-1'>
                    <div class='form-check'>
                        <input type='radio' class='form-check-input' id='INCLUDE_CUR_BILLING_PERIOD2'
                               name='INCLUDE_CUR_BILLING_PERIOD' value='1'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='NEXT_PERIOD'>_{NEXT_PERIODS}_ (_{MONTH}_):</label>
                <div class='col-sm-12 col-md-9'>
                    <div class='input-group'>
                        <input type='text' name='NEXT_PERIOD' ID='NEXT_PERIOD' value='%NEXT_PERIOD=0%' size='5'
                               class='form-control'>
                    </div>
                </div>
            </div>


            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='SEND_EMAIL'>_{SEND}_ E-mail:</label>
                <div class='col-sm-12 col-md-9 p-1'>
                    <div class='form-check'>
                        <input type='checkbox' data-return='1' class='form-check-input' id='SEND_EMAIL'
                               name='SEND_EMAIL' value='1'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-sm-12 col-md-3' for='INCLUDE_DEPOSIT'>_{INCLUDE_DEPOSIT}_:</label>
                <div class='col-sm-12 col-md-9 p-1'>
                    <div class='form-check'>
                        <input type='checkbox' data-return='1' class='form-check-input' id='INCLUDE_DEPOSIT'
                               name='INCLUDE_DEPOSIT' value='1'>
                    </div>
                </div>
            </div>

            <div class='form-group'>
              %ORDERS%
            </div>

        </div>
        <div class='card-footer'>
           %BACK%
           <input type='submit' name='update' value='_{REFRESH}_' class='btn btn-secondary'>
           <input type='submit' name='create' value='_{CREATE}_' class='btn btn-primary'>
           %NEXT%
        </div>
    </div>
</form>
