<script>
    jQuery(document).ready(function () {
        //find NAS_TYPE Select
        var typeSelect = jQuery('#NAS_TYPE');

        //find wiki-link button '?'
        var wikiLink = jQuery('#wiki-link');

        //get base url from wiki-link
        var wiki_NAS_Href = wikiLink.attr('href');

        //define handler for select
        //here we need to change href link regarding to selected option
        typeSelect.on('change', function () {

            wikiLink.fadeToggle();
            wikiLink.fadeToggle();
            var selected = typeSelect.val();
            wikiLink.attr('href', wiki_NAS_Href + ':' + selected + ':ru');
        });
    });
</script>

<form action=$SELF_URL METHOD=post name=FORM_NAS class='form-horizontal' role='form'>
    <fieldset>

        <input type=hidden name='index' value='62'>
        <input type=hidden name='NAS_ID' value='%NAS_ID%'>
        <input type=hidden name='NAS_RAD_PAIRS' id="NAS_RAD_PAIRS" value='%NAS_RAD_PAIRS%'>

        <div class='row'>

            <div class='col-md-6'>
                <div class='box box-theme box-form-big'>
                    <div class='box-header with-border'><h4 class='box-title'>_{NAS}_</h4></div>
                    <div class='box-body'>

                        <div class='form-group'>
                            <label for='NAS_IP' class='control-label col-md-3 required'>IP</label>

                            <div class='col-sm-9'>
                                <input type=text class='form-control ip-input' required id='NAS_IP'
                                       placeholder='%IP%' name='IP' value='%NAS_IP%'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_NAME' class='control-label col-md-3 required'>_{NAME}_ (a-zA-Z0-9_)</label>

                            <div class='col-md-9'>
                                <input type='text' class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%'
                                       name='NAS_NAME'
                                       value='%NAS_NAME%' required pattern='^\\w*\$' maxlength='30'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_TYPE' class='control-label col-md-3 required'>_{TYPE}_</label>

                            <div class='col-sm-9' id='NAS-type-wrapper'>
                                <div class='col-md-8'>
                                    %SEL_TYPE%
                                </div>

                                <div class='col-md-1'>
                                    <a class='btn btn-info' id='wiki-link' data-tooltip='_{GUIDE_WIKI_LINK}_'
                                       href='http://abills.net.ua/wiki/doku.php/abills:docs:nas'
                                       target='_blank'>?</a>
                                </div>

                                <div class='col-md-1'>
                                    %WINBOX%
                                </div>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_ALIVE' class='control-label col-sm-3'>Alive (sec.)</label>

                            <div class='col-sm-9'>
                                <input class='form-control' id='NAS_ALIVE' placeholder='%NAS_ALIVE%' name='NAS_ALIVE'
                                       value='%NAS_ALIVE%'>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label for='NAS_DISABLE' class='control-label col-sm-3'>_{DISABLE}_</label>

                            <div class='col-sm-5'>
                                <input type='checkbox' id='NAS_DISABLE' name='NAS_DISABLE' value='1' %NAS_DISABLE%>
                            </div>
                        </div>
                        <div class='form-group'>
                            <label class='col-md-12 bg-primary'>_{MANAGE}_</label>
                        </div>

                        <div class='form-group'>

                            <label class='control-label col-md-3' for='NAS_MNG_IP'>IP</label>

                            <div class='col-md-4'>
                                <input id='NAS_MNG_IP' name='NAS_MNG_IP' value='%NAS_MNG_IP%'
                                       placeholder='IP' class='form-control' type='text'>
                            </div>
                            <label class='control-label col-md-2' for='COA_PORT'>POD/COA</label>

                            <div class='col-md-3'>
                                <input id='COA_PORT' name='COA_PORT' value='%COA_PORT%'
                                       placeholder='PORT' class='form-control' type='text'>
                            </div>
                        </div>
                        <div class='form-group'>

                            <label class='control-label col-md-3' for='SSH_PORT'>SSH</label>

                            <div class='col-md-4'>
                                <input id='SSH_PORT' name='SSH_PORT' value='%SSH_PORT%'
                                       placeholder='PORT' class='form-control' type='text'>
                            </div>
                            <label class='control-label col-md-2' for='SNMP_PORT'>SNMP</label>

                            <div class='col-md-3'>
                                <input id='SNMP_PORT' name='SNMP_PORT' value='%SNMP_PORT%'
                                       placeholder='PORT' class='form-control' type='text'>
                            </div>
                        </div>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='NAS_MNG_USER'>_{USER}_</label>

                            <div class='col-md-9'>


                                <div class='input-group'>
                                    <input id='NAS_MNG_USER' name='NAS_MNG_USER' value='%NAS_MNG_USER%'
                                           placeholder='%NAS_MNG_USER%'
                                           class='form-control' type='text'>
                                    <span class='input-group-addon'>
                    <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&create=1&ssh_key=1'
                       class='fa fa-key' target='_new' title='_{CREATE}_ SSH public key'></a>
                                    </span>
                                    <span class='input-group-addon'>
                    <a href='$SELF_URL?qindex=$index&NAS_ID=%NAS_ID%&download=1&ssh_key=1'
                       class='fa fa-download' target='_new' title='_{DOWNLOAD}_ SSH public key'></a>
                    </span>
                                </div>


                            </div>
                        </div>
                        <div class='form-group'>
                            <label class='control-label col-md-3' for='NAS_MNG_PASSWORD'>_{PASSWD}_ (PoD,RADIUS
                                Secret,SNMP)</label>

                            <div class='col-md-9'>
                                <input id='NAS_MNG_PASSWORD' name='NAS_MNG_PASSWORD' class='form-control'
                                       type='password'>
                            </div>
                        </div>
                        <div class='form-group'>
                            %ADDRESS_FORM%
                        </div>


                    </div>
                </div>

            </div>
            <div class='col-md-6'>
                <div class='form-group'>
                    <div class='box box-theme box-form-big collapsed-box'>
                        <div class='box-header with-border'> <h4 class='box-title'>_{EXTRA}_</h4>
                            <div class='box-tools pull-right'>
                                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'><i class='fa fa-plus'></i>
                                </button>
                            </div>
                           <!-- <a data-toggle='collapse' data-parent='#accordion' href='#nas_misc'>_{EXTRA}_</a>

                           <div class='box-header with-border'><h4 class='box-title'>_{NAS}_</h4></div> -->
                        </div>
                        <div id='nas_misc' class='box-collapse box-body collapse in'>


                            %NAS_ID_FORM%
                            <div class='form-group'>
                                <label for='NAS_DESCRIBE' class='control-label col-md-3'>_{DESCRIBE}_</label>

                                <div class='col-md-9'>
                                    <input class='form-control' id='NAS_DESCRIBE' placeholder='%NAS_DESCRIBE%'
                                           name='NAS_DESCRIBE'
                                           value='%NAS_DESCRIBE%'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='NAS_IDENTIFIER'>Radius NAS-Identifier</label>

                                <div class='col-md-9'>
                                    <input id='NAS_IDENTIFIER' name='NAS_IDENTIFIER' value='%NAS_IDENTIFIER%'
                                           placeholder='%NAS_IDENTIFIER%' class='form-control' type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='MAC'>MAC</label>

                                <div class='col-md-9'>
                                    <input id='MAC' name='MAC' value='%MAC%' placeholder='%MAC%' class='form-control'
                                           type='text'>
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='AUTH_TYPE'>_{AUTH}_</label>

                                <div class='col-md-9'>
                                    %SEL_AUTH_TYPE%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label class='control-label col-md-3' for='EXT_ACCT'>External Accounting</label>

                                <div class='col-md-9'>
                                    %NAS_EXT_ACCT%
                                </div>
                            </div>

                            <div class='form-group'>
                                <label for='NAS_GROUPS' class='control-label col-sm-3'>_{GROUP}_</label>

                                <div class='col-md-9'>
                                    %NAS_GROUPS_SEL%
                                </div>
                            </div>
                            <div class='form-group'>
                                <label for='ZABBIX_HOSTID' class='control-label col-sm-3'>Zabbix hostid</label>

                                <div class='col-md-9'>
                                    <input id='ZABBIX_HOSTID' name='ZABBIX_HOSTID' value='%ZABBIX_HOSTID%' class='form-control' type='text'>
                                </div>
                            </div>


                            <div class='form-group'>
                                <label class='col-md-12'>RADIUS _{PARAMS}_</label>

                                <div class='col-md-12'>
                                    <table class='table table-bordered table-hover'>

                                        <thead>
                                        <tr>
                                            <th class='text-center col-md-1'>
                                                #
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
                                            <td class="ids">
                                                <input type='hidden' name='IDS' value='1'>
                                                1
                                            </td>
                                            <td class="left_p">
                                                <input type='text' name='LEFT_PART' id='LEFT_PART' value='%LEFT_PART%'
                                                       placeholder='_{LEFT_PART}_' class='form-control'/>
                                            </td>
                                            <td class="cnd">
                                                <input type='text' name='CONDITION' id='CONDITION' value='%CONDITION%' placeholder='='
                                                       class='form-control'/>
                                            </td>
                                            <td class="right_p">
                                                <input type='text' name='RIGHT_PART' id='RIGHT_PART'
                                                       value='%RIGHT_PART%' placeholder='_{RIGHT_PART}_'
                                                       class='form-control'/>
                                            </td>
                                        </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <div class='col-md-2 col-xs-2 pull-right' style="padding-right: 0">
                                    <a title="_{ADD}_" class='btn btn-sm btn-default' id='add_field'>
                                        <span class='glyphicon glyphicon-plus'></span>
                                    </a>
                                </div>
                                <div class='col-md-2 col-xs-2 pull-right' style="padding-right: 0">
                                    <a title="_{ADD}_" class='btn btn-sm btn-default' id='del_field'>
                                        <span class='glyphicon glyphicon-minus'></span>
                                    </a>
                                </div>
                            </div>

                            <div>

                                %EXTRA_PARAMS%

                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <div class='row'>
            <div class='box-footer'>
                <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
            </div>
        </div>

    </fieldset>
</form>

<script>
    jQuery(function () {
        var iter = 2;

        var date = document.getElementById('NAS_RAD_PAIRS').value;
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
                if (/([0-9a-zA-Z\-!]+)([-+=]{1,2})([:\-#= 0-9a-zA-Zа-яА-Я.]+)/.test(answDate[element])) {
                    let dateRegex = answDate[element].match(/([0-9a-zA-Z\-!]+)([-+=]{1,2})([:\-#= 0-9a-zA-Zа-яА-Я.]+)/);
                    if (element < answDate.length) {
                        jQuery('#addr1').clone(true)
                            .attr('id', 'addr' + iter)
                            .show()
                            .appendTo('#tab_logic');

                        jQuery('#addr' + iter).children('.ids').text(iter);

                        jQuery('#addr' + (iter - 1)).children('.left_p').children("#LEFT_PART").val(dateRegex[1]);
                        jQuery('#addr' + (iter - 1)).children('.cnd').children("#CONDITION").val(dateRegex[2]);
                        jQuery('#addr' + (iter - 1)).children('.right_p').children("#RIGHT_PART").val(dateRegex[3]);

                        iter++;
                    }
                }
                element++;
            }

            if (iter > 3) {
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
            }
        });
    })
</script>