<form action=$SELF_URL METHOD=POST>
<input type='hidden' name='index' value=%INDEX%>

<div class='panel panel-form panel-primary form-horizontal'>

<div class='panel-heading'>_{USED}_</div>
<div class='panel-body'>
<div class='form-group'>
		<label class='col-md-3 control-label'>_{YEAR}_</label>
		<div class='col-md-9'> %YEARS% </div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{MONTH}_</label>
		<div class='col-md-9'> %MONTHES% </div>
	</div>
</div>
<div class='panel-footer'>
	<button type='submit' class='btn btn-primary'>_{SHOW}_</button>
</div>

</div>
</form>