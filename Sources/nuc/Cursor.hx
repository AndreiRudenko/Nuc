package nuc;

typedef MouseCursor = kha.input.Mouse.MouseCursor;

class Cursor {

	static public var x(default, null):Float;
	static public var y(default, null):Float;
	static public var dx(default, null):Float;
	static public var dy(default, null):Float;

	static public var visible(get, set):Bool;
	static var _visible:Bool = true;
	static inline function get_visible() return _visible;
	static function set_visible(v:Bool):Bool {
		var m = kha.input.Mouse.get();
		if(m != null) {
			if(v) {
				m.showSystemCursor();
			} else {
				m.hideSystemCursor();
			}
			_visible = v;
		}

		return _visible;
	}

	@:allow(nuc.App)
	static function init() {
		x = 0;
		y = 0;
		dx = 0;
		dy = 0;
		var m = kha.input.Mouse.get();
		if(m != null) m.notify(null, null, onMove, null);
	}

	static public function lock() {
		var m = kha.input.Mouse.get();
		if(m != null) m.lock();
	}

	static public function unlock() {
		var m = kha.input.Mouse.get();
		if(m != null) m.unlock();
	}

	static public function setSystemCursor(cursor:MouseCursor) {
		var m = kha.input.Mouse.get();
		if(m != null) m.setSystemCursor(cursor);
	}

	static function onMove(cx:Int, cy:Int, cdx:Int, cdy:Int) {
		x = cx;
		y = cy;
		dx = cdx;
		dy = cdy;
	}

}
