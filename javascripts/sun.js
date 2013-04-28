// 「天体の位置計算 増補版」長沢 工著、地人書館、2001年、ISBN4-8052-0225-4
var Sun = {
	et0_msec: new Date(Date.UTC(1974, 11, 31, 0)).getTime(),	// p.206
	sin_deg: function(deg){return Math.sin(deg / 180.0 * Math.PI);}
};

// Time Parameter for the time ET (Ephemeris Time) as a Date
Sun.t = function(et) {
	return (et.getTime() - Sun.et0_msec)/(365.25*24*3600*1000);	// p.207
};

// Sun's ecliptic longitude for Time Parameter
Sun.lambda_for_t = function(t) {	// p.206
	var r = 279.0358 + 360.00769*t
		+ (1.9159 - 0.00005*t) * Sun.sin_deg(356.531 + 359.991*t)
		+ 0.0200 * Sun.sin_deg(353.06 + 719.981*t)
		- 0.0048 * Sun.sin_deg(248.64 -  19.341*t)
		+ 0.0020 * Sun.sin_deg(285.0  + 329.64*t)
		+ 0.0018 * Sun.sin_deg(334.2  -4452.67*t)

		+ 0.0018 * Sun.sin_deg(293.7  -   0.20*t)
		+ 0.0015 * Sun.sin_deg(242.4  + 450.37*t)
		+ 0.0013 * Sun.sin_deg(211.1  + 225.18*t)
		+ 0.0008 * Sun.sin_deg(208.0  + 659.29*t)
		+ 0.0007 * Sun.sin_deg( 53.5  +  90.38*t)

		+ 0.0007 * Sun.sin_deg( 12.1  -  30.35*t)
		+ 0.0006 * Sun.sin_deg(239.1  + 337.18*t)
		+ 0.0005 * Sun.sin_deg( 10.1  -   1.50*t)
		+ 0.0005 * Sun.sin_deg( 99.1  -  22.81*t)
		+ 0.0004 * Sun.sin_deg(264.8  + 315.56*t)

		+ 0.0004 * Sun.sin_deg(233.8  + 299.30*t)
		- 0.0004 * Sun.sin_deg(198.1  + 720.02*t)
		+ 0.0003 * Sun.sin_deg(349.6  +1079.97*t)
		+ 0.0003 * Sun.sin_deg(241.2  -  44.43*t)
		;
	return r % 360;
};

// Difference between Epehmeris Time and UT: ET = UT + DT
Sun.dT = function(time) {
	var y = time.getTime()/(365.25*24*3600*1000) + 1970;
	return 0.895895*(y - 1960.5) + 30.7727;	// see scratch/dt.dat
};

// Epehmeris Time for UT
Sun.eT = function(time) {
	return new Date(time.getTime() + Sun.dT(time));
};

Sun.t0_msec = Sun.eT(new Date(Date.UTC(1989, 11, 31, 0))).getTime(); // p.141

// Sun's ecliptic longitude for Time
Sun.lambda = function(time) {
	return Sun.lambda_for_t(Sun.eT(time));
};

// Mean obliquity of the ecliptic
Sun.mean_obliquity = function(et) {
	var t = (et.getTime() - Sun.t0_msec)/(36525*24*3600*1000);
	return 23.452294 - 0.0130125*t - 0.00000164*t*t + 0.000000503*t*t*t;
};
