/*
 * GitX Javascript library
 * This library contains functions that can be shared across all
 * webviews in GitX.
 * It is written only for Safari 3 and higher.
 */

function $(element) {
	return document.getElementById(element);
}

String.prototype.escapeHTML = function() {
  return this.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
};

String.prototype.unEscapeHTML = function() {
  return this.replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
};

Element.prototype.toggleDisplay = function() {
	if (this.style.display != "")
		this.style.display = "";
	else
		this.style.display = "none";
}

Array.prototype.indexOf = function(item, i) {
  i || (i = 0);
  var length = this.length;
  if (i < 0) i = length + i;
  for (; i < length; i++)
    if (this[i] === item) return i;
  return -1;
};

var notify = function(text, state) {
	var n = $("notification");
	n.style.display = "";
	$("notification_message").innerHTML = text;
	
	// Change color
	if (!state) { // Busy
		$("spinner").style.display = "";
		n.setAttribute("class", "");
	}
	else if (state == 1) { // Success
		$("spinner").style.display = "none";
		n.setAttribute("class", "success");
	} else if (state == -1) {// Fail
		$("spinner").style.display = "none";
		n.setAttribute("class", "fail");
	}
}

var hideNotification = function() {
	$("notification").style.display = "none";
}


//cookie functions from quirksmode
function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}
function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

// cookie functions from W3C Schools
function setCookie(c_name, value, expiredays) {
	var exdate = new Date();
	exdate.setDate(exdate.getDate() + expiredays);
	document.cookie = c_name + "=" + escape(value) +
	((expiredays == null) ? "" : ";expires=" + exdate.toGMTString());
}

function getCookie(c_name) {
	if (document.cookie.length > 0) {
		c_start = document.cookie.indexOf(c_name + "=");
		if (c_start != -1) {
			c_start = c_start + c_name.length + 1;
			c_end = document.cookie.indexOf(";", c_start);
			if (c_end == -1) c_end = document.cookie.length;
			return unescape(document.cookie.substring(c_start, c_end));
		}
	}
	return "";
};