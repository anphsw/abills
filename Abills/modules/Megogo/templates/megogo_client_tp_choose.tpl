<form action=$SELF_URL METHOD=POST class='form-horizontal'>

<input type='hidden' name='index' value=$index>


<div class='panel panel-primary'>

<div class='panel-heading text-center'>_{TPS}_</div>

<div class='panel-body'>
  <label class='col-md-12 label-primary text-center'>_{PRIMARY}_</label>
  <div class='col-md-12'>
    %PRIMARY_TP%
  </div>
	<label class='col-md-12 label-warning text-center'>_{SECONDARY}_</label>
  <div class='col-md-12'>
    %SECONDARY_TP%
  </div>
</div>


<div class='panel-footer text-center'>
  %WATCH_LABEL%
  %WATCH_BUTTON%
</div>

</div>
</form>