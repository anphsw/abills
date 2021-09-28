<form action=%FORM_ACTION% method='POST' name='tocheckout'>
  <input type='hidden' name='server_callback_url' value=%SERVER_CALLBACK_URL%>
  <!--<input type='hidden' name='response_url' value=%RESPONSE_URL%>-->
  <input type='hidden' name='order_id' value='%ORDER_ID%'>
  <input type='hidden' name='order_desc' value='%ORDER_DESC%'>
  <input type='hidden' name='currency' value='%CURRENCY%'>
  <input type='hidden' name='amount' value='%AMOUNT%'>
  <input type='hidden' name='signature' value='%SIGNATURE%'>
  <input type='hidden' name='merchant_id' value='%MERCHANT_ID%'>
  <input type='hidden' name='merchant_data' value='%MERCHANT_DATA%'>
  <input type='hidden' name='required_rectoken' value='%REQUIRED_RECTOKEN%'>

    <div class='card box-primary'>
      <div class='card-header with-border text-center'>
        <h4 class='card-title'>Fondy</h4>
      </div>
      <div class='card-body'>

        <div class='form-group text-center'>
          <img src='/styles/default_adm/img/paysys_logo/fondy-logo.png' style='width: auto; max-height: 200px;'>
        </div>

        <div class='form-group row'>
          <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
          <label class='font-weight-bold col-md-6 form-control-label'>%ORDER_ID%</label>
        </div>

        <div class='form-group row'>
          <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
          <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%SUM%</label>
        </div>
        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>
            _{REGULAR_PAYMENT}_
            <input type='checkbox' data-sidebarskin='toggle' class='pull-right' data-return='1' name='do_token'
                   value='on' data-checked='%REGULAR_PAYMENT%'/>
          </label>
        </div>

      </div>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' value='_{PAY}_'>
      </div>

    </div>

</form>