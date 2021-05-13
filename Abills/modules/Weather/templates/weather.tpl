<style>
  .map {
    font-size: 20px;
    background-image: linear-gradient(141deg, #9fb8ad 0%, #1fc8db 45%, #2cb5e8 75%);
    border-radius: 6px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
  }

  #provaider {
    padding: 20px 0px 0px 0px;
  }

  #date {
    font-family: Open Sans;
    font-size: 20px !important;
  }

  @media (max-width: 930px) and (min-width: 470px) {
    .map {
      width: 100%;
    }
  }

  @media (min-width: 1024px) {
    .map {
      width: 30%;
    }
  }
</style>

<form method='POST' action='$SELF_URL'>
  <input type='hidden' name='MOUNT_LANG' value=''>
  <div class="container">
    <div id="map" class="card-body table-responsive map">
      <div class="form-group">
        <div id="city-text">_{CITY}_</div>
        <div class="hidden" id="city-text4">_{LONGITUDE}_</div>
        <div id="city-text6">_{ISP}_</div>
      </div>

      <div class="form-group">
        <div id="times">
          <p>_{TODAY}_: <strong><span id="date"></span><span id="clock"></span></strong></p>
        </div>
      </div>
      <br/>
      <div class="row">
        <div class="form-group">
          <div class="form-group">
            <label class="control-label col-md-6 col-sm-6" align="left">_{TODAY}_</label>
            <div class="col-md-3 col-sm-3">
              <img text-align="center" src="%IMG_TODAY%" alt="No image" height="32" width="32">
            </div>
            <div class="col-md-3 col-sm-3">
              %TEMP_TODAY%
            </div>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="form-group">
          <label class="control-label col-md-6 col-sm-6" align="left">_{TOMORROW}_</label>
          <div class="col-md-3 col-sm-3">
            <img src="%IMG_TOMORROW%" alt="No image" height="32" width="32">
          </div>
          <div class="col-md-3 col-sm-3">
            %TEMP_TOMORROW%
          </div>
        </div>
      </div>

      <div class="row">
        <div class="form-group">
          <label class="control-label col-md-6 col-sm-6" align="left">_{DAT}_</label>
          <div class="col-md-3 col-sm-3">
            <img src="%IMG_DAT%" alt="No image" height="32" width="32">
          </div>
          <div class="col-md-3 col-sm-3">
            %TEMP_DAT%
          </div>
        </div>
      </div>
    </div>
  </div>
</form>
<script>
    var date = new Date();
    var monthGetDate = date.getMonth();
    var day = date.getDate(),
        month = monthGetDate > 8 ? ++monthGetDate : '0' + ++monthGetDate,
        year = date.getFullYear();
    var today = day + '-' + month + '-' + year + ' ';
    var counter = 0;

    document.getElementById("date").innerHTML = today;

    function getWeather(locdata) {
        var lat = locdata.latitude;
        var lon = locdata.longitude;
        var city = locdata.city;
        if (locdata) {
            console.log(locdata.latitude);
            jQuery("#city-text").html(locdata.city);
            jQuery("#city-text4").html(" _{LATITUDE}_: " + locdata.latitude + " _{LONGITUDE}_: " + locdata.longitude);
            jQuery("#city-text6").html(" _{ISP}_: " + locdata.org);
        } else {
            console.log("fail");
        }
    }

    function getLocation() {
        return jQuery.ajax({
            url: "https://ipapi.co/jsonp/",
            dataType: "jsonp",
            type: "GET",
            async: "true",
        });
    }

    setTimeout(function() {
        getLocation().done(getWeather);
    }, 500);

    function clock() {
        var date = new Date(),
            hours = (date.getHours() < 10) ? '0' + date.getHours() : date.getHours(),
            minutes = (date.getMinutes() < 10) ? '0' + date.getMinutes() : date.getMinutes(),
            seconds = (date.getSeconds() < 10) ? '0' + date.getSeconds() : date.getSeconds();
        document.getElementById('clock').innerHTML = hours + ':' + minutes + ':' + seconds;
    }

    setInterval(clock, 1000);
    clock();
</script>