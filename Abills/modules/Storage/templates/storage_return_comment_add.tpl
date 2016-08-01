
<form action=$SELF_URL  name=\"storage_return_comment\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=return_storage value=$FORM{return_comment}>

<div class='panel panel-primary' style='max-width: 70%;'>

<div class='panel-body form form-horizontal'>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{COMMENTS}_:</label>
		<div class='col-md-9'><textarea class='form-control' name=\"COMMENTS\">%COMMENTS%</textarea></div>
	</div>
</div>

<div class='panel-footer'>
	<input class='btn btn-primary' type=submit name='%ACTION%' value='%ACTION_LNG%'>
</div>

</div>
</form>