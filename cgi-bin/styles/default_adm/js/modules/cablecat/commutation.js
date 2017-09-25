/**
 * Created by Anykey on 10.11.2016.
 */
/**
 * Created by Anykey on 13.11.2015.
 *
 */
'use strict';

var ACommutation         = null;
var ACommutationControls = null;

var ACableManager = null;

var SCHEME_OPTIONS = null;
var paper          = null;

var CABLE    = 'CABLE';
var SPLITTER = 'SPLITTER';
var FIBER    = 'FIBER';

var CABLES            = document['CABLES'] || [];
var LINKS             = document['LINKS'] || [];
var COMMUTATION_LINKS = document['COMMUTATION_LINKS'] || [];
var SPLITTERS         = document['SPLITTERS'] || [];
var EQUIPMENT         = document['EQUIPMENT'] || [];
//var options = document['OPTIONS'] || {};

var DEFAULT_SCHEME_OPTIONS = {
  CABLE_SHELL_HEIGHT: 30,
  CABLE_WIDTH_MARGIN: 6,
  
  MODULE_HEIGHT: 5,
  FIBER_WIDTH  : 4,
  FIBER_HEIGHT : 25,
  FIBER_MARGIN : 6,
  
  ROUTER_WIDTH        : 25,
  ROUTER_HEIGHT_MARGIN: 5,
  OPPOSITE_SHIFT      : 3
};

$(function () {
  
  //Instantiate classes
  ACommutationControls = new CommutationControlsAbstract();
  
  cablecatMain();
  var $body = $('body');
  $body.on('expanded.pushMenu collapsed.pushMenu', function () {
    setTimeout(redraw, 400);
  });
  jQuery(window).on('resize', redraw);
});

function redraw() {
  paper = null;
  $('#drawCanvas').empty();
  cablecatMain();
}

function initOptions(options) {
  
  var scale = options['scale'] || 1;
  
  // Width of page container
  var max_width  = $('#drawCanvas').parent().width();
  var max_height = $('#content-wrapper').height();
  
  // First height and width are equal to minimal values
  var width  = options.minWidth || max_width;
  var height = options.minHeight || max_height;
  
  //console.log('init: width', width, 'height', height,
  //    'scale', scale,
  //    'max_width : ', max_width,
  //    'max_height : ', max_height
  //);
  
  scale = ((width) * scale > max_width)
      ? (Math.ceil(((width / max_width) * 100) / 100))
      : scale;
  
  //width = (scale != options['scale']) ? width * scale : max_width;
  width = max_width;
  height *= (options.minHeight) ? scale : 1;
  
  //console.log('result: width', width, 'height', height, 'scale', scale);
  
  SCHEME_OPTIONS = {
    SCALE: scale,
    
    CABLE_SHELL_HEIGHT: DEFAULT_SCHEME_OPTIONS['CABLE_SHELL_HEIGHT'] * scale,
    CABLE_WIDTH_MARGIN: DEFAULT_SCHEME_OPTIONS['CABLE_WIDTH_MARGIN'] * scale,
    CABLE_COLOR       : DEFAULT_SCHEME_OPTIONS['CABLE_COLOR'],
    
    MODULE_HEIGHT: DEFAULT_SCHEME_OPTIONS['MODULE_HEIGHT'] * scale,
    
    FIBER_WIDTH   : DEFAULT_SCHEME_OPTIONS['FIBER_WIDTH'] * scale,
    FIBER_HEIGHT  : DEFAULT_SCHEME_OPTIONS['FIBER_HEIGHT'] * scale,
    FIBER_MARGIN  : DEFAULT_SCHEME_OPTIONS['FIBER_MARGIN'] * scale,
    OPPOSITE_SHIFT: DEFAULT_SCHEME_OPTIONS['OPPOSITE_SHIFT'] * scale,
    
    ROUTER_WIDTH        : DEFAULT_SCHEME_OPTIONS['ROUTER_WIDTH'] * scale,
    ROUTER_HEIGHT_MARGIN: DEFAULT_SCHEME_OPTIONS['ROUTER_HEIGHT_MARGIN'] * scale,
    ROUTER_COLOR        : DEFAULT_SCHEME_OPTIONS['ROUTER_COLOR'],
    
    FONT      : 'Roboto',
    FONT_SIZE : 8,
    FONT_COLOR: 'black'
  };
  
  SCHEME_OPTIONS.CABLE_FULL_HEIGHT = SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + SCHEME_OPTIONS.MODULE_HEIGHT + SCHEME_OPTIONS.FIBER_HEIGHT;
  SCHEME_OPTIONS.FIBER_FULL_WIDTH  = SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN;
  
  SCHEME_OPTIONS.CANVAS_WIDTH  = width;
  SCHEME_OPTIONS.CANVAS_HEIGHT = height;
  
  // Should always match page width
  SCHEME_OPTIONS.CONTAINER_WIDTH  = max_width;
  SCHEME_OPTIONS.CONTAINER_HEIGHT = height;
  
  SCHEME_OPTIONS.CANVAS_Y_CENTER = SCHEME_OPTIONS.CANVAS_HEIGHT / 2;
  SCHEME_OPTIONS.CANVAS_X_CENTER = SCHEME_OPTIONS.CANVAS_WIDTH / 2;
  SCHEME_OPTIONS.ZOOM            = (scale < 1.5);
}

function cablecatMain() {
  
  ACableManager = new CableManager(CABLES);
  
  initOptions({
    scale    : 2,
    minHeight: ACableManager.min_height,
    minWidth : ACableManager.min_width
  });
  paper = new Raphael('drawCanvas', SCHEME_OPTIONS['CANVAS_WIDTH'], SCHEME_OPTIONS['CANVAS_HEIGHT']);
  $('#drawCanvas').css({
    width : SCHEME_OPTIONS['CONTAINER_WIDTH'],
    height: SCHEME_OPTIONS['CONTAINER_HEIGHT']
  });
  
  if (SCHEME_OPTIONS['ZOOM']) {
    initZoom(paper);
  }
  
  drawGrid(25, 0.1);
  
  ACommutation = new Commutation({});
  
  // Render elements
  $.each(ACableManager.getCables(), function (i, cable) {
    cable.calculateSizes();
    cable.render();
    ACommutation.addElement(CABLE, cable);
  });
  
  $.each(SPLITTERS, function (i, e) {
    var splitter = new Splitter(e);
    splitter.render();
    
    ACommutation.addElement(SPLITTER, {
      id    : splitter.id,
      // Concating two sides in one array ( in result have one array with pointers to fibers in both in and out)
      fibers: splitter.fibers_in.concat(splitter.fibers_out),
      origin: splitter
    });
  });
  
  $.each(EQUIPMENT, function (i, e) {
    var equipment = new Equipment(e);
    equipment.render();
    
    ACommutation.addElement('EQUIPMENT', {
      id    : equipment.id,
      fibers: equipment.fibers,
      origin: equipment
    });
    
  });
  
  
  for (var i = 0; i < LINKS.length; i++) {
    
    ACommutation.addLink($.extend(LINKS[i], {
      element_id_1: CABLE + '_' + LINKS[i].cable_id_1,
      element_id_2: CABLE + '_' + LINKS[i].cable_id_2
    }));
    
  }
  
  for (var i = 0; i < COMMUTATION_LINKS.length; i++) {
    
    //if (COMMUTATION_LINKS[i].id === '9') console.log(COMMUTATION_LINKS[i]);
    
    
    ACommutation.addLink($.extend(COMMUTATION_LINKS[i], {
      element_id_1: COMMUTATION_LINKS[i].element_1_type + '_' + COMMUTATION_LINKS[i].element_1_id,
      element_id_2: COMMUTATION_LINKS[i].element_2_type + '_' + COMMUTATION_LINKS[i].element_2_id
    }));
    
  }
  
  
  Events.on('Commutation.rendered', initContextMenus);
  
  ACommutation.render();
}

function CableManager(cablesArr) {
  this.cables             = [];
  this.cable_by_positions = {
    left  : [],
    right : [],
    top   : [],
    bottom: []
  };
  
  for (var i = 0; i < cablesArr.length; i++) {
    var cableRaw = cablesArr[i];
    
    var cable = new Cable(cableRaw);
    
    // Simple round fill
    cable.position = this.cable_positions_arr[i % this.cable_positions_arr.length];
    // TODO: check desired position
    
    cableRaw.meta.position = cable.position;
    cableRaw.meta.vertical = (cable.position === 'top' || cable.position === 'bottom');
    
    // Cable should know how many cables are on this side
    cableRaw.meta.number = this.cable_by_positions[cable.position].length;
    
    this.cables[this.cables.length] = cable;
    this.cable_by_positions[cable.position].push(cable);
  }
  
  var edge_margin = DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + DEFAULT_SCHEME_OPTIONS.MODULE_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT;
  
  //  - get max needed width
  var max_top_width    = this.cable_by_positions['top'].reduce(this.getSideWidth, 0);
  var max_bottom_width = this.cable_by_positions['bottom'].reduce(this.getSideWidth, 0);
  this.min_width       = Math.max(max_top_width, max_bottom_width) + edge_margin * 3;
  
  // - and height
  var max_left_width  = this.cable_by_positions['left'].reduce(this.getSideWidth, 0);
  var max_right_width = this.cable_by_positions['right'].reduce(this.getSideWidth, 0);
  this.min_height     = Math.max(max_left_width, max_right_width) + edge_margin * 3;
  
}

CableManager.prototype = {
  cable_positions_arr: [
    'left',
    'right',
    'top'
    //'bottom'
  ],
  
  getCables       : function () {
    return this.cables;
  },
  getCableForFiber: function (fiberId) {
    //console.log(fiberId);
    return fibers[fiberId].cable;
  },
  getCableById    : function (cableId) {
    return cableHolder[cableId] || console.log(cableHolder, cableId);
  },
  removeCable     : function (cable_id) {
    ACommutationControls.removeCableFromScheme(cable_id);
  },
  getSideWidth    : function (width_before, next_cable) {
    return width_before + next_cable.absolute_width + DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT;
  }
};

function Commutation(options) {}

