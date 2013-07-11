function checkForm( form_id )
{
    if(! check($('#'+form_id) ))
        return false;
    return true;
}

function checkFormCart( form_id )
{
    if(! check($('#'+form_id) ))
        return false;
    $('#'+form_id).submit();
    return true;
}

function check(div)
{
    err = 0;
    $(div).find('.required').each(
        function()
        {
            if(!checkElement($(this))) err ++;
        }
    );

    if( err )
    {
        return false;
    } else
        return true;
}

function checkElement(elem)
{
    if(elem.val() == elem.attr('rel') || !elem.val() )
    {
        addError(elem, elem.attr('title'));
		elem.addClass('err');
        return false;
    }
    else{
        if(elem.hasClass('email') && !checkemail(elem.val() ) ){
            addError(elem, 'Введите корректный e-mail');
			elem.addClass('err');
            return false;
        }
		if(elem.hasClass('phone') && !checkphone(elem.val() ) ){
            addError(elem, 'Номер телефона может содержать только цифры и символы');
			elem.addClass('err');
            return false;
        }
        removeError(elem);
		elem.removeClass('err');
        return true;
    }
}

function addError(elem, error)
{
    elem.siblings('div.formerrors').html(error).show();
    elem.parent().siblings('div.formerrors').html(error).show();
	
    elem.unbind('keyup');
    elem.unbind('change');
    elem.bind('keyup', function(){checkElement($(this));});
    elem.bind('change', function(){checkElement($(this));});
}
function removeError(elem)
{
    elem.siblings('div.formerrors').html('').hide();
	elem.parent().siblings('div.formerrors').html('').hide();
}
function checkemail( str )
{
    var filter=/^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
    if (filter.test(str))
    testresults=true
    else{
        //alert("Введите правильный адрес email!")
        testresults=false
    }
    return (testresults)
}
function checkphone( str )
{
    var filter=/[A-Za-z\u0400-\u04FF]/i;
    if (!filter.test(str) && str.length > 5)
		testresults=true
    else{
        testresults=false
    }
    return (testresults)
}

function clearValues( block )
{
    $(block).find('input,select,textarea').each(function()
    {
        if( $(this).attr('default') != undefined )
        {
            if( $(this).val() == $(this).attr('default') ) $(this).val('');
        }
    });
    return true;
}