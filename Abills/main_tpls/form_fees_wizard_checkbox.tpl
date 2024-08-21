<div class='checkbox'>
  <label id='label'><input type='checkbox' id='chk_1'> _{WITHOUT_FEES}_</label>
</div>

<script>
  jQuery('form#form_wizard').on('submit', function(e) {
    cancelEvent(e);

    const methodFirst = jQuery('#METHOD_0');
    const textFirst = methodFirst.find(':selected').text();

    const sumIsPositive = jQuery('#SUM_0').val() > 0 || textFirst.includes('_{PRICE}_:')

    if (jQuery('#chk_1').is(':checked') || sumIsPositive) {
      jQuery('form#form_wizard').off('submit');
      jQuery('form#form_wizard').submit();
    }
    else {
      jQuery('#label').css('color', 'red');
    }
  });
</script>
