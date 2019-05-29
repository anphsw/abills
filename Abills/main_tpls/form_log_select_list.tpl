<form action='$SELF_URL' METHOD='POST'>
  <input type=hidden name='index' value='$index'>
  <div class='box box-theme form-horizontal '>
    <div class='box-header with-border'>
      <h4 class="box-title table-caption">_{FILTERS}_</h4>
      <div class="box-tools pull-right">
        <button type="button" class="btn btn-default btn-xs" data-widget="collapse">
          <i class="fa fa-minus"></i></button>
      </div>
    </div>

    <div class='box-body'>
      <div class="row align-items-center">
        <div class="col-md-6">
          <div class='form-group'>
            <label class='col-md-3 control-label'>_{LOG}_ </label>
            <div class='col-md-9'>
              %LOGS_SELECT%
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type=submit value='_{SHOW}_' class='btn btn-primary btn-block'>
    </div>
  </div>
</form>