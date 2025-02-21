<form class='form-horizontal' id='task_add_form'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='PARENT_ID' value='%PARENT_ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'><h3 class='card-title'>%BOX_TITLE%</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body' id='task_form_body'>

      %PARENT_TASK%

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='task_type'>_{TASK_TYPE}_:</label>
        <div class='col-md-8'>
          %SEL_TASK_TYPE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label  text-md-right required' for='NAME'>_{TASK_NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' name='NAME' id='NAME' value='%NAME%' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='DESCR'>_{TASK_DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='DESCR' id='DESCR'>%DESCR%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='responsible'>_{RESPONSIBLE}_:</label>
        <div class='col-md-8'>
          %SEL_RESPONSIBLE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='responsible'>_{PARTCIPIANTS}_:</label>
        <div class='col-md-8'>
          <input type='hidden' id='PARTICIPANTS_LIST' name='PARTICIPANTS_LIST' value='%PARTICIPANTS_LIST%'>
          <button type='button' class='btn btn-primary float-left' data-toggle='modal' data-target='#myModal'
                  onClick='return openModal()'>_{SELECTED}_: <span class='admin_count'></span></button>
        </div>
      </div>
      <!-- Modal -->
      <div class='modal fade' id='myModal' role='dialog'>
        <div class='modal-dialog'>

          <!-- Modal content-->
          <div class='modal-content'>
            <div class='modal-header'>
              <h4 class='modal-title'>_{PARTCIPIANTS}_</h4>
              <button type='button' class='close' data-dismiss='modal'>&times;</button>
            </div>
            <div class='modal-body'>
              %ADMINS_LIST%
            </div>
            <div class='modal-footer'>
              <button type='button' class='btn btn-default' data-dismiss='modal' onClick='return closeModal()'>
                _{CLOSE}_
              </button>
            </div>
          </div>

        </div>
      </div>
      <hr>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CONTROL_DATE'>_{DUE_DATE}_:</label>
        <div class='col-md-8'>
          <input type='text' class='datepicker form-control' value='%CONTROL_DATE%' name='CONTROL_DATE'
                 id='CONTROL_DATE'>
        </div>
      </div>

      %PLUGINS_FIELDS%
      <hr>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TASKS_SUBTASKS}_:</label>
        <div class='col-md-8'>
          %SUBTASKS%
        </div>
      </div>

    </div>

    <div class='modal fade' id='myModal1' role='dialog'>
      <div class='modal-dialog'>

        <!-- Modal content-->
        <div class='modal-content'>
          <div class='modal-header'>
            <h4 class='modal-title'>_{CLOSE_TASK}_</h4>
            <button type='button' class='close' data-dismiss='modal'>&times;</button>
          </div>
          <div class='modal-body'>
            <div class='form-group row'>
              <div class='col-md-12'>
                <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS' placeholder='_{COMMENTS}_'></textarea>
              </div>
            </div>
          </div>
          <div class='modal-footer'>
            <input type='submit' name='done' value='_{DONE}_' class='btn btn-success'>
            <input type='submit' name='undone' value='_{UNDONE}_' class='btn btn-danger'>
          </div>
        </div>

      </div>
    </div>

    <div class='card-footer'>
      <button type='button' class='btn btn-success' data-toggle='modal' data-target='#myModal1'>_{CLOSE_TASK}_</button>
      <input type=submit name='%BTN_ACTION%' value='%BTN_NAME%' class='btn btn-primary'>
    </div>
  </div>

</form>


<script type="text/javascript">
  try {
    var types = JSON.parse('%TASK_TYPES%');

  } catch (err) {
    console.log(err);
  }
  var oldresponsible = '%RESPONSIBLE%';

  function rebuild_form(type_num) {
    console.log(type_num)
    jQuery('.appended_field').remove();
    jQuery('.plugin_field').remove();

    setCheckboxes(types[type_num]?.['PARTICIPANTS']);

    let admins = types[type_num]?.['ADMINS'] || [];
    const stringAdmins = admins.map(String);
    jQuery('#RESPONSIBLE option').each(function () {
      var aid = jQuery(this).attr("value");

      if (aid == 0) {
        jQuery(this).prop("disabled", true);
      } else if (!admins.length || stringAdmins.includes(String(aid))) {
        jQuery(this).prop("disabled", false);
      } else {
        jQuery(this).prop("disabled", true);
      }
    });

    let selected = admins[0] || 1;

    if (oldresponsible && stringAdmins.indexOf(oldresponsible) >= 0) {
      selected = oldresponsible;
    }
    jQuery("#RESPONSIBLE").val(selected).trigger("change");

    let addFields = types[type_num]?.['ADDITIONAL_FIELDS'] || [];
    jQuery.each(addFields, function (field, element) {
      jQuery('#task_form_body')
        .append(
          jQuery('<div></div>')
            .addClass('form-group appended_field row')
            .append(
              jQuery('<label></label>')
                .attr('for', element['NAME'])
                .text(element['LABEL'])
                .addClass('control-label col-md-4')
            )
            .append(
              jQuery("<div></div>")
                .addClass("col-md-8")
                .append(
                  jQuery("<input />")
                    .attr('name', element['NAME'])
                    .attr('id', element['NAME'])
                    .attr('type', element['TYPE'])
                    .addClass('form-control')
                )
            )
        );
    });

    let plugins = types[type_num]?.['PLUGINS'] || [];
    jQuery.each(plugins, function (field, element) {
      if (!Array.isArray(element?.['FIELDS'])) return;

      element['FIELDS'].forEach(field => {
        jQuery('#task_form_body')
          .append(
            jQuery('<div></div>')
              .addClass('form-group plugin_field row')
              .append(
                jQuery('<label></label>')
                  .attr('for', field['NAME'])
                  .text(field['LABEL'])
                  .addClass('control-label col-md-4')
              )
              .append(
                jQuery("<div></div>")
                  .addClass("col-md-8")
                  .append(
                    jQuery("<input />")
                      .attr('name', field['NAME'])
                      .attr('id', field['NAME'])
                      // .val(`%${field['NAME']}%`)
                      .addClass('form-control')
                  )
              )
          );
      });
    });
  }

  function closeModal() {
    var participantsArr = [];
    jQuery('.admin_checkbox').each(function () {
      if (this.checked) {
        participantsArr.push(jQuery(this).attr("aid"));
      }
    });
    jQuery('.admin_count').text(participantsArr.length);
    document.getElementById('PARTICIPANTS_LIST').value = participantsArr.join();
  }

  function setCheckboxes(participants) {
    if (!Array.isArray(participants)) return;

    let count = 0;
    const stringParticipants = participants.map(String);

    jQuery('.admin_checkbox').each(function () {
      if (stringParticipants.includes(String(jQuery(this).attr('aid')))) {
        jQuery(this).prop('checked', true);
        count++;
      } else {
        jQuery(this).prop('checked', false);
      }
    });
    jQuery('.admin_count').text(count);
  }

  jQuery(function () {
    rebuild_form(jQuery('#TASK_TYPE').val());

    jQuery('#TASK_TYPE').change(function () {
      rebuild_form(jQuery('#TASK_TYPE').val());
    });

    jQuery('#task_add_form').submit(function (event) {
      if (jQuery('#CONTROL_DATE').val() === '') {
        alert('Укажите дату.');
        event.preventDefault();
      } else if (jQuery('#DESCR').val() === '') {
        alert('Введите описание задачи.');
        event.preventDefault();
      } else if (jQuery('#RESPONSIBLE').val() === '') {
        alert('Укажите ответственного.');
        event.preventDefault();
      }
    });
  });
</script>
