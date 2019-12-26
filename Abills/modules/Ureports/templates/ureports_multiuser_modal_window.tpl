<div form='users_list'>
  <div class='form-group'>
    <label class='control-label col-md-4 col-sm-3' for='TYPE'>_{TARIF_PLAN}_</label>
    <div class='col-md-8 col-sm-9'>
      %UREPORTS_TP%
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-4 col-sm-3' for='TYPE'>_{TYPE}_</label>
    <div class='col-md-8 col-sm-9'>
      %UREPORTS_TYPE%
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-4 col-sm-3' for='TYPE'>_{STATUS}_</label>
    <div class='col-md-8 col-sm-9'>
      %UREPORTS_STATUS%
    </div>
  </div>

  <div class='form-group'>
    <div form='users_list' id="reportsTable"></div>
  </div>

</div>
<input name="MULTIUSER" value="_{APPLY}_" class="btn btn-primary" form="users_list" id="MULTIUSER" type="submit">


<script>
  jQuery(function () {
    jQuery("select#UREPORTS_TP").on('change', function () {
      jQuery.post('/admin/index.cgi', 'header=2&get_index=ureports_user&UR_MODAL_AJAX=1&TP_ID=' + jQuery(this).val(), function (result) {
        jQuery("div#reportsTable").html(result);
        // console.log(result);
      });

    })
  })

</script>
