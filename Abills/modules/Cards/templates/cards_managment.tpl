<div class="box box-theme ">
  <div class="box-body ">
    <div class='row'>
    <div class='form-group col-md-3'>
      <label for='DILLER_ID'>_{DILLERS}_:</label>
      %DILLERS_SEL%
    </div>

    <div class='form-group col-md-3'>
      <label for='STATUS'>_{STATUS}_:</label>
      %STATUS_SEL%
    </div>

      <div class='form-group col-md-2'>
        <label for='SOLD'>_{SOLD}_:</label>
        <input type='checkbox' name='SOLD' value='1' form='cards_list'>
      </div>

      <div class='form-group col-md-2'>
        <label for='INVOICE'>_{CREATE}_ _{INVOICE}_:</label>
        <input type='checkbox' name='INVOICE' value='1' form='cards_list'>
      </div>

      <input type=submit name='change' value='_{CHANGE}_' class='btn btn-primary' form='cards_list'>

    </div>
  </div>
</div>