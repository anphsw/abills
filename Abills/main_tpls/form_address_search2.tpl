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

      <div class='d-flex bd-highlight addBuildMenu'>
        <div class='flex-fill bd-highlight'>
          <div class='select'>
            <div class='input-group-append select2-append' id='%BUILD_ID%_'>
              %ADDRESS_BUILD%
            </div>
          </div>
        </div>
        <div class='bd-highlight'>
          <div class='input-group-append h-100'>
            <div class='input-group-text p-0 rounded-left-0'>
              <a title='_{ADD}_ _{BUILDS}_' class='BUTTON-ENABLE-ADD btn btn-sm text-blue'>
                <span class='fa fa-plus'></span>
              </a>
            </div>
          </div>
        </div>
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
      if (e.originalEvent) {
        jQuery(this).siblings('select').select2('open');
      }
    });
  });

  let objectToShow = [];

  function GetStreets%DISTRICT_ID%(data) {
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

  function GetBuilds%STREET_ID%(data) {
    const [formAddress] = jQuery(data).parents('.form-address');
    let [MULTI_BUILDS] = jQuery(formAddress).find('select#BUILD_ID.MULTI_BUILDS');

    MULTI_BUILDS = +!!MULTI_BUILDS;

    var strId = jQuery("#" + data.id).val();
    if (!strId || strId == 0) {
      strId = 0;
      jQuery('#ADD_LOCATION_ID').attr('value', '');
    }

    jQuery.post(
      '$SELF_URL',
      `%QINDEX%header=2&get_index=form_address_select2&MULTI_BUILDS=${MULTI_BUILDS}&STREET_ID=${strId}&BUILD=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%`,
      function (result) {
        jQuery('#%BUILD_ID%_').html(result);
        initChosen();
        jQuery("#%BUILD_ID%").focus();
        jQuery("#%BUILD_ID%").select2('open');
      });
  }
  //Get location_id after change build
  var item = '';
  function GetLoc%BUILD_ID%(data) {
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

  if (%BUILD_SELECTED% && !item && %MAPS2_SHOW_OBJECTS%){
    item = %BUILD_SELECTED%;
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

  //Changing select to input
  jQuery('.BUTTON-ENABLE-ADD').on('click', function () {
    jQuery('.addBuildMenu').removeClass('d-flex');
    jQuery('.addBuildMenu').addClass('d-none');

    jQuery('.changeBuildMenu').show();
    jQuery('#map_add_btn').fadeOut(300);
  });

  //Changing input to select
  jQuery('.BUTTON-ENABLE-SEL').on('click', function () {
    jQuery('.addBuildMenu').removeClass('d-none');
    jQuery('.addBuildMenu').addClass('d-flex');

    jQuery('.changeBuildMenu').hide();
  })
</script>
