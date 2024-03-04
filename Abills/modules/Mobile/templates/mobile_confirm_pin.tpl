<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{MOBILE_CONFIRMATION_ACTIVATION}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PHONE'>_{PHONE}_:</label>
        <div class='col-md-8'>
          <input id='PHONE' name='PHONE' value='%PHONE%' readonly class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PIN'>PIN:</label>
        <div class='col-md-8'>
          <input id='PIN' name='PIN' class='form-control' type='text'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-danger' name='cancel_confirm' value='_{UNDO}_'>
      <input type='submit' class='btn btn-primary' name='confirm_pin' value='_{MOBILE_CONFIRM}_'>
    </div>
  </div>
</form>