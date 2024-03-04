function make_tree(data, keys, attr) {
  jQuery('#show_tree').on('click', '.children-toggle', function() {
    jQuery(this).siblings('.ul-list').slideToggle();

    if (jQuery(this).children().hasClass('fa-plus-circle')) {
      let customEvent = new CustomEvent('open-tree-toggle', {detail: {parent: jQuery(this)}});
      document.dispatchEvent(customEvent);
    }

    jQuery(this).children().toggleClass('fa-minus-circle');
    jQuery(this).children().toggleClass('fa-plus-circle');
  });

  jQuery('#show_tree').append(drawTree(data, undefined, attr));
}

var _EMPTY_FIELD;
function drawTree(treeData, type, attr = {}) {
  let result = jQuery(`<ul class='ul-list'></ul>`);

  treeData.forEach(field => {
    let name = attr && attr.key ? field[attr.key] : field.name || _EMPTY_FIELD;
    name = attr.url && !attr.skip_url ?
      jQuery(`<a href='${attr.url + field.id}' target='_blank'>${name}</a>`).addClass('text-info') : jQuery(`<span>${name}</span>`);
    let icon = jQuery('<i></i>').addClass('cursor-pointer fa fa-plus-circle mn');
    let btn = attr.skip_collapse ? '' : jQuery('<a></a>').addClass('children-toggle btn btn-lg').append(icon);

    let input_name = field.type ? field.type.toUpperCase() : type.toUpperCase();
    let input = '';
    if (!attr.skip_input) {
      input = jQuery(`<input type='checkbox'/>`).attr('value', field.id)
        .addClass('tree_box mr-1').attr('name', `${input_name}_ID`).change(checkNodes);
      if (attr.parent_checked) {
        input.attr('checked', 'checked').attr('disabled', 'disabled');
        name.addClass('text-success');
      }
      else if (checked_nodes[field.type || type].checked[field.id]) {
        input.attr('checked', 'checked');
        name.addClass('text-success');
      }
      else if (checked_nodes[field.type || type].parent && checked_nodes[field.type || type].parent[field.id]) {
        name.addClass('text-info');
      }
    }

    let label = jQuery('<span></span>').addClass('parent').append(input).append(name);
    let node = jQuery('<li></li>').addClass('ul-item').attr('data-type', field.type || type).attr('data-id', field.id)
      .append(btn).append(label);

    result.append(node);
  });

  return result;
}