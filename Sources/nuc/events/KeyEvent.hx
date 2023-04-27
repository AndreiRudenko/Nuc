package nuc.events;

import nuc.events.EventType;

@:allow(nuc.input.Keyboard)
class KeyEvent {

	static public inline var KEY_UP:EventType<KeyEvent> = 'KEY_UP';
	static public inline var KEY_DOWN:EventType<KeyEvent> = 'KEY_DOWN';
	static public inline var TEXT_INPUT:EventType<String> = 'TEXT_INPUT';

    public var key(default, null):Int;
	public var state(default, null):EventType<KeyEvent> = KeyEvent.KEY_UP;

	public function new() {}

	public function set(key:Int, state:EventType<KeyEvent>) {
		this.key = key;
		this.state = state;
	}

}
