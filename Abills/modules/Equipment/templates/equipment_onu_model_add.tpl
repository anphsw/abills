<form action='$SELF_URL' method='POST' enctype='multipart/form-data' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{ACTION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required'> PON _{TYPE}_:</label>
        <div class='col-md-8'>
          %SELECT_PON_TYPE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='ONU_TYPE' >ONU _{TYPE}_:</label>
        <div class='col-md-8'>
          <input id='ONU_TYPE' name='ONU_TYPE' value='%ONU_TYPE%' placeholder='%ONU_TYPE%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ETHERNET_PORTS'> Ethernet _{PORTS}_:</label>
        <div class='col-md-8'>
          <input id='ETHERNET_PORTS' name='ETHERNET_PORTS' value='%ETHERNET_PORTS%' placeholder='%ETHERNET_PORTS%' class='form-control' type='number'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='WIFI_SSIDS'> WiFi SSIDs:</label>
        <div class='col-md-8'>
          <input id='WIFI_SSIDS' name='WIFI_SSIDS' value='%WIFI_SSIDS%' placeholder='%WIFI_SSIDS%' class='form-control' type='number'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='VOIP_PORTS'> Voip _{PORTS}_:</label>
        <div class='col-md-8'>
          <input id='VOIP_PORTS' name='VOIP_PORTS' value='%VOIP_PORTS%' placeholder='%VOIP_PORTS%' class='form-control' type='number'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CATV'>CATV:</label>
        <div class="col-sm-8 col-md-8 p-2">
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='CATV'
                   name='CATV' %CATV% value='1'>
          </div>
        </div>
      </div>

<!--      <div class='form-group row'>-->
<!--        <label class='col-md-4 col-form-label text-md-right' for='CUSTOM_PROFILES' >CUSTOM profiles:</label>-->
<!--        <div class='col-md-8'>-->
<!--          <input id='CUSTOM_PROFILES' name='CUSTOM_PROFILES' value='%CUSTOM_PROFILES%' placeholder='%CUSTOM_PROFILES%' class='form-control' type='text'>-->
<!--        </div>-->
<!--      </div>-->

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'> _{CAPABILITY}_:</label>
        <div class='col-md-8'>
          %SELECT_CAPABILITY%
        </div>
      </div>

      <div>
        <div class='form-group row'>
          <label class='col-md-4 control-label' for='IMAGE'>ONU _{PICTURE}_:</label>
          <div class='col-md-8'>
            <input type='file' id='IMAGE' name='IMAGE'>
          </div>
        </div>
          %IMAGE%
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>