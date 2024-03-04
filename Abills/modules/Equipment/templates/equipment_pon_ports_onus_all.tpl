<input type='hidden' name='index' value='%index%'>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>

<div class='row d-flex'>

  <div class='col-md-3'>

    <div class='card card-primary card-outline card-form'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{EQUIPMENT}_ _{INFO}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
        </div>
      </div>
      <div class='card-body'>

        %EQUIPMENT_IMAGE%

        <div class='form-group row'>
          <label class='col-md-3 col-form-label text-md-right' for='NAME'>ID: %NAS_ID%</label>
          <div class='col-md-8'>
            <div class='input-group'>
              <input type='text' class='form-control' placeholder='_{NAME}_: %NAS_NAME% (%NAS_IP%)'
                     name='NAME'
                     readonly value='%NAS_NAME% (%NAS_IP%)' ID='NAME'>
              <div class='input-group-append'>
                <div class='input-group-text'>
                  %MAIN_INFO%
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row mb-0'>
          <label for='MODEL_ID' class='col-md-3 col-form-label text-md-right'>_{MODEL}_:</label>
          <div class='col-md-8 p-2'>
            %VENDOR_NAME% %MODEL_NAME%
          </div>
        </div>

        <div class='form-group row mb-0'>
          <label for='LAST_ACTIVITY'
                 class='col-md-3 col-form-label text-md-right'>_{LAST_ACTIVITY}_:</label>
          <div class='col-md-8' style='height: 56px; line-height: 56px; vertical-align: middle;'>
            %LAST_ACTIVITY%
          </div>
        </div>

      </div>

    </div>

    <div class='card card-primary card-outline card-form'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{GENERAL_INFORMATION}_ ONU</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
        </div>
      </div>
      <div class='card-body p-0'>
        %PON_ONUS_SIGNAL_INFO%
      </div>
    </div>

    <div class='card card-primary card-outline card-form collapsed-card'>
      <div class='card-header with-border'>
        <h4 class='card-title'>EPON</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i></button>
        </div>
      </div>
      <div class='card-body p-2'>
        %EPON_PORTS_INFO%
      </div>
    </div>

    <div class='card card-primary card-outline card-form collapsed-card'>
      <div class='card-header with-border'>
        <h4 class='card-title'>GPON</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i></button>
        </div>
      </div>
      <div class='card-body p-2'>
        %GPON_PORTS_INFO%
      </div>
    </div>

  </div>

  <div class='col-md-9'>
    %PON_ONU_TABLE%
  </div>

</div>

<script>
  jQuery(document).ready(function () {
    fetch('$SELF_URL?header=2&get_index=equipment_info&visual=4&NAS_ID=%NAS_ID%&unreg_btn_ajax=1&PON_TYPE=%PON_TYPE%')
      .then(function (response) {
        if (!response.ok)
          throw Error(response.statusText);

        return response;
      })
      .then(function (response) {
        return response.text();
      })
      .then(result => {
        jQuery('#unreg_btn').replaceWith(result);
      });
  })
</script>