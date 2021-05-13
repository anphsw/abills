<style>
    .paysys-chooser {
        background-color: white;
    }

    input:checked + .paysys-chooser-box {
        transform: scale(1.01, 1.01);
        box-shadow: 8px 8px 3px #AAAAAA;
        z-index: 100;
    }

    input:checked + .paysys-chooser-box > .box-footer {
        background-color: lightblue;
    }

    .paysys-chooser:hover {
        transform: scale(1.05, 1.05);
        box-shadow: 10px 10px 5px #AAAAAA;
        z-index: 101;
    }
</style>

<form method='POST' action='$SELF_URL' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='sid' value='$sid'>
    <input type='hidden' name='IDENTIFIER' value='%IDENTIFIER%'>

    <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>

    <div class='card card-secondary'>
        <div class='card-header with-border text-center'>
            <h4 class='card-title'>_{BALANCE_RECHARCHE}_</h4>
        </div>
        <div class='card-body'>
            <div class="form-group row">
                <label for="transaction" class="col-sm-4 col-md-4 col-form-label text-md-right">_{TRANSACTION}_ #:</label>
                <div class="col-sm-8 col-md-8">
                    <input type="text" class="form-control" id="transaction" placeholder="_{TRANSACTION}_ #" readonly value="%OPERATION_ID%">
                </div>
            </div>

            <div class="form-group row">
                <label for="sum" class="col-sm-4 col-md-4 col-form-label text-md-right">_{SUM}_:</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='number' min='0' step='0.01' id="sum" name='SUM' value='%SUM%' autofocus>
                </div>
            </div>

            <div class="form-group row">
                <label for="describe" class="col-sm-4 col-md-4 col-form-label text-md-right">_{DESCRIBE}_:</label>
                <div class="col-sm-8 col-md-8">
                    <input class='form-control' type='text' name='DESCRIBE' placeholder="_{DESCRIBE}_" value='_{BALANCE_RECHARCHE}_'>
                </div>
            </div>

            <div class='form-group text-center'>

                %IPAY_HTML%
            </div>

            <div class='form-group text-center'>
                <label class='col-md-12 bg-primary text-center'>_{CHOOSE_SYSTEM}_</label>
                %PAY_SYSTEM_SEL%
            </div>
        </div>

        <div class='card-footer %HIDE_FOOTER%'><input class='btn btn-primary' type='submit' name=pre value='_{NEXT}_'></div>
    </div>


</form>


%MAP%
