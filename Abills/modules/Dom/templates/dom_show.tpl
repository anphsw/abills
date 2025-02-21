<script src='/styles/default/js/raphael.min.js'></script>
<script src='/styles/default/js/build_construct.js'></script>


<style type='text/css'>
   #tip {
    position: fixed;
    color: white;
    border: 1px solid gray;
    border-bottom: none;
    background-color: #7AB932;
    padding: 3px;
    z-index: 1000;
    /* set this to create word wrap */
    max-width: 200px;
  }

   .dom-control-panel {
		 padding: 6px 10px 6px 6px;
		 color: #333;
		 background: #fff;
		 position: absolute;
     top: 10px;
     right: 20px;
     z-index: 999;
		 box-shadow: 0 1px 5px rgb(0 0 0);
		 border-radius: 5px;
   }
</style>

<form method='post' class='form form-horizontal'>
  <div class='card card-primary card-outline no-padding'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%DISTRICT_NAME% %STREET_NAME% %BUILD_NAME%</h4>
    </div>
    <div class='card-body no-padding' id='body'>
      <div class='info-box-content' style='margin-left:5px'>
        <div class='col-md-12 text-center'>
          <p><b>_{ENTRANCES}_:</b> %BUILD_ENTRANCES%</p>
          <p><b>_{FLORS}_:</b> %BUILD_FLORS%</p>
          <p><b>_{MAP}_ _{FLATS}_:</b> %CLIENTS_FLATS_SUM%/%BUILD_FLATS% </p>
        </div>
        <div class='col-md-12 text-right'>
          %BTN_COMMENT%
        </div>
        <div class='col-md-12'>
          <div class='progress '>
            <div class='progress-bar'>
              <span class='badge bg-light-blue-active color-palette' id='progress-bar'>%USER_PERCENTAGE% %</span>
            </div>
          </div>
        </div>
      </div>
      <!-- Canvas -->
      <div class='col-sm-12 p-0' id='scroll_canvas_container'>
        <div class='form-group dom-control-panel'>
          <div class='form-check'>
            <input class='form-check-input' type='radio' id='user-radio' name='range' value='user' checked>
            <label class='form-check-label' for='user-radio'>_{USERS}_</label>
          </div>
          <div class='form-check'>
            <input class='form-check-input' id='pon-radio' type='radio' name='range' value='pon'>
            <label class='form-check-label' for='pon-radio'>PON</label>
          </div>
        </div>

        <div id='tip' style='display: none'></div>
        <div id='canvas_container' class='w-100 p-0' style='overflow: scroll;'>
        </div>
        <div>
          <p class='text-center'>
            <strong><i class='fa fa-list margin-r-5'></i>_{DESCRIBE}_:</strong>
            %USER_STATUS%
          </p>
        </div>
        %TABLE_NAS%
      </div>

    </div>
  </div>


</form>

<script type='application/javascript'>
  jQuery(document).ready(function () {

    let percentages = {
      user: '%USER_PERCENTAGE%' + '%',
      pon: '%PON_PERCENTAGE%' + '%'
    }

    let info = {
      user: '%USER_INFO%',
      pon: '%PON_INFO%'
    }

    jQuery("input[name='range']").on('click', function() {
      let type = jQuery(this).val();

      setView(type);
    });

    function setView(type) {
      jQuery('.progress-bar').width(percentages[type]);
      jQuery('#progress-bar').text(percentages[type]);
      jQuery('#no_correct_flat').attr('href', '%SHOW_USERS%');

      jQuery('#canvas_container').html('');
      build_construct(
        '%BUILD_FLORS%',
        '%BUILD_ENTRANCES%',
        '%FLORS_ROOMS%',
        'canvas_container',
        info[type],
        '%LANG_PACK%',
        'canvas_height',
        '%BUILD_FLATS%',
        '%BUILD_SCHEMA%',
        '%NUMBERING_DIRECTION%',
        '%START_NUMBERING_FLAT%'
      );
    }

    setView('user');
  })
</script>


