<form action='%SELF_URL%' method='post' name=pay_to>

    <input type=hidden name='index' value='%index%'>
    <input type=hidden name='UID' value='%UID%'>
    <input type=hidden name='SUM' value='%SUM%'>
    <input type=hidden name='DEBUG' value='%DEBUG%'>

    <div class='card card-primary card-outline card-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{PAY_TO}_</h4>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
                <div class='col-md-9'>
                    <input id='DATE' name='DATE' value='%DATE%' data-date-orientation='bottom' placeholder='%DATE%'
                           class='form-control datepicker' type='text' %DATE_READONLY%>
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3' for='DATE'>_{DAYS}_</label>
                <div class='col-md-9'>
                    %DAYS% _{REDUCTION}_: %DISCOUNT_DAYS%
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3' for='DATE'>_{MONTH}_</label>
                <div class='col-md-9'>
                    %MONTHES% _{REDUCTION}_: %DISCOUNT_MONTHES%
                </div>
            </div>

            <!--
            <div class='form-group' data-visible='%SUM%'>
                <label class='control-label col-md-3' for='SUM'>_{SUM}_</label>
                <div class='col-md-9'>
                    <h4>
                        <span class='label label-primary  col-md-3' id='SUM'>%SUM%</span>
                    </h4>
                </div>
            </div>

            <div class='form-group' data-visible='%SUM%'>
                <label class='control-label col-md-3' for='DAYS'>_{DAYS}_</label>
                <div class='col-md-9'>
                    <h4>
                        <label class='label label-success  col-md-3' id='DAYS'>%DAYS%</label>
                    </h4>
                </div>
            </div>
        -->
            <div class='form-group' data-visible='%SUM%'>
                <div class='col-md-12 text-center'>
                   %PAY_LINK%
                </div>
            </div>

        </div>

        <div class='card-footer'>
            <input type=submit name='pay_to' value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

    </div>

</form>
