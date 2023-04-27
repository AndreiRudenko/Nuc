package nuc.events;

import nuc.events.EventType;

@:allow(nuc.input.Gamepad, nuc.input.Gamepads)
class GamepadEvent {

	static public inline var BUTTON_UP:EventType<GamepadEvent> = 'GAMEPAD_BUTTON_UP';
	static public inline var BUTTON_DOWN:EventType<GamepadEvent> = 'GAMEPAD_BUTTON_DOWN';
	static public inline var AXIS:EventType<GamepadEvent> = 'GAMEPAD_AXIS';
	static public inline var DEVICE_ADDED:EventType<GamepadEvent> = 'GAMEPAD_DEVICE_ADDED';
	static public inline var DEVICE_REMOVED:EventType<GamepadEvent> = 'GAMEPAD_DEVICE_REMOVED';

	public var id(default, null):String;
	public var gamepad(default, null):Int;

	public var button(default, null):Int;
	public var axis(default, null):Int;
	public var value(default, null):Float;

	public var state(default, null):EventType<GamepadEvent>;

	public function new() {}

	public function set(gamepad:Int, id:String, button:Int, axisID:Int, value:Float, state:EventType<GamepadEvent>) {
		this.id = id;
		this.gamepad = gamepad;
		this.button = button;
		this.axis = axisID;
		this.value = value;
		this.state = state;
	}

}