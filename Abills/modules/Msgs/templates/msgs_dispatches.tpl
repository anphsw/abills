<FORM action='%SELF_URL%' METHOD='POST' enctype='multipart/form-data'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='UID' value='%UID%'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='FROM_DATE' value='%FROM_DATE%'/>
  <input type='hidden' name='TO_DATE' value='%TO_DATE%'/>
  <input type='hidden' name='AID' value='%AID%'/>
  <input type='hidden' name='STATE_FILTER' value='%STATE_FILTER%'/>

  %DISPATCHES%
</FORM>

<script>
  function modal_view(id, index_chg) {
    var str_request = '';
    if (id) {
      str_request = '&chg=' + id + '&not_msgs=1';
    } else {
      str_request = '&add_form=1&not_msgs=1';
    }
    jQuery.post('%SELF_URL%', 'qindex=' + index_chg + '&header=2' + str_request, function (data) {

      var add_contact_form = new AModal();
      add_contact_form
        .setId('add1_contact_modal')
        .isForm(true)
        // .setHeader('_{DISPATCH}_ #' + id)
        .setBody(data)
        .setSize('lg')
        .show(function (modal) {

        });

      initSelect2();
    });
  }
</script>