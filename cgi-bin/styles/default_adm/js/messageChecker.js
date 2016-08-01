/**
 * Created by Anykey on 22.02.2016.
 *
 *   AJAX based new message checker
 *   Calls cross_modules in ABillS
 *
 */

var AMessageChecker = (function () {
  
  
  var self             = {};
  
  self.last_id = 0;
  
  self.intervalHandler = null;
  self.extensions      = {
    MESSAGE: function (event_data) {
      showMessage(parseMessage(event_data));
      updateBadge(events.length);
    },
    DEFAULT: function (event_data) {
      console.log("[ AMessageChecker ] Got unknown event type : " + event_data.TYPE);
    }
  };
  
  function start(parameters) {
    // accept parameters
    $.extend(self, parameters);
    if (!self.disabled) {
      setSoundsDisabled(self.soundsDisabled);
      makeRequest();
      self.intervalHandler = setInterval(makeRequest, self.interval);
    }
  }
  
  function stop() {
    if (self.intervalHandler !== null) {
      clearInterval(self.intervalHandler);
    }
  }
  
  function makeRequest() {
    $.getJSON(self.link + '&AJAX=1', '', function (events) {
      
      if (events.length > 0) {
        
        $.each(events, function (i, event) {
          processData(event, events.length);
        });
      }
      
    }).fail(function () {
      console.log("[ AMessageChecker ] Got non-JSON response");
    });
  }
  
  function processData(event_data) {
    var checked_type = typeof (self.extensions[event_data.TYPE]);
    if (checked_type === 'function') {
      self.extensions[event_data.TYPE](event_data);
    }
    else {
      self.extensions['DEFAULT'](event_data);
    }
    
    self.last_id++;
  }
  
  function extend(extension) {
    var extension_message_type = extension.TYPE;
    var extension_cb           = extension.CALLBACK;
    
    var checked_type = typeof (self.extensions[extension_message_type]);
    if (checked_type !== 'undefined') {
      console.warn('[ AMessageChecker ] Extension has been already registered : ' + extension_message_type);
      return false;
    }
    else {
      self.extensions[extension_message_type] = extension_cb;
      if (typeof  (extension_cb) !== 'function') {
        console.warn('[ AMessageChecker ] extension.CALLBACK should be a function');
        return false;
      }
      console.log('[ AMessageChecker ] Successfully registered ' + extension_message_type);
    }
  }
  
  function updateBadge(count) {
    if (typeof CLIENT_INTERFACE !== 'undefined') {
      var $badgeHolder = $('#msgs_user').find('span');
      if ($badgeHolder.length > 0) {
        var text = $badgeHolder.text();
        
        var hasNumber = text.match("[(]([0-9]{1,})[)]");
        
        if (hasNumber != null) {
          text = text.substr(0, hasNumber.index);
        }
        
        $badgeHolder.text(text + ' (' + count + ')');
        
      }
    }
  }
  
  function parseMessage(data) {
    var message = {};
    
    //prevent undefined errors
    data.CLIENT = data['CLIENT'] || {};
    
    message.uid   = data.CLIENT['UID'] || '';
    message.login = data.CLIENT['LOGIN'] || '';
    
    message.caption = data['TITLE'] || '';
    message.text    = data['TEXT'] || '';
    message.num     = data['MSGS_ID'] || '';
    message.extra   = data['EXTRA'] || '';
    
    message.id = data['ID'] || 0;
    message.group_id = data['GROUP_ID'] || 0;
    
    if (message.text.length > 60) {
      message.text = message.text.substr(0, 60) + "...";
    }
    return message;
  }
  
  function showMessage(message) {
    
    //var messageText = "<b>" + message.num + "</b> " + message.text;
    var messageText = message.text;
    
    if (message.extra != '') {
      message.caption = "<a href='" + message.extra + "'>" + message.caption + '</a>';
    }
    
    if (message.uid) {
      messageText = "<a class='link_button' href='/admin/index.cgi?index=15&UID=" + message.uid + "'>" + message.login + "</a>&nbsp" + messageText;
    }
    
    QBinfo("<b>" + message.caption + "</b>",
        messageText,
        message.group_id,
        message.id
    );
    
  }
  
  function unsubscribe(qb_id, group_id) {
    hideQBinfo(qb_id);
    var url = '?AJAX=1&get_index=events_unsubscribe&GROUP_ID=' + group_id;
    
    $.get(url,'', function (data) {
      (new ATooltip).display('<h3>Unsubscribed from group ' + group_id + '</h3>', 2000);
    });
  }
  
  function seenMessage(qb_id, event_id) {
    hideQBinfo(qb_id);
    var url = '?get_index=events_main&header=2&STATE_ID=2&change=1&ID=' + event_id;
  
    $.get(url,'');
  }
  
  
  return {
    start      : start,
    stop       : stop,
    extend     : extend,
    processData: processData,
    unsubscribe: unsubscribe,
    seenMessage: seenMessage
  }
})();
