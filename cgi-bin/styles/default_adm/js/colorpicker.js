/**
 * Created by Anykey on 23.11.2015.
 *
 * Allows choose color from AColorPalette;
 *
 * <div class='row'>
 *   <div class='col-md-3'>
 *     <select name='COLOR' value='%COLOR%' id='colorPicker'></select>
 *   </div>
 * </div>
 * <script src='/styles/default_adm/js/colorpicker.js'></script>
 *
 */

$(function () {
    var $colorPicker = $('select#colorPicker');

    var colors = new AColorPalette();
    var value = $colorPicker.attr('value');

    for (var i = 0, count = colors.getColorsCount(); i < count; i++) {
        var $option = $('<option></option>');
        var color = colors.getNextColorHex();
        $option.attr('value', color);

        //if (color === value) $option.prop('selected', true);

        var $coloredDiv = $('<div></div>');
        $coloredDiv.html('&nbsp;');
        $coloredDiv.css({
            'min-height': '1em',
            'min-width': '100%',
            'background-color': color
        });

        $option.html($coloredDiv);

        $colorPicker.append($option);
    }

    //choosed color
    if (value){
        _log(1, 'ColorPicker', value.toUpperCase());
        $colorPicker.find('option[value='+ value.toUpperCase() +']').prop('selected', true);
    }

    $('#colorPicker_chosen.chosen-container').attr('style', 'width: 100%');

    $colorPicker.trigger("chosen:updated");
});

