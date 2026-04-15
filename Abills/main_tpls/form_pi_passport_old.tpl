<div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
  <div class='card-header with-border'>
    <h3 class='card-title'>_{PASPORT}_: <b>%PASPORT_NUM%</b></h3>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-plus'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='PASPORT_NUM'>_{NUM}_:</label>
      <div class='col-sm-9 col-md-4'>
        <div class='input-group'>
          <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                 placeholder='%PASPORT_NUM%'
                 class='form-control' type='text'>
        </div>
      </div>
      <label class='col-sm-3 col-md-2 control-label' for='PASPORT_DATE'>_{DATE}_:</label>
      <div class='col-sm-9 col-md-4'>
        <div class='input-group'>
          <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                 class='datepicker form-control'>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='PASPORT_EXPIRE'>_{EXPIRY}_:</label>
      <div class='col-sm-9 col-md-4'>
        <div class='input-group'>
          <input class='form-control datepicker' id='PASPORT_EXPIRE' name='PASPORT_EXPIRE'
                 type='text' value='%PASPORT_EXPIRE%'>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='PASPORT_GRANT'>_{GRANT}_:</label>
      <div class='col-sm-9 col-md-10'>
        <div class='input-group'>
          <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT' rows='2'>%PASPORT_GRANT%</textarea>
        </div>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='BIRTH_DATE'>_{BIRTH_DATE}_:</label>
      <div class='col-sm-9 col-md-4'>
        <div class='input-group'>
          <input class='form-control datepicker' id='BIRTH_DATE' name='BIRTH_DATE'
                 type='text' value='%BIRTH_DATE%'>
        </div>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='REG_ADDRESS'>_{REG_ADDRESS}_:</label>
      <div class='col-sm-9 col-md-10'>
        <div class='input-group'>
          <textarea class='form-control' id='REG_ADDRESS' name='REG_ADDRESS' rows='2'>%REG_ADDRESS%</textarea>
        </div>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='TAX_NUMBER'>_{TAX_NUMBER}_:</label>
      <div class='col-sm-9 col-md-10'>
        <div class='input-group'>
          <input id='TAX_NUMBER' name='TAX_NUMBER' value='%TAX_NUMBER%'
                 placeholder='%TAX_NUMBER%'
                 class='form-control' type='text'>
        </div>
      </div>
    </div>
  </div>
</div>