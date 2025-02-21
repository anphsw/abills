<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{ACTION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' class='form-control' type='text' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %SELECT_PRIORITY%
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-4 control-label' for='COLOR'>_{COLOR}_:</label>
        <div class="col-md-8">
          <div class="input-group">
            <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DSC'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea rows='5' name='COMMENTS' id='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>


    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>