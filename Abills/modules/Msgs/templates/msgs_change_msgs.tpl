<form action='$SELF_URL' class='form-horizontal'>
    <input type=hidden name=index value='$index'>
    <input type=hidden name=MSGS_STATUS value='%MSGS_STATUS%'>
    <input type=hidden name=MSGS_STATUS_ID value='%MSGS_STATUS_ID%'>

    <div class='box box-theme box-form'>
        <div class='box-header'><h4 class='box-title'>_{MESSAGE}_ #%MSGS_STATUS%</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3' for='STATUS_SELECT'>_{STATUS}_:</label>
                <div class=' col-md-8'>
                    %STATUS_SELECT%
                </div>
            </div>
        </div>
    </div>


    <div class='box-footer'>
        <input type='submit' name='save_status' value='_{CHANGE}_' class='btn btn-primary'>
    </div>

</form>