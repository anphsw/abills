<script>
  jQuery(document).ready(function () {
    let deliveryStatus = {};
    let params = {};
    try {
      deliveryStatus = JSON.parse('%DELIVERY_STATUS%');
      params = JSON.parse('%PARAMS%');
    }
    catch (e) {
      console.log(e);
    }
    let tableId = params['TABLE_ID'];
    let installTableBody = jQuery(`#${tableId} tbody`);
    let lastId = params['LAST_ID'] ? `>${params['LAST_ID']}` : '!';

    setInterval(function() {
      fetch(`/api.cgi/storage/installation?STA_NAME&SAT_TYPE&ID=${lastId}&LOGIN&UID=!&DELIVERY_ID=!&DELIVERY_STATUS=!4&DELIVERY_DATE=!&SORT=1`, {
        headers: {'Content-Type': 'application/json'},
      })
        .then(response => {
          if (!response.ok) throw response;
          return response;
        })
        .then(response => response.json())
        .then(data => {
          if (!Array.isArray(data)) return;
          let lastIndex = data.length - 1;

          if (data[lastIndex] && data[lastIndex].id) lastId = `>${data[lastIndex].id}`;

          data.forEach(function (install) {
            let tr = jQuery('<tr></tr>');
            let name = jQuery(`<td>${install.staName}</td>`);
            let type = jQuery(`<td>${install.satType}</td>`);
            let userBtn = jQuery('<a></a>').attr('href', `?get_index=storage_hardware&full=1&UID=${install.uid}&delivery=${install.id}`)
              .text(install.login).attr('target', '_blank');
            let login = jQuery(`<td></td>`).append(userBtn);
            let status = jQuery(`<td>${deliveryStatus[install.deliveryStatus] || install.deliveryStatus}</td>`);
            let date = jQuery(`<td>${install.deliveryDate}</td>`);

            tr.append(name).append(type).append(login).append(status).append(date);

            installTableBody.prepend(tr);
          });
        });
    }, 30000);
  });
</script>