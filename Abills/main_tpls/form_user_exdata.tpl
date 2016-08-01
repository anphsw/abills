<input type='hidden' name='UID' value='$FORM{UID}'/>

<div class='form-group'>
    <label class='control-label col-md-2'>_{DEPOSIT}_</label>
    <div class='col-md-3'>
      <h4>
        <span class='label %DEPOSIT_MARK% pull-left'>%DEPOSIT%</span>
      </h4>
      %PAYMENTS_BUTTON%  %FEES_BUTTON% %PRINT_BUTTON%
    </div>

  <label class='control-label col-md-2' for='BILL'>_{BILL}_</label>
  <div class='col-md-3'>
    <div class='input-group'>
      <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' readonly>
      <span class='input-group-addon'>%BILL_CORRECTION%</span>
    </div>
  </div>
</div>


<!-- COMPANY -->
<div class='form-group'>
  <label class='control-label col-md-2'>_{GROUPS}_</label>
  <div class='col-md-3'>
    <div class='input-group'>
      <input type=text name='GRP' value='%GID%:%G_NAME%' ID='GRP' class='form-control' readonly>
      <span class='input-group-addon'><a href='$SELF_URL?index=12&UID=$FORM{UID}' class='glyphicon glyphicon glyphicon-pencil'></a></span>
    </div>
  </div>

  <label class='control-label col-md-2'>_{COMPANY}_</label>
  <div class='col-md-3'>
    <div class='input-group'>
      <input type=text name='COMP' value='%COMPANY_NAME%' ID='COMP' class='form-control' readonly>
      <span class='input-group-addon'><a href='$SELF_URL?index=13&amp;COMPANY_ID=%COMPANY_ID%' class='glyphicon glyphicon-circle-arrow-left'></a></span>
      <span class='input-group-addon'><a href='$SELF_URL?index=21&UID=$FORM{UID}' class='glyphicon glyphicon-pencil'></a></span>
    </div>
  </div>
</div>
