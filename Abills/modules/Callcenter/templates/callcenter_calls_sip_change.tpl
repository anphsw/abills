<form action=%SELF_URL% METHOD=POST>
  <input type='hidden' name='AID' id="AID" value=%AID%>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border text-primary'>_{CHANGE}_ SIP</div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='SIP_NUMBER' > SIP </label>
        <div class='col-md-9'>
          <input class='form-control' type='text' id='SIP_NUMBER'  name='SIP_NUMBER' value='%SIP_NUMBER%' required>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <button type='submit' class='btn btn-primary' id="submit_btn">_{CHANGE}_</button>
    </div>
  </div>
</form>

<script>
  jQuery('#submit_btn').on('click', function (event) {
    var sip_number = jQuery('#SIP_NUMBER').val();
    var aid = jQuery('#AID').val();
    sendRequest(`/api.cgi/admins/${aid}`, {sip_number: sip_number}, 'PUT');
  });
</script>