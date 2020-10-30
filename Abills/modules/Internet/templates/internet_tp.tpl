<form action='$SELF_URL' class='form-horizontal' METHOD='POST'>

    <input type=hidden name='index' value='$index'>
    <input type=hidden name='TP_ID' value='%TP_ID%'>
    <input type=hidden name='RAD_PAIRS' id="RAD_PAIRS" value='%RAD_PAIRS%'>
    <div class='row'>
        <div class='col-md-6'>
            <div class='box box-theme box-big-form'>
                <div class='box-header with-border'><h4 class='box-title'>_{TARIF_PLAN}_</h4>%CLONE_BTN%</div>
                <div class='box-body'>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='ID'>#</label>
                        <div class='col-md-9'>
                            <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
                        <div class='col-md-9'>
                            <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='GROUP'>_{GROUP}_:</label>
                        <div class='col-md-9'>
                            %GROUPS_SEL%
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='ALERT'>_{UPLIMIT}_:</label>
                        <div class='col-md-9'>
                            <input id='ALERT' name='ALERT' value='%ALERT%' placeholder='%ALERT%' class='form-control' type='text'>
                        </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3' for='SIMULTANEOUSLY'>_{SIMULTANEOUSLY}_:</label>
                        <div class='col-md-9'>
                            <input id='SIMULTANEOUSLY' name='SIMULTANEOUSLY' value='%SIMULTANEOUSLY%' placeholder='%SIMULTANEOUSLY%'
                                   class='form-control' type='text'>
                        </div>
                    </div>

                    <div class='form-group'>
                      <label class='control-label col-md-3' for='COMMENTS'>_{DESCRIBE}_</label>
                      <div class='col-md-9'>
                        <textarea cols='40' rows='4' name='COMMENTS' class='form-control' id='COMMENTS'>%COMMENTS%</textarea>
                      </div>
                    </div>

                    <div class='form-group'>
                        <label class='control-label col-md-3'>_{DESCRIBE}_ (_{ADMIN}_)</label>
                        <div class='col-md-9'>
                            <textarea cols='40' rows='4' name='DESCRIBE_AID' 
                                class='form-control' id='DESCRIBE_AID'>%DESCRIBE_AID%</textarea>
                        </div>
                    </div>

                  <div class='form-group'>
                    <label class='control-label col-md-3'>_{HIDE_TP}_</label>
                    <div class='col-md-9'>
                      <div class='checkbox pull-left'>
                        <input style='margin-left:0px;' type='checkbox' name='STATUS' value='1' id='STATUS' %STATUS%>
                      </div>
                    </div>
                  </div>

                </div>
            </div>
        </div>

        <div class='col-md-6'>
            <div class='box collapsed-box box-theme box-big-form'>
              <div class='box-header with-border text-center'>
                <h3 class='box-title'>_{ABON}_</h3>
                <div class='box-tools pull-right'>
                  <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                    <i class='fa fa-plus'></i>
                  </button>
                </div>
              </div>
              <div class='box-body'>
                 <div class='form-group'>
                     <label for='DAY_FEE' class='control-label col-md-8'>_{DAY_FEE}_:</label>
                     <div class='col-md-4'>
                         <input class='form-control' id='DAY_FEE' placeholder='%DAY_FEE%' name='DAY_FEE' value='%DAY_FEE%'>
                     </div>
                 </div>

                 <div class='form-group'>
                     <label class='control-label col-md-8' for='ACTIVE_DAY_FEE'>_{ACTIVE_DAY_FEE}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='ACTIVE_DAY_FEE' name='ACTIVE_DAY_FEE' value='1' %ACTIVE_DAY_FEE% type='checkbox'>
                     </div>
                 </div>

                 <div class='form-group'>
                     <label class='control-label col-md-8' for='POSTPAID_DAY_FEE'>_{DAY_FEE}_ _{POSTPAID}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='POSTPAID_DAY_FEE' name='POSTPAID_DAY_FEE' value=1 %POSTPAID_DAY_FEE% type='checkbox'>
                     </div>
                 </div>


                 <div class='form-group'>
                     <label for='MONTH_FEE' class='control-label col-md-8'>_{MONTH_FEE}_:</label>
                     <div class='col-md-4'>
                         <input class='form-control' id='MONTH_FEE' placeholder='%MONTH_FEE%' name='MONTH_FEE'
                                value='%MONTH_FEE%'>
                     </div>
                 </div>


                 <div class='form-group'>
                     <label class='control-label col-md-8' for='POSTPAID_MONTH_FEE'>_{MONTH_FEE}_ _{POSTPAID}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='POSTPAID_MONTH_FEE' name='POSTPAID_MONTH_FEE' value='1' %POSTPAID_MONTH_FEE% type='checkbox'>
                     </div>
                 </div>

                 <div class='form-group'>
                     <label class='control-label col-md-8' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='PERIOD_ALIGNMENT' name='PERIOD_ALIGNMENT' value=1 %PERIOD_ALIGNMENT% type='checkbox' data-input-disables='FIXED_FEES_DAY,ABON_DISTRIBUTION'>
                     </div>
                 </div>

                 <div class='form-group'>
                     <label class='control-label col-md-8' for='ABON_DISTRIBUTION'>_{ABON_DISTRIBUTION}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='ABON_DISTRIBUTION' name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%
                                type='checkbox' data-input-disables='PERIOD_ALIGNMENT,FIXED_FEES_DAY'>
                     </div>
                 </div>

                 <div class='form-group'>
                     <label class='control-label col-md-8' for='FIXED_FEES_DAY'>_{FIXED_FEES_DAY}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='FIXED_FEES_DAY' name='FIXED_FEES_DAY' value=1 %FIXED_FEES_DAY% type='checkbox' data-input-disables='PERIOD_ALIGNMENT,ABON_DISTRIBUTION'>
                     </div>
                 </div>


                 <div class='form-group'>
                     <label for='SMALL_DEPOSIT_ACTION' class='control-label col-md-8'>_{SMALL_DEPOSIT_ACTION}_:</label>
                     <div class='col-md-4'>
                         %SMALL_DEPOSIT_ACTION_SEL%
                     </div>
                 </div>

                 <div class='form-group'>
                     <label class='control-label col-md-8' for='REDUCTION_FEE'>_{REDUCTION}_:</label>
                     <div class='checkbox pull-left'>
                         <input style='margin-left:15px;' id='REDUCTION_FEE' name='REDUCTION_FEE' value='1' %REDUCTION_FEE% type='checkbox'>
                     </div>
                 </div>

                 <div class='form-group'>
                     <label for='METHOD' class='control-label col-sm-4'>_{FEES}_ _{TYPE}_:</label>
                     <div class='col-md-8'>
                         %SEL_METHOD%
                     </div>
                 </div>

                 %EXT_BILL_ACCOUNT%

             </div>
            </div>
        </div>

        <div class='col-md-6'>
          <div class='box collapsed-box box-theme box-big-form'>
            <div class='box-header with-border text-center'>
              <h3 class='box-title'>_{TIME_LIMIT}_ (sec)</h3>
              <div class='box-tools pull-right'>
                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='box-body'>
              <div class='form-group'>
                  <label for='DAY_TIME_LIMIT' class='control-label col-md-3'>_{DAY}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='DAY_TIME_LIMIT' placeholder='%DAY_TIME_LIMIT%' name='DAY_TIME_LIMIT'
                             value='%DAY_TIME_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='WEEK_TIME_LIMIT' class='control-label col-md-3'>_{WEEK}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='WEEK_TIME_LIMIT' placeholder='%WEEK_TIME_LIMIT%'
                             name='WEEK_TIME_LIMIT' value='%WEEK_TIME_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='MONTH_TIME_LIMIT' class='control-label col-md-3'>_{MONTH}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='MONTH_TIME_LIMIT' placeholder='%MONTH_TIME_LIMIT%'
                             name='MONTH_TIME_LIMIT' value='%MONTH_TIME_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='TOTAL_TIME_LIMIT' class='control-label col-md-3'>_{TOTAL}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='TOTAL_TIME_LIMIT' placeholder='%TOTAL_TIME_LIMIT%'
                             name='TOTAL_TIME_LIMIT' value='%TOTAL_TIME_LIMIT%'>
                  </div>
              </div>
            </div>
          </div>
        </div>

        <div class='col-md-6'>
          <div class='box collapsed-box box-theme box-big-form'>
            <div class='box-header with-border text-center'>
              <h3 class='box-title'>_{TRAF_LIMIT}_ (Mb)</h3>
              <div class='box-tools pull-right'>
                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='box-body'>
              <div class='form-group'>
                  <label for='DAY_TRAF_LIMIT' class='control-label col-sm-3'>_{DAY}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='DAY_TRAF_LIMIT' placeholder='%DAY_TRAF_LIMIT%' name='DAY_TRAF_LIMIT'
                             value='%DAY_TRAF_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='WEEK_TRAF_LIMIT' class='control-label col-sm-3'>_{WEEK}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='WEEK_TRAF_LIMIT' placeholder='%WEEK_TRAF_LIMIT%'
                             name='WEEK_TRAF_LIMIT' value='%WEEK_TRAF_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='MONTH_TRAF_LIMIT' class='control-label col-sm-3'>_{MONTH}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='MONTH_TRAF_LIMIT' placeholder='%MONTH_TRAF_LIMIT%'
                             name='MONTH_TRAF_LIMIT' value='%MONTH_TRAF_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='TOTAL_TRAF_LIMIT' class='control-label col-sm-3'>_{TOTAL}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='TOTAL_TRAF_LIMIT' placeholder='%TOTAL_TRAF_LIMIT%'
                             name='TOTAL_TRAF_LIMIT' value='%TOTAL_TRAF_LIMIT%'>
                  </div>
              </div>
            </div>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='box collapsed-box box-theme box-big-form'>
            <div class='box-header with-border text-center'>
              <h3 class='box-title'>_{OTHER}_</h3>
              <div class='box-tools pull-right'>
                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='box-body'>
              <div class='form-group'>
                  <label for='OCTETS_DIRECTION' class='control-label col-sm-3'>_{OCTETS_DIRECTION}_</label>
                  <div class='col-md-9'>%SEL_OCTETS_DIRECTION%</div>
              </div>

              <div class='form-group'>
                  <label for='ACTIV_PRICE' class='control-label col-sm-3'>_{ACTIVATE}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' type='text' id='ACTIV_PRICE' placeholder='%ACTIV_PRICE%'
                             name='ACTIV_PRICE' value='%ACTIV_PRICE%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='CHANGE_PRICE' class='control-label col-sm-3'>_{CHANGE}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='CHANGE_PRICE' placeholder='%CHANGE_PRICE%' name='CHANGE_PRICE'
                             value='%CHANGE_PRICE%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='CREDIT_TRESSHOLD' class='control-label col-sm-3'>_{CREDIT_TRESSHOLD}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='CREDIT_TRESSHOLD' placeholder='%CREDIT_TRESSHOLD%'
                             name='CREDIT_TRESSHOLD' value='%CREDIT_TRESSHOLD%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='CREDIT' class='control-label col-sm-3'>_{CREDIT}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='USER_CREDIT_LIMIT' class='control-label col-sm-3'>_{USER_PORTAL}_ _{CREDIT}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='USER_CREDIT_LIMIT' placeholder='%USER_CREDIT_LIMIT%'
                             name='USER_CREDIT_LIMIT' value='%USER_CREDIT_LIMIT%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='MAX_SESSION_DURATION' class='control-label col-sm-3'>_{MAX_SESSION_DURATION}_
                      (sec.):</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='MAX_SESSION_DURATION' placeholder='%MAX_SESSION_DURATION%'
                             name='MAX_SESSION_DURATION' value='%MAX_SESSION_DURATION%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='FILTER_ID' class='control-label col-sm-3'>_{FILTERS}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='FILTER_ID' placeholder='%FILTER_ID%' name='FILTER_ID'
                             value='%FILTER_ID%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='PAYMENT_TYPE_SEL' class='control-label col-sm-3'>_{PAYMENT_TYPE}_:</label>
                  <div class='col-md-9'>
                      %PAYMENT_TYPE_SEL%
                  </div>
              </div>

              <div class='form-group'>
                  <label for='MIN_SESSION_COST' class='control-label col-sm-3'>_{MIN_SESSION_COST}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='MIN_SESSION_COST' placeholder='%MIN_SESSION_COST%'
                             name='MIN_SESSION_COST' value='%MIN_SESSION_COST%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='MIN_USE' class='control-label col-sm-3'>_{MIN_USE}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='MIN_USE' placeholder='%MIN_USE%' name='MIN_USE' value='%MIN_USE%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='TRAFFIC_TRANSFER_PERIOD' class='control-label col-sm-3'>_{TRAFFIC_TRANSFER_PERIOD}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='TRAFFIC_TRANSFER_PERIOD' placeholder='%TRAFFIC_TRANSFER_PERIOD%'
                             name='TRAFFIC_TRANSFER_PERIOD' value='%TRAFFIC_TRANSFER_PERIOD%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='NEG_DEPOSIT_FILTER_ID' class='control-label col-sm-3'>_{NEG_DEPOSIT_FILTER_ID}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='NEG_DEPOSIT_FILTER_ID' placeholder='%NEG_DEPOSIT_FILTER_ID%'
                             name='NEG_DEPOSIT_FILTER_ID' value='%NEG_DEPOSIT_FILTER_ID%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='NEG_DEPOSIT_IPPOOL_SEL' class='control-label col-sm-3'>_{NEG_DEPOSIT_IP_POOL}_:</label>
                  <div class='col-md-9'>
                      %NEG_DEPOSIT_IPPOOL_SEL%
                  </div>
              </div>

              <div class='form-group'>
                  <label for='IP_POOLS_SEL' class='control-label col-sm-3'>IP Pool:</label>
                  <div class='col-md-9'>
                      %IP_POOLS_SEL%
                  </div>
              </div>

              <div class='form-group'>
                  <label for='PRIORITY' class='control-label col-sm-3'>_{PRIORITY}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='PRIORITY' placeholder='%PRIORITY%' name='PRIORITY' value='%PRIORITY%'>
                  </div>
              </div>

              <div class='form-group'>
                  <label for='FINE' class='control-label col-sm-3'>_{FINE}_:</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='FINE' placeholder='%FINE%' name='FINE' value='%FINE%'>
                  </div>
              </div>

              <div class='form-group bg-info'>
                  <label for='AGE' class='control-label col-sm-3'>_{AGE}_ (_{DAYS}_):</label>
                  <div class='col-md-9'>
                      <input class='form-control' id='AGE' placeholder='%AGE%' name='AGE' value='%AGE%'>
                  </div>
              </div>

              <div class='form-group bg-info'>
                  <label for='NEXT_TARIF_PLAN_SEL' class='control-label col-sm-3'>_{TARIF_PLAN}_ _{NEXT_PERIOD}_:</label>
                  <div class='col-md-9'>
                      %NEXT_TARIF_PLAN_SEL%
                  </div>
              </div>

              <div class='form-group'>
                  <label class='col-sm-offset-2 col-sm-8'>RADIUS Parameters</label>
                    <div class='col-md-12'>
                      <table class='table table-bordered table-hover'>

                        <thead>
                        <tr>
                          <th class='text-center col-md-1'>
                            #
                          </th>
                          <th class='text-center col-md-1'>
                            _{EMPTY_FIELD}_
                          </th>
                          <th class='text-center col-md-3'>
                            _{LEFT_PART}_
                          </th>
                          <th class='text-center col-md-1'>
                            _{CONDITION}_
                          </th>
                          <th class='text-center col-md-3'>
                            _{RIGHT_PART}_
                          </th>
                        </tr>
                        </thead>
                        <tbody id='tab_logic'>

                        <tr id='addr1'>
                          <td class='ids'>
                            <input type='hidden' name='IDS' value='1'>
                            1
                          </td>
                          <td class="ignore_pair">
                            <span class="ignone_pair_parent" data-tooltip="_{EMPTY_FIELD}_" data-content="_{EMPTY_FIELD}_" 
                                  data-html="true" data-toggle="popover" data-trigger="hover" data-placement="right auto" data-container="body">
                                <i class="fa fa-exclamation"></i>
                                <input type="checkbox" id="IGNORE_PAIR" name="IGNORE_PAIR" value="1">
                            </span>
                        </td>
                          <td class='left_p'>
                            <input type='text' name='LEFT_PART' id='LEFT_PART' value='%LEFT_PART%'
                                   placeholder='_{LEFT_PART}_' class='form-control'/>
                          </td>
                          <td class='cnd'>
                            <input type='text' name='CONDITION' id='CONDITION' value='%CONDITION%' placeholder='='
                                   class='form-control'/>
                          </td>
                          <td class='right_p'>
                            <input type='text' name='RIGHT_PART' id='RIGHT_PART'
                                   value='%RIGHT_PART%' placeholder='_{RIGHT_PART}_'
                                   class='form-control'/>
                          </td>
                        </tr>
                        </tbody>
                      </table>
                    </div>
                <div class='col-md-2 col-xs-2 pull-right' style='padding-right: 0'>
                  <a title='_{ADD}_' class='btn btn-sm btn-default' id='add_field'>
                    <span class='glyphicon glyphicon-plus'></span>
                  </a>
                </div>
                <div class='col-md-2 col-xs-2 pull-right' style='padding-right: 0'>
                  <a title='_{ADD}_' class='btn btn-sm btn-default' id='del_field'>
                    <span class='glyphicon glyphicon-minus'></span>
                  </a>
                </div>
              </div>
              %BONUS%

              %FORM_DOMAINS%

            </div>
          </div>
        </div>
    </div>

    <div class='row'>
      <div class='col-md-12'>
        <div class='box-footer'>
            <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
        </div>
      </div>
    </div>
