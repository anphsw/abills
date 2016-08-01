<form ction=$SELF_URL METHOD=POST>
<input type='hidden' name='index' value='$index'>
  <div class='panel panel-primary panel-form form-horizontal'>
  <div class='panel-heading text-center'><h4>_{TYPE}_</h4></div>
  <div class='panel-body'>
    <div class='form-group'>
      <label class='col-md-3 control-label'>_{NAME}_</label>
      <div class='col-md-9'>
      <input type='text' class='form-control' name='TYPE' value='%TYPE%'>
      </div>
    </div>
    <div class='radio'>
    <label>
      <input type='radio' name='DATA_TYPE' id='optionsRadios1' value='1' required='required' %COUNTER%> Показетель счетчика
    </label>
    <label>
      <input type='radio' name='DATA_TYPE' id='optionsRadios2' value='2' %MONEY%> Деньги
    </label>
  </div>
  </div>
  <div class='panel-footer text-center'>
    <input  type='submit' class='btn btn-primary' value='%BTN_NAME%'>
  </div>
  </div>
</form>