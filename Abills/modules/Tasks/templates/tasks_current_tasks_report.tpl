<div class='card card-outline card-primary'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{CURRENT_TASKS}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
    </div>
  </div>
  <div class='card-body table-responsive p-0'>
    <div class='text-center d-flex justify-content-center align-items-center h-100' id='TASKS_CURRENT_REPORT_SPINNER'>
      <i class='fa fa-spinner fa-pulse fa-2x'></i>
    </div>
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    sendRequest(`/api.cgi/tasks?PAGE_ROWS=10&DESC=DESC`, {}, 'GET')
      .then(data => {
        jQuery('#TASKS_CURRENT_REPORT_SPINNER').removeClass('d-flex').addClass('d-none');
        if (!data.list) return;

        let rows = [];
        data.list.forEach(item => {
          let row = [item.id];
          let name = jQuery(`<a title='${item.descr}'>${item.name}</a>`);
          name.attr('href', `?get_index=task_web_add&full=1&chg_task=${item.id}`)
          row.push(name);

          let state = jQuery(`<span class='text-white badge' style='background-color:${getStateColor(item.state)}'>${getStateName(item.state)}</span>`)
          row.push(state);

          row.push(item.controlDate);

          rows.push(row);
        });

        let table = createTable(['#', '_{NAME}_', '_{STATE}_', '_{CONTROL_DATE}_'], rows);
        jQuery('#TASKS_CURRENT_REPORT_SPINNER').parent().append(table);
      });

    function getStateColor(state) {
      switch (state) {
        case 0:
          return '#17a2b8';
        case 1:
          return '#28a745';
        case 2:
          return '#dc3545';
        default:
          return '#17a2b8';
      }
    }

    function getStateName(state) {
      if (!state) return '_{TASK_IN_WORK}_';
      if (state === 1) return '_{TASKS_COMPLETED}_';
      if (state === 2) return '_{TASKS_NOT_COMPLETED}_';

      return '_{UNKNOWN}_';
    }
  });
</script>