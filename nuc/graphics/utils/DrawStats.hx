package nuc.graphics.utils;

class DrawStats {

	public var drawCalls:Int = 0;
	public var vertices:Int = 0;
	public var indices:Int = 0;

	public var geometry:Int = 0;
	public var textureSwitchCount:Int = 0;

	public function new() {}

	public function reset() {
		drawCalls = 0;
		vertices = 0;
		indices = 0;
		geometry = 0;
		textureSwitchCount = 0;
	}

}
