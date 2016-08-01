
<input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%' ID='DISTRICT_ID'>
<input type='hidden' name='STREET_ID' value='%STREET_ID%' ID='STREET_ID'>
<input type='hidden' name='LOCATION_ID' value='%LOCATION_ID%' ID='LOCATION_ID'>

<div class='form-group'>
  <!-- <label class='col-sm-offset-2 col-sm-8'>_{ADDRESS}_</label> -->

  <label class='control-label col-md-2' for='DISTRICT'>_{DISTRICTS}_</label>

  <div class='col-md-9'>
    <select data-download-on-click='1' name='ADDRESS_DISTRICT' id='DISTRICT' class='form-control'>
      <option value='%DISTRICT_ID%' selected>%ADDRESS_DISTRICT%</option>
    </select>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-2' for='STREET'>_{ADDRESS_STREET}_</label>
  <div class='col-md-9'>
    <select data-download-on-click='1' name='ADDRESS_STREET' id='STREET' class='form-control'>
      <option value='%STREET_ID%' selected>%ADDRESS_STREET%</option>
    </select>
  </div>
</div>


<div class='form-group'>
  <label class='control-label col-md-2' for='BUILD'>_{ADDRESS_BUILD}_</label>

  <div class='col-md-4'>
    <select data-download-on-click='1' name='ADDRESS_BUILD' id='BUILD' class='form-control'>
      <option value='%ADDRESS_BUILD%' selected>%ADDRESS_BUILD%</option>
    </select>
  </div>

  <label class='control-label col-md-2  pull-left ' for='FLAT'>_{ADDRESS_FLAT}_</label>

  <div class='col-md-3' id='flatDiv'>
    <input type=text name=ADDRESS_FLAT id='FLAT' value='%ADDRESS_FLAT%' class='form-control'>
  </div>
</div>

<script src='/styles/default_adm/js/searchLocation.js'></script>

<script>
  document['FLAT_CHECK_FREE']     = '%FLAT_CHECK_FREE%'     || false;
  document['FLAT_CHECK_OCCUPIED'] = '%FLAT_CHECK_OCCUPIED%' || false;
</script>