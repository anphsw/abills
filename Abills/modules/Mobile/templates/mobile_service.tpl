<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{MOBILE_SERVICES}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='CATEGORY_ID'>_{MOBILE_CATEGORIES}_:</label>
        <div class='col-md-8'>
          %CATEGORIES_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' required class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESCRIPTION'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='DESCRIPTION' id='DESCRIPTION'>%DESCRIPTION%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='USER_DESCRIPTION'>_{DESCRIBE_FOR_SUBSCRIBER}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='USER_DESCRIPTION' id='USER_DESCRIPTION'>%USER_DESCRIPTION%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRICE'>_{PRICE}_:</label>
        <div class='col-md-8'>
          <input id='PRICE' name='PRICE' value='%PRICE%' class='form-control' type='number' step='0.01' placeholder='0.00'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %PRIORITY_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FILTER_ID'>Filter Id:</label>
        <div class='col-md-8'>
          <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MANDATORY'>_{MOBILE_MANDATORY}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='MANDATORY' name='MANDATORY' %MANDATORY% value='1'>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>