<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>

<div class='panel panel-form panel-primary form-horizontal'>
<div class='panel-heading'>_{TYPE}_</div>
<div class='panel-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='NAME' value='%NAME%'>
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