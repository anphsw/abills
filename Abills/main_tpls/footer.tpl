</section>
<!-- /.content -->
</div>
<!-- /.content-wrapper -->

<!-- Main Footer -->
<footer class="main-footer">
  <!-- To the right -->
  <div class="float-right hidden-xs">

  </div>
  <b><span style='color: red'>A</span>BillS</b> %VERSION%
  <div class='float-right'>
    <button id='feedback_modal_btn' type="button" class="btn btn-primary btn-xs"
            onclick="loadToModal('?POPUP=1&FEEDBACK=1')">
      <span class='fa fa-comment'></span>
    </button>
  </div>
  %DEBUG_FORM%
</footer>
<!-- Control Sidebar -->
%RIGHT_MENU%
<script src='/styles/default/js/old/control-sidebar.js' defer></script>
<script src='/styles/default/js/abills/control-web.js' defer></script>

<script>
  /* Closing right sidebar by resize */
  function controlRightMenu() {
    if(mybody.classList.contains('control-sidebar-slide-open')) {
      if(mybody.clientWidth < 1200) {
        rightSidebarButton.click();
      }
    } else {
      if('$admin->{RIGHT_MENU_OPEN}' !== '') {
        if(mybody.clientWidth > 1200) {
          rightSidebarButton.click();
        }
      }
    }
  }
  window.addEventListener('resize', controlRightMenu, false);


  /* Double click mouse control */
  jQuery('form').submit(function() {
    if (jQuery('input[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('input[type=submit]:focus').addClass('disabled').val('_{IN_PROGRESS}_...');
    }
    if (jQuery('button[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('button[type=submit]:focus').addClass('disabled');
    }
  });
</script>
%PUSH_SCRIPT%

