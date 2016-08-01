<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>

<fieldset>
<div class='col-md-6'>
<div class='panel panel-default panel-form'>
<div class='panel-heading text-center'><h4>_{ADDRESS_BUILD}_</h4></div>
<div class='panel-body'>



<div class='form-group'>
  <label class='control-label col-md-3' for='NUMBER'>_{NUM}_:</label>
  <div class='col-md-9'>
      <input id='NUMBER' name='NUMBER' value='%NUMBER%' placeholder='%NUMBER%' class='form-control' type='text'>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-3' for='STREET_SEL'>_{ADDRESS_STREET}_:</label>
  <div class='col-md-9'>
    %STREET_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='ENTRANCES'>_{ENTRANCES}_:</label>
  <div class='col-md-9'>
      <input id='ENTRANCES' name='ENTRANCES' value='%ENTRANCES%' placeholder='%ENTRANCES%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='FLORS'>_{FLORS}_:</label>
  <div class='col-md-9'>
      <input id='FLORS' name='FLORS' value='%FLORS%' placeholder='%FLORS%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='FLATS'>_{FLATS}_:</label>
  <div class='col-md-9'>
      <input id='FLATS' name='FLATS' value='%FLATS%' placeholder='%FLATS%' class='form-control' type='text'>
  </div>
</div>
</div>
</div>
</div>
<div class='col-md-6'>
      <div class='form-group'>
        <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
           <a data-toggle='collapse' data-parent='#accordion' href='#nas_misc'>_{MISC}_</a>
            </div>
            <div id='nas_misc' class='panel-collapse panel-body collapse in'>

<div class='form-group'>
  <label class='control-label col-md-3' for='CONTRACT_ID'>_{CONTRACT}_:</label>
  <div class='col-md-9'>
      <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' placeholder='%CONTRACT_ID%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='CONTRACT_DATE'>_{CONTRACT}_ _{DATE}_:</label>
  <div class='col-md-9'>
      <input id='CONTRACT_DATE' name='CONTRACT_DATE' value='%CONTRACT_DATE%' placeholder='%CONTRACT_DATE%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='CONTRACT_PRICE'>_{PRICE}_:</label>
  <div class='col-md-9'>
      <input id='CONTRACT_PRICE' name='CONTRACT_PRICE' value='%CONTRACT_PRICE%' placeholder='%CONTRACT_PRICE%' class='form-control' type='text'>
  </div>
</div>


<div class='form-group'>
    <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
    <div class='col-md-9'>
      <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
    </div>
</div>

<label class='control-label col-md-3' for=''>_{MAP}_:</label>

<div class='form-group input-group'>
  <label class='control-label col-md-2' for='MAP_X'>X: </label>
  <div class='col-md-4'>
      <input id='MAP_X' name='MAP_X' value='%MAP_X%' placeholder='%MAP_X%' class='form-control' type='text'>
  </div>
  <label class='control-label col-md-2' for='MAP_Y'> Y: </label>
    <div class='col-md-4'>
      <input id='MAP_Y' name='MAP_Y' value='%MAP_Y%' placeholder='%MAP_Y%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='ADDED'>_{ADDED}_:</label>
  <div class='col-md-9'>
    %ADDED%
  </div>
</div>

</div>
</div>
</div>
</div>
    <div class='form-group'>
  <div class='col-md-12'>
    <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
      </div>
    </div>


</fieldset>



</form>
