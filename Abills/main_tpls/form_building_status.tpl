<form action='%SELF_URL%' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>_{TYPE}_</div>

    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IS_DEFAULT'>_{DEFAULT}_:</label>
        <div class='col-md-8 p-2'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='IS_DEFAULT' name='IS_DEFAULT' %IS_DEFAULT%
                   value='1'>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
