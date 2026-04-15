<script src='/styles/default/js/jszip.min.js' defer></script>

<div class='card card-primary card-outline m-3'>
  <div class='card-header'>
    <h4 class='card-title'>
      <i class='fas fa-file-import mr-2'></i>_{MAPS_IMPORTING_DATA}_
    </h4>
  </div>

  <div class='card-body'>
    <div class='card bg-light mb-3'>
      <div class='card-body'>
        <div class='row align-items-center'>

          <div class='form-group col-md-6 mb-md-0'>
            <label for='loadFile' class='font-weight-bold'>
              <i class='fas fa-folder-open'></i> _{MAPS_CHOOSE_FILE}_
            </label>
            <input class='form-control p-1' id='loadFile' type='file'
                   accept='.kmz,.kml'>
            <small class='form-text text-muted'>
              _{MAPS_SUPPORTED_FORMATS}_: <strong>KMZ, KML</strong>
            </small>
          </div>

          <div class='form-group col-md-3 mb-md-0'>
            <label for='batchSize' class='font-weight-bold'>
              <i class='fas fa-layer-group'></i>_{MAPS_BATCH_SIZE}_
            </label>
            <input class='form-control' id='batchSize' type='number'
                   value='50' min='10' max='500' step='10'>
            <small class='form-text text-muted'>_{MAPS_ITEMS_PER_REQUEST}_</small>
          </div>

          <div class='col-md-3 mt-3 mt-md-0'>
            <button type='button' class='btn btn-info btn-block shadow-sm mt-1' id='load'>
              <i class='fas fa-cloud-upload-alt'></i> _{UPLOAD}_
            </button>
          </div>

        </div>
      </div>
    </div>

    <div class='row mt-4'>
      <div class='col-lg-12'>
        <div id='mapping-container'></div>
      </div>
    </div>
  </div>

  <div class='card-footer bg-white border-top' id='footer-actions' style='display:none;'>
    <div class='d-flex justify-content-between'>
      <button type='button' class='btn btn-default' id='btn-preview'>
        <i class='fas fa-eye'></i> _{PREVIEW}_
      </button>
      <button type='button' class='btn btn-success' id='btn-save'>
        <i class='fas fa-save'></i> _{MAPS_IMPORTING_DATA}_
      </button>
    </div>
  </div>
</div>

<script>
  var _MAPS_CABLE = '_{CABLE}_';
  var _MAPS_WELL = '_{WELL}_';
  var _MAPS_NAME = '_{NAME}_';
  var _MAPS_LENGTH = '_{LENGTH}_';
  var _MAPS_TYPE = '_{TYPE}_';
  var _MAPS_COORDINATES = '_{MAPS_COORDINATES}_';
  var _MAPS_STATISTICS = '_{MAPS_STATISTICS}_';
  var _MAPS_TOTAL = '_{TOTAL}_';
  var _MAPS_CABLES = '_{MAPS_CABLES}_';
  var _MAPS_WELLS = '_{WELLS}_';
  var _MAPS_RESULT = '_{RESULT}_';
  var _MAPS_TOTAL_PROCESSED = '_{MAPS_TOTAL_PROCESSED}_';
  var _MAPS_SUCCESSFULLY = '_{MAPS_SUCCESSFULLY}_';
  var _MAPS_ERROR = '_{ERROR}_';
  var _MAPS_ERRORS = '_{ERRORS}_';
  var _MAPS_CONFIRMATION = '_{MAPS_CONFIRMATION}_';
  var _MAPS_CANCEL = '_{CANCEL}_';
  var _MAPS_CONFIRM = '_{MAPS_CONFIRM}_';
  var _MAPS_MESSAGE = '_{MESSAGE}_';
  var _MAPS_LAYERS_NOT_FOUND = '_{MAPS_LAYERS_NOT_FOUND}_';
  var _MAPS_IMPORT_AS = '_{MAPS_IMPORT_AS}_';
  var _MAPS_DO_NOT_IMPORT = '_{MAPS_DO_NOT_IMPORT}_';
  var _MAPS_SYSTEM_FIELD = '_{MAPS_SYSTEM_FIELD}_';
  var _MAPS_FILE_FIELD = '_{MAPS_FILE_FIELD}_';
  var _MAPS_AUTOMATICALLY = '_{MAPS_AUTOMATICALLY}_';
  var _MAPS_SKIP = '_{MAPS_SKIP}_';
  var _MAPS_EXAMPLE_SHORT = '_{MAPS_EXAMPLE_SHORT}_';
  var _MAPS_IMPORTING_DATA = '_{MAPS_IMPORTING_DATA}_';
  var _MAPS_STOP = '_{MAPS_STOP}_';
  var _MAPS_PROCESSED = '_{MAPS_PROCESSED}_';
  var _MAPS_BATCH = '_{MAPS_BATCH}_';
  var _MAPS_FROM = '_{OF}_';
  var _MAPS_KML_NOT_FOUND_ARCHIVE = '_{MAPS_KML_NOT_FOUND_ARCHIVE}_';
  var _MAPS_XML_STRUCTURE_ERROR = '_{MAPS_XML_STRUCTURE_ERROR}_';
  var _MAPS_CHOOSE_FILE = '_{MAPS_CHOOSE_FILE}_';
  var _MAPS_FORMAT_NOT_SUPPORTED = '_{MAPS_FORMAT_NOT_SUPPORTED}_';
  var _MAPS_LOADED = '_{MAPS_LOADED}_';
  var _MAPS_LAYER = '_{MAPS_LAYER}_';
  var _MAPS_LAYERS = '_{LAYERS}_';
  var _MAPS_ELEMENT = '_{MAPS_ELEMENT}_';
  var _MAPS_ELEMENTS = '_{MAPS_ELEMENTS}_';
  var _MAPS_UPLOAD = '_{UPLOAD}_';
  var _MAPS_CONFIGURE_IMPORT = '_{MAPS_CONFIGURE_IMPORT}_';
  var _MAPS_PREVIEW = '_{PREVIEW}_';
  var _MAPS_DATA_EXAMPLE_FIRST_3 = '_{MAPS_DATA_EXAMPLE_FIRST_3}_';
  var _MAPS_NOTHING_TO_IMPORT = '_{MAPS_NOTHING_TO_IMPORT}_';
  var _MAPS_IMPORT_CONFIRMATION = '_{MAPS_IMPORT_CONFIRMATION}_';
  var _MAPS_START_IMPORT_QUESTION = '_{MAPS_START_IMPORT_QUESTION}_';
  var _MAPS_START_IMPORT = '_{MAPS_START_IMPORT}_';
  var _MAPS_PROCESS_STOP = '_{MAPS_PROCESS_STOP}_';
  var _MAPS_STOP_CONFIRM_QUESTION = '_{MAPS_STOP_CONFIRM_QUESTION}_';
  var _MAPS_YES_STOP = '_{MAPS_YES_STOP}_';
  var _MAPS_CONTINUE = '_{CONTINUE}_';
  var _MAPS_IMPORT_STOPPED = '_{MAPS_IMPORT_STOPPED}_';
  var _MAPS_IMPORT_RESULT = '_{MAPS_IMPORT_RESULT}_';
  var _MAPS_CRITICAL_ERROR = '_{MAPS_CRITICAL_ERROR}_';
  var _MAPS_FIELDS_GENITIVE = '_{MAPS_FIELDS_GENITIVE}_';
</script>

<script src='/styles/default/js/maps/import.js' defer></script>