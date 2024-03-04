<nav class="abills-navbar navbar navbar-expand-lg navbar-light">
<div class="collapse navbar-collapse">

  <ul class="navbar-nav nav-tabs" id='nav-tr-069'>
  <li class="nav-item active" id='status'><a class='nav-link active' title="Status" href="#">Status</a></li>
  <li id='wan'><a class='nav-link' title="WAN" href="#">WAN</a></li>
  <li id='wlan'><a class='nav-link' title="WIFI" href="#">WLAN</a></li>
  <li id='voip'><a class='nav-link' title="VoIP" href="#">VoIP</a></li>
  </ul>
</div>
</nav>
<div class='card box-solid'>
  <div class='card-body' id=ajax_content style='padding: 0;'>
    %HTML_CONTENT%
  </div>
</div>

<style>
.nav-stacked > li > a:hover, 
.nav-stacked > li > a:active, 
.nav-stacked > li > a:focus,
.nav-stacked > li.active > a,
.nav-stacked > li.active > a:hover
{
    border-left-color: #00a65a;
}

.nav-stacked > li > a {
    border-left: 3px solid #909090;
}
.box .nav-stacked > li {
    border-right: 1px solid #f4f4f4;
}
.box .nav-stacked > li:last-of-type {
    border-bottom: 1px solid #f4f4f4;
}
</style>

    <script>
        jQuery(document).ready(function(){
            jQuery('#nav-tr-069 li').click(function(e){
                var clickedID = jQuery(this).attr( "id" );
                var em = jQuery(this);
                  jQuery.ajax({
                    type: 'POST',
                    url: 'index.cgi',
                    data: 'get_index=equipment_info&TR_069=1&onu_info=1&info_pon_onu=%info_pon_onu%&tr_069_id=%tr_069_id%&header=2&menu='+clickedID,
                    success: function(html){
                        jQuery('#ajax_content').html(html);
                        jQuery('#nav-tr-069 li').removeClass('active');
                        jQuery('#nav-tr-069 a').removeClass('active');
                        em.addClass('active');
                        em.find('a').addClass('active');
                    }
                });
                return false;
            });
            Events.on('AJAX_SUBMIT.form_setting', function({FORM: form_id, RESULT: result}){
              
            });
        });
    </script>
