package nuc.input;

import nuc.App;
import nuc.utils.Log;
import nuc.events.PenEvent;

@:allow(nuc.App)
class Pen {

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
	static public var pressure(default, null):Float = 0;

	static var penDown:Bool = false;

	static var penEvent:PenEvent;

	static public function init() {
		enabled = true;
		penEvent = new PenEvent();
	}

	static function enable() {
		#if !nuc_no_pen_input
		var p = kha.input.Pen.get();
		if(p != null) p.notify(onPressed, onReleased, onMove);
		#end
	}

	static public function disable() {
		#if !nuc_no_pen_input
		var p = kha.input.Pen.get();
		if(p != null) p.remove(onPressed, onReleased, onMove);
		#end
	}

	static function onPressed(px:Int, py:Int, pres:Float) {
		Log.debug('onPressed x:$px, y$py, button:$pres');

		x = px;
		y = py;
		pressure = pres;

		penDown = true;

		penEvent.set(x, y, 0, 0, PenEvent.PEN_DOWN, pressure);

		App.events.fire(PenEvent.PEN_DOWN, penEvent);
	}

	static function onReleased(px:Int, py:Int, pres:Float) {
		Log.debug('onReleased x:$px, y$py, button:$pres');

		x = px;
		y = py;
		// pressure = pres;
		pressure = 0;

		penDown = false;

		penEvent.set(x, y, 0, 0, PenEvent.PEN_UP, pressure);
		App.events.fire(PenEvent.PEN_UP, penEvent);
	}

	static function onMove(px:Int, py:Int, pres:Float) {
		Log.verbose('onMove x:$x, y$y, dx:$dx, dy:$dy');

		final dx = px - x;
		final dy = py - y;
		x = px;
		y = py;
		pressure = pres;

		penEvent.set(x, y, dx, dy, PenEvent.PEN_MOVE, pressure);
		App.events.fire(PenEvent.PEN_MOVE, penEvent);
	}

}
