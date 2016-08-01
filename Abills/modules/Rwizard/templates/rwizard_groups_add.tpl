<form action='$SELF_URL' class='form-horizontal'>
<input type='hidden' name='index' value=$index>
<input type='hidden' name='action' value=%ACTION%>
<input type='hidden' name='id' value=%ID%>

  <div class='panel panel-form panel-primary'>
    <div class='panel-heading'>_{GROUPS}_</div>
    <div class='panel-body'>
      <div class='form-group'>
        <label class='control-element col-md-3'>_{GROUP}_</label>
        <div class='col-md-9'>
          <input class='form-control' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='control-element col-md-3'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='panel-footer'>
      <button type='submit' class='btn btn-primary'>%BUTTON%</button>
    </div>
  </div>

</form>