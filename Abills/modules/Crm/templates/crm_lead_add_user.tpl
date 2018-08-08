<form action='$SELF_URL' id='storage_installation_form' name='storage_installation_name' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='LEAD_ID' value='%LEAD_ID%'/>
  <!--
      <input type=hidden name=STREET_ID value='%STREET_ID%' ID='STREET_ID'>
      <input type=hidden name=LOCATION_ID value='%LOCATION_ID%' ID='LOCATION_ID'>
      <input type=hidden name=DISTRICT_ID value='%DISTRICT_ID%' ID='DISTRICT_ID'>
      -->

  <div class='box box-theme box-form'>
    <div class='box-header with-title'>
      <h4>_{ADD}_ _{USER}_</h4>
    </div>
    <div class='box-body form'>

      <div class='form-group'>
        <label class='col-md-3 control-label' for='LOGIN'>_{USER}_:</label>
        <div class='col-md-9'>
          <input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
          <div class='col-md-10'>
            <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN' readonly='readonly'/>
          </div>
          <div class='col-md-2'>
            %USER_SEARCH%
          </div>
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input type=submit name=add_uid value='_{ADD}_' class='btn btn-primary'>
    </div>
  </div>

</form>
