<form method='POST' class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='TABLE_FILE' value='$FORM{TABLE_FILE}'>

<div class='card box-primary'>
  <div class='card-header'>
    <div class='form-group'> 
      <div class='collapse navbar-collapse'>
        <label class='col-md-2'>_{GROUP}_</label>
        <div class='col-md-3'>%GROUP_SELECT%</div>
        <div class='col-md-3'>%BUTTON_STYLE%</div>
      </div>
    </div>
  </div>
</div>

%FILES%
</form>