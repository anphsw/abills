<form method="post" class="form form-horizontal">
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
  <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>
  <input type='hidden' name='SUM' value='%SUM%'/>
  <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'/>

  <div class='box box-theme form-horizontal'>
    <div class='box-header with-border text-center'><h4>Easypay _{CHOOSE_SYSTEM}_</h4></div>
    <div class='box-body'>

      <div class='col-md-12'>
        <div class='col-md-6'>
          <div class="box box-solid box-primary">
            <div class='box-header with-border text-center'><h4>Easypay</h4></div>
            <div class='box-body'>
              <div class="col-md-12">
                <img class="img-responsive" src="https://docs.easypay.ua/images/new_images/registration_on_site8.png"
                     alt="Easypay_provider">
                <p>_{EASYPAY_PROVIDER}_</p>
              </div>
            </div>
            <div class="box-footer">
              <input class='btn btn-primary' type='submit' name="easypay_provider" value='_{PAY}_'>
            </div>
          </div>
        </div>
        <div class='col-md-6'>
          <div class="box box-solid box-primary">
            <div class='box-header with-border text-center'><h4>Easypay</h4></div>
            <div class='box-body'>
              <div class="col-md-12">
                <img class="img-responsive" src="https://docs.easypay.ua/images/new_images/registration_on_site8.png"
                     alt="Easypay_provider">
                <p>_{EASYPAY_MERCHANT}_</p>
                <br>
              </div>
            </div>
            <div class="box-footer">
              <input class='btn btn-primary' type='submit' name="easypay_merchant" value='_{PAY}_'>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>