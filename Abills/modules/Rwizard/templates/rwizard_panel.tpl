<script type="text/javascript">
  function autoReload() {
    jQuery('#REPORT').remove();
    jQuery('#REPORTS_SHOW').submit();
  }
</script>

<form action='$SELF_URL' METHOD='post' class='form-horizontal' role='form' id='REPORTS_SHOW'>
  <input type=hidden name=index value=$index>
  <div class="box box-theme FK">

    <div class='box-header with-border'>
      <h4 class="box-title table-caption">_{FILTERS}_</h4>
      <div class="box-tools pull-right">
        <button type="button" class="btn btn-default btn-xs" data-widget="collapse">
          <i class="fa fa-minus"></i></button>
      </div>
    </div>

    <div class="box-body">
      <div class="row align-items-center">
        <div class="col-md-6">
          <div class="form-group">
            <label class="col-md-3 control-label">GID:</label>
            <div class="col-md-9">
              %GROUP_SEL%
            </div>
          </div>
        </div>
        <div class="col-md-6">
          <div class="form-group">
            <label class="col-md-3 control-label">_{REPORTS}_:</label>
            <div class="col-md-9">
              %REPORTS_SEL%
            </div>
          </div>
        </div>
      </div>

      <div class="box-footer">
        <input type=submit class='btn btn-primary btn-block' name=SHOW value='_{SHOW}_'>
      </div>
    </div>
</form>