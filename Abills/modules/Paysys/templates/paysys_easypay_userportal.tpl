<form  method='post'>
  <input type='hidden' name='MAKE_PAYMENT' value='1'/>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
  <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>
  <input type='hidden' name='SUM' value='%SUM%'/>
  <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'/>

  <div class='container-fluid'>
    <div class='card box-primary'>
      <div class='card-header with-border text-center'>Easypay</div>
      <div class='card-body'>

        <div class='form-group'>
          <img class='col-xs-8 col-xs-offset-2'
               src='https://docs.easypay.ua/images/new_images/registration_on_site8.png'>
        </div>

        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label'>_{ORDER}_</label>
          <label class='font-weight-bold col-md-6 form-control-label'>%OPERATION_ID%</label>
        </div>

        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{BALANCE_RECHARCHE_SUM}_:</label>
          <label class='font-weight-bold col-md-6 form-control-label col-xs-12'>%SUM%</label>
        </div>

        <div class='form-group'>
          <label class='font-weight-bold text-center col-md-6 form-control-label col-xs-12'>_{CREATE_REGULAR_PAYMENT}_</label>
          <div class='col-md-3'>
          %CREATE_REGULAR_PAYMENT%
          </div>
        </div>

      </div>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' name="easypay_merchant" value='_{PAY}_'>
      </div>

    </div>
  </div>
</form>