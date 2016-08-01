'use strict';

var socket_state = {
  CONNECTING: 0,
  OPEN      : 1,
  CLOSING   : 2,
  CLOSED    : 3
};

var counter                        = 0;
var try_to_connect_again           = true;
var is_in_connection_retrieval     = false;
var unsucsessfull_connection_tries = 0;

var ws = null;
$(function () {
      var socket_link = document['WEBSOCKET_URL'];
      console.log(socket_link);
      if (socket_link) {
        ws = connect_to_socket(socket_link);
      }
      else {
        console.warn('[ WebSocket ] Will not connect to socket without $conf{WEBSOCKET_URL}');
      }
    }
);

function request_close_socket() {
  ws.send('{ "type" :  "close_request"}');
  try_to_connect_again = false;
}


function try_to_connect_again_in_(seconds) {
  
  ws = new WebSocket(document['WEBSOCKET_URL']);
  
  ws.onopen = function () {
    ws = setup_socket(ws);
  };
  
  ws.onerror = function () {
    unsucsessfull_connection_tries++;
    if (unsucsessfull_connection_tries > 10) {
      console.log('[ WebSocket ] Giving up after %i tries');
      return;
    }
    console.log('Will try again in %i seconds', seconds);
    setTimeout(function () {
      try_to_connect_again_in_(seconds * 2)
    }, seconds * 1000);
  };
  
  if (ws !== null && ws.readyState == socket_state['OPEN']) {
    ws = setup_socket(ws);
  }
  
  
}

function setup_socket(websocket) {
  
  websocket.onopen = function () {
    console.log('[ WebSocket ] Connection established');
    unsucsessfull_connection_tries = 0;
    is_in_connection_retrieval     = false;
  };
  
  websocket.onclose = function () {
    console.log('[ WebSocket ] Connection closed');
    if (!is_in_connection_retrieval) {
      is_in_connection_retrieval = true;
      try_to_connect_again_in_(3);
    }
  };
  
  websocket.onerror = function () {
    console.log('[ WebSocket ] Connection failed');
    if (!is_in_connection_retrieval) {
      is_in_connection_retrieval = true;
      try_to_connect_again_in_(3);
    }
  };
  
  websocket.onmessage = on_message;
  
  return websocket;
}

function connect_to_socket(url) {
  
  ws = new WebSocket(url);
  
  setup_socket(ws);
  return ws;
}

function on_message(event) {
  var message = null;
  try {
    message = JSON.parse(event.data);
  }
  catch (Error) {
    console.log("[ WebSocket ] Fail to parse JSON: " + event.data);
    return;
  }
  
  switch (message.TYPE) {
    case 'close':

      ws.close(1000); // Normal
      if (message.REASON) {
        console.log("[ WebSocket ] Connection closed by server : " + message.REASON);
      }
      break;
    case 'PING':
      ws.send('{"TYPE" : "PONG"}');
      break;
    case 'PONG':
      console.warn("I should not receive this :",  message);
      break;
    default:
      AMessageChecker.processData(message);
      ws.send('{"TYPE":"RESPONCE","RESPONCE":"RECEIVED"}');
      break;
  }
  
}

document.onunload = function () {
  'use strict';
  try_to_connect_again = false;
};