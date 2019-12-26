<form name='PAYSYS_CONNECT_SYSTEM' id='form_PAYSYS_CONNECT_SYSTEM' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='OLD_NAME' value='%NAME%'>

  <div class='box big-box box-theme'>
    <div class='box-header with-border'>
      <h4 class="box-title">_{ADD}_ _{PAY_SYSTEM}_</h4>
    </div>

    <div class='box-body'>
      <div class='form-group %HIDE_SELECT%'>
        <label class='control-label col-md-3'>_{PAY_SYSTEM}_</label>
        <div class='col-md-9'>
          %PAYSYS_SELECT%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>ID:</label>
        <div class='col-md-9'>
          <input type='number' class='form-control' name='PAYSYS_ID' value='%PAYSYS_ID%' id='paysys_id' required>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='paysys_name' required pattern='[A-Za-z0-9_]{1,30}' data-tooltip="Только лат. буквы, цифры и подчеркивание">
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>IP</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='IP'>%IP%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{PAYMENT_TYPE}_</label>
        <div class='col-md-9'>
          %PAYMENT_METHOD_SEL%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{PRIORITY}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='PRIORITY' value='%PRIORITY%' >
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 col-sm-4 col-xs-6' for='STATUS'>_{LOGON}_:</label>
        <div class='col-md-9 col-xs-4' style="padding-top: 7px">
          <input id="STATUS" class="pull-left"  type='checkbox' name='STATUS' data-return='1' value='1' data-checked='%ACTIVE%'>
        </div>
      </div>

    </div>

    <div class='box-footer'>
      <input class='btn btn-primary' type='submit' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  }
  catch (err) {
    console.log('JSON parse error.');
  }

  jQuery(function () {
    var select_module = jQuery("#MODULE");
    select_module.change(function () {
      var module = select_module.val();
      jQuery('#paysys_id').val(arr[module]['ID']);
      jQuery('#paysys_name').val(arr[module]['NAME']);
    });
  });
</script>