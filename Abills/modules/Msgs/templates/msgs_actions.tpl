<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h4 class="card-title">_{ACTION}_</h4>
  </div>
  <div class='card-body'>
    <div class="form-group">
      <div class="row">
        <div class="col-sm-12 col-md-4">
          <label class="col-sm-12 col-10">_{DISPATCH}_</label>
            %DISPATCH_WORK%
          <br/>
          %DISPATCH_ACTION%
        </div>
        <div class="col-sm-12 col-md-4">
          <label class="col-sm-12 col-10">_{CATEGORY}_</label>
          <div class="input-group">
            %MSGS_CATEGORY%
          </div>
          <br/>
          %CATEGORY_BTN%
        </div>
        <div class="col-sm-12 col-md-4">
          <label class="col-sm-12 col-10">_{STATUS}_</label>
          <div class="input-group">
            %STATUS_MSGS%
          </div>
          <br/>
          %STATUS_BTN%
        </div>
      </div>
    </div>
    %DELETE_MULTI_MSGS%
  </div>
</div>