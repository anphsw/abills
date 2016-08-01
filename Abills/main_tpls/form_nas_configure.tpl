<script type='text/JavaScript'>
<!--
function Process(version, INTERNAL_SUBNET, wds, SSID){
	var commandbegin='%PARAM1%';
	var commandend = '%PARAM2%';

	if (version == 'v24') {
		var commandversion = '\\\\&version=v24';
  	} else if (version == 'coova') { 
		var commandversion = '\\\\&version=coova'; 
	} else if (version == 'freebsd') {
              var commandversion = '\\\\&version=freebsd';
              commandbegin = commandbegin.replace('wget -O', '/usr/bin/fetch -o')
        } else { 
		var commandversion = ''; 
	}

	
	
 	if (document.FORM_NAS.LAN_IP && document.FORM_NAS.LAN_IP.value != '' ) {
     var commandsubnet = '\\\\&LAN_IP='+document.FORM_NAS.LAN_IP.value;
  	 }
 	 else {
	  if (INTERNAL_SUBNET != '20') {
		  var commandsubnet = '\\\\&INTERNAL_SUBNET='+INTERNAL_SUBNET;
     } 
    else { 
		  var commandsubnet = ''; 
	   }
	 }


	if (wds != '0') {
		var commandwds = '\\\\&wds='+wds;
   } 
  else { 
		var commandwds = ''; 
	 }

	if (SSID != '') {
		var commandsid = '\\\\&SSID='+SSID;
   } 
  else {
		var commandsid = ''; 
	 }

	
	document.FORM_NAS.tbox.value = commandbegin+ commandversion + commandsid + commandsubnet + commandwds + commandend;
}

function data_change(field) {
          var check = true;
          var value = field.value; //get characters
          //check that all characters are digits, ., -, or \"\"
          for(var i=0;i < field.value.length; ++i)
          {
               var new_key = value.charAt(i); //cycle through characters
               if(((new_key < '0') || (new_key > '9')) &&
                    !(new_key == ''))
               {
                    check = false;
                    break;
               }
          }
          //apply appropriate colour based on value
          if(!check)
          {
               field.style.backgroundColor = 'red';
          }
          else
          {
               field.style.backgroundColor = 'white';
          }
     }

function disableEnterKey(e)
{
	 var key;
     if(window.event)
          key = window.event.keyCode;     //IE
     else
          key = e.which;     //firefox
     if(key == 13)
          return false;
     else
          return true;
}
//-->
</script>

<div class='panel panel-default panel-form'>
	<div class='panel-heading'>
		Hotspot _{SETTINGS}_
	</div>
	<div class='panel-body'>
		<input type=hidden name=wds id=wds class='form-control' value='0' />
		
		<div class='form-group'>
			<div class='col-xs-3'>
				<label for='version'>Firmware Version:</label>
			</div>
			<div class='col-xs-9'>        
			<select name='version' class='form-control' id='version'  onchange='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)' onKeyPress='return disableEnterKey(event)'>
				<option value='v24'>DD-WRT v24 NoKaid/Standard/Mega/Special</option>
				<option value='v23'>DD-WRT v23 Standard</option>
				<option value='coova'>CoovaAP</option>
				<option value='freebsd'>FreeBSD</option>
			</select>
			</div>
		</div>
		
		<div class='form-group'>
			<div class='col-xs-3'>
				<label for='INTERNAL_SUBNET'> Set router's internal IP to:</</label>
			</div>
			<div class='col-xs-2'>192.168.</div>
			<div class='col-xs-2'>
				<input name='INTERNAL_SUBNET' class='form-control' type='text'  id='INTERNAL_SUBNET' value='20' size='3' maxlength='3'  
				onchange='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)' onkeyup='data_change(this)'
				onsubmit='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)'  
				onKeyPress='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)' />
			</div>
			<div class='col-xs-1'>
				.1
			</div>
			<div class='col-xs-4'></div>
		</div>
			
		<!--
		<br>
		Custom Network: <input name=\"LAN_IP\" class=\"form-control\" type=\"text\"  id=\"LAN_IP\" value=\"\" size=\"16\" maxlength=\"16\"  
									onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\" 
									onsubmit=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\"  
									onKeyPress='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)' />
		-->
		
		<div class='form-group'>
			<div class='col-xs-3'>
				<label for='INTERNAL_SUBNET'> SSID:</label>
			</div>
			
			<div class='col-xs-9'>
				<input name='CUSTOM_SID' class='form-control' type='text'  id='CUSTOM_SID' value='wifi' size='18' maxlength='14'  
					onchange='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)' onkeyup=''
					onsubmit='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)'  
					onKeyPress='Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)' />
			</div>
		</div>
		
		<div class='form-group'>
		<div class='col-xs-1'></div>
			<div class='col-xs-10'>
			<textarea class='form-control' name=tbox rows=4 id=tbox cols=50>%CONFIGURE_DATE%</textarea>
			</div>
		<div class='col-xs-1'></div>
		</div>
	</div>
	<div class='form-group'>
		<a href='_{SELF_URL}_?index=$index&wrt_configure=1&nas=$FORM{NAS_ID}' class='btn btn-xs btn-default'>_{CONFIG}_</a>
	</div>
</div>
