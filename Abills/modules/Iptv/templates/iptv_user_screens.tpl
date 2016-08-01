<div class='panel panel-default panel-form'>
<div class='panel-body'>

<form action=$SELF_URL method=post class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=screen value='$FORM{screen}'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=chg value='$FORM{chg}'>
<input type=hidden name=MODULE value='Iptv'>

<fieldset>
<legend>_{SCREENS}_</legend>
<div class='form-group'>
  %STORAGE_FORM%

  <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
  <div class='col-md-9'>
      %NUM% %NAME%
    </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='CID'>MAC/CID:</label>
  <div class='col-md-9'>
      <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
    </div>
   </div>

<div class='form-group'>
  <label class='control-label col-md-3' for='SERIAL'>_{SERIAL}_:</label>
  <div class='col-md-9'>
      <input id='SERIAL' name='SERIAL' value='%SERIAL%' placeholder='%SERIAL%' class='form-control' type='text'>
    </div>
   </div>

%FORM_DEVICE%

%DEVICE_BINDING_CODE_FORM%

%DELETE%


<div class='col-sm-offset-2 col-sm-8'>
  <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
</div>


</fieldset>

</form>

</div>
</div>
