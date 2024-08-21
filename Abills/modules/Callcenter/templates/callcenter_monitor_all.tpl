<div class='p-2 col-md-6'>
  <form name='report_panel' id='report_panel' method='get'>
    <input type='hidden' name='index' value='%index%'/>

    <div class='form-row align-items-center my-2'>
      <div class='col-md-4'>
        <label class='sr-only' for='REFRESH'>_{REFRESH}_ (sec): </label>
        <input type='text' placeholder='_{REFRESH}_ (sec):' name='REFRESH' value='%REFRESH%' class='form-control' id='REFRESH'
               data-tooltip='_{REFRESH}_ (sec):' data-tooltip-position='top'>
      </div>
      <div>
        <input type='SUBMIT' name='SHOW' value='_{SHOW}_' class='btn btn-primary' id='SHOW'>
      </div>
    </div>

  </form>
</div>

<div class='d-flex'>

  <div>
    %GROUP_ONLINE%
  </div>
  <div>
    %GROUP_OFFLINE%
  </div>

</div>

<script>

  updateRefresh();

  function updateRefresh (){

    var url = new URL(window.location.href);
    var params = new URLSearchParams(url.search);
    var refreshValue = params.get('REFRESH');
    if (refreshValue && refreshValue > 0){
      jQuery('#REFRESH').val(refreshValue);
    }

  }


</script>