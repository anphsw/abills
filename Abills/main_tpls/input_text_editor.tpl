<link rel='stylesheet' href='/styles/default/plugins/quilljs/quill.snow.css'/>
<script src='/styles/default/plugins/quilljs/quill.min.js'></script>

<div>
  <div id="TEXT_EDITOR">
    %TEXT%
  </div>
</div>

<script>

  let toolbar = [
    ['bold', 'italic', 'underline', 'link'],
  ]

  if ('%TOOLBAR_CONF%') {
    toolbar = JSON.parse('%TOOLBAR_CONF%')
    console.log(toolbar)
    console.log('%TOOLBAR_CONF%')
  }

  const quill = new Quill('#TEXT_EDITOR', {
    theme: 'snow',
    modules: {
      toolbar: toolbar
    },
    formats: ['bold', 'italic', 'underline', 'link', 'list']
  });

  document.getElementById('%FORM_ID%').addEventListener('submit', function () {
    document.getElementById('%INPUT_ID%').value = quill.root.innerHTML;
  });

</script>
