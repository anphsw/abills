<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
<meta http-equiv='content-type' content='text/html; charset=utf-8' />
<title></title>
<meta name='keywords' content='' />
<meta name='description' content='' />
<script src='functions.js' type='text/javascript' language='javascript'></script>
<script src='/calendar.js' type='text/javascript' language='JavaScript'></script>

<style type='text/css'>
* {
	margin: 0;
	padding: 0;
}
body {
	font: 12px/18px Arial, Tahoma, Verdana, sans-serif;
	width: 100%;
}
a {
	color: blue;
	outline: none;
	text-decoration: underline;
}
a:hover {
	text-decoration: none;
}
p {
	margin: 0 0 18px
}
img {
	border: none;
}
input {
	vertical-align: middle;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;
	margin-right: 5px;
	
}
textarea {
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;
}
select {
	margin-top:11px;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;

}

button {
	margin-top:11px;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;
	font-weight:bold;
	padding: 3px;

}

button:hover {
	background-color: #ccc;
	cursor:pointer;

}

table {
margin-top:15px;
text-align: center;



}

th {
height:35px;
background-color: #F0F0F0;

}


.tcaption {

float:right;
padding: 0px 10px 0px 0px;
font-size:1.2em;
font-weight:800;

}

#wrapper {
	width: 1000px;
	margin: 0 auto;
}
/* Header
-----------------------------------------------------------------------------*/
#header {
	height: 10px;
	/*background: #FFE680; */
	/*background-color: #F0F0F0; */
}
/* Middle
-----------------------------------------------------------------------------*/
#content {
	position:relative;
	min-height:400px;
}
#menu li {
	background-color: #F4F4F4;
	border:2px solid #ccc;
	list-style:none;
	display:inline-block;
	padding:10px 20px;
	margin-top:11px;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;
}
#menu li:hover {
	background-color: #ccc;
	cursor:pointer;

}

#menu li a {
	padding:20px 40px;
	text-decoration: none;
	color:#000;
	font-weight:bold;	
}
#auth {
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	position:absolute;
	border:2px solid #ccc;
	width:200px;
	height:100px;
	text-align:center;
	top:0px;
	right:20px;
}
#auth p {
	padding-bottom:1px;
}
#statistic {
	list-style:none;
	margin:10px 0px 0px 20px;
}
#buttons {
	margin:10px;
}
#buttons li {
	list-style:none;
	display:inline-block;
}
#buttons li button {
	padding:10px 20px;
}
.big_buttons {
	padding:10px 20px;
}

.href_buttons {

	padding:10px 20px;
	margin-top:11px;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;
	font-weight:bold;
	background-color: #f0f0f0;
	cursor:pointer;
	text-decoration:none;
	color: #000;
	font-size:14px;


}
.href_buttons:hover {
	background-color: #ccc;
	cursor:pointer;
}
#accounts {
	margin:10px;
	padding:10px 20px;
}
#search {
	margin:10px;
}
#search form input {
	margin:10px;
	height:20px;
	width:250px;
}
#search select {
	margin-top:8px;
	width:150px;
	height:24px;
	font-size:14px;
}
#search button {
	padding:10px;
}

.table_border {
	margin:0px 0px 0px; 
	border:2px solid #f0f0f0;
	border-collapse: collapse;
}
.table_border th, .table_border td{
	border:2px solid #f0f0f0;
	border-collapse: collapse;
}
.table_border .table_border {
	border-bottom:0px solid #f0f0f0;
}

.table_border .table_border td {
	border-bottom:0px solid #f0f0f0;
}


/* calendar icon 
 input box in default state */
.tcalInput {
	background:url(/img/cal.gif) 100% 50% no-repeat;
	padding-right:20px;
	cursor:pointer;
	width:70px;
}

/* additional properties for input boxe in activated state, above still applies unless in conflict */
.tcalActive {
	background-image:url(/img/no_cal.gif);
}

/* container of calendar's pop-up */
#tcal {
	position:absolute;
	visibility:hidden;
	z-index:100;
	width:170px;
	background-color:#FFF;
	margin-top:2px;
	border:1px solid silver;
	-moz-box-shadow:3px 3px 4px silver;
	-webkit-box-shadow:3px 3px 4px silver;
	box-shadow:3px 3px 4px silver;
	-ms-filter:\"progid:DXImageTransform.Microsoft.Shadow(Strength=4, Direction=135, Color='silver')\";
	filter:progid:DXImageTransform.Microsoft.Shadow(Strength=4, Direction=135, Color='silver');
	padding:0 2px 2px;
}

/* table containing navigation and current month */
#tcalControls {
	border-collapse:collapse;
	border:0;
	width:100%;
}

#tcalControls td {
	border-collapse:collapse;
	border:0;
	width:16px;
	background-position:50% 50%;
	background-repeat:no-repeat;
	cursor:pointer;
	padding:0;
}

#tcalControls th {
	border-collapse:collapse;
	border:0;
	line-height:25px;
	font-size:10px;
	text-align:center;
	font-family:Tahoma, Geneva, sans-serif;
	font-weight:700;
	white-space:nowrap;
	padding:0;
}

