<form method='post' class='form'>

<input type='hidden' name='poll' value='$FORM{poll}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='LOGIN'   value='%LOGIN%'>
<input type='hidden' name='DISCUSSION' value='1'>

<div class='panel panel-default'>
	<div class='panel-heading text-primary'><h3>%SUBJECT%</h3></div>
	<div class='panel-body text-left'>
		%MESSAGE%
	</div>
	<div class='panel-footer'>
	  <div class='form-group'>
		  <textarea class='form-control' name='MESSAGE' rows='10'></textarea>
	  </div>
	  <div class='form-group'>
          <input type='submit' class='btn btn-primary' value='_{SEND}_'>
	  </div>
	</div>
</div>

</form>