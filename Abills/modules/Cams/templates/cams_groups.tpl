<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='ID' value='%ID%'>
    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4>_{CAMERAS}_: _{GROUP}_</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3 required'>_{SERVICE}_</label>
                <div class='col-md-9'>
                    %SERVICES_SELECT%
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for="NAME">_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control' id="NAME" name='NAME' value='%NAME%'/>
                </div>
            </div>

            <div class='form-group'>
                <div class='col-md-1'></div>
                <div class='col-md-11'>%ADDRESS%</div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for="MAX_USERS">Max. _{USERS}_</label>
                <div class='col-md-9'>
                    <input type='number' class='form-control' id="MAX_USERS" name='MAX_USERS' value='%MAX_USERS%'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for="MAX_CAMERAS">Max. _{CAMERAS}_</label>
                <div class='col-md-9'>
                    <input type='number' class='form-control' id="MAX_CAMERAS" name='MAX_CAMERAS' value='%MAX_CAMERAS%'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for="COMMENT">_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <textarea class='form-control' rows='5' id="COMMENT" name='COMMENT'>%COMMENT%</textarea>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
        </div>
    </div>
</form>
