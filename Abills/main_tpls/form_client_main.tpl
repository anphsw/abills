<nav class='main-header navbar navbar-expand navbar-dark navbar-lightblue'>

  <ul class='navbar-nav'>
    <li class='nav-item'>
      <a class='nav-link' data-widget='pushmenu' data-slide='true' href='#' role='button'>
        <i class='fa fa-th-large'></i>
      </a>
    </li>
  </ul>
  <ul class='navbar-nav ml-auto'>
    <li class='nav-item d-none d-sm-inline-block'>
      <span class='nav-link'><strong>_{DATE}_:</strong> %DATE% %TIME%</span>
    </li>
    <li class='nav-item d-none d-sm-inline-block' %REG_LOGIN%>
      <span class='nav-link'><strong>_{LOGIN}_:</strong> %LOGIN%</span>
    </li>
    <li class='nav-item d-none d-sm-inline-block'>
      <span class='nav-link'><strong>IP:</strong> %IP%</span>
    </li>
    <li class='nav-item d-none d-sm-inline-block' %REG_STATE%>
      <span class='nav-link'><strong>_{STATE}_:</strong> %STATE%</span>
    </li>
  </ul>

  <ul class='navbar-nav ml-auto'>
    <li class='nav-item dropdown'>
      <a href='#'>
        <div class='input-group input-group-sm input-group-custom-select'>
          %SELECT_LANGUAGE%
        </div>
      </a>
    </li>
  </ul>
</nav>
<!-- menu -->
  <aside id='main-sidebar' class='main-sidebar sidebar-dark-lightblue elevation-4'>
    <a href='%INDEX_NAME%' class='logo' %S_MENU%>
      <a href='index.cgi' class='brand-link pb-2 text-center' style='font-size: 1.25rem; padding: .55rem .5rem;'>
        <img src='/img/abills.svg' class='brand-image-xl logo-xs'>
        <span class='brand-text font-weight'><b><span style='color: red;'>A</span></b>BillS</span>
      </a>
    </a>
    <div class='sidebar'>
      %MENU%
    </div>
  </aside>
  <div class='content-wrapper'>
    <section class='content p-2' id='main-content'>
      <br/>
      %BODY%
    </section>
  </div>
</div>

<!-- client_start End -->

<!-- AdminLTE App -->
<script src='/styles/lte_adm/dist/js/app.js'></script>

<script>
  if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
    jQuery('#language_mobile').on('change', selectLanguage);
  } else {
    jQuery('#language').on('change', selectLanguage);
  }
</script>
%PUSH_SCRIPT%
</body>

%CHECK_ADDRESS_MODAL%