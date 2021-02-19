package nuc.events;

import nuc.utils.EventType;

@:allow(nuc.input.Keyboard)
class KeyEvent implements IEvent {

	static public inline var KEY_UP:EventType<KeyEvent>;
	static public inline var KEY_DOWN:EventType<KeyEvent>;
	static public inline var TEXT_INPUT:EventType<String>;

    public var key(default, null):Int;
	public var state(default, null):EventType<KeyEvent> = KeyEvent.KEY_UP;

	function new() {}

	function set(key:Int, state:EventType<KeyEvent>) {
		this.key = key;
		this.state = state;
	}

}