Commutation.prototype = {
  element_for_fiber       : {},
  fiber_by_id             : {},
  elements_by_id          : {},
  elements                : [],
  rawLinks                : [],
  links_by_id             : {},
  links_for_element       : {},
  edgeCircles             : [],
  addElement              : function (type, elementObj) {
    var new_element = new ElementWithFibers(type, elementObj);
    
    if (typeof (new_element.id) === 'undefined') {
      console.warn('Element created without id');
      return false;
    }
    
    for (var i = 0; i < new_element.fibers.length; i++) {
      var fiber_id = new_element.id + '_' + (i + 1);
      
      this.fiber_by_id[fiber_id]       = new_element.fibers[i];
      this.element_for_fiber[fiber_id] = new_element;
      
      this.addFiberMeta(new_element, new_element.fibers[i], i + 1);
    }
    
    // Saving origin
    new_element.origin                  = elementObj.origin || elementObj;
    this.elements_by_id[new_element.id] = new_element;
    
    this.elements.push(new_element);
  },
  addFiberMeta            : function (element, fiber, num) {
    fiber._meta = {
      id  : element.id + '_' + (num),
      name: element.id + '_' + (num),
      num : num
    };
  },
  render                  : function () {
    for (var i = 0; i < this.rawLinks.length; i++) {
      if (typeof this.rawLinks[i] === 'undefined') continue;
      this.renderLink(this.rawLinks[i]);
    }
    Events.emit('Commutation.rendered');
  },
  renderLink              : function (linkObj) {
    var start_id = linkObj.fiber_id_1;
    var end_id   = linkObj.fiber_id_2;
    
    var start_present = typeof (this.fiber_by_id[start_id]) !== 'undefined';
    var end_present   = typeof (this.fiber_by_id[end_id]) !== 'undefined';
    
    if (start_present && end_present) {
      // Do not change color when connecting to splitter
      if (linkObj.element_2.type === SPLITTER) {
        linkObj.color = this.getFiberById(start_id).color;
      }
      
      var link                     = new Link(linkObj);
      this.links_by_id[linkObj.id] = link;
      
      this.saveLinkForElement(linkObj.element_id_1, link);
      this.saveLinkForElement(linkObj.element_id_2, link);
      
      link.render();
    }
    else {
      // Assuming at least one of them is present
      if (start_present || end_present) {
        var present_fiber_id = (start_present)
            ? start_id
            : end_id;
        
        this.fiber_by_id[present_fiber_id].connected = true;
        
        this.setFiberConnected(present_fiber_id, linkObj['commutation_id']);
      }
      else {
        console.log('Got links that not exists in all elements.' +
            ' This may happen if somebody changed cable type after commutation was created', start_id, end_id);
        // TODO: ask and delete
      }
    }
  },
  saveLinkForElement      : function (element_id, link) {
    if (typeof (this.links_for_element[element_id]) !== 'undefined') {
      this.links_for_element[element_id].push(link);
    }
    else {
      this.links_for_element[element_id] = [link];
    }
  },
  getFiberById            : function (fiber_id) {
    return this.fiber_by_id[fiber_id];
  },
  getFiberEdge            : function (fiber_id) {
    return this.fiber_by_id[fiber_id].rendered.edge;
  },
  getElement              : function (element_id) {
    return this.elements_by_id[element_id];
  },
  getElementByTypeAndId   : function (type, id) {
    return this.getElement(type + '_' + id);
  },
  getElementForFiber      : function (fiber_id) {
    return this.element_for_fiber[fiber_id];
  },
  removeElementByTypeAndId: function (type, id) {
    var element = this.getElementByTypeAndId(type, id);
    if (!element) {
      alert('Inner error. Cant find element for ' + type + ' and id ' + id);
      return;
    }
    
    $.post('/admin/index.cgi', {
      qindex        : INDEX,
      header        : 2,
      json          : 1,
      COMMUTATION_ID: document['COMMUTATION_ID'],
      entity        : type.toUpperCase(),
      operation     : 'DELETE',
      ID            : id,
    }, function (data) {
      if (data.MESSAGE) {
        aTooltip.displayMessage(data.MESSAGE, 2000);
        location.reload();
      }
      else {
        alert('There was error while deleting');
      }
    });
    
    console.log(element);
  },
  
  getLinkById                : function (link_id) {
    return this.links_by_id[link_id];
  },
  addLink                    : function (linkObj, renderNow) {
    if (typeof linkObj === 'undefined' || !linkObj) {
      alert('linkObj is not defined');
      console.warn(linkObj);
    }
    
    // Get elements for fibers
    var element1 = this.elements_by_id[linkObj['element_id_1']];
    var element2 = this.elements_by_id[linkObj['element_id_2']];
    
    if (!element1 || !element2) {
      return false;
    }
    
    var linkObj = $.extend(linkObj, {
      element_1: element1,
      element_2: element2
    });
    
    if (typeof linkObj.fiber_id_1 === 'undefined') {
      linkObj.fiber_id_1 = linkObj['element_id_1'] + '_' + linkObj.fiber_num_1;
      linkObj.fiber_id_2 = linkObj['element_id_2'] + '_' + linkObj.fiber_num_2;
    }
    
    this.setFiberConnected(linkObj.fiber_id_1);
    this.setFiberConnected(linkObj.fiber_id_2);
    
    // Save new link inside
    this.rawLinks.push(linkObj);
    
    // call linkAdded on elements
    if (typeof (element1['linkAdded']) !== 'undefined')
      element1.linkAdded(linkObj);
    
    if (typeof (element2['linkAdded']) !== 'undefined')
      element2.linkAdded(linkObj);
    
    if (renderNow) {
      this.renderLink(linkObj);
    }
  },
  removeLink                 : function removeLink(link, callback) {
    var self = this;
    link.removeFromServer(function (success) {
      if (success) {
        self.rawLinks.splice(self.rawLinks.indexOf(link), 1);
        // Maybe remove from links by element hash
        link.clear();
      }
      else {
        alert('Error happened')
      }
    });
  },
  createLink                 : function createLink(element_id_1, element_id_2, fiber_num_1, fiber_num_2, callback) {
    
    var start_id = element_id_1 + '_' + fiber_num_1;
    var end_id   = element_id_2 + '_' + fiber_num_2;
    
    // Check if link exists
    if (this.fiber_by_id[start_id].connected || this.fiber_by_id[end_id].connected) {
      if (callback) callback(true);
      return false;
    }
    
    var linkObj = {
      element_1   : ACommutation.getElementForFiber(start_id),
      element_2   : ACommutation.getElementForFiber(end_id),
      element_id_1: element_id_1,
      element_id_2: element_id_2,
      fiber_num_1 : fiber_num_1,
      fiber_num_2 : fiber_num_2,
      fiber_id_1  : start_id,
      fiber_id_2  : end_id
    };
    
    var link = new Link(linkObj);
    
    var self = this;
    link.sendToServer(function (success) {
      if (success) {
        // Saving ID from server response
        linkObj.id = link.id;
        
        self.addLink(linkObj, true);
        
        if (callback) callback(true);
      }
      else {
        if (callback) callback(false);
      }
    });
    
  },
  redrawLinksForElement      : function (element_id) {
    var links_to_redraw = this.links_for_element[element_id];
    
    if (typeof links_to_redraw === 'undefined') return;
    
    for (var i = 0; i < links_to_redraw.length; i++) {
      links_to_redraw[i].clear();
      links_to_redraw[i].render(true);
    }
  },
  setFiberConnected          : function (fiber_id) {
    this.fiber_by_id[fiber_id].connected = true;
  },
  startConnectingOperationFor: function (event) {
    var fiber_id        = $(event.target).data('fiber_id');
    var current_element = this.getElementForFiber(fiber_id);
    
    var END_FIBER_CLICKED_EVENT = 'Commutation.endfiberClicked';
    
    for (var i = 0; i < this.elements.length; i++) {
      if (this.elements[i] === current_element) continue;
      
      // Set function to execute when clicked on circle we want connect to
      this.elements[i].drawCirclesAndWaitForClick(function (end_fiber_id) {
        ACommutation.endFiberClicked(fiber_id, end_fiber_id);
        
        Events.emit(END_FIBER_CLICKED_EVENT);
      });
      
      Events.off(END_FIBER_CLICKED_EVENT);
      Events.once(END_FIBER_CLICKED_EVENT, this.elements[i].removeCircles.bind(this.elements[i]));
    }
    
  },
  endFiberClicked            : function (fiber_id, end_fiber_id) {
    
    var first_fiber  = this.getFiberById(fiber_id);
    var second_fiber = this.getFiberById(end_fiber_id);
    
    var first_element  = this.getElementForFiber(fiber_id);
    var second_element = this.getElementForFiber(end_fiber_id);
    
    this.createLink(
        first_element.id,
        second_element.id,
        first_fiber._meta.num,
        second_fiber._meta.num
    );
    
    second_element.removeCircles();
  }
};

/** Logical models */
function Link(rawLink) {
  var self = this;
  
  this.is_cable_link = ( rawLink.element_1.type === 'CABLE' && rawLink.element_2.type === 'CABLE' ) ? 1 : 0;
  
  this.geometry = rawLink.geometry;
  this.id       = rawLink.id || null;
  this.color    = rawLink.color || null;
  
  this.start = (rawLink.fiber_id_1)
      ? rawLink.fiber_id_1
      : rawLink.element_1.id + '_' + rawLink.fiber_num_1;
  
  this.end = (rawLink.fiber_id_2)
      ? rawLink.fiber_id_2
      : rawLink.element_2.id + '_' + rawLink.fiber_num_2;
  
  this.startFiber = ACommutation.getFiberById(this.start);
  this.endFiber   = ACommutation.getFiberById(this.end);
  
  ACommutation.setFiberConnected(this.start);
  ACommutation.setFiberConnected(this.end);
  
  // Saving raw attributes to self
  this.attributes.forEach(function (attr_name) {
    self[attr_name] = rawLink[attr_name];
  });
  
  if (rawLink.id === '9') {
    console.log(rawLink);
    console.log(this);
  }
}

