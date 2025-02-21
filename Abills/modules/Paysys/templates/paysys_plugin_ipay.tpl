<div class='card card-primary card-outline'>
  <div class='card-header with-border text-center pb-0'>
    <h4>_{BALANCE_RECHARCHE}_</h4>
  </div>

  <div class='card-body pt-0'>
    <div class='text-center'>
      <img style='width: auto; max-height: 200px;'
           src='/styles/default/img/paysys_logo/ipay-logo.png'
           alt='iPay'>
    </div>

    <ul class='list-group list-group-unbordered mb-3'>
      <li class='list-group-item'>
        <b>_{ORDER}_</b>
        <div class='float-right'>%IPAY_PAYMENT_NO%</div>
      </li>
      <li class='list-group-item'>
        <b>_{SUM}_</b>
        <div class='float-right'>%SUM%</div>
      </li>
      <li class='list-group-item'>
        <b>_{HELP}_</b>
        <div class='float-right'>
          <a class='btn btn-default' href='https://www.ipay.ua/ua/faq'>_{READ_HERE}_</a>
        </div>
      </li>
      %EXTRA_DESCRIPTIONS%
    </ul>

    <a href='%URL%' class='btn btn-primary float-right' role='button' id='FASTPAY'>_{PAY}_</a>
  </div>
</div>
