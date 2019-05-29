<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='box box-form box-primary form-horizontal'>
    <div class='box-header with-border'>
      <h4 class='box-title table-caption'>_{ADD_CASHBOX}_</h4>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' placeholder='_{TYPE_IN_CASHBOX_NAME}_'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>
  </div>

</form>