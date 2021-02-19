package nuc.input;

import nuc.utils.BitVector;
import nuc.input.Key;
import nuc.utils.Log;
import nuc.events.KeyEvent;
import nuc.App;

@:allow(nuc.Input)
class Keyboard {

	public var active(default, null):Bool = false;

	var _keyCodePressed:BitVector;
	var _keyCodeReleased:BitVector;
	var _keyCodeDown:BitVector;

	var _keyEvent:KeyEvent;
	var _dirty:Bool = false;

	var _keyBindings:Map<String, Map<Int, Bool>>;
	var _binding:Bindings;

	public function new() {
		_keyBindings = new Map();
		_binding = Nuc.input.binding;
	}

	public function enable() {
		if(active) return;
		
		#if nuc_keyboard_input
		var k = kha.input.Keyboard.get();
		if(k != null) k.notify(onKeyPressed, onKeyReleased, onTextInput);
		#end
		
		_keyCodePressed = new BitVector(256);
		_keyCodeReleased = new BitVector(256);
		_keyCodeDown = new BitVector(256);

		_keyEvent = new KeyEvent();

		active = true;
	}

	public function disable() {
		if(!active) return;
		
		#if nuc_keyboard_input
		var k = kha.input.Keyboard.get();
		if(k != null) k.remove(onKeyPressed, onKeyReleased, onTextInput);
		#end

		_keyCodePressed = null;
		_keyCodeReleased = null;
		_keyCodeDown = null;

		_keyEvent = null;

		active = true;
	}

	public function pressed(key:Key):Bool {
		return _keyCodePressed.get(key);
	}

	public function released(key:Key):Bool {
		return _keyCodeReleased.get(key);
	}

	public function down(key:Key):Bool {
		return _keyCodeDown.get(key);
	}

	public function bind(name:String, key:Key) {
		var b = _keyBindings.get(name);
		if(b == null) {
			b = new Map<Int, Bool>();
			_keyBindings.set(name, b);
		}
		b.set(key, true);
	}

	public function unbind(name:String) {
		if(_keyBindings.exists(name)) {
			_keyBindings.remove(name);
			_binding.removeAll(name);
		}
	}

	function checkBinding(key:Int, pressed:Bool) {
		for (k in _keyBindings.keys()) {
			if(_keyBindings.get(k).exists(key)) {
				_binding.inputEvent.setKeyEvent(k, _keyEvent);
				if(pressed) {
					_binding.inputPressed();
				} else {
					_binding.inputReleased();
				}
				return;
			}
		}
	}

	function reset() {
		#if nuc_keyboard_input
		if(_dirty) {
			Log.debug("reset");
			_keyCodePressed.disableAll();
			_keyCodeReleased.disableAll();
			_dirty = false;
		}
		#end
	}

	function onKeyPressed(key:Int) {
		Log.debug('onKeyPressed: $key');

		_dirty = true;

		_keyCodePressed.enable(key);
		_keyCodeDown.enable(key);

		_keyEvent.set(key, KeyEvent.KEY_DOWN);

		checkBinding(key, true);

		Nuc.app.emitter.emit(KeyEvent.KEY_DOWN, _keyEvent);
	}

	function onKeyReleased(key:Int) {
		Log.debug('onKeyReleased: $key');

		_dirty = true;

		_keyCodeReleased.enable(key);
		_keyCodePressed.disable(key);
		_keyCodeDown.disable(key);
		_keyEvent.set(key, KeyEvent.KEY_UP);

		checkBinding(key, false);

		Nuc.app.emitter.emit(KeyEvent.KEY_UP, _keyEvent);
	}
	
	function onTextInput(char:String) {
		Log.debug('onTextInput: $char');
		Nuc.app.emitter.emit(KeyEvent.TEXT_INPUT, char);
	}

}
