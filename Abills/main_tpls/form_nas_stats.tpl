<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='NAS_ID' value=$FORM{NAS_ID}>
<input type='hidden' name='subf' value=$FORM{subf}>

<div class='panel panel-primary panel-form form-horizontal'>
<div class='panel-heading'>_{STATS}_(%DATE%)</div>
<div class='panel-body'>
	<div class='form-group'>
		<label class='col-md-5 control-label'>Online _{USERS}_:</label>
		<div class='col-md-7'>
			<input type='text' class='form-control' disabled name='USERS_ONLINE' value='%USERS_ONLINE%'>
		</div>
	</div>
	<hr>
	<div class='form-group'>
		<label class='col-md-5 control-label'>_{LAST_LOGIN}_:</label>
		<div class='col-md-7'>
			<input type='text' class='form-control' disabled name='LAST_CONNECT' value='%LAST_CONNECT%'>
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-5 control-label'>_{FIRST_LOGIN}_:</label>
		<div class='col-md-7'>
			<input type='text' class='form-control' disabled name='FIRST_CONNECT' value='%FIRST_CONNECT%'>
		</div>
	</div>
	<hr>
	<div class='form-group'>
		<label class='control-label col-md-5'>_{DATE}_</label>
		<div class='col-md-7'>
	 	  <input type='text' name='DATE' value='%DATE%' class='form-control tcal' >
	 </div>
	</div>
	<div class='form-group'>
		<label class='col-md-5 control-label'>_{SUCCESS_CONNECTIONS}_ / _{DAY}_:</label>
		<div class='col-md-7'>
			<input type='text' class='form-control' disabled name='SUC_CONNECTS_PER_DAY' value='%SUC_CONNECTS_PER_DAY%'>
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-5 control-label'>_{SUCCESS_ATTEMPTS}_ / _{DAY}_:</label>
		<div class='col-md-7'>
		<div class='input-group'>
			<input type='text' class='form-control' disabled name='SUC_ATTEMPTS_PER_DAY' value='%SUC_ATTEMPTS_PER_DAY%'>
			<span class='input-group-btn'>
			<a href='$SELF_URL?index=%FUNC_INDEX%&LOG_TYPE=%LOG_INFO%&DATE=%DATE%' class='btn btn-info'>_{SHOW}_</a>
			</span>
			</div>
		</div>
	</div>
	<div class='form-group'>
		<label class='col-md-5 control-label'>_{FALSE_ATTEMPTS}_ / _{DAY}_:</label>
		<div class='col-md-7'>
			<div class='input-group'>
			<input type='text' class='form-control' disabled name='FALSE_ATTEMPTS_PER_DAY' value='%FALSE_ATTEMPTS_PER_DAY%'>
			<span class='input-group-btn'>
			<a href='$SELF_URL?index=%FUNC_INDEX%&LOG_TYPE=%LOG_WARN%&DATE=%DATE%' class='btn btn-danger'>_{SHOW}_</a>
			</span>
			</div>
		</div>
	</div>
</div>
<div class='panel-footer'>
<button type='submit' class='btn btn-primary'>Check</button>
</div>
</div>
</form>