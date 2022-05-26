<form class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
  
    <div class='card card-form card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>%TITLE%</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>  
        <div class='form-group row' %DATE_FIELD%>
          <label class='col-md-4 col-form-label text-md-right' for='FROM_DATE'>_{FROM}_ :</label>
          <div class='col-md-8'>
            <input class='form-control' data-provide='datepicker' data-date-format='yyyy-mm-dd' value='%FROM_DATE%' name='FROM_DATE'>
          </div>
          <label class='col-md-4 col-form-label text-md-right' for='TO_DATE'>_{TO}_ :</label>
          <div class='col-md-8'>
            <input class='form-control' data-provide='datepicker' data-date-format='yyyy-mm-dd' value='%TO_DATE%' name='TO_DATE'>
          </div>
        </div>
      
        <div class='form-group row' %IP_FIELD%>
          <label class='col-md-4 col-form-label text-md-right' for='IP_NUM'>IP :</label>
          <div class='col-md-8'>
            <input name='IP_NUM' value='%IP_NUM%' class='form-control' type='text'>
          </div>
        </div>
        
        <div class='form-group row' %IP_FIELD%>
          <label class='col-md-4 col-form-label text-md-right' for='CID'>CID :</label>
          <div class='col-md-8'>
            <input name='CID' value='%CID%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group row'>
          <label class='control-label col-md-4' for='LOGIN'>_{LOGIN}_ :</label>
          <div class='col-md-8'>
            <input name='LOGIN' value='%LOGIN%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='FIO'>_{FIO}_ :</label>
          <div class='col-md-8'>
            <input name='FIO' value='%FIO%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='COMPANY_NAME'>_{COMPANY}_ :</label>
          <div class='col-md-8'>
            <input name='COMPANY_NAME' value='%COMPANY_NAME%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='ADDRESS_FULL'>_{ADDRESS}_ :</label>
          <div class='col-md-8'>
            <input name='ADDRESS_FULL' value='%ADDRESS_FULL%' class='form-control' type='text'>
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type=submit name=search value='_{SEARCH}_' class='btn btn-primary'>
      </div>  
    </div>
 
</form>
