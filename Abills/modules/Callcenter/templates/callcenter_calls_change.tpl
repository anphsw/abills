<form action=%SELF_URL% METHOD=POST>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='change' value=%ID%>

  <div class='card card-primary card-outline box-form'>
  
  <div class='card-header with-border text-primary'>_{CHANGE}_ ID: %ID%</div>

  <div class='card-body'>
    <div class='form-group row'>
      <label class='control-label col-md-3'>_{STATUS}_</label>
      <div class='col-md-9'>
        %STATUS_SELECT%
      </div>
    </div>
    <div class='form-group row'>
      <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
      <div class='col-md-9'>
        <input class='form-control' type='text' id='DATE'  name='DATE' value='%DATE%' disabled='disabled'>
      </div>
    </div>
    <div class='form-group row'>
      <label class='control-label col-md-3' for='USER_PHONE'>_{USER}_ _{PHONE}_</label>
      <div class='col-md-9'>
        <input class='form-control' type='text' name='USER_PHONE' id='USER_PHONE' value='%USER_PHONE%' disabled='disabled'>
      </div>
    </div>
    <div class='form-group row'>
      <label class='control-label col-md-3' for='OPERATOR_PHONE'>_{OPERATOR}_ _{PHONE}_</label>
      <div class='col-md-9'>
        <input class='form-control' type='text' id='OPERATOR_PHONE'  name='OPERATOR_PHONE' value='%OPERATOR_PHONE%' disabled='disabled'>
      </div>
    </div>
    <div class='form-group row'>
      <label class='control-label col-md-3' for='RECORD'>_{LISTEN}_</label>
      <div class='col-md-9 p-1'>
        <audio controls style='width: 500px;height: 30px;'><source src='%FILE_PATH%' type='audio/wav'></audio>
      </div>
    </div>
  </div>

  <div class='card-footer'>
    <button type='submit' class='btn btn-primary'>_{CHANGE}_</button>
  </div>
  </div>
</form>