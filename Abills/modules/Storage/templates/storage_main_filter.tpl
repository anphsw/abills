<script language='JavaScript'>
    function autoReload() {
        document.depot_form.type.value = 'prihod';
        document.depot_form.submit();
    }
</script>
<div class='row'>
    <form class='form form-horizontal' action='$SELF_URL?index=$index\&storage_status=1' name='depot_form' method=POST>
        <fieldset>

            <input type=hidden name=index value=$index>
            <input type=hidden name=ID value=$FORM{chg}>
            <input type=hidden name=INCOMING_ID value=%INCOMING_ID%>
            <input type=hidden name='type' value='prihod2'>
            <input type=hidden name='storage_status' value='1'>

            <div class='panel panel-primary panel-form'>
                <div class='panel-heading'>
                    _{SEARCH}_
                </div>
                <div class='panel-body'>
                    <div class='form-group'>
                        <label class='control-label col-md-3'>_{TYPE}_:</label>

                        <div class='col-md-9'>
                            %ARTICLE_TYPES%
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='control-label col-md-3'>_{NAME}_:</label>

                        <div class='col-md-9'>
                            %ARTICLE_ID%
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='control-label col-md-3'>_{SUPPLIERS}_:</label>

                        <div class='col-md-9'>
                            %SUPPLIER_ID%
                        </div>
                    </div>
                    <div class='form-group'>
                        <label class='control-label col-md-3'>_{STORAGE}_:</label>

                        <div class='col-md-9'>
                            %STORAGE_STORAGES%
                        </div>
                    </div>
                </div>
                <div class='panel-footer'>
                    <input class='btn btn-primary' type='submit' name='storage_status' value=_{SHOW}_>
                </div>
            </div>
        </fieldset>
    </form>
</div>