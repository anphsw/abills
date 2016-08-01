/**
 * Created by Anykey on 08.07.2015.
 */
if (QueryString.login != '') {
    var user_login = QueryString.login;
}

if (QueryString.password != '') {
    var user_pass = QueryString.password;
}

if (QueryString.fastlogin != '') {
    try {
		var fastLogin = QueryString.fastlogin.toLowerCase();
		console.log(fastLogin);		
	} catch ( e ) {
		var fastLogin = 'false';
	}
}

if (fastLogin == 'true') {
	
	console.log(user_login, user_pass);
    if (user_login != '' && user_pass != '') {
        doFastLogin(user_login, user_pass);
    }
    else {
      console.warn('empty login or pass in query');
    }
}

function doFastLogin(username, password) {
  $(function(){
    $('#request_login_form').hide();
    
	var login_form = jQuery('form#login');
  	var username_field = login_form.find('#username');
  	var password_field = login_form.find('#password');
  	
  	username_field.val(username);
  	password_field.val(password);
  	
    login_form.submit();
  });
  
  return true;
}