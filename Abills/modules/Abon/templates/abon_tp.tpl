<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input class='form-control' type='hidden' name='index' value='$index'/>
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
            <input type='checkbox' data-return='1' class='form-check-input' id='NONFIX_PERIOD' name='NONFIX_PERIOD'
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
        <label class='col-md-4 col-form-label text-md-right' for='CREATE_ACCOUNT'>_{CREATE}_, _{SEND_ACCOUNT}_:</label>
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

      <div class='form-group text-center'>
        <button class='btn btn-default' type='button' data-toggle='collapse' data-target='#notification'
                aria-expanded='true' aria-controls='collapseExample'>
          _{NOTIFICATION}_ (E-mail)
        </button>
      </div>
      <div class='collapse' id='notification'>
        <div class='card'>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='NOTIFICATION1'>1: _{DAYS_TO_END}_:</label>
              <div class='col-md-2'>
                <input class='form-control' type='text' id='NOTIFICATION1' name='NOTIFICATION1' value='%NOTIFICATION1%'
                       maxlength='2'/>
              </div>

              <label class='col-md-4 col-form-label text-md-right' for='NOTIFICATION_ACCOUNT'>_{CREATE}_,
                _{SEND_ACCOUNT}_:</label>
              <div class='col-md-2'>
                <div class='form-check'>
                  <input type='checkbox' data-return='1' class='form-check-input' id='NOTIFICATION_ACCOUNT'
                         name='NOTIFICATION_ACCOUNT' %NOTIFICATION_ACCOUNT% value='1'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='NOTIFICATION2'>2: _{DAYS_TO_END}_:</label>
              <div class='col-md-2'>
                <input class='form-control' type='text' name='NOTIFICATION2' id='NOTIFICATION2' value='%NOTIFICATION2%'
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

              <label class='col-md-4 col-form-label text-md-right' for='ALERT_ACCOUNT'>_{SEND_ACCOUNT}_:</label>
              <div class='col-md-2'>
                <div class='form-check'>
                  <input type='checkbox' data-return='1' class='form-check-input' id='ALERT_ACCOUNT'
                         name='ALERT_ACCOUNT' %ALERT_ACCOUNT% value='1'>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='EXT_CMD'>_{EXT_CMD}_:</label>
        <div class='col-md-8'>
          <input id='EXT_CMD' class='form-control' type='text' name='EXT_CMD' value='%EXT_CMD%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERVICE_LINK'>URL:(caption|url):</label>
        <div class='col-md-8'>
          <input class='form-control' id='SERVICE_LINK' type='text' name='SERVICE_LINK' value='%SERVICE_LINK%'
                 maxlength='60'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESCRIPTION'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea rows='2' id='DESCRIPTION' name='DESCRIPTION' class='form-control'>%DESCRIPTION%</textarea>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'/>
    </div>
  </div>
</form>