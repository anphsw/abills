<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{ACTION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME' >_{CUSTOMER}_:</label>
        <div class='col-md-8'>
          <input id='CUSTOMER' name='CUSTOMER' value='%CUSTOMER%' placeholder='%CUSTOMER%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='UID'>UID:</label>
        <div class='col-md-8'>
          <input id='UID' name='UID' value='%UID%' placeholder='%UID%' class='form-control' type='number'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %SELECT_TYPE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CONTRACT_ID'>_{CONTRACT}_:</label>
        <div class='col-md-8'>
          <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' placeholder='%CONTRACT_ID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-md-3 col-form-label text-md-right' for='CONTRACT_DATE'>_{DATE}_</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE' value='%CONTRACT_DATE%' class='datepicker form-control'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='INN'>_{INN}_:</label>
        <div class='col-md-8'>
          <input id='INN' name='INN' value='%INN%' placeholder='%INN%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='EDRPOU'>_{EDRPOU}_:</label>
        <div class='col-md-8'>
          <input id='EDRPOU' name='EDRPOU' value='%EDRPOU%' placeholder='%EDRPOU%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IS_DOCS'>_{DOCUMENTS}_:</label>
        <div class="col-sm-8 col-md-8 p-2">
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='IS_DOCS'
                   name='IS_DOCS' %IS_DOCS% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLE'>_{DISABLE}_:</label>
        <div class="col-sm-8 col-md-8 p-2">
        <div class='form-check'>
          <input type='checkbox' data-return='1' class='form-check-input' id='DISABLE'
                 name='DISABLE' %DISABLE% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea id='COMMENTS' name='COMMENTS' cols='50' rows='4' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>