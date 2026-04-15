<form class='double_enter_check' action='%SELF_URL%' method='post' ID='user' name=user role='form'
      onsubmit=\"postthread('submitbutton');\">
    <input type=hidden name=UID value='%UID%'>
    <input type=hidden name=index value='%index%'>
    <input type=hidden name=ID value='%ID%'>

    <div class='card card-primary card-outline container-md'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{COMPENSATE}_ </h4>
        </div>

        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='ID'>ID:</label>
                <div class='col-sm-10 col-md-9'>
                    <input id='ID' type='text' name='ID' value='%ID%' class='form-control' disabled>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='FEES_SUM'>_{FEES}_ _{SUM}_:</label>
                <div class='col-sm-10 col-md-9'>
                    <input id='FEES_SUM' type='number' name='FEES_SUM' value='%SUM%' class='form-control' disabled>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='DSC'>_{DESCRIBE}_:</label>
                <div class='col-sm-10 col-md-9'>
                    <input id='DSC' type='text' name='DSC' value='%DSC%' class='form-control' disabled>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='INNER_DESCRIBE'>_{INNER}_:</label>
                <div class='col-sm-10 col-md-9'>
                    <input id='INNER_DESCRIBE' type='text' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%'
                           class='form-control' maxlength='%MAX_LENGTH_INNER_DESCRIBE%' required>
                </div>
            </div>


            <div class='form-group row'>
                <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='SUM'>_{SUM}_:</label>
                <div class='col-sm-10 col-md-9'>
                    <input id='SUM' type='number' name='SUM' value='' class='form-control' max='%SUM%'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-2 col-md-3 col-form-label text-md-right' for='PERCENT'>_{PERCENT}_:</label>
                <div class='col-sm-10 col-md-9'>
                    <input id='PERCENT' type='number' name='PERCENT' value='%PERCENT%' class='form-control' min='0'
                           max='100'>
                </div>
            </div>

        </div>

        <div class='card-footer'>
            <input type=submit name='COMPENSATE' value='_{COMPENSATION}_' class='btn btn-primary double_click_check'
                   id='submitbutton'>
        </div>

    </div>
</form>
