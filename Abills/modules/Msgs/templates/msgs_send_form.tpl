<script TYPE='text/javascript'>
  function add_comments() {

    var DISPATCH_CREATE = document.getElementById('DISPATCH_CREATE');

    if (DISPATCH_CREATE.checked) {
      DISPATCH_CREATE.checked = false;
      var comments = prompt('_{COMMENTS}_', '');

      var new_dispatch = document.getElementById('new_dispatch');
      var dispatch_list = document.getElementById('dispatch_list');
      var DISPATCH_COMMENTS = document.getElementById('DISPATCH_COMMENTS');

      if (comments === '' || comments === null) {
        alert('Enter comments');
        DISPATCH_CREATE.checked = false;
        new_dispatch.style.display = 'none';
        dispatch_list.style.display = 'block';
      } else {
        DISPATCH_CREATE.checked = true;
        DISPATCH_COMMENTS.value = comments;
        new_dispatch.style.display = 'block';
        dispatch_list.style.display = 'none';
      }
    } else {
      DISPATCH_CREATE.checked = false;
      DISPATCH_COMMENTS.value = '';
      new_dispatch.style.display = 'none';
      dispatch_list.style.display = 'block';
    }
  }

  function add_delivery() {

    var DELIVERY_CREATE = document.getElementById('DELIVERY_CREATE');

    if (DELIVERY_CREATE.checked) {
      DELIVERY_CREATE.checked = false;
      var comments = prompt('_{SUBJECT}_', '');

      var new_delivery = document.getElementById('new_delivery');
      var delivery_list = document.getElementById('delivery_list');
      var DELIVERY_COMMENTS = document.getElementById('SUBJECT');

      if (comments === '' || comments === null) {
        alert('Enter comments');
        DELIVERY_CREATE.checked = false;
        new_delivery.style.display = 'none';
        delivery_list.style.display = 'block';
      } else {
        DELIVERY_CREATE.checked = true;
        DELIVERY_COMMENTS.value = comments;
        new_delivery.style.display = 'block';
        delivery_list.style.display = 'none';
      }
    } else {
      DELIVERY_CREATE.checked = false;
      DELIVERY_COMMENTS.value = '';
      new_delivery.style.display = 'none';
      delivery_list.style.display = 'block';
    }
  }

  var MAX_FILES_COUNT = 3;
  initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
</script>

