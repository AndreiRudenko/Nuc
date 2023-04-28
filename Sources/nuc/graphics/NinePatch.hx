package nuc.graphics;

class NinePatch {

	public var visible:Bool = true;

	public var color:Color = Color.WHITE;

	public var x(get, set):Float;
	var _x:Float;
	inline function get_x() return _x;
	function set_x(v) {
		dirty = true;
		return _x = v;
	}

	public var y(get, set):Float;
	var _y:Float;
	inline function get_y() return _y;
	function set_y(v) {
		dirty = true;
		return _y = v;
	}

	public var width(get, set):Float;
	var _width:Float;
	inline function get_width() return _width;
	function set_width(v) {
		dirty = true;
		return _width = v;
	}

	public var height(get, set):Float;
	var _height:Float;
	inline function get_height() return _height;
	function set_height(v) {
		dirty = true;
		return _height = v;
	}

	public var scale(get, set):Float;
	var _scale:Float = 1;
	inline function get_scale() return _scale;
	function set_scale(v) {
		dirty = true;
		return _scale = v;
	}

	public var left(get, set):Float;
	var _left:Float;
	inline function get_left() return _left;
	function set_left(v) {
		dirty = true;
		return _left = v;
	}

	public var right(get, set):Float;
	var _right:Float;
	inline function get_right() return _right;
	function set_right(v) {
		dirty = true;
		return _right = v;
	}

	public var top(get, set):Float;
	var _top:Float;
	inline function get_top() return _top;
	function set_top(v) {
		dirty = true;
		return _top = v;
	}

	public var bottom(get, set):Float;
	var _bottom:Float;
	inline function get_bottom() return _bottom;
	function set_bottom(v) {
		dirty = true;
		return _bottom = v;
	}

	public var rotation(get, set):Float;
	var _rotation:Float = 0;
	inline function get_rotation() return _rotation;
	function set_rotation(v) {
		dirty = true;
		return _rotation = v;
	}

	public var texture(get, set):Texture;
	var _texture:Texture;
	inline function get_texture() return _texture;
	function set_texture(v) {
		dirty = true;
		return _texture = v;
	}

	var dirty:Bool = true;
	
	var leftScaled:Float;
	var rightScaled:Float;
	var topScaled:Float;
	var bottomScaled:Float;
	
	var midLeft:Float;
	var midRight:Float;
	var midTop:Float;
	var midBottom:Float;
	var midWidth:Float;
	var midHeight:Float;

	var texMidRight:Float;
	var texMidBottom:Float;
	var texMidWidth:Float;
	var texMidHeight:Float;

	public function new(texture:Texture, left:Float, right:Float, top:Float, bottom:Float) {
		_texture = texture;
		_left = left;
		_right = right;
		_top = top;
		_bottom = bottom;
	}

	function calcPatches() {
		leftScaled = left * scale;
		rightScaled = right * scale;
		topScaled = top * scale;
		bottomScaled = bottom * scale;
	
		midLeft = x + leftScaled;
		midRight = x + width - rightScaled;
		
		midTop = y + topScaled;
		midBottom = y + height - bottomScaled;
	
		midWidth = midRight - midLeft;
		midHeight = midBottom - midTop;

		texMidRight = texture.width - right;
		texMidBottom = texture.height - bottom;
	
		texMidWidth = texMidRight - left;
		texMidHeight = texMidBottom - top;
	}

	public function draw(batch:SpriteBatch) {
		if (!visible) return;

		if (dirty) {
			calcPatches();
			dirty = false;
		}

		batch.color = color;

		if (rotation == 0) {
			batch.drawImage(texture, x, y, leftScaled, topScaled, 0, 0, left, top);
			batch.drawImage(texture, midLeft, y, midWidth, topScaled, left, 0, texMidWidth, top);
			batch.drawImage(texture, midRight, y, rightScaled, topScaled, texMidRight, 0, right, top);

			batch.drawImage(texture, x, midTop, leftScaled, midHeight, 0, top, left, texMidHeight);
			batch.drawImage(texture, midLeft, midTop, midWidth, midHeight, left, top, texMidWidth, texMidHeight);
			batch.drawImage(texture, midRight, midTop, rightScaled, midHeight, texMidRight, top, right, texMidHeight);

			batch.drawImage(texture, x, midBottom, leftScaled, bottomScaled, 0, texMidBottom, left, bottom);
			batch.drawImage(texture, midLeft, midBottom, midWidth, bottomScaled, left, texMidBottom, texMidWidth, bottom);
			batch.drawImage(texture, midRight, midBottom, rightScaled, bottomScaled, texMidRight, texMidBottom, right, bottom);
		} else {
			batch.drawImage(texture, x, y, leftScaled, topScaled, rotation, 0, 0, 0, 0, 0, 0, left, top);
			batch.drawImage(texture, midLeft, y, midWidth, topScaled, rotation, 0, 0, 0, 0, left, 0, texMidWidth, top);
			batch.drawImage(texture, midRight, y, rightScaled, topScaled, rotation, 0, 0, 0, 0, texMidRight, 0, right, top);

			batch.drawImage(texture, x, midTop, leftScaled, midHeight, rotation, 0, 0, 0, 0, 0, top, left, texMidHeight);
			batch.drawImage(texture, midLeft, midTop, midWidth, midHeight, rotation, 0, 0, 0, 0, left, top, texMidWidth, texMidHeight);
			batch.drawImage(texture, midRight, midTop, rightScaled, midHeight, rotation, 0, 0, 0, 0, texMidRight, top, right, texMidHeight);

			batch.drawImage(texture, x, midBottom, leftScaled, bottomScaled, rotation, 0, 0, 0, 0, 0, texMidBottom, left, bottom);
			batch.drawImage(texture, midLeft, midBottom, midWidth, bottomScaled, rotation, 0, 0, 0, 0, left, texMidBottom, texMidWidth, bottom);
			batch.drawImage(texture, midRight, midBottom, rightScaled, bottomScaled, rotation, 0, 0, 0, 0, texMidRight, texMidBottom, right, bottom);
		}
	}

}