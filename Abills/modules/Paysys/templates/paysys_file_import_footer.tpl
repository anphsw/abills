<div class='container'>
  <div class='form-group form-inline'>
    <div class='form-group mr-3 row'>
      <input type='checkbox' class='form-check-input' id='%TYPE%'
             name='%TYPE%' value='1' data-input-disables='CANCEL_PAYMENTS' checked>
      <label class='form-check-label' for='%TYPE%'>_{IMPORT}_ %TYPE_LABEL%</label>
    </div>

    <div class='form-group mr-3 row'>
      <input type='checkbox' class='form-check-input' id='CANCEL_PAYMENTS'
             name='CANCEL_PAYMENTS' value='1' data-input-disables='%TYPE%'>
      <label class='form-check-label' for='CANCEL_PAYMENTS'>_{CANCEL_PAYMENTS}_</label>
    </div>

    <div class='form-group mr-3 row'>
      <input type='checkbox' class='form-check-input' id='SKIP_CROSSMODULES_CALLS'
             name='SKIP_CROSSMODULES_CALLS' value='1'>
      <label class='form-check-label' for='SKIP_CROSSMODULES_CALLS'>_{NO}_ _{MODULES}_ (crossmodules call)</label>
    </div>
  </div>
</div>
