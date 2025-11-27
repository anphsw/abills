<form action='%SELF_URL%' METHOD='post' enctype='multipart/form-data' name=add_district>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>_{TERRITORIAL_UNITS}_</div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE_CODE'>_{TYPE}_:</label>
        <div class='col-md-8'>
          <input id='TYPE_CODE' name='TYPE_CODE' value='%TYPE_CODE%' placeholder='%TYPE_CODE%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CODE'>_{CODE}_:</label>
        <div class='col-md-8'>
          <input id='CODE' name='CODE' value='%CODE%' placeholder='%CODE%' class='form-control' type='text'>
        </div>
      </div>

      <!--      %TERRITORIAL_UNITS_SEL%-->

    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>