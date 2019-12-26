<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{SETTINGS}_</h4></div>
  <div class='box-body'>

    <form name='API' id='form_API' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='%SUBMIT_BTN_VALUE%'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='API_NAME'>API</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%API_NAME%' name='API_NAME' id='API_NAME'/>
        </div>
      </div>
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%LOGIN%' name='LOGIN' id='LOGIN'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PASSWORD'>_{PASSWD}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%PASSWORD%' name='PASSWORD' id='PASSWORD'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='URL'>URL</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%URL%' name='URL' id='URL'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CALLBACK'>Callback url</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%CALLBACK%' name='CALLBACK' id='CALLBACK'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='INN'>INN</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%INN%' name='INN' id='INN'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='ADDRESS'>_{ADDRESS}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%ADDRESS%' name='ADDRESS' id='ADDRESS'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='EMAIL'>EMAIL</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%EMAIL%' name='EMAIL' id='EMAIL'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='GOODS_NAME'>_{ARTICLE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%GOODS_NAME%' name='GOODS_NAME' id='GOODS_NAME'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='AUTHOR'>_{ADMIN}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%AUTHOR%' name='AUTHOR' id='AUTHOR'/>
        </div>
      </div>
    </form>

  </div>
  <div class='box-footer'>
    <input type='submit' form='form_API' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>