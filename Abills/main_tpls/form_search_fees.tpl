<div class='col-sm-12 col-md-6'>
  <div class='card card-primary card-outline collapsed-card'>

    <div class='card-header'>
      <h3 class='card-title'>_{OTHER}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-plus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 col-form-label' for='A_LOGIN'>_{OPERATOR}_ (_{LOGIN}_)</label>
        <div class='col-sm-8 col-md-8'>
          <input id='A_LOGIN' name='A_LOGIN' value='%A_LOGIN%' placeholder='%A_LOGIN%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 col-form-label' for='DESCRIBE'>_{DESCRIBE}_ _{USERS}_</label>
        <div class='col-sm-8 col-md-8'>
          <input id='DESCRIBE' name='DESCRIBE' value='%DESCRIBE%' placeholder='%DESCRIBE%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 col-form-label' for='INNER_DESCRIBE'>_{INNER}_</label>
        <div class='col-sm-8 col-md-8'>
          <input id='INNER_DESCRIBE' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%'
                 placeholder='%INNER_DESCRIBE%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 col-form-label' for='METHOD_SEL'>_{TYPE}_</label>
        <div class='col-sm-8 col-md-8'>
          %METHOD_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 col-form-label' for='ID'>_{FEES}_ ID</label>
        <div class='col-sm-8 col-md-8'>
          <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
        </div>
      </div>


      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 col-form-label' for='SUM'>_{SUM}_</label>
        <div class='col-sm-8 col-md-8'>
          <input id='SUM' name='SUM' value='%SUM%' placeholder='%SUM%' class='form-control' type='text'>
        </div>
      </div>
    </div>

    <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>

      <div class='card-header'>
        <h3 class='card-title'>_{EXTRA}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='SUBCONTO'>_{SUBCONTO}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='SUBCONTO' name='SUBCONTO' value='%SUBCONTO%' placeholder='%SUBCONTO%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='START_DATE'>_{DATE}_ _{FROM}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='START_DATE' name='START_DATE' value='%START_DATE%' placeholder='%START_DATE%'
                   class='form-control datepicker' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='END_DATE'>_{DATE}_ _{TO}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='END_DATE' name='END_DATE' value='%END_DATE%' placeholder='%END_DATE%' class='form-control datepicker'type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='MODULE'>_{MODULE}_</label>
          <div class='col-sm-8 col-md-8'>
            %MODULE_SEL%
          </div>
        </div>


        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='TP_ID'>TP ID</label>
          <div class='col-sm-8 col-md-8'>
            <input id='TP_ID' name='TP_ID' value='%TP_ID%' placeholder='%TP_ID%' class='form-control' type='number' min='1'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='COUNT'>_{COUNT}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='COUNT' name='COUNT' value='%COUNT%' placeholder='%COUNT%' class='form-control' type='number' min='1'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='UNITS'>_{UNITS}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='UNITS' name='UNITS' value='%UNITS%' placeholder='%UNITS%' class='form-control' type='number' min='1'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='DISCOUNT'>_{DISCOUNT}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='DISCOUNT' name='DISCOUNT' value='%DISCOUNT%' placeholder='%DISCOUNT%' class='form-control' type='number' min='1'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='PAYMENT_ID'>_{PAYMENT}_ ID</label>
          <div class='col-sm-8 col-md-8'>
            <input id='PAYMENT_ID' name='PAYMENT_ID' value='%PAYMENT_ID%' placeholder='%PAYMENT_ID%' class='form-control' type='number' min='1'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-4 col-md-4 col-form-label' for='COMPENSATION'>_{COMPENSATION}_</label>
          <div class='col-sm-8 col-md-8'>
            <input id='COMPENSATION' name='COMPENSATION' value='%COMPENSATION%' placeholder='%COMPENSATION%' class='form-control' type='number' min='1'>
          </div>
        </div>

      </div>
    </div>
  </div>
</div>
