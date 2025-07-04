<div class='card collapsed-card mb-0 border-top card-outline'>
  <div class='card-header with-border'>
    <h3 class='card-title'>_{CONTRACT}_</h3>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-plus'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    %ACCEPT_RULES_FORM%
    <div class='form-group row'>
      <label class='col-sm-4 col-md-3 col-form-label text-md-right' for='CONTRACT_ID'>_{CONTRACT_ID}_ %CONTRACT_SUFIX%</label>
      <div class='col-sm-8 col-md-9'>
        <div class='input-group'>
          <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%'
                 placeholder='%CONTRACT_ID%' class='form-control' type='text'>
          <div class='input-group-append'>
            %SIGN_CONTRACT%
            %PRINT_CONTRACT%
            <a href='$SELF_URL?qindex=13&COMPANY_ID=$FORM{COMPANY_ID}&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1'
               class='btn input-group-button' target=_new>
              <i class='fa fa-envelope'></i>
            </a>
          </div>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-4 col-md-3 col-form-label text-md-right' for='CONTRACT_DATE'>_{DATE}_</label>
      <div class='col-sm-8 col-md-9'>
        <div class='input-group'>
          <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE'
                 value='%CONTRACT_DATE%' class='datepicker form-control'>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-4 col-md-3 col-form-label text-md-right' for='STATUS'>_{STATUS}_</label>
      <div class='col-sm-8 col-md-9'>
        %CONTRACT_STATUS_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-4 col-md-3 col-form-label text-md-right'  for='BANK_NAME'> _{INDICATION}_</label>
      <div class='input-group col-md-9'>
        <input class='form-control' id='INDICATION' placeholder='%INDICATION%' name='INDICATION' value='%INDICATION%'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-4 col-md-3 col-form-label text-md-right' for='CONTRACT_EXPIRY'>_{EXPIRY}_</label>
      <div class='col-sm-8 col-md-9'>
        <div class='input-group'>
          <input id='CONTRACT_EXPIRY' type='text' name='CONTRACT_EXPIRY'
                 value='%CONTRACT_EXPIRY%' class='datepicker form-control'>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-4 col-md-3 col-form-label text-md-right' for='PAYMENT_TYPE_SEL'>_{PAYMENT_METHOD}_</label>
      <div class='col-sm-8 col-md-9'>
        %PAYMENT_TYPE_SEL%
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          %CONTRACT_TYPE%
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          %CONTRACTS_TABLE%
        </div>
      </div>
    </div>
  </div>
</div>