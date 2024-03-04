<form class='form-horizontal skip-pin'>
  <input type='hidden' name='no_addr' value='1'>
  <div id='checkAddress' class='modal fade' role='dialog'>
    <div class='modal-dialog'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h4 class='modal-title'>_{CHECK_ADDRESS}_</h4>
          <button type='button' class='close' data-dismiss='modal'>&times;</button>
        </div>
        <div class='modal-body'>
          <div class='callout callout-info'>_{CHECK_ADDRESS_MESAGE}_</div>
          %ADDRESS%
        </div>
        <div class='modal-footer'>
          <input type='submit' name='check_address' class='btn btn-primary' id='modal_submit' value='_{CONTINUE}_'>
        </div>
      </div>
    </div>
  </div>
</form>