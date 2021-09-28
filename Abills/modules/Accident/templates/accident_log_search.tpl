<form action='$SELF_URL' method='GET' class='form-horizontal container-md' id='ACCIDENT_LOG'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='search' value='1'>

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{ADDRESS}_</h4>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-md-4 col-sm-4'>_{PRIORITY}_:</label>
                <div class='col-md-8 col-sm-8'>
                    %SELECT_PRIORITY%
                </div>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-4 col-sm-4'>_{STATUS}_:</label>
                <div class='col-md-8 col-sm-8'>
                    %SELECT_STATUS%
                </div>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-4 col-sm-4'>_{ADMIN}_:</label>
                <div class='col-md-8 col-sm-8'>
                    %SELECT_ADMIN%
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 control-label' for='REGISTRATION'>_{DATE}_:</label>
                <div class='col-md-8'>
                    <div class='input-group'>
                        <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' class='form-control-static' data-input-enables='FROM_DATE_TO_DATE'/>
              </span>
                        </div>
                        %DATE_PCIKER%
                    </div>
                </div>
            </div>

                %SELECT_ADDRESS%
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' name='search' value='_{SEARCH}_'>
        </div>
    </div>
</form>

