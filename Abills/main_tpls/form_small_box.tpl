<div class='modal fade' id='changeCreditModal' data-open='%OPEN_CREDIT_MODAL%'>
  <div class='modal-dialog modal-sm'>
    <form action=$SELF_URL class='form form-horizontal text-center pswd-confirm' id='changeCreditForm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>&times;</span></button>
          <h4 class='modal-title text-center'>_{SET_CREDIT}_</h4>
        </div>
        <div class='modal-body' style='padding: 30px;'>
          <input type=hidden name='index' value='10'>
          <input type=hidden name='sid' value='$sid'>

          <div class='form-group'>
            <label class='col-md-7'>_{CREDIT_SUM}_: </label>
            <label class='col-md-3'> %CREDIT_SUM%</label>
          </div>
          <div class='form-group'>
            <label class='col-md-7'>_{CREDIT_PRICE}_:</label>
            <label class='col-md-3'>%CREDIT_CHG_PRICE%</label>
          </div>
          <div class='form-group'>
            <label class='col-md-7'>_{ACCEPT}_:</label>

            <div class='col-md-3'>
              <input type='checkbox' required='required' value='%CREDIT_SUM%' name='change_credit'>
            </div>
          </div>
        </div>
        <div class='modal-footer'>
          <input type=submit class='btn btn-primary' value='_{SET}_' name='set'>
        </div>
      </div>
    </form>
  </div>
</div>
<!-- /.modal -->

<div class="callout callout-danger">
    <h4>Статус: Слишком маленький депозит</h4>
    <h5>Установить кредит?</h5>
    <label>
        <input type="checkbox"> Подтвердить
    </label>
    <button type="submit" class="btn btn-primary" name='hold_up_window' data-toggle='modal' data-target='#changeCreditModal'>ДА !</button>
</div>
