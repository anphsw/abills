
<div class='panel panel-default panel-form'>
  <div class='panel-heading'>
      <a data-toggle='collapse' data-parent='#accordion' href='#docs_'>_{DOCS}_</a>
  </div>
<div id='docs_' class='panel-collapse collapse out'>

<div class='panel-body'>

<div class='form-group'>
  <label class='control-label col-md-4' for='APPLY_TO_INVOICE'>_{APPLY_TO_INVOICE}_</label>
  <div class='col-md-8'>
    <select name='APPLY_TO_INVOICE' ID='APPLY_TO_INVOICE' class='form-control'>
<option value=1>_{YES}_</option>
<option value=0>_{NO}_</option>
</select>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-4' for='INVOICE_ID'>_{INVOICE}_</label>
  <div class='col-md-8'>
    %INVOICE_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-4' for='CREATE_RECEIPT'>_{RECEIPT}_</label>
  <div class='col-md-3'>
    <input type=checkbox name=CREATE_RECEIPT   value='1' checked id='CREATE_RECEIPT'>
  </div>
</div>
<input type=hidden name=SEND_EMAIL value='0'>

</div>
</div>
</div>