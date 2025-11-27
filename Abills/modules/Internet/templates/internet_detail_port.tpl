<form method='post' name='IPN_DETAIL_PORT_FORM' action=%SELF_URL%>
    <div class='form-control row form-inline ml-auto flex-nowrap'>
        <input type='hidden' name='index' value='%index%'/>

        <label for='S_TIME'>_{DATE}_</label>
        <input type='text' class='form-control datepicker' name='S_TIME' id='S_TIME' value='%S_TIME%'/>

        <label for='F_TIME'>-</label>
        <input type='text' class='form-control datepicker' name='F_TIME' id='F_TIME' value='%F_TIME%'/>

        <label for='PORTS'>_{PORT}_</label>
        %PORTS_SELECT%

        <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>

    </div>
</form>