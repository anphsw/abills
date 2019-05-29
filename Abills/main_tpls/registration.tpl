<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>

  <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
  <meta HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
  <meta HTTP-EQUIV='Expires' CONTENT='-1'/>
  <meta HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
  <meta HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <meta HTTP-EQUIV='Content-Language' content='%CONTENT_LANGUAGE%'/>
  <meta name='Author' content='~AsmodeuS~'/>

  <title>%TITLE%</title>
  <!-- CSS -->
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/select2.css'>
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/bootstrap.min.css'>
  <link rel='stylesheet' href='/styles/lte_adm/dist/css/AdminLTE.css'>

  <!-- Theme style -->
  <link rel='stylesheet' href='/styles/lte_adm/dist/css/skins/_all-skins.css'>

  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/currencies.css'>

  <link rel='stylesheet' href='/styles/lte_adm/plugins/pace/pace.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/datepicker/datepicker3.css'>
  <!--<link rel='stylesheet' type='text/css' href='/styles/default_adm/css/chosen.min.css'>-->
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/QBInfo.css'>

  <!-- Ionicons -->
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/font-awesome.min.css'>
  <link rel='stylesheet' href='/styles/default_adm/css/ionicons.min.css'>
  <!-- Pace style -->

  <!-- DataTables -->
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/datatables/dataTables.bootstrap.css'>
  <link rel='stylesheet' type='text/css' href='/styles/lte_adm/plugins/timepicker/bootstrap-timepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/default_adm/css/style.css'>

  <!-- Bootstrap -->
  <script src='/styles/default_adm/js/jquery.min.js'></script>
  <script src='/styles/default_adm/js/bootstrap.min.js'></script>

  <!-- Cookies and LocalStorage from JavaScript -->
  <script src='/styles/default_adm/js/js.cookies.js'></script>
  <script src='/styles/default_adm/js/permanent_data.js'></script>

  <!-- temp -->
  <script src='/styles/default_adm/js/functions.js'></script>
  <script src='/styles/default_adm/js/functions-admin.js'></script>

  <!--Keyboard-->
  <script src='/styles/default_adm/js/keys.js'></script>

  <!-- Navigation bar saving show/hide state -->
  <script src='/styles/default_adm/js/navBarCollapse.js'></script>

  <!-- Custom <select> design -->
  <!--<script src='/styles/default_adm/js/chosen.jquery.min.js'></script>-->

  <!--Javascript template engine-->
  <script src='/styles/default_adm/js/mustache.min.js'></script>

  <script src='/styles/default_adm/js/QBinfo.js'></script>

  <!--Event PubSub-->
  <script src='/styles/default_adm/js/events.js'></script>

  <!-- Modal popup windows management -->
  <script src='/styles/default_adm/js/modals.js'></script>

  <!-- AJAX Search scripts -->
  <script src='/styles/default_adm/js/search.js'></script>

  <script src='/styles/default_adm/js/messageChecker.js'></script>

  <script src='/styles/default_adm/js/msgs/jquery-ui.min.js'></script>

  <!-- date-range-picker -->
  <script src='/styles/lte_adm/plugins/moment/moment.min.js'></script>
  <script src='/styles/lte_adm/plugins/datepicker/bootstrap-datepicker.js'></script>
  <script src='/styles/lte_adm/plugins/pace/pace.js'></script>
  <script src='/styles/lte_adm/plugins/datatables/jquery.dataTables.min.js'></script>
  <script src='/styles/lte_adm/plugins/datatables/dataTables.bootstrap.min.js'></script>
  <script src='/styles/lte_adm/plugins/timepicker/bootstrap-timepicker.min.js'></script>
  <script src='/styles/default_adm/js/select2.min.js'></script>

  <script>
    var SELF_URL = '$SELF_URL';
    var CONTENT_LANGUAGE = '%CONTENT_LANGUAGE%';
  </script>

</head>
<body class='hold-transition layout-boxed'>
<div class='container'>
  <div class='row'>
    <div class='col-md-3'>
      %HEADER_ROW%
    </div>
  </div>
  <div class='row'>
    %BODY%
  </div>
</div>
</body>

%CHECK_ADDRESS_MODAL%