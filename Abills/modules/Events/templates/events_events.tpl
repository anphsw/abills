<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>_{EVENTS}_</h4></div>
  <div class='panel-body'>

    <form name='EVENTS_EVENTS' id='form_EVENTS_EVENTS' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='MODULE'>MODULE</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' id='MODULE' name='MODULE' value='WEB' readonly/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='EXTRA'>_{EXTRA}_ URL</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' id='EXTRA' name='EXTRA' value='%EXTRA%'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STATE'>_{STATE}_</label>
        <div class='col-md-9'>
          %STATE_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PRIORITY'>_{PRIORITY}_</label>
        <div class='col-md-9'>
          %PRIORITY_SELECT%
        </div>
      </div>

<!--
      <div class='form-group'>
        <label class='control-label col-md-3' for='PRIVACY'>_{ACCESS}_</label>
        <div class='col-md-9'>
          %PRIVACY_SELECT%
        </div>
      </div>

      -->

      <div class='form-group'>
        <label class='control-label col-md-3' for='GROUP'>_{GROUP}_</label>
        <div class='col-md-9'>
          %GROUP_SELECT%
        </div>
      </div>

    </form>

  </div>
  <div class='panel-footer text-center'>
    <input type='submit' class='btn btn-primary' form='form_EVENTS_EVENTS' name='%SUBMIT_BTN_ACTION%'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

