<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='TP_ID' value='%TP_ID%'>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header'>
          <h4 class='card-title'>_{TARIF_PLAN}_</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
            <div class='col-md-8'>
              <input id='NAME' name='NAME' value='%NAME%' class='form-control' required type='text'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='PAYMENT_TYPE'>_{PAYMENT_TYPE}_:</label>
            <div class='col-md-8'>
              %PAYMENT_TYPES_SEL%
            </div>
          </div>
          <div class='form-group row'>
            <label for='MONTH_FEE' class='control-label col-md-4'>_{MONTH_FEE}_:</label>
            <div class='col-md-8'>
              <input class='form-control' id='MONTH_FEE' placeholder='%MONTH_FEE%' name='MONTH_FEE'
                     value='%MONTH_FEE%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 text-right' for='REDUCTION_FEE'>_{REDUCTION}_:</label>
            <div class='col-sm-8'>
              <div class='form-check text-left'>
                <input type='checkbox' class='form-check-input' id='REDUCTION_FEE' name='REDUCTION_FEE'
                       %REDUCTION_FEE% value='1'>
              </div>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{DESCRIBE}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
            </div>
          </div>
        </div>
        <div class='card-footer'>
          <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
<!--      <div class='card card-primary card-outline'>-->
<!--        <div class='card-header'>-->
<!--          <h4 class='card-title'>Послуги</h4>-->
<!--        </div>-->
<!--        <div class='card-body'>-->
          %CATEGORIES_TABLE%
<!--        </div>-->
<!--      </div>-->
    </div>
  </div>
</form>

<script>
  jQuery('.mobile-service').on('change', function() {
    let price = 0;
    jQuery('.mobile-service:checked').each(function() {
      price += jQuery(this).data('price') || 0;
    });

    jQuery(`[name='MONTH_FEE']`).val(price);
  });
</script>