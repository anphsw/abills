<form method='post' action='%SELF_URL%'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='del_accountability' value='1'>

  <div class='card card-primary card-outline box-form form-horizontal'>
    <div class='card-header'><h4 class='card-title'>_{RETURN_STORAGE}_</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{STORAGE}_</label>
        <div class='col-md-9'>%STORAGE_SELECT%</div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='confirm' value='_{APPLY}_'>
    </div>
  </div>
</form>
