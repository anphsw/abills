<form method='get' name='REFERRAL_REPORTS_FORM' class='form form-inline'>
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
            <label class='col-md-3 control-label' for='UID'>_{USER}_</label>
            <div class='col-md-9'>
              %USER_SELECT%
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary btn-block' value='_{SHOW}_'/>
    </div>
  </div>
</form>

<div>
  %REFERRAL_TREE%
</div>