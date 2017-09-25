</form>


<style type="text/css">
  
  .custom-send {height: 5.25em}
</style>


<div id='s%ID%' class='tab-pane fade %ACTIVE%'>
<form action='$SELF_URL' method='POST' id='FORM%ID%'> 
<input type='hidden' name='index' value='%INDEX%'>
<input type='hidden' name='LEAD_ID' value='%LEAD_ID%'>
<input type='hidden' name='STEP_ID' value='%ID%'>
<ul class='timeline'>

%TIMELINE_ITEMS%

</ul>

<div class='form-group'>
  <div class='input-group'>
    <textarea class='form-control custom-control' rows='3' style='resize:none' name='MESSAGE'></textarea>     
    <span class='input-group-btn'>
    <input form='FORM%ID%' type='submit' class='btn btn-primary custom-send' name='add_message' value='_{SEND}_'></input>
    </span>
</div>
</div>

</div>
