<form class='form-horizontal' id='voip_recalculate'>
  <input type=hidden name='index' value=$index>
  <input type=hidden name='UID' value='%UID%'>
  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{RECALCULATE}_</h3>
      <div class='card-tools pull-right'>
        <button type='button' class='btn btn-secondary btn-xs' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div id='_main' class='card-body'>
      <div class='form-group'>
        <label class='col-md-4 control-label'>_{FROM}_</label>
        <div class='col-md-8'>
          %FROM_DATE%
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-4 control-label'>_{TO}_:</label>
        <div class='col-md-8'>
          %TO_DATE%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name='recalc' value='_{RECALCULATE}_'>
    </div>
  </div>
</form>