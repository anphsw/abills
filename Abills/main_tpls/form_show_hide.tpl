<div class='card collapsed-card card-big-form %PARAMS%'>
  <div class='card-header-custom with-border'>
    <h4 class='card-title'>%NAME% <b>%ADD_NAME%</b></h4>
    %BTN_ADDRESS_COPY%
    <div class='card-tools float-right'>
      %PRE_ADDRESS% %NEXT_ADDRESS%
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-%BUTTON_ICON%'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    %CONTENT%
  </div>
</div>


<style>
  .card-header-custom {
    background-color: transparent;
    border-bottom: 1px solid rgba(0, 0, 0, .125);
    padding: .75rem .60rem;
    position: relative;
    border-top-left-radius: .25rem;
    border-top-right-radius: .25rem;
    margin-left: 10px;
  }
</style>