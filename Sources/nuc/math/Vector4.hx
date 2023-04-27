package nuc.math;

import kha.simd.Float32x4;

@:structInit
class Vector4 {

	public var x(get, set):Float;
	var _x:Float;
	inline function get_x() return _x;
	function set_x(v:Float) return _x = v;

	public var y(get, set):Float;
	var _y:Float;
	inline function get_y() return _y;
	function set_y(v:Float) return _y = v;

	public var z(get, set):Float;
	var _z:Float;
	inline function get_z() return _z;
	function set_z(v:Float) return _z = v;

	public var w(get, set):Float;
	var _w:Float;
	inline function get_w() return _w;
	function set_w(v:Float) return _w = v;

	public var length(get, set):Float;
	inline function get_length() return Math.sqrt(x * x + y * y + z * z + w * w);
	function set_length(v:Float) {
		normalize();
		multiply(v);
		return v;
	}

	public var lengthSquared(get, never):Float;
	inline function get_lengthSquared() return x * x + y * y + z * z + w * w;
	
	public inline function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
		_x = x;
		_y = y;
		_z = z;
		_w = w;
	}

	public function set(x:Float, y:Float, z:Float, w:Float) {
		_x = x;
		_y = y;
		_z = z;
		_w = w;
		
		return this;
	}

	public inline function copyFrom(other:Vector4) {
		return set(other.x, other.y, other.z, other.w);
	}

	public inline function equals(other:Vector4):Bool {
		return x == other.x && y == other.y && z == other.z && w == other.w;
	}

	public inline function isZero():Bool {
		return x == 0 && y == 0 && z == 0 && w == 0;
	}

	public inline function clone() {
		return new Vector4(x, y, z, w);
	}

	public inline function normalize() {
		final ls = lengthSquared;
		if(ls != 0) divide(Math.sqrt(ls));
		return this;
	}

	public inline function dot(other:Vector4) {
		return x * other.x + y * other.y + z * other.z + w * other.w;
	}

	public inline function cross(other:Vector4) {
		return set(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x, w);
	}

	public inline function distance(other:Vector4) {
		return Math.sqrt((other.y - y) * (other.y - y) + (other.x - x) * (other.x - x) + (other.z - z) * (other.z - z) + (other.w - w) * (other.w - w));
	}

	public inline function invert() {
		return set(-x, -y, -z, -w);
	}

	public extern overload inline function add(other:Vector4) {
		return set(x + other.x, y + other.y, z + other.z, w + other.w);
	}

	public extern overload inline function add(x:Float, y:Float, z:Float, w:Float) {
		return set(this.x + x, this.y + y, this.z, this.w);
	}

	public extern overload inline function add(v:Float) {
		return set(x + v, y + v, z + v, w + v);
	}

	public extern overload inline function subtract(other:Vector4) {
		return set(x - other.x, y - other.y, z - other.z, w - other.w);
	}

	public extern overload inline function subtract(x:Float, y:Float, z:Float, w:Float) {
		return set(this.x - x, this.y - y, this.z, this.w);
	}

	public extern overload inline function subtract(v:Float) {
		return set(x - v, y - v, z - v, w - v);
	}

	public extern overload inline function multiply(other:Vector4) {
		return set(x * other.x, y * other.y, z * other.z, w * other.w);
	}

	public extern overload inline function multiply(x:Float, y:Float, z:Float, w:Float) {
		return set(this.x * x, this.y * y, this.z, this.w);
	}

	public extern overload inline function multiply(v:Float) {
		return set(x * v, y * v, z * v, w * v);
	}

	public extern overload inline function divide(other:Vector4) {
		return set(x / other.x, y / other.y, z / other.z, w / other.w);
	}

	public extern overload inline function divide(x:Float, y:Float, z:Float, w:Float) {
		return set(this.x / x, this.y / y, this.z, this.w);
	}

	public extern overload inline function divide(v:Float) {
		return set(x / v, y / v, z / v, w / v);
	}

	public inline function lerp(other:Vector4, alpha:Float) {
		return set(x + (other.x - x) * alpha, y + (other.y - y) * alpha, z + (other.z - z) * alpha, w + (other.w - w) * alpha);
	}

	public inline function transformFromMatrix(m:Matrix4) {
		#if (cpp && !nuc_no_simd)

		final s1 = Float32x4.loadFast(m._00, m._01, m._02, m._03);
		final s2 = Float32x4.loadFast(m._10, m._11, m._12, m._13);
		final s3 = Float32x4.loadFast(m._20, m._21, m._22, m._23);
		final s4 = Float32x4.loadFast(m._30, m._31, m._32, m._33);

		final sX = Float32x4.loadAllFast(x);
		final sY = Float32x4.loadAllFast(y);
		final sZ = Float32x4.loadAllFast(z);

		final oX = Float32x4.mul(sX, s1);
		final oY = Float32x4.mul(sY, s2);
		final oZ = Float32x4.mul(sZ, s3);

		final o = Float32x4.add(Float32x4.add(oX, oY), Float32x4.add(oZ, s4));

		return set(
			Float32x4.getFast(o, 0),
			Float32x4.getFast(o, 1),
			Float32x4.getFast(o, 2),
			Float32x4.getFast(o, 3)
		);

		#else
		return set(
			x * m._00 + y * m._10 + z * m._20 + m._30, 
			x * m._01 + y * m._11 + z * m._21 + m._31, 
			x * m._02 + y * m._12 + z * m._22 + m._32, 
			x * m._03 + y * m._13 + z * m._23 + m._33
		);
		#end
	}

	public inline function transformFromQuaternion(q:Quaternion) {
		// TODO: SIMD

		final x:Float = this.x;
		final y:Float = this.y;
		final z:Float = this.z;

		final qx:Float = q.x;
		final qy:Float = q.y;
		final qz:Float = q.z;
		final qw:Float = q.w;

		final ix:Float = qw * x + qy * z - qz * y;
		final iy:Float = qw * y + qz * x - qx * z;
		final iz:Float = qw * z + qx * y - qy * x;
		final iw:Float = -qx * x - qy * y - qz * z;

		return set(
			ix * qw + iw * -qx + iy * -qz - iz * -qy,
			iy * qw + iw * -qy + iz * -qx - ix * -qz,
			iz * qw + iw * -qz + ix * -qy - iy * -qx,
			w
		);
	}

	static public extern overload inline function Add(a:Vector4, b:Vector4) {
	    return a.clone().add(b);
	}

	static public extern overload inline function Add(a:Vector4, v:Float) {
	    return a.clone().add(v);
	}

	static public extern overload inline function Subtract(a:Vector4, b:Vector4) {
	    return a.clone().subtract(b);
	}

	static public extern overload inline function Subtract(a:Vector4, v:Float) {
	    return a.clone().subtract(v);
	}

	static public extern overload inline function Multiply(a:Vector4, b:Vector4) {
	    return a.clone().multiply(b);
	}

	static public extern overload inline function Multiply(a:Vector4, v:Float) {
	    return a.clone().multiply(v);
	}

	static public extern overload inline function Divide(a:Vector4, b:Vector4) {
	    return a.clone().divide(b);
	}

	static public extern overload inline function Divide(a:Vector4, v:Float) {
	    return a.clone().divide(v);
	}

	static public inline function Lerp(a:Vector4, b:Vector4, alpha:Float) {
	    return a.clone().lerp(b, alpha);
	}

	static public inline function Distance(a:Vector4, v:Vector4) {
	    return a.distance(v);
	}

}


@:structInit
class Vector4Callback extends Vector4 {

    public var ignoreListeners:Bool = false;
    public var listener:(v:Vector4)->Void;

    public inline function new(x:Float = 0, y:Float = 0, y:Float = 0, w:Float = 0) {
        super(x, y, z, w);
    }

    override function set(x:Float, y:Float, z:Float, w:Float) {
        _x = x;
        _y = y;
		_z = z;
		_w = w;
        callListener();
        return this;
    }

    override function set_x(v:Float):Float {
        _x = v;
        callListener();
        return v;
    }

    override function set_y(v:Float):Float {
        _y = v;
        callListener();
        return v;
    }

	override function set_z(v:Float):Float {
		_z = v;
		callListener();
		return v;
	}

	override function set_w(v:Float):Float {
		_w = v;
		callListener();
		return v;
	}

    public function listen(f:(v:Vector4)->Void) {
        listener = f;
    }

    inline function callListener() {
        if(listener != null && !ignoreListeners) {
            listener(this);
        }
    }

}
