<label class='col-sm-4 text-center paysys-chooser p-0 m-1' style="max-width: 12rem;" role='button'>
  <input type='radio' required class='hidden' name='PAYMENT_SYSTEM' id='%PAY_SYSTEM%' value='%PAY_SYSTEM%' %CHECKED%>

  <div class='card card-primary paysys-chooser-box m-0'>

    <div class='card-body text-center'>
      <img class='img-fluid center-block' src='%PAY_SYSTEM_LC%' alt='%PAY_SYSTEM_NAME%'>
    </div>

    <div class='card-footer %HIDDEN%'>
      <h4>%PAY_SYSTEM_NAME%</h4>
    </div>

  </div>
</label>

<script>
  if (jQuery('.hidden-btn-text').length) {
    jQuery('.img-fluid').css('margin-bottom', '20px');
  }
</script>