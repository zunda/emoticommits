// 「天体の位置計算 増補版」長沢 工著、地人書館、2001年、ISBN4-8052-0225-4
var Sun = {
	et0_msec: new Date(Date.UTC(1974, 11, 31, 0)).getTime()	// p.206
};

// Time Parameter for the time ET (Ephemeris Time) as a Date
Sun.t = function(et) {
	return (et.getTime() - Sun.et0_msec)/(365.25*24*3600*1000);	// p.207
};
