<form action=$SELF_URL METHOD=POST class='form-horizontal' enctype=multipart/form-data>

<input type='hidden' name='index' value=%INDEX%>

<div class='panel panel-primary panel-form'>
<div class='panel-heading text-primary'>_{UPLOAD}_</div>

<div class='panel-body'>
	<label class='col-md-3'>_{FILE}_</label>
	<div class='col-md-9'><input type='file' name=FILE></div>
</div>

<div class='panel-footer text-center'>
	<button type='submit' class='btn btn-primary'>_{ADD}_</button>
</div>
</div>

</form>