Link.prototype = {
  image           : null,
  name            : '',
  attributes      : ['attenuation', 'direction', 'comments'],
  setId           : function (id) {
    this.id = id;
    return this;
  },
  clearGeometry   : function () {
    this.path.clear();
    
    this.geometry = null;
    this.render();
    
    this.saveGeometry();
  },
  render          : function (skip_unnormalize) {
    
    var color = this.startFiber.color;
    
    var path_attr = {
      'stroke'         : color,
      'stroke-width'   : SCHEME_OPTIONS['FIBER_WIDTH'] / 2,
      'stroke-linejoin': 'round',
      'stroke-linecap' : 'round',
      'class'          : 'fiber-link',
      'id'             : this.id
    };
    
    if (!skip_unnormalize && isDefined(this.geometry) && this.geometry !== null) {
      this.geometry = this.geometry.map(function (p) {
        return {
          x: p.x * SCHEME_OPTIONS['CONTAINER_WIDTH'],
          y: p.y * SCHEME_OPTIONS['CONTAINER_HEIGHT']
        }
      })
    }
    
    this.path = new EditablePath(this.geometry, path_attr, {
      color_left : this.startFiber.color,
      color_right: this.endFiber.color,
      color      : this.color,
      start      : this.start,
      end        : this.end,
      onChange   : this.saveGeometry.bind(this)
    });
    
  },
  clear           : function () {
    this.path.path.remove();
    if (this.circle) this.circle.remove();
    
    // Set fibers not connected
    this.startFiber.connected = false;
    this.endFiber.connected   = false;
    
    //Remove edge circle (connected visualization)
    //this.startFiber.rendered.edge.circle.remove();
    //this.endFiber.rendered.edge.circle.remove();
  },
  editAttribute   : function (attr_name) {
    var self  = this;
    var value = self[attr_name.toLowerCase()] || '';
    
    var form_group = getSimpleRow(
        attr_name.toUpperCase(),
        attr_name.toUpperCase(),
        _translate(capitalizeFirst(attr_name)),
        value
    );
    
    aModal.clear()
        .setSmall(true)
        .setBody(form_group[0].innerHTML)
        .addButton(_translate('Set'), 'modalSetBtn', 'default')
        .show(function () {
          $('#modalSetBtn').on('click', function () {
            var value = $('#' + attr_name.toUpperCase()).val();
            self.saveAttribute(attr_name, value);
            aModal.hide();
          })
        });
    
  },
  saveAttribute   : function (attr_name, value, callback) {
    var self          = this;
    var current_value = self[attr_name.toLowerCase()];
    
    if (current_value && current_value === value) {
      console.log('not changed ', attr_name);
      return;
    }
    
    var params = {
      qindex     : INDEX,
      json       : 1,
      header     : 2,
      commutation: 1,
      change     : this.id
    };
    
    params[attr_name.toUpperCase()] = value;
    
    var xhr = $.getJSON(SELF_URL, params, function (response) {
      if (response.MESSAGE && response.MESSAGE.type === 'info') {
        self[attr_name.toLowerCase()] = value;
        if (callback) callback(true);
      }
    });
    
    xhr.fail(function (error) {
      aTooltip.displayError(error);
      if (callback) callback(false);
    });
  },
  editAttenuation : function () {
    this.editAttribute('attenuation');
  },
  saveAttenuation : function (value) {
    this.saveAttribute('attenuation', value);
  },
  editComments    : function () {
    this.editAttribute('comments');
  },
  saveComments    : function (value) {
    this.saveAttribute('comments', value);
  },
  sendToServer    : function (callback) {
    var self = this;
    
    var first_element  = ACommutation.getElementForFiber(this.startFiber._meta.id);
    var second_element = ACommutation.getElementForFiber(this.endFiber._meta.id);
    
    var params = {
      qindex        : INDEX,
      json          : 1,
      header        : 2,
      commutation   : 1,
      add           : 1,
      cables_link   : this.is_cable_link,
      COMMUTATION_ID: document['COMMUTATION_ID'],
      
      ELEMENT_1_TYPE: first_element.type,
      ELEMENT_1_ID  : first_element.origin.id,
      
      ELEMENT_2_TYPE: second_element.type,
      ELEMENT_2_ID  : second_element.origin.id,
      
      FIBER_NUM_1: this.startFiber._meta.num,
      FIBER_NUM_2: this.endFiber._meta.num
    };
    
    $.post(SELF_URL, params, function (response) {
      if (response.MESSAGE && response.MESSAGE.type === 'info') {
        self.saved = true;
        self.id    = response.MESSAGE.ID;
        
        if (callback) callback(true);
      }
      else {
        if (callback) callback(false);
      }
    }).fail(function (error) {
      aTooltip.displayError(error);
      if (callback) callback(false);
    });
    
  },
  removeFromServer: function (callback) {
    var params = {
      qindex     : INDEX,
      json       : 1,
      header     : 2,
      commutation: 1,
      cables_link: this.is_cable_link,
      del        : this.id
    };
    
    $.getJSON(SELF_URL, params, function (response) {
      if (response.MESSAGE && response.MESSAGE.type === 'info') {
        if (callback) callback(true);
      }
    })
        .fail(function (error) {
          aTooltip.displayError(error);
          if (callback) callback(false);
        });
    
  },
  saveGeometry    : function () {
    // Get points from this.path
    var points = this.path.getPoints();
    
    // Normalize points
    var normalize_point = function (p) {
      var accuracy = 10000;
      return {
        x: ((p.x * accuracy) / SCHEME_OPTIONS['CONTAINER_WIDTH']) / accuracy,
        y: ((p.y * accuracy) / SCHEME_OPTIONS['CONTAINER_HEIGHT']) / accuracy
      }
    };
    
    var params = {
      qindex        : INDEX,
      json          : 1,
      header        : 2,
      commutation   : 1,
      change        : this.id,
      cables_link   : this.is_cable_link,
      GEOMETRY      : JSON.stringify(points.map(normalize_point)),
      COMMUTATION_ID: document['COMMUTATION_ID']
    };
    
    $.post(SELF_URL, params).fail(function (error) {
      aTooltip.displayError(error);
    });
  }
};

function ElementWithFibers(type, options) {
  this.name        = options.name || '';
  this.type        = options.type || type;
  this.id          = this.type + '_' + options.id;
  this.fibers      = options.fibers;
  this.edgeCircles = [];
}

ElementWithFibers.prototype = {
  rendered                  : {
    vertical: false,
  },
  drawCirclesAndWaitForClick: function (onEndFiberClick) {
    console.trace();
    for (var j = 0; j < this.fibers.length; j++) {
      var fiber = this.fibers[j];
      if (fiber.connected) continue;
      
      var circle = paper
          .circle(fiber.edge.x, fiber.edge.y, SCHEME_OPTIONS['FIBER_WIDTH'])
          .attr({
            'fill': fiber.color
          })
          .data('fiber_id', fiber._meta.id)
          .data('color', fiber.color)
          .hover(
              function () {    //hover in
                this.attr({
                  fill: 'black'
                })
              }, function () { //hover out
                this.attr({
                  fill: this.data('color')
                })
              })
          .click(function () {
            onEndFiberClick(this.data('fiber_id'));
          });
      
      this.edgeCircles.push(circle);
    }
  },
  removeCircles             : function () {
    
    console.log('removeCircles');
    
    this.edgeCircles.forEach(function (c) {
      c.remove();
    });
    
    this.edgeCircles = [];
  },
  //drawEdgeCircle   : function (index, fiber) {
  //  var fiberStartId = $(fiber.node).data('fiber_id');
  //  var fiberEl      = ACommutation.getFiberById(fiberStartId);
  //  if (fiberEl.rendered.meta.connected) return;
  //
  //  var edge = fiberEl.rendered.edge;
  //
  //  if (!isDefined(edge)) {
  //    console.warn('No edge for fiber. index: ', index, fiber);
  //    return false;
  //  }
  //
  //  var circle = paper.circle(edge.x, edge.y, SCHEME_OPTIONS['FIBER_WIDTH'])
  //      .click(self.endFiberClicked.bind(self))
  //      .attr({
  //        fill: fiberEl.rendered.color
  //      })
  //      .hover(
  //          function () {    //hover in
  //            circle.attr({
  //              fill: 'black'
  //            })
  //          }, function () { //hover out
  //            circle.attr({
  //              fill: fiberEl.rendered.color
  //            })
  //          });
  //
  //  $(circle.node).data('fiber_id', fiberStartId);
  //
  //  fiberEl.rendered.circle = circle;
  //  this.edgeCircles.push(circle);
  //},
  //bindEndFiberClick: function () {
  //
  //  //draw circles
  //  $.each(this.cables, function (index, cable) {
  //    cable.rendered.fibers.unclick();
  //    $.each(cable.rendered.fibers.items, self.drawEdgeCircle.bind(self));
  //  });
  //
  //  //removing circle from fiber that was clicked
  //  this.startFiber.rendered.circle.remove();
  //},
  //endFiberClicked  : function (event) {
  //  //clear circles
  //  $.each(this.edgeCircles, function (index, circle) {
  //    circle.remove();
  //  });
  //  //get info about fiber
  //  var circle = event.target;
  //
  //  var fiberStartId = $(this.startFiber.node).data('fiber_id');
  //  var fiberEndId   = $(circle).data('fiber_id');
  //
  //  // id will be set after adding
  //  var newLink = new Link({
  //    startFiberId: fiberStartId,
  //    endFiberId  : fiberEndId
  //  });
  //
  //  ACommutation.addLink(newLink, function (success) {
  //    if (success) {
  //      self.setFiberConnected(fiberStartId);
  //      self.setFiberConnected(fiberEndId);
  //    }
  //  });
  //
  //  //this.bindStartFiberClick();
  //},
  //setFiberConnected: function (fiber_id, commutation_id) {
  //  var fiberEl = ACommutation.getFiberById(fiber_id);
  //
  //  if (!isDefined(fiberEl)) {
  //    return false;
  //  }
  //
  //  fiberEl.rendered.meta.connected = true;
  //  var edge                        = fiberEl.rendered.edge;
  //
  //  edge['circle'] = paper.circle(edge.x, edge.y, SCHEME_OPTIONS['FIBER_WIDTH'] / 2)
  //      .attr({
  //        fill : 'black',
  //        title: 'connected'
  //      });
  //
  //  $(edge['circle'].node).data('fiber-id', fiber_id);
  //
  //  if (typeof (commutation_id) !== 'undefined' && commutation_id !== document['COMMUTATION_ID']) {
  //    edge['circle'].attr({'class': 'fiber-connected-another'});
  //    $(edge['circle'].node).data('another-commutation_id', commutation_id);
  //  }
  //
  //}
};

var Drawable       = function () {
  this.type = null;
  this.x    = null;
  this.y    = null;
  
  this.rendered = null;
  
  var self = this;
  Events.on('Commutation.rendered', function () {
    self.getInfo(self.initTip.bind(self))
  })
  
};
Drawable.prototype = {
  clear     : function () {
    console.log('default clear')
  },
  redraw    : function () {
    console.log('default redraw')
  },
  render    : function () {
    console.log('default render')
  },
  saveCoords: function () {
    $.post('/admin/index.cgi', {
      qindex        : INDEX,
      header        : 2,
      json          : 1,
      operation     : 'SAVE_COORDS',
      entity        : this.type.toUpperCase(),
      ID            : this.id,
      COMMUTATION_ID: this.raw.commutation_id,
      
      // TODO: normalize coords
      X: this.x,
      Y: this.y
    });
  },
  getInfo   : function (callback) {
    if (!this.getInfoParams) {
      console.log('no getInfo defined for type ' + this.type);
      return;
    }
    
    if (!this.id) {
      console.log(this);
      console.warn(this.type + ' without id');
      return;
    }
    
    var params = this.getInfoParams();
    
    if (this.info && callback) {
      callback(this.info);
      return;
    }
    
    var self = this;
    $.getJSON('/admin/index.cgi', params.params, function (data) {
      if (params.format)
        data = params.format(data);
      
      self.info = data;
      callback(data);
    })
  },
  initTip   : function (info_hash) {
    if (!this.shell) {
      console.log('Drawable without shell defined', this.type);
      console.trace();
    }
    
    this.tip = new HTMLTip(info_hash, this.shell.node);
  }
};

