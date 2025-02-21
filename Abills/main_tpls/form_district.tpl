<form action='%SELF_URL%' METHOD='post' enctype='multipart/form-data' name=add_district>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>_{DISTRICTS}_</div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE_ID'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_SEL%
        </div>
      </div>

      <hr>
      <div class='form-group row'>
        <label class='col-md-12 col-form-label text-center' for='NAME'>_{ADDRESS_PARENT}_</label>
      </div>
          %DISTRICT_SEL%
      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ZIP'>_{ZIP}_:</label>
        <div class='col-md-8'>
          <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='%ZIP%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='POPULATION'>_{POPULATION}_:</label>
        <div class='col-md-8'>
          <input id='POPULATION' name='POPULATION' value='%POPULATION%' min='0' class='form-control' type='number'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='HOUSEHOLDS'>_{HOUSEHOLDS}_:</label>
        <div class='col-md-8'>
          <input id='HOUSEHOLDS' name='HOUSEHOLDS' value='%HOUSEHOLDS%' min='0' class='form-control' type='number'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>

<script>
  jQuery('#POPULATION').on('input', function () {
    let population = jQuery(this).val();
    if (population < 1) return;

    jQuery('#HOUSEHOLDS').val(Math.round(parseInt(population) / 3.3));
  });
</script>