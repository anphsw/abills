<form method='post' class='form'>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='poll'  value='$FORM{poll}'>
<input type='hidden' name='UID'   value='%UID%'> 
<input type='hidden' name='RESULT' value='1'>

	<div class='panel panel-%PANEL_COLOR%'>
	<div class='panel-heading text-primary'><h3>%SUBJECT%</h3></div>
	<div class='panel-body'>
		<div class='form-group'>
			<h4>%DESCRIPTION%</h4>
		</div>
		<div class='form-group'>
			%ANSWERS%
		</div>
	</div>
	<div class='panel-footer'>
		%BUTTONS%
	</div>
	</div>
</form>