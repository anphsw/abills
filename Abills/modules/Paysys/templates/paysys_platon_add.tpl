<form action=%PAY_URL% method="POST">

<input type='hidden' name='key' value=%KEY%>
<input type='hidden' name='payment' value=%PAYMENT%>
<input type='hidden' name='order' value=%OID%>
<input type='hidden' name='data' value=%PRODUCT_DATA%>
<input type='hidden' name='ext1' value=%UID%>
<input type='hidden' name='url' value=%URL_OK%>
<input type='hidden' name='sign' value=%SIGNATURE%>

<div class='panel panel-primary'>
    <div class='panel-heading text-center'>_{BALANCE_RECHARCHE}_</div>


<div class='panel-body'>
	<div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_</label>
		<label class='col-md-6 control-label'>$FORM{OPERATION_ID}</label>
	</div>
	<div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{PAY_SYSTEM}_</label>
		<label class='col-md-6 control-label'>PLATON</label>
	</div>
	<div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_</label>
		<label class='control-label col-md-6'>$FORM{SUM}</label>
	</div>
	<div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SERVICE_FEE}_</label>
		<label class='control-label col-md-6'>%COMMISSION%</label>
	</div>
	<div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{TOTAL}_</label>
		<label class='control-label col-md-6'>%TOTAL%</label>
	</div>
</div>

<div class='panel-footer text-center'>
    <input class='btn btn-primary' type=submit value=_{PAY}_>
</div>

</div>
</form>