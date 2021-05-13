<script src='/styles/default_adm/js/modules/equipment.js'></script>

<FORM action='$SELF_URL' METHOD='POST' class='form-horizontal' id='EQUIPMENT_MODEL_INFO_FORM'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='$FORM{chg}'>
  <input type='hidden' name='chg' value='$FORM{chg}'>
  <input type='hidden' name='HAS_EXTRA_PORTS' id='HAS_EXTRA_PORTS'>

    <div class='card card-primary card-outline container col-md-6'>
      <div class='card-header with-border'>
        <h4 class="card-title">_{EQUIPMENT}_ _{INFO}_</h4>
      </div>
      <div class='card-body'>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='TYPE_ID'>_{TYPE}_</label>
          <div class='col-sm-10' style="padding-right: 65px;">
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='VENDOR_ID'>_{VENDOR}_</label>
          <div class='col-sm-10' style="padding-right: 65px;">
            %VENDOR_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='MODEL_NAME'>_{MODEL}_</label>
          <div class='col-sm-10'>
            <input type=text class='form-control' id='MODEL_NAME' placeholder='%MODEL_NAME%'
              name='MODEL_NAME' value='%MODEL_NAME%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='TEST_FIRMWARE'>_{FIRMWARE}_</label>
          <div class='col-sm-10'>
            <input type=text class='form-control' id='TEST_FIRMWARE' placeholder='%TEST_FIRMWARE%' name='TEST_FIRMWARE'
              value='%TEST_FIRMWARE%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='SITE'>URL</label>
          <div class='col-sm-10'>
            <div class="input-group">
              <input class='form-control' type='text' id='SITE' name='SITE' value='%SITE%'>
              <div class="input-group-append">
                <div class='input-group-text'>
                  <a title='_{GO}_' href='%SITE%' target='%SITE%'>_{GO}_</a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='ELECTRIC_POWER'>_{ELECTRIC_POWER}_</label>
          <div class='col-sm-10'>
            <input type=number class='form-control' id='ELECTRIC_POWER' placeholder='%ELECTRIC_POWER%'
              name='ELECTRIC_POWER' value='%ELECTRIC_POWER%'>
          </div>
        </div>

        <div class='card box-default collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{MANAGE}_</h3>
            <div class='card-tools pull-right'>
              <button type='button' class='btn btn-box-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='MANAGE_WEB'>WEB</label>
              <div class='col-sm-10'>
                <input class='form-control' type='text' id='MANAGE_WEB' name='MANAGE_WEB' value='%MANAGE_WEB%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='MANAGE_SSH'>telnet/ssh</label>
              <div class='col-sm-10'>
                <input class='form-control' type='text' name='MANAGE_SSH' id='MANAGE_SSH' value='%MANAGE_SSH%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='SNMP_TPL'>_{SNMP_SURVEY}_</label>
              <div class='col-sm-10'>
                %SNMP_TPL_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='SYS_OID'>SYSTEM_OID</label>
              <div class='col-sm-10'>
                <input class='form-control' type='text' id='SYS_OID' name='SYS_OID' value='%SYS_OID%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='COMMENTS'>_{COMMENTS}_</label>
              <div class='col-sm-10'>
                <textarea class='form-control' name='COMMENTS' id='COMMENTS' rows='6'
                  cols='50'>%COMMENTS%</textarea>
              </div>
            </div>

          </div>
        </div>


        <div class='card box-default collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{PORTS}_</h3>
            <div class='card-tools pull-right'>
              <button type='button' class='btn btn-box-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='PORT_SHIFT'>_{PORT_SHIFT}_ SNMP</label>
              <div class='col-sm-10'>
                <input class='form-control' type='number' min='0' id='PORT_SHIFT' name='PORT_SHIFT'
                  value='%PORT_SHIFT%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='AUTO_PORT_SHIFT'>_{USE_AUTO_PORT_SHIFT}_ SNMP</label>
              <div class='col-sm-10'>
                <input type='checkbox' name='AUTO_PORT_SHIFT' value=1 %AUTO_PORT_SHIFT% ID='AUTO_PORT_SHIFT'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='FDB_USES_PORT_NUMBER_INDEX'>_{FDB_USES_PORT_NUMBER_INDEX}_</label>
              <div class='col-sm-10'>
                <input type='checkbox' name='FDB_USES_PORT_NUMBER_INDEX' value=1 %FDB_USES_PORT_NUMBER_INDEX% ID='FDB_USES_PORT_NUMBER_INDEX'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='PORTS'>_{COUNT}_</label>
              <div class='col-sm-10'>
                <input class='form-control' type='number' min='1' id='PORTS' name='PORTS' value='%PORTS%'>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='PORTS_TYPE'>_{PORTS}_ _{TYPE}_</label>
              <div class='col-sm-10'>
                %PORTS_TYPE_SELECT%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='ROWS_COUNT_id'>_{ROWS}_</label>
              <div class='col-sm-10'>
                <input type='number' min='1' class='form-control' name='ROWS_COUNT' value='%ROWS_COUNT%'
                  id='ROWS_COUNT_id'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='BLOCK_SIZE_id'>_{IN_BLOCK}_</label>
              <div class='col-sm-10'>
                <input type='number' min='1' class='form-control' name='BLOCK_SIZE' value='%BLOCK_SIZE%'
                  id='BLOCK_SIZE_id'/>
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='PORT_NUMBERING'>_{PORT_NUMBERING}_</label>
              <div class='col-sm-10'>
                %PORT_NUMBERING_SELECT%
              </div>
            </div>

            <div class='form-group row'>
              <label  class='col-sm-2 col-form-label' for='FIRST_POSITION'>_{FIRST_PORT_POSITION}_</label>
              <div class='col-sm-10'>
                %FIRST_POSITION_SELECT%
              </div>
            </div>

            <div id='extraPortWrapper'>

              <div id='templateWrapper'>
                <div class='form-group row'>
                  <label  class='col-sm-2 col-form-label' for='EXTRA_PORT'>_{EXTRA}_ _{PORT}_</label>
                  <div class='col-sm-10'>
                    %EXTRA_PORT1_SELECT%
                  </div>
                </div>
              </div>
            </div>

            <div class='form-group' id='extraPortControls' style='margin-right: 15px;'>
              <div class='text-right'>
                <div class='btn-group btn-group-xs'>
                  <button class='btn btn-xs btn-danger' id='removePortBtn'
                      data-tooltip='_{DEL}_ _{PORT}_'
                      data-tooltip-position='bottom'>
                    <span class='fa fa-remove'></span>
                  </button>
                  <button class='btn btn-xs btn-success' id='addPortBtn'
                      data-tooltip='_{ADD}_ _{PORT}_'>
                    <span class='fa fa-plus'></span>
                  </button>
                </div>
              </div>
            </div>

          </div>

        </div>

        <div class='card box-default collapsed-card disabled' id='equipmentModelPon' %EQUIPMENT_MODEL_PON_HIDDEN%>
          <div class='card-header with-border'>
            <h3 class='card-title'>PON</h3>
            <div class='card-tools pull-right'>
              <button type='button' class='btn btn-box-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-md-4 col-form-label' for='EPON_SUPPORTED_ONUS'>_{NUMBER_OF_SUPPORTED_ONUS_ON_BRANCH_FOR}_ EPON</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min=0 id='EPON_SUPPORTED_ONUS' name='EPON_SUPPORTED_ONUS' value='%EPON_SUPPORTED_ONUS%' %EQUIPMENT_MODEL_PON_DISABLED%>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label' for='GPON_SUPPORTED_ONUS'>_{NUMBER_OF_SUPPORTED_ONUS_ON_BRANCH_FOR}_ GPON</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min=0 id='GPON_SUPPORTED_ONUS' name='GPON_SUPPORTED_ONUS' value='%GPON_SUPPORTED_ONUS%' %EQUIPMENT_MODEL_PON_DISABLED%>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label' for='GEPON_SUPPORTED_ONUS'>_{NUMBER_OF_SUPPORTED_ONUS_ON_BRANCH_FOR}_ GEPON</label>
              <div class='col-md-8'>
                <input class='form-control' type='number' min=0 id='GEPON_SUPPORTED_ONUS' name='GEPON_SUPPORTED_ONUS' value='%GEPON_SUPPORTED_ONUS%' %EQUIPMENT_MODEL_PON_DISABLED%>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='card-footer'>
        <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
      </div>
    </div>

  <div class='card card-primary card-outline' id='ports_preview'>
    <div class='card-body'>
      %PORTS_PREVIEW%
    </div>
  </div>


  %EX_INFO%

</FORM>


