<form action='%SELF_URL%' method='POST'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='sid' value='$sid'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{ACCOUMULATION}_ _{BONUS}_</h3>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          %TARIF_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3'>_{ENABLE}_:</label>

        <div class='col-md-9'>
          %STATE%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3'>_{ACCEPT_RULES}_:</label>

        <div class='col-md-9'>
          %ACCEPT_RULES%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3'>_{BONUS}_:</label>

        <div class='col-md-9'>
          %COST_FORM%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </div>
</form>

