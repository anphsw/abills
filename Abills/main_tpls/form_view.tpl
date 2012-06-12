<script language=\"JavaScript\">
$(document).ready(function () {
	$(\"select[name=VIEW]\").change(function () {
		$.cookie('dhcphosts_view', $(\"select[name=VIEW] option:selected\").val());
	});
	var selected_item = $(\"select[name=VIEW] option:selected\");
	var dhcp_cookie =  $.cookie('dhcphosts_view') || '';
	if(dhcp_cookie.length && dhcp_cookie != selected_item.val() ) {
		selected_item.removeAttr('selected');	
			$(\"select[name=VIEW] option[value=\" +dhcp_cookie+ \"]\").attr('selected', 'yes');
	}
});
</script>

<FORM action='$_SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
%EXT_PARAMS%
<table width=100% border=0>
<tr><td align=right>$_VIEW: %VIEW_SEL% <input type=submit name=show value='$_SHOW'></td></tr>
</table>
</FORM>
