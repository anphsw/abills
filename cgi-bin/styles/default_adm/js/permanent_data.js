/**
 * Created by Anykey on 21.06.2016.
 *
 *  Manipulation of permanent data, stored in cookies or browser
 *
 */


function setCookie(name, value, expires) {
  Cookies.set(name, value, expires);
}

function getCookie(name, defaultValue) {
  var result = Cookies.get(name);

  if (typeof (result) === 'undefined') {
    setCookie(name, defaultValue);
    return defaultValue;
  }
  else {
    return result;
  }
}

function setPermanentValue(name, value) {
  if (typeof(Storage) !== "undefined") {
    localStorage.setItem(name, value);
  }
  else {
    setCookie(name, value);
  }
}

function getPermanentValue(name, defaultValue) {
  if (typeof(Storage) !== "undefined") {
    var result = localStorage.getItem(name);
    if (typeof (result) !== "undefined") {
      return result;
    }
    else {
      setPermanentValue(name, defaultValue);
      return defaultValue;
    }
  }
  else {
    getCookie(name, defaultValue);
  }
}

function setSessionValue(name, value) {
  if (typeof(sessionStorage) !== "undefined") {
    sessionStorage.setItem(name, value);
  } else {
    setCookie(name, value);
  }
}

function getSessionValue(name, defValue) {
  if (typeof(sessionStorage) !== "undefined") {
    var result = sessionStorage.getItem(name);
    if (typeof (result) !== "undefined") {
      return result;
    }
    else {
      setSessionValue(name, defValue);
      return defValue;
    }
  }
  else {
    getCookie(name, defValue);
  }
}

