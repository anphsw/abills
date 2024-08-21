<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='stop_form' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{POWER_STOP_GENERATOR}_</h4>
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
        <label class='col-md-4 col-form-label text-md-right required' for='STOP_DATE'>_{DATE}_:</label>
        <div class='col-md-8'>
          %STOP_DATE%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>