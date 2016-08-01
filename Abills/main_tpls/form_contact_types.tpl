<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>_{CONTACTS}_ _{TYPES}_</h4></div>
  <div class='panel-body'>

    <form name='contact_types' id='form_contact_types' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%CHANGE_ID%' value='%ID%'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='checkbox'>
        <label>
          <input type='checkbox' name='IS_DEFAULT' %IS_DEFAULT_CHECKED% data-return='1' value='1' id='IS_DEFAULT_id'/>
          <strong>_{DEFAULT}_</strong>
        </label>
      </div>
    </form>

  </div>
  <div class='panel-footer text-center'>
    <input type='submit' form='form_contact_types' class='btn btn-primary' name='%SUBMIT_BTN_ACTION%'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

