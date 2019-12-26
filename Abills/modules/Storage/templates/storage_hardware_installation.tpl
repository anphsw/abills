<script language='JavaScript'>
  function autoReload() {
    document.storage_hardware_form.type.value = 'prihod';
    document.storage_hardware_form.submit();
  }

  function rebuild_form(status){
    console.log(status);
    if(status == 3){
      console.log("Add monthes input");
      var element = jQuery("<div></div>").addClass("form-group appended_field");
      element.append(jQuery("<label for=''></label>").text("_{MONTHES}_").addClass("col-md-3 control-label"));
      element.append(jQuery("<div></div>").addClass("col-md-9").append(
        jQuery("<input name='MONTHES' id='MONTHES' value='%MONTHES%'>").addClass("form-control")));

      jQuery('#storage_monthes_by_installments').append(element);
    }
    else{
      console.log("Remove monthes input");
      jQuery('.appended_field').remove();
    }
  }

  function disableInputs(context) {
    var j_context = jQuery(jQuery(context).attr('href'));

    j_context.find('input').prop('disabled', true);
    j_context.find('select').prop('disabled', true);

    updateChosen();
  }

  function enableInputs(context) {
    var j_context = jQuery(jQuery(context).attr('href'));

    j_context.find('input').prop('disabled', false);
    j_context.find('select').prop('disabled', false);


  }

  jQuery(document).ready(function() {
    jQuery('#menu1').find('input').prop('disabled', true);
    jQuery('#menu1').find('select').prop('disabled', true);
    jQuery('#menu1').find('textarea').prop('disabled', true);
    jQuery('#home').find('input').prop('disabled', true);
    jQuery('#home').find('select').prop('disabled', true);
    jQuery('#home').find('textarea').prop('disabled', true);
    updateChosen();
  });

  jQuery(function () {
    jQuery('a[data-toggle=\"tab\"]').on('shown.bs.tab', function (e) {
      console.log(e);
      enableInputs(e.target);
      disableInputs(e.relatedTarget);
    })
  });


  jQuery(function () {
    if(jQuery('#STATUS').val()) {
      rebuild_form(jQuery('#STATUS').val());
    }

    jQuery("#STATUS").change(function () {
      rebuild_form(jQuery('#STATUS').val());

    });
  });

  jQuery(function () {
    //    jQuery('#REG_REQUEST_BTN').prop('disabled', true);
    var timeout = null;

    function doDelayedSearch(val, element) {
      if (timeout) {
        clearTimeout(timeout);
      }
      timeout = setTimeout(function() {
        doSearch(val, element); //this is your existing function
      }, 500);
    };

    function doSearch(val, element) {
      if(!val){
        console.log("Value is empty");
        return 1;
      }
      jQuery.post('$SELF_URL', 'header=2&qindex=' + '%MAIN_INDEX%' + '&get_info_by_sn=' + val, function (data) {
        console.log(data);
        var info;
        try {
          info = JSON.parse(data);
        }
        catch (Error) {
          console.log(Error);
          alert("Cant handle info");
          return 1;
        }
        if(info.error){
          jQuery(element).parent().removeClass('has-success').addClass('has-error');
          jQuery(element).css('border', '3px solid red');
          jQuery('#sell_price').val('');
          jQuery('.item_info_by_sn').text('');
        }
        else{
          console.log("success");
          jQuery(element).parent().removeClass('has-error');
          jQuery(element).css('border', "");
          jQuery('#sell_price').val(info.SELL_PRICE);
//          jQuery('.item_info_by_sn').text(info.ARTICLE_TYPE_NAME + " " + info.ARTICLE_NAME);
          jQuery('.item_info_by_sn').append('<label class="control-label col-md-3">_{ARTICLE}_</label><div class="col-md-9"><input type="text" value="' + info.ARTICLE_TYPE_NAME + ' ' + info.ARTICLE_NAME + '" class="form-control" disabled></div>');
        }

      });
    }

    jQuery('.sn_installation').on('input', function(event){
//      console.log(this);
      var element = event.target;
      var value = jQuery(element).val();
      console.log(value);
      doDelayedSearch(value, element);
    });
  });
</script>

<script>
  function selectArticles(empty_sel) {
    console.log("Changed");
    empty_search = "";
    if(empty_sel == 1){
      empty_search = "&EMPTY_SEL=" + empty_sel;
    }
    jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_hardware&quick_info=1&ARTICLE_TYPE_ID=' + jQuery('#ARTICLE_TYPE_ID').val() + empty_search, function (result) {
      jQuery("div.ARTICLES_S").empty();
      jQuery("div.ARTICLES_S").html(result);
      initChosen();
      console.log(result);
    });

    console.log("Ending");
  };

</script>

