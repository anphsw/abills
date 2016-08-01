<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>

<div class='noprint'>
    <div class='panel panel-primary'>
        <div class='panel-heading'>
            <h5 class='panel-title text-center'>_{REPLY}_</h5>
        </div>
        <input type='hidden' name='SUBJECT' value='%SUBJECT%' size=50/>

        <div class='panel-body form form-horizontal'>
            <div class='form-group'>
                <div class='col-md-12'>
                    <textarea class='form-control' name='REPLY_TEXT' cols='90' rows='11' onkeydown='keyDown(event)'
                              onkeyup='keyUp(event)'>%QUOTING% %REPLY_TEXT%</textarea>
                </div>
            </div>
            <div class='form-group'>
                %ATTACHMENT%
            </div>

            <div class='form-group'>
                <label class='col-md-3 control-label'>_{ATTACHMENT}_:</label>

                <div class='col-md-9' style='padding:5px'><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
                    <!--   <input class='button' type='submit' name='AttachmentUpload' value='_{ADD}_'>-->
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label'>_{STATUS}_:</label>

                <div class='col-md-9'>%STATE_SEL% %RUN_TIME%</div>
            </div>

        </div>

        <div class='form-group text-center'>
            <input type='hidden' name='sid' value='$sid'/>
            <input type='submit' class='btn btn-primary' name='%ACTION%' value='  %LNG_ACTION%  ' id='go'
                   title='_{SEND}_ (Ctrl+Enter)'/>
        </div>
    </div>


</div>
