package nuc.input;

import nuc.utils.BitVector;
import nuc.input.Key;
import nuc.utils.Log;
import nuc.events.KeyEvent;
import nuc.App;

@:allow(nuc.App)
class Keyboard {

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

	static var keyCodeDown:BitVector;

	static var keyEvent:KeyEvent;
	static var dirty:Bool = false;

	static function init() {
		keyCodeDown = new BitVector(256);
		keyEvent = new KeyEvent();
		enabled = true;
	}

	static public function enable() {
		#if !nuc_no_keyboard_input
		final k = kha.input.Keyboard.get();
		if(k != null) k.notify(onKeyPressed, onKeyReleased, onTextInput);
		#end
	}

	static function disable() {
		#if !nuc_no_keyboard_input
		final k = kha.input.Keyboard.get();
		if(k != null) k.remove(onKeyPressed, onKeyReleased, onTextInput);
		#end

		keyCodeDown.disableAll();
	}

	static public function show() {
		if (!enabled) return;
		#if !nuc_no_keyboard_input
		final k = kha.input.Keyboard.get();
		k.show();
		#end
	}

	static public function hide() {
		if (!enabled) return;
		#if !nuc_no_keyboard_input
		final k = kha.input.Keyboard.get();
		k.hide();
		#end
	}

	static public function down(key:Key):Bool {
		return keyCodeDown.get(key);
	}

	static function onKeyPressed(key:Int) {
		Log.debug('onKeyPressed: $key');

		keyCodeDown.enable(key);

		keyEvent.set(key, KeyEvent.KEY_DOWN);
		App.events.fire(KeyEvent.KEY_DOWN, keyEvent);
	}

	static function onKeyReleased(key:Int) {
		Log.debug('onKeyReleased: $key');

		keyCodeDown.disable(key);

		keyEvent.set(key, KeyEvent.KEY_UP);
		App.events.fire(KeyEvent.KEY_UP, keyEvent);
	}
	
	static function onTextInput(char:String) {
		Log.debug('onTextInput: $char');
		App.events.fire(KeyEvent.TEXT_INPUT, char);
	}

}
