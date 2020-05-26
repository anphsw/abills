<div class='form-address'>
    <input type='hidden' name='LOCATION_ID' id='ADD_LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>

    <div class='form-group' style='%EXT_SEL_STYLE%'>
        <label class='control-label col-sm-3 col-md-4 LABEL-DISTRICT'>_{DISTRICTS}_</label>
        <div class='col-sm-9 col-md-8'>
            %ADDRESS_DISTRICT%
        </div>
    </div>

    <div class='form-group' style='%EXT_SEL_STYLE%'>
        <label class='control-label col-sm-3 col-md-4 LABEL-STREET'>_{ADDRESS_STREET}_</label>
        <div class='col-sm-9 col-md-8' id='%STREET_ID%_'>
            %ADDRESS_STREET%
        </div>
    </div>

    <div class='form-group' style='%EXT_SEL_STYLE%'>
        <label class='control-label col-sm-3 col-md-4 LABEL-BUILD'>_{ADDRESS_BUILD}_</label>

        <div class='input-group col-sm-9 col-md-8 addBuildMenu' style='padding-left: 15px; padding-right: 15px;'>
            <div id='%BUILD_ID%_' class='col-md-12' style='padding: 0'>
                %ADDRESS_BUILD%
            </div>
            <span class='input-group-addon' %ADD_BUILD_HIDE%>
        <a title='_{ADD}_ _{BUILDS}_' class='BUTTON-ENABLE-ADD'>
        <span class='glyphicon glyphicon-plus'></span>
        </a>
        </span>
        </div>

        <div class='col-sm-8 col-md-8 changeBuildMenu' style='display : none; padding-left: 15px; padding-right: 15px;'>
            <div class='input-group'>
                <input type='text' id='ADD_ADDRESS_BUILD_ID' name='ADD_ADDRESS_BUILD' class='form-control INPUT-ADD-BUILD'/>
                <span class='input-group-addon'>
              <a class='BUTTON-ENABLE-SEL'>
                <span class='glyphicon glyphicon-list'></span>
              </a>
             </span>
            </div>
        </div>
    </div>
    <div class='form-group'>
        <span class='visible-sm visible-sm col-sm-12' > </span>

        <div style='%HIDE_FLAT%'>

            <label class='control-label col-sm-3 col-md-4'>_{ADDRESS_FLAT}_</label>

            <div class='col-sm-9 col-md-8'>
                <input type='text' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%' class='form-control INPUT-FLAT'>
            </div>

        </div>

    </div>
    <div class='form-group'>
        %EXT_ADDRESS%
    </div>
    <div class=' pull-right'>
        %ADDRESS_ADD_BUTTONS%
        %MAP_BTN%
        %DOM_BTN%
        <span id="map_add_btn" style="display: none">%MAPS2_BTN%</span>
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
    // console.log(distrId);
    jQuery.post('$SELF_URL', '%QINDEX%header=2&get_index=form_address_select2&DISTRICT_ID=' + distrId
      + '&STREET=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%', function (result) {
      // console.log(result);
      jQuery('#%STREET_ID%_').html(result);
      initChosen();
      jQuery("#%STREET_ID%").focus();
      jQuery("#%STREET_ID%").select2('open');
    });
  }

  function GetBuilds%STREET_ID%(data) {
    var strId = jQuery("#" + data.id).val();
    if (!strId || strId == 0) {
      strId = 0;
      jQuery('#ADD_LOCATION_ID').attr('value', '');
    }
    jQuery.post('$SELF_URL', '%QINDEX%header=2&get_index=form_address_select2&STREET_ID=' + strId
      + '&BUILD=1&DISTRICT_SELECT_ID=%DISTRICT_ID%&STREET_SELECT_ID=%STREET_ID%&BUILD_SELECT_ID=%BUILD_ID%', function (result) {
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
    jQuery('.addBuildMenu').hide();
    jQuery('.changeBuildMenu').show();
    jQuery('#map_add_btn').fadeOut(300);
  });
  //Changing input to select
  jQuery('.BUTTON-ENABLE-SEL').on('click', function () {
    jQuery('.addBuildMenu').show();
    jQuery('.changeBuildMenu').hide();
  })
</script>
