<form class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='$FORM{chg}'/>

  <div class="card card-primary card-outline container-md">
    <div class="card-header with-border">
      <h3 class="card-title">_{NAS}_ - _{GROUPS}_</h3>
    </div>
    <div class="card-body">
      <div class='form-group row'>
        <label  class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_</label>
        <div class='col-md-8'>
          <input id='NAME' value='%NAME%' name='NAME' placeholder='%NAME%' class='form-control ' type='text' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLED'>_{DISABLED}_:</label>
        <div class='col-md-8 p-2'>
          <div class='form-check'>
            <input id='DISABLE' value='1' name='DISABLE' class='form-check-input' type='checkbox' %DISABLE%>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label  class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-8'>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

      <div class='card-footer'>
          <input type='submit' class='btn btn-primary btn-sm float-right' name='%ACTION%' value='%LNG_ACTION%'>
      </div>
    </div>
  </div>
</form>
