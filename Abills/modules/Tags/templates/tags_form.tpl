<form action='$SELF_URL' method='post' class='form-horizontal'>
  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <h4 class='box-title'>_{TAGS}_</h4>
    </div>
    <div class='box-body'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='$FORM{chg}'/>
      <fieldset>
        <div class='form-group'>
          <label for='NAME' class='control-label col-md-4 col-sm-3'>_{NAME}_:</label>
          <div class='col-md-8 col-sm-9'>
            <input type='text' class='form-control' id='NAME' name='NAME' value='%NAME%'/>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-4 col-sm-3'>_{PRIORITY}_:</label>
          <div class='col-md-8 col-sm-9'>
            %PRIORITY_SEL%
          </div>
        </div>
        <div class='form-group'>
          <label class='control-label col-md-4 col-sm3'>_{RESPONSIBLE}_:</label>
          <div class='col-md-8 col-sm-9'>
            %RESPONSIBLE%
          </div>
        </div>
        <div class='form-group'>
          <label for='COMMENTS' class='control-label col-md-4 col-sm-3'>_{COMMENTS}_:</label>
          <div class='col-md-8 col-sm-9'>
            <textarea rows=4 id='COMMENTS' name=COMMENTS class='form-control'>%COMMENTS%</textarea>
          </div>
        </div>
      </fieldset>

    </div>
    <div class='box-footer'>
      <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
    </div>
  </div>
</form>