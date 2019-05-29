<form class='form form-horizontal ' action=$SELF_URL method='POST'>
  <input type='hidden' name='DATE' value='%DATE%'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='day' value='%day%'>

  <div class='box box-theme box-big-form'>
    <div class='box-body'>
      <div class='form-group'>
        <label class='col-md-2 control-label'>_{POSITION}_:</label>
        <div class='col-md-3'>
          %POSITION%
        </div>
        <label class='col-md-2 control-label'>_{DEPARTMENT}_:</label>
        <div class='col-md-3'>
          %DEPARTMENT%
        </div>
        <div class='col-md-2'>
          <div class='btn-group'>
            %BTN_LOAD_TO_MODAL%
            %BTN_CHART%
            %BTN_PRINT%
          </div>
        </div>
      </div>
    </div>
  </div>
  %TABLE%
  <input type='submit' name='change' value='_{CHANGE}_' class='btn btn-primary'>
</form>