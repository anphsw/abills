
<script language='JavaScript'>
    function autoReload() {
        document.iptv_user_info.add_form.value = '1';
        document.iptv_user_info.submit();
    }
</script>

<form method='POST' action='$SELF_URL' class='form form-horizontal' id='iptv_user_info' name='iptv_user_info'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='sid' value='$sid'>
    <input type='hidden' name='add_form' value=1>

    <div class='box box-primary'>
        <div class='box-header with-border text-center'><h4 class='box-title'>_{SUBCRIBES}_</h4></div>
        <div class='box-body'>

            <div class='form-group text-center'>
                <label class='col-md-12 bg-primary text-center'>_{CHOOSE_SYSTEM}_</label>
                %SERVICE_SEL%
            </div>

            <div class='panel panel-default'>
              %TP_SEL%
            </div>

            <div class='form-group text-center'>
                <label class='col-md-3 bg-primary' for='%SUBSCRIBE_PARAM_ID%'>%SUBSCRIBE_PARAM_NAME% %SUBSCRIBE_PARAM_DESCRIBE%</label>
                <div class='col-md-9'>
                <input type='text' name='%SUBSCRIBE_PARAM_ID%' value='%SUBSCRIBE_PARAM_VALUE%' class='form-control' id='%SUBSCRIBE_PARAM_ID%'>
                </div>
            </div>
        </div>

        <div class='box-footer'><input class='btn btn-primary' type='submit' name=add value='_{ADD}_'></div>
    </div>
</form>
