<form action='$SELF_URL' method='post' name='add_message' class='form form-horizontal'>
  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4>_{DISPATCH}_</h4></div>
    <div class='box-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='AID' value='%AID%'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PLAN_DATE'>_{EXECUTION}_</label>
        <div class='col-md-9'>
          <input type='text' name='PLAN_DATE' id='PLAN_DATE'
                 value='%PLAN_DATE%' placeholder='%PLAN_DATE%'
                 class='form-control datepicker'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'
          >%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
        <div class='col-md-9'>
          %STATE_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CREATED_BY'>_{DISPATCH_CREATE}_</label>
        <div class='col-md-9'>
          %CREATED_BY_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='RESPOSIBLE'>_{HEAD}_</label>
        <div class='col-md-9'>
          %RESPOSIBLE_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME'>_{DISPACTH_CATEGORY}_</label>
        <div class='col-md-9'>
          %CATEGORY_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='START_DATE'>_{TIME_START_WORK}_:</label>
        <div class='col-md-9'>
          %START_DATE%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='END_DATE'>_{TIME_END_WORK}_:</label>
        <div class='col-md-9'>
          %END_DATE%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'  for='ACTUAL_END_DATE'>_{ACTUAL_TIME_END}_:</label>
        <div class='col-md-9' disabled>
          %ACTUAL_END_DATE%
        </div>
      </div>

      <div class='form-group'>
        <div class='box box-theme collapsed-box'>
          <div class="box-header with-border">
            <h3 class="box-title">_{BRIGADE}_:</h3>
          <div class="box-tools pull-right">
            <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
            </button>
          </div>
          </div>
        <div class='box-body'>
          %AIDS%
        </div>
      </div>
    </div>

  </div>
    <div class='box-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>

  </div>
</form>
