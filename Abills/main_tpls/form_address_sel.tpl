

<input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%' ID='DISTRICT_ID'>
<input type='hidden' name='STREET_ID' value='%STREET_ID%' ID='STREET_ID'>
<input type='hidden' name='LOCATION_ID' value='%LOCATION_ID%' ID='LOCATION_ID'>

<div class='form-group'>

  <label class='control-label col-md-2' for='DISTRICT'>_{DISTRICTS}_</label>

  <div class='col-md-10'>
    <select data-download-on-click='1' name='ADDRESS_DISTRICT' id='DISTRICT' class='form-control'>
      <option value='%DISTRICT_ID%' selected>%ADDRESS_DISTRICT%</option>
    </select>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-2' for='STREET'>_{ADDRESS_STREET}_</label>

  <div class='col-md-10'>
    <select data-download-on-click='1' name='ADDRESS_STREET' id='STREET' class='form-control'>
      <option value='%STREET_ID%' selected>%ADDRESS_STREET%</option>
    </select>
  </div>
  %ADDRESS_STREET2%
</div>

<div class='form-group'>
  <label class='control-label col-md-2' for='BUILD'>_{ADDRESS_BUILD}_</label>

  <div class='col-md-4 changeBuildMenu'>

    <div class='input-group'>
      <select data-download-on-click='1' name='ADDRESS_BUILD' id='BUILD' class='form-control'>
        <option value='%ADDRESS_BUILD%' selected>%ADDRESS_BUILD%</option>
      </select>

      <span class='input-group-addon'>
        <a id='addBuildInput' title='_{ADD}_ _{BUILDS}_'>
            <span class='glyphicon glyphicon-plus'></span>
        </a>
      </span>
    </div>
  </div>

  <div class='col-md-4 addBuildMenu' style='display:none;'>
    <span class='input-group-addon'>
    <input type='text' name='ADD_ADDRESS_BUILD' class='form-control'/>
        <a id='changeBuildInput'>
            <span class='glyphicon glyphicon-plus'></span>
        </a>
    </span>
  </div>
  <div id='flatDiv'>
    <label class='control-label col-md-2' for='ADDRESS_FLAT'>_{ADDRESS_FLAT}_</label>

    <div class='col-md-3'>
      <input type=text name=ADDRESS_FLAT id='ADDRESS_FLAT' value='%ADDRESS_FLAT%' class='form-control'>
    </div>
  </div>
</div>

<div class='form-group' id='addressButtonsDiv'>
  <div class='col-md-12'>
    <label class='label label-primary'>
      %MAP_BTN%
      <a href='$SELF_URL?get_index=form_districts&full=1&header=1' class='btn btn-default btn-xs'>_{ADD}_
        _{ADDRESS}_</a>
      %ADD_ADDRESS_LINK%
    </label>
  </div>
</div>

<script src='/styles/default_adm/js/searchLocation.js'></script>

<script>
  document['FLAT_CHECK_FREE']     = '%FLAT_CHECK_FREE%'     || true;
  document['FLAT_CHECK_OCCUPIED'] = '%FLAT_CHECK_OCCUPIED%' || false;

  jQuery('#addBuildInput').click(function (e) {
    e.preventDefault();
    jQuery('.addBuildMenu').show();
    jQuery('.changeBuildMenu').hide();
  });
  jQuery('#changeBuildInput').click(function (e) {
    e.preventDefault();
    jQuery('.addBuildMenu').hide();
    jQuery('.changeBuildMenu').show();
  });
</script>
