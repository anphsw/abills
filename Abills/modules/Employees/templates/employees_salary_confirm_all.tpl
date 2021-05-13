<form method='POST'>

  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='AID' value='%AID%'>
  <input type='hidden' name='YEAR' value='%YEAR%'>
  <input type='hidden' name='MONTH' value='%MONTH%'>

  <div class='card card-primary card-outline box-form form-horizontal'>

    <div class='card-header with-border'>_{SALARY}_</div>

    <div class='card-body'>
       %FIO_1%

      <div class='form-group row'>
        <label class='col-sm-2 col-form-label'>_{CASHBOX}_</label>
        <div class='col-sm-10'>
          %CASHBOX%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-form-label'>_{SPENDING}_ _{TYPE}_</label>
        <div class='col-sm-10'>
          %SPENDING_TYPE_ID%
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' name='confirm' value='_{ADD}_' class='btn btn-primary'>
    </div>

  </div>

</form>