<form METHOD=POST class='form-horizontal container-md' >
    <input type='hidden' name='index' value='%INDEX%'>
    <input type="hidden" name="%ADD_CHG%" value="1">
    <input type="hidden" name="al_id" id="al_id" value="%ID_CHANGE%">
    <input type="hidden" name="al_chg" id="al_chg" value="%CHG_JS%">
    <input type="hidden" name="USER_ACCIDENT" id="USER_ACCIDENT" value="%USER_ACCIDENT%">

    <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'>
            <h4 class='card-title'>
                _{ADD_ACCIDENT}_
            </h4>
        </div>
        <div class="card-body">

            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{NAME}_:</label>
                <div class="col-md-9 col-sm-8">
                    <input type='text' name='NAME' value='%NAME%' placeholder='%P_NAME%'
                           class='form-control'>
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{DESCRIBE}_:</label>
                <div class="col-md-9 col-sm-8">
                    <input type='text' name='DESCR' value='%DESCR%' placeholder='%DESCRIBE%'
                           class='form-control'>
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{PRIORITY}_:</label>
                <div class="col-md-9 col-sm-8">
                    %SELECT_PRIORITY%
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{STATUS}_:</label>
                <div class="col-md-9 col-sm-8">
                    %SELECT_STATUS%
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{ADMIN}_:</label>
                <div class="col-md-9 col-sm-8">
                    %ADMIN_SELECT%
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{DATE}_:</label>
                <div class="col-md-9 col-sm-8">
                    %DATE%
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{WORK_END_DATE}_:</label>
                <div class="col-md-9 col-sm-8">
                    %DATEPICKER_END%
                </div>
            </div>
            <div class="form-group row">
                <label class="control-label col-md-2 col-sm-3">_{WORK_REALY_DATE}_:</label>
                <div class="col-md-9 col-sm-8">
                    %DATEPICKER_REAL%
                </div>
            </div>
            %GEO_TREE%
        </div>
        <div class='card-footer'>
            <input type="submit" class="btn btn-primary" name="ADD" value="%ADD%">
        </div>
    </div>
</form>
<script>
    jQuery(document).on('click', '#show_tree input', function(){
        let parent = jQuery(this).parent().parent();
        if(parent.attr('class') === "parent"){
            parent.parent().find(".ul-list").find('input').prop('checked', jQuery(this).prop("checked"));
        }
    });

    let date = jQuery('#al_chg').val();
    let result = date.match(/[0-9]{1,9}/g);

    if (result.length > 0) {
        setTimeout(function() {
            for (var i = 0; i < result.length; i++) {
                jQuery("#"+result[i]).trigger('click');
            }
        }, 1500);
    }
    else {
        setTimeout(function(){
            jQuery("#"+jQuery('#al_chg').val()).trigger('click');
        }, 1500);
    }
</script>