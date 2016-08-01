<form action=%ACTIONFORM% method=POST>
    
    <input type=hidden name=clientid value=%CLIENTID%>
    <input type=hidden name=sum value=%SUMMA%>
    <input type=hidden name=orderid value=%OID%>
    <input type=hidden name=phone value=%PHONE%>
    
<div class='panel panel-primary'>
    <div class='panel-heading text-center'>_{BALANCE_RECHARCHE}_</div>
<div class='panel-body'>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>PAYKEEPER</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6 text-left'> %SUMMA% </label>
    </div>
</div>

<div class='panel-footer text-center'>
    <input class='btn btn-primary' type=submit value=_{PAY}_>
</div>

</div>
</form>