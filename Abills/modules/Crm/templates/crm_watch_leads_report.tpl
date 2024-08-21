<div class='card card-outline card-form card-primary'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{TRACKED_LEADS}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
    </div>
  </div>
  <div class='card-body table-responsive p-0'>
    <div class='text-center d-flex justify-content-center align-items-center h-100' id='CRM_WATCH_LEADS_SPINNER'>
      <i class='fa fa-spinner fa-pulse fa-2x'></i>
    </div>
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    sendRequest(`/api.cgi/crm/leads?WATCHER=1&FIO&CURRENT_STEP_NAME&STEP_COLOR&ADMIN_NAME&SORT=id`, {}, 'GET')
      .then(data => {
        jQuery('#CRM_WATCH_LEADS_SPINNER').removeClass('d-flex').addClass('d-none');

        let rows = [];
        data.forEach(item => {
          let row = [item.id];
          let fio = jQuery(`<a title='${item.fio}'>${item.fio}</a>`);
          fio.attr('href', `?get_index=crm_lead_info&full=1&LEAD_ID=${item.id}`)
          row.push(fio);

          let step = jQuery(`<span class='text-white badge' style='background-color:${item.stepColor}'>${item.currentStepName}</span>`)
          row.push(step);

          row.push(item.adminName);

          rows.push(row);
        });

        let table = createTable(['#', '_{FIO}_', '_{STEP}_', '_{RESPOSIBLE}_'], rows);
        jQuery('#CRM_WATCH_LEADS_SPINNER').parent().append(table);
      });
  });

  function createTable(title = [], rows = []) {
    let table = jQuery('<table></table>').addClass('table table-striped table-hover table-condensed');
    let thead = jQuery('<thead></thead>');

    let tr = jQuery('<tr></tr>');
    title.forEach(thValue => {
      let th = jQuery('<th></th>');
      let span = jQuery('<span></span>').text(thValue);

      th.append(span);
      tr.append(th);
    });
    thead.append(tr);
    table.append(thead);

    let tbody = jQuery('<tbody></tbody>');
    rows.forEach(row => {
      let tr = jQuery('<tr></tr>');

      row.forEach(column => {
        let td = jQuery('<td></td>').append(column);
        tr.append(td);
      })
      tbody.append(tr);
    });

    table.append(tbody);
    return table;
  }
</script>