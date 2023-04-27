package nuc.events;

import nuc.events.EventType;

@:allow(nuc.input.Pen)
class PenEvent {

	static public inline var PEN_UP:EventType<PenEvent> = 'PEN_UP';
	static public inline var PEN_DOWN:EventType<PenEvent> = 'PEN_DOWN';
	static public inline var PEN_MOVE:EventType<PenEvent> = 'PEN_MOVE';

	public var x(default, null):Float = 0;
	public var y(default, null):Float = 0;
	public var dx(default, null):Float = 0;
	public var dy(default, null):Float = 0;

	public var pressure(default, null):Float = 0;
	public var state(default, null):EventType<PenEvent> = PenEvent.PEN_UP;

	public function new() {}

	public function set(x:Float, y:Float, dx:Float, dy:Float, state:EventType<PenEvent>, pressure:Float) {
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
		this.state = state;
		this.pressure = pressure;
	}

}
