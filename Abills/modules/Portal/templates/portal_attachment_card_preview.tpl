<div attach-id='%ATTACH_ID%' class='col-md-4 mb-3 cursor-pointer'>
  <div class='card card-primary abon-card'>
    <div class='card-header text-center border-0'>
      <h3 class='card-title'>%FILENAME%</h3>
      <div class='card-tools'>
        <i class='far fa-calendar'></i>
        %UPLOADED_AT%
      </div>
    </div>
    <div class='card-body p-0 m-0 text-center'>
      <img src='%LINK%' alt='Portal' style='max-width: 100%'>
    </div>
  </div>
  <script>
    // Just isolate scope for multicards
    (function() {
      const portalCard = jQuery("[attach-id='%ATTACH_ID%']");
      portalCard.on('click', function () {
        var portalEditor = document.querySelector('.CodeMirror').CodeMirror;

        let picture = portalCard.find('img').first().prop('outerHTML');

        let value = portalEditor.getValue();
        value = value + picture + '\n';

        portalEditor.setValue(value);
        jQuery('#CurrentOpenedModal').modal('hide');
      });

      portalCard.on('mouseenter', function () {
        portalCard.find('.card').toggleClass('card-success');
      });

      portalCard.on('mouseleave', function () {
        portalCard.find('.card').toggleClass('card-success');
      });
    })();
  </script>
</div>
