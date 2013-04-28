var Assert = {
};

Assert.htmlEscape = function(string) {
	return string.replace(/&/g, '&amp;').replace(/>/g, '&gt;').replace(/</g, '&lt');
}

Assert.showOk = function(message) {
	document.write('<font color="green">OK</font>: ' + Assert.htmlEscape(message) + '<br>')
};

Assert.showNg = function(message) {
	document.write('<font color="red">NG</font>: ' + Assert.htmlEscape(message) + '<br>');
};

Assert.showError = function(message) {
	document.write('<font color="red">ER</font>: ' + Assert.htmlEscape(message) + '<br>');
};

var assert = function(str) {
	try {
		result = eval(str);
		if (result) {Assert.showOk(str);} else {Assert.showNg(str);};
	} catch (e) {
		Assert.showError(str + " threw " + e.name + ": " + e.message);
	};
};

var assert_equal = function(target, str) {
	try {
		result = eval(str);
		if (target == result) {
			Assert.showOk(str);
		} else {
			Assert.showNg(str + " is " + result + " and not " + target);
		};
	} catch (e) {
		Assert.showError(str + " threw " + e.name + ": " + e.message);
	};
};

var assert_in_delta = function(target, delta, str) {
	try {
		result = eval(str);
		if (Math.abs(result - target) <= delta) {
			Assert.showOk(str);
		} else {
			Assert.showNg(str + " is " + result + " and not within " + delta + " from " + target);
		};
	} catch (e) {
		Assert.showError(str + " threw " + e.name + ": " + e.message);
	};
};

