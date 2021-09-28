<div class='form-address'>
  <input type='hidden' name='LOCATION_ID' id='ADD_LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-DISTRICT'>_{DISTRICTS}_:</label>
    <div class='col-sm-9 col-md-8'>
      %ADDRESS_DISTRICT%
    </div>
  </div>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-STREET'>_{ADDRESS_STREET}_:</label>
    <div class='col-sm-9 col-md-8'>
      %ADDRESS_STREET%
    </div>
  </div>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-BUILD'>_{ADDRESS_BUILD}_:</label>
    <div class='col-sm-9 col-md-8'>
      <div class='addBuildMenu'>
        %ADDRESS_BUILD%
      </div>

      <div class='input-group changeBuildMenu' style='display : none;'>
        <input type='text' id='ADD_ADDRESS_BUILD_ID' name='ADD_ADDRESS_BUILD' class='form-control INPUT-ADD-BUILD'/>
        <div class='input-group-append'>
          <div class='input-group-text'>
            <a class='BUTTON-ENABLE-SEL'>
              <span class='fa fa-list'></span>
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right'>_{ADDRESS_FLAT}_:</label>
    <div class='col-sm-9 col-md-8'>
      <input type='text' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%' class='form-control INPUT-FLAT'>
    </div>
  </div>

  %EXT_ADDRESS%

  <div class='pull-right'>
    %ADDRESS_ADD_BUTTONS%
    %MAP_BTN%
    %DOM_BTN%
    <span id='map_add_btn' style='display: none'>%MAPS2_BTN%</span>
  </div>
</div>

<script>
  document['FLAT_CHECK_FREE']     = '%FLAT_CHECK_FREE%' || "1";
  document['FLAT_CHECK_OCCUPIED'] = '%FLAT_CHECK_OCCUPIED%' || "0";
</script>
<script>
  jQuery(function () {
    jQuery(document).on('keypress', 'span.select2', function (e) {
      if (e.originalEvent) jQuery(this).siblings('select').select2('open');
    });
  });

  let objectToShow = [];

  function GetStreets(data) {
    var distrId = jQuery("#" + data.id).val();
    distrId = distrId ? distrId : '_SHOW';
    jQuery.post('$SELF_URL', '%QINDEX%header=2&get_index=form_address_select2&DISTRICT_ID=' + distrId
      + '&STREET=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%', function (result) {
      jQuery('#%STREET_ID%').html(result);
      initChosen();
      jQuery("#%STREET_ID%").focus();
      jQuery("#%STREET_ID%").select2('open');
    });
  }

  function GetBuilds(data) {
    var strId = jQuery("#" + data.id).val();
    if (Array.isArray(strId) && strId.length > 1) strId = strId.join(';');

    if (!strId || strId == 0) {
      strId = 0;
      jQuery('#ADD_LOCATION_ID').attr('value', '');
    }

    jQuery.post('$SELF_URL',
      `%QINDEX%header=2&get_index=form_address_select2&STREET_ID=${strId}&BUILD=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%`,
      function (result) {
        jQuery('#%BUILD_ID%').html(result);
        initChosen();
        jQuery("#%BUILD_ID%").focus();
        jQuery("#%BUILD_ID%").select2('open');

        activateBuildButtons();
      });
  }
  //Get location_id after change build
  var item = '';
  function GetLoc(data) {
    item = jQuery("#" + data.id).val();

    if (item == '--') {
      item = '';
    }

    if (%MAPS2_SHOW_OBJECTS%) {
      if (item && item !== '0') {
        jQuery('#map_add_btn').fadeIn(300);
        objectToShow = [];
        getObjectToMap();
      } else
        jQuery('#map_add_btn').fadeOut(200);
    }

    jQuery('#ADD_LOCATION_ID').attr('value', item);
    setTimeout(function () {
      jQuery('.INPUT-FLAT').focus();
    }, 100);
  }

  let selected_builds = jQuery('#ADD_LOCATION_ID').attr('value');
  if (selected_builds && !item && %MAPS2_SHOW_OBJECTS%){
    item = selected_builds;
    jQuery('#map_add_btn').fadeIn(300);
    getObjectToMap();
  }

  function getObjectId (){
    return {
      OBJECTS   : objectToShow,
      OBJECT_ID : item
    };
  }

  function getObjectToMap() {
    let url = '$SELF_URL?header=2&get_index=maps2_show_map&RETURN_HASH_OBJECT=1';
    fetch(url + '&OBJECT_ID=' + item)
      .then(function (response) {
        if (!response.ok)
          throw Error(response.statusText);

        return response;
      })
      .then(function (response) {
        return response.json();
      })
      .then(result => async function (result) {
        objectToShow = result;
      }(result));
  }

  function activateBuildButtons() {
    //Changing select to input
    jQuery('.BUTTON-ENABLE-ADD').on('click', function () {
      let buildDiv = jQuery('.addBuildMenu');
      buildDiv.removeClass('d-block');
      buildDiv.addClass('d-none');

      jQuery('.changeBuildMenu').show();
      jQuery('#map_add_btn').fadeOut(300);
    });

    //Changing input to select
    jQuery('.BUTTON-ENABLE-SEL').on('click', function () {
      let buildDiv = jQuery('.addBuildMenu');
      buildDiv.removeClass('d-none');
      buildDiv.addClass('d-block');

      jQuery('.changeBuildMenu').hide();
    })
  }

  activateBuildButtons();

</script>
