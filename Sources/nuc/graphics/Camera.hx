package nuc.graphics;

import nuc.math.Vector2;
import nuc.utils.Math;
import nuc.math.Affine;
import nuc.math.Rectangle;
import nuc.graphics.Color;
import nuc.Graphics;
import nuc.utils.Log;

class Camera {
	
	static public var current:Camera = null;

	public var target(default, null):Texture;
	public var clearColor:Color = Color.TRANSPARENT;
	
	@:allow(nuc.graphics.Batch)
	public var renderCalls(default, null):Int = 0;

	public var x(get, set):Float;
	var _x:Float = 0;
	inline function get_x() return _x;
	function set_x(v) {
		dirty = true;
		return _x = v;
	}

	public var y(get, set):Float;
	var _y:Float = 0;
	inline function get_y() return _y;
	function set_y(v) {
		dirty = true;
		return _y = v;
	}

	public var width(get, set):Float;
	var _width:Float = 0;
	inline function get_width() return _width;
	function set_width(v) {
		dirty = true;
		return _width = v;
	}

	public var height(get, set):Float;
	var _height:Float = 0;
	inline function get_height() return _height;
	function set_height(v) {
		dirty = true;
		return _height = v;
	}

	public var anchorX(get, set):Float;
	var _anchorX:Float = 0.5;
	inline function get_anchorX() return _anchorX;
	function set_anchorX(v) {
		dirty = true;
		return _anchorX = v;
	}

	public var anchorY(get, set):Float;
	var _anchorY:Float = 0.5;
	inline function get_anchorY() return _anchorY;
	function set_anchorY(v) {
		dirty = true;
		return _anchorY = v;
	}

	public var rotation(get, set):Float;
	var _rotation:Float = 0;
	inline function get_rotation() return _rotation;
	function set_rotation(v) {
		dirty = true;
		return _rotation = v;
	}

	public var zoom(get, set):Float;
	var _zoom:Float = 1;
	inline function get_zoom() return _zoom;
	function set_zoom(v) {
		dirty = true;
		return _zoom = v;
	}

	public var viewX(get, set):Int;
	var _viewX:Int = 0;
	inline function get_viewX() return _viewX;
	function set_viewX(v) {
		dirty = true;
		return _viewX = v;
	}

	public var viewY(get, set):Int;
	var _viewY:Int = 0;
	inline function get_viewY() return _viewY;
	function set_viewY(v) {
		dirty = true;
		return _viewY = v;
	}

	public var viewWidth(get, set):Int;
	var _viewWidth:Int = 0;
	inline function get_viewWidth() return _viewWidth;
	function set_viewWidth(v) {
		dirty = true;
		return _viewWidth = v;
	}

	public var viewHeight(get, set):Int;
	var _viewHeight:Int = 0;
	inline function get_viewHeight() return _viewHeight;
	function set_viewHeight(v) {
		dirty = true;
		return _viewHeight = v;
	}

	public var scaleMode(get, set):ScaleMode;
	var _scaleMode:ScaleMode = ScaleMode.None;
	inline function get_scaleMode() return _scaleMode;
	function set_scaleMode(v) {
		dirty = true;
		return _scaleMode = v;
	}

	public var useScissors(get, set):Bool;
	var _useScissors:Bool = true;
	inline function get_useScissors() return _useScissors;
	function set_useScissors(v) {
		dirty = true;
		return _useScissors = v;
	}

	public final matrix:Affine;
	@:allow(nuc.graphics.Batch)
	var projectionViewMatrix:Affine = new Affine();

	var offsetX:Float = 0;
	var offsetY:Float = 0;

	var dirty:Bool = true;
	var hasBegin:Bool = false;

	public function new(width:Float, height:Float) {
		this.width = width;
		this.height = height;

		matrix = new Affine();

		_viewX = 0;
		_viewY = 0;
		_viewWidth = Window.width;
		_viewHeight = Window.height;
	}

	public function begin(clear:Bool = true, ?target:Texture) {
		Log.assert(Camera.current == null, 'Camera is already in use, call end() first before calling begin()');
		
		Camera.current = this;
		this.target = target;
		hasBegin = true;

		Graphics.begin(target);
		if(clear) Graphics.clear(clearColor);
		if(_useScissors) Graphics.scissor(viewX, viewY, viewWidth, viewHeight);

		update(true);

		renderCalls = 0;
	}

	public function end() {
		Log.assert(hasBegin, 'Camera is not in use, call begin() first before calling end()');

		if(Batch.current != null) Batch.current.end();
		if(_useScissors) Graphics.disableScissor();
		Graphics.end();
		
		target = null;
		Camera.current = null;
		hasBegin = false;
	}

