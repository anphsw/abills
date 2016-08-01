<div class='alert alert-danger' style='padding: 0'>
    %PAYMENT_MESSAGE%
</div>

<div class='panel panel-default'>
    <div class='panel-heading text-center'>
        <h4>
            _{DV}_
        </h4>
    </div>
    <div class='panel-body'>

        %PAYMENT_MESSAGE%

        <div class='panel-heading text-center'><h4>%NEXT_FEES_WARNING%</h4></div>

        %SERVICE_EXPIRE_DATE%


        <div class='table table-striped table-hover'>
            <div class='row'>
                <div class='col-md-3 text-1'>_{TARIF_PLAN}_:</div>
                <div class='col-md-9 text-2'>[%TP_ID%] <b>%TP_NAME%</b> <span class='extra'>%TP_CHANGE% </span> <br>%COMMENTS%
                </div>
            </div>

            <div class='row'>
                <div class='col-md-3 text-1'>_{MONTH_FEE}_:</div>
                <div class='col-md-9 text-2'><b><span style='color : red'>%MONTH_ABON%</span></b>
                </div>
            </div>
            <div class='row'>
                <div class='col-md-3 text-1'>_{DAY_FEE}_:</div>
                <div class='col-md-9 text-2'><b><span style='color : red'>%DAY_ABON%</span></b>
                </div>
            </div>
            <!--
                        <div class='row'>
                            <div class='col-md-3 text-1'>_{SIMULTANEOUSLY}_</div>
                            <div class='col-md-9 text-2'>%LOGINS%</div>
                        </div>
            -->
            <div class='row'>
                <div class='col-md-3 text-1'>_{STATIC}_ IP</div>
                <div class='col-md-9 text-2'>%IP%</div>
            </div>
            <!--
                        <div class='row'>
                            <div class='col-md-3 text-1'>Netmask</div>
                            <div class='col-md-9 text-2'>%NETMASK%</div>
                        </div>
                        <div class='row'>
                            <div class='col-md-3 text-1'>_{SPEED}_ (kb)</div>
                            <div class='col-md-9 text-2'>%SPEED%</div>
                        </div>
            -->
            <div class='row'>
                <div class='col-md-3 text-1'>MAC _{ADDRESS}_</div>
                <div class='col-md-9 text-2'>%CID%</div>
            </div>
            <div class='row'>
                <div class='col-md-3 text-1'>_{STATUS}_</div>
                <div class='col-md-9 text-2'>%STATUS_VALUE% %HOLDUP_BTN%</div>
            </div>
            <!-- <tr><td>_{ABON}_:</td><td>%ABON_DATE%</td></tr> -->
            <!--
                        <div class='row'>
                            <div class='col-md-3 text-1'>_{EXPIRE}_</div>
                            <div class='col-md-9 text-2'>%DV_EXPIRE%</div>
                        </div>
            -->
        </div>

    </div>
</div>

