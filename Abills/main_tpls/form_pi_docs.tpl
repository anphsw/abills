<div class='card card-outline border-top mb-0' id='docs-card'>
  <div class='card-header with-border py-2'>
    <h3 class='card-title text-md'>
      _{DOCS}_
    </h3>
    <div class='card-tools float-right'>
      <button type='button' id='btn-add-doc' class='btn btn-tool btn-outline-success' title='_{ADD_DOCUMENT}_'>
        <i class='fa fa-plus'></i>
      </button>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>

  <div class='card-body p-0'>
    <div id='docs-content' class='p-3 position-relative'>

      <div id='docs-loader' class='position-absolute w-100 h-100' style='top:0; left:0; background:rgba(255,255,255,0.8); z-index:10; display:none; align-items:center; justify-content:center;'>
        <i class='fa fa-spinner fa-spin fa-2x text-primary'></i>
      </div>

      <div id='docs-panel-empty' class='text-center text-muted py-4'>
        <i class='fa fa-id-card-o fa-3x mb-2 d-block'></i>
        <p class='mb-1'>_{NO_DOCUMENTS}_</p>
      </div>

      <div id='docs-panel-form' style='display:none'>
        <div id='doc-alert' class='alert py-1 px-2 mb-3 small' style='display:none'></div>

        <input type='hidden' id='doc-id' value=''>

        <div class='form-group row mb-2' id='field-type'>
          <label class='col-sm-4 col-form-label col-form-label-sm text-md-right' for='doc-type-select'>
            _{TYPE}_: <span class='text-danger'>*</span>
          </label>
          <div class='col-sm-8'>
            <select class='form-control' id='doc-type-select' required></select>
          </div>
        </div>

        <div class='form-group row mb-2' id='field-num'>
          <label class='col-sm-4 col-form-label col-form-label-sm text-md-right' for='doc-num'>
            _{NUM}_: <span class='text-danger'>*</span>
          </label>
          <div class='col-sm-8'>
            <input type='text' class='form-control' id='doc-num' name='doc_num' maxlength='32' autocomplete='off' placeholder='_{NUM_PLACEHOLDER}_' required>
          </div>
        </div>

        <div class='form-group row mb-2' id='field-date'>
          <label class='col-sm-4 col-form-label col-form-label-sm text-md-right' for='doc-date'>_{DATE}_:</label>
          <div class='col-sm-8'>
            <input type='text' class='form-control datepicker' id='doc-date' name='doc_date' autocomplete='off'>
          </div>
        </div>

        <div class='form-group row mb-2' id='field-expire' style='display:none'>
          <label class='col-sm-4 col-form-label col-form-label-sm text-md-right' for='doc-expire'>_{EXPIRY}_:</label>
          <div class='col-sm-8'>
            <input type='text' class='form-control datepicker' id='doc-expire' name='doc_expire' autocomplete='off'>
            <small id='expire-warn' class='form-text mt-1' style='display:none'></small>
          </div>
        </div>

        <div class='form-group row mb-2' id='field-issued-by'>
          <label class='col-sm-4 col-form-label col-form-label-sm text-md-right' for='doc-issued-by'>_{GRANT}_:</label>
          <div class='col-sm-8'>
            <textarea class='form-control' id='doc-issued-by' name='doc_issued_by' rows='2' placeholder='_{ISSUED_BY_PLACEHOLDER}_'></textarea>
          </div>
        </div>

        <div class='form-group row mt-3 mb-0'>
          <div class='col-sm-8 offset-sm-4'>
            <button type='submit' id='btn-doc-save' class='btn btn-sm btn-primary mr-1'>
              _{ADD}_
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class='table table-striped table-hover table-condensed with-function-fields' id='docs-table-container'>
      <table class='table table-sm table-hover mb-0'>
        <thead>
        <tr>
          <th class='border-top-0 pl-3'>_{TYPE}_</th>
          <th class='border-top-0'>_{NUM}_</th>
          <th class='border-top-0 text-center'>_{DATE}_</th>
          <th class='border-top-0 text-center pr-3'></th> </tr>
        </thead>
        <tbody id='docs-table-body'></tbody>
      </table>
    </div>
  </div>
</div>

<script src='/styles/default/js/abills/document-manager.js' defer></script>
<script>
  var _PASSPORT = '_{PASPORT}_' || 'Passport';
  var _ID_CARD = '_{ID_CARD}_' || 'ID Card';
  var _DRIVER_LICENSE = '_{DRIVER_LICENSE}_' || 'Driver License';

  var _SAVING = '_{SAVING}_' || 'Saving';
  var _CHANGED = '_{CHANGED}_' || 'Changed';
  var _CHANGE = '_{CHANGE}_' || 'Change';
  var _ADD = '_{ADD}_' || 'Add';

  var _NO_DOCUMENTS = '_{NO_DOCUMENTS}_' || 'No documents';

  var _DOCUMENT_EXPIRED = '_{DOCUMENT_EXPIRED}_' || 'Document expired';
  var _EXPIRES_IN = '_{EXPIRES_IN}_' || 'Expires in';
  var _DAYS = '_{DAYS}_' || 'days';

  var _ERROR_LOADING_LIST = '_{ERROR_LOADING_LIST}_' || 'Error loading list';
  var _CONNECTION_ERROR = '_{CONNECTION_ERROR}_' || 'Connection error';
  var _ERROR_LOADING_DOCUMENT = '_{ERROR_LOADING_DOCUMENT}_' || 'Error loading document';
  var _ERROR = '_{ERROR}_' || 'Error';
  var _DELETING_DOCUMENT = '_{DELETING_DOCUMENT}_' || 'Deleting document';
  var _CONFIRM_DELETE_DOCUMENT = '_{CONFIRM_DELETE_DOCUMENT}_' || 'Are you sure you want to delete this document?';
  var _NO = '_{NO}_' || 'No';
  var _YES = '_{YES}_' || 'Yes';
  var _DOCUMENT_DELETED = '_{DOCUMENT_DELETED}_' || 'Document deleted';
  var _EDIT = '_{EDIT}_' || 'Edit';
  var _DELETE = '_{DELETE}_' || 'Delete';

  jQuery(document).ready(function () {
    let myDocsManager = new DocumentManager({
      containerSelector: '#docs-card',
      uid: '%UID%'
    });
  });
</script>