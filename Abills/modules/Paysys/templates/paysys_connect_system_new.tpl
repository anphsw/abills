<form name='PAYSYS_CONNECT_SYSTEM' id='form_PAYSYS_CONNECT_SYSTEM' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='OLD_NAME' value='%NAME%'>

  <div class='card card-primary card-outline box-form form-horizontal'>
    <div class='card-header with-border'>
      <h4 class="card-title">_{ADD}_ _{PAY_SYSTEM}_</h4>
    </div>
    <div class='card-body'>
      <div class="form-group row %HIDE_SELECT%">
        <label class='col-form-label text-md-right col-sm-2'>_{PAY_SYSTEM}_:</label>
        <div class="input-group col-sm-10">
          %PAYSYS_SELECT%
        </div>
      </div>

      <div class="form-group row">
        <label class='col-form-label text-md-right col-sm-2'>ID:</label>
        <div class="input-group col-sm-10">
          <input type='number' class='form-control' name='PAYSYS_ID' value='%PAYSYS_ID%' id='paysys_id' required>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-form-label text-md-right col-sm-2'>_{PRIORITY}_:</label>
        <div class="input-group col-sm-10">
          <input type='text' class='form-control' name='PRIORITY' value='%PRIORITY%' >
        </div>
      </div>

      <div class="form-group row">
        <label class='col-form-label text-md-right col-sm-2'>_{NAME}_:</label>
        <div class="input-group col-sm-10">
          <input type='text' class='form-control' name='NAME' value='%NAME%'
                 id='paysys_name' required pattern='[A-Za-z0-9_]{1,30}' data-tooltip="Только лат. буквы, цифры и подчеркивание">
        </div>
      </div>

      <div class="form-group row">
        <label class='col-form-label text-md-right col-sm-2'>_{PAYMENT_TYPE}_:</label>
        <div class="input-group col-sm-10">
          %PAYMENT_METHOD_SEL%
        </div>
      </div>

      <div class="form-group row">
        <label class='col-form-label text-md-right col-sm-2'>IP:</label>
        <div class="input-group col-sm-10">
          <textarea class='form-control' name='IP'>%IP%</textarea>
        </div>
      </div>

      <div class="form-group">
        <div class="form-check">
          <input id="STATUS" class="form-check-input"  type='checkbox' name='STATUS' data-return='1' value='1' data-checked='%ACTIVE%'>
          <label class='form-check-label' for='STATUS'>_{LOGON}_</label>
        </div>
      </div>

    </div>

    <div class='card-footer'>
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