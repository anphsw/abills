<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{POWER_GENERATOR_TYPE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='PHONE' name='NAME' value='%NAME%' class='form-control' required type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LITRES_PER_HOUR'>_{POWER_CONSUMPTION_PER_HOUR_IN_LITERS}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='number' name='LITRES_PER_HOUR' id='LITRES_PER_HOUR' value='%LITRES_PER_HOUR%' min='0'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PHASE'>_{POWER_NUMBER_OF_PHASES}_:</label>
        <div class='col-md-4 pt-2'>
          <div class='form-check'>
            <input class='form-check-input' type='radio' %PHASE_1_CHECKED% value='1' id='phase-1' name='PHASE'>
            <label class='form-check-label' for='phase-1'>1</label>
          </div>
        </div>
        <div class='col-md-4 pt-2'>
          <div class='form-check'>
            <input class='form-check-input' type='radio' %PHASE_3_CHECKED% value='3' id='phase-3' name='PHASE'>
            <label class='form-check-label' for='phase-3'>3</label>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='POWER_KVA'>_{POWER_POWER_IN_KVA}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='number' name='POWER_KVA' id='POWER_KVA' value='%POWER_KVA%' min='0'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='POWER_KW'>_{POWER_POWER_IN_KW}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='number' name='POWER_KW' id='POWER_KW' value='%POWER_KW%' min='0'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESCRIPTION'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='DESCRIPTION' id='DESCRIPTION'>%DESCRIPTION%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>