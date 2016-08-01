<form action=$SELF_URL METHOD=POST class='form form-horizontal'>

<input type='hidden' name='index'  value=$index>
<input type='hidden' name='ACTION' value='%ACTION%'>
<input type='hidden' name='ID'   value='%ID%'>

<div class='panel panel-primary panel-form'>
    <div class='panel-heading text-center'>_{ADD}_ _{TERMINALS}_</div>

<div class='panel-body'>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{TYPE}_</label>
    <div class='col-md-9'>
      %TERMINAL_TYPE%
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{STATUS}_</label>
    <div class='col-md-9'>
      %STATUS%
    </div>
  </div>
<hr>

    %ADRESS_FORM%

<hr>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9 control-label'>
      <textarea class='form-control' name='COMMENT'>%COMMENT%</textarea>
    </div>
  </div>

</div>

<div class='panel-footer'>
  <button class='btn btn-primary' type='submit'>%BTN%</button>
</div>

</div>

</form>
