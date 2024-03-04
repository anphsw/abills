<script>
function setDefaultEndDate(checkbox) {
  let id = checkbox.value;
  let checked = checkbox.checked;
  let end_date_element = jQuery("[data-id="+id+"]");

  if (checked){
    if (!end_date_element.val()){
      jQuery("[data-id="+id+"]").val('0000-00-00');
    }
  }
  else {
    jQuery("[data-id="+id+"]").val('');
  }
}
</script>