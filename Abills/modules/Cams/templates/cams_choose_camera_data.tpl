<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='%index%'/>
    <input type='hidden' name='UID' value='%UID%'/>
    <input type='hidden' name='sid' value='%sid%'/>
    <div class='box box-theme'>
        <div class='box-header with-border'><h4>_{CAMS_ARCHIVE}_</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='col-md-1'>_{CAM}_:</label>
                <div class='col-md-4'>
                    %CAMS_SELECT%
                </div>
                <label class='col-md-1'>_{DATE}_:</label>
                <div class='col-md-4'>
                    %DATE_SELECT%
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' class='btn btn-primary' name='show_cameras' value='_{SHOW}_'>
        </div>
    </div>
</form>
