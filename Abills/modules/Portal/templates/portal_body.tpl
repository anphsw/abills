<!DOCTYPE html>
<html>
<head>
  <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
  <title>$conf{WEB_TITLE} - Portal</title>

  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/font-awesome.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/adminlte.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datatables/dataTables.bootstrap.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/timepicker/bootstrap-timepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/daterangepicker/daterangepicker.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datetimepicker/datetimepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/style.css'>

  <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/bootstrap.bundle.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/adminlte.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/bs-stepper.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/select2.min.js'></script>


  <style>
    #form_login span.fa {
      top : 0;
    }

    #form_login #input_wrapper{
      padding: 20px 30px 20px
    }

    .brand-logo {
      padding: 2px;
      margin-right: 4em;
    }

    .login-button {
      margin: 5px 5px;
    }

    .btn-group {
      padding-right:28px;
    }

    .timeline {
      margin-top: 15px;
    }

    .modal-header-primary {
      color: #fff;
      padding: 9px 15px;
      border-bottom: 1px solid #eee;
      background-color: #428bca;
      border-top-left-radius: 5px;
      border-top-right-radius: 5px;
    }

    body {
      background-color: #ecf0f5;
    }

    .cookieAcceptBar {
      right: 0;
      text-align: center;
      background-color: #333;
      color: #fff;
      padding: 20px 0;
      z-index: 99999;
      position: fixed;
      width: 100%;
      height: 100px;
      bottom: 0;
      left: 0;
    }

    .cookieAcceptBar a {
      color: #fff;
      text-decoration: none;
      font-weight: bold;
    }

    button .cookieAcceptBarConfirm {
      cursor: pointer;
      border: none;
      background-color: #2387c0;
      color: #fff;
      text-transform: uppercase;
      margin-top: 10px;
      height: 40px;
      line-height: 40px;
      padding: 0 20px;
    }

    .article {
      padding-bottom: 0px;
    }

    .picture {
      max-width: 100%;
      max-height: 400px;
    }
  </style>

</head>
<body class='skin-blue-light sidebar-collapse layout-boxed '>
<div class='container'>

<header class='navbar navbar-expand-lg navbar-light bg-light'>
  <a href='index.cgi' class='navbar-brand pl-2'>
  <!-- mini logo for sidebar mini 50x50 pixels -->
    <span class='logo-mini' title='ABillS'>
      <b><span style='color: red;'>A</span></b>BillS
    </span>
  </a>

  <button
    class='navbar-toggler'
    type='button'
    data-toggle='collapse'
    data-target='#navbarContent'
    aria-controls='navbarContent'
    aria-expanded='false'
    aria-label='Toggle navigation'
  >
    <span class='navbar-toggler-icon'></span>
  </button>

  <div class='collapse navbar-collapse' id='navbarContent'>
    <ul class='navbar-nav mr-auto'>
      %MENU%
    </ul>

    <ul class='navbar-nav'>
      <li>
        %REGISTRATION%
      </li>
    </ul>
    <a href='%SELF_URL%?login_page=1' class='btn btn-primary' title='_{USER_PORTAL}_'>
      <i class='fa fa-user'></i>
      _{USER_PORTAL}_
    </a>
  </div>
</header>

<div id='bodyPan'>

  <ul class='list-unstyled'>
    %CONTENT%
  </ul>
  </div>

  <div id='bodyMiddlePan'>
  </div>

  <div id='footermainPan'>
    <div id='footerPan'>
    </div>
  </div>

</div>
  <div id='cookieAcceptBar' class='cookieAcceptBar' style='display: none;'>
    _{COOKIE_AGREEMENTS}_
    <a href='%COOKIE_URL_DOC%' target='_blank'>_{COOKIE_URL}_</a>
    <br>
    <button id='cookieAcceptBarConfirm' class='btn btn-success' onclick='hideBanner()'>_{SUCCESS}_</button>
  </div>
</body>
</html>

<script>
  jQuery(document).on('ready', function() {
    var successCookie = localStorage.getItem('successCookie');

    if (successCookie != '1') {
      jQuery('#cookieAcceptBar').show();

      var checkVisibleCookie = jQuery('#HIDDE_COOKIE').val();
      jQuery('#cookieAcceptBar').css('display', checkVisibleCookie)
    }
  });

  function hideBanner() {
    var banner = document.getElementById('cookieAcceptBar');

    if (banner.style.display === 'none') {
      banner.style.display = 'block';
    } else {
      banner.style.display = 'none';
      localStorage.setItem('successCookie', 1);
    }
  }

</script>