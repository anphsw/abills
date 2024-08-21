<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{POWER_SERVICE_TYPE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='PHONE' name='NAME' value='%NAME%' class='form-control' required type='text'>
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