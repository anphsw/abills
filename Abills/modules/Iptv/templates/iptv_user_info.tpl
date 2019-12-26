<FORM action='$SELF_URL' METHOD='POST' name='user_tp_change' id='user_tp_change'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='sid' value='$FORM{sid}'/>
    <input type='hidden' name='ID' value='$FORM{ID}'/>
    <input type='hidden' name='SHEDULE_ID' value='$FORM{SHEDULE_ID}'/>
    <div class='box box-theme'>
        <div class='box-header with-border'>
            <h4 class='box-title'>_{TV}_: %ID%</h4>
            <div class='box-tools pull-right'>
                %TP_CHANGE_BTN%
                %DISABLE_BTN%
                <button type='button' class='btn btn-box-tool' data-widget='collapse'>
                    <i class='fa fa-minus'></i>
                </button>
            </div>
        </div>
        <div class='box-body'>
            <div class='row'>
                <div class='col-md-3 text-1'>_{STATUS}_</div>
                <div class='col-md-9 text-2'><b>%DISABLE%</b></div>
            </div>
            <div class='row'>
                <div class='col-md-3 text-1'>_{TARIF_PLAN}_</div>
                <div class='col-md-9 text-2'>%TP_NAME%</div>
            </div>
            %IPTV_EXTRA_FIELDS%
            <!--<div class='row'>-->
            <!--<label class='col-xs-3 control-label'>_{TARIF_PLAN}_:</label>-->
            <!--<div class='col-xs-9 form-control-static'>%TP_NAME%</div>-->
            <!--</div>-->
            <!--<div class='form-group'>-->
            <!--<label class='col-xs-3 control-label'>_{STATUS}_:</label>-->
            <!--<div class='col-xs-9 form-control-static'>%DISABLE%</div>-->
            <!--</div>-->
            <div class='form-group col-md-12'></br>
                %M3U_LIST%
                %ADDITIONAL_BUTTON%
            </div>
        </div>

        <div id="confirmModal" class="modal fade" role="dialog">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                        <h4 class="modal-title">_{DEL}_ _{SHEDULE}_</h4>
                    </div>
                    <div class="modal-footer">
                        <input type="submit" name='del_shedule_tp' class='btn btn-primary' value='_{DEL}_'
                               title='Ctrl+Enter'/>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class='form-group'>
        %ACTIVE_CODE%
        %WATCH_NOW%
        %CONAX_STATUS%
    </div>
</FORM>

<script>
    function modal_view() {
        jQuery('.modal').modal('hide');
        jQuery('#confirmModal').modal('show');
    }
</script>

<style>
    .glyphicon-off {
        cursor: pointer;
    }
</style>