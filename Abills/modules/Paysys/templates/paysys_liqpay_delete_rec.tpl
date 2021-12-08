<div class='card card-primary card-outline'>
    <form method='post' action='%URL%' accept-charset='utf-8'>
        <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
        <input type='hidden' name='signature' value='%SIGN%'/>
        <input type='hidden' name='index' value='%index%'>
        %BODY%
        <div class='card-header with-border text-center pb-0'>
            <h4>_{CANCEL_RECURRENT_PAYMENT}_</h4>
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <div class='font-weight-bold text-center col-md-12 form-control-label'>
                    <br>
                    <label> _{UNSUBSCRIBE_LIQPAY}_ </label>
                    <br>
                    <label> На суму %SUM% наступна дата списання %DATE% </label>
                </div>
            </div>
        </div>
        <div class='box-footer text-center'>
            <a class='btn btn-primary btn center mb-2' role='button' aria-disabled='true' href='%HREF%'
               name='cancel_delete'>_{HANGUP}_
            </a>
        </div>
    </form>
</div>