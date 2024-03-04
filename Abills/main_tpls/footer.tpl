</section>
<!-- /.content -->
</div>
<!-- /.content-wrapper -->

<!-- Main Footer -->
<footer class='main-footer'>
  %FOOTER_CONTENT%
  %FOOTER_DEBUG%
  <div class='px-1 my-n1 row justify-content-between align-items-center'>
    <div class='d-flex align-items-center' style='column-gap: 4px'>
      <a href='http://abills.net.ua/?utm_source=abills' target='_blank'>
        <b><span style='color: red'>A</span>BillS</b>
      </a>
      %VERSION%
    </div>
    <div class='d-inline-block'>
      <button id='feedback_modal_btn' type='button' class='btn btn-primary btn-xs'
              onclick="loadToModal('?POPUP=1&FEEDBACK=1')">
        <span class='fa fa-comment'></span>
      </button>
    </div>
  </div>
</footer>
<!-- Control Sidebar -->
%RIGHT_MENU%
<script src='/styles/default/js/old/control-sidebar.js' defer></script>
<script src='/styles/default/js/abills/control-web.js' defer></script>

<script>
  /* Closing right sidebar by resize */
  let canBeOpen = '$admin->{RIGHT_MENU_OPEN}' !== '';
  let openRightSidebar = !canBeOpen;
  jQuery(function () {
    jQuery(rightSidebarButton).on('click', function() {
      if (mybody.classList.contains('control-sidebar-slide-open')) {
        openRightSidebar = false;
      } else {
        openRightSidebar = true;
      }
    });
  });

  function controlRightMenu() {
    if(mybody.classList.contains('control-sidebar-slide-open')) {
      if(mybody.clientWidth < 1200) {
        rightSidebarButton.click();
      }
    } else {
      if(!openRightSidebar) {
        if(mybody.clientWidth > 1200) {
          rightSidebarButton.click();
        }
      }
    }
  }
  window.addEventListener('resize', controlRightMenu, false);

  /* Double click mouse control */
  jQuery('form').submit(() => {
    if (jQuery('input[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('input[type=submit]:focus').addClass('disabled').val('_{IN_PROGRESS}_...');
      const val = jQuery('input[type=submit]:focus').attr('val') || '1';
      const name = jQuery('input[type=submit]:focus').attr('name');
      jQuery('<input />').attr('type', 'hidden')
        .attr('name', name)
        .attr('value', val)
        .appendTo('form');
      jQuery('input[type=submit]:focus').attr('disabled', true);
    }
    if (jQuery('button[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('button[type=submit]:focus').addClass('disabled');
      const val = jQuery('button[type=submit]:focus').attr('val') || '1';
      const name = jQuery('button[type=submit]:focus').attr('name');
      jQuery('<input />').attr('type', 'hidden')
        .attr('name', name)
        .attr('value', val)
        .appendTo('form');
      jQuery('button[type=submit]:focus').attr('disabled', true);
    }
  });

  jQuery('.hidden_empty_required_filed_check').on('click', function() {
    let form = jQuery(this).closest('form');
    if (form.length < 1) return;

    let hiddenRequiredEmptyFields = form.find("input[required], textarea[required], select[required]");
    hiddenRequiredEmptyFields.each((index, field) => {
      if (jQuery(field).val() || jQuery(field).width() > 1) return;

      jQuery(field).closest('.collapsed-card').find('.btn-tool > .fa-plus').first().click();
    })
  });
</script>
%PUSH_SCRIPT%

