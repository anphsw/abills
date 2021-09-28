<form action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='add_delivery' value='%ID%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card container-md'>
    <div class='card-header'>
      <h4 class='card-title'>
        _{ADD_DELIVERY}_
      </h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label required' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-9'>
          <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' required placeholder='%SUBJECT%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label required' for='TEXT'>_{MESSAGES}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control' required rows='5' id='TEXT' name='TEXT'
                    placeholder='_{TEXT}_'>%TEXT%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TEXT'>_{SEND_TIME}_:</label>
        <div class='col-md-9'>
          %DATE_PIKER%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='TEXT'></label>
        <div class='col-md-9'>
          %TIME_PIKER%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-9'>
          %PRIORITY_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='SEND_METHOD'>_{SEND}_:</label>
        <div class='col-md-9'>
          %SEND_METHOD_SELECT%
        </div>
      </div>
    </div>
    <div class='card-footer'><input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'></div>
  </div>
</form>