<form class='form-horizontal' action='$SELF_URL' name='reseller_users' METHOD='POST'>
  <input type=hidden name='index' value='$index'>
  
  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h3 class="box-title">_{INFO}_</h3>
      <div class="box-tools pull-right">
      </div>
    </div>

    <div class="box-body">

      <div class='form-group'>
        <label class='control-label col-xs-3' for='LOGIN'>_{LOGIN}_</label>
        <div class='col-xs-9'>
          <input name='LOGIN' class='form-control' id='LOGIN' value='%LOGIN%'>
        </div>
      </div>  

      <div class='form-group'>
        <label class='control-label col-xs-3' for='FIO'>_{FIO}_</label>
        <div class='col-xs-9'>
          <input name='FIO' class='form-control' id='FIO' value='%FIO%'>
        </div>
      </div>

      <div class='form-group' >
        <label class='control-label col-xs-3' for='PHONE'>_{PHONE}_</label>
        <div class='col-xs-9'>
          <input id='PHONE' name='PHONE' value='%PHONE%' class='form-control' type='text'/>
        </div>
      </div>

      <div class='form-group' >
        <label class='control-label col-xs-3' for='TP_ID'>_{TARIF_PLAN}_</label>
        <div class='col-xs-9'>
          %TP_ADD%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='CID'>MAC (Modem):</label>
        <div class='col-md-9'>
          <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
        <div class='col-md-9' style='background: %STATUS_COLOR%;'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-sm-2 col-md-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-sm-10 col-md-9'>
           <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>

<script type='text/javascript'>
  var box = document.querySelector("[data-action=wizard]");
  var buttonOnCode = '<a onclick="wizardOn()"><i class="fa fa-eye"></i></a>';
  var buttonOffCode = '<a onclick="wizardOff()"><i class="fa fa-eye-slash"></i></a>';
  var boxTools = box.querySelector(".box-tools");
  boxTools.innerHTML += buttonOnCode;

  function wizardOn() {
    var elementsList = box.querySelectorAll("div.form-group");
    for (var i = 0; i < elementsList.length; ++i) {
      var btn = document.createElement('a');
      btn.className = 'wizBtn';
      btn.innerHTML = '<i class="fa fa-eye-slash"></i>';
      var coordTop = elementsList[i].offsetTop + 5;
      btn.style.cssText = "position:absolute; right:20px; top:" + coordTop + "px; color:red;"
      elementsList[i].appendChild(btn);
    }
    boxTools.innerHTML = buttonOffCode;
  }
  
  function wizardOff() {
    var elementsList = box.querySelectorAll("a.wizBtn");
    for (var i = 0; i < elementsList.length; ++i) {
      elementsList[i].remove();
    }
    boxTools.innerHTML = buttonOnCode;
  }

</script>