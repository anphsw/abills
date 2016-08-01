<form action='$SELF_URL' METHOD='POST' name='user' ID='user' class='form-horizontal'>
<input type=hidden name=sid value='$sid'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=ID value='%ID%'>
<input type=hidden name=m value='%m%'>
<input type=hidden name='index' value='$index'>

<fieldset>

<div class='panel panel-default panel-form'>
<div class='panel-body'>
<legend>_{TARIF_PLANS}_</legend>

<div class='form-group'>
  <label class='control-label col-md-3' for='TARIF'>_{FROM}_</label>
  <div class='col-md-9 text-left'>
    <input type=text name=TARIF value='$user->{TP_ID} %TP_NAME%' ID='TARIF' class='form-control' readonly style='text-align: inherit;'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='TARIF_PLAN'>_{TO}_</label>
  <div class='col-md-9 text-left'>
    %TARIF_PLAN_SEL%
  </div>
</div>

<div class='form-group'>
<label class='control-label col-md-5' for='GET_ABON'>_{GET}_ _{ABON}_:</label>
  <div class='col-md-2'>
    <input type=checkbox name=GET_ABON ID='GET_ABON' value=1 checked>
  </div>

<label class='control-label col-md-3' for='RECALCULATE'>_{RECALCULATE}_</label>
  <div class='col-md-2'>
    <input type=checkbox name=RECALCULATE value=1 checked>
  </div>
</div>

%PARAMS%
<br>
%SHEDULE_LIST%
<br>&nbsp;
<div class='form-group'>
  <div class='col-sm-offset-2 col-sm-8'>
    <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
  </div>
</div>

</div>
</div>

</fieldset>
</form>