	public function update(force:Bool = false) {
		if (!dirty && !force) return;

		var scaleX:Float = 1.0;
		var scaleY:Float = 1.0;
		
		offsetX = 0;
		offsetY = 0;

		switch (scaleMode) {
			case Fit(horizontalAlign, verticalAlign):
				scaleX = Math.min(viewWidth / width, viewHeight / height);
				scaleY = scaleX;
				calcOffset(horizontalAlign, verticalAlign, scaleX, scaleY);
			case Fill(horizontalAlign, verticalAlign):
				scaleX = Math.max(viewWidth / width, viewHeight / height);
				scaleY = scaleX;
				calcOffset(horizontalAlign, verticalAlign, scaleX, scaleY);
			case Stretch:
				scaleX = viewWidth / width;
				scaleY = viewHeight / height;
			default:
		}

		final originX = viewWidth * anchorX;
		final originY = viewHeight * anchorY;

		offsetX += viewX;
		offsetY += viewY;

		matrix.identity();
		matrix.translate(originX, originY);
		matrix.scale(zoom, zoom);
		if (rotation != 0) matrix.rotate(Math.radians(rotation));
		matrix.prependTranslate(-(x + originX) + offsetX, -(y + originY) + offsetY);
		matrix.scale(scaleX, scaleY);

		setupMatrices();

		dirty = false;
	}
	
	public function screenToWorld(screenCoords:Vector2, ?into:Vector2):Vector2 {
		update();

		if (into == null) into = new Vector2();

		into.copyFrom(screenCoords);
		into.inverseTransformFromAffine(matrix);

		return into;
	}

	public function worldToScreen(worldCoords:Vector2, ?into:Vector2):Vector2 {
		update();

		if (into == null) into = new Vector2();

		into.copyFrom(worldCoords);
		into.transformFromAffine(matrix);
		
		return into;
	}

	public function containsPoint(px:Float, py:Float):Bool {
		update();

        final sPosX = matrix.getTransformX(px, py);
		final sPosY = matrix.getTransformY(px, py);

		return sPosX >= _viewX && sPosX <= _viewX + _viewWidth && 
			sPosY >= _viewY && sPosY <= _viewY + _viewHeight;
	}

	public function containsRectangle(rx:Float, ry:Float, rWidth:Int, rHeight:Int):Bool {
		update();

        final sPosX = matrix.getTransformX(rx, ry);
		final sPosY = matrix.getTransformY(rx, ry);
        final sWidth = rWidth * matrix.a;
        final sHeight = rHeight * matrix.d;

		return sPosX + sWidth >= _viewX && sPosX <= _viewX + _viewWidth && 
			sPosY + sHeight >= _viewY && sPosY <= _viewY + _viewHeight;
    }

	public function setView(x:Int, y:Int, width:Int, height:Int) {
		_viewX = x;
		_viewY = y;
		_viewWidth = width;
		_viewHeight = height;
		dirty = true;
	}

	function calcOffset(horizontalAlign:ScaleModeAlign, verticalAlign:ScaleModeAlign, scaleX:Float, scaleY:Float) {
		switch (horizontalAlign) {
			case ScaleModeAlign.Left:
				offsetX = 0;
			case ScaleModeAlign.Right:
				offsetX = viewWidth - width * scaleX;
			case ScaleModeAlign.Center:
				offsetX = (viewWidth - width * scaleX) / 2;
			default:
		}
		switch (verticalAlign) {
			case ScaleModeAlign.Top:
				offsetY = 0;
			case ScaleModeAlign.Bottom:
				offsetY = viewHeight - height * scaleY;
			case ScaleModeAlign.Center:
				offsetY = (viewHeight - height * scaleY) / 2;
			default:
		}
	}

	function setupMatrices() {
		if (target == null) {
			projectionViewMatrix.orthographic(0,Window.width,Window.height, 0);
		} else {
			var tw = target.widthActual;
			var th = target.heightActual;

			if (!Texture.nonPow2Supported) {
				tw = Math.getPowOf2(tw);
				th = Math.getPowOf2(th);
			}

			if (Texture.renderTargetsInvertedY) {
				projectionViewMatrix.orthographic(0, tw, 0, th);
			} else {
				projectionViewMatrix.orthographic(0, tw, th, 0);
			}
		}

		projectionViewMatrix.append(matrix);
	}

}

enum ScaleMode {
	Fill(horizontalAlign:ScaleModeAlign, verticalAlign:ScaleModeAlign);
	Fit(horizontalAlign:ScaleModeAlign, verticalAlign:ScaleModeAlign);
	Stretch;
	None;
}

enum abstract ScaleModeAlign(Int) {
	var Top;
	var Bottom;
	var Left;
	var Right;
	var Center;
}
