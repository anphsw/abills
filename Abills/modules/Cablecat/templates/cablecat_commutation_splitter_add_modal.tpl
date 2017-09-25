<div class='box box-theme box-form'>
  <div class='box-header with-border'><h4 class='box-title'>_{SPLITTERS}_ : %WELL%</h4></div>
  <div class='box-body'>
    <form name='CABLECAT_COMMUTATION_ADD_MODAL' id='form_CABLECAT_COMMUTATION_ADD_MODAL' method='post'
          class='form form-horizontal ajax-submit-form'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='operation' value='ADD'/>
      <input type='hidden' name='entity' value='SPLITTER'/>
      <input type='hidden' name='ID' value='%COMMUTATION_ID%'/>
      <input type='hidden' name='COMMUTATION_ID' value='%COMMUTATION_ID%'/>
      <input type='hidden' name='CONNECTER_ID' value='%CONNECTER_ID%'/>

      <div class="form-group">
        <label for="SPLITTER_ID" class="control-label col-md-3">_{SPLITTER}_</label>
        <div class="col-md-9" id='SPLITTER_ID'>
          %SPLITTERS_SELECT%
        </div>
      </div>

    </form>

    <div id="splitter_form_wrapper"></div>

  </div>
  <div class='box-footer text-center'>
    <input type='submit' form='form_CABLECAT_COMMUTATION_ADD_MODAL' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

<script>
  jQuery(function () {
    Events.off('AJAX_SUBMIT.form_CABLECAT_COMMUTATION_ADD_MODAL');
    Events.on('AJAX_SUBMIT.form_CABLECAT_COMMUTATION_ADD_MODAL', function(){
      location.reload();
    });

    var select                = jQuery('div#SPLITTER_ID').find('select');
    var splitter_form_wrapper = jQuery('#splitter_form_wrapper');

    var option_add = jQuery('<option></option>', {'value': 'add'}).text('_{CREATE}_');

    select.append(option_add);
    updateChosen();

    select.on('change', function () {
      if (jQuery(this).val() === 'add') {

        splitter_form_wrapper.load('?get_index=cablecat_splitters&header=2&add_form=1' +
            '&WELL_ID=%WELL_ID%&COMMUTATION_ID=%COMMUTATION_ID%' + '&TEMPLATE_ONLY=1', null, function () {
          // Element was replaced, so need update reference
          splitter_form_wrapper = jQuery('#splitter_form_wrapper');

          // Change button text
          splitter_form_wrapper.find('input[type="submit"]').val('_{CREATE}_');

          // Send form in AJAX
          jQuery('#form_CABLECAT_SPLITTER').submit(ajaxFormSubmit);

          // When form sent, refresh page
          Events.off('AJAX_SUBMIT.form_CABLECAT_SPLITTER');
          Events.on('AJAX_SUBMIT.form_CABLECAT_SPLITTER', function (result) {
            if (result.MESSAGE && result.MESSAGE.type === 'info') {
              var new_splitter_type_select = splitter_form_wrapper.find('#TYPE_ID');

              var type_id   = new_splitter_type_select.val();
              var type_name = new_splitter_type_select.find('option[value="' + type_id + '"]').text();

              select.append(jQuery('<option></option>', {'value': result.MESSAGE.ID}).text(type_name + '_#' + result.MESSAGE.ID));

              renewChosenValue(select, result.MESSAGE.ID);
              splitter_form_wrapper.empty();
            }
          });

        });

      }
      else {
        splitter_form_wrapper.empty();
      }


    })

  });
</script>