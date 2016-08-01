<div class='well well-sm'>
  <form method='get' name='HOTSPOT_REPORTS_FORM' class='form form-inline'>
    <input type='hidden' name='index' value='$index'/>

    <label for='FILTER'>_{FILTER}_</label>
    %FILTER_SELECT%

    <label for='DATE_START'>_{DATE}_</label>
    <input type='text' class='form-control tcal' name='DATE_START' id='DATE_START' value='%DATE_START%'/>

    <label for='DATE_END'>-</label>
    <input type='text' class='form-control tcal' name='DATE_END' id='DATE_END' value='%DATE_END%'/>

    <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
  </form>
</div>