<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'
      class='form-horizontal'>
  <div>
    %PREVIEW_FORM%
  </div>


  <div class='card container-md'>
    <div class='card-header with-border'><h4 class='card-title'>_{MESSAGES}_</h4></div>
    <div class='card-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='add_form' value='1'/>
      <input type='hidden' name='UID' value='$FORM{UID}'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='PARENT' value='%PARENT%'/>
      <input type='hidden' name='PAR' value='%PAR%'/>
      <input type='hidden' name='step' value='$FORM{step}'/>
      <input type='hidden' name='check_repeat' value='$FORM{CHECK_REPEAT}'/>
      <input type='hidden' name='LOCATION_ID' value='$FORM{LOCATION_ID}'>
      <input type='hidden' name='DISTRICT_ID' value='$FORM{DISTRICT_ID}'>
      <input type='hidden' name='STREET_ID' value='$FORM{STREET_ID}'>
      <input type='hidden' name='ADDRESS_FLAT' value='$FORM{ADDRESS_FLAT}'>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CHAPTER'>_{CHAPTERS}_:</label>
        <div class='col-md-9'>
          %CHAPTER_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-9'>
          <input type='text' name='SUBJECT' id='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%'
                 class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='SUBJECT'>_{MESSAGE}_:</label>
        <div class='col-md-9'>
            <textarea data-action='drop-zone' class='form-control' id='MESSAGE' name='MESSAGE'
                      rows='3'>%TPL_MESSAGE%</textarea>
        </div>
      </div>

      %SEND_TYPES_FORM%
      %SEND_EXTRA_FORM%

      <div class='form-group custom-control custom-checkbox'>
        <input class='custom-control-input' type='checkbox' id='CHECK_FOR_ADDRESS' name='CHECK_FOR_ADDRESS'>
        <label for='CHECK_FOR_ADDRESS' class='custom-control-label'>_{ATTACH_ADDRESS}_</label>
      </div>

      %ADDRESS_FORM%
      %TAGS_FORM%
      %SEND_DELIVERY_FORM%

      <div class='card collapsed-card'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{ADDITIONALLY}_</h4>
          <div class='card-tools pull-right'>
            <button type='button' class='btn btn-box-tool' data-card-widget='collapse'><i
                class='fa fa-plus'></i>
            </button>
          </div>
        </div>

        <div id='nas_misc' class='card-body'>

          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='INNER_MSG' value='1' name='INNER_MSG' %INNER_MSG%>
            <label for='INNER_MSG' class='custom-control-label'>_{PRIVATE}_</label>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='DATE'>_{DATE}_:</label>
            <div class='col-md-9'>
              <input id='DATE' type='text' name='DATE' value='%DATE%' class='datepicker form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='ATTACHMENT'>_{ATTACHMENT}_:</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <div class='custom-file' id='file_upload_holder'>
                  <input name='FILE_UPLOAD' class='custom-file-input' type='file' data-number='0'>
                  <label class='custom-file-label' for='exampleInputFile'>_{ATTACHMENT}_</label>
                </div>
                <div class='input-group-append'>
                  <span class='input-group-text'>_{FILE}_</span>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='STATE'>_{STATE}_:</label>
            <div class='col-md-9'>
              %STATE_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_:</label>
            <div class='col-md-9'>
              %PRIORITY_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='RESPOSIBLE'>_{RESPOSIBLE}_:</label>
            <div class='col-md-9'>
              %RESPOSIBLE%
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='PLAN_TIME'>_{EXECUTION}_:</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <input type='hidden' value='%PLAN_TIME%' name='PLAN_TIME' id='PLAN_TIME'/>
                <input type='hidden' value='%PLAN_DATE%' name='PLAN_DATE' id='PLAN_DATE'/>
                %PLAN_DATETIME_INPUT%
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='DISPATCH'>_{DISPATCH}_:</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <div class='input-group-prepend'>
                  <div class='input-group-text'>
                    _{ADD}_
                    <input type='checkbox' id='DISPATCH_CREATE' name='DISPATCH_CREATE' value='1'
                           onClick='add_comments();' title='_{CREATE}_ _{DISPATCH}_'>
                  </div>
                  %DISPATCH_SEL%
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='CALL_PHONE'>_{PHONE}_:</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <div class='input-group-prepend'>
                  <div class='input-group-text'>
                    <i class='fa fa-phone'></i>
                  </div>
                </div>
                <input class='form-control' name='CALL_PHONE' value='%CALL_PHONE%'
                       placeholder='%CALL_PHONE%'
                       data-inputmask='{'mask' : '(999) 999-9999', 'removeMaskOnSubmit' : true}'
                       type='text'/>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='SURVEY'>_{TEMPLATES}_ (_{SURVEY}_):</label>
            <div class='col-md-9'>
              %SURVEY_SEL%
            </div>
          </div>

          <div class='form-group' style='display: none;'>
            <div class='row'>
              <div class='col-sm-12 col-md-6'>
                <label class='control-label col-md-10' for='DISPATCH_PLAN_DATE'>_{COMMENTS}_</label>
                <div class='input-group'>
                  <input type='text' id='DISPATCH_COMMENTS' name='DISPATCH_COMMENTS' value='%DISPATCH_COMMENTS%'
                         class='form-control'>
                </div>
              </div>

              <div class='col-sm-12 col-md-6'>
                <label class='control-label col-md-10' for='DISPATCH_PLAN_DATE'>_{DATE}_</label>
                <div class='input-group'>
                  <input id='DISPATCH_PLAN_DATE' type='text' name='DISPATCH_PLAN_DATE'
                         value='%DISPATCH_PLAN_DATE%'
                         class='datepicker form-control'>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='card collapsed-card'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{SHEDULE}_</h4>
          <div class='card-tools pull-right'>
            <button type='button' class='btn btn-box-tool' data-card-widget='collapse'><i
                class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='PERIODIC' value='1' name='PERIODIC' %PERIODIC%>
            <label for='PERIODIC' class='custom-control-label'>_{PERIODICALLY}_</label>
          </div>
          <div class='row'>
            <label class='control-label col-md-2'>_{DAY}_:</label>
            <div class='col-md-2'><input class='form-control' name='DAY' value='%DAY%'></div>
            <label class='control-label col-md-2'>_{MONTH}_:</label>
            <div class='col-md-2'><input class='form-control' name='MONTH' value='%MONTH%'></div>
            <label class='control-label col-md-2'>_{YEAR}_:</label>
            <div class='col-md-2'><input class='form-control' name='YEAR' value='%YEAR%'></div>
          </div>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      %BACK_BUTTON%
      <!--Should stay on single line-->
      <input type='submit' name='%ACTION%' class='btn btn-primary' value='%LNG_ACTION%' id='go' title='Ctrl+Enter'/>
    </div>
  </div>

  <div id='confirmModal' class='modal fade' role='dialog'>
    <div class='modal-dialog'>
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal'>&times;</button>
          <h4 class='modal-title'>_{MASS_MAILING}_</h4>
        </div>
        <div class='modal-footer'>
          <input type='submit' name='%ACTION%' class='btn btn-primary' value='%LNG_ACTION%'
                 title='Ctrl+Enter'/>
        </div>
      </div>
    </div>
  </div>

  <div id='confirmRepeatModal' class='modal fade' role='dialog'>
    <div class='modal-dialog'>
      <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal'>&times;</button>
          <h4 id='repeat_title' class='modal-title'></h4>
        </div>
        <div class='modal-footer'>
          <input type='submit' name='%ACTION%' class='btn btn-primary text-center' value='%LNG_ACTION%'
                 title='Ctrl+Enter'/>
        </div>
      </div>
    </div>
  </div>

