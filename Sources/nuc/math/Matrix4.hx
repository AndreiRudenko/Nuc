package nuc.math;

import kha.FastFloat;
import nuc.utils.Math;
import kha.simd.Float32x4;

abstract Matrix4(kha.math.FastMatrix4) from kha.math.FastMatrix4 to kha.math.FastMatrix4 {

	public var _00(get, set):FastFloat;
	inline function get__00() return this._00; 
	inline function set__00(v:FastFloat) return this._00 = v; 

	public var _01(get, set):FastFloat;
	inline function get__01() return this._01;
	inline function set__01(v:FastFloat) return this._01 = v;

	public var _02(get, set):FastFloat;
	inline function get__02() return this._02;
	inline function set__02(v:FastFloat) return this._02 = v;

	public var _03(get, set):FastFloat;
	inline function get__03() return this._03;
	inline function set__03(v:FastFloat) return this._03 = v;

	public var _10(get, set):FastFloat;
	inline function get__10() return this._10;
	inline function set__10(v:FastFloat) return this._10 = v;

	public var _11(get, set):FastFloat;
	inline function get__11() return this._11;
	inline function set__11(v:FastFloat) return this._11 = v;

	public var _12(get, set):FastFloat;
	inline function get__12() return this._12;
	inline function set__12(v:FastFloat) return this._12 = v;

	public var _13(get, set):FastFloat;
	inline function get__13() return this._13;
	inline function set__13(v:FastFloat) return this._13 = v;

	public var _20(get, set):FastFloat;
	inline function get__20() return this._20;
	inline function set__20(v:FastFloat) return this._20 = v;

	public var _21(get, set):FastFloat;
	inline function get__21() return this._21;
	inline function set__21(v:FastFloat) return this._21 = v;

	public var _22(get, set):FastFloat;
	inline function get__22() return this._22;
	inline function set__22(v:FastFloat) return this._22 = v;

	public var _23(get, set):FastFloat;
	inline function get__23() return this._23;
	inline function set__23(v:FastFloat) return this._23 = v;

	public var _30(get, set):FastFloat;
	inline function get__30() return this._30;
	inline function set__30(v:FastFloat) return this._30 = v;

	public var _31(get, set):FastFloat;
	inline function get__31() return this._31;
	inline function set__31(v:FastFloat) return this._31 = v;

	public var _32(get, set):FastFloat;
	inline function get__32() return this._32;
	inline function set__32(v:FastFloat) return this._32 = v;

	public var _33(get, set):FastFloat;
	inline function get__33() return this._33;
	inline function set__33(v:FastFloat) return this._33 = v;

	
	public inline function new() {
		this = new kha.math.FastMatrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
	}

	public inline function set(
		m00:Float, m10:Float, m20:Float, m30:Float,
		m01:Float, m11:Float, m21:Float, m31:Float,
		m02:Float, m12:Float, m22:Float, m32:Float,
		m03:Float, m13:Float, m23:Float, m33:Float
	) {
		_00 = m00; _10 = m10; _20 = m20; _30 = m30;
		_01 = m01; _11 = m11; _21 = m21; _31 = m31;
		_02 = m02; _12 = m12; _22 = m22; _32 = m32;
		_03 = m03; _13 = m13; _23 = m23; _33 = m33;

		return this;
	}

	public inline function zero() {
		_00 = 0.0; _10 = 0.0; _20 = 0.0; _30 = 0.0;
		_01 = 0.0; _11 = 0.0; _21 = 0.0; _31 = 0.0;
		_02 = 0.0; _12 = 0.0; _22 = 0.0; _32 = 0.0;
		_03 = 0.0; _13 = 0.0; _23 = 0.0; _33 = 0.0;

		return this;
	}

	public inline function identity() {
		_00 = 1.0; _10 = 0.0; _20 = 0.0; _30 = 0.0;
		_01 = 0.0; _11 = 1.0; _21 = 0.0; _31 = 0.0;
		_02 = 0.0; _12 = 0.0; _22 = 1.0; _32 = 0.0;
		_03 = 0.0; _13 = 0.0; _23 = 0.0; _33 = 1.0;

		return this;
	}

	public inline function copyFrom(m:Matrix4):Matrix4 {
		return set(m._00, m._10, m._20, m._30, m._01, m._11, m._21, m._31, m._02, m._12, m._22, m._32, m._03, m._13, m._23, m._33);
	}

	public inline function clone() {
		return new Matrix4().copyFrom(this);
	}

	public inline function transpose() {
		var a01 = _10, a02 = _20, a03 = _30;
		var a12 = _21, a13 = _31;
		var a23 = _32;

		_10 = _01; _20 = _02; _30 = _03;
		_21 = _12; _31 = _13;
		_32 = _23;

		_01 = a01; _02 = a02; _03 = a03;
		_12 = a12; _13 = a13;
		_23 = a23;

		return this;
	}

	public inline function perspective(fovY:FastFloat, aspect:FastFloat, zn:FastFloat, zf:FastFloat): Matrix4 {
		var uh = 1.0 / Math.tan(fovY / 2);
		var uw = uh / aspect;
		return set(
			uw, 0, 0, 0, 
			0, uh, 0, 0, 
			0, 0, (zf + zn) / (zn - zf), 2 * zf * zn / (zn - zf), 
			0, 0, -1, 0
		);
	}

	public inline function orthographic(left:FastFloat, right:FastFloat, bottom:FastFloat, top:FastFloat, zn:FastFloat, zf:FastFloat) {
		var tx:FastFloat = -(right + left) / (right - left);
		var ty:FastFloat = -(top + bottom) / (top - bottom);
		var tz:FastFloat = -(zf + zn) / (zf - zn);
		return set(
			2.0 / (right - left), 0, 0, tx, 
			0, 2.0 / (top - bottom), 0, ty, 
			0, 0, -2 / (zf - zn), tz, 
			0, 0, 0, 1
		);
	}

	public inline function translate(x:Float, y:Float, z:Float) {
		_00 += x * _03;
		_01 += y * _03;
		_02 += z * _03;
		_10 += x * _13;
		_11 += y * _13;
		_12 += z * _13;
		_20 += x * _23;
		_21 += y * _23;
		_22 += z * _23;
		_30 += x * _33;
		_31 += y * _33;
		_32 += z * _33;

		return this;
	}

	public inline function setTranslation(x:Float, y:Float, z:Float) {
		_00 = 1;
		_01 = 0;
		_02 = 0;
		_03 = 0;

		_10 = 0;
		_11 = 1;
		_12 = 0;
		_13 = 0;

		_20 = 0;
		_21 = 0;
		_22 = 1;
		_23 = 0;

		_30 = x;
		_31 = y;
		_32 = z;
		_33 = 1;

		return this;
	}

	public inline function scale(x:Float, y:Float, z:Float) {
		_00 *= x;
		_01 *= x;
		_02 *= x;
		_03 *= x;

		_10 *= y;
		_11 *= y;
		_12 *= y;
		_13 *= y;

		_20 *= z;
		_21 *= z;
		_22 *= z;
		_23 *= z;

		return this;
	}

	public inline function setScale(x:Float, y:Float, z:Float) {
		_00 = x;
		_01 = 0;
		_02 = 0;
		_03 = 0;

		_10 = 0;
		_11 = y;
		_12 = 0;
		_13 = 0;

		_20 = 0;
		_21 = 0;
		_22 = z;
		_23 = 0;

		return this;
	}

	public inline function rotateX(radians:Float) {
		var c = Math.cos(radians);
		var s = Math.sin(radians);
		var a10 = _10;
		var a11 = _11;
		var a12 = _12;
		var a13 = _13;
		var a20 = _20;
		var a21 = _21;
		var a22 = _22;
		var a23 = _23;

		_10 = a10 * c + a20 * s;
		_11 = a11 * c + a21 * s;
		_12 = a12 * c + a22 * s;
		_13 = a13 * c + a23 * s;
		_20 = a20 * c - a10 * s;
		_21 = a21 * c - a11 * s;
		_22 = a22 * c - a12 * s;
		_23 = a23 * c - a13 * s;

		return this;
	}

	public inline function rotateY(radians:Float) {
		var c = Math.cos(radians);
		var s = Math.sin(radians);
		var a00 = _00;
		var a01 = _01;
		var a02 = _02;
		var a03 = _03;
		var a20 = _20;
		var a21 = _21;
		var a22 = _22;
		var a23 = _23;

		_00 = a00 * c - a20 * s;
		_01 = a01 * c - a21 * s;
		_02 = a02 * c - a22 * s;
		_03 = a03 * c - a23 * s;
		_20 = a00 * s + a20 * c;
		_21 = a01 * s + a21 * c;
		_22 = a02 * s + a22 * c;
		_23 = a03 * s + a23 * c;

		return this;
	}

	public inline function rotateZ(radians:Float) {
		var c = Math.cos(radians);
		var s = Math.sin(radians);
		var a00 = _00;
		var a01 = _01;
		var a02 = _02;
		var a03 = _03;
		var a10 = _10;
		var a11 = _11;
		var a12 = _12;
		var a13 = _13;

		_00 = a00 * c + a10 * s;
		_01 = a01 * c + a11 * s;
		_02 = a02 * c + a12 * s;
		_03 = a03 * c + a13 * s;
		_10 = a10 * c - a00 * s;
		_11 = a11 * c - a01 * s;
		_12 = a12 * c - a02 * s;
		_13 = a13 * c - a03 * s;

		return this;
	}

	public inline function rotateAxis(axis:Vector3, radians:Float) {
		var len = axis.lengthSquared;
		if (Math.abs(len) < Math.EPSILON) return this;

		len = Math.sqrt(len);
		var x = axis.x / len;
		var y = axis.y / len;
		var z = axis.z / len;

		var s = Math.sin(radians);
		var c = Math.cos(radians);
		var t = 1 - c;

		//  Construct the elements of the rotation matrix
		var b00 = x * x * t + c;
		var b01 = y * x * t + z * s;
		var b02 = z * x * t - y * s;

		var b10 = x * y * t - z * s;
		var b11 = y * y * t + c;
		var b12 = z * y * t + x * s;

		var b20 = x * z * t + y * s;
		var b21 = y * z * t - x * s;
		var b22 = z * z * t + c;

		//  Perform rotation-specific matrix multiplication

		#if (cpp && !nuc_no_simd)

		final m00_03 = Float32x4.loadFast(_00, _01, _02, _03);
		final m10_13 = Float32x4.loadFast(_10, _11, _12, _13);
		final m20_23 = Float32x4.loadFast(_20, _21, _22, _23);

		final sb00 = Float32x4.loadAllFast(b00);
		final sb01 = Float32x4.loadAllFast(b01);
		final sb02 = Float32x4.loadAllFast(b02);
		final o1 = Float32x4.add(Float32x4.add(Float32x4.mul(m00_03, sb00), Float32x4.mul(m10_13, sb01)),Float32x4.mul(m20_23, sb02));

		final sb10 = Float32x4.loadAllFast(b10);
		final sb11 = Float32x4.loadAllFast(b11);
		final sb12 = Float32x4.loadAllFast(b12);
		final o2 = Float32x4.add(Float32x4.add(Float32x4.mul(m00_03, sb10), Float32x4.mul(m10_13, sb11)),Float32x4.mul(m20_23, sb12));

		final sb20 = Float32x4.loadAllFast(b20);
		final sb21 = Float32x4.loadAllFast(b21);
		final sb22 = Float32x4.loadAllFast(b22);
		final o3 = Float32x4.add(Float32x4.add(Float32x4.mul(m00_03, sb20), Float32x4.mul(m10_13, sb21)),Float32x4.mul(m20_23, sb22));

		return set(
			Float32x4.getFast(o1, 0),
			Float32x4.getFast(o1, 1),
			Float32x4.getFast(o1, 2),
			Float32x4.getFast(o1, 3),

			Float32x4.getFast(o2, 0),
			Float32x4.getFast(o2, 1),
			Float32x4.getFast(o2, 2),
			Float32x4.getFast(o2, 3),

			Float32x4.getFast(o3, 0),
			Float32x4.getFast(o3, 1),
			Float32x4.getFast(o3, 2),
			Float32x4.getFast(o3, 3),

			_30, _31, _32, _33
		);

		#else
		return set(
			_00 * b00 + _10 * b01 + _20 * b02,
			_01 * b00 + _11 * b01 + _21 * b02,
			_02 * b00 + _12 * b01 + _22 * b02,
			_03 * b00 + _13 * b01 + _23 * b02,

			_00 * b10 + _10 * b11 + _20 * b12,
			_01 * b10 + _11 * b11 + _21 * b12,
			_02 * b10 + _12 * b11 + _22 * b12,
			_03 * b10 + _13 * b11 + _23 * b12,

			_00 * b20 + _10 * b21 + _20 * b22,
			_01 * b20 + _11 * b21 + _21 * b22,
			_02 * b20 + _12 * b21 + _22 * b22,
			_03 * b20 + _13 * b21 + _23 * b22,

			_30, _31, _32, _33
		);
		#end
	}

	public inline function setRotationAxis(axis:Vector3, radians:Float) {
		var c = Math.cos(radians);
		var s = Math.sin(radians);
		var t = 1 - c;
		var x = axis.x;
		var y = axis.y;
		var z = axis.z;
		var tx = t * x;
		var ty = t * y;

		return set(
			tx * x + c, 
			tx * y - s * z, 
			tx * z + s * y, 
			0,

			tx * y + s * z, 
			ty * y + c, 
			ty * z - s * x, 
			0,

			tx * z - s * y, 
			ty * z + s * x, 
			t * z * z + c, 
			0,

			0, 0, 0, 1
		);
	}

	public inline function multiply(m:Matrix4) {
		#if (cpp && !nuc_no_simd)

		final m00_30 = Float32x4.loadFast(m._00, m._10, m._20, m._30);
		final m01_31 = Float32x4.loadFast(m._01, m._11, m._21, m._31);
		final m02_32 = Float32x4.loadFast(m._02, m._12, m._22, m._32);
		final m03_33 = Float32x4.loadFast(m._03, m._13, m._23, m._33);

		final s00 = Float32x4.loadAllFast(_00);
		final s10 = Float32x4.loadAllFast(_10);
		final s20 = Float32x4.loadAllFast(_20);
		final s30 = Float32x4.loadAllFast(_30);
		final o1 = Float32x4.add(Float32x4.add(Float32x4.mul(s00, m00_30), Float32x4.mul(s10, m01_31)), Float32x4.add(Float32x4.mul(s20, m02_32), Float32x4.mul(s30, m03_33)));

		final s01 = Float32x4.loadAllFast(_01);
		final s11 = Float32x4.loadAllFast(_11);
		final s21 = Float32x4.loadAllFast(_21);
		final s31 = Float32x4.loadAllFast(_31);
		final o2 = Float32x4.add(Float32x4.add(Float32x4.mul(s01, m00_30), Float32x4.mul(s11, m01_31)), Float32x4.add(Float32x4.mul(s21, m02_32), Float32x4.mul(s31, m03_33)));

		final s02 = Float32x4.loadAllFast(_02);
		final s12 = Float32x4.loadAllFast(_12);
		final s22 = Float32x4.loadAllFast(_22);
		final s32 = Float32x4.loadAllFast(_32);
		final o3 = Float32x4.add(Float32x4.add(Float32x4.mul(s02, m00_30), Float32x4.mul(s12, m01_31)), Float32x4.add(Float32x4.mul(s22, m02_32), Float32x4.mul(s32, m03_33)));

		final s03 = Float32x4.loadAllFast(_03);
		final s13 = Float32x4.loadAllFast(_13);
		final s23 = Float32x4.loadAllFast(_23);
		final s33 = Float32x4.loadAllFast(_33);
		final o4 = Float32x4.add(Float32x4.add(Float32x4.mul(s03, m00_30), Float32x4.mul(s13, m01_31)), Float32x4.add(Float32x4.mul(s23, m02_32), Float32x4.mul(s33, m03_33)));

		return set(
			Float32x4.getFast(o1, 0),
			Float32x4.getFast(o1, 1),
			Float32x4.getFast(o1, 2),
			Float32x4.getFast(o1, 3),

			Float32x4.getFast(o2, 0),
			Float32x4.getFast(o2, 1),
			Float32x4.getFast(o2, 2),
			Float32x4.getFast(o2, 3),

			Float32x4.getFast(o3, 0),
			Float32x4.getFast(o3, 1),
			Float32x4.getFast(o3, 2),
			Float32x4.getFast(o3, 3),

			Float32x4.getFast(o4, 0),
			Float32x4.getFast(o4, 1),
			Float32x4.getFast(o4, 2),
			Float32x4.getFast(o4, 3)
		);

		#else

		return set(
			_00 * m._00 + _10 * m._01 + _20 * m._02 + _30 * m._03,
			_00 * m._10 + _10 * m._11 + _20 * m._12 + _30 * m._13,
			_00 * m._20 + _10 * m._21 + _20 * m._22 + _30 * m._23,
			_00 * m._30 + _10 * m._31 + _20 * m._32 + _30 * m._33,

			_01 * m._00 + _11 * m._01 + _21 * m._02 + _31 * m._03,
			_01 * m._10 + _11 * m._11 + _21 * m._12 + _31 * m._13,
			_01 * m._20 + _11 * m._21 + _21 * m._22 + _31 * m._23,
			_01 * m._30 + _11 * m._31 + _21 * m._32 + _31 * m._33,

			_02 * m._00 + _12 * m._01 + _22 * m._02 + _32 * m._03,
			_02 * m._10 + _12 * m._11 + _22 * m._12 + _32 * m._13,
			_02 * m._20 + _12 * m._21 + _22 * m._22 + _32 * m._23,
			_02 * m._30 + _12 * m._31 + _22 * m._32 + _32 * m._33,

			_03 * m._00 + _13 * m._01 + _23 * m._02 + _33 * m._03,
			_03 * m._10 + _13 * m._11 + _23 * m._12 + _33 * m._13,
			_03 * m._20 + _13 * m._21 + _23 * m._22 + _33 * m._23,
			_03 * m._30 + _13 * m._31 + _23 * m._32 + _33 * m._33
		);

		#end
	}

	public inline function determinant():Float {
		#if (cpp && !nuc_no_simd)

		final b1 = Float32x4.loadFast(_00, _00, _00, _01);
		final b2 = Float32x4.loadFast(_11, _12, _13, _12);
		final b3 = Float32x4.loadFast(_01, _02, _03, _02);
		final b4 = Float32x4.loadFast(_10, _10, _10, _11);
		
		final bo1 = Float32x4.sub(Float32x4.mul(b1, b2), Float32x4.mul(b3, b4));

		final b00 = Float32x4.getFast(bo1, 0);
		final b01 = Float32x4.getFast(bo1, 1);
		final b02 = Float32x4.getFast(bo1, 2);
		final b03 = Float32x4.getFast(bo1, 3);

		final b5 = Float32x4.loadFast(_01, _02, _20, _20);
		final b6 = Float32x4.loadFast(_13, _13, _31, _32);
		final b7 = Float32x4.loadFast(_03, _03, _21, _22);
		final b8 = Float32x4.loadFast(_11, _12, _30, _30);
		
		final bo2 = Float32x4.sub(Float32x4.mul(b5, b6), Float32x4.mul(b7, b8));

		final b04 = Float32x4.getFast(bo2, 0);
		final b05 = Float32x4.getFast(bo2, 1);
		final b06 = Float32x4.getFast(bo2, 2);
		final b07 = Float32x4.getFast(bo2, 3);

		final b9 = Float32x4.loadFast(_20, _21, _21, _22);
		final b10 = Float32x4.loadFast(_33, _32, _33, _33);
		final b11 = Float32x4.loadFast(_23, _22, _23, _23);
		final b12 = Float32x4.loadFast(_30, _31, _31, _32);

		final bo3 = Float32x4.sub(Float32x4.mul(b9, b10), Float32x4.mul(b11, b12));

		final b08 = Float32x4.getFast(bo3, 0);
		final b09 = Float32x4.getFast(bo3, 1);
		final b10 = Float32x4.getFast(bo3, 2);
		final b11 = Float32x4.getFast(bo3, 3);

		#else

		final b00 = _00 * _11 - _01 * _10;
		final b01 = _00 * _12 - _02 * _10;
		final b02 = _00 * _13 - _03 * _10;
		final b03 = _01 * _12 - _02 * _11;

		final b04 = _01 * _13 - _03 * _11;
		final b05 = _02 * _13 - _03 * _12;
		final b06 = _20 * _31 - _21 * _30;
		final b07 = _20 * _32 - _22 * _30;

		final b08 = _20 * _33 - _23 * _30;
		final b09 = _21 * _32 - _22 * _31;
		final b10 = _21 * _33 - _23 * _31;
		final b11 = _22 * _33 - _23 * _32;

		#end

		//  Calculate the determinant
		return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
	}

	public inline function invert():Matrix4 {
		#if (cpp && !nuc_no_simd)

		final b1 = Float32x4.loadFast(_00, _00, _00, _01);
		final b2 = Float32x4.loadFast(_11, _12, _13, _12);
		final b3 = Float32x4.loadFast(_01, _02, _03, _02);
		final b4 = Float32x4.loadFast(_10, _10, _10, _11);
		
		final bo1 = Float32x4.sub(Float32x4.mul(b1, b2), Float32x4.mul(b3, b4));

		final b00 = Float32x4.getFast(bo1, 0);
		final b01 = Float32x4.getFast(bo1, 1);
		final b02 = Float32x4.getFast(bo1, 2);
		final b03 = Float32x4.getFast(bo1, 3);

		final b5 = Float32x4.loadFast(_01, _02, _20, _20);
		final b6 = Float32x4.loadFast(_13, _13, _31, _32);
		final b7 = Float32x4.loadFast(_03, _03, _21, _22);
		final b8 = Float32x4.loadFast(_11, _12, _30, _30);
		
		final bo2 = Float32x4.sub(Float32x4.mul(b5, b6), Float32x4.mul(b7, b8));

		final b04 = Float32x4.getFast(bo2, 0);
		final b05 = Float32x4.getFast(bo2, 1);
		final b06 = Float32x4.getFast(bo2, 2);
		final b07 = Float32x4.getFast(bo2, 3);

		final b9 = Float32x4.loadFast(_20, _21, _21, _22);
		final b10 = Float32x4.loadFast(_33, _32, _33, _33);
		final b11 = Float32x4.loadFast(_23, _22, _23, _23);
		final b12 = Float32x4.loadFast(_30, _31, _31, _32);

		final bo3 = Float32x4.sub(Float32x4.mul(b9, b10), Float32x4.mul(b11, b12));

		final b08 = Float32x4.getFast(bo3, 0);
		final b09 = Float32x4.getFast(bo3, 1);
		final b10 = Float32x4.getFast(bo3, 2);
		final b11 = Float32x4.getFast(bo3, 3);

		//  Calculate the determinant
		var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

		if (Math.abs(det) < Math.EPSILON) {
			throw "determinant is too small";
		}

		det = 1 / det;

		final sdet = Float32x4.loadAllFast(det);

		final b11_b05_b11_b05 = Float32x4.loadFast(b11, b05, b11, b05);
		final b06_b00_b06_b00 = Float32x4.loadFast(b06, b00, b06, b00);

		final b10_b04_b09_b03 = Float32x4.loadFast(b10, b04, b09, b03);
		final b10_b04_b08_b02 = Float32x4.loadFast(b10, b04, b08, b02);
		final b09_b03_b07_b01 = Float32x4.loadFast(b09, b03, b07, b01);
		final b08_b02_b07_b01 = Float32x4.loadFast(b08, b02, b07, b01);

		// (_11 * b11 - _12 * b10 + _13 * b09) * det, // 0
		// (_31 * b05 - _32 * b04 + _33 * b03) * det, // 2
		// (_00 * b11 - _02 * b08 + _03 * b07) * det, // 5
		// (_20 * b05 - _22 * b02 + _23 * b01) * det, // 7

		final _11_31_00_20 = Float32x4.loadFast(_11, _31, _00, _20);
		final _12_32_02_22 = Float32x4.loadFast(_12, _32, _02, _22);
		final _13_33_03_23 = Float32x4.loadFast(_13, _33, _03, _23);

		final o1 = Float32x4.mul(
			Float32x4.add(
				Float32x4.sub(
					Float32x4.mul(_11_31_00_20, b11_b05_b11_b05),
					Float32x4.mul(_12_32_02_22, b10_b04_b08_b02)
				),
				Float32x4.mul(_13_33_03_23, b09_b03_b07_b01)
			),
			sdet
		);

		// (_10 * b10 - _11 * b08 + _13 * b06) * det, // 8
		// (_30 * b04 - _31 * b02 + _33 * b00) * det, // 10
		// (_00 * b09 - _01 * b07 + _02 * b06) * det, // 13
		// (_20 * b03 - _21 * b01 + _22 * b00) * det // 15

		final _10_30_00_20 = Float32x4.loadFast(_10, _30, _00, _20);
		final _11_31_01_21 = Float32x4.loadFast(_11, _31, _01, _21);
		final _13_33_02_22 = Float32x4.loadFast(_13, _33, _02, _22);

		final o2 = Float32x4.mul(
			Float32x4.add(
				Float32x4.sub(
					Float32x4.mul(_10_30_00_20, b10_b04_b09_b03),
					Float32x4.mul(_11_31_01_21, b08_b02_b07_b01)
				),
				Float32x4.mul(_13_33_02_22, b06_b00_b06_b00)
			),
			sdet
		);

		// (_02 * b10 - _01 * b11 - _03 * b09) * det, // 1
		// (_22 * b04 - _21 * b05 - _23 * b03) * det, // 3
		// (_12 * b08 - _10 * b11 - _13 * b07) * det, // 4
		// (_32 * b02 - _30 * b05 - _33 * b01) * det, // 6

		final _02_22_12_32 = Float32x4.loadFast(_02, _22, _12, _32);
		final _01_21_10_30 = Float32x4.loadFast(_01, _21, _10, _30);
		final _03_23_13_33 = Float32x4.loadFast(_03, _23, _13, _33);

		final o3 = Float32x4.mul(
			Float32x4.sub(
				Float32x4.sub(
					Float32x4.mul(_02_22_12_32, b10_b04_b09_b03),
					Float32x4.mul(_01_21_10_30, b11_b05_b11_b05)
				),
				Float32x4.mul(_03_23_13_33, b09_b03_b07_b01)
			),
			sdet
		);

		// (_01 * b08 - _00 * b10 - _03 * b06) * det, // 9
		// (_21 * b02 - _20 * b04 - _23 * b00) * det, // 11
		// (_11 * b07 - _10 * b09 - _12 * b06) * det, // 12
		// (_31 * b01 - _30 * b03 - _32 * b00) * det, // 14

		final _01_21_11_31 = Float32x4.loadFast(_01, _21, _11, _31);
		final _00_20_10_30 = Float32x4.loadFast(_00, _20, _10, _30);
		final _03_23_12_32 = Float32x4.loadFast(_03, _23, _12, _32);

		final o4 = Float32x4.mul(
			Float32x4.sub(
				Float32x4.sub(
					Float32x4.mul(_01_21_11_31, b08_b02_b07_b01),
					Float32x4.mul(_00_20_10_30, b10_b04_b09_b03)
				),
				Float32x4.mul(_03_23_12_32, b06_b00_b06_b00)
			),
			sdet
		);

		return set(
			Float32x4.getFast(o1, 0),
			Float32x4.getFast(o3, 0),
			Float32x4.getFast(o1, 1),
			Float32x4.getFast(o3, 1),

			Float32x4.getFast(o3, 2),
			Float32x4.getFast(o1, 2),
			Float32x4.getFast(o3, 3),
			Float32x4.getFast(o1, 3),

			Float32x4.getFast(o2, 0),
			Float32x4.getFast(o4, 0),
			Float32x4.getFast(o2, 1),
			Float32x4.getFast(o4, 1),

			Float32x4.getFast(o4, 2),
			Float32x4.getFast(o2, 2),
			Float32x4.getFast(o4, 3),
			Float32x4.getFast(o2, 3)
		);

		#else

		var b00 = _00 * _11 - _01 * _10;
		var b01 = _00 * _12 - _02 * _10;
		var b02 = _00 * _13 - _03 * _10;
		var b03 = _01 * _12 - _02 * _11;

		var b04 = _01 * _13 - _03 * _11;
		var b05 = _02 * _13 - _03 * _12;
		var b06 = _20 * _31 - _21 * _30;
		var b07 = _20 * _32 - _22 * _30;

		var b08 = _20 * _33 - _23 * _30;
		var b09 = _21 * _32 - _22 * _31;
		var b10 = _21 * _33 - _23 * _31;
		var b11 = _22 * _33 - _23 * _32;

		//  Calculate the determinant
		var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

		if (Math.abs(det) < Math.EPSILON) {
			throw "determinant is too small";
		}

		det = 1 / det;

		return set(
			(_11 * b11 - _12 * b10 + _13 * b09) * det, // 0
			(_02 * b10 - _01 * b11 - _03 * b09) * det, // 1
			(_31 * b05 - _32 * b04 + _33 * b03) * det, // 2
			(_22 * b04 - _21 * b05 - _23 * b03) * det, // 3

			(_12 * b08 - _10 * b11 - _13 * b07) * det, // 4
			(_00 * b11 - _02 * b08 + _03 * b07) * det, // 5
			(_32 * b02 - _30 * b05 - _33 * b01) * det, // 6
			(_20 * b05 - _22 * b02 + _23 * b01) * det, // 7

			(_10 * b10 - _11 * b08 + _13 * b06) * det, // 8
			(_01 * b08 - _00 * b10 - _03 * b06) * det, // 9
			(_30 * b04 - _31 * b02 + _33 * b00) * det, // 10
			(_21 * b02 - _20 * b04 - _23 * b00) * det, // 11

			(_11 * b07 - _10 * b09 - _12 * b06) * det, // 12
			(_00 * b09 - _01 * b07 + _02 * b06) * det, // 13
			(_31 * b01 - _30 * b03 - _32 * b00) * det, // 14
			(_20 * b03 - _21 * b01 + _22 * b00) * det // 15
		);

		#end
	}

	public inline function lookAt(eye:Vector3, target:Vector3, up:Vector3): Matrix4 {
		var zaxis = target.clone();
		zaxis.subtract(eye);
		zaxis.normalize();
		
		var xaxis = zaxis.clone();
		xaxis.cross(up);
		xaxis.normalize();
		
		var yaxis = xaxis.clone();
		yaxis.cross(zaxis);
		
		return set(
			xaxis.x, xaxis.y, xaxis.z, -xaxis.dot(eye), 
			yaxis.x, yaxis.y, yaxis.z, -yaxis.dot(eye), 
			-zaxis.x, -zaxis.y, -zaxis.z, zaxis.dot(eye), 
			0, 0, 0, 1);
	}

	public function toString() {
		return "[" + _00 + "|" + _01 + "|" + _02 + "|" + _03 + "]\n" //
			+ "[" + _10 + "|" + _11 + "|" + _12 + "|" + _13 + "]\n" //
			+ "[" + _20 + "|" + _21 + "|" + _22 + "|" + _23 + "]\n" //
			+ "[" + _30 + "|" + _31 + "|" + _32 + "|" + _33 + "]\n";
	}


}