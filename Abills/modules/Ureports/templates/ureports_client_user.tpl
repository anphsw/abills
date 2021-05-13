<script src='/styles/default_adm/js/modules/ureports/sender_contact_choose.js'></script>
<script>
  var LANG = {
    NO_CONTACTS_FOR_TYPE : '_{NO_CONTACTS_FOR_TYPE}_'
  };

  var contacts_list;
  try {
    contacts_list = JSON.parse('%UID_CONTACTS%');
  }
  catch (Error) {
    console.log(Error);
    alert("Error while parsing contacts. Please contact support system");
  }

</script>

%MENU%

<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>

    <div class='card card-secondary'>
      <div class='card-header with-border'>
        <h3 class="card-title">
          _{NOTIFICATIONS}_
        </h3>
      </div>
      <div class='card-body'>
        <div class="form-group row">
          <label class="col-sm-4 col-md-4" for='TP_ID'>_{TARIF_PLAN}_</label>
          <div class="col-sm-8 col-md-8">
            %TP_ID%
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-4 col-md-4" for='TYPE'>_{TYPE}_</label>
          <div class="col-sm-8 col-md-8">
            %TYPE_SEL%
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-4 col-md-4" for='STATUS'>_{STATUS}_</label>
          <div class="col-sm-8 col-md-8">
            %STATUS_SEL%
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-4 col-md-4" for='DESTINATION'>_{DESTINATION}_</label>
          <div class="col-sm-8 col-md-8" id="DESTINATION_SELECT_WRAPPER">
            %DESTINATION_VIEW%
          </div>
        </div>
        <div class="form-group row">
          <label class="col-sm-4 col-md-4">_{REGISTRATION}_</label>
          <div class="col-sm-8 col-md-8">
            %REGISTRATION%
          </div>
        </div>
      </div>

      <div class='card-footer'>
        <input type=submit class='btn btn-primary' id='SUBMIT_UREPORTS_USER' name='%ACTION%' value='%LNG_ACTION%'>
        %HISTORY_BTN%
      </div>

    </div>

    <div>%REPORTS_LIST%</div>
</form>
<script>

  var current_destination = '%DESTINATION%';

  var type_select = jQuery('select#TYPE');
  var result_wrapper = jQuery('div#DESTINATION_SELECT_WRAPPER');

  var chooser = new ContactChooser(true, contacts_list, type_select, result_wrapper);
  chooser.setValue(current_destination);


  let contactView = document.querySelector('#DESTINATION_SELECT_WRAPPER .select2-selection__rendered');

    contactView.textContent = current_destination

</script>

