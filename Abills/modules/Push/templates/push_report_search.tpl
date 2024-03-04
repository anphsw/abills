<form action='%SELF_URL%' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='search_form' value='1'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title '>_{SET_PARAMS}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body row'>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{DATE}_:</label>
        <div class='col-md-8'>
          %DATEPICKER%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{ADMIN}_:</label>
        <div class='col-md-8'>
          %ADMINS_SELECT%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SELECT%
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input class='btn btn-primary btn-block' type='submit' name='search' value='_{SHOW}_'>
    </div>
  </div>
</form>

<script>
  if (window.location.search.includes('UID')) {
    var url = new URL(window.location.href);
    url.searchParams.delete('UID');
    window.location.href = url;
  }
</script>