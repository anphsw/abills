<form name='MAPS_DISTRICT' id='form_MAPS_DISTRICT' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='RETURN_FORM' value='COLOR'/>
  <input type='hidden' name='OBJECT_ID' value='%OBJECT_ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'><h4 class='card-title'>_{DISTRICT}_</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='DISTRICT_ID'>_{DISTRICT}_</label>
        <div class='col-md-9'>
          %DISTRICT_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='COLOR'>_{COLOR}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%'/>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' form='form_MAPS_DISTRICT' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>

