package nuc.input;

import nuc.App;
import nuc.utils.Log;
import nuc.utils.Bits;
import nuc.events.GamepadEvent;

@:allow(nuc.App)
class Gamepad {

	static var GAMEPADS_MAX:Int = 4;

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

	static var gamepads:Map<Int, Gamepad>;


	static public function init() {
		gamepads = new Map();
		enabled = true;
	}

	static public function get(index:Int):Gamepad {
		return gamepads.get(index);
	}

	static function enable() {
		#if !nuc_no_gamepad_input
		kha.input.Gamepad.notifyOnConnect(onGamepadConnect, onGamepadDisconnect);
		for (i in 0...GAMEPADS_MAX) {
			var g = kha.input.Gamepad.get(i);
			if (g != null && g.connected) {
				onGamepadConnect(i);
			}
		}
		#end 
	}

	static function disable() {
		#if !nuc_no_gamepad_input
		for (i in 0...GAMEPADS_MAX) {
			var g = kha.input.Gamepad.get(i);
			if (g != null && g.connected) {
				onGamepadDisconnect(i);
			}
		}
		kha.input.Gamepad.removeConnect(onGamepadConnect, onGamepadDisconnect);
		#end 

		gamepads.clear();
	}

	static function onGamepadConnect(index:Int) {
		Log.debug('onGamepadConnect gamepad:$index');
		Log.assert(!gamepads.exists(index), 'trying to add gamepad that already exists');

		var g = new Gamepad(index);
		gamepads.set(index, g);
		g.onConnect();
	}

	static function onGamepadDisconnect(index:Int) {
		Log.debug('onGamepadDisconnect gamepad:$index');
		Log.assert(gamepads.exists(index), 'trying to remove gamepad that not exists');

		var g = gamepads.get(index);
		g.onDisconnect();
		gamepads.remove(index);
	}

	public var id(default, null):String;
	public var index(default, null):Int;
	public var deadzone:Float = 0.15;

	var buttonsDown:UInt = 0;

	var gamepadEvent:GamepadEvent;

	function new(index:Int) {
		this.index = index;
		gamepads = gamepads;
		id = kha.input.Gamepad.get(this.index).id;
		gamepadEvent = new GamepadEvent();
	}

	public inline function isDown(b:Int):Bool {
		return Bits.check(buttonsDown, b);
	}

	public function rumble(leftAmount:Float, rightAmount:Float) {
		kha.input.Gamepad.get(index).rumble(leftAmount, rightAmount);
	}

	function onConnect() {
		kha.input.Gamepad.get(index).notify(onAxis, onButton);
		gamepadEvent.set(index, id, -1, -1, 0, GamepadEvent.DEVICE_ADDED);
		App.events.fire(GamepadEvent.DEVICE_ADDED, gamepadEvent);
	}

	function onDisconnect() {
		gamepadEvent.set(index, id, -1, -1, 0, GamepadEvent.DEVICE_REMOVED);
		App.events.fire(GamepadEvent.DEVICE_REMOVED, gamepadEvent);

		kha.input.Gamepad.get(index).remove(onAxis, onButton);
	}

	function onAxis(a:Int, v:Float) {
		if(Math.abs(v) < deadzone) return;
		
		Log.debug('onAxis gamepad:$index, axis:$a, value:$v');

		gamepadEvent.set(index, id, -1, a, v, GamepadEvent.AXIS);

		App.events.fire(GamepadEvent.AXIS, gamepadEvent);
	}

	function onButton(b:Int, v:Float) {
		Log.debug('onButton gamepad:$index, button:$b, value:$v');

		if(v > 0.5) {
			onPressed(b);
		} else {
			onReleased(b);
		}
	}

	inline function onPressed(b:Int) {
		Log.debug('onPressed gamepad:$index, button:$b');

		buttonsDown = Bits.set(buttonsDown, b);

		gamepadEvent.set(index, id, b, -1, 0, GamepadEvent.BUTTON_DOWN);

		App.events.fire(GamepadEvent.BUTTON_DOWN, gamepadEvent);
	}
	
	// TODO: Fix on HTML5 target, when controller is connected, and you press button, after connection event, goes buttonPressed
	// and then for all buttons it sends event buttonReleased
	inline function onReleased(b:Int) {
		Log.debug('onReleased gamepad:$index, button:$b');

		buttonsDown = Bits.clear(buttonsDown, b);

		gamepadEvent.set(index, id, b, -1, 0, GamepadEvent.BUTTON_UP);

		App.events.fire(GamepadEvent.BUTTON_UP, gamepadEvent);
	}

}