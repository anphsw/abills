<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>


<div class='panel panel-primary panel-form'>
<div class='panel-heading'>%ACTION_LNG%</div>

<div class='panel-body form-horizontal'>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{NAME}_:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='NAME' value='%NAME%' /></div>
	</div>
	
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{COMMENTS}_:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='COMMENTS' value='%COMMENTS%' /></div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>IP:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='IP' value='%IP%' /></div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>NETMASK:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='NETMASK' value='%NETMASK%' /></div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>_{GROUP}_:</label>
		<div class='col-md-9'>%PARENT_SELECT%</div>
	</div>

</div>
<div class='panel-footer'>
	<input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</div>

</div>

</form>
