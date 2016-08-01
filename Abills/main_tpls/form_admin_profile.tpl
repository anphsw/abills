<form action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='AWEB_OPTIONS' value='1'/>

  <div class='panel panel-primary panel-form'>
    <div class='panel-heading'><h4>_{PROFILE}_</h4></div>
    <div class='panel-body'>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{LANGUAGE}_:</label>

        <div class='col-md-9'>
          %SEL_LANGUAGE%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-4'>_{REFRESH}_ (sec.):</label>

        <div class='col-md-3'>
          <input type='text' name='REFRESH' value='$REFRESH' class='form-control'/>
        </div>
        <label class='control-label col-md-2'>_{ROWS}_:</label>

        <div class='col-md-3'>
          <input type='text' name='PAGE_ROWS' value='$PAGE_ROWS' class='form-control'/>
        </div>
      </div>

      <div class='form-group'>
        <legend>_{EVENTS}_</legend>
      </div>

      <div class='form-group'>
        <div class='col-md-6'>
          <label class='control-label col-md-9'>_{DISABLE}_:</label>

          <div class='col-md-3'>
            <input type='checkbox' data-return='1' name='NO_EVENT' value='1' %NO_EVENT%/>
          </div>
        </div>
        <div class='col-md-6'>
          <label class='control-label col-md-9'>_{DISABLE}_ _{SOUND}_:</label>

          <div class='col-md-3'>
            <input type='checkbox' data-return='1' name='NO_EVENT_SOUND' value='1' %NO_EVENT_SOUND%/>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 %EVENTS_GROUPS_HIDDEN%' for='GROUP'>_{GROUP}_</label>
        <div class='col-md-9'>
          %EVENT_GROUPS_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <legend>_{COLOR}_</legend>
      </div>


      <div class='form-group'>
        <label for='COLORS' class='control-label col-md-3'>_{COLOR}_</label>
        <div class='col-md-9'>
          %COLORS_CSS%
        </div>
      </div>

      <div class='form-group'>
        <div class='col-md-1'></div>
        <div class='col-md-8'>
          <input type=text name='img_css' id='image_css' placeholder='Enter URL to image to create style from'
                 class='form-control'>
        </div>
        <div class='col-md-3'>
          <input type=submit name=apply_css value='_{CREATE}_' class='btn btn-default'>
        </div>
      </div>
    </div>

    <div class='panel-footer text-center'>
      <input type='submit' name='set' value='_{SET}_' class='btn btn-primary'/>
    </div>
  </div>


  %QUICK_REPORTS%


  <input type='submit' name='set' value='_{SET}_' class='btn btn-primary'/>
  <input type='submit' name='default' value='_{DEFAULT}_' class='btn btn-default'/>
</form>