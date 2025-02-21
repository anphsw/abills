<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='ID' id='ID' value='%ID%'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TRACKING_DATE_TO'>_{DOCS_SEND_INVOICE}_ _{TO}_ _{OF_CLIENT}_</label>
        <div class='col-md-6'>
          <input type='date' id='TRACKING_DATE_TO' class='form-control' name='TRACKING_DATE_TO' value=%TRACKING_DATE_TO%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TRACKING_NUMBER_TO'>_{DOCS_TRACKING_NUMBER}_ _{TO}_ _{OF_CLIENT}_</label>
        <div class='col-md-6'>
          <input type='text' id='TRACKING_NUMBER_TO' class='form-control' name='TRACKING_NUMBER_TO' value=%TRACKING_NUMBER_TO%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RECEIVE_DATE'>_{DOCS_RECEIVE_INVOICE}_ _{BY_CLIENT}_</label>
        <div class='col-md-6'>
          <input type='date' id='RECEIVE_DATE' class='form-control' name='RECEIVE_DATE' value=%RECEIVE_DATE%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TRACKING_DATE_FROM'>_{DOCS_TRACKING_DATE}_ _{FROM}_ _{OF_CLIENT}_</label>
        <div class='col-md-6'>
          <input type='date' id='TRACKING_DATE_FROM' class='form-control' name='TRACKING_DATE_FROM' value=%TRACKING_DATE_FROM%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TRACKING_NUMBER_FROM'>_{DOCS_TRACKING_NUMBER}_ _{FROM}_ _{OF_CLIENT}_</label>
        <div class='col-md-6'>
          <input type='text' id='TRACKING_NUMBER_FROM' class='form-control' name='TRACKING_NUMBER_FROM' value=%TRACKING_NUMBER_FROM%>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <button type='submit' class='btn btn-primary float-right' id="submit_btn">_{SAVE}_</button>
    </div>
  </div>
</form>

<script>
  jQuery('#submit_btn').on('click', function (event) {
    var invoice_id = jQuery('#ID').val();
    var tracking_date_to = jQuery('#TRACKING_DATE_TO').val();
    var tracking_number_to = jQuery('#TRACKING_NUMBER_TO').val();
    var receive_date = jQuery('#RECEIVE_DATE').val();
    var tracking_number_from = jQuery('#TRACKING_NUMBER_FROM').val();
    var tracking_date_from = jQuery('#TRACKING_DATE_FROM').val();

    sendRequest(`/api.cgi/docs/invoices/${invoice_id}`, {
      tracking_date_to: tracking_date_to,
      tracking_number_to: tracking_number_to,
      receive_date: receive_date,
      tracking_number_from: tracking_number_from,
      tracking_date_from: tracking_date_from
    }, 'PUT');
  });
</script>