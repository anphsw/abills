<link rel='stylesheet' type='text/css' href='/styles/default/css/fullcalendar.min.css'>
<link rel='stylesheet' type='text/css' href='/styles/default/css/modules/msgs/msgs.calendar.css'>

<script src='/styles/default/js/fullcalendar/fullcalendar.min.js'></script>
<script src='/styles/default/js/fullcalendar/locales/uk.js'></script>
<script src='/styles/default/js/fullcalendar/locales/ru.js'></script>
<script src='/styles/default/js/msgs/msgs.calendar.js'></script>

<div class='container-fluid mt-3'>
  <div class='row'>
    <div class='col-md-3'>
      <div class='sticky-top mb-3'>
        <div class='card'>
          <div class='card-header'>
            <h4 class='card-title'>_{MSGS_UNPLANNED_MESSAGES}_</h4>
          </div>
          <div class='card-body p-0'>
            <div id='admin-filter-container' class='p-3 pb-2'>
              <label for='admin-filter' class='form-label'>_{MSGS_FILTER_BY_ADMIN}_:</label>
              <select id='admin-filter' class='form-select'>
                <option value=''>_{MSGS_ALL_ADMINS}_</option>
              </select>
            </div>
            <div id='external-events-container'>
              <div id='tasks-counter' class='p-3 border-top bg-light text-center'>
                <small class='text-muted'>
                  <i class='fas fa-tasks me-1'></i>
                  _{MSGS_LOADED_MESSAGES}_: <span id='loaded-count'>0</span> _{FROM}_ <span id='total-count'>0</span>
                </small>
              </div>
              <div id='external-events'></div>
              <div id='no-tasks-message' class='text-center p-4' style='display: none;'>
                <div class='text-muted'>
                  <i class='fas fa-inbox fa-2x mb-2'></i>
                  <p class='mb-0'>_{MSGS_NO_UNPLANNED_MESSAGES}_</p>
                </div>
              </div>
              <div id='load-more-container' class='text-center p-3' style='display: none;'>
                <button id='load-more-btn' class='btn btn-primary btn-sm'>
                  <i class='fas fa-plus me-1'></i>_{MSGS_LOAD_MORE}_
                </button>
                <div id='loading-indicator' class='mt-2' style='display: none;'>
                  <i class='fas fa-spinner fa-spin'></i> _{LOADING}_...
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-9'>
      <div class='card'>
        <div class='card-body'>
          <div id='calendar'></div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
  var _NO_RESPONSIBLE = '_{NO_RESPONSIBLE}_' || 'No responsible';
  var _NO_SUBJECT = '_{NO_SUBJECT}_' || 'No subject';
  var _MSGS_ALL_ADMINS = '_{MSGS_ALL_ADMINS}_' || 'All administrators';
  const locale = '%LOCALE%' || 'en';
  document.addEventListener('DOMContentLoaded', function () {
    let statuses = {};
    try {
      statuses = JSON.parse('%STATUSES%');
    } catch (e) {
      statuses = {
        1: {color: '#dc3545', icon: 'fa fa-times-circle'},
        6: {color: '#ffc107', icon: 'fa fa-hourglass-half'},
        2: {color: '#28a745', icon: 'fa fa-check-circle'}
      };
      console.log('Using default statuses:', e);
    }

    const calendarManager = new CalendarManager({statuses: statuses, locale: locale});
    window.calendarManager = calendarManager;
  });
</script>