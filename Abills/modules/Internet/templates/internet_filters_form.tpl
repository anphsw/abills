<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{FILTERS_LOG}_</h4>
  </div>
  <div class='card-body'>
    <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='ID' value='%ID%' />

      <div class="form-group">
        <div class="row">
          <div class="col-sm-12 col-md-4">
            <label class='control-label col-md-10' for='FILTER_ID'>_{NAME}_</label>
            <div class="input-group">
              <input type='text' class='form-control' name='FILTER'  id='FILTER_ID' value='%FILTER%' />
            </div>
          </div>

          <div class="col-sm-12 col-md-4">
            <label class='control-label col-md-10' for='PARAMS_ID'>_{PARAMS}_</label>
            <div class="input-group">
              <input type='text' class='form-control' name='PARAMS'  id='PARAMS_ID' value='%PARAMS%' />
            </div>
          </div>

          <div class="col-sm-12 col-md-4">
            <label class='control-label col-md-10' for='DESCR_ID'>_{DESCRIBE}_</label>
            <div class="input-group">
              <input type='text' class='form-control' name='DESCR'  id='DESCR_ID' value='%DESCR%' />
            </div>
          </div>
        </div>
      </div>
    </form>
  </div>
  <div class='card-footer text-center'>
      <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
  </div>
</div>
