<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%index%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{REGISTRATION}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='GPS_IMEI'>GPS IMEI:</label>
        <div class='col-md-8'>
          <input id='GPS_IMEI' name='GPS_IMEI' value='%GPS_IMEI%' placeholder='%GPS_IMEI%' class='form-control' readonly type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ADMIN'>_{ADMIN}_</label>
        <div class='col-md-8'>
          %ADMINS_SEL%
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <button type='submit' name='change' value='1' class='btn btn-primary float-right'>_{SAVE}_</button>
    </div>
  </div>
</form>
