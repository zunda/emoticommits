var Assert = {
};

Assert.showOk = function(message) {
	document.write('<font color="green">OK</font>: ' + message + '<br>')
};

Assert.showNg = function(message) {
	document.write('<font color="red">NG</font>: ' + message + '<br>');
};

var assert = function(str) {
	result = eval(str);
	if (result) {Assert.showOk(str);} else {Assert.showNg(str);};
};

var assert_equal = function(target, str) {
	result = eval(str);
	if (target == result) {
		Assert.showOk(str + " is " + target);
	} else {
		Assert.showNg(str + " is " + result + " and not " + target);
	};
};

var assert_in_delta = function(target, delta, str) {
	result = eval(str);
	if (Math.abs(result - target) <= delta) {
		Assert.showOk(str + " is within " + delta + " from " + target);
	} else {
		Assert.showNg(str + " is " + result + " and not within " + delta + " from " + target);
	};
};

