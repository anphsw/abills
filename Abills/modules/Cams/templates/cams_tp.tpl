<div class='noprint' id='CAMS'>
    <form name='CAMS_USER_ADD' id='form_CAMS_USER_ADD' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='ID' value='%ID%'/>
        <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

        <div class='box box-theme box-form'>
            <div class='box-header with-border'>
                <h4 class='box-title'>_{TARIF_PLAN}_ #%ID%</h4>
            </div>

            <div class='box-body form form-horizontal'>

                <div class='form-group'>
                    <label class='control-label col-md-3 required' for='SERVICE'>_{SERVICE}_</label>
                    <div class='col-md-9'>
                        %SERVICE_TP%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_ TP</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id'/>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3 required' for='STREAMS_COUNT_id'>_{MAX}_
                        _{STREAMS_COUNT}_</label>
                    <div class='col-md-9'>
                        <input type='text' class='form-control' required name='STREAMS_COUNT' value='%STREAMS_COUNT%'
                               id='STREAMS_COUNT_id'/>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
                    <div class='col-md-9'>
                        <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
                    </div>
                </div>


                <div class='form-group'>

                    <div class='box collapsed-box box-theme box-big-form'>
                        <div class='box-header with-border text-center'>
                            <h3 class='box-title'>_{ABON}_</h3>
                            <div class='box-tools pull-right'>
                                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                                    <i class='fa fa-plus'></i>
                                </button>
                            </div>
                        </div>

                        <div class='box-body'>

                            <div class='form-group'>
                                <label class='col-md-3'>_{MONTH_FEE}_:</label>
                                <div class='col-md-9'><input type=text name='MONTH_FEE' value='%MONTH_FEE%'
                                                             class='form-control'></div>
                            </div>

                            <div class='form-group'>
                                <label class='col-md-3'>_{PAYMENT_TYPE}_:</label>
                                <div class='col-md-9'>%PAYMENT_TYPE_SEL%</div>
                            </div>
                        </div>
                    </div>
                </div>


                <div class='form-group'>

                    <div class='box collapsed-box box-theme box-big-form'>
                        <div class='box-header with-border text-center'>
                            <h3 class='box-title'>_{OTHER}_</h3>
                            <div class='box-tools pull-right'>
                                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                                    <i class='fa fa-plus'></i>
                                </button>
                            </div>
                        </div>

                        <div class='box-body'>
                            <div class='form-group'>
                                <label class='col-md-3 control-label'>_{ACTIVATE}_:</label>
                                <div class='col-md-9'>
                                    <input type='number' name='ACTIV_PRICE' value='%ACTIVATE_PRICE%'
                                           class='form-control'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='col-md-3 control-label'>_{CHANGE}_:</label>
                                <div class='col-md-9'>
                                    <input type='number' name='CHANGE_PRICE' value='%CHANGE_PRICE%'
                                           class='form-control'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='col-md-3 control-label'>DVR:</label>
                                <div class='checkbox col-md-3'>
                                    <label>
                                        <input type='checkbox' name='DVR' value='1' %DVR%>
                                    </label>
                                </div>
                                <label class='col-md-3 control-label'>PTZ:</label>
                                <div class='checkbox col-md-3'>
                                    <label>
                                        <input type='checkbox' name='PTZ' value='1' %PTZ%>
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
            <div class='box-footer'>
                <input type='submit' form='form_CAMS_USER_ADD' id='go' class='btn btn-primary' name='submit'
                       value='%SUBMIT_BTN_NAME%'>
            </div>
        </div>

    </form>
</div>