</FORM>

<script src='/styles/default_adm/js/draganddropfile.js'></script>

<script>
  jQuery(function () {
    var survey_select = jQuery('select#SURVEY_ID');
    survey_select.on('change', function () {
      var select_value = this.value;
      if (select_value) {
        jQuery.ajax({
          url: '$SELF_URL?get_index=msgs_admin&header=2&ajax=1&SURVEY_ID=' + select_value + '',
          success: function (result) {
            if (result) {
              jQuery('textarea#MESSAGE').val(result);
            }
          }
        });
      } else {
        jQuery('textarea#MESSAGE').val('');
      }
    });

    jQuery('#go').on('click', function (e) {
      let form_hash = getFormData();
      if (form_hash['check_repeat'] && parseInt(form_hash['check_repeat'])) {
        let uid = '%UID%' || '';
        let location_id = form_hash['LOCATION_ID'] || '';
        let results = [];

        let link = 'header=2&get_index=msgs_repeat_ticket&UID=' + uid + '&LOCATION_ID=' + location_id;
        jQuery.ajaxSetup({async: false});
        jQuery.get('$SELF_URL', link, function (result) {
          results = result.split(':');
        });

        if (parseInt(results[0])) {
          e.preventDefault();
          jQuery('.modal').modal('hide');
          document.getElementById('repeat_title').innerHTML = results[1] || '';
          jQuery('#confirmRepeatModal').modal('show');
          jQuery.ajaxSetup({async: true});
        }
      }

      if (!form_hash['UID'] && !form_hash['CHECK_FOR_ADDRESS']) {
        e.preventDefault();
        jQuery('.modal').modal('hide');
        jQuery('#confirmModal').modal('show');
      }
    });

    var form_hash = getFormData();
    if (form_hash['UID']) {
      jQuery('#CHECK_ADDRESS').hide();
    }
  });

  function getFormData() {
    var unindexed_array = jQuery('form').serializeArray();
    var indexed_array = {};

    jQuery.map(unindexed_array, function (n, i) {
      indexed_array[n['name']] = n['value'];
    });

    return indexed_array;
  }

  jQuery('#CHECK_FOR_ADDRESS').change(function () {
    if (jQuery(this).is(':checked')) {
      jQuery('#PREVIEW').attr('disabled', true);
      jQuery('#GID').attr('disabled', true);
    } else {
      jQuery('#PREVIEW').attr('disabled', false);
      jQuery('#GID').attr('disabled', false);
    }
  });
</script>