<script TYPE='text/javascript'>
  'use strict';
  function add_comments() {

    if (document.user_form.DISABLE.checked) {
      document.user_form.DISABLE.checked = false;

      var comments = prompt('_{COMMENTS}_', '');

      if (comments === '' || comments == null) {
        alert('Enter comments');
        document.user_form.DISABLE.checked               = false;
        document.user_form.ACTION_COMMENTS.style.display = 'none';
      }
      else {
        document.user_form.DISABLE.checked               = true;
        document.user_form.ACTION_COMMENTS.value         = comments;
        document.user_form.ACTION_COMMENTS.style.display = 'block';
      }
    }
    else {
      document.user_form.DISABLE.checked               = false;
      document.user_form.ACTION_COMMENTS.style.display = 'block';
      document.user_form.ACTION_COMMENTS.value         = '';
    }
  }

  jQuery(function(){
    jQuery('input#DISABLE').on('click', add_comments );
    if ('%PASSWORD_HIDDEN%' === '1') jQuery('div#PASSWORD_WRAPPER').hide();

    jQuery('#create_company').on('click', function(){
      if (this.checked) {
        var company_name_input = jQuery('<input/>', { 'class' : 'form-control', name : 'COMPANY_NAME', id : 'COMPANY_NAME' });
        jQuery('#create_company_wrapper').after(company_name_input);
        jQuery('#COMPANY_NAME').wrap("<div class='col-md-6 col-xs-12' id='company_name_wrapper'></div>");
      }
      else {
        jQuery('#company_name_wrapper').remove();
      }
    });

    if (jQuery('#create_company_id').val() == 1) {
        var company_name_input = jQuery('<input/>', { 'class' : 'form-control', name : 'COMPANY_NAME', id : 'COMPANY_NAME' });

        jQuery('#create_company').attr('checked','checked')
        jQuery('#create_company_wrapper').after(company_name_input);
        jQuery('#COMPANY_NAME').wrap("<div class='col-md-6 col-xs-12' id='company_name_wrapper'></div>");

        jQuery('#COMPANY_NAME').val(
          jQuery('#company_name').val()
        );
    }

    jQuery('#LOGIN').on('input', function(){
      var value = jQuery('#LOGIN').val();
      doDelayedSearch(value)
    });
  });
  
  var timeout = null;
  var next_disable = 1;
  function doDelayedSearch(val) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function() {
      doSearch(val); //this is your existing function
    }, 500);
  };

  function doSearch(val) {
    if(!val){
      jQuery('#LOGIN').parent().parent().removeClass('has-success').addClass('has-error');
      return 1;
    }
    jQuery.post('$SELF_URL', 'header=2&get_index=' + 'check_login_availability' + '&login_check=' + val, function (data) {
      if(data === 'success') {
        jQuery('#LOGIN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('input[name=next]').removeAttr('disabled', 'disabled');
        next_disable = 1;
        validate_after_login();
      }
      else{
        jQuery('#LOGIN').parent().parent().removeClass('has-success').addClass('has-error');
        jQuery('input[name=next]').attr('disabled', 'disabled');
        next_disable = 2;
      }
    });
  }

</script>

<form class='form-horizontal' action='$SELF_URL' method='post' id='user_form' name='user_form' role='form'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
  <input type=hidden name=step value='$FORM{step}'>
  <input type=hidden name=NOTIFY_FN value='%NOTIFY_FN%'>
  <input type=hidden name=NOTIFY_ID value='%NOTIFY_ID%'>
  <input type=hidden name=TP_ID value='%TP_ID%'>
  <input type=hidden name=REFERRAL_REQUEST value='%REFERRAL_REQUEST%'>
  <input type=hidden name=create_company_id id='create_company_id' value='$FORM{company}'>
  <input type=hidden name=company_name id='company_name' value='$FORM{company_name}'>

  <div id='form_1' class='box box-theme box-big-form for_sort'>
    <div class='box-header with-border'><h3 class='box-title'>_{USER_ACCOUNT}_</h3>
      <div class='box-tools pull-right'>
        <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='box-body'>
      <!--<div style='padding: 10px'>-->

      %EXDATA%

      <line class='visible-xs visible-sm dashed'></line>

      <!-- CREDIT / DATE  -->
      <div class='form-group'>
        <label class='control-label col-xs-4 col-md-2' for='CREDIT'>_{CREDIT}_</label>
        <div class='col-xs-8 col-md-3'>
          <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control r-0-9'
                 type='number' step='0.01' min='0'
                  data-tooltip='_{ERR_CREDIT_CHANGE_LIMIT_REACH}_<br/>
                                <h5>_{SUM}_:</h5>%CREDIT%<br/>
                                <h5>_{DATE}_:</h5>%DATE_CREDIT%'
                  data-tooltip-position='top'>
        </div>

        <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>

        <label class='control-label col-xs-4 col-md-2' for='CREDIT_DATE'>_{TO}_</label>
        <div class='col-xs-8 col-md-5'>
          <input id='CREDIT_DATE' type='text' name='CREDIT_DATE' value='%CREDIT_DATE%'
                 class='datepicker form-control d-0-9'>
        </div>

      </div>

      <line class='visible-xs visible-sm dashed'></line>

      <!-- DISCOUNT / DATE  -->
      <div class='form-group'>
        <label class='control-label col-xs-4 col-md-2' for='REDUCTION'>_{REDUCTION}_(%)</label>
        <div class='col-xs-8 col-md-3'>
          <input type='number' id='REDUCTION' name='REDUCTION' value='%REDUCTION%' placeholder='%REDUCTION%'
                 min='0' max='100' step='0.01' lang=en class='form-control r-0-11'>
        </div>

        <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>

        <label class='control-label col-xs-4 col-md-2' for='REDUCTION_DATE'>_{TO}_</label>
        <div class='col-xs-8 col-md-5'>
          <input id='REDUCTION_DATE' type='text' name='REDUCTION_DATE' value='%REDUCTION_DATE%'
                 class='datepicker form-control d-0-11'>
        </div>
      </div>
      <!-- DISCOUNT / DATE  -->

      <div class='row'>
        <!-- DISABLE -->
        <div class='col-md-6'>
          <div class='checkbox text-center %DISABLE_COLOR% h-0-18'>
            <label for='ACTION_COMMENTS'>
              <input type='checkbox' name='DISABLE' id='DISABLE' value='1' data-checked='%DISABLE%' /> %DISABLE%
              <strong>_{DISABLE}_</strong>
              <!--%DISABLE_MARK%-->
            </label>
              <br>
            %DISABLE_COMMENTS%
            <input class='form-control' type='text' name='ACTION_COMMENTS' ID='ACTION_COMMENTS' value='%DISABLE_COMMENTS%' size='30'
                   style='display : none;' />%ACTION_COMMENTS%
          </div>
        </div>

        <div class='col-md-6' id='PASSWORD_WRAPPER' %HIDE_PASSWORD%>
          <label class='control-label col-md-4'>_{PASSWD}_</label>
          <div class='col-md-8' align='left'>%PASSWORD%</div>
        </div>
      </div>
      <!--<span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'></span>-->

      %DEL_FORM%
      <div class='col-sm-offset-2 col-sm-8'></div>
      <!--</div>-->


      <div class='box box-default box-big-form collapsed-box'>
        <div class='box-header with-border'>
          <h3 class='box-title'>_{EXTRA}_</h3>
          <div class='box-tools pull-right'>
            <button type='button' class='btn btn-box-tool' data-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='box-body'>
          <div class='form-group' %HIDE_COMPANY%>
            <label class='control-label col-xs-4 col-md-2' for='COMP'>_{COMPANY}_</label>
            <div class=' col-xs-8 col-md-4'>
              <div class='input-group'>
                <input type=text name='COMP' value='%COMPANY_NAME%' ID='COMP' class='form-control'
                       readonly>
                <span class='input-group-addon'><a href='$SELF_URL?index=13&amp;COMPANY_ID=%COMPANY_ID%'
                                                   class='glyphicon glyphicon-circle-arrow-left'></a></span>
                <span class='input-group-addon'><a href='$SELF_URL?index=21&amp;UID=$FORM{UID}'
                                                   class='glyphicon glyphicon-pencil'></a></span>
              </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='REG'>_{REGISTRATION}_</label>
            <div class='col-xs-8 col-md-4'>
              <input type=text name='REG' value='%REGISTRATION%' ID='REG' class='form-control' readonly>
            </div>
          </div>
          <div class='form-group' %HIDE_COMPANY%>
            <label class='control-label col-xs-4 col-md-2' for='BILL'>_{BILL}_</label>
            <div class='col-xs-8 col-md-4'>
              <div class='input-group'>
                <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' readonly>
                <span class='input-group-addon'>%BILL_CORRECTION%</span>
              </div>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='EXT_BILL'>!! _{EXTRA_ABBR}_. _{BILL}_</label>
            <div class='col-xs-8 col-md-4'>
              <input type=text name='EXT_BILL_ID' value='%EXT_BILL_ID%' ID='EXT_BILL' class='form-control' readonly>
            </div>
          </div>
          <line class='visible-xs visible-sm dashed'></line>
          <!-- ACTIVATION / EXPIRED -->
          <div class='form-group' style="%ACT_EXP_BTN_HIDE%">
            <label class='control-label col-xs-4 col-md-2' for='ACTIVATE'>_{ACTIVATE}_</label>
            <div class='col-xs-8 col-md-4'>
              <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                     class='form-control datepicker d-0-19' type='text'>
            </div>
            <span class='visible-xs visible-sm col-xs-12' style='padding-top: 5px'> </span>
            <label class='control-label col-xs-4 col-md-2' for='EXPIRE'>_{EXPIRE}_</label>
            <div class='col-xs-8 col-md-4 %EXPIRE_COLOR%'>
              <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                     class='form-control datepicker d-0-20' type='text'>
              <!--    <span class='help-block'>%EXPIRE_COMMENTS%</span> -->
            </div>
          </div>
          <line class='visible-xs visible-sm dashed'></line>

        </div>
      </div>
    </div>
    <div class='box-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
