<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>
<input type='hidden' name='SUBJECT' value='%SUBJECT%' size=50/>
<a name="reply" class="anchor"></a>
<div class='panel panel-primary'>
    <div class='panel-heading'>
        <h5 class='panel-title'>_{REPLY}_</h5>
    </div>
    <div class='panel-body form form-horizontal'>

        <div class='form-group'>
            <textarea name='REPLY_TEXT' class='form-control' rows=10 style='width:90%; margin-left:auto;margin-right:auto' onkeydown='SendComment(event)'>%QUOTING%%REPLY_TEXT%</textarea>
        </div>
        <div class='form-group'>
	<label class='col-md-12'>%ATTACHMENT%</label>
    </div>
    <div class='form-group'>
        <label class='col-md-2 control-label'>_{ATTACHMENT}_:</label>

        <div class='col-md-5'>
          <div class='input-group'>
            <input name='FILE_UPLOAD' type='file' class='form-control'/> 
               <span class='input-group-addon'><a
                 href='$SELF_URL?UID=$FORM{UID}&index=$index&PHOTO=$FORM{chg}&webcam=1'
                                    class='glyphicon glyphicon-camera'></a></span>
          </div>
        </div>
        <div class='col-md-5' style='padding:0px'>
            <label class='col-md-7 control-label text-left'>_{RUN_TIME}_:</label>

            <div class='col-md-5'>
                <input class='form-control' type='text' name='RUN_TIME' value='%RUN_TIME%' %RUN_TIME_STATUS%>
            </div>
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-2 control-label'>_{STATUS}_:</label>

        <div class='col-md-5'>
            %STATE_SEL%
        </div>
        <div class='col-md-5' style='padding:0px;'>
            <label class='col-md-9 control-label' style='text-align: left'>_{INNER}_:</label>

            <div class='col-md-1'>
                <input type=checkbox name=REPLY_INNER_MSG value=1 %INNER_MSG% style=/>
            </div>

        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-3 control-label'>_{CHANGE}_ _{CHAPTERS}_:</label>

        <div class='col-md-9'>
            %CHAPTERS_SEL%
        </div>
    </div>

    <div class='form-group'>
        <label class='col-md-3'>_{TEMPLATES}_ (_{SURVEY}_):</label>

        <div class='col-md-9'>
            %SURVEY_SEL%
        </div>
    </div>

    <input type='hidden' name='sid' value='$sid'/>

    <div class='form-group text-center'>
        <input type='submit' class='btn btn-primary' name='%ACTION%' value='  %LNG_ACTION%  ' id='go' title='Ctrl+C'/>
    </div>
</div>
</div>

<script language='javascript'>
    function SendComment(e) {
        e = e || window.event;
        if (e.keyCode == 13 && e.ctrlKey) {
            document.getElementById('go').click();
        }
    }
</script>