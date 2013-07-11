$(document).ready(function(){
	$('.noscript').removeClass('noscript');
	$(".styled_selectbox").selectbox();
});

function changeFile(elem){
	elem.siblings('#id_file').val(elem.val().replace("C:\\fakepath\\",""));
}