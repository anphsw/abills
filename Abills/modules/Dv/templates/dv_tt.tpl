<form action='$SELF_URL' method='POST' class='form-horizontal'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='TP_ID' value='%TP_ID%'>
    <input type=hidden name='tt' value='%TI_ID%'>

<fieldset>
<div class='panel panel-primary panel-form'>
<div class='panel-heading text-center'><h4>_{TRAFIC_TARIFS}_</h4></div>
<div class='panel-body'>




                <div class='form-group'>
                    <label class='control-label col-sm-3' for='TI_ID'>_{INTERVALS}_:</label>

                    <div class='col-sm-9'>
                        <label class='control-label' for='TI_ID'>%TI_ID%</label>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-sm-3' for='SEL_ID'>_{TRAFFIC_CLASS}_:</label>

                    <div class='col-sm-9'>
                        %SEL_TT_ID%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-md-3' for='NETS_SEL'>_{NETWORKS}_:</label>

                    <div class='col-md-9'>
                        %NETS_SEL%
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-sm-3' for='PREPAID'>_{PREPAID}_</label>

                    <div class='col-sm-8'>
                        <input id='PREPAID' name='PREPAID' value='%PREPAID%' placeholder='%PREPAID%'
                               class='form-control' type='text'>
                    </div>
                    <label class='col-md-1 control-label' style='text-align: left; padding-left: 0'> Mb </label>
                </div>

                <div class='form-group'>
                    <label class='control-label col-sm-4' style='text-align: center;'>_{TRAFIC_TARIFS}_ (1 Mb):</label>

                    <label class='control-label col-sm-1' for='IN_PRICE'>IN</label>

                    <div class='col-sm-3'>
                        <input id='IN_PRICE' name='IN_PRICE' value='%IN_PRICE%' placeholder='%IN_PRICE%'
                               class='form-control' type='text'>
                    </div>

                    <label class='control-label col-sm-1' for='OUT_PRICE'>OUT:</label>

                    <div class='col-sm-3'>
                        <input id='OUT_PRICE' name='OUT_PRICE' value='%OUT_PRICE%' placeholder='%OUT_PRICE%'
                               class='form-control' type='text'>
                    </div>

                </div>

                <div class='form-group'>
                    <label class='control-label col-sm-4' for=''>_{SPEED}_ (Kbits):</label>
                    <label class='control-label col-sm-1' for='IN_SPEED'>IN</label>

                    <div class='col-sm-3'>
                        <input id='IN_SPEED' name='IN_SPEED' value='%IN_SPEED%' placeholder='%IN_SPEED%'
                               class='form-control' type='text'>
                    </div>
                    <label class='control-label col-sm-1' for='OUT_SPEED'>OUT:</label>

                    <div class='col-sm-3'>
                        <input id='OUT_SPEED' name='OUT_SPEED' value='%OUT_SPEED%' placeholder='%OUT_SPEED%'
                               class='form-control' type='text'>
                    </div>
                </div>
                <div class='form-group'>
                <div class='panel panel-default'>
                <div class='panel-heading bg-info' role='tab' id='burstlimit' class='center'>
                       <h4 class='panel-title'>
                            <a role='button' data-toggle='collapse' data-parent='#accordion' href='#collapseOne'
                               aria-expanded='false' aria-controls='collapseOne'>
                                Burst Mode
                            </a>
                        </h4>

                    </div>
                    <div id='collapseOne' class='panel-collapse collapse collapsing' role='tabpanel'
                         aria-labelledby='burstLimit'>
                        <div class='panel-body'>
                            <div class='form-group '>
                                <label class='control-label col-md-5' for='BURST_LIMIT_DL'>Burst limit,
                                    kbps</label>

                                <div class='col-md-3'>
                                    <input id='BURST_LIMIT_DL' name='BURST_LIMIT_DL' value='%BURST_LIMIT_DL%'
                                           placeholder='%BURST_LIMIT_DL%'
                                           class='form-control' type='text'>
                                </div>
                                <div class='col-md-1 control-label'>/</div>
                                <div class='col-md-3'>
                                    <input id='BURST_LIMIT_UL' name='BURST_LIMIT_UL' value='%BURST_LIMIT_UL%'
                                           placeholder='%BURST_LIMIT_UL%'
                                           class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group '>
                                <label class='control-label col-md-5' for='BURST_THRESHOLD_DL'>Burst threshold,
                                    kbps</label>

                                <div class='col-md-3'>
                                    <input id='BURST_THRESHOLD_DL' name='BURST_THRESHOLD_DL'
                                           value='%BURST_THRESHOLD_DL%'
                                           placeholder='%BURST_THRESHOLD_DL%' class='form-control' type='text'>
                                </div>
                                <div class='col-md-1 control-label'>/</div>
                                <div class='col-md-3'>
                                    <input id='BURST_THRESHOLD_UL' name='BURST_THRESHOLD_UL'
                                           value='%BURST_THRESHOLD_UL%'
                                           placeholder='%BURST_THRESHOLD_UL%' class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group '>
                                <label class='control-label col-md-5' for='BURST_TIME_DL'>Burst time,
                                    _{SECONDS}_</label>

                                <div class='col-md-3'>
                                    <input id='BURST_TIME_DL' name='BURST_TIME_DL' value='%BURST_TIME_DL%'
                                           placeholder='%BURST_TIME_DL%'
                                           class='form-control' type='text'>
                                </div>
                                <div class='col-md-1 control-label'>/</div>
                                <div class='col-md-3'>
                                    <input id='BURST_TIME_UL' name='BURST_TIME_UL' value='%BURST_TIME_UL%'
                                           placeholder='%BURST_TIME_UL%' class='form-control' type='text'>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

                <div class='form-group'>
                    <label class='control-label col-sm-3' for='DESCR'>_{DESCRIBE}_:</label>

                    <div class='col-sm-9'>
                        <input id='DESCR' name='DESCR' value='%DESCR%' placeholder='%DESCR%'
                               class='form-control' type='text'>
                    </div>
                </div>

                <div class='form-group'>
                    <label class='control-label col-sm-3' for='EXPRESSION'>_{EXPRESSION}_:</label>

                    <div class='col-md-9'>
                        <textarea class='form-control' id='EXPRESSION'
                                  name='EXPRESSION'>%EXPRESSION%</textarea>
                    </div>

                    <div class='form-group'>
                    </div>

     </div>               %DV_EXPPP_NETFILES%



</div>
               <div class='panel-footer'>
    %BACK_BUTTON% <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
  </div>
</div>
                </div>

    </fieldset>

</form>

