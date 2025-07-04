<div class='row'>
  %LEAD_PROFILE_PANEL%
  <div class='col-md-9'>
    %PROGRESSBAR%
  </div>
</div>

<script>
  Events.on('AJAX_SUBMIT.form_CRM_LEAD_SEARCH', function () {
    location.reload(false)
  })
</script>