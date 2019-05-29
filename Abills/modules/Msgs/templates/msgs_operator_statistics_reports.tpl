<form name='report_panel' id='report_panel' method='post' value='1'>
  <input type='hidden' name='index' value='$index'/>
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
            <label class='col-md-3 control-label'>_{YEAR}_ </label>
            <div class='col-md-9'>
              %YEAR%
            </div>
          </div>
        </div>

        <div class="col-md-6">
          <div class='form-group'>
            <label class='col-md-3 control-label'>_{MONTH}_ </label>
            <div class='col-md-9'>
              %MONTH%
            </div>
          </div>
        </div>

        <div class="box-footer">
          <input type="submit" name="show" value="_{SHOW}_" class="btn btn-primary" form="report_panel" id="show">
        </div>
      </div>
    </div>
  </div>
</form>