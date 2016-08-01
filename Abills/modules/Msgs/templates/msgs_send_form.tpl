<SCRIPT TYPE='text/javascript'>
    <!--
    function add_comments() {

        var DISPATCH_CREATE = document.getElementById('DISPATCH_CREATE');

        if (DISPATCH_CREATE.checked) {
            DISPATCH_CREATE.checked = false;
            comments = prompt('_{COMMENTS}_', '');

            var new_dispatch = document.getElementById('new_dispatch');
            var dispatch_list = document.getElementById('dispatch_list');
            var DISPATCH_COMMENTS = document.getElementById('DISPATCH_COMMENTS');

            if (comments == '' || comments == null) {
                alert('Enter comments');
                DISPATCH_CREATE.checked = false;
                new_dispatch.style.display = 'none';
                dispatch_list.style.display = 'block';
            }
            else {
                DISPATCH_CREATE.checked = true;
                DISPATCH_COMMENTS.value = comments;
                new_dispatch.style.display = 'block';
                dispatch_list.style.display = 'none';
            }
        }
        else {
            DISPATCH_CREATE.checked = false;
            DISPATCH_COMMENTS.value = '';
            new_dispatch.style.display = 'none';
            dispatch_list.style.display = 'block';
        }
    }

    -->
</SCRIPT>

<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'
      class='form-horizontal'>
    <!-- <legend>_{MESSAGES}_</legend> -->
    <fieldset>
    
<div>
 %PREVIEW_FORM%
</div>


        <div class='panel panel-primary panel-form'>
        <div class='panel-heading'>_{MESSAGES}_</div>
            <div class='panel-body'>

                <input type='hidden' name='index' value='$index'/>
                <input type='hidden' name='add_form' value='1'/>
                <input type='hidden' name='UID' value='$FORM{UID}'/>
                <input type='hidden' name='ID' value='%ID%'/>
                <input type='hidden' name='PARENT' value='%PARENT%'/>
                <input type='hidden' name='step' value='$FORM{step}'/>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='CHAPTER'>_{CHAPTERS}_</label>

                    <div class='col-md-9'>
                        %CHAPTER_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_</label>

                    <div class='col-md-9'>
                        <input type='text' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%'
                               class='form-control'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='COMMENTS'>_{MESSAGE}_</label>

                    <div class='col-md-9'>
                        <textarea class='form-control' id='MESSAGE' name='MESSAGE' rows='3' class='form-control'>%MESSAGE%</textarea>
                    </div>
                </div>
                %SEND_EXTRA_FORM%
                %SEND_TYPES_FORM%
            
        </div>


        <div class='panel panel-default panel-form'>
            <div class='panel-heading'>
                <h1 class='panel-title'><a data-toggle='collapse' data-parent='#accordion' href='#nas_misc'>_{MISC}_</a>
                </h1>
            </div>

            <div id='nas_misc' class='panel-body panel-collapse collapse out'>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>

                    <div class='col-md-6'>
                        %DATE%
                        <!--  <input type='text' name='DATE' value='%DATE%' placeholder='%DATE%' class='form-control tcal' > -->
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='INNER_MSG'>_{PRIVATE}_</label>

                    <div class='col-md-6'>
                        <input type='checkbox' name='INNER_MSG' value='1' %INNER_MSG%>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='FILE_UPLOAD_1'>_{ATTACHMENT}_ 1</label>

                    <div class='col-md-6'>
                        <input type='file' name='FILE_UPLOAD_1' ID='FILE_UPLOAD_1' value='%FILE_UPLOAD%'
                               placeholder='%FILE_UPLOAD%' class='form-control'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='FILE_UPLOAD_2'>_{ATTACHMENT}_ 2</label>

                    <div class='col-md-6'>
                        <input type='file' name='FILE_UPLOAD_2' ID='FILE_UPLOAD_2' value='%FILE_UPLOAD%'
                               placeholder='%FILE_UPLOAD%' class='form-control'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='STATE'>_{STATE}_</label>

                    <div class='col-md-9'>
                        %STATE_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_</label>

                    <div class='col-md-9'>
                        %PRIORITY_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_</label>

                    <div class='col-md-9'>
                        %RESPOSIBLE%
                    </div>
                </div>


                <div class='form-group'>
                    <label class='control-label col-md-3' for='PLAN_DATE'>_{EXECUTION}_ _{DATE}_</label>

                    <div class='col-md-4'>
                        %PLAN_DATE%
                    </div>

                    <label class='control-label col-md-2' for='PLAN_TIME'>_{TIME}_</label>

                    <div class='col-md-3'>
                        <input type=text value='%PLAN_TIME%' name='PLAN_TIME' ID='PLAN_TIME' class='form-control'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='DISPATCH'>_{DISPATCH}_</label>

                    <div class='col-md-9' id=dispatch_list>
                        %DISPATCH_SEL% <input type=checkbox id=DISPATCH_CREATE name=DISPATCH_CREATE value=1
                                              onClick='add_comments();'> _{CREATE}_ _{DISPATCH}_
                    </div>

                    <div id=new_dispatch style='display: none'>
                        <input type=text id=DISPATCH_COMMENTS name=DISPATCH_COMMENTS value='%DISPATCH_COMMENTS%'
                               size=30> _{DATE}_: %DISPATCH_PLAN_DATE%
                    </div>

                    <div id=new_dispatch style='display: none'>
                        <input type=text id=DISPATCH_COMMENTS name=DISPATCH_COMMENTS value='%DISPATCH_COMMENTS%'
                               size=30> _{DATE}_: %DISPATCH_PLAN_DATE%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='SURVEY'>_{TEMPLATES}_ (_{SURVEY}_)</label>

                    <div class='col-md-9'>
                        %SURVEY_SEL%
                    </div>
                </div>
            </div>
        </div>
        
        <div class='panel-footer'>
        %BACK_BUTTON% <input type=submit name='%ACTION%' class='btn btn-primary' value='%LNG_ACTION%' id='go' title='Ctrl+C'/>

        
        </div>
        </div>
    </fieldset>

</FORM>

