package nuc.events;

import nuc.utils.EventType;

class InputEvent implements IEvent {

	static public inline var INPUT_UP:EventType<InputEvent>;
	static public inline var INPUT_DOWN:EventType<InputEvent>;

	public var name(default, null):String;
	public var type(default, null):InputType;

	public var mouse(default, null):MouseEvent;
	public var keyboard(default, null):KeyEvent;
	public var gamepad(default, null):GamepadEvent;

	@:allow(nuc.input.Bindings)
	function new() {
		name = "";
		type = InputType.NONE;
	}

	@:allow(nuc.input.Mouse)
	function setMouseEvent(name:String, event:MouseEvent) {
		this.name = name;
		type = InputType.MOUSE;
		mouse = event;
	}

	@:allow(nuc.input.Keyboard)
	function setKeyEvent(name:String, event:KeyEvent) {
		this.name = name;
		type = InputType.KEYBOARD;
		keyboard = event;
	}

	@:allow(nuc.input.Gamepads)
	function setGamepadEvent(name:String, event:GamepadEvent) {
		this.name = name;
		type = InputType.GAMEPAD;
		gamepad = event;
	}

}

enum abstract InputType(Int){
	var NONE;
	var MOUSE;
	var KEYBOARD;
	var GAMEPAD;
}

