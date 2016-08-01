<style type="text/css">
  .rules {
    left: 0;
  }
</style>

%NEWS%
<div class='panel panel-primary'>
  <div class='panel-heading text-center'>
    <button type='button' class='btn btn-success pull-left' data-toggle='modal' data-target='#rulesModal'>
      _{RULES}_
    </button>
    <span class='extra'>%FORM_CHG_INFO%</span>
    <h4>
      _{INFO}_
    </h4>
  </div>
  <div class='panel-body'>
    <div class='table table-hover table-striped'>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{LOGIN}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%LOGIN% <i>(UID: %UID%)</i>
          <div class='extra'>%CHANGE_PASSWORD%</div>
        </div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{DEPOSIT}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%DEPOSIT%
          <div class='extra'>%DOCS_ACCOUNT% %PAYSYS_PAYMENTS%</div>
        </div>
      </div>
      <div class='row'>
        %EXT_DATA%
      </div>
      <div class='row'>
        %INFO_FIELDS%
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{CREDIT}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>
          <span class='strong'>%CREDIT%</span>

          <div class='extra'>%CREDIT_CHG_BUTTON% _{DATE}_: %CREDIT_DATE%</div>
        </div>
      </div>
      <!--
                  <div class='row'>
                      <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{REDUCTION}_</div>
                      <div class='col-xs-12 col-sm-9 col-md-9 text-2'>
                          <span class='strong'>%REDUCTION%</span>

                          <div class='extra'>_{DATE}_: %REDUCTION_DATE%</div>
                      </div>
                  </div>
      -->
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{FIO}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%FIO%</div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{PHONE}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PHONE%</div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{ADDRESS}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>E-mail</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%EMAIL%</div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{CONTRACT}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%CONTRACT_ID%%CONTRACT_SUFIX%
          <div class='extra '>
            <a class='btn' target='new'
               href='$SELF_URL?qindex=10&PRINT_CONTRACT=%CONTRACT_ID%&sid=$sid&pdf=$conf{DOCS_PDF_PRINT}'
               title='_{PRINT}_'><span class='glyphicon glyphicon glyphicon-print'></span></a>
          </div>
        </div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{CONTRACT}_ _{DATE}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%CONTRACT_DATE%</div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{STATUS}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%STATUS%</div>
      </div>
      <!--            <div class='row'>
                      <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{ACTIVATE}_</div>
                      <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%ACTIVATE%</div>
                  </div>
                  <div class='row'>
                      <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{EXPIRE}_</div>
                      <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%EXPIRE%</div>
                  </div>
      -->
      <div class='row'>
        <div class='bg-success text-center'><strong>_{PAYMENTS}_</strong></div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{DATE}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PAYMENT_DATE%</div>
      </div>
      <div class='row'>
        <div class='col-xs-12 col-sm-3 col-md-3 text-1'>_{SUM}_</div>
        <div class='col-xs-12 col-sm-9 col-md-9 text-2'>%PAYMENT_SUM%</div>
      </div>
    </div>
  </div>
</div>

<div class='modal fade' id='changeCreditModal'>
  <div class='modal-dialog modal-sm'>
    <form action=$SELF_URL class='form form-horizontal text-center' id='changeCreditForm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>&times;</span></button>
          <h4 class='modal-title text-center'>_{CHANGE}_ _{CREDIT}_</h4>
        </div>
        <div class='modal-body' style='padding: 30px;'>
          <input type=hidden name='index' value='10'>
          <input type=hidden name='sid' value='$sid'>

          <div class='form-group'>
            <label class='col-md-7'>_{SUM}_: </label>
            <label class='col-md-3'> %CREDIT_SUM%</label>
          </div>
          <div class='form-group'>
            <label class='col-md-7'>_{PRICE}_:</label>
            <label class='col-md-3'>%CREDIT_CHG_PRICE%</label>
          </div>
          <div class='form-group'>
            <label class='col-md-7'>_{ACCEPT}_:</label>

            <div class='col-md-3'>
              <input type='checkbox' value='%CREDIT_SUM%' name='change_credit'>
            </div>
          </div>
        </div>
        <div class='modal-footer'>
          <input type=submit class='btn btn-primary' value='_{SET}_' name='set'>
        </div>
      </div>
    </form>
  </div>
</div>
<!-- /.modal -->

<script>
  jQuery('.open_credit_window').on('click', function () {
    jQuery('#changeCreditModal').modal({
      show    : true,
      keyboard: true,
      backdrop: true
    });
  });

  jQuery(function () {
    if ('%PINFO%' === '1') {

      var template = "%TEMPLATE_BODY%" || '';

      function init_address_form() {
        eval("%ADDRESS_FORM_INIT%");
      }

      if(aModal){
        aModal.hide();
      }

      aModal.clear()
          .setBody(template)
          .show(function () {
            init_address_form();
            jQuery.getScript('/styles/default_adm/js/searchLocation.js');
            updateChosen();
          });

    }
  });
</script>

<div class='modal fade' id='rulesModal' tabindex='-1' role='dialog' aria-labelledby='myModalLabel'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %ACCEPT_RULES%
    </div>
  </div>
</div>