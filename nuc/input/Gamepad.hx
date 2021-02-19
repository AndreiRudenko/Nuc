package nuc.input;

import nuc.App;
import nuc.utils.Log;
import nuc.utils.Bits;
import nuc.events.GamepadEvent;

@:allow(nuc.Input)
class Gamepads {

	public var active(default, null):Bool = false;

	// TODO: need to figure out how gamepads is stored, and change map to array maybe
	var _gamepads:Map<Int, Gamepad>;
	var _gamepadEvent:GamepadEvent;

	var _gamepadBindings:Map<String, Map<Int, Int>>;
	var _binding:Bindings;

	public function new() {
		_gamepadBindings = new Map();
		_binding = Nuc.input.binding;
	}

	public function get(gamepad:Int):Gamepad {
		if(!active) return null;
		return _gamepads.get(gamepad);
	}

	public function enable() {
		if(active) return;

		_gamepads = new Map();

		#if nuc_gamepad_input
		kha.input.Gamepad.notifyOnConnect(onConnect, onDisconnect);
		#end 

		_gamepadEvent = new GamepadEvent();
		active = true;
	}

	public function disable() {
		if(!active) return;

		#if nuc_gamepad_input
		kha.input.Gamepad.removeConnect(onConnect, onDisconnect);
		for (g in _gamepads) {
			g.unlistenEvents();
		}
		#end 

		_gamepads = null;
		_gamepadEvent = null;
		active = false;
	}

	public function pressed(gamepad:Int, button:Int):Bool {
		var g = _gamepads.get(gamepad);
		return g != null ? g.pressed(button) : false;
	}

	public function released(gamepad:Int, button:Int):Bool {
		var g = _gamepads.get(gamepad);
		return g != null ? g.released(button) : false;
	}

	public function down(gamepad:Int, button:Int):Bool {
		var g = _gamepads.get(gamepad);
		return g != null ? g.down(button) : false;
	}

	public function axis(gamepad:Int, axis:Int):Float {
		var g = _gamepads.get(gamepad);
		return g != null ? g.axis(axis) : 0;
	}

	public function rumble(gamepad:Int, leftAmount:Float, rightAmount:Float) {
		var g = _gamepads.get(gamepad);
		if(g != null) g.rumble(leftAmount, rightAmount);
	}

	public function bind(name:String, gamepad:Int, button:Int) {
		var b = _gamepadBindings.get(name);

		if(b == null) {
			b = new Map();
			_gamepadBindings.set(name, b);
		}

		b.set(gamepad, button);
	}

	public function unbind(name:String) {
		if(_gamepadBindings.exists(name)) {
			_gamepadBindings.remove(name);
			_binding.removeAll(name);
		}
	}

	function checkBinding(gamepad:Int, button:Int, pressed:Bool) {
		for (k in _gamepadBindings.keys()) {
			var g = _gamepadBindings.get(k);
			if(g != null) {
				if(g.exists(gamepad)) {
					var n = g.get(gamepad);
					if(Bits.check(n, button)) {
						_binding.inputEvent.setGamepadEvent(k, _gamepadEvent);
						if(pressed) {
							_binding.inputPressed();
						} else {
							_binding.inputReleased();
						}
						return;
					}
				}
			}
		}
	}

	function reset() {
		#if nuc_gamepad_input
		for (g in _gamepads) {
			g.reset();
		}
		#end
	}

	function onConnect(gamepad:Int) {
		Log.debug('onConnect gamepad:$gamepad');
		Log.assert(!_gamepads.exists(gamepad), 'trying to add gamepad that already exists');

		var g = new Gamepad(gamepad, this);
		g.listenEvents();
		addGamepad(gamepad, g);

		_gamepadEvent.set(gamepad, g.id, -1, -1, 0, GamepadEvent.DEVICE_ADDED);

		Nuc.app.emitter.emit(GamepadEvent.DEVICE_ADDED, _gamepadEvent);
	}

	function onDisconnect(gamepad:Int) {
		Log.debug('onDisconnect gamepad:$gamepad');
		Log.assert(_gamepads.exists(gamepad), 'trying to remove gamepad that not exists');

		var g = getGamepad(gamepad);
		g.unlistenEvents();
		removeGamepad(gamepad);

		_gamepadEvent.set(gamepad, g.id, -1, -1, 0, GamepadEvent.DEVICE_REMOVED);
		
		Nuc.app.emitter.emit(GamepadEvent.DEVICE_REMOVED, _gamepadEvent);
	}

