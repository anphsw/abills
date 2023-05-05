<div class='form-group row'>
  <label class='col-form-label text-right col-4 col-md-2' for='LOGIN'>_{LOGIN}_:</label>
  <div class='col-8 col-md-4'>
    <input id='LOGIN' name='LOGIN' value='%LOGIN%' data-check-for-pattern='%LOGIN_PATTERN%' class='form-control' type='text'>
    <div class='invalid-feedback'>
      _{USER_EXIST}_
    </div>
  </div>
  %CREATE_COMPANY%
</div>

<div class='form-group row'>
  <label class='col-form-label text-right col-4 col-md-2 %GROUP_REQ%' for='GID'>_{GROUPS}_:</label>
  <div class='col-8 col-md-4'>
    %GID%
  </div>
</div>

<div class='form-group row'>
  <label class='col-form-label text-right col-4 col-md-2' for='CREATE_BILL'>_{BILL}_:</label>
  <div class='col-8 col-md-4'>
    <div class='form-check'>
      <input type='checkbox' class='form-check-input' id='CREATE_BILL' name='CREATE_BILL' value='%CREATE_BILL%' %CREATE_BILL%> _{CREATE}_
    </div>
  </div>
</div>

