<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='UID' value='$FORM{UID}'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='PARENT' value='%PARENT%'/>
    <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
    <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

    <div class='table'>
        <div class='col-md-9' id='reply_wrapper' style='margin-top: 15px;'>

            <div class='panel panel-default %MAIN_PANEL_COLOR%'>
                <div class='panel-heading'>
                    <div class='panel-title'> %SUBJECT%</div>
                </div>
                <div class='panel-body'>
                        <div class='row'>
                            <div class='col-md-3 text-left'><strong>#:</strong></div>
                            <div class='col-md-3 text-left'><span class='badge %MAIN_PANEL_COLOR%'>%ID%</span></div>

                            <div class='col-md-3 text-left'><strong>_{CHAPTERS}_:</strong></div>
                            <div class='col-md-3 text-left'>%CHAPTER_NAME%</div>
                        </div>

                        <div class='row'>
                            <div class='col-md-3 text-left'><strong>_{STATUS}_:</strong></div>
                            <div class='col-md-3 text-left'>%STATE_NAME%</div>

                            <div class='col-md-3 text-left'><strong>_{PRIORITY}_:</strong></div>
                            <div class='col-md-3 text-left'>%PRIORITY_TEXT%</div>
                        </div>

                        <div class='row'>
                            <div class='col-md-3 text-left'><strong>_{CREATED}_:</strong></div>
                            <div class='col-md-3 text-left'>%DATE%</div>

                            <div class='col-md-3 text-left'><strong>_{UPDATED}_:</strong></div>
                            <div class='col-md-3 text-left'>%UPDATED%</div>
                        </div>

                        <!-- progres start -->
                    %PROGRESSBAR%
                        <!-- progres -->
                    </div>

            </div>
            

            <div class='panel panel-primary'>
                <div class='panel-heading'>
                    <h5 class='panel-title'>%LOGIN% _{ADDED}_: %DATE%</h5>
                </div>
                <div class='panel-body' style='text-align: left'>
                    %MESSAGE%
                    <div class='pull-right'>%QUOTING% %DELETE%</div>
                </div>
                <div class='panel-footer'>%RUN_TIME% %ATTACHMENT%</div>
            </div>

            %REPLY%

        </div>
        <div class='col-md-3' id='ext_wrapper'>
            %EXT_INFO%
        </div>

    </div>
    <!-- end of table -->
</form>

