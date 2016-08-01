<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>

<div class='panel panel-form panel-primary form-horizontal'>
<div class='panel-heading'>_{COMING}_</div>
<div class='panel-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{SUM}_</label>
    <div class='col-md-9'>
      <input type='number' step='0.01' class='form-control' name='AMOUNT' value='%AMOUNT%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMING}_ _{TYPE}_</label>
    <div class='col-md-9'>
      %COMING_TYPE_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CASHBOX}_</label>
    <div class='col-md-9'>
      %CASHBOX_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{DATE}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control tcal' name='DATE' value='%DATE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='panel-footer'>
  <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
</div>
</div>

</form>