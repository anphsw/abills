<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{CRM_CONNECT_PHONE_NUMBER}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NUMBER'>_{CRM_PHONE_NUMBER}_:</label>
        <div class='col-md-8'>
          <input id='NUMBER' name='NUMBER' value='%NUMBER%' class='form-control' required type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TOKEN'>_{CRM_API_KEY}_:</label>
        <div class='col-md-8'>
          <input id='TOKEN' name='TOKEN' value='%TOKEN%' class='form-control' required type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea name='COMMENTS' id='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>