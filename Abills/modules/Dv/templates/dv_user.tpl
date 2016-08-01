%MENU%

<!-- STATUS COLOR -->
<style>
  .alert-%STATUS% {
    /*color : %STATUS_COLOR%;*/

    background-image: -webkit-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    background-image: -o-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    background-image: -webkit-gradient(linear, left top, left bottom, from(%STATUS_COLOR_GR_S%), to(%STATUS_COLOR_GR_F%));
    background-image: linear-gradient(to bottom, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
    filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='%STATUS_COLOR_GR_S%', endColorstr='%STATUS_COLOR_GR_F%', GradientType=0);
    background-repeat: repeat-x;
    border-color: %STATUS_COLOR%;

  }
</style>

<form class='form-horizontal' action='$SELF_URL' method='post'>

    <input type=hidden name='index' value='$index'>
    <input type=hidden name='UID' value='$FORM{UID}'>
    <input type=hidden name='STATUS_DAYS' value='%STATUS_DAYS%'>
    <input type=hidden name='step' value='$FORM{step}'>

    <div class='panel panel-default'>
        <div class='panel-body'>
            %ONLINE_TABLE%
            %PAYMENT_MESSAGE%

            %NEXT_FEES_WARNING%

            %LAST_LOGIN_MSG%

            <div class='row'>
                <div class='col-md-6'>
                    <div class='panel panel-default panel-form'>
                        <div class='panel-heading'>
                            <a data-toggle='collapse' data-parent='#accordion' href='#_main'>_{MAIN}_</a>
                        </div>
                        <div id='_main' class='panel-body panel-collapse collapse in'>
                            %LOGIN_FORM%
                            <div class='form-group'>
                                <label class='control-label col-md-3 pull-left' for='TP'>_{TARIF_PLAN}_</label>
                                <div class='col-md-9'>
                                    %TP_ADD%
                                    <div class='input-group'>
                                        <span class='input-group-addon bg-primary'>%TP_ID%</span>
                                        <input type=text name='GRP' value='%TP_NAME%' ID='TP' class='form-control'
                                               readonly>
                                        <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
                                        <span class='input-group-addon'><a
                                                href='$SELF?index=$index&UID=$FORM{UID}&pay_to=1'
                                                class='$conf{CURRENCY_ICON}' title='_{PAY_TO}_'></a></span>
                                    </div>
                                </div>
                                <div class='col-md-12'>%PERSONAL_TP_MSG%</div>
                            </div>

                            <div class='form-group alert alert-%STATUS%'>
                                <label class='control-label col-md-3'>_{STATUS}_</label>
                                <div class='col-md-9'>
                                    <div class='input-group'>
                                        %STATUS_SEL%
                                        <span class='input-group-addon'>%SHEDULE%</span>
                                    </div>
                                    <div class='row text-center'>
                                        <strong>%STATUS_INFO%</strong>
                                    </div>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3'>_{STATIC}_ IP Pool</label>
                                <div class='col-md-9'>
                                    %STATIC_IP_POOL%
                                </div>
                            </div>

                            <div class='form-group form-group-sm'>
                                <label class='control-label col-md-3' for='IP'>_{STATIC}_ IP</label>
                                <div class='col-md-4'>
                                    <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control'
                                           type='text'>
                                </div>

                                <label class='control-label col-md-1' for='NETMASK'>MASK</label>
                                <div class='col-md-4 %NETMASK_COLOR%'>
                                    <input id='NETMASK' name='NETMASK' value='%NETMASK%' placeholder='%NETMASK%'
                                           class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='CID'>CID (_{DELISMITER}_ ;)</label>
                                <div class='col-md-9'>
                                    <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control'
                                           type='text'>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class='col-md-6'>

                    <div class='panel panel-default panel-form'>
                        <div class='panel-heading'>
                            <a data-toggle='collapse' data-parent='#accordion' href='#_dv_other'>_{OTHER}_</a>
                        </div>
                        <div id='_dv_other' class='panel-body panel-collapse collapse out'>


                            <div class='form-group'>
                                <label class='control-label col-md-3' for='SPEED'>_{SPEED}_ (kb)</label>
                                <div class='col-md-3'>
                                    <input id='SPEED' name='SPEED' value='%SPEED%' placeholder='%SPEED%'
                                           class='form-control' type='text'>
                                </div>

                                <label class='control-label col-md-3' for='LOGINS'>_{SIMULTANEOUSLY}_</label>
                                <div class='col-md-3'>
                                    <input id='LOGINS' type='text' name='LOGINS' value='%LOGINS%' class='form-control'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
                                <div class='col-md-9 %EXPIRE_COLOR%'>
                                    <input id='EXPIRE' name='DV_EXPIRE' value='%DV_EXPIRE%' placeholder='%DV_EXPIRE%'
                                           class='form-control tcal' rel='tcal' type='text'>
                                </div>
                            </div>


                            <div class='form-group'>
                                <label class='control-label col-md-3' for='FILTER_ID'>_{FILTERS}_</label>
                                <div class='col-md-9'>
                                    <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                                           class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='PORT'>_{PORT}_</label>
                                <div class='col-md-3'>
                                    <input id='PORT' name='PORT' value='%PORT%' placeholder='%PORT%'
                                           class='form-control' type='text'>
                                </div>


                                <label class='control-label col-md-3' for='CALLBACK'>Callback</label>
                                <div class='col-md-2'>
                                    <input id='CALLBACK' type='checkbox' name='LOGINS' value='1' %CALLBACK%>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='DETAIL_STATS'>_{DETAIL}_</label>
                                <div class='col-md-9'>
                                    <input id='DETAIL_STATS' name='DETAIL_STATS' value='1' %DETAIL_STATS%
                                           type='checkbox'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3 pull-left'>_{PERSONAL}_ _{TARIF_PLAN}_</label>
                                <div class='col-md-9'>
                                    <input type='text' class='form-control' name='PERSONAL_TP' value='%PERSONAL_TP%'>
                                </div>
                            </div>

                            <!--      <div class='form-group'>
                                    <div class='col-md-12'></div>
                                  </div>
                            -->
                            %TURBO_MODE_FORM%

                        </div>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='col-sm-offset-2 col-sm-8'>
                        %REGISTRATION_INFO% %REGISTRATION_INFO_PDF% %PASSWORD_BTN%
                    </label>
                </div>

                %DEL_FORM%

                <div class='form-group'>
                    <div class='col-sm-offset-2 col-sm-8'>
                        %BACK_BUTTON%
                        <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
                    </div>
                </div>

            </div>
        </div>
    </div>

</form>

