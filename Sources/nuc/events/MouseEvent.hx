package nuc.events;

import nuc.events.EventType;

@:allow(nuc.input.Mouse)
class MouseEvent {

	static public inline var MOUSE_UP:EventType<MouseEvent> = 'MOUSE_UP';
	static public inline var MOUSE_DOWN:EventType<MouseEvent> = 'MOUSE_DOWN';
	static public inline var MOUSE_MOVE:EventType<MouseEvent> = 'MOUSE_MOVE';
	static public inline var MOUSE_WHEEL:EventType<MouseEvent> = 'MOUSE_WHEEL';

	public var x(default, null):Float = 0;
	public var y(default, null):Float = 0;
	public var dx(default, null):Float = 0;
	public var dy(default, null):Float = 0;
	public var wheel(default, null):Float = 0;

	public var button(default, null):MouseButton = MouseButton.NONE;
	public var state(default, null):EventType<MouseEvent> = MouseEvent.MOUSE_UP;

	public function new() {}

	public function set(x:Float, y:Float, dx:Float, dy:Float, wheel:Int, state:EventType<MouseEvent>, button:MouseButton) {
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
		this.wheel = wheel;
		this.state = state;
		this.button = button;
	}

}

enum abstract MouseButton(Int) from Int to Int {
    var NONE = -1;
    var LEFT = 0;
    var RIGHT = 1;
    var MIDDLE = 2;
    var EXTRA1 = 3;
    var EXTRA2 = 4;
    var EXTRA3 = 5;
    var EXTRA4 = 6;
}
