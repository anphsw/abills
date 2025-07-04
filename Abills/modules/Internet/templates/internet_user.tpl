<style>
  .alert-%STATUS% {
    background-image: -webkit-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    background-image: -o-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    background-image: -webkit-gradient(linear, left top, left bottom, from(%STATUS_COLOR_GR_S%), to(%STATUS_COLOR_GR_F%));
    background-image: linear-gradient(to bottom, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='%STATUS_COLOR_GR_S%', endColorstr='%STATUS_COLOR_GR_F%', GradientType=0);
    background-repeat: repeat-x;
    border-color:%STATUS_COLOR%;
  }

  /*div.input-group > span.clear_button {
    cursor: pointer;
  }*/
</style>

<form action='%SELF_URL%' method='post'>

  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='%UID%'>
  <input type=hidden name='STATUS_DAYS' value='%STATUS_DAYS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='ID' value='%ID%'>
  <input type=hidden name='LEAD_ID' value='$FORM{LEAD_ID}'>
  <input type=hidden name='LOCATION_ID' value='$FORM{LOCATION_ID}'>
  <input type=hidden name='DISTRICT_ID' value='$FORM{DISTRICT_ID}'>
  <input type=hidden name='STREET_ID' value='$FORM{STREET_ID}'>
  <input type=hidden name='ADDRESS_FLAT' value='$FORM{ADDRESS_FLAT}'>

  <div id='form_3' class='card card-primary card-outline card-big-form for_sort container-md pl-0 pr-0'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{INTERNET}_: %ID%</h4>
      <div class='card-tools float-right'>
        <a href='%SELF_URL%?get_index=internet_user&full=1&UID=%UID%&add_form=1'
           title='_{ADD_SERVICE}_' class='btn btn-tool btn-success'>
          <i class='fa fa-plus'></i>
        </a>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='row no-padding'>
        <div class='col-md-12 text-center'>
          %MENU%
        </div>
      </div>
      %ONLINE_TABLE%
      <div>

        %PAYMENT_MESSAGE%

        %NEXT_FEES_WARNING%

        %TP_CHANGE_WARNING%

        %LAST_LOGIN_MSG%

        <br/>
        %LOGIN_FORM%

        <div class='form-group row'>
          <label class='col-xs-4 col-md-2 col-form-label text-md-right' for='TP'>_{TARIF_PLAN}_:</label>
          <div class='col-xs-8 col-md-10'>
            <div class='input-group'>
              %TP_ADD%
              <div class='input-group' %TP_DISPLAY_NONE%>
                <div class='input-group-prepend'>
                  <div class='input-group-text'>
                    <span class='hidden-xs'>%TP_NUM%</span>
                  </div>
                </div>
                <input type='text' name='GRP' value='%TP_NAME% %DESCRIBE_AID%' ID='TP' class='form-control hidden-xs' %TARIF_PLAN_TOOLTIP% readonly>
                <div class='input-group-append'>
                  %CHANGE_TP_BUTTON%
                  <a class='btn input-group-button hidden-print px-3' title='_{PAY_TO}_'
                     href='%SELF_URL%?index=%index%&UID=%UID%&ID=%ID%&pay_to=1'>
                    <i class='$conf{CURRENCY_ICON}'></i>
                  </a>
                </div>
              </div>
            </div>
          </div>
          <div class='col-md-12'>%PERSONAL_TP_MSG%</div>
        </div>

        <div class='form-group row alert alert-%STATUS%'>
          <label class='col-xs-4 col-md-2 col-form-label text-md-right'>_{STATUS}_:</label>

          <div class='col-xs-8 col-md-10'>
            %STATUS_SEL%
            %STATUS_INFO%
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-form-label text-md-right col-xs-4 col-md-2'>_{STATIC}_ IP Pool:</label>
          <div class='col-xs-8 col-md-4'>
            %STATIC_IP_POOL%
            <div class='row text-left'>
              <strong>%CHOOSEN_STATIC_IP_POOL%</strong>
            </div>
          </div>
          <label class='col-form-label text-md-right col-xs-4 col-md-2' for='IP'>_{STATIC}_ IP:</label>
          <div class='col-xs-8 col-md-4'>
            <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-form-label text-md-right col-xs-4 col-md-2' for='CID'>CID:</label>
          <div class='col-xs-8 col-md-4'>
            <div class='input-group'>
              <input id='CID' name='CID' value='%CID%' placeholder='%CID%' %CID_PATTERN% class='form-control' type='text'>
                <div class='input-group-append'>
                  %CID_BUTTON_COPY%
                </div>
                <div class='input-group-append btn input-group-button d-none' id='CID_BLOCK_ANY'>
                  %CID_BUTTON_ANY%
                </div>
            </div>
          </div>

          <label class='col-form-label text-md-right col-xs-4 col-md-2' for='NETMASK'>MASK:</label>
          <div class='col-xs-8 col-md-4'>
            <input id='NETMASK' name='NETMASK' value='%NETMASK%' placeholder='%NETMASK%' class='form-control'
                   type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-form-label text-md-right col-xs-4 col-md-2' for='CPE_MAC'>CPE MAC:</label>
          <div class='col-xs-8 col-md-4'>
            <div class='input-group'>
            <input id='CPE_MAC' type='text' class='form-control' name='CPE_MAC' value='%CPE_MAC%'
                   %CPE_PATTERN%>
              <div class='input-group-append'>
                %CPE_MAC_BUTTON_COPY%
              </div>
              <div class='input-group-append btn input-group-button d-none' id='CPE_BLOCK_ANY'>
                %CPE_BUTTON_ANY%
              </div>
            </div>
          </div>
        </div>
      </div>



    </div>
    <div class='card mb-0 border-top card-outline card-big-form %IPOE_SHOW_BOX%'>
      <div class='card-header with-border'>
        <h3 class='card-title'>IPoE / DHCP Option 82</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-xs-4 col-md-2 col-form-label text-md-right' for='NAS_SEL'>_{NAS}_</label>
          <div class='col-xs-8 col-md-10'>
            <div class='input-group'>
              %NAS_SEL%
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-xs-4 col-md-2 col-form-label text-md-right' for='PORT'>_{PORT}_</label>
          <div class='col-xs-8 col-md-10 input-group'>
            %PORT_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-2 col-xs-4 col-form-label text-md-right' for='VLAN'>VLAN ID</label>
          <div class='input-group col-md-4 col-xs-8'>
            <input type='text' id='VLAN' name='VLAN' value='%VLAN%' class='form-control'/>
            <div class='input-group-append'>
              <div class='input-group-text clear_results cursor-pointer'>
                <span class='fa fa-times'></span>
              </div>
            </div>
          </div>

          <label class='col-md-2 col-xs-4 col-form-label text-md-right' for='SERVER_VLAN'>Server</label>
            <div class='col-md-4 col-xs-8 input-group'>
              %VLAN_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-2 text-right' for='IPN_ACTIVATE'>_{ACTIVATE}_ IPN</label>
            <div class='form-check col-md-10'>
              <input class='form-check-input text-left' id='IPN_ACTIVATE' name='IPN_ACTIVATE' value='1'
                           type='checkbox' %IPN_ACTIVATE%>
                %IPN_ACTIVATE_BUTTON%
            </div>
          </div>
        </div>
      </div>

      %EXT_SERVICE_CONTROL%

      <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
        <div class='card-body'>
            <div class='form-group row'>
              <label class='col-xs-4 col-md-3 col-form-label text-md-right'>IPv6 Pool:</label>
              <div class='col-xs-8 col-md-9'>
                %STATIC_IPV6_POOL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-xs-4 col-md-3 col-form-label text-md-right' for='IPV6'>_{STATIC}_ IPv6</label>
              <div class='col-sm-5 col-md-6'>
                <div class='input-group'>
                  <input id='IPV6' name='IPV6' value='%IPV6%' placeholder='%IPV6%' class='form-control'
                           type='text'>
                </div>
              </div>
              <div class='col-sm-3 col-md-3'>
                %IPV6_MASK_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-xs-4 col-md-3 col-form-label text-md-right' for='IPV6_PREFIX'>_{PREFIX}_ IPv6</label>
              <div class='col-sm-5 col-md-6'>
                <div class='input-group'>
                  <input id='IPV6_PREFIX' name='IPV6_PREFIX' value='%IPV6_PREFIX%' placeholder='%IPV6_PREFIX%'
                           class='form-control'
                           type='text'>
                </div>
              </div>
              <div class='col-sm-3 col-md-3'>
                %IPV6_PREFIX_MASK_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-3 col-form-label text-md-right' for='SPEED'>_{SPEED}_ (kb)</label>
              <div class='col-3'>
                <div class='input-group'>
                  <input id='SPEED' name='SPEED' value='%SPEED%' placeholder='%SPEED%'
                           class='form-control' type='text'>
                </div>
              </div>

              <label class='col-3 col-form-label text-md-right' for='LOGINS'>_{SIMULTANEOUSLY}_</label>
              <div class='col-3'>
                <div class='input-group'>
                  <input id='LOGINS' type='text' name='LOGINS' value='%LOGINS%' class='form-control'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-3 col-form-label text-md-right' for='SERVICE_ACTIVATE'>_{ACTIVATE}_</label>
              <div class='col-3'>
                <div class='input-group'>
                  <input id='SERVICE_ACTIVATE' name='SERVICE_ACTIVATE' value='%SERVICE_ACTIVATE%'
                           placeholder='%SERVICE_ACTIVATE%'
                           class='form-control datepicker d-0-19' rel='tcal' type='text'>
                </div>
              </div>

              <label class='col-3 col-form-label text-md-right' for='SERVICE_EXPIRE'>_{EXPIRE}_</label>
              <div class='col-3'>
                <div class='input-group'>
                  <input id='SERVICE_EXPIRE' name='SERVICE_EXPIRE' value='%SERVICE_EXPIRE%' placeholder='%SERVICE_EXPIRE%'
                           class='form-control datepicker d-0-20' rel='tcal' type='text'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-xs-4 col-md-3 col-form-label text-md-right' for='FILTER_ID'>_{FILTERS}_</label>
              <div class='col-xs-8 col-md-9'>
                <div class='input-group'>
                    <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                           class='form-control' type='text'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-xs-4 col-md-3 text-right' for='DETAIL_STATS'>_{DETAIL}_</label>
              <div class='col-xs-8 col-md-9'>
                <div class='form-check text-left'>
                  <input id='DETAIL_STATS' class='form-check-input' name='DETAIL_STATS' value='1' %DETAIL_STATS%
                           type='checkbox'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-xs-4 col-md-3 text-right' for='PERSONAL_TP'>_{PERSONAL}_ _{TARIF_PLAN}_</label>
              <div class='col-xs-8 col-md-9'>
                <div class='input-group'>
                  <input type='text' class='form-control r-0-25' id='PERSONAL_TP' name='PERSONAL_TP' value='%PERSONAL_TP%'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-xs-4 col-md-3'>$lang{MEMO}</label>
              <div class='input-group text-center col-xs-8 col-md-9'>
                %REGISTRATION_INFO%
                %REGISTRATION_INFO_PDF%
              </div>
            </div>

            %PASSWORD_FORM%
            %TURBO_MODE_FORM%

            <div class='form-group row'>
              <label class='col-form-label text-md-right col-xs-4 col-md-3' for='COMMENTS'>_{COMMENTS}_</label>
              <div class='col-xs-8 col-md-9'>
                <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%INTERNET_COMMENT%</textarea>
              </div>
            </div>
          </div>
        </div>
    <div class='card-footer'>
      %BACK_BUTTON%
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary double_click_check'/>
      %DEL_BUTTON%
    </div>
  </div>
