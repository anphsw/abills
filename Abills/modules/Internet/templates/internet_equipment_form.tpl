<div id='form_4' class='card card-primary card-outline card-big-form for_sort container-md pr-0 pl-0'>
  <div class='card-header with-border'>
    <h3 class='card-title'>_{EQUIPMENT}_</h3>
    <div class='card-tools float-right'>
      <button id='reload_equipment_info_button' type='button' class='btn btn-tool' title='_{RELOAD_EQUIPMENT_INFO}_' disabled>
        <i class='fas fa-sync'></i>
      </button>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    <div id='status-loading-content'>
      <div class='text-center'>
        <span class='fa fa-spinner fa-spin fa-2x'></span>
      </div>
    </div>
    <div id='equipment_info'></div>
  </div>
</div>

<script>
  let nasId = '%NAS_ID%';
  let port = '%PORT%';
  let vlan = '%VLAN%';
  let uid = '%UID%';
  let id = '%ID%';

  let equipment_get_info_url = '$SELF_URL?header=2&get_index=equipment_user_info_ajax' + '&NAS_ID=' + nasId + '&PORT=' + port + '&VLAN=' +
    vlan + '&UID=' + uid + '&ID=' + id;

  let equipment_change_port_status_url = '$SELF_URL?header=2&get_index=equipment_change_port_status_ajax' + '&NAS_ID=' + nasId + '&PORT=' + port;

  jQuery('#reload_equipment_info_button').on('click', function (e) {
    equipment_get_info(equipment_get_info_url);
  });

  equipment_get_info(equipment_get_info_url);

  function hide_equipment_info() {
    jQuery('#equipment_info').hide();
    jQuery('#equipment_info').parent().css('padding', '');
    jQuery('#status-loading-content').show();
    jQuery('#reload_equipment_info_button').prop('disabled', true);
  }

  function equipment_get_info(url) {
    hide_equipment_info();

    fetch(url)
      .then(function (response) {
        if (!response.ok) {
          throw Error(response.statusText);
        }

        return response.text();
      })
      .then(result => {
        jQuery('#equipment_info').html(result);
        jQuery('#equipment_info').show();
        jQuery('#status-loading-content').hide();
        jQuery('#reload_equipment_info_button').prop('disabled', false);

        let cardBody = jQuery('#equipment_info').children();
        cardBody.removeClass('card-primary');
        cardBody.css('margin-bottom', '0');
        jQuery('#equipment_info').parent().css('padding', '0');

        jQuery('#run_cable_test_button').on('click', function (e) {
          equipment_get_info(equipment_get_info_url + '&RUN_CABLE_TEST=1');
        });

        jQuery('#change_status_button').on('click', function (e) {
          hide_equipment_info();

          let atooltip = new ATooltip();
          atooltip.displayMessage({caption: '_{PORT_STATUS_CHANGING}_', message_type: 'info'});

          fetch(equipment_change_port_status_url + '&PORT_STATUS=' + jQuery('#change_status_button').data('change_to_status'))
            .then(function (response) {
              if (!response.ok)
                throw Error(response.statusText);

              return response.text();
            })
            .then(result_json => {
              let result = jQuery.parseJSON(result_json);

              atooltip.displayMessage({caption: result.comment, message_type: (result.error ? 'err' : '')});
              if (!result.error) {
                setTimeout(function() { //wait for physical status to change
                  equipment_get_info(equipment_get_info_url);
                }, 3000);
              }
              else {
                equipment_get_info(equipment_get_info_url);
              }
            })
        });
      });
  }
</script>
