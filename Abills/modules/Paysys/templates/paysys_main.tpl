<form method='POST' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='sid' value='$sid'>
  <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border text-center'>
      <h4 class='card-title'>_{BALANCE_RECHARCHE}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group row' %IDENTIFIER_HIDDEN%>
        <label for='transaction' class='col-sm-2 col-md-2 col-form-label'>%IDENTIFIER_LANG%</label>
        <div class='col-sm-10 col-md-10'>
          <input type='text' class='form-control' name='IDENTIFIER' id='IDENTIFIER' readonly
                 value='%IDENTIFIER%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='transaction' class='col-sm-2 col-md-2 col-form-label'>_{TRANSACTION}_ #:</label>
        <div class='col-sm-10 col-md-10'>
          <input type='text' class='form-control' id='transaction' placeholder='_{TRANSACTION}_ #' readonly
                 value='%OPERATION_ID%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='sum' class='col-sm-2 col-md-2 col-form-label'>_{SUM}_:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='number' min='0' step='0.01' id='sum' name='SUM' value='%SUM%' autofocus>
        </div>
      </div>

      <div class='form-group'>
        <div id='GooglePay'></div>
      </div>

      <div class='form-group'>
        <apple-pay-button buttonstyle='black' onclick='onApplePayButtonClicked()'  type='pay'></apple-pay-button>
      </div>

      <div class='form-group text-center'>
        %IPAY_HTML%
      </div>

      <div class='form-group row d-flex justify-content-center'>
        %PAY_SYSTEM_SEL%
      </div>
    </div>

    <div class='modal fade' id='modal' role='dialog'>
      <div class='modal-dialog'>
        <div class='modal-content'>
          <div class='modal-header'>
            <h4 class='modal-title'>_{PAYMENT_MADE}_</h4>
            <button type='button' class='close' data-dismiss='modal'>&times;</button>
          </div>

          <div class='modal-body'>
            <ul class='list-group list-group-unbordered mb-3'>
              <li class='list-group-item'>
                <b>_{BALANCE_RECHARCHE_SUM}_</b>
                <div class='float-right' id='sum-info'></div>
              </li>
              <li class='list-group-item'>
                <b>_{TRANSACTION}_ #:</b>
                <div class='float-right' id='transaction-info'></div>
              </li>
            </ul>
          </div>

          <div class='modal-footer'>
            <button type='button' class='btn btn-primary' data-dismiss='modal'>_{CLOSE}_</button>
          </div>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input class='btn btn-primary float-right' type='submit' name=pre value='_{NEXT}_'>
    </div>
  </div>
</form>

<style>
    input[type='radio']:checked + label {
        box-shadow: 3px 3px 1px #AAAAAA;
    }

    input[type='radio']:hover + label {
        box-shadow: 4px 4px 2px #AAAAAA;
    }

    label {
        border-radius: 5px;
    }

    .logo-container {
        max-width: 12rem;
    }
</style>

<script>
  let height_element = 240;
  jQuery('.logo-container').each(function (elem, val) {
    if (val.scrollHeight > height_element) {
      height_element = val.scrollHeight;
    }
  }).css('height', height_element);

  // from paysys_check
  if ('%index%' === '0') {
    const type = performance.getEntriesByType("navigation")[0]?.type;

    window.addEventListener('pageshow', function (event) {
      var historyTraversal = event.persisted ||
              (type && type === 'back_forward');
      if (historyTraversal) {
        window.location.reload();
      }
    });
  }
</script>

%MAP%
