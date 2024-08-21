<form method='post' action='%SELF_URL%' accept-charset='utf-8'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border text-center pb-0'>
      <h4>_{CANCEL_RECURRENT_PAYMENT}_</h4>
    </div>
    <div class='box-body'>
      <div class='form-group'>
        <div class='font-weight-bold text-center col-md-12 form-control-label'>
          <br>
          <label> _{UNSUBSCRIBE}_ %MODULE% </label>
          <br>
          <label>Сума %SUM% наступна дата списання %DATE%</label>
        </div>
      </div>
    </div>
    <div class='box-footer text-center'>
      <a class='btn btn-primary btn center mb-2' role='button' aria-disabled='true' href='%SELF_URL%?%UNSUBSCRIBE_URL%'
         name='cancel_delete'>_{HANGUP}_
      </a>
    </div>
  </div>
</form>
