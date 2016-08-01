<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>$lang{EVENTS} $lang{GROUP}</h4></div>
  <div class='panel-body'>

    <form name='EVENTS_GROUP' id='form_EVENTS_GROUP' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>$lang{NAME}</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

    <div class='row'>%MODULE_CHECKBOXES%</div>

    </form>
  </div>
  <div class='panel-footer text-center'>
    <input type='submit' form='form_EVENTS_GROUP' class='btn btn-primary' name='%SUBMIT_BTN_ACTION%'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>


