<form action=%SELF_URL% METHOD=POST>
  <input type='hidden' name='index' value=%index%>
  <input type='hidden' name='chg' value=%ID%>

  <div class='row'>

    <div class='col-md-6'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TARIF_PLAN}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label' for='NAME'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input type='text' required class='form-control' id='NAME' NAME='NAME' VALUE='%NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='MONTH_FEE'>_{MONTH_FEE}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' id='MONTH_FEE' NAME='MONTH_FEE' VALUE='%MONTH_FEE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='DAY_FEE'>_{DAY_FEE}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' id='DAY_FEE' NAME='DAY_FEE' VALUE='%DAY_FEE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
        <div class='col-md-9'>
          <div class='form-check text-left'>
            <input type='checkbox' class='form-check-input' id='PERIOD_ALIGNMENT' name='PERIOD_ALIGNMENT'
                   %PERIOD_ALIGNMENT% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='REDUCTION_FEE'>_{REDUCTION}_:</label>
        <div class='col-md-9'>
          <input type='checkbox' id='REDUCTION_FEE' NAME='REDUCTION_FEE' VALUE='1' %REDUCTION_FEE%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='PAYMENT_TYPE_SEL'>_{PAYMENT_TYPE}_:</label>
        <div class='col-md-9'>
          %PAYMENT_TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='METHOD'>_{FEES}_ _{TYPE}_:</label>
        <div class='col-md-9'>
          %SEL_METHOD%
        </div>
      </div>



      <div class='form-group row'>
        <label class='col-md-3 control-label' for='COMMENT'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control' placeholder='_{COMMENTS}_' name='COMMENT' id='COMMENT'>%COMMENT%</textarea>
        </div>
      </div>

    </div>
  </div>
    </div>
    <div class='col-md-6'>

      <div class='card  card-primary card-outline box-big-form'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{SERVICES}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{INTERNET}_:</label>
            <div class='col-md-9'>
              %INTERNET%
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{TV}_:</label>
            <div class='col-md-9'>
              %IPTV%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{ABON}_:</label>
            <div class='col-md-9'>
              %ABON%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{VOIP}_:</label>
            <div class='col-md-9'>
              %VOIP%
            </div>
          </div>

        </div>
      </div>


      <div class='card  card-primary card-outline box-big-form collapsed-card'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{EXTRA}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-plus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='ACTIVATE_PRICE' class='control-label col-md-4'>_{ACTIVATE}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='ACTIVATE_PRICE' placeholder='%ACTIVATE_PRICE%' name='ACTIVATE_PRICE' value='%ACTIVATE_PRICE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='AGE' class='control-label col-md-4'>_{AGE}_ (_{DAYS}_):</label>
        <div class='col-md-8'>
          <input class='form-control' id='AGE' placeholder='%AGE%' name='AGE' value='%AGE%'>
        </div>
      </div>

      <div class='form-group row bg-info'>
        <label for='NEXT_TARIF_PLAN_SEL' class='control-label col-md-4'>_{TARIF_PLAN}_ _{NEXT_PERIOD}_:</label>
        <div class='col-md-8'>
          %NEXT_TARIF_PLAN_SEL%
        </div>
      </div>
    </div>
  </div>

    </div>
  </div>

  <div class='row'>
    <div class='col-md-12'>
      <div class='card-footer'>
        <input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
      </div>
    </div>
  </div>
</form>