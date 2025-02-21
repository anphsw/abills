<form action='%SELF_URL%' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{AUTO_COORDS}_</h4></div>
    <div class='card-body'>
      <div class='form-address'>
        <input type='hidden' name='LOCATION_ID' id='ADD_LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

        %DISTRICTS_SELECT%

        <div class='form-group row' style='%EXT_SEL_STYLE%'>
          <label class='col-md-4 col-form-label text-md-right LABEL-DISTRICT'>_{STREETS}_</label>
          <div class='col-md-8'>
            %STREETS_SELECT%
          </div>
        </div>

      </div>
    </div>
    <div class='card-footer'>
      <input id='GMA_EXECUTE_BTN' type=submit name=discovery value='_{START}_' class='btn btn-primary'>
    </div>
  </div>
</form>

<script>

  const NOT_FOUND       = '_{COORDS_NOT_FOUND}_' || 'Not found';
  const SUCCESS         = '_{SUCCESS}_' || 'Success';
  const SEVERAL_RESULTS = '_{SEVERAL_RESULTS}_' || 'Several results';

  const streetId = jQuery('#STREET_ID');

  document.addEventListener('district-change-DISTRICT_SEL', function(event) {
    GetStreets(event.detail.district);
  });

  function GetStreets(data) {
    let street = streetId;
    street.attr('disabled', 'disabled');

    let district_id = jQuery(data).val();
    district_id = district_id ? district_id : '_SHOW';

    fetch(`/api.cgi/streets?DISTRICT_ID=${district_id}&DISTRICT_NAME=_SHOW&PAGE_ROWS=1000000`, {
      mode: 'cors',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
    })
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        street.html('');

        if (data.length < 1) return 1;

        feelOptionGroup(street, data, 'districtId', 'districtName', 'streetName');

        let feel_options = street.find('option[value!=""]').length;
        if (feel_options > 0) initChosen();
        if (!jQuery(data).prop('multiple') && feel_options > 0) street.focus().select2('open');
        street.removeAttr('disabled');
      });
  }

  function feelOptionGroup (select, data, groupKey, groupLabel, optionName) {
    let default_option = jQuery('<option></option>', {value: '', text: '--'});
    select.append(default_option);

    let optgroups = {};
    data.forEach(address => {
      if (!optgroups[address[groupKey]]) {
        optgroups[address[groupKey]] = jQuery(`<optgroup label='== ${address[groupLabel]} =='></optgroup>`);
      }

      let option = jQuery('<option></option>', {value: address.id, text: address[optionName]});
      optgroups[address[groupKey]].append(option);
    });

    jQuery.each(optgroups, function(key, value) { select.append(value);});
  }
</script>

<script src='/styles/default/js/maps/location-search.js'></script>