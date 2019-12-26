<div class='box box-theme collapsed-box %PARAMS%' form='internet_users_list'>
    <div class='box-header with-border'>
        <h4 class='box-title'>_{MULTIUSER_OP}_</h4>
        <div class='box-tools pull-right'>
            <button type='button' id='mu_status_box_btn' class='btn btn-default btn-xs' data-widget='collapse'><i
                    class='fa fa-plus'></i>
            </button>
        </div>
    </div>

    <div class=' box-body' id='daasd'>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    %MU_STATUS_CHECKBOX%
                    _{STATUS}_
                </div>
                <div class='col-md-8'>
                    %MU_STATUS_SELECT%
                </div>
            </div>
        </div>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    %MU_TP_CHECKBOX%
                    _{TARIF_PLAN}_
                </div>
                <div class='col-md-8'>
                    %MU_TP_SELECT%
                </div>
            </div>
        </div>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    <input type='checkbox' name='MU_CREDIT' value='1' form='internet_users_list' id='MU_CREDIT'>
                    _{CREDIT}_
                </div>
                <div class='col-md-4'>
                    <input class='form-control' type='number' name='MU_CREDIT_SUM' form='internet_users_list'
                           id='MU_CREDIT_SUM' step='0.01'>
                </div>
                <div class='col-md-1'>
                    <label class='control-label' style='padding-top: 5px;'>_{TO}_</label>
                </div>
                <div class='col-md-3'>
                    %MU_CREDIT_DATEPICKER%
                </div>
            </div>
        </div>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    %MU_DATE_CHECKBOX%
                    _{EXPIRE}_
                </div>
                <div class='col-md-8'>
                    %MU_DATE%
                </div>
            </div>
        </div>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    <input type='checkbox' name='MU_REDUCTION' value='1' form='internet_users_list' id='MU_REDUCTION'>
                    _{REDUCTION}_(%)
                </div>
                <div class=' col-xs-4 col-md-4'>
                    <input id='MU_REDUCTION_SUM' name='MU_REDUCTION_SUM' class='form-control' form='internet_users_list'
                           type='number' min='0' max='100' value='%MU_REDUCTION_SUM%' step='0.01'>
                </div>
                <label class='control-label col-md-1 col-xs-1' for='MU_REDUCTION_DATE'>_{TO}_</label>
                <div class='col-md-3 col-xs-3'>
                    <input id='MU_REDUCTION_DATE' name='MU_REDUCTION_DATE' form='internet_users_list'
                           class='datepicker form-control' type='text' value='0000-00-00'>
                </div>
            </div>
        </div>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    <input type='checkbox' name='MU_ACTIVATE' value='1' form='internet_users_list' id='MU_ACTIVATE'>
                    _{ACTIVATE}_
                </div>
                <div class='col-md-4'>
                    <input id='MU_ACTIVATE_DATE' name='MU_ACTIVATE_DATE' value='0000-00-00'
                            form='internet_users_list' class='form-control datepicker' type='text'>
                </div>
            </div>
        </div>

        <div class='form-group' %IPV6_HIDE%>
            <div class='row'>
                <div class='col-md-4'>
                    <input type='checkbox' name='MU_SET_IPV6' value='1' form='internet_users_list' id='MU_SET_IPV6'>
                    _{SET}_ _{STATIC}_ IPv6
                </div>
                <div class='col-md-4'>
                    %MU_IPV6_POLL_SEL%
                </div>
            </div>
        </div>

        <div class='form-group'>
            <div class='row'>
                <div class='col-md-4'>
                    <input type='checkbox' name='MU_SET_IPV4' value='1' form='internet_users_list' id='MU_SET_IPV4'>
                    _{SET}_ _{STATIC}_ IPv4
                </div>
                <div class='col-md-4'>
                    %MU_IPV4_POLL_SEL%
                </div>
            </div>
        </div>
        <input name='INTERNET_MULTIUSER' form='internet_users_list' value='_{ACCEPT}_' class='btn btn-primary' type='submit'>
    </div>
</div>
</form>