<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{SETTINGS}_</h4></div>
  <div class='box-body'>

    <form name='API' id='form_API' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='%SUBMIT_BTN_VALUE%'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='API_ID'>API</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%API_ID%' name='API_ID' id='API_ID'/>
        </div>
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='KKT_GROUP'>KKT _{GROUP}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%KKT_GROUP%' name='KKT_GROUP' id='KKT_GROUP'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='METHODS'>_{PAYMENT_METHOD}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%METHODS%' name='METHODS' id='METHODS'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='GROUPS'>_{GROUPS}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%GROUPS%' name='GROUPS' id='GROUPS'/>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_API' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>