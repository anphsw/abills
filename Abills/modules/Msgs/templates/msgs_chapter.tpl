<FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal' enctype='multipart/form-data'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>

    <div class='box box-primary' style='max-width: 600px;'>
        <div class='box-header with-border'><h4>Раздел</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-4'>_{NAME}_:</label>

                <div class='col-md-8'>
                    <input class='form-control' type=text name=NAME value='%NAME%' maxlength="20">
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-4'>_{RESPOSIBLE}_:</label>
                <div class='col-md-8'>
                    %RESPONSIBLE_SEL%
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-4 control-label'>_{COLOR}_</label>
                <div class='col-md-8'>
                    <input type='color' class='form-control' name='COLOR' value='%COLOR%'>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4'>_{ICON}_:</label>
                <div class='col-md-8'><input type='file' name=UPLOAD_FILE></div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-4'>_{AUTO_CLOSE}_:</label>

                <div class='col-md-8'>
                    <input class='form-control' type=text name=AUTOCLOSE value='%AUTOCLOSE%' maxlength="20">
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-7'>_{INNER_M}_ _{CHAPTER}_:</label>

                <div class='col-md-5 text-left'>
                    <input type='checkbox' name=INNER_CHAPTER value='1' %INNER_CHAPTER%
                           style='margin-top:10px'>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
        </div>
    </div>


</form>
