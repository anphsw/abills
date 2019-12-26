<!DOCTYPE html>
<html>
  <head>
    <title>Tcpdump</title>
    <script>
      var eventSource = new EventSource('%URL%');
      eventSource.onopen = function(e) {
        console.log("Open connection");
      };

      eventSource.onerror = function(e) {
        if (this.readyState == EventSource.CONNECTING) {
          console.log("Connection error, reconnecting");
        } else {
          console.log("Error: " + this.readyState);
        }
      };

      eventSource.onmessage = function(e) {
        document.getElementById('tcpdump_pre').append(e.data+"\n");
	window.scrollTo({left: 0, top: document.body.scrollHeight, behavior: 'smooth'});
      };
    </script>
  </head>
  <body>
    <pre id='tcpdump_pre'></pre>
  </body>
</html>
