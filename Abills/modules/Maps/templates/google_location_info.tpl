
 
	var latlng = new google.maps.LatLng(%MAP_Y%, %MAP_X% );
	var online = '%USERS_ONLINE%';
	var offline = '%USER_OFFLINE%';
	var sub_online = '%SUB_ONLINE%';
	var Mcolor;
	var thOnline;
	var showOnline = '';
	var showOffline = '';
	var thAll ='';
	
	if (online == '' ) {
		 
		Mcolor = 'build_off';
		if(sub_online == 1) {
		  Mcolor = 'build_on';
		}  
		thOnline ='';
		
		
	} else {
		Mcolor = 'build_on';
		thOnline = '<tr><th class=\"table_title\">$_USER:</th><th class=\"table_title\">IP:</th></tr>';
		showOnline = '<strong><font color=green>$_USERS online(%USER_COUNT_ONLINE%)</font></strong><br /><table border=0 cellspacing=0 cellpadding=0 width=300>'+ thOnline +' %USERS_ONLINE% </table>';
	}	
	if (offline == '' ) {
		thAll ='';
	} else {
	  showOffline = '<strong><font color=red>$_USERS(%USER_COUNT_OFFLINE%):</font></strong><br /><table border=0 cellspacing=0 cellpadding=0 width=300>'+ thAll +'  %USER_OFFLINE% </table>';
		thAll ='<tr><th class=\"table_title\">$_USER:</th><th class=\"table_title\">$_DEPOSIT:</th><th class=\"table_title\">$_FLAT:</th></tr>';
	}
	createMarker(latlng, '<strong>$_STREET: </strong>%STREET_ID%<br /><strong>$_BUILD: </strong>%NUMBER%<br /><div id=\"infoWindowSize\">' + showOnline + ' ' + showOffline + '</div>  ', Mcolor , '%STREET_ID% %NUMBER%', %BUILD_ID%); 
	    