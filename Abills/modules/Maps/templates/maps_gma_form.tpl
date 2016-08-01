<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>_{AUTO_COORDS}_</h4></div>
  <div class='panel-body'>

    <form id='form_GMA' class='form form-horizontal'>


      <div class='form-group'>
        <label class='control-label col-md-7 required' for='COUNTRY_CODE_id'>_{COUNTRY}_ (2 letters)</label>
        <div class='col-md-5'>
          <input type='text' class='form-control' required name='COUNTRY_CODE' value='%COUNTRY_ABBR%'
                 id='COUNTRY_CODE_id'
                 placeholder='IANA format'/>
        </div>
      </div>

      <div class='checkbox'>
        <label>
          <input type='checkbox' name='DISTRICTS_ARE_NOT_REAL' id='DISTRICTS_ARE_NO_REAL' value='1' %DISTRICTS_ARE_NOT_REAL_CHECKED% />
          <strong>_{FAKE}_ _{DISTRICTS}_</strong>
        </label>
      </div>

    </form>

  </div>
  <div class='panel-footer text-center'>
    <button id='GMA_EXECUTE_BTN' class='btn btn-primary'>_{EXECUTE}_</button>
  </div>
</div>

<div class='progress'>
  <div class='progress-bar progress-bar-success progress-bar-striped' aria-valuenow='0' id='progress_status'
       style='width: 0'></div>
</div>

<script id='GMA_JSON'>%GMA_JSON%</script>

<script src='/styles/default_adm/js/maps/gma.js'></script>