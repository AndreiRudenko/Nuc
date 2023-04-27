package nuc.events;

import nuc.events.EventType;

class AppEvent {

	static public inline var INIT:EventType<AppEvent> = 'APP_INIT';
	static public inline var SHUTDOWN:EventType<AppEvent> = 'APP_SHUTDOWN';

	static public inline var UPDATE:EventType<Float> = 'APP_UPDATE';

	static public inline var FOREGROUND:EventType<AppEvent> = 'APP_FOREGROUND';
	static public inline var BACKGROUND:EventType<AppEvent> = 'APP_BACKGROUND';
	static public inline var PAUSE:EventType<AppEvent> = 'APP_PAUSE';
	static public inline var RESUME:EventType<AppEvent> = 'APP_RESUME';

	@:allow(nuc.App)
	public function new() {}

}
