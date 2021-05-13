<form method='post' action='%URL%' accept-charset='utf-8'>
    <input type="hidden" name="OPERATION_ID" value="%OPERATION_ID%">
    <input type='hidden' name='signature' value='%SIGN%'/>
    <input type='hidden' name='index' value='%index%'>
    %BODY%
    <div class='container-fluid'>
        <div class='box box-primary'>
            <div class='box-header with-border text-center'>_{UNSUBSCRIBE_LIQPAY}_</div>
            <div class='form-group'>
                <div class="font-weight-bold text-center col-md-12 form-control-label">
                    <label>  На суму %SUM% наступна дата списання %DATE% </label>
                </div>
            </div>
           <div class='box-body'>
                <div class='form-group'>
                    <img class='col-xs-8 col-xs-offset-2' src='https://www.liqpay.ua/static/img/logo.png' />
                </div>
            </div>
            <div class='box-footer text-center'>
                <a class='btn btn-primary btn-lg center' role="button" aria-disabled="true" href="%HREF%" name='cancel_delete'>_{HANGUP}_
                </a>
            </div>

        </div>
    </div>
</form>
