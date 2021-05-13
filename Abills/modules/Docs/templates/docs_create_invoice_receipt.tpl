
<div class="card card-secondary card-outline collapsed-card" style="border-top-width: 1px; margin-bottom: 0px;">
  <div class="card-header with-border">
    <h3 class="card-title">_{DOCS}_</h3>
	  <div class="card-tools pull-right">
      <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse">
	      <i class="fa fa-plus"></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    <div class="form-group row">
      <label  class="col-sm-2 col-form-label required" for='APPLY_TO_INVOICE'>_{APPLY_TO_INVOICE}_</label>
      <div class="col-sm-10">
        <select name='APPLY_TO_INVOICE' ID='APPLY_TO_INVOICE' class='form-control' style="width: 100%">
          <option value='1'>_{YES}_</option>
          <option value='0'>_{NO}_</option>
        </select>
      </div>
    </div>

    <div class="form-group row">
      <label  class="col-sm-2 col-form-label required" for='INVOICE_ID'>_{INVOICE}_</label>
      <div class="col-sm-10" style="padding-right: 60px;">
        %INVOICE_SEL%
      </div>
    </div>

    <div class='form-group'>
      <div class="form-check">
        <input type='checkbox' class="form-check-input" name='CREATE_RECEIPT' value='1' %CREATE_RECEIPT_CHECKED% id='CREATE_RECEIPT'>
        <label class='form-check-label' for='CREATE_RECEIPT'>_{RECEIPT}_</label>
      </div>
    </div>

    <input type='hidden' name='SEND_EMAIL' value='%SEND_MAIL%'>
  </div>
</div>