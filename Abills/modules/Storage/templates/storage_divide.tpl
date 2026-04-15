<form method='POST' action='%SELF_URL%'>
  <input type='hidden' name='INCOMING_ARTICLE_ID' value='%INCOMING_ARTICLE_ID%'>
  <input type='hidden' name='AVAILABLE_COUNT' value='%COUNT%' id='availableCount'>
  <input type='hidden' name='index' value='%index%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{STORAGE_INCOMING_ARTICLE_SPLIT}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input readonly value='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COUNT}_:</label>
        <div class='col-md-8'>
          <input readonly value='%COUNT%' class='form-control' type='text'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STORAGE_HOW_MANY_UNITS_TO_DIVIDE}_</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='number' id='splitCount' class='form-control' min='1' max='%COUNT%' value='1'>

            <div class='input-group-append'>
              <button type='button' id='generateRows' class='btn btn-secondary'>
                _{CREATE}_
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  %DIVIDE_TABLE%

  <div class='card-footer'>
    <button type='submit' name='divide_all' value='_{DIVIDE}_' id='DIVIDE_BUTTON' class='btn btn-primary'>_{DIVIDE}_</button>
  </div>

</form>

<script>
  jQuery(document).ready(function () {

    jQuery('#generateRows').on('click', function () {
      let count = parseInt(jQuery('#splitCount').val());
      let max = parseInt(jQuery('#availableCount').val());

      if (count > max) {
        jQuery('#splitCount').val(max)
        return;
      }

      let table = jQuery('#splitTable_');
      let tbody = table.find('tbody');

      if (!tbody.length) {
        tbody = jQuery('<tbody></tbody>');
        table.append(tbody);
      }

      tbody.empty();

      for (let i = 1; i <= count; i++) {
        tbody.append(`
        <tr>
          <td>` + i + `</td>
          <td><input type='text' name='SERIAL' class='form-control serial-number-input' placeholder='SN'></td>
          <td><input type='text' name='SN_COMMENTS' class='form-control' placeholder='_{COMMENTS}_'></td>
          <td><input type='text' name='IDENT1' class='form-control' placeholder='_{IDENT1}_'></td>
          <td><input type='text' name='IDENT2' class='form-control' placeholder='_{IDENT2}_'></td>
          <td><input type='text' name='IDENT3' class='form-control' placeholder='_{IDENT3}_'></td>
          <td><input type='text' name='IDENT4' class='form-control' placeholder='_{IDENT4}_'></td>

          <td>
            <a type='button' class='remove-row-btn'>
              <span class="fa fa-times text-danger p-1"></span>
            </a>
          </td>
        </tr>
      `);
      }

      jQuery('.serial-number-input').on('input', function (event) {
        var element = event.target;
        var value = jQuery(element).val();
        doDelayedSearch(value, element);
      });
    });

    jQuery('#splitTable_').on('click', '.remove-row-btn', function () {
      jQuery(this).closest('tr').remove();
      renumerate();
    });

    function renumerate() {
      jQuery('#splitTable_ tbody tr').each(function (i) {
        jQuery(this).find('td:first').text(i + 1);
      });
    }

    var timeout = null;

    function doDelayedSearch(val, element) {
      if (timeout) {
        clearTimeout(timeout);
      }
      document.getElementById('DIVIDE_BUTTON').disabled = true;
      timeout = setTimeout(function () {
        doSearch(val, element);
      }, 500);
    }

    function doSearch(val, element) {
      if (!val) {
        jQuery(element).parent().removeClass('has-success').removeClass('has-error');
        jQuery(element).css('border', '');
        element.setCustomValidity('');
        document.getElementById('DIVIDE_BUTTON').disabled = false;
        return 1;
      }

      if (checkInputsDuplicates(val)) {
        changeInputStatus(element, false);
        return 1;
      }

      jQuery.post('%SELF_URL%', 'header=2&get_index=storage_main&sn_check=' + val, function (data) {
        changeInputStatus(element, data === 'success');
      });
    }

    function checkInputsDuplicates(val) {
      let coincidences = 0;

      jQuery('.serial-number-input').each(function () {
        if (jQuery(this).val() === val) coincidences++;
      });

      return coincidences > 1;
    }

    function changeInputStatus(element, success = true) {
      document.getElementById('DIVIDE_BUTTON').disabled = false;
      if (success) {
        jQuery(element).parent().removeClass('has-error').addClass('has-success');
        jQuery(element).css('border', '3px solid green');
        element.setCustomValidity('');
        return;
      }
      jQuery(element).parent().removeClass('has-success').addClass('has-error');
      jQuery(element).css('border', '3px solid red');
      element.setCustomValidity('_{SERIAL_NUMBER_IS_ALREADY_IN_USE}_');
    }
  });

</script>