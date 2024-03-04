<div class='form-address'>
  <input type='hidden' name='LOCATION_ID' id='LOCATION_ID_REG' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-xs-3 col-md-2 LABEL-DISTRICT'>_{DISTRICTS}_</label>
    <div class='col-xs-9 col-md-10'>
      %ADDRESS_DISTRICT%
    </div>
  </div>
  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-xs-3 col-md-2 LABEL-STREET'>_{ADDRESS_STREET}_</label>
    <div class='col-xs-9 col-md-10' id='registration_streets'>
      %ADDRESS_STREET%
    </div>
  </div>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-xs-3 col-md-2 LABEL-BUILD'>_{ADDRESS_BUILD}_</label>
    <div id='registration_builds' class='col-xs-9 col-md-10'>
      %ADDRESS_BUILD%
    </div>
  </div>

</div>

<script>
  document.addEventListener('district-change-%DISTRICT_ID%', function(event) {
    GetStreets(event.detail.district);
  }, { passive: true });

  function GetStreets(data) {
    let street_id = data.data('street-id') || '%STREET_ID%';
    let street = jQuery(`#${street_id}`);
    street.attr('disabled', 'disabled');

    let district_id = jQuery(data).val();
    district_id = district_id ? district_id : '_SHOW';

    fetch(`/api.cgi/streets?DISTRICT_ID=${district_id}&DISTRICT_NAME=_SHOW&PAGE_ROWS=1000000&SORT=street_name`, {
      mode: 'cors',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
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

  function GetBuilds(data) {
    let build = jQuery('#%BUILD_ID%');
    build.attr('disabled', 'disabled');
    let street_id = jQuery(data).val();
    if (Array.isArray(street_id) && street_id.length > 1) street_id = street_id.join(';');

    if (!street_id || street_id == 0) {
      street_id = 0;
      jQuery('#ADD_LOCATION_ID').attr('value', '');
    }

    fetch(`/api.cgi/builds?STREET_ID=${street_id}&STREET_NAME=_SHOW&PAGE_ROWS=1000000`, {
      mode: 'cors',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
    })
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        build.html('');
        if (data.length < 1) return 1;

        feelOptionGroup(build, data, 'streetId', 'streetName', 'number');

        let feel_options = build.find('option[value!=""]').length;
        if (feel_options > 0) initChosen();
        build.removeAttr('disabled');
      });
  }

  function GetLoc() {}

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
