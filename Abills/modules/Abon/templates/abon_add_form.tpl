<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='FULL_INFO_ACTIVATE_TP_ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%TITLE%</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IDS'>_{ACTIVATE}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='IDS' name='IDS' %ACTIVATED% value='%ID%'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS_%ID%'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <input id='COMMENTS_%ID%' name='COMMENTS_%ID%' value='%COMMENTS%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PERSONAL_DESCRIPTION_%ID%'>_{PERSONAL_DESCRIPTION}_:</label>
        <div class='col-md-8'>
          <input id='PERSONAL_DESCRIPTION_%ID%' name='PERSONAL_DESCRIPTION_%ID%' value='%PERSONAL_DESCRIPTION%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERVICE_COUNT_%ID%'>_{SERVICE_COUNT}_:</label>
        <div class='col-md-8'>
          <input id='SERVICE_COUNT_%ID%' name='SERVICE_COUNT_%ID%' value='1' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FEES_PERIOD_%ID%'>_{FEES_PERIOD}_:</label>
        <div class='col-md-8'>
          <input id='FEES_PERIOD_%ID%' name='FEES_PERIOD_%ID%' value='0' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DATE_%ID%'>_{START}_:</label>
        <div class='col-md-8'>
          <input id='DATE_%ID%' name='DATE_%ID%' value='%NEXT_ABON%' placeholder='0000-00-00' class='form-control datepicker' type='text' %START_DISABLED%>
          <!-- %NEXT_ABON% -->
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='END_DATE_%ID%'>_{END}_:</label>
        <div class='col-md-8'>
          <input id='END_DATE_%ID%' name='END_DATE_%ID%' value='%END_DATE%' placeholder='0000-00-00' class='form-control datepicker' type='text' %END_DISABLED%>
          <!-- %NEXT_ABON% -->
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISCOUNT_%ID%'>_{REDUCTION}_ (%):</label>
        <div class='col-md-8'>
          <input id='DISCOUNT_%ID%' name='DISCOUNT_%ID%' value='%DISCOUNT%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISCOUNT_ACTIVATE_%ID%'>_{ABON_DISCOUNT_ACTIVATE_DATE}_:</label>
        <div class='col-md-8'>
          <input id='DISCOUNT_ACTIVATE_%ID%' name='DISCOUNT_ACTIVATE_%ID%' value='%DISCOUNT_ACTIVATE%' placeholder='0000-00-00' class='form-control datepicker' type='text'>
          <!-- %DISCOUNT_ACTIVATE_DATE% -->
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISCOUNT_EXPIRE_%ID%'>_{ABON_DISCOUNT_EXPIRE_DATE}_:</label>
        <div class='col-md-8'>
          <input id='DISCOUNT_EXPIRE_%ID%' name='DISCOUNT_EXPIRE_%ID%' value='%DISCOUNT_EXPIRE%' placeholder='0000-00-00' class='form-control datepicker' type='text'>
          <!-- %DISCOUNT_EXPIRE_DATE% -->
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CREATE_DOCS_%ID%'>_{CREATE}_ _{DOCS}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='CREATE_DOCS_%ID%' name='CREATE_DOCS_%ID%' %CREATE_DOCS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SEND_DOCS_%ID%'>_{SEND_NOTIFICATION}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='SEND_DOCS_%ID%' name='SEND_DOCS_%ID%' %SEND_DOCS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MANUAL_FEE_%ID%'>_{MANUAL_ACTIVATE}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='MANUAL_FEE_%ID%' name='MANUAL_FEE_%ID%' %MANUAL_FEE% value='1'>
          </div>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <button type='submit' class='btn btn-primary float-right' value='1' name='change'>_{CHANGE}_</button>
    </div>
  </div>
</form>
