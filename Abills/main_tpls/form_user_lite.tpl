<script TYPE='text/javascript'>
  'use strict';

  function add_comments() {
    if (document.user_form.DISABLE.checked) {
      document.user_form.DISABLE.checked = false;

      if (document.user_form.ACTION_COMMENTS.disabled) {
        document.user_form.ACTION_COMMENTS.style.display = 'block';
        document.user_form.DISABLE.checked = true;
        document.getElementById('DISABLE_LABEL').innerHTML = '_{DISABLE}_';
      } else {
        var comments = prompt('_{COMMENTS}_', '');

        if (comments === '' || comments == null) {
          alert(_COMMENTS_PLEASE);
          document.user_form.ACTION_COMMENTS.style.display = 'none';
        } else {
          document.user_form.DISABLE.checked = true;
          document.user_form.ACTION_COMMENTS.value = comments;
          document.user_form.ACTION_COMMENTS.style.display = 'block';
          document.getElementById('DISABLE_LABEL').innerHTML = '_{DISABLE}_';
        }
      }
    } else {
      document.user_form.ACTION_COMMENTS.style.display = 'none';
      document.getElementById('DISABLE_LABEL').innerHTML = '_{ACTIV}_';
      if (!document.user_form.ACTION_COMMENTS.disabled) {
        document.user_form.ACTION_COMMENTS.value = '';
      }
    }
  }

  function add_comments_multi(e) {
    // That means 'active' so it's option without commenting and checking
    if (e.params.args.data.element.value == 0) {
      document.user_form.ACTION_COMMENTS.style.display = 'none';
      return;
    }

    if (e.params.args.data.element.value) {
      document.user_form.ACTION_COMMENTS.style.display = 'block';
      var comments = prompt('_{COMMENTS}_', '');

      if (comments === '' || comments == null) {
        e.preventDefault();
        alert(_COMMENTS_PLEASE);
        if (document.user_form.DISABLE.value == 0) {
          document.user_form.ACTION_COMMENTS.style.display = 'none';
        }
      } else {
        document.user_form.ACTION_COMMENTS.value = comments;
        document.user_form.ACTION_COMMENTS.style.display = 'block';
        document.user_form.ACTION_COMMENTS.disabled = false;
      }
    }
  }

  jQuery(function () {
    if (jQuery('#CUSTOM_DISABLE_FORM').length) {
      jQuery('#DISABLE_FORM').remove();
    }

    if (
            document.user_form.DISABLE.checked ||
            (document.user_form.DISABLE.checked === undefined &&
                    document.user_form.DISABLE.value != 0)
    ) {
      document.user_form.ACTION_COMMENTS.style.display = 'block';
      document.user_form.ACTION_COMMENTS.disabled = true;
    } else {
      document.user_form.ACTION_COMMENTS.style.display = 'none';
    }

    jQuery('input#DISABLE').on('click', add_comments);  //XXX fix input#DISABLE in form_user_lite, add h-0-18 to it.
    jQuery('select#DISABLE').on('select2:selecting', add_comments_multi);

    jQuery('#create_company').on('click', function () {
      if (this.checked) {
        var company_name_input = jQuery('<input/>', {
          'class': 'form-control',
          name: 'COMPANY_NAME',
          id: 'COMPANY_NAME'
        });
        jQuery('#create_company_wrapper').after(company_name_input);
        jQuery('#COMPANY_NAME').wrap("<div class='col-md-6 col-xs-12' id='company_name_wrapper'></div>");
      } else {
        jQuery('#company_name_wrapper').remove();
      }
    });

    if (jQuery('#create_company_id').val() == 1) {
      var company_name_input = jQuery('<input/>', {'class': 'form-control', name: 'COMPANY_NAME', id: 'COMPANY_NAME'});

      jQuery('#create_company').attr('checked', 'checked')
      jQuery('#create_company_wrapper').after(company_name_input);
      jQuery('#COMPANY_NAME').wrap("<div class='col-md-6 col-xs-12' id='company_name_wrapper'></div>");

      jQuery('#COMPANY_NAME').val(
              jQuery('#company_name').val()
      );
    }

    jQuery('#LOGIN').on('input', function () {
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
    timeout = setTimeout(function () {
      doSearch(val);
    }, 500);
  }

  function doSearch(val) {
    if (!val) {
      jQuery('#LOGIN').removeClass('is-valid').addClass('is-invalid');
      return 1;
    }
    jQuery.post('%SELF_URL%', 'header=2&get_index=' + 'check_login_availability' + '&login_check=' + val, function (data) {
      if (data === 'success') {
        jQuery('#LOGIN').removeClass('is-invalid').addClass('is-valid');
        jQuery('input[name=next]').removeAttr('disabled', 'disabled');
        next_disable = 1;
        validate_after_login();
      } else {
        jQuery('#LOGIN').removeClass('is-valid').addClass('is-invalid');
        jQuery('input[name=next]').attr('disabled', 'disabled');
        next_disable = 2;
      }
    });
  }

</script>

<form action='%SELF_URL%' id='user_form' name='user_form' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='%index%'>
    %MAIN_USER_TPL%
  <input type=hidden name=UID value='%UID%'>

  <!-- General panel -->
  <div id='form_1' class='card card-big-form card-primary card-outline for_sort'>
    <div class='card-header with-border'><h3 class='card-title'>_{USER_ACCOUNT}_ %DISABLE_MARK%</h3>
      <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
      <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <div class='col-sm col-12 form-group'>
          <div class='info-box h-100'>
            <span class='info-box-icon bg-success'>
              <i class='far fa-money-bill-alt'></i>
            </span>
            <div class='info-box-content pr-0'>
              <div class='row'>
                <h3 class='col-md-12'>
                  <span class='info-box-number %DEPOSIT_MARK% ' title='%DEPOSIT%'>%SHOW_DEPOSIT%<a><span class='fa'></span></a></span>
                </h3>
              </div>
              <span class='info-box-text row'>
                <div class='btn-group col-md-12'>
                  %PAYMENTS_BUTTON% %FEES_BUTTON% %PRINT_BUTTON%
                </div>
              </span>
            </div>
          </div>
        </div>
        <div id='CUSTOM_DISABLE_FORM' class='col-sm col-12 form-group h-0-18'>
        <div class='info-box h-100 %DISABLE_COLOR%'>
          <div class='info-box-content'>
            <span class='info-box-text text-center'></span>
            <div class='info-box-content'>
              <div class='text-center'> <!-- %DISABLE% -->
                <div class='custom-control custom-switch custom-switch-on-danger custom-switch-off-success pl-0'>
                  %FORM_DISABLE%
                </div>
              </div>
              <input class='form-control mt-2' type='text' name='ACTION_COMMENTS' ID='ACTION_COMMENTS' value='%DISABLE_COMMENTS%' size='40'
                     style='display: none; height: calc(2rem)' />
            </div>
          </div>
        </div>
      </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-form-label text-md-right' for='CREDIT'>_{CREDIT}_</label>
        <div class='col-sm-4'>
          <input id='CREDIT' name='CREDIT' class='form-control r-0-9' type='number' step='0.01' min='0'
              value='%CREDIT%' data-tooltip='<h5>_{SUM}_:</h5>%CREDIT%<br/><h5>_{DATE}_:</h5>%DATE_CREDIT%'
              data-tooltip-position='top'>
        </div>

        <label class='col-sm-2 col-form-label text-md-right' for='CREDIT_DATE'>_{DATE}_</label>
        <div class='col-sm-4'>
          <input id='CREDIT_DATE' name='CREDIT_DATE' class='datepicker form-control d-0-9' type='text'
              value='%CREDIT_DATE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-2 col-form-label text-md-right' for='REDUCTION'>_{REDUCTION}_(%)</label>
        <div class='col-sm-4'>
          <input id='REDUCTION' name='REDUCTION' class='form-control r-0-11' type='number' min='0' max='100' value='%REDUCTION%' step='0.01'>
        </div>

        <label class='col-sm-2 col-form-label text-md-right' for='REDUCTION_DATE'>_{DATE}_</label>
        <div class='col-sm-4'>
          <input id='REDUCTION_DATE' name='REDUCTION_DATE' class='datepicker form-control d-0-11' type='text' value='%REDUCTION_DATE%'>
        </div>
      </div>
      <div %HIDE_PASSWORD% class='text-center'>%PASSWORD%</div>
    </div>

    <div class='card card-secondary card-outline collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group'>
          <div class='row'>
            <div class='col-sm-12 col-md-6'>
              <div class='form-group row'>
                <label  class='col-sm-2 col-md-4 col-form-label' for='ACTIVATE'>_{ACTIVATE}_</label>
                <div class='col-sm-10 col-md-8'>
                  <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                    class='form-control datepicker d-0-19' type='text'>
                </div>
              </div>
            </div>
            <div class='col-sm-12 col-md-6'>
              <div class='form-group row'>
                <label  class='col-sm-2 col-md-4 col-form-label' for='EXPIRE'>_{EXPIRE}_</label>
                <div class='col-sm-10 col-md-8'>
                  <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                    class='form-control datepicker d-0-20' type='text'>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-md-2 col-form-label' for='COMP'>_{COMPANY}_</label>
          <div class='col-sm-10 col-md-10'>
            <div class='input-group'>
              <input type=text name='COMP' value='%COMPANY_NAME%' ID='COMP' class='form-control' disabled readonly>
              <div class='input-group-append'>
                <a href='%SELF_URL%?index=13&amp;COMPANY_ID=%COMPANY_ID%'
                  class='btn input-group-button'>
                  <i class='fa fa-arrow-circle-left'></i>
                </a>
              </div>
              <div class='input-group-append'>
                <a href='%SELF_URL%?index=21&UID=%UID%' class='btn input-group-button'>
                  <i class='fa fa-pencil-alt'></i>
                </a>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row' style='%GROUP_PERMISSION%'>
          <label  class='col-sm-2 col-form-label'>_{GROUP}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
              <input type=text name='GRP' value='%GID%:%G_NAME%' ID='GRP' %GRP_ERR% class='form-control' disabled readonly>
              <div class='input-group-append'>
                <a href='%SELF_URL%?index=12&UID=%UID%' class='btn input-group-button'>
                  <span class='fa fa-pencil-alt'></span>
                </a>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group'>
          <div class='row'>
            <div class='col-sm-12 col-md-6'>
              <div class='form-group row'>
                <label  class='col-sm-2 col-md-4 col-form-label' for='REG'>_{REGISTRATION}_</label>
                <div class='col-sm-10 col-md-8'>
                  <input type=text name='REG' value='%REGISTRATION%' ID='REG' class='form-control' disabled readonly>
                </div>
              </div>
            </div>

            <div class='col-sm-12 col-md-6'>
              <div class='form-group row'>
                <label  class='col-sm-2 col-md-4 col-form-label' for='BILL'>_{BILL}_</label>
                <div class='col-sm-10 col-md-8'>
                  <div class='input-group'>
                    <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' disabled readonly>
                    <div class='input-group-append'>
                      %BILL_CORRECTION%
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type=submit name='%ACTION%' id='ACTION' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
