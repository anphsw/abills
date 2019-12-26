<form action='$SELF_URL' method='POST' class='form-horizontal' id='DILLER_OPERATION_LOG'>
    <input type='hidden' name='index' value="%INDEX%">
    <input type='hidden' name='sid' value="%SID%">
    <input type='hidden' name='operations_log' value="1">

    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4 class='box-title'>_{LIST_OF_LOGS}_</h4></div>

        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-4 col-sm-3 control-label'>_{PERIOD}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %PERIOD%
                </div>
            </div>
            <input class='btn btn-primary col-md-12 col-sm-12' type='submit' value='_{SEARCH}_'>
        </div>
    </div>
</form>

