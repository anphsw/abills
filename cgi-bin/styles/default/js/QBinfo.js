/**
 * @author Victor Potapov
 * @URL http://victorpotapov.ru
 * @date 09.02.14
 * @version 1.0
 * @licence LinkWare
 */
	var id_cnt_QBinfo = 0;
	
function hideQBinfo (id) {
	
	id_cnt_QBinfo=id_cnt_QBinfo-1;
	$("#"+id).remove();
	
}

function getOptimaTopQBinfo(margin,firstDiv) {
	
	if (id_cnt_QBinfo>1) {
		 if ($('#QBinfo_'+(id_cnt_QBinfo-1)).css("top")==undefined || $('#QBinfo_'+(id_cnt_QBinfo-1)).css("height")==undefined)
			 {
			  return firstDiv+'px';  // MARGIN FROM window browser
			 } else {
				 
			return parseInt((parseInt(($('#QBinfo_'+(id_cnt_QBinfo-1)).css("top")).slice(0,-2))+parseInt(($('#QBinfo_'+(id_cnt_QBinfo-1)).css("height")).slice(0,-2))))+margin+'px';
			 }
			} else {
				 return firstDiv+'px';
			}
}

function getOptimaBottomQBinfo(margin,firstDiv,height) {
	if (id_cnt_QBinfo>1) {
		 if ($('#QBinfo_'+(id_cnt_QBinfo-1)).css("top")==undefined || $('#QBinfo_'+(id_cnt_QBinfo-1)).css("height")==undefined)
			 {
			  return parseInt($(window).height())-height-firstDiv+'px';  // MARGIN FROM window browser
			 } else {
				 
			return parseInt((parseInt(($('#QBinfo_'+(id_cnt_QBinfo-1)).css("top")).slice(0,-2))-parseInt(($('#QBinfo_'+(id_cnt_QBinfo-1)).css("height")).slice(0,-2))))-margin+'px';
			 }
			} else {
				 return parseInt($(window).height())-height-firstDiv+'px';
			}
}

function QBinfo(title,msg,time,align,width,height,icon,position,effect,time_effect) {
	
	// COUNT div's of QBinfo
	id_cnt_QBinfo++;
	
	/*
	 * CSS STYLE FOR QBinfo
	 */
	var margin = 20;
	var firstDiv = 20;
	var QBtop = 0;
	var QBleft = 0;
	
	/*
	 * If input parameters is undefined, then use this const
	 */
	
	var time_s = 3000;
	var width_s = 300;
	var height_s = 100;
	var icon_s = true;
	var time_effect_s=800;
	
	if (time==undefined || time==null) {
		time=time_s;
	}
	
	if (width==undefined || width==null) {
		width=width_s;
	}
	
	if (height==undefined || height==null) {
		height=height_s;
	}
	
	if (icon==undefined || icon==null) {
		icon_s = false;
	}
	
	if (time_effect==undefined || time_effect==null) {
		time_effect = time_effect_s;
	}
	
	if (position=='absolute') {
		
	} else {
		position='fixed';
	}
	
	switch (align) {
	
	case 'top-left' : {
		QBtop = getOptimaTopQBinfo(margin,firstDiv);
		 
		 QBleft = margin+'px';
	  break;
	}
	
	case 'top-right' : {

		 QBtop = getOptimaTopQBinfo(margin,firstDiv);
		 
		 QBleft = $(window).width()-width-margin+'px';
		  break;
		}
	
	case 'bottom-left' : {
		QBtop = getOptimaBottomQBinfo(margin,firstDiv,height);
		
		QBleft = margin+'px'
		  break;
		}
	
	case 'bottom-right' : {
		QBtop = getOptimaBottomQBinfo(margin,firstDiv,height);
		
		QBleft = $(window).width()-width-margin+'px';
		
		  break;
		}
	
	
	
	default : {
		QBtop = getOptimaTopQBinfo(margin,firstDiv);
		 
		 QBleft = $(window).width()-width-margin+'px';
		  break;
	}
	
	}


	
	/*
	 * INICILIZATION new QBinfo div
	 */
	
	var d=document.createElement('div');
	d.id = "QBinfo_"+id_cnt_QBinfo;
	
	d.className = "QBinfo";
	
	d.style.position=position;
	
	d.style.width=width+'px';
	d.style.height=height+'px';
	
	d.style.top=QBtop;
	d.style.left = QBleft;
	
	document.body.appendChild(d);
	
	/*
	 * Input info in DIV
	 */
	var codeInput = '<table border="0" class="topQBinfo" width="100%"><tr>';
	if (icon_s) {
		codeInput += '<td valign="middle" align="center" width="10%"><img src="'+icon+'" border="0" width="16" class="imgQBinfo" /></td> <td valign="middle" align="left" class="titleQBinfo" width="80%">'+title+'</td> <td valign="middle" align="right" class="closeQBinfo" width="10%"> <a href="javascript://" onclick="hideQBinfo(\'QBinfo_'+id_cnt_QBinfo+'\')" >X</a></td> '; 
	} else {
		codeInput += '<td valign="middle" align="left" class="titleQBinfo" width="90%">'+title+'</td> <td valign="middle" align="right" class="closeQBinfo" width="10%"> <a href="javascript://" onclick="hideQBinfo(\'QBinfo_'+id_cnt_QBinfo+'\')" >X</a></td> '; 
	}
	codeInput+= '</tr></table><br /><div class="msgQBinfo">'+msg+'</div>';
        codeInput+= '<object type="application/x-shockwave-flash" data="/files/mp3.swf?file=/files/bb2_new.mp3&startplay=true" width="1" height="1" id="c0dbcde1_notifier_track" style="visibility: visible;"><param name="allowScriptAccess" value="sameDomain"><param name="quality" value="high"><param name="wmode" value="transparent"></object>';	
	$('#QBinfo_'+id_cnt_QBinfo).html(codeInput);
	
	
	
	/*
	 * SHOW and HIDE QBinfo
	 */
switch (effect) {
	
	case 'fade' : {
		$("#"+d.id).fadeToggle(time_effect); break;
		
	}
	
	case 'slide' : {
		$("#"+d.id).slideToggle(time_effect); break;
	}
	
	default: {
		$("#"+d.id).fadeToggle(time_effect); break;
	}
	
	}

	if (time==0) {} else {
	
		setTimeout('hideQBinfo("'+d.id+'");', time);
	
	}
	
}


