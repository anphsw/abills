<form class='form-horizontal' action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>

<fieldset>
<legend>$_IMPORT</legend>

<div class='form-group'>
  <label class='col-md-6 control-label' for='FILE_DATA'>$_FILE</label>
  <div class='col-md-2'>
    <input id='FILE_DATA' name='FILE_DATA' value='%FILE_DATA%' placeholder='%FILE_DATA%' class='input-file' type='file'>
  </div>
</div>

<div class='form-group'>
  <label class='col-md-6 control-label' for='IMPORT_TYPE'>$_FROM</label>
  <div class='col-md-2'>
    %IMPORT_TYPE_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='col-md-6 control-label' for='DATE'>$_DATE</label>
  <div class='col-md-2'>
    <input id='DATE' name='DATE' value='%DATE%' placeholder='%DATE%' class='form-control' type='text'>
  </div>
</div>


<div class='form-group'>
  <label class='col-md-6 control-label' for='PAYMENT_METHOD'>$_PAYMENT_METHOD</label>
  <div class='col-md-2'>
    %METHOD%
  </div>
</div>

<div class='form-group'>
  <label class='col-md-6 control-label' for='ENCODE'>$_ENCODE</label>
  <div class='col-md-2'>
    %ENCODE_SEL%
  </div>
</div>


<div class='form-group'>
    <label class='col-md-6 control-label' for='DEBUG'>$_DEBUG</label>
    <div class='col-md-2'>
      <input name='DEBUG' id='DEBUG' value='1' type='checkbox'>
    </div>
</div>

<input type=submit name=IMPORT value='IMPORT'>


</fieldset>
</form>


<!--
<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>

<table>
<tr><th align=right colspan=2 class='form_title'>IMPORT</th></tr>
<tr><td>$_FILE:</td><td><input type=file name='FILE_DATA' value='%FILE_DATA%'> <input type=submit name=IMPORT value='IMPORT'></td></tr>
<tr><td>$_FROM:</td><td>%IMPORT_TYPE_SEL%</td></tr>
<!-- <tr><td>$_CANCEL_PAYMENT:</td><td><input type=checkbox name=CANCEL_PAYMENT value='1'></td></tr> -->

<!--
<tr><td>$_DATE:</td><td><input type=text name=DATE value='$DATE'></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>%METHOD%</td></tr>

<tr><td>ENCODE:</td><td>%ENCODE_SEL%</td></tr>
<tr><td>DEBUG:</td><td><input type=checkbox name=DEBUG value='1'></td></tr>


</table>
</form>
-->