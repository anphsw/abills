<form action=%SELF_URL% METHOD=POST>

    <input type='hidden' name='index' value=%index%>
    <input type='hidden' name='UID' value=%UID%>

    <div class='card card-primary card-outline card-big-form for_sort container-md'>
        <div class='card-header with-border'>
            <h4 class='card-title'>3Play</h4></div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-xs-4 col-md-2 col-form-label text-md-right' for='TP'>_{TARIF_PLAN}_:</label>
                <div class='col-xs-8 col-md-10'>
                    <div class='input-group'>
                        %TP_ADD%
                        <div class='input-group' %TP_DISPLAY_NONE%>
                            <div class='input-group-prepend'>
                                <div class='input-group-text'>
                                    <span class='hidden-xs'>%TP_NUM%</span>
                                </div>
                            </div>
                            <input type='text' name='GRP' value='%TP_NAME% %DESCRIBE_AID%' ID='TP' class='form-control hidden-xs' %TARIF_PLAN_TOOLTIP% readonly>
                            <div class='input-group-append'>
                                %CHANGE_TP_BUTTON%
                                <a class='btn input-group-button hidden-print px-3' title='_{PAY_TO}_'
                                   href='%SELF_URL%?index=%index%&UID=%UID%&ID=%ID%&pay_to=1'>
                                    <i class='$conf{CURRENCY_ICON}'></i>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
                <div class='col-md-12'>%PERSONAL_TP_MSG%</div>
            </div>

            <div class='form-group row' style='background-color: %STATUS_COLOR%'>
                <label class='col-md-2 control-label'>_{STATUS}_</label>
                <div class='col-md-10'>
                    %STATUS_SEL%
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-2 control-label' for='EXPIRE'>_{EXPIRE}_</label>
                <div class='col-md-10'>
                    <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                           class='form-control datepicker' rel='tcal' type='text'>
                </div>
            </div>
        </div>

        %SERVICES_INFO%

        <div class='card mb-0 card-outline border-top card-big-form collapsed-card'>
            <div class='form-group'>
                <label for='COMMENTS' class='col-md-12'>
                    <span class='col'>_{COMMENTS}_:</span>
                </label>

                <div class='col-md-12'>
                    <textarea rows='5' cols='100' name='COMMENTS' class='form-control' id='COMMENTS'>%COMMENTS%</textarea>
                </div>

            </div>

        </div>

        <div class='card-footer'>

            %BACK_BUTTON%
            <input type='submit' class='btn btn-primary double_click_check' name='%ACTION%'  value='%ACTION_LNG%'>
            %DEL_BUTTON%
        </div>

    </div>

</form>