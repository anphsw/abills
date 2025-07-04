<form action='%SELF_URL%' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='search_form' value='1'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title '>_{SET_PARAMS}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body row'>
      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label' for='FROM_DATE_TO_DATE'>_{DATE}_ _{FROM}_/_{DATE}_ _{TO}_</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='hidden' name='FROM_DATE' value='%FROM_DATE%' id='FROM_DATE'>
            <input type='hidden' name='TO_DATE' value='%TO_DATE%' id='TO_DATE'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' %DATE_PICKER_CHECKED% class='form-control-static' data-input-enables='FROM_DATE_TO_DATE,FROM_DATE,TO_DATE'/>
              </span>
            </div>
            %DATE_PICKER%
          </div>
        </div>
      </div>


      <div class='form-group row col-md-6'>
        <label class='col-md-3 col-form-label text-md-right' for='SUM'>_{SUM}_</label>
        <div class='col-md-3'>
          <input class='form-control' type='text' id='SUM' name='SUM' value='%SUM%'>
        </div>
        <label class='col-md-2 col-form-label text-md-right' for='PERCENT'>_{PERCENT}_</label>
        <div class='col-md-3'>
          <input class='form-control' type='number' min='0' max='100' name='PERCENT' id='PERCENT' value='%PERCENT%'>
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label' for='FROM_REG_DATE_TO_REG_DATE'>_{DATE_OF_CREATION}_</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='hidden' name='FROM_REG_DATE' value='%FROM_REG_DATE%' id='FROM_REG_DATE'>
            <input type='hidden' name='TO_REG_DATE' value='%TO_REG_DATE%' id='TO_REG_DATE'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' %REG_DATE_PICKER_CHECKED% class='form-control-static' data-input-enables='FROM_REG_DATE_TO_REG_DATE,FROM_REG_DATE,TO_REG_DATE'/>
              </span>
            </div>
            %REG_DATE_PICKER%
          </div>
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{STATUS}_</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{TYPE}_</label>
        <div class='col-md-8'>
          %REPORT_TYPE_SEL%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{DISCOUNTS_TYPE}_</label>
        <div class='col-md-8'>
          %DISCOUNT_TYPE_SEL%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 control-label'>_{ADMIN}_</label>
        <div class='col-md-8'>
          %ADMIN_SEL%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 col-form-label text-md-right' for='GROUP'>_{GROUP}_</label>
        <div class='col-md-8'>
          %GROUP_SEL%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 col-form-label text-md-right' for='TAGS'>_{TAGS}_</label>
        <div class='col-md-8'>
          %TAGS_SEL%
        </div>
      </div>

      <div class='form-group row col-md-6'>
        <label class='col-md-3 text-right control-label' for='ADDRESS' ></label>
        <div class='col-md-8'>
          %ADDRESS_TPL%
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input class='btn btn-primary btn-block' type='submit' name='search' value='_{SHOW}_'>
    </div>
  </div>
</form>


