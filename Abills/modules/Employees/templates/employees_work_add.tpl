<script language='JavaScript' type='text/javascript'>
  function enable_input(what) {
    var item = document.getElementById(what);

    if (item.disabled)
      item.disabled = false;
    else
      item.disabled = true;
  }
</script>

<form action='$SELF_URL' method='get' name='works' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='EXT_ID' value='%EXT_ID%'>
  <input type=hidden name='ID' value='%EXT_ID%'>
  <input type=hidden name='UID' value='%UID%'>
  %HIDDEN_INPUTS%

  <div class='card card-primary card-outline card-big-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{WORK}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ADMIN'>_{ADMIN}_:</label>
        <div class='col-md-9'>
          %ADMIN_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='TYPE'>_{TYPE}_:</label>
        <div class='col-md-9'>
          %WORK_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='PIN'>_{RATIO}_:</label>
        <div class='col-md-9'>
          <input id='RATIO' name='RATIO' value='%RATIO%' placeholder='%RATIO%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CID'>_{EXTRA}_ _{PRICE}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <div class='input-group-prepend'><span class="input-group-text">
              <input type='checkbox' onchange="enable_input('EXTRA_SUM')">
            </span></div>
            <input type='number' class='form-control' id='EXTRA_SUM' name='EXTRA_SUM' value='%EXTRA_SUM%' disabled>
          </div>
        </div>
      </div>

      %TAKE_FEES%

      <div class="form-group custom-control custom-checkbox" style="text-align: center;">
        <input class="custom-control-input" type="checkbox" id="WORK_DONE" name="WORK_DONE"
               %WORK_DONE% value='1'>
        <label for="WORK_DONE" class="custom-control-label">_{WORK_DONE}_</label>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea name='COMMENTS' rows='5' col='60' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>


    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
    </div>
  </div>

</form>
