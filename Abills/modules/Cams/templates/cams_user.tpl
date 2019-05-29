<script language='JavaScript'>
    function autoReload() {
        document.cams_user_info.add_form.value = '1';
        document.cams_user_info.TP_ID.value = '';
        document.cams_user_info.new.value = '$FORM{new}';
        document.cams_user_info.step.value = '$FORM{step}';
        document.cams_user_info.submit();
    }
</script>

<form action='$SELF_URL' method=post name='cams_user_info' class='form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value='$FORM{chg}'>
    <input type=hidden name=UID value='$FORM{UID}'>
    <input type=hidden name=TP_IDS value='%TP_IDS%'>
    <input type=hidden name='step' value='$FORM{step}'>
    <input type=hidden name='new' value=''>
    <input type=hidden name='add_form' value=''>

    <fieldset>
        %NEXT_FEES_WARNING%
        <div class='box box-theme box-form box-big-form'>
            <div class='box-header with-border'><h4 class='box-title'>_{CAMERAS}_: %ID%</h4></div>
            <div class='box-body'>
                %MENU%
                %SUBSCRIBE_FORM%
                %SERVICE_FORM%
                <div class='form-group'>
                    <label class='control-label col-md-3' for='TP_NUM'>_{TARIF_PLAN}_:</label>
                    <div class='col-md-9'>
                        %TP_ADD%
                        <div class='input-group' %TP_DISPLAY_NONE%>
                            <span class='hidden-xs input-group-addon bg-primary'>%TP_NUM%</span>
                            <input type=text name='GRP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs'
                                   readonly>
                            <input type=text name='GRP1' value='%TP_ID%:%TP_NAME%' ID='TP'
                                   class='form-control visible-xs'
                                   readonly>
                            <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
                        </div>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
                    <div class='col-md-9' style='background: %STATUS_COLOR%;'>
                        %STATUS_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='EMAIL'>E-mail:</label>
                    <div class='col-md-9'>
                        <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control'
                               type='text'>
                    </div>
                </div>

                <div class='box-footer'>
                    %BACK_BUTTON%
                    <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
                </div>


            </div>

        </div>

    </fieldset>

</form>

