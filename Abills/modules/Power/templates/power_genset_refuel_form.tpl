<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='fuel_form' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{POWER_ADD_REFUELING}_</h4>
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
        <label class='col-md-4 col-form-label text-md-right required' for='DATE'>_{DATE}_:</label>
        <div class='col-md-8'>
          %DATE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LITRES'>_{POWER_FILLED_LITERS}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='number' name='LITRES' id='LITRES' min='1'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LITRES_AFTER'>%LITRES_AFTER_LANG%:</label>
        <div class='col-md-8'>
          <input class='form-control' type='number' name='LITRES_AFTER' id='LITRES_AFTER' value='%LITRES_AFTER%'
                 step='0.5' min='0' max='%FUEL_LITRES%'>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>