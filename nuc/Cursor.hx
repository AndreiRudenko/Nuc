package nuc;


class Cursor {

	public var x(default, null):Float;
	public var y(default, null):Float;
	public var dx(default, null):Float;
	public var dy(default, null):Float;

	public var visible(get, set):Bool;
	var _visible:Bool = true;
	inline function get_visible() return _visible;
	function set_visible(v:Bool):Bool {
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
	function new() {
		x = 0;
		y = 0;
		dx = 0;
		dy = 0;
		var m = kha.input.Mouse.get();
		if(m != null) m.notify(null, null, onMove, null);
	}

	public function lock() {
		var m = kha.input.Mouse.get();
		if(m != null) m.lock();
	}

	public function unlock() {
		var m = kha.input.Mouse.get();
		if(m != null) m.unlock();
	}

	function onMove(x:Int, y:Int, dx:Int, dy:Int) {
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
	}

}
