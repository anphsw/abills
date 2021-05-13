<form id=pay name=pay method='POST' action='%ACTION_URL%'>
  <input type='hidden' name='LMI_MERCHANT_ID' value='%LMI_MERCHANT_ID%'>
  <input type='hidden' name='LMI_RESULT_URL' value='%PAYSYS_LMI_RESULT_URL%'>
  <input type='hidden' name='LMI_SUCCESS_URL' value='%LMI_SUCCESS_URL%'>
  <input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
  <input type='hidden' name='LMI_FAIL_URL' value='%LMI_FAIL_URL%'>
  <input type='hidden' name='LMI_FAIL_METHOD' value='2'>
  <input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
  <input type='hidden' name='at' value='%AT%'>
  <input type='hidden' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/>
  <input type='hidden' name='LMI_PAYMENT_SYSTEM' value='%LMI_PAYMENT_SYSTEM%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='sid' value='%SID%'>
  <input type='hidden' name='IP' value='%IP%'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>
  %TEST_MODE%

  <div class='card box-primary'>
    <div class='card-header with-border text-center'>
      <h4 class='card-title'>Paysoft</h4>
    </div>
    <div class='card-body'>
      <div class='form-group text-center'>
        <img src='/styles/default_adm/img/paysys_logo/paysoft-logo.png' style="width: auto; max-height: 200px;">
      </div>

      <div class='form-group'>
        <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
        <label class='font-weight-bold col-md-6 form-control-label'>%LMI_PAYMENT_NO%</label>
      </div>

      <div class='form-group'>
        <label
          class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
        <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%LMI_PAYMENT_AMOUNT%</label>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='_{PAY}_'>
    </div>
  </div>

</form>
