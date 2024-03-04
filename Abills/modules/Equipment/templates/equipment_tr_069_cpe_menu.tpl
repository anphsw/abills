<div class='row'>
  <div class='col-3 col-sm-2'>
    <div class='nav flex-column nav-tabs h-100' id='cpe-menu' role='tablist' aria-orientation='vertical'>
        %SUB_MENU_CONTENT%
    </div>
  </div>
  <div class='col-9 col-sm-10'>
    <div class='tab-content' id='content'>
      %HTML_CONTENT%
    </div>
  </div>
</div>

    <script>
        jQuery(document).ready(function(){
            jQuery('#cpe-menu a').click(function(e){
                var clickedID = jQuery(this).attr( 'id' );
                console.log(clickedID);
                var em = jQuery(this);
                jQuery.ajax({
                    type: 'POST',
                    url: 'index.cgi',
                    data: 'get_index=equipment_info&TR_069=1&info_pon_onu=%info_pon_onu%&onu_info=1&tr_069_id=%tr_069_id%&header=2&menu=%MENU%&sub_menu='+clickedID,
                    success: function(html){
                        jQuery('#content').html(html);
                        jQuery('#cpe-menu a').removeClass('active');
                        em.addClass('active');
                    }
                });
                return false;
            });
        });
    </script>
