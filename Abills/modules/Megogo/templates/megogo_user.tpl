<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value=%INDEX%>
<input type='hidden' name='UID' value=%UID%>
<input type='hidden' name='unsubscribe' value=%UNSUBSCRIBE%>

<div class='panel panel-primary panel-form'>
<div class='panel-heading text-primary'>_{SUBSCRIBE}_</div>

<div class='panel-body'>
		<div class='form-group text-center'>
			<label class='control-label'>_{FREE_PERIOD}_ : %FREE_PERIOD%</label>
		</div>

		%TABLES%

</div>

</div>
</form>