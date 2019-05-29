<form action='$SELF_URL' method='post' class='form form-horizontal'>
  <input type=hidden name=index value=$index>
  <div class='box box-theme'>
    <div class='box-header with-border'>
      <h4 class="box-title table-caption">_{FILTERS}_</h4>
      <div class="box-tools pull-right">
        <button type="button" class="btn btn-default btn-xs" data-widget="collapse">
          <i class="fa fa-minus"></i></button>
      </div>
    </div>

    <div class='box-body'>
      <div class="row align-items-center">
        <div class='form-group'>
          <label class='col-md-3 control-label'>FB likes </label>
          <input type='textarea' name='post_url' value='' size=30%>
        </div>

      </div>
      <div class='box-footer'>
        <input type=submit class='btn btn-primary btn-block' name=''>
      </div>
    </div>
</form>


