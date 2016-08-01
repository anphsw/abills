/**
 * Created by AnyKey 15.08.2015
 * e-mail: antoman1994@gmail.com
 * Skype: horodchukanton
 *
 * License: feel free to use it any case and anywhere.
 *
 * Если добавите языки, вышлите мне файлик, добавлю в оригинальную версию.
 */

//Двубуквенный код языка
var _lang;

var _start_session;
var _login;
var _password;
var _connect;

// ссылка, по которой производится переход на start.cgi
var _ext_url_lang;
var _title;
var _register;

//Читаем из cookie
var lang_set = docCookies.getItem('lang');

//если в cookie ичего не записано
if (typeof lang_set === 'undefined') lang_set = 'ru';

setLang(lang_set);


function setLang(language) {
    try {
	  var lang = language.toLowerCase();
	} catch (e) {
		setLang('ru');
	}
    switch (lang) {
        case "en":
            _lang = "EN";
            _start_session = "Start <span> Session";
            _title = "Authorization";
            _login = "Login";
            _password = "Password";
            _connect = "Connect";
            _ext_url_lang = ext_url + '?language=english';
            _register = "Get access";
            break;
        case "ua":
            _lang = "UA";
            _start_session = "Вхід до мережі";
            _title = "Авторизація";
            _login = "Логін";
            _password = "Пароль";
            _connect = "Ввійти";
            _ext_url_lang = ext_url + '?language=ukraine';
            _register = "Отримати доступ";
            break;
        default:
            _lang = "RU";
            _start_session = "Войти";
            _title = "Авторизация";
            _login = "Логин";
            _password = "Пароль";
            _connect = "Вход";
            _ext_url_lang = ext_url + '?language=russian';
            _register = "Получить доступ";
            break;
    }
}

$(document).ready(function () {
    $('#external').attr('href', _ext_url_lang);

    $('#username').attr('placeholder', _login);
    $('#password').attr('placeholder', _password);

    $('#submit').val(_connect);
    $('#get_access').attr('href',_ext_url_lang);

    $('html').attr('lang', _lang);
});

function write(string) {
    document.write(string);
}