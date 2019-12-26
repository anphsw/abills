<form action='$SELF_URL' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='storage_status' value=5>

  <div class='box box-form box-theme'>

    <div class='box-header with-border'><h4 class='box-title'>_{SEARCH}_</h4></div>

    <div class='box-body'>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{TYPE}_:</label>
        <div class='col-md-9'>
          %ARTICLE_TYPES_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='col-md-3 control-label'>_{NAME}_:</label>
        <div class='col-md-9'>
          <div class="ARTICLES_S">
            %ARTICLE_ID_SELECT%
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{ADMIN}_:</label>
        <div class='col-md-9'>
          %ADMIN_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>SN:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{DATE}_:</label>
        <div class='col-md-9'>
          %DATE_RANGE_PICKER%
        </div>
      </div>

    </div>

    <div class='box-footer'>
      <input type='submit' name='show_discard' value='_{SHOW}_' class='btn btn-primary'>

    </div>

  </div>

</form>

<script src='/styles/default_adm/js/storage.js'></script>