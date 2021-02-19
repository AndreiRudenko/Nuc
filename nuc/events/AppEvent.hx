package nuc.events;

import nuc.utils.EventType;

class AppEvent implements IEvent {

	static public inline var TICKSTART:EventType<AppEvent>;
	static public inline var TICKEND:EventType<AppEvent>;

	static public inline var UPDATE:EventType<Float>;
	static public inline var FIXEDUPDATE:EventType<Float>;

	static public inline var TIMESCALE:EventType<Float>;

	static public inline var FOREGROUND:EventType<AppEvent>;
	static public inline var BACKGROUND:EventType<AppEvent>;
	static public inline var PAUSE:EventType<AppEvent>;
	static public inline var RESUME:EventType<AppEvent>;

	@:allow(nuc.App)
	function new() {}

}
