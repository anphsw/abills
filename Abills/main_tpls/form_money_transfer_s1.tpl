<form action=%SELF_URL% method=post>
  <input type=hidden name=index value=%index%>
  <input type=hidden name=UID value='%UID%'>
  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{MONEY_TRANSFER}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='RECIPIENT'>_{TO_USER}_ (UID):</label>
        <div class='col-md-4'><input type=text id='RECIPIENT' name=RECIPIENT value='%RECIPIENT%' class='form-control' required> </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='SUM'>_{SUM}_:</label>
        <div class='col-md-4'><input type=text name=SUM value='%SUM%' id='SUM' class='form-control' required> </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-4'>
          <textarea class='form-control' rows='3' id="COMMENTS" name='COMMENTS' value='%COMMENTS%' maxlength='70' >%COMMENT%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name=s2 value='_{SEND}_' class='btn btn-primary'>
    </div>
  </div>

</form>
 