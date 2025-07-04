<div id='POINT_INFO_BLOCK'>
  <hr/>

  <div class='form-group row'>
    <label class='col-md-4 col-form-label text-md-right' for='COMMENTS_ID'>_{COMMENTS}_:</label>
    <div class='col-md-8'>
      <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_ID'>%COMMENTS%</textarea>
    </div>
  </div>

  <ul class="list-group" style="text-align: left">
    <li class="list-group-item"><b>_{CREATED}_:</b> %CREATED%</li>
    <li class="list-group-item"><b>_{PLANNED}_:</b> %PLANNED_NAMED%</li>
    <li class="list-group-item" data-visible='%SHOW_MAP_BTN%'><b>_{MAP}_:</b> %MAP_BTN%</li>
    <li class="list-group-item"><b>_{ADDRESS}_:</b> %ADDRESS_NAME%</li>
<!--    <li class="list-group-item"><b>_{COMMENTS}_:</b> %COMMENTS%</li>-->
  </ul>
</div>
<script>
  jQuery(function () {

    var btn = jQuery('#point_info_edit_btn');
    btn.on('click', function () {
      // Load modal
      loadToModal('%SELF_URL%?get_index=maps_objects_main&TEMPLATE_ONLY=1&header=2&chg=%ID%');

      // When submitted, renew
      Events.once('AJAX_SUBMIT.form_MAPS_OBJECT', function () {
        aModal.hide();
        jQuery('#POINT_INFO_BLOCK').load(' #POINT_INFO_BLOCK');
      })
    });
  })
</script>
