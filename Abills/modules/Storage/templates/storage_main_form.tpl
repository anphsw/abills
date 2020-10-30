<script language='JavaScript'>
  function autoReload() {
    document.depot_form.type.value = 'prihod';
    document.depot_form.submit();
  }
</script>

<form action='$SELF_URL' name='depot_form' method=POST class='form-horizontal'>

  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=%ID%>
  <input type=hidden name=INCOMING_ID value=%STORAGE_INCOMING_ID%>
  <input type=hidden name=type value=prihod2>
  <input type=hidden name=add_article value=1>


  <fieldset>
    <div class='col-md-offset-3 col-md-6'>
      <div class='box box-theme '>
        <div class='box-body'>
          <legend>_{ARTICLE}_</legend>

          <div class='form-group'>
            <label class='col-md-3 control-label'>_{INVOICE_NUMBER}_:</label>
            <div class='col-md-9'>
              <div class='addInvoiceMenu'>
                <div class='input-group'>
                  <!--<select data-download-on-click='1' name='INVOICE_NUMBER' class='form-control SELECT-INVOICE' data-fieldname='INVOICE'>-->
                    <!--<option value='%INVOICE_ID%' selected>%INVOICE_NUMBER%</option>-->
                  <!--</select>-->
                  %INVOICE_SELECT%
                  <!-- Control for toggle build mode SELECT/ADD -->
                  <span class='input-group-addon' %HIDE_ADD_INVOICE_BUTTON%>
                    <a title='_{ADD}_ Invoice' class='BUTTON-ENABLE-ADD'><span class='glyphicon glyphicon-plus'></span></a>
                  </span>
                </div>
              </div>

              <div class='changeInvoiceMenu' style='display : none'>
                <div class='input-group'>
                  <input type='text' name='ADD_INVOICE_NUMBER' class='form-control INPUT-ADD-INVOICE'/>
                  <span class='input-group-addon'>
                    <a class='BUTTON-ENABLE-SEL'>
                    <span class='glyphicon glyphicon-list'></span>
                    </a>
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-3 control-label'>_{TYPE}_:</label>
            <div class='col-md-9'>
              %ARTICLE_TYPES%
            </div>
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
            <label class='col-md-3 control-label'>_{SUPPLIERS}_:</label>
            <div class='col-md-9'>%SUPPLIER_ID%
            </div>
          </div>
          <div class='form-group'>
            <label class='col-md-3 control-label'>_{DATE}_:</label>
            <div class='col-md-9'>%DATE_TIME_PICKER%</div>
          </div>
          <div class='form-group'>
            <label class='col-md-3 control-label required'>_{QUANTITY_OF_GOODS}_: </label>
            <div class='col-md-9'><input class='form-control' required name='COUNT' type='text' value='%COUNT%' %DISABLED%/>
            </div>
          </div>
          <div class='form-group'>
            <label class='col-md-3 control-label required'>_{SUM_ALL}_: </label>
            <div class='col-md-9'><input class='form-control' required name='SUM' type='text' value='%SUM%' %DISABLED%/></div>
          </div>
          <div class='form-group'>
            <label class='col-md-3 '>_{SELL_PRICE}_ <br>(_{PER_ONE_ITEM}_): </label>
            <div class='col-md-9'><input class='form-control' name='SELL_PRICE' type='text' value='%SELL_PRICE%'/></div>
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
                  <label class='col-md-3 control-label'>_{RENT_PRICE}_ (_{MONTH}_): </label>
                  <div class='col-md-9'><input class='form-control' name='RENT_PRICE' type='text' value='%RENT_PRICE%'/>
                  </div>
                </div>
                <div class='form-group'>
                  <label class='col-md-3 control-label'>_{BY_INSTALLMENTS}_: </label>
                  <div class='col-md-9'><input class='form-control' name='IN_INSTALLMENTS_PRICE' type='text'
                                               value='%IN_INSTALLMENTS_PRICE%'/></div>
                </div>
                <div class='form-group'>
                  <label for='METHOD' class='control-label col-sm-3'>_{FEES}_ _{TYPE}_:</label>
                  <div class='col-md-9'>
                    %SEL_METHOD%
                  </div>
                </div>

                <div class='form-group'>
                  <label class='control-label col-md-8' for='ABON_DISTRIBUTION'>_{ABON_DISTRIBUTION}_:</label>
                  <div class='checkbox pull-left'>
                    <input style='margin-left:15px;' id='ABON_DISTRIBUTION' name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%
                           type='checkbox' data-input-disables='PERIOD_ALIGNMENT,FIXED_FEES_DAY'>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group'>
            <label class='col-md-3 control-label'>_{DEPOT_NUM}_: </label>
            <div class='col-md-9'>%STORAGE_STORAGES%
            </div>
          </div>
          <div class='form-group'>
            <label class='col-md-3 control-label'>SN: </label>
            <div class='col-md-9'>
              <input class='form-control' name='SN' type='hidden' value='%SN%'/>
              <input class='form-control' id='SN' name='SERIAL' type='%INPUT_TYPE%' value='%SERIAL%'/> %DIVIDE_BTN%
            </div>
          </div>
          <div class='form-group' %SN_COMMENTS_HIDDEN%>
            <label class='col-md-3 control-label'>_{NOTES}_: </label>
            <div class='col-md-9'>
              <textarea class='form-control' name='SN_COMMENTS'>%SN_COMMENTS%</textarea>
            </div>
          </div>
          %PROPERTIES%
          <div class='form-group'>
            <label class='col-md-3 control-label'>_{COMMENTS}_</label>
            <div class='col-md-9'><textarea class='form-control col-xs-12' name='COMMENTS'>%COMMENTS%</textarea></div>
          </div>


        </div>

        <div class='box-footer'>
          <input type=submit id="SUBMIT_FORM_BUTTON" name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
        </div>

      </div>
    </div>
  </fieldset>

</form>

<script>
  var timeout     = null;
  var start_value = jQuery('#SN').val();

  function doDelayedSearch(val) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function () {
      doSearch(val); //this is your existing function
    }, 500);
  }

  function doSearch(val) {
    if (!val) {
      jQuery('#SN').parent().parent().removeClass('has-success').addClass('has-error');
      return 1;
    }

    document.getElementById('SUBMIT_FORM_BUTTON').disabled = true;
    jQuery.post('$SELF_URL', 'header=2&qindex=' + '%CHECK_SN_INDEX%' + '&sn_check=' + val, function (data) {
      document.getElementById('SUBMIT_FORM_BUTTON').disabled = false;
      if (data === 'success') {
        jQuery('#SN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('#SN').css('border', '3px solid green');
        document.getElementById('SN').setCustomValidity('');
      }
      else if (val === start_value) {
        jQuery('#SN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('#SN').css('border', '3px solid green');
        document.getElementById('SN').setCustomValidity('');
      }
      else {
        jQuery('#SN').parent().parent().removeClass('has-success').addClass('has-error');
        jQuery('#SN').css('border', '3px solid red');
        document.getElementById('SN').setCustomValidity('_{SERIAL_NUMBER_IS_ALREADY_IN_USE}_');
      }
    });
  }

  jQuery('#SN').on('input', function () {
    var value = jQuery('#SN').val();
    doDelayedSearch(value)
  });

</script>

<script src='/styles/default_adm/js/storage.js'></script>