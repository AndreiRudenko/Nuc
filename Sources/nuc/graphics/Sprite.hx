package nuc.graphics;

import nuc.graphics.Color;
import nuc.graphics.Texture;

class Sprite {

	public var visible:Bool = true;

	public var x:Float;
	public var y:Float;

	public var width:Float;
	public var height:Float;

	public var originX:Float;
	public var originY:Float;

	public var rotation:Float;

	public var scaleX:Float;
	public var scaleY:Float;

	public var regionX(default, set):Float = 0;
	function set_regionX(v) {
		dirty = true;
		return regionX = v;
	}

	public var regionY(default, set):Float = 0;
	function set_regionY(v) {
		dirty = true;
		return regionY = v;
	}

	public var regionWidth(default, set):Float = 1;
	function set_regionWidth(v) {
		dirty = true;
		return regionWidth = v;
	}

	public var regionHeight(default, set):Float = 1;
	function set_regionHeight(v) {
		dirty = true;
		return regionHeight = v;
	}

	public var flipX(default, set):Bool = false;
	function set_flipX(v) {
		dirty = true;
		return flipX = v;
	}

	public var flipY(default, set):Bool = false;
	function set_flipY(v) {
		dirty = true;
		return flipY = v;
	}

	public var color:Color;

	public var texture(default, set):Texture;
	function set_texture(v) {
		dirty = true;
		return texture = v;
	}

	var rx:Float;
	var ry:Float;
	var rw:Float;
	var rh:Float;

	var dirty:Bool = true;

	public function new(?texture:Texture, width:Float = 32, height:Float = 32) {
		this.texture = texture;

		this.width = width;
		this.height = height;

		color = new Color(1, 1, 1, 1);

		rotation = 0;

		scaleX = 1;
		scaleY = 1;

		originX = width / 2;
		originY = height / 2;
	}

	public function draw(b:SpriteBatch) {
		if (!visible) return;

		if (dirty) {
			updateRegion();
			dirty = false;
		}

		b.color = color;

		if (rotation == 0) {
			b.drawImage(texture, x - originX, y - originY, width, height, rx, ry, rw, rh);
		} else {
			b.drawImage(texture, x, y, width, height, rotation, originX, originY, 0, 0, rx, ry, rw, rh);
		}
	}

	public function updateRegion() {
		rx = regionX * texture.width;
		ry = regionY * texture.height;
		rw = regionWidth * texture.width;
		rh = regionHeight * texture.height;

		if (flipX) {
			rx = rw;
			rw = -rw;
		}

		if (flipY) {
			ry = rh;
			rh = -rh;
		}

	}
	
}



