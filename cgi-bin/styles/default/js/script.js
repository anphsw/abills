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
var interval=null;

if (!xmlHttp && typeof XMLHttpRequest != 'undefined') {
  xmlHttp = new XMLHttpRequest();
}

function start(operator) {
    if (interval!=null) {
	clearInterval(interval);
    }
    operatorPhone=operator;
    interval=setInterval("check()",2000);
    check();
}

function check() {
    var url = "/cgi-bin/get-current-calls.cgi?operator=" + escape(operatorPhone);
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
		var id=r[0];
		var time=r[1];
		var caller=r[2];
		var uid=r[4];
		var uphone=r[5];
		
		if ((i==0) && (id!=lastRecord)) {
		    lastRecord=id;
		    if (uid!='') {
			userInfo(uid);
		    }
		}
		
		s+=""+time+"</br>"+caller+"</br>";
		
		if (uid!='') {
		    s+="<input type=submit name=info value=\"User info\" onclick='userInfo("+uid+")'></br>";
		}
		
		s+="<input type=submit name=delete value=\"Delete\" onclick='deleteRecord("+id+")'></br>";
	    }
	
	}
	else {
	    s+="No active calls<br>";
	}
	document.getElementById("info").innerHTML = "<b>Operator "+operatorPhone+"</b><br><br>"+getDate()+" "+getTime()+"<br><br>"+s;
    }
}

function userInfo(uid) {
    window.open("/cgi-bin/user-info.cgi?uid="+uid,"userinfo-"+uid,"left=512,top=100,width=400,height=400");
}

function getDate() {
	var d = new Date();
	var current_date = d.getDate();
	var current_month = d.getMonth()+1;
	var current_year = d.getFullYear();
	
	return current_date + "." + current_month + "." + current_year;
	
}

function getTime() {
	var currentTime = new Date();
	var hours = currentTime.getHours();
	var minutes = currentTime.getMinutes();
	var seconds = currentTime.getSeconds();
	
	if (minutes < 10){
		minutes = "0" + minutes;
	}
	if (seconds < 10){
		seconds = "0" + seconds;
	}
	return hours + ":" + minutes + ":" + seconds;
}

function deleteRecord(id) {
    var url = "/cgi-bin/get-current-calls.cgi?delete=" + escape(id);
    xmlHttp.open("GET", url, true);
    xmlHttp.onreadystatechange = null;
    xmlHttp.send(null);
}
