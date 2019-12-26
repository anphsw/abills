<div class=' col-md-6'>
  <div class='box box-theme collapsed-box'>
    <div class='box-header with-border'>
      <h3 class='box-title'>_{BILL}_</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
          <i class='fa fa-plus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='FIO'>_{FIO}_ (*):</label>

        <div class='col-sm-8 col-md-8'>
          <div class="input-group">
            <input id='FIO' name='FIO' value='%FIO%' class='form-control' type='text'/>
            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='FIO' data-input-disables=FIO value='!'>
                </span>
          </div>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='CONTRACT_ID'>_{CONTRACT_ID}_ (*):</label>

        <div class='col-sm-8 col-md-8'>
          <div class="input-group">
            <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' class='form-control'
                   type='text'/>
            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='CONTRACT_ID' data-input-disables=CONTRACT_ID value='!'>
                </span>
          </div>
        </div>
      </div>

      %CONTRACT_TYPE_FORM%

      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='CONTRACT_DATE'>_{CONTRACT}_ _{DATE}_:</label>

        <div class='col-sm-8 col-md-8'>
          <input id='CONTRACT_DATE' name='CONTRACT_DATE' value='%CONTRACT_DATE%'
                 placeholder='%CONTRACT_DATE%'
                 class='form-control datepicker' type='text'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='PHONE'>_{PHONE}_ (&gt;, &lt;, *):</label>

        <div class='col-sm-8 col-md-8'>
          <div class="input-group">
            <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control'
                   type='text'/>
            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='PHONE' data-input-disables=PHONE value='!'>
                </span>
          </div>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='CELL_PHONE'>_{CELL_PHONE}_ (&gt;, &lt;, *):</label>

        <div class='col-sm-8 col-md-8'>
          <div class="input-group">
            <input id='CELL_PHONE' name='CELL_PHONE' value='%CELL_PHONE%' placeholder='%CELL_PHONE%' class='form-control'
                   type='text'/>
            <span class="input-group-addon" data-tooltip="_{EMPTY_FIELD}_">
                  <i class='fa fa-exclamation'></i>
                  <input type="checkbox" name='CELL_PHONE' data-input-disables=CELL_PHONE value='!'>
                </span>
          </div>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='COMMENTS'>_{COMMENTS}_ (*):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='COMMENTS' name='COMMENTS' value='%COMMENTS%' placeholder='%COMMENTS%'
                 class='form-control' type='text'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='DEPOSIT'>_{DEPOSIT}_ (&gt;, &lt;):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='DEPOSIT' name='DEPOSIT' value='%DEPOSIT%' placeholder='%DEPOSIT%'
                 class='form-control' type='text'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='BILL_ID'>_{BILL}_:</label>

        <div class='col-sm-8 col-md-8'>
          <input id='BILL_ID' name='BILL_ID' value='%BILL_ID%' placeholder='%BILL_ID%'
                 class='form-control' type='text'/>
        </div>
      </div>

      %DOMAIN_FORM%
    </div>
  </div>
</div>

<div class=' col-md-6'>
  <div class='box box-theme collapsed-box'>
    <div class='box-header with-border'>
      <h3 class='box-title'>_{CREDIT}_</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
          <i class='fa fa-plus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='CREDIT'>_{SUM}_ (&gt;, &lt;):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%'
                 class='form-control' type='text'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='CREDIT_DATE'>_{DATE}_ ((&gt;, &lt;)
          YYYY-MM-DD):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='CREDIT_DATE' name='CREDIT_DATE' value='%CREDIT_DATE%'
                 placeholder='%CREDIT_DATE%' class='form-control datepicker' type='text'/>
        </div>
      </div>
      <legend>_{PAYMENTS}_</legend>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='PAYMENTS'>_{DATE}_ ((&gt;, &lt;)
          YYYY-MM-DD):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='PAYMENTS' name='PAYMENTS' value='%PAYMENTS%' placeholder='%PAYMENTS%'
                 class='form-control' type='text'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='PAYMENT_DAYS'>_{DAYS}_ (&gt;, &lt;):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='PAYMENT_DAYS' name='PAYMENT_DAYS' value='%PAYMENT_DAYS%'
                 placeholder='%PAYMENT_DAYS%' class='form-control' type='text'/>
        </div>
      </div>
      <legend>_{FEES}_</legend>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='FEES'>_{DATE}_ ((&gt;, &lt;) YYYY-MM-DD):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='FEES' name='FEES' value='%FEES%' placeholder='%FEES%' class='form-control'
                 type='text'/>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-sm-4 col-md-4' for='FEES_DAYS'>_{DAYS}_ (&gt;, &lt;):</label>

        <div class='col-sm-8 col-md-8'>
          <input id='FEES_DAYS' name='FEES_DAYS' value='%FEES_DAYS%' placeholder='%FEES_DAYS%'
                 class='form-control' type='text'/>
        </div>
      </div>
    </div>
  </div>
</div>