/** Physical models */
var Cable       = function (cableObj) {
  Drawable.apply(this, arguments);
  
  this.type = 'CABLE';
  
  this.cable_raw = cableObj;
  this.id        = cableObj.id;
  this.name      = cableObj.name;
  
  this.absolute_width  = this.cable_raw.image.fibers * (DEFAULT_SCHEME_OPTIONS.FIBER_WIDTH + DEFAULT_SCHEME_OPTIONS.FIBER_MARGIN);
  this.absolute_height = DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + DEFAULT_SCHEME_OPTIONS.MODULE_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT;
  
  this.fibers = [];
  
  // Calculate fibers
};
Cable.prototype = Object.create(Drawable.prototype);
Cable.prototype = $.extend(Cable.prototype, {
  calculateSizes          : function () {
    this.position = this.getPositionRelatedParams();
    
    this.x      = this.position.cable.x;
    this.y      = this.position.cable.y;
    this.width  = this.position.cable.width;
    this.height = this.position.cable.height;
    
    this.calculateFibers();
  },
  calculateFibers         : function () {
    var cable        = this.cable_raw;
    var params       = this.position.fibers;
    var fiber_colors = this.checkColorsLength(cable.image.color_scheme, cable.image.fibers / cable.image.modules);
    if (!fiber_colors) return false;
    
    var marked             = this.filterMarked(fiber_colors);
    var fibersColorPalette = new AColorPalette(fiber_colors);
    
    for (var i = 0; i < cable.image.fibers; i++) {
      
      var color = fibersColorPalette.getNextColorHex();
      
      this.fibers[this.fibers.length] = {
        x       : params.x + params.ox * i,
        y       : params.y + params.oy * i,
        width   : params.width,
        height  : params.height,
        edge    : {
          x: params.x + params.ox * i + params.edge_x_offset,
          y: params.y + params.oy * i + params.edge_y_offset
        },
        start   : {
          x: params.x + params.ox * i + params.start_x,
          y: params.y + params.oy * i + params.start_y
        },
        color   : color,
        vertical: this.position.cable.vertical,
        marked  : marked[i] === true
      };
    }
    
  },
  render                  : function () {
    var cable = this;
    
    //this.calculateSizes();
    
    // Cable outer shell
    var rect = paper.rect(this.x, this.y, this.width, this.height)
        .attr({
          fill          : this.cable_raw.image.color || SCHEME_OPTIONS['CABLE_COLOR'],
          'class'       : 'cable',
          'stroke-width': SCHEME_OPTIONS['SCALE']
        });
    
    $(rect.node).data({
      'cable-id': this.cable_raw.id
    });
    
    var meta = {
      x       : this.position.cable.x,
      y       : this.position.cable.y,
      width   : this.position.cable.width,
      height  : this.position.cable.height,
      vertical: this.position.cable.vertical,
      way     : this.position.cable.way
    };
    rect.data(meta);
    rect.meta = meta;
    
    this.modules = this.drawModules(this.position.modules);
    this.drawFibers(this.position.fibers);
    
    this.rendered = rect;
    // Maybe move all this.rendered ( that are LOT of references ) to this.shell
    this.shell    = this.rendered;
    
    this.renderTooltips(this.cable_raw);
    
    return this;
  },
  getPositionRelatedParams: function () {
    
    var cable = this.cable_raw;
    
    var cable_params   = getCableParams(cable);
    var modules_params = getModulesParams(cable, cable_params);
    var fibers_params  = getFiberParams(cable_params, modules_params);
    
    function getCableParams(cable) {
      var position = cable.meta.position;
      var number   = cable.meta.number;
      
      var fibers_count = cable.image.fibers;
      
      var mirrored = ((position === 'bottom') || (position === 'right'));
      var vertical = ((position === 'top') || (position === 'bottom'));
      
      //if mirrored, should be drawn in negative way
      var way = (mirrored) ? -1 : 1;
      
      var offset = SCHEME_OPTIONS['OPPOSITE_SHIFT'];
      
      // If not first cable on side
      if (number !== 0) {
        // Get width of previous cables
        var cables_before          = ACableManager.cable_by_positions[position].slice(0, number);
        var width_of_cables_before = cables_before.reduce(ACableManager.getSideWidth, 0);
        
        // Apply it to corresponding param
        offset += width_of_cables_before * SCHEME_OPTIONS.SCALE;
      }
      
      //width depends on fibers count
      var width = fibers_count * (SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN'])
          + SCHEME_OPTIONS['CABLE_WIDTH_MARGIN'];
      
      var height = SCHEME_OPTIONS['CABLE_SHELL_HEIGHT'];
      
      var x, y;
      if (vertical) {
        x = (SCHEME_OPTIONS.CABLE_FULL_HEIGHT / 2) + SCHEME_OPTIONS.CABLE_FULL_HEIGHT + offset;
        y = (mirrored) ? SCHEME_OPTIONS['CANVAS_HEIGHT'] - height : 0;
      }
      else {
        x = (mirrored) ? SCHEME_OPTIONS['CANVAS_WIDTH'] - height : 0;
        y = (SCHEME_OPTIONS.CABLE_FULL_HEIGHT / 2) + SCHEME_OPTIONS.CABLE_FULL_HEIGHT + offset;
      }
      
      //if not vertical, flip height and width
      if (!vertical) {
        var temp = height;
        //noinspection JSSuspiciousNameCombination
        height   = width;
        width    = temp;
      }
      
      return {
        x       : x,
        y       : y,
        width   : width,
        height  : height,
        vertical: vertical,
        way     : way
      };
    }
    
    function getModulesParams(cable, cable_params) {
      var y = cable_params.y + cable_params.height;
      var x = cable_params.x + SCHEME_OPTIONS['CABLE_WIDTH_MARGIN'] / 2;
      
      if (!cable_params.vertical) {
        y = cable_params.y + SCHEME_OPTIONS['CABLE_WIDTH_MARGIN'] / 2;
        x = cable_params.x + SCHEME_OPTIONS['MODULE_HEIGHT'] * cable_params.way;
      }
      
      if (cable_params.vertical) {
        if (cable_params.way < 0) {
          y -= cable_params.height + SCHEME_OPTIONS['MODULE_HEIGHT'];
        }
      }
      else {
        if (cable_params.way >= 0) {
          x += SCHEME_OPTIONS['CABLE_SHELL_HEIGHT'] - SCHEME_OPTIONS['MODULE_HEIGHT'];
        }
      }
      
      var width  = cable.image.fibers * (SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN']) / cable.image.modules;
      //noinspection JSSuspiciousNameCombination
      var height = SCHEME_OPTIONS['MODULE_HEIGHT'];
      
      var offset_y = 0;
      var offset_x = width;
      
      if (!cable_params.vertical) {
        offset_x = 0;
        //noinspection JSSuspiciousNameCombination
        offset_y = width;
      }
      
      //if not vertical, flip height and width
      if (!cable_params.vertical) {
        [height, width] = [width, height];
      }
      
      return {
        x     : x,
        y     : y,
        ox    : offset_x,
        oy    : offset_y,
        width : width,
        height: height
      }
    }
    
    function getFiberParams(cable_params, modules_params) {
      
      var width  = SCHEME_OPTIONS['FIBER_WIDTH'];
      var height = SCHEME_OPTIONS['FIBER_HEIGHT'];
      
      var offset_x = SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN'];
      var offset_y = 0;
      
      var first_x, first_y, edge_x_offset, edge_y_offset, start_x, start_y;
      
      if (cable_params.vertical) {
        first_x = modules_params.x + SCHEME_OPTIONS['FIBER_MARGIN'] / 2;
        
        if (cable_params.way < 0) { // Bottom
          first_y       = modules_params.y - SCHEME_OPTIONS['FIBER_HEIGHT'];
          edge_x_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
          edge_y_offset = 0;
          
          start_y = SCHEME_OPTIONS['FIBER_HEIGHT'];
        }
        else { // Up
          first_y       = modules_params.y + SCHEME_OPTIONS['MODULE_HEIGHT'];
          edge_x_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
          edge_y_offset = SCHEME_OPTIONS['FIBER_HEIGHT'] * cable_params.way;
          start_y       = 0;
        }
        
        start_x = edge_x_offset;
      }
      else {
        first_x = modules_params.x + SCHEME_OPTIONS['MODULE_HEIGHT'];
        first_y = modules_params.y + SCHEME_OPTIONS['FIBER_MARGIN'] / 2;
        
        offset_x = 0;
        offset_y = SCHEME_OPTIONS['FIBER_WIDTH'] + SCHEME_OPTIONS['FIBER_MARGIN'];
        
        // Swap height and width
        [width, height] = [height, width];
        
        if (cable_params.way < 0) { // Right
          first_x -= SCHEME_OPTIONS['FIBER_HEIGHT'] + SCHEME_OPTIONS['MODULE_HEIGHT'];
          
          edge_x_offset = 0;
          edge_y_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
          
          start_x = SCHEME_OPTIONS['FIBER_HEIGHT'];
          
        }
        else { // Left
          edge_x_offset = SCHEME_OPTIONS['FIBER_HEIGHT'] * cable_params.way;
          edge_y_offset = SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
          
          start_x = 0;
        }
        
        start_y = edge_y_offset;
      }
      
      return {
        x            : first_x,
        y            : first_y,
        ox           : offset_x,
        oy           : offset_y,
        width        : width,
        height       : height,
        edge_x_offset: edge_x_offset,
        edge_y_offset: edge_y_offset,
        start_x      : start_x,
        start_y      : start_y
      }
    }
    
    return {
      cable  : cable_params,
      modules: modules_params,
      fibers : fibers_params
      
    }
  },
  checkColorsLength       : function (colors_array, desired_length) {
    // If color scheme has more colors, need to splice
    if (colors_array.length > desired_length) {
      colors_array = colors_array.slice(0, desired_length);
    }
    else if (colors_array.length < desired_length) {
      alert('Check color scheme. Color scheme is not enough to show cable : ' + cable.meta.name);
      return false;
    }
    
    return colors_array;
  },
  drawModules             : function (params) {
    var cable = this.cable_raw;
    
    var modules_colors = this.checkColorsLength(cable.image.modules_color_scheme, cable.image.modules);
    if (!modules_colors) return false;
    
    // Saving hash of marked colors
    this.filterMarked(modules_colors);
    var modulesColorPalette = new AColorPalette(modules_colors);
    
    paper.setStart();
    
    for (var i = 0; i < cable.image.modules; i++) {
      paper.rect(params.x + params.ox * i, params.y + params.oy * i, params.width, params.height)
          .attr({
            fill          : modulesColorPalette.getNextColorHex(),
            'stroke-width': SCHEME_OPTIONS['SCALE']
          });
    }
    
    return paper.setFinish();
  },
  drawFibers              : function (params) {
    var cable_raw = this.cable_raw;
    
    paper.setStart();
    
    for (var i = 0; i < this.fibers.length; i++) {
      var fiber = this.fibers[i];
      
      
      var fiber_rect = paper.rect(
          fiber.x, fiber.y, fiber.width, fiber.height
      ).attr({
        fill          : fiber.color,
        'stroke-width': SCHEME_OPTIONS['SCALE'],
        'class'       : 'fiber'
      });
      
      if (fiber.marked) {
        drawLine(fiber.edge, fiber.start);
      }
      
      $(fiber_rect.node)
          .data('fiber_id', 'CABLE_' + cable_raw.id + '_' + (i + 1));
      
      fiber.rendered = fiber_rect;
    }
    
    return paper.setFinish();
  },
  filterMarked            : function (colors_array) {
    var marked = {};
    for (var i = 0; i < colors_array.length; i++) {
      if (colors_array[i].indexOf('+') > 0) {
        marked[i]       = true;
        colors_array[i] = colors_array[i].substr(0, colors_array[i].indexOf('+'));
      }
    }
    return marked;
  },
  renderTooltips          : function () {
    
    var rect = this.rendered;
    
    var x = rect.data('x');
    var y = rect.data('y');
    
    var width  = rect.data('width');
    var height = rect.data('height');
    
    var vertical = rect.data('vertical');
    
    drawText(this.cable_raw);
    
    function drawText(info_object) {
      var description = info_object.meta.name;
      
      var text_x = x + width / 2;
      var text_y = y + height / 2;
      
      var text = paper.text(text_x, text_y, description);
      
      var color = SCHEME_OPTIONS['FONT_COLOR'];
      
      if (info_object.image.color === 'black' || info_object.image.color === ('#000000')) {
        color = '#ffffff';
      }
      
      text.attr({
        'font-family': SCHEME_OPTIONS['FONT'],
        'font-size'  : SCHEME_OPTIONS['FONT_SIZE'] * SCHEME_OPTIONS['SCALE'],
        'font-weight': 400,
        fill         : color
      });
      
      //if cable is horizontal, need to rotate text
      if (!vertical) {
        var angle = 90;
        if (rect.data('way') < 0) {
          angle = 270;
        }
        
        text.attr({
          transform: 'r' + angle
        })
      }
    }
  },
  getInfoParams           : function () {
    return {
      params: {
        chg          : this.id,
        get_index    : 'cablecat_cables',
        header       : 2,
        json         : 1,
        TEMPLATE_ONLY: 1
      },
      format: function (data) {
        var template_params = data['_INFO'];
        return {
          name  : template_params['NAME'],
          length: template_params['LENGTH']
        }
      }
    };
  }
});

function Splitter(splitter_raw) {
  Drawable.apply(this, arguments);
  
  this.type = 'SPLITTER';
  
  this.inputs  = splitter_raw.fibers_in;
  this.outputs = splitter_raw.fibers_out;
  
  this.raw = splitter_raw;
  this.id  = this.raw.id;
  
  // Inits width and height
  this.calculateSizes();
  
  // +( forces values to numeric
  this.x = +(this.raw.commutation_x || SCHEME_OPTIONS.CANVAS_X_CENTER - (this.width / 2));
  this.y = +(this.raw.commutation_y || SCHEME_OPTIONS.CANVAS_Y_CENTER - (this.height / 2));
  
  if (!this.raw.commutation_x && this.num > 0)
    this.x += (this.width * this.num) + SCHEME_OPTIONS.FIBER_MARGIN * 2;
  
  this.fibers_in  = new Array(this.inputs);
  this.fibers_out = new Array(this.outputs);
  
  this.fibers_attrs = {
    fill   : '#dddddd',
    'class': 'fiber',
  };
  this.calculateFiberPositions();
  
  Splitter.prototype.num += 1;
}

Splitter.prototype = Object.create(Drawable.prototype);
Splitter.prototype = $.extend(Splitter.prototype, {
  num                    : 0,
  type                   : SPLITTER,
  clear                  : function () {
    if (this.rendered) this.rendered.remove();
    
    this.rendered = null;
  },
  redraw                 : function () {
    this.clear();
    
    this.rendered = paper.set();
    
    this.shell = paper.rect(
        this.x,
        this.y,
        this.width,
        this.height
    ).attr({
      'class': 'splitter',
      'fill' : 'white'
    });
    
    $(this.shell.node).data('splitter-id', this.id);
    
    this.rendered.push(this.shell);
    
    this.calculateFiberPositions();
    
    for (var i = 0; i < this.fibers_in.length; i++) {
      
      this.rendered.push(this.drawFiber(this.fibers_in[i], i));
    }
    for (var i = 0; i < this.fibers_out.length; i++) {
      this.rendered.push(this.drawFiber(this.fibers_out[i], i + this.fibers_in.length));
    }
  },
  drawFiber              : function (fiber, i) {
    var fiber_rect = paper.rect(
        fiber.x,
        fiber.y,
        SCHEME_OPTIONS['FIBER_WIDTH'],
        SCHEME_OPTIONS['FIBER_HEIGHT'] / 2
    ).attr(this.fibers_attrs);
    
    $(fiber_rect.node)
        .data('fiber_id', this.type + '_' + this.id + '_' + (i + 1));
    
    return fiber_rect;
  },
  makeDraggable          : function () {
    // Draggable circle
    this.draggableCircle = paper.circle(this.x, this.y, SCHEME_OPTIONS.FIBER_MARGIN / 4).attr({fill: 'green'});
    
    var self   = this;
    var moveTo = function (x, y) {
      self.x = x;
      self.y = y;
      self.redraw();
      self.draggableCircle.toFront();
    };
    
    // Make draggable
    this.draggableCircle.draggable({
      moveCb: moveTo,
      endCb : function () {
        self.saveCoords();
        ACommutation.redrawLinksForElement(SPLITTER + '_' + self.id);
      }
    });
    
  },
  render                 : function () {
    
    //this.redraw();
    this.redraw();
    this.makeDraggable();
    
    // Bind on click
    
    return this;
  },
  calculateSizes         : function () {
    var max_count = Math.max(this.inputs, this.outputs);
    
    // Calculate total shell
    this.width  = max_count * SCHEME_OPTIONS.FIBER_FULL_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN / 2;
    this.height = SCHEME_OPTIONS.CABLE_SHELL_HEIGHT / 2;
    
    // Calculate inputs params
    this.inputs_start_x = this.getCenteredFibersStartX(this.inputs);
    this.inputs_edge_y  = SCHEME_OPTIONS['FIBER_HEIGHT'] / 2;
    
    this.outputs_start_x = this.getCenteredFibersStartX(this.outputs);
    this.outputs_edge_y  = this.height;
  },
  calculateFiberPositions: function () {
    // Input fibers
    for (var i = 0; i < this.inputs; i++) {
      var fiber_x       = this.x + this.inputs_start_x + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
      var fiber_y       = this.y - this.inputs_edge_y;
      this.fibers_in[i] = $.extend(this.fibers_in[i] || {}, {
        num     : i,
        x       : fiber_x,
        y       : fiber_y,
        vertical: true,
        edge    : {
          x: fiber_x + SCHEME_OPTIONS['FIBER_WIDTH'] / 2,
          y: fiber_y
        },
        color   : this.fibers_attrs.fill
      });
    }
    
    // Output fibers
    for (var i = 0; i < this.outputs; i++) {
      var fiber_x        = this.x + this.outputs_start_x + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
      var fiber_y        = this.y + this.outputs_edge_y;
      this.fibers_out[i] = $.extend(this.fibers_out[i] || {}, {
        num  : i,
        x    : fiber_x,
        y    : fiber_y,
        edge : {
          x: fiber_x + SCHEME_OPTIONS['FIBER_WIDTH'] / 2,
          y: fiber_y + SCHEME_OPTIONS['FIBER_HEIGHT'] / 2
        },
        color: this.fibers_attrs.fill
      });
    }
  },
  getCenteredFibersStartX: function (fibers_count) {
    return (this.width / 2) - ((SCHEME_OPTIONS.FIBER_FULL_WIDTH * fibers_count - SCHEME_OPTIONS.FIBER_MARGIN) / 2);
  },
});

function Equipment(equipment_raw, options) {
  Drawable.apply(this, arguments);
  
  this.type = 'EQUIPMENT';
  this.id   = equipment_raw.id;
  
  if (!this.id) {
    throw new Error("Got equipment without id")
  }
  
  this.raw    = equipment_raw;
  this.fibers = new Array(+equipment_raw.ports);
  
  this.calculateSizes();
  this.calculateFiberPositions();
  
  this.fiber_attr = {
    fill: 'lightgrey'
  };
  
  Equipment.prototype.num += 1;
}

Equipment.prototype = Object.create(Drawable.prototype);
Equipment.prototype = $.extend(Equipment.prototype, {
  num : 0,
  type: 'EQUIPMENT',
  
  clear                  : function () {
    if (this.rendered) this.rendered.remove();
    this.rendered = null;
  },
  redraw                 : function () {
    this.clear();
    
    this.rendered = paper.set();
    this.text     = paper.text(
        this.x + (this.width / 2),
        this.y + ((this.height + SCHEME_OPTIONS.FIBER_HEIGHT / 4) / 2),
        this.raw.model_name
    );
    
    this.shell = paper.rect(
        this.x,
        this.y,
        this.width,
        this.height
    ).attr({
      'fill' : 'lightblue',
      'class': 'equipment',
      text   : this.text
    });
    
    $(this.shell.node).data('equipment-id', this.id);
    
    this.rendered.push(this.shell);
    this.text.toFront();
    this.rendered.push(this.text);
    
    this.calculateFiberPositions();
    for (var i = 0; i < this.fibers.length; i++) {
      this.rendered.push(
          paper.rect(
              this.fibers[i].x,
              this.fibers[i].y,
              SCHEME_OPTIONS['FIBER_WIDTH'],
              SCHEME_OPTIONS['FIBER_HEIGHT'] / 4
          ).attr({'fill': 'yellowgreen', text: i})
      );
    }
  },
  render                 : function () {
    this.redraw();
    this.makeDraggable();
    //this.getInfo(function (info) {
    // Show info on hover
    
    //this.shell
    //})
  },
  makeDraggable          : function () {
    // Draggable circle
    this.draggableCircle = paper.circle(this.x, this.y, SCHEME_OPTIONS.FIBER_MARGIN / 4).attr({fill: 'green'});
    
    var self   = this;
    var moveTo = function (x, y) {
      self.x = x;
      self.y = y;
      self.redraw();
      self.draggableCircle.toFront();
    };
    
    // Make draggable
    this.draggableCircle.draggable({
      moveCb: moveTo,
      endCb : function () {
        self.saveCoords();
        ACommutation.redrawLinksForElement('EQUIPMENT_' + self.id);
      }
    });
  },
  calculateSizes         : function () {
    // Calculate total shell
    this.width  = this.raw.ports * SCHEME_OPTIONS.FIBER_FULL_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN / 2;
    this.height = SCHEME_OPTIONS.CABLE_SHELL_HEIGHT / 2;
    
    
    // +( forces values to numeric
    if (this.raw.commutation_x && this.raw.commutation_y) {
      this.x = +this.raw.commutation_x;
      this.y = +this.raw.commutation_y;
    }
    else {
      this.x = +(SCHEME_OPTIONS.CANVAS_X_CENTER - (this.width / 2));
      this.y = +(SCHEME_OPTIONS.CANVAS_Y_CENTER - (this.height / 2));
    }
    
    if (!this.raw.commutation_x && this.num > 0)
      this.x += (this.width * this.num) + SCHEME_OPTIONS.FIBER_MARGIN * 2;
    
    
    // Calculate inputs params
    this.fibers_start_x = this.getCenteredFibersStartX(this.raw.ports);
    this.fibers_edge_y  = 0;
    
  },
  calculateFiberPositions: function () {
    // Input fibers
    for (var i = 0; i < this.fibers.length; i++) {
      var fiber_x    = this.x + this.fibers_start_x + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
      var fiber_y    = this.y - this.fibers_edge_y;
      this.fibers[i] = $.extend(this.fibers[i] || {}, {
        num     : i,
        x       : fiber_x,
        y       : fiber_y,
        vertical: true,
        edge    : {
          x: fiber_x + SCHEME_OPTIONS['FIBER_WIDTH'] / 2,
          y: fiber_y
        },
        color   : 'silver'
      });
    }
  },
  getCenteredFibersStartX: function (fibers_count) {
    return (this.width / 2) - ((SCHEME_OPTIONS.FIBER_FULL_WIDTH * fibers_count - SCHEME_OPTIONS.FIBER_MARGIN) / 2);
  },
  getInfoParams          : function () {
    return {
      params: {
        get_index: 'equipment_info',
        NAS_ID   : this.id,
        json     : 1,
        header   : 2
      },
      format: function (template_in_json) {
        var info_tpl_part = template_in_json['_INFO'];
        
        return {
          name    : info_tpl_part['NAS_NAME'],
          ip      : info_tpl_part['NAS_IP'],
          comments: info_tpl_part['COMMENTS']
        };
      }
    };
  }
});

/** Helper geometric models */
function EditablePath(points_raw, path_attr, options) {
  this.attr    = path_attr;
  this.options = options;
  
  if (points_raw) {
    var startFiber = ACommutation.getFiberById(options.start);
    var endFiber   = ACommutation.getFiberById(options.end);
    
    var startPoint = startFiber.edge;
    var endPoint   = endFiber.edge;
    
    points_raw[0]                     = startPoint;
    points_raw[points_raw.length - 1] = endPoint;
  }
  
  this.geometry = points_raw || computePath(this.options.start, this.options.end);
  
  this.first_color  = options.color_left;
  this.second_color = options.color_right;
  
  if (options.color !== null) {
    this.first_color  = options.color;
    this.second_color = options.color;
  }
  
  this.elements = [];
  
  this.render();
}

EditablePath.prototype = {
  clear          : function () {
    this.elements.map(function (elem) {elem.clear()});
  },
  render         : function () {
    this.middle_point_i = Math.ceil(this.geometry.length / 2) - 1;
    
    // Delete view for elements
    this.clear();
    
    // Clear internal elements array
    this.elements = [];
    
    this.path = paper.setStart();
    for (var i = 0; i < this.geometry.length - 1; i++) {
      
      var color = (i < this.middle_point_i) ? this.first_color : this.second_color;
      
      var new_link = new EditablePathElement(this.geometry[i], this.geometry[i + 1], color, this.attr, {
        first   : i === 0,
        last    : i === this.geometry.length - 2,
        num     : i,
        changeCb: this.elementsChanged.bind(this)
      });
      
      this.elements.push(new_link);
    }
    
    for (var i = 0; i < this.elements.length - 1; i++) {
      this.elements[i].setNext(this.elements[i + 1]);
    }
    
    this.path = paper.setFinish();
    
    this.path.circlesToFront();
    this.path.expandOnHover({callback: this.path.circlesToFront});
  },
  elementsChanged: function (pointsChanged) {
    
    if (pointsChanged) {
      this.geometry = [];
      
      for (var i = 0; i < this.elements.length; i++) {
        
        // If element was broken in two parts, save them, ignoring old
        if (isDefined(this.elements[i].first_path) && isDefined(this.elements[i].second_path)) {
          // second_path.p2 === next first_path.p1
          if (i === 0) this.geometry.push(this.elements[i].first_path.p1);
          this.geometry.push(this.elements[i].first_path.p2);
          this.geometry.push(this.elements[i].second_path.p2);
        }
        else {
          // second_path.p2 === next first_path.p1
          if (i === 0) this.geometry.push(this.elements[i].p1);
          this.geometry.push(this.elements[i].p2);
        }
      }
    }
    
    this.render();
    
    if (this.options.onChange) this.options.onChange();
  },
  getPoints      : function () {
    
    var startFiber = ACommutation.getFiberById(this.options.start);
    var endFiber   = ACommutation.getFiberById(this.options.end);
    
    var startPoint = startFiber.edge;
    var endPoint   = endFiber.edge;
    
    var points = this.geometry.map(function (p) {
      return {x: p.x, y: p.y};
    });
    
    points[0]                 = startPoint;
    points[points.length - 1] = endPoint;
    
    return points;
  }
};

function EditablePathElement(point1, point2, color, path_attr, options) {
  this.p1      = point1;
  this.p2      = point2;
  this.attr    = $.extend({}, path_attr, {stroke: color});
  this.id      = path_attr.id + '_' + options.num;
  this.options = options;
  this.last    = options.last;
  
  if (!options.hidden) {
    this.render();
  }
  
  return this;
}

EditablePathElement.prototype = {
  render               : function () {
    this.redraw();
    this.makeDraggable();
  },
  redrawLine           : function () {
    if (this.path) this.path.remove();
    
    this.cmd  = makePathCommand([this.p1, this.p2]);
    this.path = paper
        .path(this.cmd)
        .attr(this.attr);
  },
  redraw               : function () {
    this.clear();
    
    this.point_beetween = getCoordsBetween(this.p1, this.p2);
    
    this.center_circle = paper
        .circle(this.point_beetween.x, this.point_beetween.y, this.attr['stroke-width'] / 4)
        .attr({
          'class'       : 'link-circle',
          'stroke-width': this.attr['stroke-width']
        })
        .click(this.circleClick.bind(this));
    
    if (!this.last) {
      this.right_circle = paper
          .circle(this.p2.x, this.p2.y, this.attr['stroke-width'] / 2)
          .attr({
            'class'       : 'link-circle',
            'stroke-width': this.attr['stroke-width']
          })
          .click(this.circleClick.bind(this));
      $(this.right_circle.node).data({'link-id': this.attr.id});
    }
    // Saving id for context-menu
    $(this.center_circle.node).data({'link-id': this.attr.id});
    
    this.redrawLine();
    
    //if (this.left_circle) this.left_circle.toFront();
    if (this.center_circle) this.center_circle.toFront();
    if (this.right_circle) this.right_circle.toFront();
    
  },
  makeDraggable        : function () {
    this.center_circle.draggable({
      moveCb : this.centerCircleDrag.bind(this),
      startCb: this.centerCircleDragStart.bind(this),
      endCb  : this.centerCircleDragEnd.bind(this)
    });
    
    if (this.right_circle) {
      this.right_circle.draggable({
        moveCb : this.rightCircleDrag.bind(this),
        startCb: this.rightCircleDragStart.bind(this),
        endCb  : this.rightCircleDragEnd.bind(this)
      });
    }
  },
  clear                : function () {
    if (this.path) this.path.remove();
    if (this.center_circle) this.center_circle.remove();
    if (this.right_circle) this.right_circle.remove();
    if (this.first_path) this.first_path.clear();
    if (this.second_path) this.second_path.clear();
  },
  getPath              : function () {
    return this.path;
  },
  circleClick          : function () {
    return this;
  },
  setNext              : function (editableElement) {
    this.right_element = editableElement;
  },
  centerCircleDragStart: function (revert) {
    // On circles drag, create two new editable pathes for neighbor pathes
    if (revert) {
      this.render();
      return;
    }
    
    var options_copy = $.extend({}, this.options, {
      hidden: true
    });
    
    this.path.remove();
    
    var first_coord  = {x: this.p1.x, y: this.p1.y};
    var middle_coord = getCoordsBetween(this.p1, this.p2);
    var second_coord = {x: this.p2.x, y: this.p2.y};
    
    this.first_path  = new EditablePathElement(first_coord, middle_coord, this.attr.color, this.attr, options_copy);
    this.second_path = new EditablePathElement(middle_coord, second_coord, this.attr.color, this.attr, options_copy);
    if (this.last) {
      this.first_path.last  = false;
      this.second_path.last = true;
    }
    
    return this;
  },
  centerCircleDrag     : function (x, y) {
    // Change new pathes while moving
    this.first_path.p2  = {x: x, y: y};
    this.second_path.p1 = {x: x, y: y};
    
    this.first_path.redrawLine();
    this.second_path.redrawLine();
    
    return this;
  },
  centerCircleDragEnd  : function (clicked) {
    // pass new pathes
    if (this.options.changeCb) this.options.changeCb(!clicked);
    
    this.first_path.render();
    this.second_path.render();
    this.clear();
    
    return this;
  },
  rightCircleDragStart : function (revert) {
    
    if (revert) {
      this.render();
      if (this.right_element) this.right_element.render();
      return;
    }
    
    // Hide old view
    this.right_element.clear();
    
    this.path.remove();
    this.center_circle.remove();
    
    return this;
  },
  rightCircleDrag      : function (x, y) {
    
    this.right_element.p1 = {x: x, y: y};
    this.p2               = {x: x, y: y};
    
    this.right_element.redrawLine();
    this.redrawLine();
    
    return this;
  },
  rightCircleDragEnd   : function (clicked) {
    this.render();
    this.right_element.render();
    
    // call changed on parent
    if (this.options.changeCb) this.options.changeCb(!clicked);
    
    return this;
  }
};

//function HTMLTooltip
// Upper menu
function CommutationControlsAbstract() {
  this.$panel = $('#scheme_controls');
  
  var self = this;
  
  this.$plus_dropdown = this.$panel.find('ul.dropdown-menu.plus-options');
  this.$adv_dropdown  = this.$panel.find('ul.dropdown-menu.advanced-options');
  this.$info_btn      = this.$panel.find('button#info-btn');
  
  this.commutation_id = document['COMMUTATION_ID'];
  this.connecter_id   = document['CONNECTER_ID'];
  this.well_id        = document['WELL_ID'];
  
  this.addCable = function () {
    
    loadToModal('?qindex=' + INDEX
        + '&header=2'
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&entity=CABLE'
        + '&operation=LIST'
    );
  };
  
  this.addSplitter = function () {
    
    loadToModal('?qindex=' + INDEX
        + '&header=2'
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&entity=SPLITTER'
        + '&operation=LIST'
    );
  };
  
  this.addEquipment = function () {
    
    loadToModal('?qindex=' + INDEX
        + '&header=2'
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&entity=EQUIPMENT'
        + '&operation=LIST'
    );
    
  };
  
  this.removeCableFromScheme = function (cable_id) {
    Events.once('modal_loaded', function () {
      setTimeout(function () {
        location.reload(true)
      }, 1000);
    });
    
    loadToModal('?qindex=' + INDEX
        + '&header=' + 2
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&CABLE_ID=' + cable_id
        + '&entity=CABLE'
        + '&operation=DELETE'
    );
    
  };
  
  this.connectTwoCablesByNumbers = function (connect_options) {
    
    if (typeof (connect_options.cable_1_id) === 'undefined') {
      loadToModal('?qindex=' + INDEX
          + '&header=2&operation=CONNECT_BY_NUMBERS' +
          '&COMMUTATION_ID=' + document['COMMUTATION_ID']
      );
      return false;
    }
    
    var cable_id_1 = 'CABLE_' + connect_options.cable_1_id;
    var cable_id_2 = 'CABLE_' + connect_options.cable_2_id;
    
    var cable_1_start = connect_options.cable_1_start;
    var cable_1_end   = connect_options.cable_1_end;
    
    var cable_2_start = connect_options.cable_2_start;
    var cable_2_end   = connect_options.cable_2_end;
    
    var selected_1_range = cable_1_end - cable_1_start;
    var selected_2_range = cable_2_end - cable_2_start;
    
    if (selected_1_range !== selected_2_range) {
      alert('Wrong range');
      return;
    }
    
    var array_of_link_params = [];
    for (var i = 0; i <= selected_1_range; i++) {
      array_of_link_params[array_of_link_params.length] = {
        f_1: cable_1_start + i,
        f_2: cable_2_start + i
      };
    }
    
    /**
     *  Recursion used to handle async requests (send only after success of previous request)
     * @param index
     */
    var recursive_add = function (index) {
      var params = array_of_link_params[index];
      if (typeof (params) === 'undefined') return;
      
      console.log("Connecting", cable_id_1, params.f_1, cable_id_2, params.f_2);
      ACommutation.createLink(cable_id_1, cable_id_2, params.f_1, params.f_2, function (success) {
        if (success) {
          recursive_add(++index)
        }
      });
      
    };
    
    recursive_add(0);
    ACommutation.redrawLinksForElement(cable_id_1);
    
  };
  
  this.clearCommutation = function () {
    Events.once('modal_loaded', function () {
      setTimeout(function () {
        location.reload(true)
      }, 1000);
    });
    
    loadToModal('?qindex=' + INDEX
        + '&header=' + 2
        + '&WELL_ID=' + this.well_id
        + '&CONNECTER_ID=' + this.connecter_id
        + '&COMMUTATION_ID=' + this.commutation_id
        + '&operation=CLEAR_COMMUTATION'
    );
  };
  
  this.addLink = function () {
    alert('Add link');
  };
  
  this.initOptionsList = function ($ul, options_table) {
    for (var option in options_table) {
      if (!options_table.hasOwnProperty(option)) continue;
      
      var $option = $('<li></li>');
      var $btn    = $('<a></a>');
      
      $btn.text(_translate(option));
      $btn.on('click', options_table[option].bind(self));
      
      $ul.append($option.append($btn));
    }
  };
  
  this.add_options = {
    'Cable'    : this.addCable,
    'Link'     : this.addLink,
    'Splitter' : this.addSplitter,
    'Equipment': this.addEquipment
  };
  
  this.advanced_options = {
    'Clear': this.clearCommutation
  };
  
  if (CABLES.length === 2 && CABLES[0].image.fibers === CABLES[1].image.fibers) {
    this.advanced_options['Connect by number'] = this.connectTwoCablesByNumbers;
  }
  
  this.initOptionsList(this.$plus_dropdown, this.add_options);
  this.initOptionsList(this.$adv_dropdown, this.advanced_options);
  
  //this.$info_btn.on('click', this.sayHello.bind(this));
  // Add options
  
}

function HTMLTip(info, onElement, options) {
  this.html = this.formatTip(info);
  
  this.element = onElement;
  this.options = options;
  this.id      = 'I' + generate_guid();
  
  this.$tip   = this.createDOM();
  this.height = this.$tip.height();
  // Expose inner element interface
  this.show   = this.$tip.show;
  this.hide   = this.$tip.hide;
  
  this.hide();
  
  if (this.element) {
    this.bindToEl(this.element);
  }
}

HTMLTip.prototype = {
  createDOM: function () {
    return $('<div></div>', {
      id     : this.id,
      'class': 'info-tip'
    })
        .html(this.html)
        .appendTo('div.wrapper');
  },
  formatTip: function (input) {
    switch (typeof input) {
      case 'object' :
        // make table from hash
        var table = $('<table></table>', {'class': 'table table-condensed no-margin'});
        var tbody = $('<tbody></tbody>');
        
        for (var key in input) {
          if (!input.hasOwnProperty(key)) continue;
          
          var name = _translate(key);
          tbody.append($(
              '<tr><td>' + name + '</td><td>' + input[key] + '</td></tr>'
          ))
        }
        
        table.append(tbody);
        return table;
        break;
      default:
        return input
    }
  },
  bindToEl : function (element) {
    var self = this;
    $(element).hover(
        function () {
          self.$tip.show();
        },
        function () {
          self.$tip.hide();
        }
    ).mousemove(function (event) {
      self.moveTo(event.clientX, event.clientY)
    });
  },
  moveTo   : function (left, top) {
    this.$tip.css("left", left - 70).css("top", top - (40 + this.height));
  },
  remove   : function () {
  
  }
};

function initContextMenus() {
  
  var open_url_function = function (url, new_tab) {
    return (typeof(new_tab) !== 'undefined' && new_tab === true)
        ? function () {
          window.open(url, '_blank');
        }
        : function () {
          window.location.href = url;
        }
  };
  
  //Init fiber context-menu
  $.contextMenu({
    // define which elements trigger this menu
    selector      : ".fiber",
    trigger       : 'left',
    itemClickEvent: "click",
    
    build: function ($trigger) {
      var fiber_id = $trigger.data('fiber_id');
      
      var element = ACommutation.getElementForFiber(fiber_id);
      var fiber   = ACommutation.getFiberById(fiber_id);
      if (!fiber) {
        alert('Error creating menu. can\'t find fiber : ' + fiber_id);
        return false;
      }
      
      // Connection options
      var connection_option = (fiber.connected)
          ? {
            name    : _translate('Delete link'),
            icon    : 'delete',
            callback: function () { ACommutation.removeLinkForFiber(fiber_id)}
          }
          : {
            name    : _translate('Connect'),
            icon    : 'add',
            callback: function () { ACommutation.startConnectingOperationFor({target: $trigger}) }
          };
      
      var full_name = fiber._meta.name; //element.name + ':' + (fiber.rendered.meta.number + 1);
      
      return {
        items: {
          // Fiber label
          full_name : {name: full_name, callback: $.noop},
          connection: connection_option
        }
      };
      
    }
  });
  
  //Init link context-menu
  $.contextMenu({
    // define which elements trigger this menu
    selector      : ".link-circle",
    trigger       : 'left',
    itemClickEvent: "click",
    
    build: function ($trigger) {
      var link_id = $trigger.data('link-id');
      
      var link = ACommutation.getLinkById(link_id);
      if (!link) {
        alert('Error creating menu. can\'t find link : ' + link_id);
        return false;
      }
      
      return {
        items: {
          // Fiber label
          full_name  : {name: link.name, callback: $.noop()},
          connection : {
            name    : _translate('Delete link'),
            icon    : 'delete',
            callback: function () { ACommutation.removeLink(link)}
          },
          attenuation: {
            name    : _translate('Attenuation'),
            'icon'  : 'fa-signal',
            callback: link.editAttenuation.bind(link)
          },
          comments   : {
            name    : _translate('Comments'),
            icon    : 'fa-comments-o',
            callback: link.editComments.bind(link)
          },
          clear      : {
            name    : _translate('Clear'),
            icon    : 'fa-remove',
            callback: link.clearGeometry.bind(link)
          }
        }
      };
      
    }
  });
  
  //Init cable context-menu
  $.contextMenu({
    // define which elements trigger this menu
    selector      : ".cable",
    trigger       : 'left',
    itemClickEvent: "click",
    
    build: function ($trigger) {
      var cable_id = $trigger.data('cable-id');
      
      var cable_el = ACommutation.getElementByTypeAndId('CABLE', cable_id);
      if (!cable_el) {
        alert('Error creating menu. can\'t find cable', cable_id);
        return false;
      }
      
      var cable = cable_el.origin.cable_raw;
      
      var cable_other_commutations = {};
      if (cable.meta && cable.meta.other_commutations) {
        
        var commutation_ids = Object.keys(cable.meta.other_commutations);
        if (commutation_ids.length > 0) {
          for (var i = 0; i < commutation_ids.length; i++) {
            
            var com_id    = commutation_ids[i];
            var well_name = cable.meta.other_commutations[com_id];
            
            cable_other_commutations['COMMUTATION_' + com_id] = {
              name    : well_name + ' (' + _translate('Commutation') + '#' + com_id + ')',
              callback: open_url_function('?index=' + INDEX + '&ID=' + com_id)
            }
          }
          
        }
        else {
          cable_other_commutations['no_other_commutations'] = {
            name: _translate('No other commutations')
          }
        }
        
      }
      
      return {
        items: {
          // Fiber label
          full_name         : {
            name : cable.meta.name,
            icon : 'preview',
            items: {
              change : {
                name    : _translate('Change'),
                icon    : 'fa-external-link',
                callback: open_url_function('?get_index=cablecat_cables&full=1&chg=' + cable_id, true)
              },
              map_btn: {
                name    : _translate('Map'),
                icon    : 'fa-map',
                callback: open_url_function('?' + cable.meta.map_btn, true)
              },
              well_1 : {
                name    : cable.meta.well_1,
                icon    : 'fa-external-link',
                callback: open_url_function('?get_index=cablecat_wells&full=1&chg=' + cable.meta.well_1_id, true)
              },
              well_2 : {
                name    : cable.meta.well_2,
                icon    : 'fa-external-link',
                callback: open_url_function('?get_index=cablecat_wells&full=1&chg=' + cable.meta.well_2_id, true)
              }
            }
          },
          other_commutations: {
            name : _translate('Other commutations'),
            icon : 'exchange',
            items: cable_other_commutations
          },
          connection        : {
            name    : _translate('Remove %s from scheme', 'cable'),
            icon    : 'delete',
            callback: function () { ACommutation.removeElementByTypeAndId('CABLE', cable_id)}
          }
        }
      }
    }
  });
  
  //Init connected fiber context-menu
  $.contextMenu({
    // define which elements trigger this menu
    selector      : ".fiber-connected-another",
    trigger       : 'left',
    itemClickEvent: "click",
    
    build: function ($trigger) {
      var another_commutation_id = $trigger.data('another-commutation_id');
      var fiber_id               = $trigger.data('fiber-id');
      
      if (!fiber_id) {
        alert('Error creating menu. can\'t read fiber_id');
        return false;
      }
      
      return {
        items: {
          // Fiber label
          name: {
            name    : _translate('Go to commutation'),
            icon    : 'fa-external-link',
            callback: open_url_function('?get_index=cablecat_commutation&full=1&ID=' + another_commutation_id)
          }
        }
      };
      
    }
  });
  
  //Init splitter context-menu
  $.contextMenu({
    // define which elements trigger this menu
    selector      : ".splitter",
    trigger       : 'left',
    itemClickEvent: "click",
    
    build: function ($trigger) {
      
      var splitter_id = $trigger.data('splitter-id');
      var splitter_el = ACommutation.getElementByTypeAndId('SPLITTER', splitter_id);
      
      if (!splitter_el) {
        alert('Error creating menu. can\'t find splitter ' + splitter_id);
        return false;
      }
      
      var splitter = splitter_el.origin.raw;
      
      console.log(splitter);
      return {
        items: {
          // Fiber label
          full_name : {
            name : splitter.type + '#' + splitter.id,
            icon : 'preview',
            items: {
              change: {
                name    : _translate('Change'),
                icon    : 'fa-external-link',
                callback: open_url_function('?get_index=cablecat_splitters&full=1&chg=' + splitter_id, true)
              }
            }
          },
          connection: {
            name    : capitalizeFirst(_translate('Remove %s from scheme', 'splitter').toLowerCase()),
            icon    : 'delete',
            callback: function () { ACommutation.removeElementByTypeAndId('SPLITTER', splitter_id)}
          }
        }
      }
    }
  });
  
  //Init equipment context-menu
  $.contextMenu({
    // define which elements trigger this menu
    selector      : ".equipment",
    trigger       : 'left',
    itemClickEvent: "click",
    
    build: function ($trigger) {
      
      var equipment_id = $trigger.data('equipment-id');
      var equipment_el = ACommutation.getElementByTypeAndId('EQUIPMENT', equipment_id);
      
      if (!equipment_el) {
        alert('Error creating menu. can\'t find equipment ' + equipment_id);
        return false;
      }
      
      var equipment = equipment_el.origin.raw;
      
      return {
        items: {
          // Fiber label
          full_name : {
            name : equipment.type + '#' + equipment.id,
            icon : 'preview',
            items: {
              change: {
                name    : _translate('Change'),
                icon    : 'fa-external-link',
                callback: open_url_function('?get_index=equipment_info&full=1&NAS_ID=' + equipment_id, true)
              }
            }
          },
          connection: {
            name    : capitalizeFirst(_translate('Remove %s from scheme', 'equipment').toLowerCase()),
            icon    : 'delete',
            callback: function () { ACommutation.removeElementByTypeAndId('EQUIPMENT', equipment_id)}
          }
        }
      }
    }
  });
  
}

function drawLine(point1, point2, color, stroke_w_) {
  var stroke_w = stroke_w_
      ? stroke_w_ * SCHEME_OPTIONS['SCALE']
      : SCHEME_OPTIONS['FIBER_WIDTH'] / 2;
  
  return paper.path('M' + point1.x + ',' + point1.y + 'L' + point2.x + ',' + point2.y).attr({
    'stroke'         : color,
    'stroke-width'   : stroke_w,
    'stroke-linejoin': 'round',
    'stroke-linecap' : 'round'
  });
}

function drawGrid(step, strokeWidth) {
  var path_command = '';
  for (var xx = 0; xx <= SCHEME_OPTIONS['CANVAS_WIDTH']; xx += step) {
    path_command += makePathCommand([{x: xx, y: 0}, {x: xx, y: SCHEME_OPTIONS['CANVAS_HEIGHT']}]);
  }
  for (var yy = 0; yy <= SCHEME_OPTIONS['CANVAS_HEIGHT']; yy += step) {
    path_command += makePathCommand([{x: 0, y: yy}, {x: SCHEME_OPTIONS['CANVAS_WIDTH'], y: yy}]);
  }
  
  paper.path(path_command).attr({
    'stroke-color': 'silver',
    'stroke-width': strokeWidth
  });
}

function makePathCommand(pointsArr) {
  // Move cursor to first point
  var command = 'M ' + pointsArr[0].x + ',' + pointsArr[0].y;
  
  // Apply 'lineto' for every other point
  for (var i = 1; i < pointsArr.length; i++) {
    command += ' L' + pointsArr[i].x + ',' + pointsArr[i].y;
  }
  
  return command;
}

/**
 * Returns coords of point that has minimal and equal distance from both points
 * @param p1 - point
 * @param p2 - point
 * @returns {{x: number, y: number}}
 */
function getCoordsBetween(p1, p2) {
  return {
    x: (p1.x + p2.x) / 2,
    y: (p1.y + p2.y) / 2
  }
}

function calculateMinHeightAndWidth(cablesArr) {
  // Get maximal fibers for present cables
  var max_horizontal_fibers_count = 0;
  var max_vertical_fibers_count   = 0;
  
  for (var i = 0; i < cablesArr.length; i++) {
    
    var fibers_count = +cablesArr[i].image.fibers;
    
    if (+cablesArr[i].meta.vertical === 1) {
      
      if (fibers_count > max_horizontal_fibers_count)
        max_horizontal_fibers_count = fibers_count;
    }
    else {
      if (fibers_count > max_vertical_fibers_count)
        max_vertical_fibers_count = fibers_count;
    }
  }
  
  var base_fiber_width  = DEFAULT_SCHEME_OPTIONS.FIBER_WIDTH + DEFAULT_SCHEME_OPTIONS.FIBER_MARGIN;
  var base_cable_height = DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT * 2;
  
  console.log('calculateMinHeightAndWidth hor ver', max_horizontal_fibers_count, max_vertical_fibers_count);
  
  return {
    height: (max_horizontal_fibers_count > 0)
        ? (base_fiber_width * max_horizontal_fibers_count) + base_cable_height * 3
        : 0,
    width : (max_vertical_fibers_count > 0)
        ? (base_fiber_width * max_vertical_fibers_count) + base_cable_height * 3
        : 0
  };
}

function initZoom(paper) {
  var panZoom;
  panZoom = paper.panzoom({
    initialZoom    : 0,
    initialPosition: {x: 0, y: 0},
    redrawCallback : function () {
      Events.emit('commutation.zoom_changed', panZoom);
    }
  });
  panZoom.enable();
  
  //Events.on('commutation.zoom_changed', function (panzoom) {
  //  var zoom = panzoom.getCurrentZoom();
  //  var pan  = panzoom.getCurrentPosition();
  //
  //  // Set zoomCenter to center of current pan
  //
  //
  //console.log(zoom, pan);
  //})
}

function computePath(start, end) {
  var result = [];
  
  var startElement = ACommutation.getElementForFiber(start);
  var endElement   = ACommutation.getElementForFiber(end);
  
  var startFiber = ACommutation.getFiberById(start);
  var endFiber   = ACommutation.getFiberById(end);
  
  var startPoint = startFiber.edge;
  var endPoint   = endFiber.edge;
  
  result[result.length] = (startPoint);
  
  var sameElement = (startElement === endElement);
  if (sameElement) {
    result.push(endPoint);
    return result;
  }
  
  var sameAxis = (startFiber.vertical === endFiber.vertical);
  
  if (sameAxis) {
    //4-2 points path
    var offset = SCHEME_OPTIONS['FIBER_MARGIN'];//* -1;
    
    offset /= SCHEME_OPTIONS['SCALE'];
    
    var first_point, second_point;
    if (startFiber.vertical) {
      var middle_y =
              SCHEME_OPTIONS['CANVAS_Y_CENTER'] + offset;
      
      if (startPoint.x === endPoint.x) {
        result.push({x: startPoint.x, y: middle_y});
      }
      else {
        first_point  = {
          x: startPoint.x,
          y: middle_y
        };
        second_point = {
          x: endPoint.x,
          y: middle_y
        };
        Array.prototype.push.apply(result, [first_point, getCoordsBetween(first_point, second_point), second_point]);
      }
    }
    else {
      var middle_x =
              SCHEME_OPTIONS['CANVAS_X_CENTER'] + offset;
      
      if (startPoint.y === endPoint.y) {
        result.push({x: middle_x, y: startPoint.y});
      }
      else {
        first_point  = {
          x: middle_x,
          y: startPoint.y
        };
        second_point = {
          x: middle_x,
          y: endPoint.y
        };
        Array.prototype.push.apply(result, [first_point, getCoordsBetween(first_point, second_point), second_point]);
      }
    }
    
  }
  else {
    //3-2 points path
    result.push({
      x: getCloserPoint(startPoint.x, endPoint.x, SCHEME_OPTIONS['CANVAS_WIDTH']),
      y: getCloserPoint(startPoint.y, endPoint.y, SCHEME_OPTIONS['CANVAS_HEIGHT'])
    });
  }
  
  result[result.length] = (endPoint);
  
  return result;
}

/**
 * Return coordinate that is closer to value
 * @param p1 - coordinate of first point
 * @param p2 - coordinate of second point
 * @param value - CANVAS size parameter (height or width)
 * @returns coordinate
 */
function getCloserPoint(p1, p2, value) {
  var del1 = Math.abs(value / 2 - p1);
  var del2 = Math.abs(value / 2 - p2);
  return (Math.max(del1, del2) === del1) ? p2 : p1;
}

function _translate(text, insertion) {
  var translated = document['LANG'][text.toUpperCase()];
  
  if (typeof translated === 'undefined') {
    console.log('[ Commutation:_translate ] No translation for: ' + text);
    return text;
  }
  
  if (typeof insertion !== 'undefined') {
    var insert_translated = function (prev, to_translate) {
      var translated_insertion = _translate(to_translate);
      return prev.replace('%s', translated_insertion);
    };
    
    if ($.isArray(insertion)) {
      for (var i = 0; i < insertion.length; i++) {
        translated = insert_translated(translated, insertion[i])
      }
    }
    else {
      translated = insert_translated(translated, insertion);
    }
    
  }
  
  translated = translated.replace(/&#39;/gm, '\'');
  
  return translated;
}