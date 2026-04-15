<form action=%SELF_URL% METHOD=POST>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='chg' value='%chg%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border text-primary'>_{TEST}_</div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='NUMBER'>_{PHONE}_ _{NUMBER}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' id='NUMBER'  name='NUMBER' value='%NUMBER%' placeholder='380000000000' required>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <button type='submit' class='btn btn-primary' id="test_sent">_{SEND}_</button>
    </div>
  </div>
</form>