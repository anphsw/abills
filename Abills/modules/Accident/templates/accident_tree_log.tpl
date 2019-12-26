<form action=$SELF_URL METHOD=POST class='form-horizontal'>
    <input type='hidden' name='index' value='%INDEX%'>

    <div class='box box-theme'>
        <div class='box-header with-border'>
            <h4 class='box-title'>
                _{ACCIDENT_LOG}_
            </h4>
        </div>
        <div class="box-body">
            <div class='row'>
                <div class='col-sm-12 col-md-12'>
                    %GEOLOCATION_TREE%
                </div>
            </div>
            <div class='col-md-12 col-sm-12'>
                <input type="submit" class="btn btn-primary col-md-12 col-sm-12" name="SAVE" value="%SAVE%">
            </div>
        </div>
    </div>
</form>