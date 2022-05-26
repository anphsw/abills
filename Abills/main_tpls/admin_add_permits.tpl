<form name='add_permits' id='form_add_permits' method='post'>
  <input type='hidden' name='index' value='50'/>
  <input type='hidden' name='AID' value='%AID%'/>
  <input type='hidden' name='subf' value='%subf%'/>

  <div class='container-fluid text-center pt-2 pb-3'>
    %BUTTONS%
    <input type='text' name='TYPE'>
    <input type='submit' form='form_add_permits' class='btn btn-success btn-sm' name='add_permits'
           value='_{SAVE}_ _{TEMPLATE}_'>
  </div>
  %TABLE1%
  %TABLE2%

  <input type='submit' form='form_add_permits' class='btn btn-primary' name='set' value='_{SAVE}_'>
</form>
