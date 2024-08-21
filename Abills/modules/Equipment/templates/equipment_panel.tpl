<FORM action='$SELF_URL' METHOD='POST' class='form-inline'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='visual' value='$FORM{visual}'>
  <fieldset class='form-inline'>

    <div class='form-group mb-3'>
      <label class='mr-2'> _{NAS}_:</label>
      %DEVICE_SEL%
      <input type=submit name=show value='_{SHOW}_' class='btn btn-primary ml-2'>
    </div>

  </fieldset>
</form>