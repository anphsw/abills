<div class='%FORM_CLASS%'>
  <form class='form-inline'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='DATE' value='%DATE%'>

    <div class='form-group mb-2'>
      %ADMIN_SEL%
    </div>
    <div class='form-group mx-sm-3 mb-2'>
      %STATUS_SEL%
    </div>
    <button type='submit' class='btn btn-primary mb-2'>_{APPLY}_</button>
  </form>
  <hr class='m-1'>
</div>

<script>
  document.addEventListener('save-plan-time', (e) => {
    let id = e.detail.id;
    let aid = e.detail.aid;
    let plan_time = e.detail.planTime;
    if (!id || !plan_time) return;

    sendRequest(`/api.cgi/msgs/${id}`, {plan_time: plan_time, resposible: aid}, 'PUT');
  });

  document.addEventListener('save-plan-interval', (e) => {
    let id = e.detail.id;
    let plan_interval = e.detail.planInterval;
    if (!id || !plan_interval) return;

    sendRequest(`/api.cgi/msgs/${id}`, {plan_interval: plan_interval}, 'PUT');
  });

  document.addEventListener('save-plan-date', (e) => {
    let id = e.detail.id;
    let plan_date = e.detail.planDate;
    if (!id || !plan_date) return;

    sendRequest(`/api.cgi/msgs/${id}`, {plan_date: plan_date}, 'PUT');
  });

  jQuery('ul.time-sidebar').sortable({
    items: 'li.time-row.admin-row',
    cursor: 'move',
    start: function(event, ui) {
      ui.item.data('start-index', ui.item.index());

      let startIndex = ui.item.index();
      let correspondingRow = jQuery('.time-row-container').eq(startIndex);
      correspondingRow.addClass('selected');
    },
    sort: function(event, ui) {
      let currentIndex = ui.placeholder.index();
      jQuery('.time-row-container.selected').insertAfter(jQuery('.time-row-container').eq(currentIndex - 1));
    },
    stop: function(event, ui) {
      jQuery('.time-row-container').removeClass('selected');
    },
    update: function () {
      const adminValues = jQuery('.draggable-row[data-admin]').map(function() {
        return jQuery(this).attr('data-admin');
      }).get();

      fetch('/api.cgi/admins/settings', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ SETTING: adminValues.join(','), OBJECT: 'MSGS_SCHEDULE_TASKS_BOARD' })
      })
    }
  });

</script>