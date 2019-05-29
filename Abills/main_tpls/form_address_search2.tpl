<div class='form-address' style="padding-left: 10px">
  <input type='hidden' name='LOCATION_ID' id="ADD_LOCATION_ID" value='%LOCATION_ID%' class='HIDDEN-BUILD'>

  <div class='form-group' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-sm-3 col-md-2 LABEL-DISTRICT'>_{DISTRICTS}_</label>
    <div class='col-sm-9 col-md-10'>
      %ADDRESS_DISTRICT%
    </div>
  </div>

  <div class='form-group' style='%EXT_SEL_STYLE%'>
    <label class='control-label col-sm-3 col-md-2 LABEL-STREET'>_{ADDRESS_STREET}_</label>
    <div class='col-sm-9 col-md-10' id="streets">
      %ADDRESS_STREET%
    </div>
  </div>

  <div class='form-group' style='%EXT_SEL_STYLE%'>

    <div class="col-md-6 ">

      <label class='control-label col-sm-3 col-md-4 LABEL-BUILD'>_{ADDRESS_BUILD}_</label>

      <div class='input-group col-sm-9 col-md-8 addBuildMenu' style="padding-left: 10px">
        <div id="builds" class="col-md-12" style="padding: 0">
          %ADDRESS_BUILD%
        </div>
        <span class='input-group-addon' %ADD_BUILD_HIDE%>
        <a title='_{ADD}_ _{BUILDS}_' class='BUTTON-ENABLE-ADD'>
        <span class='glyphicon glyphicon-plus'></span>
        </a>
        </span>
      </div>

      <div class='col-sm-9 col-md-8 changeBuildMenu' style='display : none; padding-left: 10px; padding-right: 0'>
        <div class='input-group'>
          <input type='text' name='ADD_ADDRESS_BUILD' class='form-control INPUT-ADD-BUILD'/>
          <span class='input-group-addon'>
              <a class='BUTTON-ENABLE-SEL'>
                <span class='glyphicon glyphicon-list'></span>
              </a>
             </span>
        </div>
      </div>

    </div>

    <div class="col-md-6 no-padding" style=" %HIDE_FLAT%">

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
    <a href='$SELF_URL?get_index=form_districts&full=1&header=1' class='btn btn-success btn-sm'
       data-tooltip-position='top' data-tooltip='_{ADD}_ _{DISTRICT}_'><i class='fa fa-street-view'></i></a>
    <a href='$SELF_URL?get_index=form_streets&full=1&header=1' class='btn btn-success btn-sm'
       data-tooltip-position='top' data-tooltip='_{ADD}_ _{STREET}_'><i class='fa fa-road'></i></a>
    %MAP_BTN%
    %DOM_BTN%
  </div>
</div>

<script>
  document['FLAT_CHECK_FREE']     = '%FLAT_CHECK_FREE%' || "1";
  document['FLAT_CHECK_OCCUPIED'] = '%FLAT_CHECK_OCCUPIED%' || "0";
</script>
<!--<script src='/styles/default_adm/js/searchLocation.js'></script>-->
<script>
  jQuery(function () {
    // Updating streets and builds
      var distName = jQuery('#select2-DISTRICT_ID-container.select2-selection__rendered').text();
      var strName = jQuery('#select2-STREET_ID-container.select2-selection__rendered').text();
      var buildName = jQuery('#select2-BUILD_ID-container.select2-selection__rendered').text();
    setInterval(function () {
        var newD = jQuery('#select2-DISTRICT_ID-container.select2-selection__rendered').text();
        var newS = jQuery('#select2-STREET_ID-container.select2-selection__rendered').text();
        var newB = jQuery('#select2-BUILD_ID-container.select2-selection__rendered').text();
        //Get streets after change district
        if (distName !== newD) {
          GetStreets();
          distName = newD;
        }
        //Get builds after change street
        if (strName !== newS) {
          GetBuilds();
          strName = newS;
        }
        //Get location_id after change build
        if (buildName !== newB) {
          GetLoc();
          buildName = newB;
        }
      }, 1000);
  });

  function GetStreets(data) {
    var d = jQuery("#DISTRICT_ID").val();
    // console.log(d);
    jQuery.post('$SELF_URL', 'header=2&get_index=form_address_select2&DISTRICT_ID=' + d + '&STREET=1', function (result) {
      jQuery('#streets').html(result);
      initChosen();
    });
  }
    function GetBuilds(data) {
      var s = jQuery("#STREET_ID").val();
      // console.log(s);
      jQuery.post('$SELF_URL', 'header=2&get_index=form_address_select2&STREET_ID='+s+'&BUILD=1', function (result) {
        jQuery('#builds').html(result);
        initChosen();
      });
  }
  //Get location_id after change build
  function GetLoc(data) {
    var i = jQuery("#BUILD_ID").val();
    if (i == '--') {
      i = '';
    }
    jQuery('#ADD_LOCATION_ID').attr('value', i);
  };

  //Changing select to input
  jQuery('.BUTTON-ENABLE-ADD').on('click', function () {
    jQuery('.addBuildMenu').hide();
    jQuery('.changeBuildMenu').show();
  });
  //Changing input to select
  jQuery('.BUTTON-ENABLE-SEL').on('click', function () {
    jQuery('.addBuildMenu').show();
    jQuery('.changeBuildMenu').hide();
  })

</script>