	inline function getGamepad(id:Int):Gamepad {
		return _gamepads.get(id);
	}

	inline function hasGamepad(id:Int):Bool {
		return _gamepads.exists(id);
	}

	inline function addGamepad(id:Int, g:Gamepad) {
		_gamepads.set(id, g);
	}

	inline function removeGamepad(id:Int) {
		_gamepads.remove(id);
	}

}

@:allow(nuc.input.Gamepads)
@:access(nuc.App, nuc.input.Gamepads)
class Gamepad {

	public var id(default, null):String;
	public var gamepad(default, null):Int;
	public var deadzone:Float = 0.15;

	var _buttonsPressed:UInt = 0;
	var _buttonsReleased:UInt = 0;
	var _buttonsDown:UInt = 0;

	var _axisID:Int = -1;
	var _axisValue:Float = 0;

	var _gamepadEvent:GamepadEvent;
	var _gamepads:Gamepads;

	function new(gamepad:Int, gamepads:Gamepads) {
		this.gamepad = gamepad;
		_gamepads = gamepads;
		id = kha.input.Gamepad.get(this.gamepad).id;
		_gamepadEvent = new GamepadEvent();
	}

	public inline function pressed(b:Int):Bool {
		return Bits.check(_buttonsPressed, b);
	}

	public inline function released(b:Int):Bool {
		return Bits.check(_buttonsReleased, b);
	}

	public inline function down(b:Int):Bool {
		return Bits.check(_buttonsDown, b);
	}

	public inline function axis(a:Int):Float {
		if(a == _axisID) return _axisValue;
		return 0;
	}

	public function rumble(leftAmount:Float, rightAmount:Float) {
		// kha.input.Gamepad.get(gamepad).rumble(leftAmount, rightAmount);
	}

	function listenEvents() {
		kha.input.Gamepad.get(gamepad).notify(onAxis, onButton);
	}

	function unlistenEvents() {
		kha.input.Gamepad.get(gamepad).remove(onAxis, onButton);
	}

	function reset() {
		_buttonsPressed = 0;
		_buttonsReleased = 0;
		_axisID = -1;
		_axisValue = 0;
	}

	function onAxis(a:Int, v:Float) {
		if(Math.abs(v) < deadzone) return;
		
		Log.debug('onAxis gamepad:$gamepad, axis:$a, value:$v');

		_axisID = a;
		_axisValue = v;

		_gamepadEvent.set(gamepad, id, -1, _axisID, _axisValue, GamepadEvent.AXIS);

		Nuc.app.emitter.emit(GamepadEvent.AXIS, _gamepadEvent);
	}

	function onButton(b:Int, v:Float) {
		Log.debug('onButton gamepad:$gamepad, button:$b, value:$v');

		if(v > 0.5) {
			onPressed(b);
		} else {
			onReleased(b);
		}
	}

	inline function onPressed(b:Int) {
		Log.debug('onPressed gamepad:$gamepad, button:$b');

		_buttonsPressed = Bits.set(_buttonsPressed, b);
		_buttonsDown = Bits.set(_buttonsDown, b);

		_gamepadEvent.set(gamepad, id, b, -1, 0, GamepadEvent.BUTTON_DOWN);

		_gamepads.checkBinding(gamepad, b, true);
		Nuc.app.emitter.emit(GamepadEvent.BUTTON_DOWN, _gamepadEvent);
	}

	inline function onReleased(b:Int) {
		Log.debug('onReleased gamepad:$gamepad, button:$b');

		_buttonsPressed = Bits.clear(_buttonsPressed, b);
		_buttonsDown = Bits.clear(_buttonsDown, b);
		_buttonsReleased = Bits.set(_buttonsReleased, b);

		_gamepadEvent.set(gamepad, id, b, -1, 0, GamepadEvent.BUTTON_UP);

		_gamepads.checkBinding(gamepad, b, false);
		Nuc.app.emitter.emit(GamepadEvent.BUTTON_UP, _gamepadEvent);
	}

}