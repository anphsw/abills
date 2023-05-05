<form action='%SELF_URL%' method='post'>
  <input class='form-control' type='hidden' name='index' value='%index%'/>
  <input class='form-control' type='hidden' name='ABON_ID' value='$FORM{ABON_ID}'/>

  <div class='card card-primary card-outline container-md col-md-6'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%ACTION_LNG% _{ABON}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' id='NAME' name='NAME' value='%NAME%' maxlength='45'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRICE'>_{SUM}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' id='PRICE' name='PRICE' value='%PRICE%' maxlength='10'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PERIOD_SEL'>_{PERIOD}_:</label>
        <div class='col-md-8'>
          %PERIOD_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PAYMENT_TYPE_SEL'>_{PAYMENT_TYPE}_:</label>
        <div class='col-md-8'>
          %PAYMENT_TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='USER_PORTAL'>_{USER_PORTAL}_:</label>
        <div class='col-md-8'>
          %USER_PORTAL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NONFIX_PERIOD'>_{NONFIX_PERIOD}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='NONFIX_PERIOD'
                   name='NONFIX_PERIOD'
                   %NONFIX_PERIOD% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MANUAL_ACTIVATE'>_{MANUAL_ACTIVATE}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='MANUAL_ACTIVATE'
                   name='MANUAL_ACTIVATE' %MANUAL_ACTIVATE% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='PERIOD_ALIGNMENT'
                   name='PERIOD_ALIGNMENT' %PERIOD_ALIGNMENT% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISCOUNT'>_{REDUCTION}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='DISCOUNT'
                   name='DISCOUNT' %DISCOUNT% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        %EXT_BILL_ACCOUNT%
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %PRIORITY%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FEES_TYPES_SEL'>_{FEES}_ _{TYPE}_:</label>
        <div class='col-md-8'>
          %FEES_TYPES_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'
               for='SERVICE_RECOVERY'>_{SERVICE_RECOVERY}_:</label>
        <div class='col-md-8'>
          %SERVICE_RECOVERY_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CREATE_ACCOUNT'>_{CREATE}_,
          _{SEND_ACCOUNT}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='CREATE_ACCOUNT'
                   name='CREATE_ACCOUNT' %CREATE_ACCOUNT% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='VAT'>_{VAT_INCLUDE}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='VAT'
                   name='VAT' %VAT% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ACTIVATE_NOTIFICATION'>_{SERVICE_ACTIVATE_NOTIFICATION}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='ACTIVATE_NOTIFICATION'
                   name='ACTIVATE_NOTIFICATION' %ACTIVATE_NOTIFICATION% value='1'>
          </div>
        </div>
      </div>


    </div>
    <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{NOTIFICATION}_ (E-mail)</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='NOTIFICATION1'>1:
            _{DAYS_TO_END}_:</label>
          <div class='col-md-2'>
            <input class='form-control' type='text' id='NOTIFICATION1' name='NOTIFICATION1'
                   value='%NOTIFICATION1%'
                   maxlength='2'/>
          </div>

          <label class='col-md-4 col-form-label text-md-right' for='NOTIFICATION_ACCOUNT'>_{CREATE}_,
            _{SEND_ACCOUNT}_:</label>
          <div class='col-md-2'>
            <div class='form-check'>
              <input type='checkbox' data-return='1' class='form-check-input'
                     id='NOTIFICATION_ACCOUNT'
                     name='NOTIFICATION_ACCOUNT' %NOTIFICATION_ACCOUNT% value='1'>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='NOTIFICATION2'>2:
            _{DAYS_TO_END}_:</label>
          <div class='col-md-2'>
            <input class='form-control' type='text' name='NOTIFICATION2' id='NOTIFICATION2'
                   value='%NOTIFICATION2%'
                   maxlength='2'/>
          </div>
          <div class='clearfix-visible-xs-6'></div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='ALERT'>2: _{ENDED}_:</label>
          <div class='col-md-2'>
            <div class='form-check'>
              <input type='checkbox' data-return='1' class='form-check-input' id='ALERT'
                     name='ALERT' %ALERT% value='1'>
            </div>
          </div>

          <label class='col-md-4 col-form-label text-md-right'
                 for='ALERT_ACCOUNT'>_{SEND_ACCOUNT}_:</label>
          <div class='col-md-2'>
            <div class='form-check'>
              <input type='checkbox' data-return='1' class='form-check-input' id='ALERT_ACCOUNT'
                     name='ALERT_ACCOUNT' %ALERT_ACCOUNT% value='1'>
            </div>
          </div>
        </div>
      </div>
    </div>


    <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
      <div class='card-header with-border'>
        <h3 class='card-title'>API</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>
        <div class='form-group row'>
          <label for='MODULE' class='control-label col-md-3'>Plug-in:</label>
          <div class='col-md-9'>
            <input id='MODULE' name='MODULE' value='%MODULE%' placeholder='%MODULE%' class='form-control'
                   type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='URL' class='control-label col-md-3'>URL:</label>
          <div class='col-md-9'>
            <input id='URL' name='URL' value='%URL%' placeholder='%URL%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='LOGIN' class='control-label col-md-3'>_{LOGIN}_:</label>
          <div class='col-md-9'>
            <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%' class='form-control'
                   type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label for='PASSWORD' class='control-label col-md-3'>_{PASSWD}_:</label>
          <div class='col-md-9'>
            <input id='PASSWORD' name='PASSWORD' class='form-control' type='password'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-3 col-form-label text-md-right' for='SERVICE_LINK'>URL:(caption|url):</label>
          <div class='col-md-9'>
            <input class='form-control' id='SERVICE_LINK' type='text' name='SERVICE_LINK' value='%SERVICE_LINK%'
                   maxlength='60'/>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-3 col-form-label text-md-right' for='EXT_CMD'>_{EXT_CMD}_:</label>
          <div class='col-md-9'>
            <input id='EXT_CMD' class='form-control' type='text' name='EXT_CMD' value='%EXT_CMD%'/>
          </div>
        </div>

        <div class='form-group row'>
          <label for='DEBUG' class='control-label col-md-3'>DEBUG:</label>
          <div class='col-md-9'>
            %DEBUG_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label for='DEBUG_FILE' class='control-label col-md-3'>DEBUG _{FILE}_:</label>
          <div class='col-md-9'>
            <input id='DEBUG_FILE' name='DEBUG_FILE' value='%DEBUG_FILE%' class='form-control' type='text'>
          </div>
        </div>

      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESCRIPTION'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea rows='3' id='DESCRIPTION' name='DESCRIPTION' class='form-control'>%DESCRIPTION%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='USER_DESCRIPTION'>_{USER}_
          _{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea rows='3' id='USER_DESCRIPTION' name='USER_DESCRIPTION' class='form-control'>%USER_DESCRIPTION%</textarea>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'/>
    </div>

  </div>
</form>