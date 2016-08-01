<SCRIPT TYPE='text/javascript'>
    <!--
    function add_comments() {

        if (document.user_form.DISABLE.checked) {
            document.user_form.DISABLE.checked = false;

            var comments = prompt('_{COMMENTS}_', '');

            if (comments == '' || comments == null) {
                alert('Enter comments');
                document.user_form.DISABLE.checked = false;
                document.user_form.ACTION_COMMENTS.style.visibility = 'hidden';
            }
            else {
                document.user_form.DISABLE.checked = true;
                document.user_form.ACTION_COMMENTS.value = comments;
                document.user_form.ACTION_COMMENTS.style.visibility = 'visible';
            }
        }
        else {
            document.user_form.DISABLE.checked = false;
            document.user_form.ACTION_COMMENTS.style.visibility = 'hidden';
            document.user_form.ACTION_COMMENTS.value = '';
        }
    }
    -->
</SCRIPT>


<div class='panel panel-default'>
    <div class='panel-body'>

        <form class='form-horizontal' action='$SELF_URL' method='post' id='user_form' name='user_form' role='form'>
            <input type=hidden name=index value='$index'>
            <input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
            <input type=hidden name=step value='$FORM{step}'>
            <input type=hidden name=NOTIFY_FN value='%NOTIFY_FN%'>
            <input type=hidden name=NOTIFY_ID value='%NOTIFY_ID%'>

            <fieldset>

                %EXDATA%

                <!-- CREDIT / DATE  -->
                <div class='form-group'>
                    <label class='control-label col-md-2' for='CREDIT'>_{CREDIT}_</label>
                    <div class='col-md-3'>
                        <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control'
                               type='text'>
                    </div>
                    <label class='control-label col-md-2' for='CREDIT_DATE'>_{DATE}_</label>
                    <div class='col-md-3'>
                        <input id='CREDIT_DATE' type='text' name='CREDIT_DATE' value='%CREDIT_DATE%'
                               class='tcal form-control'>
                    </div>
                </div>

                <!-- DISCOUNT / DATE  -->
                <div class='form-group'>
                    <label class='control-label col-md-2' for='REDUCTION'>_{REDUCTION}_ (%)</label>
                    <div class='col-md-3'>
                        <input id='REDUCTION' name='REDUCTION' value='%REDUCTION%' placeholder='%REDUCTION%'
                               class='form-control' type='text'>
                    </div>
                    <label class='control-label col-md-2' for='REDUCTION_DATE'>_{DATE}_</label>
                    <div class='col-md-3'>
                        <input id='REDUCTION_DATE' type='text' name='REDUCTION_DATE' value='%REDUCTION_DATE%'
                               class='tcal form-control'>
                    </div>
                </div>

                <!-- ACTIVATION / EXPIRED -->
                <div class='form-group'>
                    <label class='control-label col-md-2' for='ACTIVATE'>_{ACTIVATE}_</label>
                    <div class='col-md-3'>
                        <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                               class='form-control tcal' type='text'>
                    </div>
                    <label class='control-label col-md-2' for='EXPIRE'>_{EXPIRE}_</label>
                    <div class='col-md-3 %EXPIRE_COLOR%'>
                        <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                               class='form-control tcal' type='text'>
                        <!--    <span class='help-block'>%EXPIRE_COMMENTS%</span> -->
                    </div>
                </div>

                <!-- DISABLE -->
                <div class='form-group'>
                    <label class='control-label col-md-2' for='DISABLE'>_{DISABLE}_</label>
                    <div class='col-md-1 %DISABLE_COLOR%'>
                        <input id='DISABLE' name='DISABLE' value='1' %DISABLE% type='checkbox'
                               onClick='add_comments();'>
                        %DISABLE_MARK%
                    </div>
                    <div class='col-md-2 %DISABLE_COLOR%'>
                        %DISABLE_COMMENTS%
                        <input class='form-control' type=text name=ACTION_COMMENTS value='%DISABLE_COMMENTS%' size=30
                               style='visibility: hidden;'>%ACTION_COMMENTS%
                    </div>

                    <label class='control-label col-md-2' for='REG'>_{REGISTRATION}_</label>
                    <div class='col-md-3'>
                        <input type=text name='REG' value='%REGISTRATION%' ID='REG' class='form-control' readonly>
                    </div>
                </div>

                <label class='col-sm-offset-2 col-sm-8'>%PASSWORD%</label>

                %DEL_FORM%

                <div class='col-sm-offset-2 col-sm-8'>
                    <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
                </div>
            </fieldset>
        </form>

    </div>
</div>
