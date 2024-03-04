<form action='%SELF_URL%' METHOD=POST class='form-horizontal'>
    <input type='hidden' name='index' value=$index>
    <input type='hidden' name='search_form' value='1'>

    <div class='card card-primary card-outline box-form container-md'>

        <div class='card-header with-border'><h4 class='card-title'>_{FILTERS}_</h4></div>

        <div class='card-body'>
            <div class='form-group row' data-visible='%STATUS_VISIBILITY%'>
                <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_</label>
                <div class='col-md-8'>
                    %STATUS_SELECT%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-form-label text-md-right'>_{ADMIN}_</label>
                <div class='col-md-8'>
                    %ADMINS_SELECT%
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-form-label text-md-right' for='DATE_START'>_{DATE}_ _{BEGIN}_</label>
                <div class='col-md-8'>
                    <input type='text' name='DATE_START' id='DATE_START' value='%DATE_START%' placeholder='%TIME_START%'
                           class='form-control datepicker'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 col-form-label text-md-right' for='DATE_END'>_{DATE}_ _{END}_</label>
                <div class='col-md-8'>
                    <input type='text' name='DATE_END' id='DATE_END' value='%DATE_END%' placeholder='%TIME_END%'
                           class='form-control datepicker'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 col-form-label text-md-right' for='ID'>ID</label>
                <div class='col-md-8'>
                    <input type='text' name='ID' id='ID' value='%ID%' placeholder='%ID%'
                           class='form-control'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 col-form-label text-md-right' for='CALL_PHONE'>_{PHONE}_</label>
                <div class='col-md-8'>
                    <input type='text' name='CALL_PHONE' id='CALL_PHONE' value='%CALL_PHONE%' placeholder='%CALL_PHONE%'
                           class='form-control'>
                </div>
            </div>

            <!--
            <div class='form-group row'>
                <label class='control-label col-md-3' for='OPERATOR_PHONE'>OPERATOR_PHONE</label>
                <div class='col-md-9'>
                    <input type='text' name='OPERATOR_PHONE' id='OPERATOR_PHONE' value='%OPERATOR_PHONE%' placeholder='%OPERATOR_PHONE%'
                           class='form-control'>
                </div>
            </div>
-->

        </div>

        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='search' value='_{FILTER}_'>
            <a href='%SELF_URL%?index=$index&refresh=1' type='button' class='btn btn-success'
               data-tooltip='_{FILLING_DATA}_' data-visible='%REFRESH_VISIBILITY%'>
                <span class='fas fa-sync' aria-hidden='true'></span>
            </a>
        </div>
    </div>
</form>

%CHART%