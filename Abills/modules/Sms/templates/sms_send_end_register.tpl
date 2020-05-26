<form action='$SELF_URL' method='POST' class='form-horizontal' id='SEND_SMS_REGISTRATION'>
    <input type="hidden" name="index" value="%INDEX%">
    <input type="hidden" name="REGISTRATION_INFO_SMS" value="%REGISTRATION_INFO_SMS%">
    <input type="hidden" name="UID" value="%UID%">
    <input type="hidden" name="sms" value="%sms%">
    <input type="hidden" name="step" value="%step%">
    <input type='hidden' name='LEAD_ID' value='$FORM{LEAD_ID}'>

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <h4 class='box-title'>SMS</h4>
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>UID:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' value='%UID%' placeholder='UID'
                           class='form-control' %READONLY%>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{USER}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' name='LOGIN' value='%USER%' placeholder='_{USER}_'
                           class='form-control' %READONLY%>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3 required'>_{PHONE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input type='text' name='PHONE' value='%PHONE%' placeholder='_{PHONE}_'
                           class='form-control' required>
                </div>
            </div>
            <div class='box-footer'>
                %BACK_BUTTON%
                <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
            </div>
        </div>
    </div>
</form>
