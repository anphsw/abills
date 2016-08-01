<div class='panel panel-default panel-form'>
<div class='panel-heading'>_{SESSIONS}_</div>
<div class='panel-body'>
	<div class='form-group'>
		<label class='col-md-3 control-label'>SUM(>,<)</label>
	  	<div class='col-md-9'>
			<input class='form-control' type=text name=SUM value='%SUM%'>
	  	</div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>IP (>,<)</label>
	  	<div class='col-md-9'>
			<input class='form-control' type=text name=IP value='%IP%'>
	  	</div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>CID</label>
	  	<div class='col-md-9'>
			<input class='form-control' type=text name=CID value='%CID%'>
	  	</div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>NAS</label>
	  	<div class='col-md-9'>%SEL_NAS%</div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>NAS Port</label>
	  	<div class='col-md-9'>
	  		<input class='form-control' type=text name=NAS_PORT value='%NAS_PORT%'>
	  	</div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>SESSION_ID</label>
	  	<div class='col-md-9'>
	  		<input class='form-control' type=text name=ACCT_SESSION_ID value='%ACCT_SESSION_ID%'>
	  	</div>
	</div>

	<div class='form-group'>
		<label class='col-md-3 control-label'>_{HANGUP}_ _{STATUS}_:</label>
	  	<div class='col-md-9'>%TERMINATE_CAUSE_SEL%</div>
	</div>
</div>
</div>