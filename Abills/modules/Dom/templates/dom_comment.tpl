<form action=%SELF_URL% method=post>
  <input type='hidden' name=index id=INDEX value=%index%>
  <input type='hidden' name=LOCATION_ID id=LOCATION_ID value=%LOCATION_ID%>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border text-primary'>_{CHANGE}_ </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='COMMENTS' > _{COMMENTS}_ </label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
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
    var location_id = jQuery('#LOCATION_ID').val();
    var comments = jQuery('#COMMENTS').val();
    if(location_id){
      sendRequest(`/api.cgi/builds/${location_id}`, {comments: comments}, 'PUT');
    }
  });
</script>