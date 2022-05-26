<div class='col-lg-12 grid-margin stretch-card'>
  <div class='card card-weather'>
    <div class='card-header pb-2'>
      <div>
        <h3>%DATA%</h3>
      </div>
      <div class='d-flex flex-row'>
        <img src='https://openweathermap.org/img/wn/%ICON%@2x.png'
             alt='%ICON%'>
        <div>
          <h1 class='mt-2'>
            %DEG%<span class='symbol'>&deg;</span>C
          </h1>
          <p class='text-gray'>
            <span>%DESC%&deg;C</span>
          </p>
        </div>
        <div>
          <h5 class='text-danger'>
            <span>%TODAY_WARNINGS%</span>
          </h5>
        </div>
      </div>
    </div>
    <div class='card-footer p-0'>
      <div class='d-flex weakly-weather'></div>
    </div>
  </div>
</div>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  } catch (err) {
    console.log('JSON parse error.');
  }

  arr.map((item) => {
    console.log(item);
    let element = `<div class='weakly-weather-item'>
            <h5 class='mb-0'>
              ` + item.DATE + `
            </h5>
            <img src='https://openweathermap.org/img/wn/` + item.ICON + `.png'>
            <h5 class='mb-0'>
              ` + item.TEMP_MAX + `&deg; <span class='text-gray'>` + item.TEMP_MIN + `</span>&deg;` + `
            </h5>
            <p class='text-gray'>
              <span>` + item.DESC + `</span>
            </p>
          </div>`;

    jQuery('.weakly-weather').append(element);
  });
</script>

<style>
  .card-weather .card-header:first-child {
    background: #e4f2fb;
  }

  .text-gray {
    color: #969696;
  }

  .card-weather .weakly-weather .weakly-weather-item {
    flex: 0 0 25%;
    border-right: 2px solid #f2f2f2;
    background: white;
    padding-top: 10px;
    text-align: center;
  }
</style>
