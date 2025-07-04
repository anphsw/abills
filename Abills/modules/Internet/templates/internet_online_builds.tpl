<style>
  .popover {
    max-height: 256px;
    overflow-y: scroll;
  }
</style>

<div class='d-flex justify-content-center form-inline form m-1'>
  <div class='checkbox m-1'>
    <label>
      <input type='checkbox' checked='checked' id='SHOW_ONLINE'>
      _{ONLINE}_
    </label>
  </div>
  <div class='checkbox m-1'>
    <label>
      <input type='checkbox' checked='checked' id='SHOW_OFFLINE'>
      _{OFFLINE}_
    </label>
  </div>
  <div class='checkbox m-1'>
    <label>
      <input type='checkbox' checked='checked' id='SHOW_EMPTY'>
      _{EMPTY}_
    </label>
  </div>
  <div class='form-group m-1'>
    <button class='btn btn-default' id='OPEN_ALL'><span class='fa fa-plus'></span>&nbsp;_{OPEN_ALL}_</button>
  </div>
  <div class='form-group m-1'>
    <button class='btn btn-default' id='CLOSE_ALL'><span class='fa fa-minus'></span>&nbsp;_{CLOSE_ALL}_</button>
  </div>

</div>

<div id='DISTRICT_PANELS'>
</div>

<div id='status-loading-content'>
  <div class='text-center'>
    <span class='fa fa-spinner fa-spin fa-2x'></span>
  </div>
</div>

<script src='/styles/default/js/modules/internet/internet-address-monitoring.js'></script>

<script>
  let districtManager;

  var _LOADING = '_{LOADING}_' || 'Loading';
  var _DISTRICT = '_{DISTRICT}_' || 'District';
  var _DISTRICT = '_{DISTRICT}_' || 'District';
  var _INTERNET_DATA_LOADING_ERROR = '_{INTERNET_DATA_LOADING_ERROR}_' || 'Data loading error';
  var _INTERNET_NO_STREETS_IN_THIS_AREA = '_{INTERNET_NO_STREETS_IN_THIS_AREA}_' || 'No streets in this area';
  var _INTERNET_NO_BUILDINGS_ON_THIS_STREET = '_{INTERNET_NO_BUILDINGS_ON_THIS_STREET}_' || 'No buildings on this street';

  try {
    var onlineUsers = JSON.parse('%ONLINE_USERS_LIST%');
    var offlineUsers = JSON.parse('%OFFLINE_USERS_LIST%');
    var districtTypes = JSON.parse('%DISTRICT_TYPES%');
  } catch (err) {
    console.log('JSON parse error');
    console.log(err);
  }


  jQuery(document).ready(() => {
    districtManager = new DistrictManager({
      onlineUsers: onlineUsers,
      offlineUsers: offlineUsers,
      districtTypes: districtTypes,
    });

    districtManager.init();
  });
</script>