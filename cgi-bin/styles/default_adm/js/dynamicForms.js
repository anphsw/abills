/**
 * Created by Anykey on 21.07.2015.
 *
 * Provides bootstrap dynamic form rows
 */

input_classes = 'form-control';
input_col_classes = 'col-md-9 col-sm-9';

label_classes = 'control-label';
label_col_classes = 'col-md-3 col-sm-3';

function get_input(type, name, id) {
    return '<input class="' + input_classes + '" type=' + type + ' name=' + name + ' id=' + id + ' />'
}

function get_label(for_, text) {
    return '<label class=\"' + label_classes + ' ' + label_col_classes + '\" for=\"' + for_ + '\">' + text + '</label>'
}

function get_wrapped_div(classes, element) {
    return get_wrapped_element('div', classes, element);
}

function get_wrapped_element(tag, classes, element) {
    var s = '';
    s += '<' + tag + ' class="' + classes + '" >';
    s += element;
    s += '</' + tag + '>';
    return s;
}

/**
 * Returns a simple bootstrap form-group row with label and text typed input;
 *
 * @param name
 * @param id
 * @param label_text
 * @returns {*}
 */
function getSimpleRow(name, id, label_text) {
    return get_wrapped_div('form-group', get_label(id, label_text) + get_wrapped_div(input_col_classes, get_input('text', name, id)));
}

function getCheckboxRow(name, id, label_text){
    return get_wrapped_div('form-group', get_label(id,label_text) + get_wrapped_div('control-element', get_input('checkbox',name,id)));
}

/**
 * Returns text of grouped simple rows
 * @param arrRows - two-dimensional array [[Input_name,Input_id,Label_value],[Input_name1,Input_id1,Label_value1]]
 */
function get_multi_simple_row(arrRows) {
    var result = '';
    arrRows.forEach(function (row) {
        var name = row[0];
        var id = row[1];
        var label = row[2];
        result += getSimpleRow(name, id, label);
    });
    return result;
}

function getWrappedInForm(form_name, nullable_classes, element) {
    if (!nullable_classes) nullable_classes = '';
    return get_wrapped_element('form name="' + form_name + '" id="'+ form_name +'"', nullable_classes, element);
}

function parseCSV(CSVdata){
    var arrRows = CSVdata.split('\n');
    console.log(arrRows);

    return true;
}

function wrap($element, classes){
    $( $element ).wrap( "<div class='"+classes+"'></div>" );
}
