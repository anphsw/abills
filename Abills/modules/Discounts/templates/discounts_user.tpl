<script language='JavaScript'>
  function autoReload() {
    document.discounts_user.submit();
  }
</script>

<form action=%SELF_URL% METHOD=POST name='discounts_user' id='discounts_user'>

  <input type='hidden' name='index' value=%index%>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='AID' value='%AID%'>
  <input type='hidden' name='add_form' id='add_form' value='$FORM{add_form}'/>
  <input type='hidden' name='chg' id='chg' value='$FORM{chg}'>

  <div class='card card-primary card-outline box-form container col-md-6'>
    <div class='card-header with-border'>$lang{DISCOUNT}</div>

    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>_{MODULE}_</label>
        <div class='col-md-8'>
          %MODULE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TARIF_PLANS}_</label>
        <div class='col-md-8'>
          %TARIFF_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'>_{TYPE}_</label>
        <div class='col-md-8'>
          %TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PERCENT'>_{PERCENT}_</label>
        <div class='col-md-8'>
          <input class='form-control' type='number' min='0' max='100' name='PERCENT' id='PERCENT' value='%PERCENT%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SUM'>_{SUM}_</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' id='SUM' name='SUM' value='%SUM%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 control-label text-md-right' for='FROM_DATE'>_{DATE}_ _{FROM}_</label>
        <div class='col-md-8'>
          <input id='FROM_DATE' name='FROM_DATE' value='%FROM_DATE%' placeholder='0000-00-00'
                 class='form-control datepicker' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 control-label text-md-right' for='TO_DATE'>_{DATE}_ _{TO}_</label>
        <div class='col-md-8'>
          <input id='TO_DATE' name='TO_DATE' value='%TO_DATE%' placeholder='0000-00-00'
                 class='form-control datepicker' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name=%ACTION% id=%ACTION% value='%ACTION_LANG%'>
    </div>
  </div>

</form>

<script>
  formatInputWithThousands('SUM');

  jQuery('#change').on('click', function (event) {
    jQuery('#chg').remove();
  });
  jQuery('#add').on('click', function (event) {
    jQuery('#add_form').remove();
  });
</script>