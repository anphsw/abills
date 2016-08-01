<form action=$SELF_URL name='depot_form_types' method=POST class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>


<div class='panel panel-primary panel-form'>
<div class='panel-heading'>%TITLE_NAME%</div>
<div class='panel-body'>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{NAME}_:</label>
    <div class='col-md-9'>
      <input class='form-control' name='NAME' type='text' value='%NAME%'/>
    </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'>URL:</label>
    <div class='col-md-9'>
      <input class='form-control' name='URL' type='text' value='%URL%'/>
    </div>
  </div>

  <div class='form-group'>
      <label class='col-md-3 control-label'>_{MENU}_:</label>
    <div class='col-md-9'>
        <input type='radio' name='STATUS' value=1 %SHOWED%>_{SHOW}_
      <br />
        <input type='radio' name='STATUS' value=0 %HIDDEN%>_{HIDE}_
    </div>
  </div>
</div>
<div class='panel-footer'>
<input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
</div>

</div>
</form>
