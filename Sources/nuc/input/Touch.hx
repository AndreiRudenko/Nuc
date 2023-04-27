package nuc.input;

import nuc.App;
import nuc.utils.Log;
import nuc.events.TouchEvent;
using nuc.utils.ArrayTools;

@:allow(nuc.App)
class Touch {

	static var TOUCHES_MAX(default, null):Int = 10;

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

	static public var count(default, null):Int = 0;
	static public var touches(default, null):Array<TouchEvent>;

	static var touchCache(default, null):Array<TouchEvent>;

	static public function init() {
		touchCache = [];
		touches = [];
		
		for (i in 0...TOUCHES_MAX) {
			touchCache.push(new TouchEvent(i));
		}

		enabled = true;
	}

	static function enable() {
		Log.debug('enable');

		#if !nuc_no_touch_input
		var t = kha.input.Surface.get();
		if(t != null) t.notify(onPressed, onReleased, onMove);
		#end
	}

	static function disable() {
		Log.debug('disable');

		#if !nuc_no_touch_input
		var t = kha.input.Surface.get();
		if(t != null) t.remove(onPressed, onReleased, onMove);
		#end
	}

	static function onPressed(id:Int, x:Int, y:Int) {
		Log.debug('onPressed id:$id, x:$x, y$y');

		count++;

		final t = touchCache[id];
		t.set(x, y, 0, 0, TouchEvent.TOUCH_DOWN);

		touches.push(t);

		App.events.fire(TouchEvent.TOUCH_DOWN, t);
	}

	static function onReleased(id:Int, x:Int, y:Int) {
		Log.debug('onReleased id:$id, x:$x, y$y');

		count--;

		final t = touchCache[id];
		t.set(x, y, 0, 0, TouchEvent.TOUCH_UP);

		touches.remove(t);

		App.events.fire(TouchEvent.TOUCH_UP, t);
	}

	static function onMove(id:Int, x:Int, y:Int) {
		Log.verbose('onMove id:$id, x:$x, y$y');

		var t = touchCache[id];
		t.set(x, y, x - t.x, y - t.y, TouchEvent.TOUCH_MOVE);

		App.events.fire(TouchEvent.TOUCH_MOVE, t);
	}

}
