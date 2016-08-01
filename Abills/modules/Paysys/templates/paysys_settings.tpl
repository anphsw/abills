<style> 
#paysys-chooser img{
  cursor:pointer;
}
</style>

<div class='panel panel-primary'>
    <div class='panel-heading text-center'><h4>_{CHOOSE}_</h4></div>
  <div class='panel-body'>
    
        <form name='PAYSYS_SETTINGS' id='form_PAYSYS_SETTINGS' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='%index%' />

      <div class='form-group'>
        %PAY_SYSTEM_SEL%
      </div>
    </form>

  </div>
  <div class='panel-footer text-center'>
      <input type='submit' form='form_PAYSYS_SETTINGS' class='btn btn-primary' name='action' value='_{SELECT}_'>
  </div>
</div>

            