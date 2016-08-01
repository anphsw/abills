  <div class='form-group'>
  	<label class='col-md-12 control-label bg-primary'>DHCP</label>
  </div>			
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{HOSTS_HOSTNAME}_:</label>
  	<div class='col-md-9'><input class='form-control' type=text name=HOSTNAME value='%HOSTNAME%'></div>
  </div>			
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{HOSTS_NETWORKS}_:</label>
  	<div class='col-md-9'>%NETWORKS_SEL%</div>
  </div>
  <div class='form-group'>
  	<label class='col-md-3 control-label'>IP:</label>
  	<div class='col-md-5'>
  		<input class='form-control' type=text name=IP value='%IP%' > 
  	</div>
  	<div class='col-md-1'>
  			<input type=checkbox name=AUTO_IP value=1>
  	</div>
  		<label class='col-md-3 text-left'>
  			_{AUTO}_
  		</label>
  </div>			
  <div class='form-group'>
  	<label class='col-md-3 control-label'>_{HOSTS_MAC}_:<BR>(00:00:00:00:00:00)</label>
  	<div class='col-md-9'><input class='form-control' type=text name=MAC value='%MAC%'></div>
  </div> 