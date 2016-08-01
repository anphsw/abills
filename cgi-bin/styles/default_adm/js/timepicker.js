/**
 * Created by Anykey on 12.10.2015.
 *
 * Usage: add class 'with-time' to any text input element on page
 *
 * Adjust variables as you need
 */

var HOURS_STEP = 1;
var MINUTES_STEP = 30;

function timepickerInit() {
    //get all elements on page
    var selects = $('input.tcal.with-time');


    $.each(selects, function (i, e) {
        //create new select
        var timeSelect = $('<select></select>');
        timeSelect.addClass('form-control');

        var input = e;

        //fill it with options
        for (var j = 0; j < 24; j += HOURS_STEP)
            for (var k = 0; k <= (60 - MINUTES_STEP); k += MINUTES_STEP)
                $(timeSelect).append(createOption(j, k))

        //attach listener
        $(timeSelect).on('change', function () {
            var select = $(this);

            //read calendar input value
            var prevVal = $(input).val().split(' ')[0];

            //get value and append seconds
            var val = select.val() + ':00';

            $(input).val(prevVal + ' ' + val);
        });


        //$(e).addClass("col-md-6");
        var inpParent = $(e).wrap('<div class="col-md-8"></div>').parent();

        //timeSelect.addClass("col-md-6");
        var selParent =  $(timeSelect).wrap('<div class="col-md-4"></div>').parent();

        //put new select after input
        inpParent.after(selParent);
        //
        //timeSelect.chosen();

    });

    function createOption(hours, minutes) {
        if (!minutes)
            minutes = '00';

        var val = hours + ':' + minutes;

        return '<option value=' + val + '>' + val + '</option>';
    }
}
$(function () {
    timepickerInit();
});
