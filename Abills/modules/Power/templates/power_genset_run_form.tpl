<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='run_form' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{POWER_GENERATOR_START}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{ADDRESS}_:</label>
        <div class='col-md-8'>
          <input class='form-control' readonly value='%ADDRESS_FULL%' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{POWER_GENERATOR_TYPE}_:</label>
        <div class='col-md-8'>
          <input class='form-control' readonly value='%TYPE%' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='START_DATE'>_{DATE}_:</label>
        <div class='col-md-8'>
          %START_DATE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{POWER_START_TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{POWER_DID_THE_GENERATOR_START}_</label>
        <div class='col-md-8'>
          %RESULT_SEL%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>