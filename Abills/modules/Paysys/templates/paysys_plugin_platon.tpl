<form action=%URL% method='POST'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='key' value=%key%>
    <input type='hidden' name='payment' value=%payment%>
    <input type='hidden' name='order' value=%order%>
    <input type='hidden' name='data' value=%data%>
    <input type='hidden' name='ext1' value=%ext1%>
    <input type='hidden' name='url' value=%url%>
    <input type='hidden' name='sign' value=%sign%>
    <input type='hidden' name='commission' value=%commission%>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
      <div class='text-center'>
        <img src='/styles/default/img/paysys_logo/platon-logo.png'
             style='max-width: 300px; max-height: 200px;'
             alt='Platon'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>%DESCRIBE%</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>%TRANSACTION_ID%</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%SUM%</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
    </div>
  </div>
</form>
