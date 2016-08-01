<form class='form-horizontal'>

<input type='hidden' name='action' value='%ACTION%'>
<input type='hidden' name='index' value='%INDEX%'>
<input type='hidden' name='id' value='%ID%'>

<div class='panel panel-primary panel-form'>
<div class='panel-heading'><h4>Vlan</h4></div>
<div class='panel-body'>
	<div class='form-group'>
		<label class='control-label col-md-3 required'>_{NUMBER}_</label>
		<div class='col-md-9'>
			<input type='number' required class='form-control' name='NUMBER' value='%NUMBER%'>
		</div>
	</div>
	<div class='form-group'>
		<label class='control-label col-md-3 required'>_{NAME}_</label>
		<div class='col-md-9'>
			<input type='text' required class='form-control' name='NAME' value='%NAME%'>
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{COMMENTS}_</label>
		<div class='col-md-9'>
			<textarea type='text' class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
		</div>
	</div>
</div>
<div class='panel-footer'>
	<input type='submit' class='btn btn-primary' value='%BUTTON%'>
</div>
</div>

</form>