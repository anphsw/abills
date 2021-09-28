<style type='text/css'>
	.rules {
		left: 0;
	}

	.social-auth-links > .btn-group {
		width: 100%;
		max-width: 150px;
		margin-bottom: 10px;
	}

	.social-auth-links > .btn-group > a.btn.btn-social {
		width: 80%;
	}

	.social-auth-links > .btn-group > a.btn.btn-social-unreg {
		width: 20%;
	}

	div#notifications-subscribe-block {
		margin-bottom: 10px;
	}
</style>

<div class='modal fade' id='changeCreditModal' data-open='%OPEN_CREDIT_MODAL%'>
  <div class='modal-dialog modal-sm'>
    <form action=$SELF_URL class='text-center pswd-confirm' id='changeCreditForm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h4 class='modal-title text-center'>_{SET_CREDIT}_</h4>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
            <span aria-hidden='true'>&times;</span>
          </button>
        </div>
        <div class='modal-body'>
          <input type=hidden name='index' value='10'>
          <input type=hidden name='sid' value='$sid'>
          <input type=hidden name='CREDIT_RULE' value='' ID='CREDIT_RULE'>

          <div class='form-group row'>
            <label class='col-md-7'>_{CREDIT_SUM}_: </label>
            <label class='col-md-3'>%CREDIT_SUM%</label>
          </div>

          <div class='form-group row'>
            <label class='col-md-7'>_{CREDIT_PRICE}_:</label>
            <label class='col-md-3' id='CREDIT_CHG_PRICE'>%CREDIT_CHG_PRICE%</label>
          </div>

          <div class='form-group row'>
            <label class='col-md-7' for='change_credit'>_{ACCEPT}_:</label>

            <div class='col-md-3'>
              <input id='change_credit' type='checkbox' required='required' value='%CREDIT_SUM%' name='change_credit'>
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

<div class='modal fade' id='confirmationClientInfo' tabindex='-1' role='dialog'
     data-open='%CONFIRMATION_CLIENT_PHONE_OPEN_INFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %FORM_CONFIRMATION_CLIENT_PHONE%
    </div>
  </div>
</div>

<div class='modal fade' id='confirmationClientInfo2' tabindex='-1' role='dialog'
     data-open='%CONFIRMATION_EMAIL_OPEN_INFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %FORM_CONFIRMATION_CLIENT_EMAIL%
    </div>
  </div>
</div>

<div class='modal fade' id='changePersonalInfo' tabindex='-1' role='dialog' data-open='%PINFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %TEMPLATE_BODY%
    </div>
  </div>
</div>

<div class='modal fade' id='rulesModal' tabindex='-1' role='dialog' aria-labelledby='myModalLabel'>
  <div class='modal-dialog modal-lg' role='document'>
    <div class='modal-content'>
      %ACCEPT_RULES%
    </div>
  </div>
</div>

<div class='row'>
  <div class='col-md-12'>%NEWS%</div>

  <div class='col-md-12 row' id='notifications-subscribe-block'>
    %SENDER_SUBSCRIBE_BLOCK%
  </div>

  <script>
    var show = %SHOW_SUBSCRIBE_BLOCK%;
    if(!show){
      jQuery("#notifications-subscribe-block").hide();
    }
  </script>

  <div class='%INFO_CARD_CLASS%'>
    <div class='card card-primary card-outline'>
      <div class='card-header'>
        <h3 class='card-title'> _{INFO}_</h3>
        <div class='card-tools'>
          <button type='button' class='btn btn-success btn-xs %SHOW_ACCEPT_RULES%' data-toggle='modal' data-target='#rulesModal'>
            _{RULES}_
          </button>
          %FORM_CHG_INFO%
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body p-2'>
        <table class='table table-bordered table-sm'>
          <tr>
            <td class='font-weight-bold text-right'>_{LOGIN}_</td>
            <td>%LOGIN% (UID: %UID%)</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{DEPOSIT}_</td>
            <td>
              <div class='d-flex bd-highlight'>
                <div class='bd-highlight'>%DEPOSIT% %MONEY_UNIT_NAME%</div>
                <div class='ml-auto bd-highlight'>
                  <div class='bd-example'>
                    %DOCS_ACCOUNT% %PAYSYS_PAYMENTS% %CARDS_PAYMENTS%
                  </div>
                </div>
              </div>
            </td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{FIO}_</td>
            <td>%FIO%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{PHONE}_</td>
            <td>%PHONE_ALL%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{CELL_PHONE}_</td>
            <td>%CELL_PHONE_ALL%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>E-mail</td>
            <td>%EMAIL%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{ADDRESS}_</td>
            <td>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{CREDIT}_</td>
            <td>
              <div class='d-flex bd-highlight'>
                <div class='bd-highlight'>%CREDIT% %MONEY_UNIT_NAME% ( %CREDIT_DATE% )</div>
                <div class='ml-auto bd-highlight'>
                  <div class='bd-example'>
                    %CREDIT_CHG_BUTTON%
                  </div>
                </div>
              </div>
            </td>
          </tr>
          <tr class='%SHOW_REDUCTION%'>
            <td class='font-weight-bold text-right'>_{REDUCTION}_</td>
            <td>%REDUCTION% %</td>
          </tr>
          <tr class='%SHOW_REDUCTION%'>
            <td class='font-weight-bold text-right'>_{REDUCTION}_ _{DATE}_</td>
            <td>%REDUCTION_DATE%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{CONTRACT}_</td>
            <td>
              <div class='d-flex bd-highlight'>
                <div class='bd-highlight'>%CONTRACT_ID%%CONTRACT_SUFIX%%NO_CONTRACT_MSG%</div>
                <div class='ml-auto bd-highlight'>
                  <div class='bd-example'>
                    <a %NO_DISPLAY% title='_{PRINT}_' target='new' class='p-2'
                       href='$SELF_URL?qindex=10&PRINT_CONTRACT=%CONTRACT_ID%&sid=$sid&pdf=$conf{DOCS_PDF_PRINT}'>
                      <span class='fa fa-print'></span>
                    </a>

                    <a href='$SELF_URL?index=10&CONTRACT_LIST=1%&sid=$sid' title='_{LIST}_' class='p-2'>
                      <span class='fa fa-list'></span>
                    </a>
                  </div>
                </div>
              </div>
            </td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{CONTRACT}_ _{DATE}_</td>
            <td>%CONTRACT_DATE%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{STATUS}_</td>
            <td>%STATUS%</td>
          </tr>

          %EXT_DATA%
          %INFO_FIELDS%
          <tr><td colspan='2' class='bg-success text-center'>_{PAYMENTS}_</td></tr>
          <tr>
            <td class='font-weight-bold text-right'>_{DATE}_</td>
            <td>%PAYMENT_DATE%</td>
          </tr>
          <tr>
            <td class='font-weight-bold text-right'>_{SUM}_</td>
            <td>%PAYMENT_SUM%</td>
          </tr>

        </table>
        <div class='mt-1'>
          %CHANGE_PASSWORD% %AUTH_G2FA%
        </div>
      </div>
    </div>

  </div>

  <div class='col-md-2 no-padding' data-visible='%HAS_SOCIAL_BUTTONS%' style='display : none'>
    <div class='social-auth-links text-center'>
      %SOCIAL_AUTH_BUTTONS_BLOCK%
    </div>
  </div>

</div>