<form action=$SELF_URL name='storage_hardware_form' method=POST class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=CHG_ID value=%CHG_ID%>
  <input type=hidden name='type' value='prihod2'>
  <input type=hidden name=ajax_index value=$index>
  <input type=hidden name=UID value=$FORM{UID}>
  <input type=hidden name=OLD_MAC value=%OLD_MAC%>
  <input type=hidden name=COUNT1 value=%COUNT1%>
  <input type=hidden name=ARTICLE_ID1 value=%ARTICLE_ID1%>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='STORAGE_MSGS_ID' value='$FORM{STORAGE_MSGS_ID}'>
  <fieldset>

    <div class='box box-theme box-form'>
      <div class="box-header"><ul class="nav nav-tabs" role="tablist">
        <li class="active"><a data-toggle="tab" href="#main">_{MAIN}_</a></li>
        <li><a data-toggle="tab" href="#home">_{STORAGE}_</a></li>
        <li><a data-toggle="tab" href="#menu1">_{ACCOUNTABILITY}_</a></li>
      </ul></div>
      <div class='box-body form'>


        <div class="tab-content">
          <!--Main content-->
          <div id="main" class="tab-pane fade in active">
            <input type='hidden' name='fast_install' value='1'>
            <div class='form-group'>
              <label class='col-md-3 control-label'>SN:</label>
              <div class='col-md-9'><input class='form-control sn_installation' name='SERIAL' type='text' VALUE='%SERIAL%'
                                           autofocus/></div>
            </div>

            <div class="form-group item_info_by_sn">

            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{SELL_PRICE}_:</label>
              <div class='col-md-9'><input class='form-control' name='ACTUAL_SELL_PRICE' type='text' value='%ACTUAL_SELL_PRICE%'
                                           id="sell_price"/></div>
            </div>
          </div>

          <!--Home Content-->
          <div id="home" class="tab-pane fade">
            <input type=hidden name=ID value=%ID%>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{TYPE}_:</label>
              <div class='col-md-9'>%ARTICLE_TYPES%</div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{NAME}_:</label>

              <div class='col-md-9'>
                <div class="ARTICLES_S">
                  %ARTICLE_ID%
                </div>
              </div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{COUNT}_:</label>
              <div class='col-md-9'><input class='form-control' name='COUNT' type='text' value='%COUNT%' %DISABLE%/>
              </div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{SELL_PRICE}_:</label>
              <div class='col-md-9'><input class='form-control' name='ACTUAL_SELL_PRICE' type='text' value=''/></div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>SN:</label>
              <div class='col-md-9'><textarea class='form-control col-xs-12' name='SERIAL'>%SERIAL%</textarea></div>
            </div>
          </div>

          <!--Menu1 Content-->
          <div id="menu1" class="tab-pane fade">
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{NAME}_:</label>
              <div class='col-md-9'>%IN_ACCOUNTABILITY_SELECT%</div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>_{COUNT}_:</label>
              <div class='col-md-9'><input class='form-control' name='COUNT_ACCOUNTABILITY' type='text' value='%COUNT%'
                                           %DISABLE%/></div>
            </div>
            <div class='form-group'>
              <label class='col-md-3 control-label'>SN:</label>
              <div class='col-md-9'><textarea class='form-control col-xs-12' name='SERIAL'>%SERIAL%</textarea></div>
            </div>
          </div>
        </div>

        <div class='form-group'>
          <label class='col-md-3 control-label'>_{ACTION}_:</label>
          <div class='col-md-9'>%STATUS% %STORAGE_DOC_CONTRACT% %STORAGE_DOC_RECEIPT%</div>
        </div>
        <div id='storage_monthes_by_installments'>

        </div>

        <div class='form-group'>
          <div class='box collapsed-box box-theme box-big-form'>
            <div class='box-header with-border text-center'>
              <h3 class='box-title'>_{EXTRA}_</h3>
              <div class='box-tools pull-right'>
                <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='box-body'>
              <div class='form-group'>
                <label class='col-md-3 control-label'>_{RESPONSIBLE}_ _{FOR_INSTALLATION}_:</label>
                <div class='col-md-9'>%INSTALLED_AID_SEL%</div>
              </div>
              <!--
                      <div class='form-group'>
                        <label class='col-md-3 control-label'>Grounds:</label>
                        <div class='col-md-9'><input class='form-control' name='GROUNDS' type='text' value='%GROUNDS%'/></div>
                      </div>
              -->
              <div class='form-group'>
                <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
                <div class='col-md-9'><input name='COMMENTS' class='form-control' type='text' value='%COMMENTS%'/></div>
              </div>

              %DHCP_ADD_FORM%
            </div>
          </div>
        </div>

      </div>
      <div class='box-footer'>
        %BACK_BUTTON% <input type=submit name='%ACTION%' value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
      </div>
    </div>
  </fieldset>
</form>
