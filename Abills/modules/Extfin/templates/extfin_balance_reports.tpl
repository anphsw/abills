<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value='$index'>

<div class='card box-form box-primary form-horizontal'>
  
<div class='card-header with-border'>_{FILTER}_</div>

<div class='card-body'>
  <div class='form-group'>
  <label class='col-md-3 control-label'>_{MONTH}_</label>
  <div class='col-md-9'>%MONTH_SELECT%</div>
  </div>
</div>

<div class='card-body'>
  <div class='form-group'>
  <label class='col-md-3 control-label'>_{YEAR}_</label>
  <div class='col-md-9'>%YEAR_SELECT%</div>
  </div>
</div>

  <div class='card-body'>
    <div class='form-group'>
      <label class='col-md-3 control-label'>_{GROUP}_</label>
      <div class='col-md-9'>%GROUPS_SELECT%</div>
    </div>
  </div>

<div class='card-footer'>
  <input type='submit' class='btn btn-primary' value='_{SHOW}_' name='show'>
</div>

</div>

</form>