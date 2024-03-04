<!-- Loading WebCam script -->
<script src='/styles/default/js/webcam/webcam.min.js'></script>

<style>
  #camera_preview {
    border: 1px solid silver;
    margin: 10px;
  }
</style>

<div class='card box-primary'>
  <div class='card-body'>
    <div class='row'>
      <div id='camera_preview'></div>
      <label class='col-form-label text-md-right' for='snapshot_resolution'>_{RESOLUTION}_: </label>

      <div class='col-md-3'>
        <select id='snapshot_resolution' onchange='changeResolution(this)'>
          <option value='0'>640x480</option>
          <option value='1'>320x240</option>
          <option value='2'>1280x960</option>
        </select>
      </div>
    </div>
  </div>

  <div class='card-footer'>
    <div class='row'>
      <div class='col-md-4 btn btn-secondary'>
        <label class='control-label p-0' id='includeLocation_lbl'
               for='includeLocation'>_{GEO}_</label>
        <input type='checkbox' class='form-control-m' id='includeLocation'
               value='1' name='includeLocation' onchange='makeGeolocation()' checked>
      </div>
      <div class='col-md-4'>
        <a class='btn btn-success form-control' id='upload_btn' href='javascript:void(upload())'>
          _{UPLOAD}_
        </a>
      </div>
      <div class='col-md-4'>
        <a class='btn btn-primary form-control' id='snapshot_btn'>
          _{TAKE_SNAPSHOT}_
        </a>
      </div>
    </div>
  </div>
</div>

<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'
      id='submit_photo_form'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='PHOTO' value='%PHOTO%'>
  <input type='hidden' name='EXTERNAL_ID' value='%EXTERNAL_ID%'>
  <input type='hidden' name='IMAGE' id='PHOTO'>
  <input type='hidden' name='COORDX' id='location_x'>
  <input type='hidden' name='COORDY' id='location_y'>
</form>


<script>
  var _TAKE_SNAPSHOT = '_{TAKE_SNAPSHOT}_';
  var _TAKE_ANOTHER = '_{DEL}_';
</script>
<!-- After page loaded, load WebCam custom script-->
<script src='/styles/default/js/webcam/webcam-script.js'></script>

<script>
  attachWebcam(640, 480);
  makeGeolocation();

  function successCall(coords) {
    jQuery('#includeLocation_lbl').addClass('text-success');
  }

  function errorCall() {
    jQuery('#includeLocation_lbl')
      .prop('disabled', true)
      .addClass('disabled text-danger')
      .html("_{GEO_DISABLED_BY_BROWSER}_");
  }

  function makeGeolocation() {
    var includeLocation = document.getElementById('includeLocation').checked;
    if (includeLocation)
        getLocation(successCall, errorCall, false);
  }
</script>
