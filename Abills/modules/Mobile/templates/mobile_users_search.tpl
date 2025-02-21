<div class='col-md-6'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{SERVICE}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TP_ID'>_{TARIF_PLAN}_ (ID):</label>
        <div class='col-md-8'>
          %TP_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLE'>_{MOBILE_STATUS_NUMBER}_:</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERVICE_STATUS'>_{MOBILE_STATUS_TARIFF_PLAN}_:</label>
        <div class='col-md-8'>
          %SERVICE_STATUS_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PHONE'>_{PHONE}_:</label>
        <div class='col-md-8'>
          <input id='PHONE' name='PHONE' value='%PHONE%' class='form-control' type='text'>
        </div>
      </div>
    </div>
  </div>
</div>
