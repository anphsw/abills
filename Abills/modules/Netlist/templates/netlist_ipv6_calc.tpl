<form action='%SELF_URL%' method='get' class='form form-horizontal'>
    <input type='hidden' name='index' value='%index%'>

    <div class='card card-primary card-outline card-form' style='max-width: 600px'>
        <div class='card-header with-border'>
            IPv6 _{CALCULATOR}_ (POOL_ID: %POOL_ID%)
        </div>
        <div class='card-body'>

            <div class='form-group row'>
                <label class='control-label col-md-3' for='ip'>IP </label>

                <div class='col-md-9'>
                    <input type='text' id='ip' value='%IP%' name='IP' class='form-control' aria-labelledby='IPv6'/>
                </div>
            </div>
            <div class='form-group row' id='prefix-length'>
                <label class='control-label col-md-3'>_{PREFIX}_ _{LENGTH}_:</label>

                <div class='col-md-9'>
                    %PREFIX_LENGTH_SELECT%
                </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3'>_{EXTENDED}_</label>
                <label id='ipv6_label_extended' class='control-element text-muted col-md-9'></label>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3'>_{SHORT}_</label>
                <label id='ipv6_label_short' class='control-element text-muted col-md-9'></label>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3' for='PD'>PD </label>

                <div class='col-md-9'>
                    <input type='text' id='PD' value='%PD%' name='PD' class='form-control' aria-labelledby='PD'/>
                </div>
            </div>
            <div class='form-group row'>
                <label class='control-label col-md-3'>PD _{MASK}_:</label>
                <div class='col-md-9'>
                    %PD_MASK_SELECT%
                </div>
            </div>

        </div>
        <div class='card-footer'>
            <input role='button' type='submit' class='btn btn-primary' value='_{SEND}_'>
        </div>
    </div>
</form>

<script src='/styles/default/js/modules/netlist/ipv6.js'></script>