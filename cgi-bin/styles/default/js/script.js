var xmlHttp = false;
/*@cc_on @*/
/*@if (@_jscript_version >= 5)
try {
  xmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
} catch (e) {
  try {
    xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
  } catch (e2) {
    xmlHttp = false;
  }
}
@end @*/

//var counter=0;
var lastRecord=0;
var operatorPhone;
var qindex;
var interval=null;

if (!xmlHttp && typeof XMLHttpRequest != 'undefined') {
  xmlHttp = new XMLHttpRequest();
}

function start(operator, index) {
    if (interval!=null) {
	clearInterval(interval);
    }
    operatorPhone=operator;
    qindex = 'qindex=' + index ;
    interval=setInterval("check()",2000);
    check();
}

function check() {
    var url = '/admin/index.cgi?' + qindex + '&current_call=1&operator=' + escape(operatorPhone);
    xmlHttp.open("GET", url, true);
    xmlHttp.onreadystatechange = updatePage;
    xmlHttp.send(null);
}

function updatePage() {
    if (xmlHttp.readyState == 4) {
	var response = xmlHttp.responseText;
	var n=response.split("|");
	n.splice(-1,1);
	var s="";

	if (n.length>0) {
	    
	    for (var i=0; i < n.length; i++) {
		var r=n[i].split(",");
		var caller=r[0];
		var uid=r[1];
		var login=r[2];
                var title=r[3];
                var num=r[4];
                var unknown=r[5];
		if (uid!='0') {
                   QBinfo("<b>"+title+"</b>","<b>"+num+" "+caller+" </b><a  class=link_button href=/admin/index.cgi?index=15&UID="+uid+"><b>"+login+"</b></a></br>",15000,'bottom-left',300,100,'/img/information.png','absolute');
		}
		else {
                   QBinfo("<b>"+title+"</b>","<b>"+num+" "+caller+" "+unknown+"",15000,'bottom-left',300,100,'/img/information.png','absolute');
                }
	    }

	}
    }
}
