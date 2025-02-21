<div class='modal fade' id='password-expired-modal' tabindex='-1' data-backdrop='static' data-keyboard='false'>
  <div class='modal-dialog'>
    <div class='modal-content'>
      <div class='modal-header bg-warning text-dark'>
        <h5 class='modal-title'>_{PASSWORD_CHANGE_MANDATORY}_</h5>
      </div>
      <div class='modal-body'>
        <p>%PASSWORD_EXPIRY_NOTICE%</p>
      </div>
      <div class='modal-footer'>
        <a href='?get_index=form_admins&subf=54&AID=%AID%&full=1' class='btn btn-warning'>_{CHANGE_PASSWORD}_</a>
      </div>
    </div>
  </div>
</div>

<script>
  jQuery('#password-expired-modal').modal('show');
</script>