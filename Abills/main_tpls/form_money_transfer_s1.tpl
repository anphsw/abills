<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>

<div class='panel panel-primary'>
<div class='panel-heading text-center'>
	<h4>_{MONEY_TRANSFER}_</h4>
</div>
<div class='panel-body form form-horizontal'>
<div class='form-group'>
	<label class='col-md-3 control-label'>_{TO_USER}_ (UID):</label>
	<div class='col-md-9'><input type=text name=RECIPIENT value='%RECIPIENT%' class='form-control'></div>
</div>
<div class='form-group'>
	<label class='col-md-3 control-label'>_{SUM}_:</label>
	<div class='col-md-9'><input type=text name=SUM value='%SUM%' class='form-control'></div>
</div>
</div>
<div class='panel-footer text-center'>
<input type=submit name=s2 value='_{SEND}_' class='btn btn-primary'>
</div>
</div>

</form>
 