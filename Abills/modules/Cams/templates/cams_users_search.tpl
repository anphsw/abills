<div class='col-md-6'>
  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'>
      <h3 class='box-title'>_{SERVICE}_</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>

      <div class='form-group'>
        <label class='control-label col-md-3' for='SERVICE_ID'>_{SERVICE}_:</label>
        <div class='col-md-9'>
          %SERVICE_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_ (ID):</label>
        <div class='col-md-9'>
          <input id='TP_ID' name='TP_ID' value='%TP_ID%' placeholder='%TP_ID%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='SERVICE_STATUS'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ID'>ID:</label>
        <div class='col-md-9'>
          <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label' for='SERVICES' style="padding-right: 0">_{SERVICES}_ (>,<)</label>
        <div class='col-md-9'>
          <input id='SERVICES' name='SERVICES' value='%SERVICES%' class='form-control'
                 type='text'>
        </div>
      </div>
    </div>
  </div>
</div>