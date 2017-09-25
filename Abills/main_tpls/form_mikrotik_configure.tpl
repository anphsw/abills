<form method='post' action='$SELF_URL' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'/>
  <input type='hidden' name='CONNECTION_TYPE' value='$FORM{CONNECTION_TYPE}'/>
  <input type='hidden' name='mikrotik_configure' value='1'/>
  <input type='hidden' name='subf' value=''/>

  <div class='box box-theme box-form'>
    <div class='box-header with-border'>
      <h4 class='box-title'>_{CONFIGURATION}_ : $FORM{CONNECTION_TYPE}</h4>
      <div class="pull-right">%CLEAN_BTN%</div>
    </div>
    <div class='box-body'>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='RADIUS_IP_ID'>RADIUS IP</label>
        <div class='col-md-9'>
          %RADIUS_IP_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='DNS_ID'>DNS (,)</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%DNS%' name='DNS' id='DNS_ID'/>
        </div>
      </div>

<!--
      <div class='form-group'>
        <label class='control-label col-md-3' for='CLIENTS_POOL_ID'>IP Pool</label>
        <div class='col-md-9'>
          %IP_POOL_SELECT%
        </div>
      </div>
-->

      <div class='checkbox text-center'>
        <label>
          <input type='checkbox' data-return='1' data-checked='%USE_NAT%' value='1' name='USE_NAT' id='USE_NAT_ID'/>
          <strong>NAT (Masquerade)</strong>
        </label>
      </div>

      <hr/>

      <!--extra-->
      %EXTRA_INPUTS%
      <!--extra-->


    </div>

    <div class='box-footer text-center'>
        <input type='submit' class='btn btn-primary' name='action' value='_{APPLY}_'>
    </div>
  </div>
</form>