<script>

  function setExpireDate(checkbox) {
  let id = checkbox.value;
  let checked = checkbox.checked;
  let end_date_element = jQuery("[data-id="+id+"]");
  let expire_days = Number(jQuery("[data-exp-days-id="+id+"]").val());
  let expire_date = '0000-00-00';

  if( expire_days > 0 ){
    let today = new Date();
    today.setDate(today.getDate() + expire_days);
    let year = today.getFullYear();
    let month = (today.getMonth() + 1).toString().padStart(2, '0');
    let day = today.getDate().toString().padStart(2, '0');
    expire_date = year + '-' + month + '-' + day;
  }

  if (checked){
    if (!end_date_element.val()){
      jQuery("[data-id="+id+"]").val(expire_date);
    }
  }
  else {
    jQuery("[data-id="+id+"]").val('');
  }
}
</script>