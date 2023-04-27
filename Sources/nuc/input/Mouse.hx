package nuc.input;

import nuc.App;
import nuc.utils.Log;
import nuc.utils.Bits;

import nuc.events.MouseEvent;

@:allow(nuc.App)
class Mouse {

	static public var enabled(default, set):Bool = false;
	static function set_enabled(v:Bool) {
		if (enabled != v) {
			if (v) {
				enable();
			} else {
				disable();
			}
		}
		return enabled = v;
	}
	
	static public var x(default, null):Int = 0;
	static public var y(default, null):Int = 0;

	static var buttonsDown:UInt = 0;
	static var mouseEvent:MouseEvent;

	static public function init() {
		mouseEvent = new MouseEvent();
		enabled = true;
	}

	static function enable() {
		#if !nuc_no_mouse_input
		var m = kha.input.Mouse.get();
		if(m != null) m.notify(onPressed, onReleased, onMove, onWheel);
		#end
	}

	static function disable() {
		#if !nuc_no_mouse_input
		var m = kha.input.Mouse.get();
		if(m != null) m.remove(onPressed, onReleased, onMove, onWheel);
		#end
	}

	static public inline function down(button:Int):Bool {
		return Bits.check(buttonsDown, button);
	}

	static function onPressed(button:Int, px:Int, py:Int) {
		Log.debug('onPressed x:$px, y$py, button:$button');

		x = px;
		y = py;

		buttonsDown = Bits.set(buttonsDown, button);

		mouseEvent.set(x, y, 0, 0, 0, MouseEvent.MOUSE_DOWN, button);

		App.events.fire(MouseEvent.MOUSE_DOWN, mouseEvent);
	}

	static function onReleased(button:Int, px:Int, py:Int) {
		Log.debug('onPressed x:$px, y$py, button:$button');

		x = px;
		y = py;

		buttonsDown = Bits.clear(buttonsDown, button);

		mouseEvent.set(x, y, 0, 0, 0, MouseEvent.MOUSE_UP, button);

		App.events.fire(MouseEvent.MOUSE_UP, mouseEvent);
	}

	static function onWheel(d:Int) {
		Log.debug('onWheel delta:$d');

		mouseEvent.set(x, y, 0, 0, d, MouseEvent.MOUSE_WHEEL, MouseButton.NONE);

		App.events.fire(MouseEvent.MOUSE_WHEEL, mouseEvent);
	}

	static function onMove(px:Int, py:Int, dx:Int, dy:Int) {
		Log.verbose('onMove x:$x, y$y, dx:$dx, dy:$dy');

		x = px;
		y = py;

		mouseEvent.set(x, y, dx, dy, 0, MouseEvent.MOUSE_MOVE, MouseButton.NONE);

		App.events.fire(MouseEvent.MOUSE_MOVE, mouseEvent);
	}

}
