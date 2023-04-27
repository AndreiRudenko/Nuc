package nuc.events;

import nuc.events.EventType;

@:allow(nuc.Window)
class WindowEvent {

	static public inline var RESIZE:EventType<WindowEvent> = 'WINDOW_RESIZE';

	public var id(default, null):Int = 0;

	public var x(default, null):Int = 0;
	public var y(default, null):Int = 0;
	public var width(default, null):Int = 0;
	public var height(default, null):Int = 0;

	public function new() {}

	public function set(id:Int, x:Int, y:Int, width:Int, height:Int) {
		this.id = id;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

}
