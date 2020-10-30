<script>
    jQuery(document).ready(() => {
        jQuery('[name=PAYSYS_GROUPS_SETTINGS]').submit(function(e) {
            e.preventDefault()

            const formData = new FormData()
            const index = jQuery(this).find('input[name=index]').first().val()

            formData.append('index', index)
            formData.append('add_settings', 'Сохранить')
            formData.append('GROUPS_USER_PORTAL_TABLE__length', '10')

            const isChecked = jQuery(this).find('input:checked').get()
            const isNotChecked = jQuery(this).find('input[id^=SETTINGS]').not(':checked').get()

            for(const checkbox in isChecked){
                formData.append(isChecked[checkbox].id, '1')
             }
            for(const checkbox in isNotChecked){
                formData.append(isNotChecked[checkbox].id, '0')
            }

            fetch(this.action, {
                body: formData,
                method: "POST"
            }).then()
        })
    })
</script>