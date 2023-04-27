package nuc.events;

import nuc.events.EventType;

@:allow(nuc.input.Touch)
class TouchEvent {

	static public inline var TOUCH_UP:EventType<TouchEvent> = 'TOUCH_UP';
	static public inline var TOUCH_DOWN:EventType<TouchEvent> = 'TOUCH_DOWN';
	static public inline var TOUCH_MOVE:EventType<TouchEvent> = 'TOUCH_MOVE';

	public var id(default, null):Int = 0;

	public var x(default, null):Float = 0;
	public var y(default, null):Float = 0;
	public var dx(default, null):Float = 0;
	public var dy(default, null):Float = 0;

	// public var touches(default, null):Array<Touch>;

	public var state(default, null):EventType<TouchEvent> = TouchEvent.TOUCH_UP;

	public function new(id:Int) {
		this.id = id;
	}

	public function set(x:Float, y:Float, dx:Float, dy:Float, state:EventType<TouchEvent>) {
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
		this.state = state;
	}

}
