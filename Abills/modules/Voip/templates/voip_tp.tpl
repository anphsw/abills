<form action='$SELF_URL' METHOD='POST' class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=TP_ID value=%TP_ID%>
  <div class='row'>
    <div class='col-md-6'>
      <div class='col-md-12'>
        <div class='card card-primary card-outline'>
          <div class='card-header with-border'>
            <h4 class='card-title'>_{TARIF_PLAN}_</h4>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-minus'></i>
              </button>
            </div>
          </div>
          <div id='_main' class='card-body'>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>#:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=ID value='%ID%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{NAME}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=NAME value='%NAME%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{UPLIMIT}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=ALERT value='%ALERT%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{SIMULTANEOUSLY}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{HOUR_TARIF}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=TIME_TARIF value='%TIME_TARIF%'>
              </div>
            </div>
          </div>
        </div>
        <div class='card card-primary card-outline collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{LIMIT}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div id='_t3' class='card-body'>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{DAY}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{WEEK}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{MONTH}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'>
              </div>
            </div>
          </div>
        </div>
        <div class='card card-primary card-outline collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{TIME}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div id='_t5' class='card-body'>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{FREE_TIME}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=FREE_TIME value='%FREE_TIME%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{FIRST_PERIOD}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=FIRST_PERIOD value='%FIRST_PERIOD%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{FIRST_PERIOD_STEP}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=FIRST_PERIOD_STEP value='%FIRST_PERIOD_STEP%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{NEXT_PERIOD}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=NEXT_PERIOD value='%NEXT_PERIOD%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{NEXT_PERIOD_STEP}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=NEXT_PERIOD_STEP value='%NEXT_PERIOD_STEP%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{TIME_DIVISION}_ (_{SECONDS}_ .):</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=TIME_DIVISION value='%TIME_DIVISION%'>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='col-md-12'>
        <div class='card card-primary card-outline'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{ABON}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-minus'></i>
              </button>
            </div>
          </div>
          <div id='_abon' class='card-body'>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{DAY_FEE}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=DAY_FEE value='%DAY_FEE%'>
              </div>
            </div>

            <div class="form-group custom-control custom-checkbox">
              <input class="custom-control-input" type="checkbox" id="POSTPAID_DAY_FEE" name="POSTPAID_DAY_FEE"
                     %POSTPAID_DAY_FEE% value='1'>
              <label for="POSTPAID_DAY_FEE" class="custom-control-label">_{DAY_FEE}_ _{POSTPAID}_</label>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{MONTH_FEE}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=MONTH_FEE value='%MONTH_FEE%'>
              </div>
            </div>

            <div class="form-group custom-control custom-checkbox">
              <input class="custom-control-input" type="checkbox" id="POSTPAID_MONTH_FEE" name="POSTPAID_MONTH_FEE"
                     %POSTPAID_MONTH_FEE% value='1'>
              <label for="POSTPAID_MONTH_FEE" class="custom-control-label">_{MONTH_FEE}_ _{POSTPAID}_</label>
            </div>

            <div class='form-group row'>
              <label for='METHOD' class='control-label col-md-3'>_{FEES}_ _{TYPE}_:</label>
              <div class='col-md-9'>
                %SEL_METHOD%
              </div>
            </div>
          </div>
        </div>
        <div class='card card-primary card-outline collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{OTHER}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div id='_other' class='card-body'>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{MAX_SESSION_DURATION}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{AGE}_ (_{DAYS}_):</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=AGE value='%AGE%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{PAYMENT_TYPE}_:</label>
              <div class='col-md-9'>%PAYMENT_TYPE_SEL%</div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{MIN_SESSION_COST}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type='text' name='MIN_SESSION_COST' value='%MIN_SESSION_COST%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>FILTER_ID:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=FILTER_ID value='%FILTER_ID%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{ACTIVATE}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{CHANGE}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{CREDIT_TRESSHOLD}_:</label>
              <div class='col-md-9'>
                <input class='form-control' type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='row'>
    <div class="col-md-12">
      <div class='card-footer'>
        <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
      </div>
    </div>
  </div>
</form>