<form method='POST' action='$SELF_URL' class='form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='edit_login' value='%edit_login%'>
    <input type='hidden' name='UID' value='%UID%'>
    <div class='box box-theme box-form'>
        <div class='box-header with-border'><h4>_{CHANGE}_ _{LOGIN}_</h4></div>
        <div class='box-body'>
            <div class='form-group'>
                <label class='control-label col-md-3' for="LOGIN">_{LOGIN}_</label>
                <div class='col-md-9'>
                    <input required='' type='text' class='form-control' id="LOGIN" name='LOGIN' value='%LOGIN%'/>
                </div>
            </div>
        </div>
        <div class='box-footer'>
            <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
        </div>
    </div>
</form>

<script TYPE='text/javascript'>
    'use strict';

    jQuery(function(){

        jQuery('#LOGIN').on('input', function(){
            var value = jQuery('#LOGIN').val();
            doDelayedSearch(value)
        });
    });

    var timeout = null;
    function doDelayedSearch(val) {
        if (timeout) {
            clearTimeout(timeout);
        }
        timeout = setTimeout(function() {
            doSearch(val); //this is your existing function
        }, 500);
    };

    function doSearch(val) {
        if(!val){
            jQuery('#LOGIN').parent().parent().removeClass('has-success').addClass('has-error');
            return 1;
        }
        jQuery.post('$SELF_URL', 'header=2&get_index=' + 'check_login_availability' + '&login_check=' + val, function (data) {
            console.log(data);
            if(data === 'success'){
                jQuery('#LOGIN').parent().parent().removeClass('has-error').addClass('has-success');
            }
            else{
                jQuery('#LOGIN').parent().parent().removeClass('has-success').addClass('has-error');
            }

        });
    }

</script>
