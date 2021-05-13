<form action="https://pay.smst.uz/prePay.do" target="_blank" method="POST">
  <input type='hidden' name='personalAccount' value='%PERSONAL_ACCOUNT%'>
  <input type='hidden' name='apiVersion' value='1'>
  <input type='hidden' name='serviceId' value='$conf{PAYSYS_UPAY_SERVICE_ID}'>
  <input type='hidden' name='amount'  value='%AMOUNT%'>

  <div class='card box-primary'>
    <div class='card-header with-border text-center'>UPAY</div>
    <div class='card-body'>
      <div class='form-group text-center'>
        <img src='/img/logo_upay.png' width=300 height=150 border=0>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 text-right'>_{SUM}_:</label>
        <label class='col-md-2 control-label'>%AMOUNT%</label>
      </div>

    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='pay' value='Оплатить через UPAY'>
    </div>

  </div>
</form>