<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='STATE' value='%STATE%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{POWER_GENERATOR}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{POWER_GENERATOR_TYPE}_:</label>
        <div class='col-md-8'>
          %TYPES_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='FUELTANK_ID'>_{POWER_TANK_TYPE}_:</label>
        <div class='col-md-8'>
          %FUELTANKS_SEL%
        </div>
      </div>

      %ADDRESS_TPL%
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>