#tcalPrevYear {
	background-image:url(/img/prev_year.gif);
}

#tcalPrevMonth {
	background-image:url(/img/prev_mon.gif);
}

#tcalNextMonth {
	background-image:url(/img/next_mon.gif);
}

#tcalNextYear {
	background-image:url(/img/next_year.gif);
}

/* table containing week days header and calendar grid */
#tcalGrid {
	border-collapse:collapse;
	border:1px solid silver;
	width:100%;
}

#tcalGrid th {
	border:1px solid silver;
	border-collapse:collapse;
	text-align:center;
	font-family:Tahoma, Geneva, sans-serif;
	font-size:10px;
	background-color:gray;
	color:#FFF;
	padding:3px 0;
}

#tcalGrid td {
	border:0;
	border-collapse:collapse;
	text-align:center;
	font-family:Tahoma, Geneva, sans-serif;
	width:14%;
	font-size:11px;
	cursor:pointer;
	padding:2px 0;
}

#tcalGrid td.tcalOtherMonth {
	color:silver;
}

#tcalGrid td.tcalWeekend {
	background-color:#ACD6F5;
}

#tcalGrid td.tcalToday {
	border:1px solid red;
}

#tcalGrid td.tcalSelected {
	background-color:#FFB3BE;
}



#rules {	
	text-align:center;
	overflow:hidden;
	height:32px;
	line-height:30px;
	padding:0 0 6px;
}

#rules li {
	display:inline;
	padding:0;
	
}

#rules .center a {
	font-weight:100;
	font-size:11px;
	background:#eeeeee;
	border:1px solid #E1E1E1;
	color:#000000;
	text-decoration:none;
	margin:1px;
	padding:2px 5px;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	border: 2px solid #ccc;
}

#rules .center a:hover {
	background:#FFFFFF;
	border:1px solid #CADCEB;
}

#rules .center a.active {
	background:#FFFFFF;
	border:1px solid #666;
	color:#fff;
}

#pageJumpWindow {
	border:2px solid #ccc;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
	width:130px;
	height:40px;
	display:none;
	position:absolute;
	background-color:#FFFFFF;
	z-index:3;
	padding:5px;
	margin:0 auto;
}

#pageJumpWindow button  {
	padding:0;
	border:1px solid #ccc;
	-moz-border-radius: 4px; /* Firefox */
	-webkit-border-radius: 4px; /* Safari, Chrome */
	-khtml-border-radius: 4px; /* KHTML */
	border-radius: 4px; /* CSS3 */
}
#pageJumpWindow input  {
	height:19px;
	border:1px solid #ccc;
}

#pageJumpWindow h2 {
	font-size:10px;
	font-family:Tahoma, Geneva, sans-serif;
	margin:0 0 -10px;
}

#buttonJumpMenu {
	position:relative;
	width:1px;
	height:1px;
	margin:0 auto;
}

.err_message {
	background-color:red;
}

.info_message {
	background-color:#FDE302;
}
#info_message {
	color:#000000;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
	text-align:center;
	position:relative;
	border:1px solid #000;
	width:400px;
	min-height:60px;
	margin:0 auto;
	border:1px solid #ccc;
	-moz-border-radius: 4px; 
	-webkit-border-radius: 4px; 
	-khtml-border-radius: 4px; 
	border-radius: 4px; 	
}
#info_message div {
	padding: 5px;
	padding-left:20px;
}
#info_message div.err_message, 
#info_message div.info_message {
	-moz-border-radius: 4px; 
	-webkit-border-radius: 4px; 
	-khtml-border-radius: 4px; 
	border-radius: 4px; 
	margin:2px;	
	font-weight:bold;
	padding: 5px 0 0 0;
}
#info_message div img {
	position:absolute;
	left:5px;
	top:27px;	
}




/* Footer
-----------------------------------------------------------------------------*/
#footer {
	height: 20px;
	/* background: #BFF08E; */
	background-color: #F0F0F0;
	clear:both;
}



</style>
</head>

<body>
<div id=\"wrapper\">
  <div id=\"header\"> </div>
  <!-- #header-->
  
  <div id=\"content\">
    <ul id=\"menu\">
      <li><a href=\"$SELF_URL?index=11&NEW_USER=1\" title='Вспливающая подсказка'>$_ADD_USER</a></li>
      <li><a href=\"$SELF_URL\">$_SEARCH</a></li>
      <li><a href=\"$SELF_URL?SHOW_REPORT=users_total\">$_REPORTS</a></li>
    </ul>
    <div id=\"auth\"> <br />
      <p><strong>менеджер</strong>:<br />
        <strong><a href=\"#\">%ADMIN_NAME%</a></strong></p>
      <a href='$SELF_URL?index=1000' class='href_buttons'>$_LOGOUT</a>
    </div>
	%FILTER%
	%CONTENT%

  </div>
  
  <!-- #content-->
  
  <!-- <div id=\"footer\"></div> --> 
  <!-- #footer --> 
  
</div>
<!-- #wrapper -->

</body>
</html>