<form action=%PAY_URL% method='POST'>
  <input type='hidden' name='key' value=%KEY%>
  <input type='hidden' name='payment' value=%PAYMENT%>
  <input type='hidden' name='order' value=%ORDER_ID%>
  <input type='hidden' name='data' value=%PRODUCT_DATA%>
  <input type='hidden' name='ext1' value=%UID%>
  <input type='hidden' name='url' value=%URL_OK%>
  <input type='hidden' name='sign' value=%SIGNATURE%>
  <input type='hidden' name='commission' value=%COMMISSION%>

  <div class='container-fluid'>
    <div class='card box-primary'>
      <div class='card-header with-border text-center'>
        <h4 class='card-title'>Platon</h4>
      </div>
      <div class='card-body'>

        <div class='form-group text-center'>
          <img
               src='/styles/default_adm/img/paysys_logo/platon-logo.png' style='width: auto; max-height: 200px;'>>
        </div>

        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
          <label class='font-weight-bold col-md-6 form-control-label'>%ORDER_ID%</label>
        </div>

        <div class='form-group'>
          <label
            class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
          <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%SUM%</label>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-6 text-center'>_{SERVICE_FEE}_</label>
          <label class='control-label col-md-6'>%SERVICE%</label>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-6 text-center'>_{TOTAL}_</label>
          <label class='control-label col-md-6'>%TOTAL%</label>
        </div>


      </div>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' value='_{PAY}_'>
      </div>

    </div>
  </div>
</form>