<form action='$SELF_URL' METHOD=POST>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='box box-form box-primary form-horizontal'>
    <div class='box-header with-border'>
      <h4 class='box-title table-caption'>_{MOVING_BETWEEN_CASHBOXES}_</h4>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{SUM}_</label>
        <div class='col-md-9'>
          <input type='number' step='0.01' class='form-control' name='AMOUNT' value='%AMOUNT%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{CASHBOX}_</br>_{COMING}_</label>
        <div class='col-md-9'>
          %CASHBOX_SELECT_COMING%
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{CASHBOX}_</br>_{SPENDING}_</label>
        <div class='col-md-9'>
          %CASHBOX_SELECT_SPENDING%
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{MOVING}_ _{TYPE}_</label>
        <div class='col-md-9'>
          %MOVING_TYPE_SELECT%
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{DATE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control datepicker' name='DATE' value='%DATE%'>
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