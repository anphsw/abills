<form action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='add_delivery' value='%ID%'>
  <input type='hidden' name='ID' value='%ID%'>
    <div class='card'>
      <div class='card-header'>
        <h4 class='card-title'>
          _{ADD_DELIVERY}_
        </h4>
      </div>
      <div class='card-body'>
        <div class="form-group row">
          <label class="col-sm-4 col-md-4 col-form-label required" for='SUBJECT'>_{SUBJECT}_:</label>
          <div class="col-sm-8 col-md-8">
            <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' required placeholder='%SUBJECT%' %DISABLE% class='form-control' type='text'>
          </div>
        </div>

        <div class="form-group row">
          <label class="col-sm-4 col-md-4 col-form-label required" for='TEXT'>_{MESSAGES}_:</label>
          <div class="col-sm-8 col-md-8">
            <textarea class='form-control'  required rows='5' %DISABLE% id='TEXT' name='TEXT'  placeholder='_{TEXT}_' >%TEXT%</textarea>
          </div>
        </div>

        <div class="form-group row">
          <label class="col-sm-4 col-md-4 col-form-label" for='TEXT'>_{SEND_TIME}_:</label>
          <div class="col-sm-8 col-md-8">
            %DATE_PIKER%
          </div>
        </div>

        <div class="form-group row">
          <label class="col-sm-4 col-md-4 col-form-label" for='TEXT'></label>
          <div class="col-sm-8 col-md-8">
            %TIME_PIKER%
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='STATUS'>_{STATUS}_:</label>
        <div class="col-sm-8 col-md-8">
          %STATUS_SELECT%
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='PRIORITY'>_{PRIORITY}_:</label>
        <div class="col-sm-8 col-md-8">
          %PRIORITY_SELECT%
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 col-form-label" for='SEND_METHOD'>_{SEND}_:</label>
        <div class="col-sm-8 col-md-8">
          %SEND_METHOD_SELECT%
        </div>
      </div>

      <div class='card-footer'><input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'></div>

    </div>
  </div>
</form>