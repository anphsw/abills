<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
<input type='hidden' name='index' value='27'/>
<input type='hidden' name='chg' value='%GID%'/>

<fieldset>
<div class='panel panel-primary panel-form'>
<div class='panel-heading text-center'><h4>_{GROUPS}_</h4></div>
<div class='panel-body'>



<div class='form-group'>
    <label class='control-label col-md-3 required' for='GID'>GID:</label>
  <div class='col-md-9'>
      <input id='GID' name='GID' value='%GID%' required placeholder='%GID%' class='form-control' type='text'>
   </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
  <div class='col-md-9'>
    <input id='NAME' type='text' name='NAME' value='%NAME%' class='form-control'>
  </div>
</div>

<div class='form-group'>
    <label class='control-label col-md-3' for='DESCRIBE'>_{DESCRIBE}_:</label>
  <div class='col-md-9'>
     <input id='DESCRIBE' type='text' name='DESCRIBE' value='%DESCRIBE%' class='form-control'>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-6' for='ALLOW_CREDIT'>_{ALLOW}_ _{CREDIT}_</label>
  <div class='col-md-2'>
    <input id='ALLOW_CREDIT' name='ALLOW_CREDIT' value='1' %ALLOW_CREDIT%  type='checkbox'>
  </div>
   </div>
    <div class='form-group'>
  <label class='control-label col-md-6' for='DISABLE_PAYSYS'>_{DISABLE}_ PAYSYS</label>
  <div class='col-md-2'>
    <input id='DISABLE_PAYSYS' name='DISABLE_PAYSYS' value='1' %DISABLE_PAYSYS%  type='checkbox'>
  </div>
   </div>
    <div class='form-group'>
  <label class='control-label col-md-6' for='DISABLE_CHG_TP'>_{DISABLE}__{USER_CHG_TP}_:</label>
  <div class='col-md-2'>
    <input id='DISABLE_CHG_TP' name='DISABLE_CHG_TP' value='1' %DISABLE_CHG_TP%  type='checkbox'>
  </div>
   </div>
    <div class='form-group'>
  <label class='control-label col-md-6' for='SEPARATE_DOCS'>_{SEPARATE_DOCS}_:</label>
  <div class='col-md-2'>
    <input id='SEPARATE_DOCS' name='SEPARATE_DOCS' value='1' %SEPARATE_DOCS%  type='checkbox'>
  </div>
   </div>


  </div>
  <div class='panel-footer'><div class='form-group'>
  <div class='col-sm-offset-2 col-sm-8'>
    <input type='submit' name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
  </div>
</div></div>
</div>
   </fieldset>
<!--
<TABLE class=form>
<TR><TH colspan=2 class=form_title>_{GROUPS}_</TH></TR>
<TR><TD>GID:</TD><TD><input type='text' name='GID' value='%GID%'/></TD></TR>
<TR><TD>_{NAME}_:</TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>_{DESCRIBE}_:</TD><TD><input type='text' name='DESCR' value='%DESCR%'></TD></TR>
<TR><TD>_{ALLOW}_ _{CREDIT}_</TD><TD><input type='checkbox' name='ALLOW_CREDIT' value='1' %ALLOW_CREDIT%></TD></TR>
<TR><TD>_{DISABLE}_ PAYSYS</TD><TD><input type='checkbox' name='DISABLE_PAYSYS' value='1' %DISABLE_PAYSYS%></TD></TR>
<TR><TD>_{DISABLE}_ _{USER_CHG_TP}_:</TD><TD><input type='checkbox' name='DISABLE_CHG_TP' value='1' %DISABLE_PAYSYS%></TD></TR>
<TR><TD>_{SEPARATE_DOCS}_:</TD><TD><input type='checkbox' name='SEPARATE_DOCS' value='1' %SEPARATE_DOCS%></TD></TR>

<TR><TH colspan=2 class=even><input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/></TH></TR>
</TABLE>
-->
</form>
