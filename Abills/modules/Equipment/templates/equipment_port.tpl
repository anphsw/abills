<FORM action='$SELF_URL' METHOD='POST'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='$FORM{chg}'>
    <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>

    <div class='panel panel-primary panel-form center-block'>
        <div class='panel-heading'>
            <h4> _{PORT}_</h4>
        </div>
        <div class='panel-body'>

            <div class='form-group'>
                <label class='control-label col-md-5' for='PORT'>_{PORT}_:</label>

                <div class='col-md-3 control-element'>
                    <input type='text' name='PORT' value='%PORT%' class='form-control' ID='PORT'/>
                </div>
                <label class='control-label col-md-2' for='SNMP'>SNMP:</label>
                <div class='col-md-2 control-element'>
                    <input type='checkbox' name='SNMP' value=1 checked ID='SNMP'/>
                </div>

            </div>

            <div class='form-group'>
                <label class='control-label col-md-5' for='STATUS'>_{ADMIN}_ _{STATUS}_:</label>

                <div class='col-md-7 control-element'>
                    %STATUS_SEL%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-5' for='UPLINK'>UPLINK:</label>

                <div class='col-md-7 control-element'>
                    %UPLINK_SEL%
                </div>
            </div>


            <div class='form-group'>
                <label class='control-label col-md-5' for='COMMENTS'>_{DESCRIBE}_:</label>

                <div class='col-md-7 control-element'>
                    <input type='text' name='COMMENTS' value='%COMMENTS%' class='form-control' ID='COMMENTS'/>
                </div>
            </div>
        </div>
        <div class='panel-footer'>
            <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>
</FORM>

