<FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='VENDOR' value='$FORM{VENDOR}'>
    <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
    <input type='hidden' name='TYPE' value='$FORM{TYPE}'>
    <input type='hidden' name='BRANCH' value='$FORM{BRANCH}'>
    <input type='hidden' name='MAC_SERIAL' value='$FORM{MAC_SERIAL}'>
    <input type='hidden' name='visual' value='$FORM{visual}'>
    <input type='hidden' name='unregister' value='$FORM{unregister}'>
    <input type='hidden' name='register' value='$FORM{register}'>

    <div class='box box-theme box-form center-block'>
        <div class='box-header with-border'>
            <h3 class="box-title"> _{REGISTRATION}_ ONU</h3>
        </div>
        <div class='box-body'>

            <div class='form-group'>
                <label class='control-label col-md-5' for='LINE_PROFILE'>Line-Profile:</label>

                <div class='col-md-7 control-element'>
                    %LINE_PROFILE_SEL%
                </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for='SRV_PROFILE'>Srv-Profile:</label>

                <div class='col-md-7 control-element'>
                    %SRV_PROFILE_SEL%
                </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group' id='VLAN_SEL_DIV'>
                <label class='control-label col-md-5' for='VLAN'>VLAN:</label>

                <div class='col-md-7 control-element'>
                    %VLAN_SEL%
                </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for=''>Branch:</label>

                <div class='col-md-7 control-element'>
                     $FORM{UC_TYPE} %BRANCH%
                </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for=''>Mac_Serial:</label>

                <div class='col-md-7 control-element'>
                     %MAC_SERIAL%
                </div>
            </div>
            <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
            <div class='form-group'>
                <label class='control-label col-md-5' for='COMMENTS'>_{DESCRIBE}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='ONU_DESC' value='' class='form-control' ID='ONU_DESC'/>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>
    <script type='text/javascript'>
        jQuery(document).ready(function () {
  
            var vlan_sel_div = jQuery('div#VLAN_SEL_DIV');
            var vlan_select  = jQuery('select#VLAN_ID');
  
            jQuery('select#LINE_PROFILE').change(function () {
                if (jQuery('select#LINE_PROFILE').val() === '$FORM{DEF_LINE_PROFILE}') {
                    vlan_sel_div.show();
                    vlan_select.attr('name', 'VLAN_ID');
                }
                else {
                    vlan_sel_div.hide()
                    vlan_select.attr('name', 'VLAN_ID_HIDE');
                }
            });
        });
    </script>
</FORM>