</form>

<script src='/styles/default/js/jquery.maskedinput.min.js'></script>
<script src='/styles/default/js/modules/internet/internet-tariff-calculator.js'></script>
<script>
  const tariffCalculator = new TariffCalculator();

  jQuery(document).ready(() => {
    tariffCalculator.init().catch(error => {
      console.error('Failed to initialize TariffCalculator:', error);
    });
  });

  jQuery('#STATIC_IP_POOL').on('change', function () {
    let pool = jQuery(this);
    if (!pool.val()) return;

    jQuery.post('$SELF_URL', 'header=2&get_index=internet_ip_pool_check&PRINT_JSON=1&POOL_ID=' + pool.val(), function (data) {

      try {
        let json_data = JSON.parse(data);
        if (!json_data.status) return;

        jQuery('#select2-STATIC_IP_POOL-container').children().next().addClass(`text-${json_data.status}`)
      }
      catch (error) {
        console.log(error);
      }
    });
  });

  jQuery(function() {
    // CID
    var cid = document.getElementById("CID");
    var cid_value = cid.value;
    var cid_pattern = cid.pattern;
    var cid_any = document.getElementById("CID_ANY");

    if(cid_pattern){
      jQuery('#CID_BLOCK_ANY').removeClass('d-none');
    }

    if (cid_value == 'ANY' || cid_value == 'Any' || cid_value == 'any'){
      jQuery("#CID").unmask();
      cid_any.checked = true;
    }
    else {
      if (cid_pattern){
        jQuery("#CID").mask('%CID_MASK%');
        cid_any.checked = false;
      }
    }

    jQuery('#CID_ANY').on('click', function (event) {
      if (cid_any.checked == true){
        jQuery("#CID").unmask();
        cid.value = 'ANY';
      }
      else {
        jQuery("#CID").mask('%CID_MASK%');
        cid.value = cid_value || '';
      }
    });

    // CPE MAC
    var cpe = document.getElementById("CPE_MAC");
    var cpe_value = cpe.value;
    var cpe_pattern = cpe.pattern;
    var cpe_any = document.getElementById("CPE_ANY");

    if(cpe_pattern){
      jQuery('#CPE_BLOCK_ANY').removeClass('d-none');
    }

    if (cpe_value == 'ANY' || cpe_value == 'Any' || cpe_value == 'any'){
      jQuery("#CPE_MAC").unmask();
      cpe_any.checked = true;
    }
    else {
      if (cpe_pattern){
        jQuery("#CPE_MAC").mask('%CPE_MASK%');
        cpe_any.checked = false;
      }
    }

    jQuery('#CPE_ANY').on('click', function (event) {
      if (cpe_any.checked == true){
        jQuery("#CPE_MAC").unmask();
        cpe.value = 'ANY';
      }
      else {
        jQuery("#CPE_MAC").mask('%CPE_MASK%');
        cpe.value = cpe_value || '';
      }
    });
  });

</script>
