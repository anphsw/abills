<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
<input type='hidden' name='index' value='$index'/>
<!-- <input type='hidden' name='ID' value='%ID%'/> -->

<div class='panel panel-default panel-form'>
  <div class='panel-body'>

<fieldset>
    <legend>_{SERVICE}_ _{STATUS}_</legend>

<div class='form-group'>
    <label class='control-label col-md-3' for='ID'>_{NUM}_:</label>
  <div class='col-md-9'>
      <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
  </div>  
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
  <div class='col-md-9'>
      <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
  </div>  
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='COLOR'>_{COLOR}_:</label>
  <div class='col-md-9'>
  	 <select name='COLOR' id='colorPicker' value='%COLOR%'></select>
  </div>  
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='TYPE'>_{TYPE}_:</label>
  <div class='col-md-9'>
      %TYPE_SEL%
  </div>  
</div>
	
<input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>

</fieldset>
</div>
</div>

</form>

<script src='/styles/default_adm/js/colorpicker.js'></script>