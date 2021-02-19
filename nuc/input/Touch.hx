package nuc.input;

import nuc.App;
import nuc.utils.Log;
import nuc.utils.Bits;
import nuc.events.TouchEvent;

// TODO: Test what is if app is minimized while touching

@:allow(nuc.Input)
class Touch {

	public var active(default, null):Bool = false;

	public var count(default, null):Int = 0;
	public var touches(default, null):Array<TouchEvent>;

	var _touchesCache:Array<TouchEvent>;

	public function new() {}

	public function enable() {
		if(active) return;

		Log.debug('enable');

		_touchesCache = [];
		touches = [];

		for (i in 0...10) {
			_touchesCache.push(new TouchEvent(i));
		}

		#if nuc_touch_input
		var t = kha.input.Surface.get();
		if(t != null) t.notify(onPressed, onReleased, onMove);
		#end

		active = true;
	}

	public function disable() {
		if(!active) return;
		
		Log.debug('disable');

		#if nuc_touch_input
		var t = kha.input.Surface.get();
		if(t != null) t.remove(onPressed, onReleased, onMove);
		#end

		_touchesCache = null;

		active = false;
	}

	function reset() {}

	function onPressed(id:Int, x:Int, y:Int) {
		Log.debug('onPressed id:$id, x:$x, y$y');

		count++;

		var t = _touchesCache[id];
		t.set(x, y, 0, 0, TouchEvent.TOUCH_DOWN);
		
		touches.push(t);

		Nuc.app.emitter.emit(TouchEvent.TOUCH_DOWN, t);
	}

	function onReleased(id:Int, x:Int, y:Int) {
		Log.debug('onPressed id:$id, x:$x, y$y');

		count--;

		var t = _touchesCache[id];
		t.set(x, y, 0, 0, TouchEvent.TOUCH_UP);

		Nuc.app.emitter.emit(TouchEvent.TOUCH_UP, t);

		touches.remove(t);
	}

	function onMove(id:Int, x:Int, y:Int) {
		Log.verbose('onMove id:$id, x:$x, y$y');

		var t = _touchesCache[id];
		t.set(x, y, x - t.x, y - t.y, TouchEvent.TOUCH_MOVE);

		Nuc.app.emitter.emit(TouchEvent.TOUCH_MOVE, t);
	}

}
