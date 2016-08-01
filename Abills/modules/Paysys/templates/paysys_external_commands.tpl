<form action='$SELF_URL' >

<input type='hidden' name='index' value=$index>

<div class='panel panel-form panel-primary form-horizontal'>

<div class='panel-heading'>_{EXTERNAL_COMMAND}_</div>

<div class='panel-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{START_COMMAND}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='PAYSYS_EXTERNAL_START_COMMAND'>%PAYSYS_EXTERNAL_START_COMMAND%</textarea>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{END_COMMAND}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='PAYSYS_EXTERNAL_END_COMMAND'>%PAYSYS_EXTERNAL_END_COMMAND%</textarea>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ATTEMPTS}_</label>
    <div class='col-md-9'>
      <input type='number' class='form-control' name='PAYSYS_EXTERNAL_ATTEMPTS' value='%PAYSYS_EXTERNAL_ATTEMPTS%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{TIME}_</label>
    <div class='col-md-9'>
      <input type='number' class='form-control' name='PAYSYS_EXTERNAL_TIME' value='%PAYSYS_EXTERNAL_TIME%'>
    </div>
  </div>
</div>

<div class='panel-footer'>
<input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LANG%'>
</div>

</div>

</form>