<form action=$SELF_URL class='form-horizontal'>
  <input type=hidden name=index value=$index>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'><h4 class='box-title'>_{AUTO_COORDS}_</h4></div>
    <div class='box-body'>
      <div class='form-address'>
        <input type='hidden' name='LOCATION_ID' id='ADD_LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

        <div class='form-group' style='%EXT_SEL_STYLE%'>
          <label class='control-label col-sm-3 col-md-4 LABEL-DISTRICT'>_{DISTRICTS}_</label>
          <div class='col-sm-9 col-md-8'>
            %DISTRICTS_SELECT%
          </div>
        </div>

        <div class='form-group' style='%EXT_SEL_STYLE%'>
          <label class='control-label col-sm-3 col-md-4 LABEL-DISTRICT'>_{STREETS}_</label>
          <div class='col-sm-9 col-md-8'>
            %STREETS_SELECT%
          </div>
        </div>

      </div>
    </div>
    <div class='box-footer'>
      <input id='GMA_EXECUTE_BTN' type=submit name=discovery value='_{START}_' class='btn btn-primary'>
    </div>
  </div>
</form>

<script>

  const NOT_FOUND       = '_{COORDS_NOT_FOUND}_' || 'Not found';
  const SUCCESS         = '_{SUCCESS}_' || 'Success';
  const SEVERAL_RESULTS = '_{SEVERAL_RESULTS}_' || 'Several results';

  const streetId = jQuery('#STREET_ID');

  function GetStreets(data) {
    const districtId = jQuery("#" + data.id).val();
    jQuery.post('$SELF_URL', getUrl(districtId ? districtId : '_SHOW'), function (result) {
      streetId.html(result);
      streetId.focus();
      streetId.select2('open');
    });
  }

  function getUrl(districtId) {
    return '%QINDEX%header=2&get_index=form_address_select2&DISTRICT_ID=' + districtId
    + '&STREET=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%';
  }
</script>

<script src='/styles/default_adm/js/maps/location-search.js'></script>