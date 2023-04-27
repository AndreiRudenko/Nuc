package nuc.audio;

interface AudioChannel {
	public function play():Void;
	public function pause():Void;
	public function stop():Void;

	public var length(get, null):Float; // Seconds
	private function get_length():Float;

	public var position(get, set):Float;
	private function get_position():Float;
	private function set_position(value:Float):Float;

	public var pan(get, set):Float;
	private function get_pan():Float;
	private function set_pan(value:Float):Float;

	public var playbackRate(get, set):Float;
	private function get_playbackRate():Float;
	private function set_playbackRate(value:Float):Float;

	public var volume(get, set):Float;
	private function get_volume():Float;
	private function set_volume(value:Float):Float;

	public var finished(get, null):Bool;
	private function get_finished():Bool;
}
