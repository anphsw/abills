<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  %MAIN_USER_TPL%
  <input type=hidden name=UID value='%UID%'>

  <!-- General panel -->
  <div class='box box-theme box-big-form'>
    <div class='box-header with-border'><h3 class='box-title'>_{INFO}_</h3>
      <div class='box-tools pull-right'>
        %EDIT_BUTTON%
	    <button type='button' class='btn btn-default btn-xs' data-widget='collapse'>
		  <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='box-body'>
	  <div class='col-md-2 col-xs-2 no-padding'>
	    <img src=%PHOTO% class='img-responsive pull-left' alt=''>
	  </div>
      <div class='col-md-10 col-xs-10'>
	    <div class='input-group' style='margin-bottom: -1px;'>
	      <span class='input-group-addon'><span class='glyphicon glyphicon-user'></span></span>
          <input class='form-control' type='text' readonly value='%FIO%' placeholder='_{FIO}_'>
		  <span class='input-group-addon'>
                    <a href='$SELF_URL?UID=$FORM{UID}&get_index=msgs_admin&add_form=1&SEND_TYPE=1&header=1&full=1'
                       class='fa fa-envelope'></a>
                    </span>
	    </div>
	    <div class='input-group' style='margin-bottom: -1px;'>
	      <span class='input-group-addon'><span class='glyphicon glyphicon-home'></span></span>
          <input class='form-control' type='text' readonly value='%CITY%, %ADDRESS_FULL%' placeholder='_{ADDRESS}_'>
		  <span class='input-group-addon'>%MAP_BTN%</span>
		</div>
	    <div class='input-group' style='margin-bottom: -1px;'>
	      <span class='input-group-addon'><span class='glyphicon glyphicon-earphone'></span></span>
          <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{PHONE}_'>
		  <span class='input-group-addon'><a href='#' class='fa fa-list'></a></span>
	    </div>
        <div class='input-group'>
		  <span class='input-group-addon'><span class='glyphicon glyphicon-file'></span></span>
          <input value='%CONTRACT_ID%, %CONTRACT_DATE%' class='form-control' type='text' readonly style='text-transform: lowercase;'>
          <span class='input-group-addon'>%PRINT_CONTRACT%</span>
          <span class='input-group-addon'><a
		        title='Send' 
                href='$SELF_URL?qindex=15&UID=$FORM{UID}&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1'
                class='glyphicon glyphicon-envelope' target=_new>
                                        </a></span>
        </div>
      </div>
	  <div class='col-md-12 col-xs-12'>
	    <div class='input-group' style='margin-top: 5px;'>
	    <span class='input-group-addon'><span class='align-middle glyphicon glyphicon-exclamation-sign'></span></span>
	    <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='2' readonly>%COMMENTS%</textarea>
        </div>
      </div>
	</div>
	
	  <div class="box collapsed-box" style='margin-bottom: 0px; border-top-width: 1px;'>
        <div class="box-header with-border">
          <h3 class="box-title">_{EXTRA_ABBR}_. _{FIELDS}_</h3>
          <div class="box-tools pull-right">
            <button type="button" class="btn btn-default btn-xs" data-widget="collapse"><i class="fa fa-plus"></i>
            </button>
          </div>
        </div>
        <div class="box-body">
          %INFO_FIELDS%
        </div>
      </div>
	  
	  
  </div>
  
</form>