<br>
</form>
<script>
    jQuery(function () {
        var iter = 2;

        var date = document.getElementById('RAD_PAIRS').value;
        var element = 0;

        var answDate = date.split(',');

        while (element < answDate.length) {
            if(answDate[element] === " ") {
                answDate.splice(element, 1);
            }
            element++;
        }

        element = 0;

        if (date) {
            while (element < answDate.length) {
                if (/([0-9a-zA-Z\-!:]+)([-+=]{1,2})([:\-\;\(\,\)\\'\\’\"\#= 0-9a-zA-Zа-яА-Я.]+)/.test(answDate[element])) {
                    let dateRegex = answDate[element].match(/([0-9a-zA-Z\-!:]+)([-+=]{1,2})([:\-\;\(\,\)\\'\\’\"\#= 0-9a-zA-Zа-яА-Я.]+)/);
                    if (element < answDate.length) {
                        jQuery('#addr1').clone(true)
                            .attr('id', 'addr' + iter)
                            .show()
                            .appendTo('#tab_logic');

                        jQuery('#addr' + iter).children('.ids').text(iter);

                        jQuery('#addr' + (iter - 1)).children('.left_p').children("#LEFT_PART").val(dateRegex[1]);
                        jQuery('#addr' + (iter - 1)).children('.cnd').children("#CONDITION").val(dateRegex[2]);
                        
                        if (/ \n/.test(answDate[1])) {
                            answDate[1] = answDate[1].replace(' \n', ',');
                            var newRightData = dateRegex[3] + answDate[1];
                            
                            jQuery('#addr' + (iter - 1)).children('.right_p').children("#RIGHT_PART").val(dateRegex[3] + ',' + answDate[1]);
                        } else {
                            jQuery('#addr' + (iter - 1)).children('.right_p').children("#RIGHT_PART").val(dateRegex[3]);
                        }

                        jQuery('#addr' + (iter - 1))
                                .children('.ignore_pair')
                                .children('.ignone_pair_parent')
                                .children('#IGNORE_PAIR')
                                .val(iter - 1);

                        var checkboxCheck = false;
                        if (/!/.test(answDate[element])) {
                            checkboxCheck = true;
                        }

                        jQuery('#addr' + (iter - 1))
                            .children('.ignore_pair')
                            .children('.ignone_pair_parent')
                            .children('#IGNORE_PAIR')
                            .prop('checked', checkboxCheck);

                        iter++;
                    }
                }
                element++;
            }

            if (iter > 2) {
                jQuery('#del_field').show();
            }

            jQuery('#addr' + (iter - 1)).remove();
            iter--;
        }

        jQuery('#add_field').click(function () {
            jQuery('#addr1').clone(true)
                .attr('id', 'addr' + iter)
                .show()
                .appendTo('#tab_logic');

            jQuery('#addr' + iter).children('.ids').text(iter);

            jQuery('#addr' + iter).children('.left_p').children("#LEFT_PART").val("");
            jQuery('#addr' + iter).children('.cnd').children("#CONDITION").val("");
            jQuery('#addr' + iter).children('.right_p').children("#RIGHT_PART").val("");

            jQuery('#addr' + (iter)).children('.ignore_pair').children('.ignone_pair_parent').children('#IGNORE_PAIR').attr('checked', false);
            jQuery('#addr' + (iter)).children('.ignore_pair').children('.ignone_pair_parent').children('#IGNORE_PAIR').val(iter);

            iter++;

            if (iter > 2) {
                jQuery('#del_field').show();
            }
        });

        jQuery('#del_field').click(function () {
            if (iter > 2) {
                jQuery('#addr' + (iter - 1)).remove();
                iter--;
            }
            else if (iter === 2) {
                jQuery('#addr' + (iter-1)).children('.left_p').children("#LEFT_PART").val("");
                jQuery('#addr' + (iter-1)).children('.cnd').children("#CONDITION").val("");
                jQuery('#addr' + (iter-1)).children('.right_p').children("#RIGHT_PART").val("");

                jQuery('#addr' + (iter-1)).children('.ignore_pair').children('.ignone_pair_parent').children('#IGNORE_PAIR').val("");
            }
        });
    })
</script>