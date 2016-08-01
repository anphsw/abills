<form action=''$SELF_URL?index=$index\&add_article=1' name='depot_form' method=POST class='form form-horizontal'>
    <input type=hidden name=index value=$index>

    <div class='panel panel-primary panel-form'>
        <div class='panel-heading'>_{ADD}_ _{TYPE}_</div>
        <div class='panel-body'>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{TYPE}_:</label>

                <div class='col-md-9'>
                    <select class='form-control control-element' name='TYPE'>
                        <option value=0>Hardware</option>
                        <option value=1>Software</option>
                    </select>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label col-md-3'>_{NAME}_:</label>

                <div class='col-md-9'>
                    <input class='form-control' type='text' name='NAME' />
                </div>
            </div>
        </div>
        <div class='panel-footer'>
                <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
        </div>
    </div>
</form>
