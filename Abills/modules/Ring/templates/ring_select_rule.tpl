<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value='$index'>

<div class='panel panel-primary panel-form'>
<div class='panel-heading text-primary'>_{RULES_LIST}_</div>
<div class='panel-body'>
        <div class='form-group'>
			<label class='col-md-3 control-label'>_{RULE}_</label>
			<div class='col-md-9'>
			    %RULE_SELECT%
			</div>
		</div>
</div>

<div class='panel-footer'>
	<button type='submit' class='btn btn-primary'>_{SELECT}_</button>
</div>

</div>

</form>