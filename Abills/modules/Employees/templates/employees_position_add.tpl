<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='action' value='%ACTION%'>
<input type='hidden' name='id' value=%ID%>

<div class='panel panel-primary panel-form form-horizontal'>

<div class='panel-heading'>_{ADD_POSITION}_</div>
<div class='panel-body'>

	<div class='form-group'>
		<label class='control-element col-md-3'>_{POSITION}_</label>
		<div class='col-md-9'>
			<input type='text' class='form-control' name='POSITION' value='%POSITION%'>
		</div>
	</div>

	<div class='form-group'>
		<label class='control-element col-md-3'>_{SUBORDINATION}_</label>
		<div class='col-md-9'>
			%SUBORDINATION%
		</div>
	</div>

</div>
<div class='panel-footer'>
	<input type='submit' class='btn btn-primary' name='BUTTON' value='%BUTTON_NAME%'>
</div>

</div>

</form>