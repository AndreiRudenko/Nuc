package nuc.input;

import nuc.input.Mouse;
import nuc.input.Keyboard;
import nuc.input.Gamepad;
import nuc.input.Touch;
import nuc.input.Pen;
import nuc.utils.Log;
import nuc.events.*;

// TODO: bindings for touches

@:allow(nuc.Input)
class Bindings {

	public var active(default, null):Bool = false;

	@:noCompletion public var inputEvent:InputEvent;

	var _inputPressed:Map<String, Int>;
	var _inputReleased:Map<String, Int>;
	var _inputDown:Map<String, Int>;

	var _dirty:Bool = false;

	public function new() {}

	public function enable() {
		if(active) return;
		
		_inputPressed = new Map();
		_inputReleased = new Map();
		_inputDown = new Map();

		inputEvent = new InputEvent();
		
		active = true;
	}

	public function disable() {
		if(!active) return;

		_inputPressed = null;
		_inputReleased = null;
		_inputDown = null;

		inputEvent = null;

		active = false;
	}

	public function pressed(key:String):Bool {
		return _inputPressed.exists(key);
	}

	public function released(key:String):Bool {
		return _inputReleased.exists(key);
	}

	public function down(key:String):Bool {
		return _inputDown.exists(key);
	}

	function reset() {
		if(_dirty) {
			Log.debug("reset");
			for (k in _inputPressed.keys()) {
				_inputPressed.remove(k);
			}
			for (k in _inputReleased.keys()) {
				_inputReleased.remove(k);
			}
			_dirty = false;
		}
	}

	inline function addPressed(name:String) {
		var n:Int = 0;
		if(_inputPressed.exists(name)) {
			n = _inputPressed.get(name);
		}
		_inputPressed.set(name, ++n);
	}

	inline function addDown(name:String) {
		var n:Int = 0;
		if(_inputDown.exists(name)) {
			n = _inputDown.get(name);
		}
		_inputDown.set(name, ++n);
	}

	inline function addReleased(name:String) {
		var n:Int = 0;
		if(_inputReleased.exists(name)) {
			n = _inputReleased.get(name);
		}
		_inputReleased.set(name, ++n);
	}

	inline function removePressed(name:String) {
		if(_inputPressed.exists(name)) {
			var n = _inputPressed.get(name);
			if(--n <= 0) {
				_inputPressed.remove(name);
			}
		}
	}

	inline function removeDown(name:String) {
		if(_inputDown.exists(name)) {
			var n = _inputDown.get(name);
			if(--n <= 0) {
				_inputDown.remove(name);
			}
		}
	}

	inline function removeReleased(name:String) {
		if(_inputReleased.exists(name)) {
			var n = _inputReleased.get(name);
			if(--n <= 0) {
				_inputReleased.remove(name);
			}
		}
	}

	@:noCompletion public function removeAll(name:String) {
		removePressed(name);
		removeDown(name);
		removeReleased(name);
	}

	@:noCompletion public function inputPressed() {
		Log.debug('inputPressed');

		_dirty = true;

		addPressed(inputEvent.name);
		addDown(inputEvent.name);

		Nuc.app.emitter.emit(InputEvent.INPUT_DOWN, inputEvent);
	}

	@:noCompletion public function inputReleased() {
		Log.debug('inputReleased');

		_dirty = true;

		addReleased(inputEvent.name);
		removePressed(inputEvent.name);
		removeDown(inputEvent.name);

		Nuc.app.emitter.emit(InputEvent.INPUT_UP, inputEvent);
	}

}
