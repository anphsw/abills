<form action='%SELF_URL%' method='POST' name='MSGS_TEAMS' id='MSGS_TEAMS'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{BRIGADE}_</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{NAME}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control' placeholder='_{NAME}_' name='NAME' id='NAME' value='%NAME%'/>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='DESCR'>_{DESCRIBE}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' id='DESCR' name='DESCR' rows='2'
                        placeholder='%DESCR%'>%DESCR%</textarea>
            </div>
          </div>
          <div class='form-group row'>
            <div class='col-12'>
              <div class='card card-primary card-outline collapsed-card'>
                <div class='card-header with-border'>
                  <h3 class='card-title'>_{MEMBERS}_</h3>
                  <div class='card-tools float-right'>
                    <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                      <i class='fa fa-plus'></i>
                    </button>
                  </div>
                </div>
                <div class='card-body'>
                  <div class='abills-result-former-bar'>
                    <div class='input-group col-12 col-md-6'>
                      <input class='form-control' placeholder='_{SEARCH}_...' id='resultFormSearch'>
                      <div class='input-group-append'>
                        <a class='btn input-group-button'><i class='fa fa-search fa-fw'></i></a>
                      </div>
                    </div>
                  </div>
                  %TEAM_MEMBERS%
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{WORK_REGION}_</h4>
        </div>
        <div class='card-body'>
          %GEOLOCATION_TREE%
          <div class='form-group custom-control custom-switch custom-switch-on-danger'>
            <input class='custom-control-input' type='checkbox' id='CLEAR' name='CLEAR' value='1'>
            <label for='CLEAR' class='custom-control-label'>_{CLEAR_GEO}_</label>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class='abills-form-main-buttons mb-3'>
    <input type='submit' class='btn btn-primary double_click_check' name='%ACTION%' value='%LNG_ACTION%'>
  </div>
</form>

