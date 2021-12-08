<div class='container'>
  <div class='row align-items-start p-1'>
    <div class='col-md-5 align-self-center %DISPLAY_BLOCKS% %BLOCKS_COL%'>
      <div class='form-group row align-items-start'>
        <div class='col-md-5 card-info border-55 pl-2 pt-1'>
          <div class='row m-1'>
            <h4 class='h4 mb-0'>_{NEW_TICKETS}_</h4>
          </div>
          <div class='row mh-auto ml-2 mb-2'>
            <small class='text-muted text-bold'>%ADMIN%</small>
          </div>
          <div class='row mh-50 m-1'>
            <h1 class='text-warning text-bold title'>%TOTAL_TICKETS%</h1>
          </div>
        </div>
        <div class='col-md-2' style='max-width: 1rem !important;'></div>
        <div class='col-md-5 card-info border-55 pl-2 pt-1'>
          <div class='row m-1'>
            <h4 class='h4 mb-0'>_{REPLYS}_</h4>
          </div>
          <div class='row mh-auto ml-2 mb-2'>
            <small class='text-muted text-bold'>%ADMIN%</small>
          </div>
          <div class='row mh-50 m-1'>
            <h1 class='text-danger text-bold title'>%TOTAL_REPLIES%</h1>
          </div>
        </div>
      </div>
      <div class='row align-items-start'>
        <div class='col-md-5 card-info border-55 pl-2 pt-1'>
          <div class='row m-1'>
            <h4 class='h4 mb-0'>_{CLOSED}_</h4>
          </div>
          <div class='row mh-auto ml-2 mb-2'>
            <small class='text-muted text-bold'>%ADMIN%</small>
          </div>
          <div class='row mh-50 m-1'>
            <h1 class='text-indigo text-bold title'>%CLOSED_TICKETS%</h1>
          </div>
        </div>
        <div class='col-md-2' style='max-width: 1rem !important;'></div>
        <div class='col-md-5 card-info border-55 pl-2 pt-1'>
          <div class='row m-1'>
            <h4 class='h4 mb-0'>_{AVERAGE_RATING}_</h4>
          </div>
          <div class='h4 text-center mt-3'>
            %RATING%
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-7 border-55 bg-white %DISPLAY_CHART% %CHART_COL%'>
      %CHART%
    </div>
  </div>
</div>

<style>
	.card-info {
		min-height: 9rem;
		background-color: white;
	}

  .border-55 {
		border-radius: 0.55rem !important;
  }

  .title {
		font-size: 3.5rem !important;
  }
</style>