<div class='card card-primary card-outline box-form'>
  <div class="card-header with-border"><h4 class="card-title">_{REFERRAL_SYSTEM}_</h4></div>
  <form name='SETTINGS' id='form_REFERRAL_SETTINGS' method='post' class='form form-horizontal'>
    <div class='card-body'>

      <input type='hidden' name='index' value='$index'/>
      %CHANGE%

      <div class='form-group row'>
        <label class='control-label col-md-3' for='NAME'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%'
                 id='NAME'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='BONUS_AMOUNT'>_{BONUS_AMOUNT}_</label>
        <div class='col-md-9'>
          <input type='number' class='form-control' name='BONUS_AMOUNT' value='%BONUS_AMOUNT%'
                 id='BONUS_AMOUNT'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='PAYMENT_ARREARS'>_{PAYMENT_ARREARS}_</label>
        <div class='col-md-9'>
          <input type='number'
                 data-tooltip='_{NO_ARREARS}_<br>_{X_ARREARS}_'
                 class='form-control' name='PAYMENT_ARREARS' value='%PAYMENT_ARREARS%' id='PAYMENT_ARREARS'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='PAYMENT_ARREARS'>_{PERIOD}_ _{ACCRUALS}_</label>
        <div class='col-md-9'>
          <input type='number'
                 data-tooltip='_{PAY_NOW}_<br>_{PAY_X_MONTH}_'
                 class='form-control' name='PERIOD' value='%PERIOD%' id='PERIOD'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='MAX_LEVEL_id'>_{REPL_PERCENT}_</label>
        <div class='col-md-9'>
          <input type='number' min='0' max='100' class='form-control'
                 data-tooltip='<b>_{MIN}_</b>: 0 <br> <b>_{MAX}_</b>:100'
                 name='REPL_PERCENT' value='%REPL_PERCENT%' id='MAX_LEVEL_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='MAX_LEVEL_id'>_{SPEND_PERCENT}_</label>
        <div class='col-md-9'>
          <input type='number' min='0' max='100' class='form-control'
                 data-tooltip='<b>_{MIN}_</b>: 0 <br> <b>_{MAX}_</b>:100'
                 name='SPEND_PERCENT' value='%SPEND_PERCENT%' id='SPEND_PERCENT'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='BONUS_BILL'>_{BILL}_</label>
        <div class='col-md-9'>
          %BILL_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 text-right' for='IS_DEFAULT'>_{DEFAULT}_</label>
        <div class='col-sm-9'>
          <div class='form-check text-left'>
            <input type='checkbox' class='form-check-input' id='IS_DEFAULT' value='1' %DEFAULT% name='IS_DEFAULT'>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </form>
</div>

