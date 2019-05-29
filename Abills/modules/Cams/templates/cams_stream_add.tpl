<form name='CAMS_STREAM_ADD' id='form_CAMS_STREAM_ADD' method='post' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='SERVICE_ID' value='%SERVICE_ID%'/>
    <input type='hidden' name='TP_ID' value='%TP_ID%'/>
    <input type='hidden' name='CAMS_TP_ID' value='%CAMS_TP_ID%'/>
    <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
    <div class='container-fluid'>
        <div class='row'>
            <div class='col-md-6'>
                <div class='box box-theme box-big-form'>
                    <div class='box-header with-border'>
                        <h4 class='box-title'>_{CAMERAS}_</h4>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                                <i class='fa fa-minus'></i>
                            </button>
                        </div>
                    </div>
                    <div class='box-body'>
                        <div class='form-group'>
                            <label class='control-label col-md-3 required'>_{CAMS_GROUP}_</label>
                            <div class='col-md-8'>
                                %GROUPS_SELECT%
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='OWNER_id'>_{OWNER}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' name='OWNER' value='%OWNER%' id='OWNER_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='TITLE_id'>_{CAM_TITLE}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' required='required' name='TITLE' value='%TITLE%'
                                       id='TITLE_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' required='required' name='NAME' value='%NAME%'
                                       id='NAME_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='HOST_id'>RTSP Host</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control'
                                       required='required' name='HOST' value='%HOST%' id='HOST_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='RTSP_PORT_id'>RTSP _{PORT}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control'
                                       required='required' name='RTSP_PORT' value='%RTSP_PORT%' id='RTSP_PORT_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>
                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='RTSP_PATH_id'>RTSP _{PATH}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control'
                                       required='required' name='RTSP_PATH' value='%RTSP_PATH%' id='RTSP_PATH_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <hr>

                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='LOGIN_id'>_{LOGIN}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' required='required' name='LOGIN' value='%LOGIN%'
                                       id='LOGIN_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3 required' for='PASSWORD_id'>_{PASSWD}_</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' required='required' name='PASSWORD'
                                       value='%PASSWORD%' id='PASSWORD_id'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <hr>

                        <div class='checkbox text-center'>
                            <label>
                                <input type='checkbox' %DISABLED_CHECKED% data-return='1' value='1' name='DISABLED'/>
                                <strong>_{DISABLED}_
                                    <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                                </strong>
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            <div class='col-md-6'>
                <div class='box collapsed-box box-theme box-big-form'>
                    <div class='box-header with-border'>
                        <h3 class='box-title'>_{OTHER}_</h3>
                        <div class='box-tools pull-right'>
                            <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                                <i class='fa fa-plus'></i>
                            </button>
                        </div>
                    </div>
                    <div class='box-body'>
                        <div class='form-group'>
                            <label class='control-label col-md-3' for='EXTRA_URL'>_{EXTRA}_ URL</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' name='EXTRA_URL' value='%EXTRA_URL%'
                                       id='EXTRA_URL'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3'>_{ORIENTATION}_</label>
                            <div class='col-md-8'>
                                %ORIENTATION_SELECT%
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3'>_{CAMS_ARCHIVE}_</label>
                            <div class='col-md-8'>
                                %ARCHIVE_SELECT%
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <div class='checkbox col-md-3 text-center'>
                                <label title="Tooltip on top">
                                    <input type='checkbox' %CONSTANTLY_WORKING% data-return='1' value='1' name='CONSTANTLY_WORKING'/>
                                    <strong>_{CONSTANTLY_WORKING}_
                                        <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                                    </strong>
                                </label>
                            </div>
                            <div class='checkbox col-md-3 text-center'>
                                <label>
                                    <input type='checkbox' %PRE_IMAGE% data-return='1' value='1' name='PRE_IMAGE'/>
                                    <strong>_{PRE_IMAGE}_
                                        <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                                    </strong>
                                </label>
                            </div>
                            <div class='checkbox col-md-3 text-center'>
                                <label>
                                    <input type='checkbox' %LIMIT_ARCHIVE% data-return='1' value='1' name='LIMIT_ARCHIVE'/>
                                    <strong>_{LIMIT_ARCHIVE}_
                                        <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                                    </strong>
                                </label>
                            </div>
                            <div class='checkbox col-md-3 text-center'>
                                <label>
                                    <input type='checkbox' %ONLY_VIDEO% data-return='1' value='1' name='ONLY_VIDEO'/>
                                    <strong>_{ONLY_VIDEO}_
                                        <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                                    </strong>
                                </label>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label class='control-label col-md-3'>_{PRE_IMAGE}_ URL</label>
                            <div class='col-md-8'>
                                <input type='text' class='form-control' name='PRE_IMAGE_URL' value='%PRE_IMAGE_URL%'
                                       id='PRE_IMAGE_URL'/>
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3'>_{SOUND}_</label>
                            <div class='col-md-8'>
                                %SOUND_SELECT%
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3'>_{TYPE_FOR_SERVICE}_</label>
                            <div class='col-md-8'>
                                %TYPE_SELECT%
                            </div>
                            <a href="#" data-toggle="tooltip" title=""><span class="glyphicon glyphicon-question-sign"></span></a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' form='form_CAMS_STREAM_ADD' class='btn btn-primary' name='submit'
                   value='%SUBMIT_BTN_NAME%'>
        </div>
    </div>
</form>

<script>
    $(document).ready(function(){
        $('[data-toggle="tooltip"]').tooltip();
    });
</script>