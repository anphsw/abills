<form name='CABLECAT_SPLITTER' id='form_CABLECAT_SPLITTER' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{SPLITTER}_:</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{SPLITTER_TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='WELL_ID'>_{WELL}_:</label>
        <div class='col-md-8'>
          %WELL_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMUTATION_ID'>_{COMMUTATION}_:</label>
        <div class='col-md-8'>
          %COMMUTATION_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='COLOR_SCHEME_ID_SELECT'>_{COLOR_SCHEME}_:</label>
        <div class='col-md-8'>
          %COLOR_SCHEME_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ATTENUATION'>_{ATTENUATION}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' id="ATTENUATION" name='ATTENUATION'
                 value='%ATTENUATION%' pattern="^[0-9]{1,2}(\/[0-9]{1,2}){1,}"/>
        </div>
      </div>

      %OBJECT_INFO%

    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_SPLITTER' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>