package nuc.graphics;

import nuc.graphics.Texture;

class TextureRegion {

	public var texture:Texture;
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;
	
	public function new(texture:Texture, x:Float, y:Float, width:Float, height:Float) {
		this.texture = texture;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

}