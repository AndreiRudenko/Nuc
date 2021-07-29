package nuc.graphics;

import nuc.Nuc;
import nuc.graphics.Texture;
import nuc.graphics.Color;

import nuc.Graphics;
import nuc.graphics.VertexBuffer;
import nuc.graphics.IndexBuffer;
import nuc.graphics.Pipeline;
import nuc.graphics.VertexStructure;
import nuc.graphics.Shaders;

import nuc.math.FastMatrix3;
import nuc.math.Vector2;
import nuc.math.FastVector2;
import nuc.math.Rectangle;

import nuc.utils.DynamicPool;
import nuc.utils.Math;
import nuc.utils.Float32Array;
import nuc.utils.Uint32Array;
import nuc.utils.FastFloat;
import nuc.utils.Log;


class Canvas {

	public var transform(get, set):FastMatrix3;
	var _transform:FastMatrix3 = new FastMatrix3();
	inline function get_transform() return _transform; 
	function set_transform(v:FastMatrix3):FastMatrix3 {
		return _transform.copyFrom(v);
	}

	var _transformStack:Array<FastMatrix3>;
	var _transformPool:DynamicPool<FastMatrix3>;

	var _invertseTransform:FastMatrix3;
	var _invertseTransformDirty:Bool = true;

	public function new() {
		_transformStack = [];
		_transformPool = new DynamicPool<FastMatrix3>(16, function() { return new FastMatrix3(); });
	}
	
	public function pushTransform(?m:FastMatrix3) {
		_transformStack.push(_transform);
		if(m == null) m = _transform;
		_transform = _transformPool.get();
		_transform.copyFrom(m);
		onTransformUpdate();
	}

	public function popTransform() {
		if(_transformStack.length > 0) {
			_transformPool.put(_transform);
			_transform = _transformStack.pop();
			onTransformUpdate();
		} else {
			Log.warning('pop transform with no transforms left in stack');
		}
	}

	public function applyTransform(m:FastMatrix3) {
		_transform.append(m);
		onTransformUpdate();
	}

	public function translate(x:FastFloat, y:FastFloat) {
		_transform.translate(x, y);
		onTransformUpdate();
	}

	public function prependTranslate(x:FastFloat, y:FastFloat) {
		_transform.prependTranslate(x, y);
		onTransformUpdate();
	}

	public function scale(x:FastFloat, y:FastFloat) {
		_transform.scale(x, y);
		onTransformUpdate();
	}

	public function rotate(radians:FastFloat, ox:FastFloat = 0, oy:FastFloat = 0) {
		if(radians == 0) return;
		
		if(ox != 0 || oy != 0) {
			var m = new FastMatrix3();
			m.translate(ox, oy)
			.rotate(radians)
			.prependTranslate(-ox, -oy)
			.append(_transform);
			_transform.copyFrom(m);
		} else {
			_transform.rotate(radians);
		}
		onTransformUpdate();
	}

	public function shear(x:FastFloat, y:FastFloat, ox:FastFloat = 0, oy:FastFloat = 0) {
		if(x == 0 && y == 0) return;

		if(ox != 0 || oy != 0) {
			var m = new FastMatrix3();
			m.translate(ox, oy)
			.shear(x, y)
			.prependTranslate(-ox, -oy)
			.append(_transform);
			_transform.copyFrom(m);
		} else {
			_transform.shear(x, y);	
		}
		onTransformUpdate();
	}

	public function inverseTransformPointX(x:FastFloat, y:FastFloat):FastFloat {
		return _transform.getTransformX(x, y);
	}

	public function inverseTransformPointY(x:FastFloat, y:FastFloat):FastFloat {
		return _transform.getTransformY(x, y);
	}

	public function transformPointX(x:FastFloat, y:FastFloat):FastFloat {
		updateInvertedTransform();
		return _invertseTransform.getTransformX(x, y);
	}

	public function transformPointY(x:FastFloat, y:FastFloat):FastFloat {
		updateInvertedTransform();
		return _invertseTransform.getTransformY(x, y);
	}

	inline function onTransformUpdate() {
		_invertseTransformDirty = true;
	}
	
	inline function updateInvertedTransform() {
		if(_invertseTransformDirty) {
			_invertseTransform.copyFrom(_transform);
			_invertseTransform.invert();
			_invertseTransformDirty = false;
		}
	}

}
