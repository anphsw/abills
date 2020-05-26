<form action='$SELF_URL' method='POST' class='form-horizontal' id='ACCIDENT_LOG'>
    <input type="hidden" name="index" value="%INDEX%">
    <input type="hidden" name="search" value="1">

    <div class='box box-theme box-form'>
        <div class='box-header with-border'>
            <h4 class='box-title'>_{ADDRESS}_</h4>
        </div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{PRIORITY}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %SELECT_PRIORITY%
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{STATUS}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %SELECT_STATUS%
                </div>
            </div>
            <div class="form-group">
                <label class="control-label col-md-4 col-sm-3">_{ADMIN}_:</label>
                <div class="col-md-8 col-sm-9">
                    %SELECT_ADMIN%
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4 col-sm-3'>_{DATE}_:</label>
                <div class='col-md-8 col-sm-9'>
                    %DATE_PCIKER%
                </div>
            </div>
                %SELECT_ADDRESS%
            <input class='btn btn-primary col-md-12 col-sm-12' type='submit' name="search" value='_{SEARCH}_'>
        </div>
    </div>
</form>

