<div class='card card-outline card-form card-primary'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{DYNAMICS_OF_MESSAGES_AND_REPLIES}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
    </div>
  </div>
  <div class='card-body p-0'>
    <div class='text-center d-flex justify-content-center align-items-center h-100' id='DYNAMICS_OF_MESSAGES_AND_REPLIES_SPINNER'>
      <i class='fa fa-spinner fa-pulse fa-2x'></i>
    </div>
    <canvas id='DYNAMICS_OF_MESSAGES_AND_REPLIES_CHART' class='chartjs'
            style='display: block; min-height: 250px; max-height: 45vh;'>
    </canvas>
  </div>
</div>

<script src='/styles/default/plugins/chartjs/Chart.min.js'></script>
<script>
  jQuery(document).ready(function () {
    sendRequest(`/api.cgi/msgs/report/dynamics/`, {}, 'GET')
      .then(data => {
        jQuery('#DYNAMICS_OF_MESSAGES_AND_REPLIES_SPINNER').removeClass('d-flex').addClass('d-none');
        var c = document.getElementById('DYNAMICS_OF_MESSAGES_AND_REPLIES_CHART');
        var ctx = c.getContext('2d');

        let chart_data = {
          datasets: [
            {
              backgroundColor: 'rgba(255, 193, 7, 0.8)',
              borderColor: 'rgba(255, 193, 7, 0.8)',
              label: '_{CLOSED}_',
              data: []
            },
            {
              backgroundColor: 'rgba(54, 123, 245, 0.8)',
              borderColor: 'rgba(54, 123, 245, 0.8)',
              label: '_{REPLYS}_',
              data: []
            },
            {
              backgroundColor: 'rgba(2, 99, 2, 0.8)',
              borderColor: 'rgba(2, 99, 2, 0.8)',
              label: '_{MESSAGES}_',
              data: []
            }
          ],
          labels: []
        };

        data.forEach(item => {
          let date = item.date;
          let values = item.value;
          if (!date || !values) return;

          chart_data.labels.push(date);
          chart_data.datasets[0].data.push(values.closed);
          chart_data.datasets[1].data.push(values.replies);
          chart_data.datasets[2].data.push(values.messages);
        });

        new Chart(ctx, {
          type: 'bar',
          data: chart_data,
          maintainAspectRatio: true,
          options: {
            responsive: true,
            title: {
              display: true,
              text: 'chart_title',
              fontSize: 16
            },
          }
        });
      });
  });
</script>