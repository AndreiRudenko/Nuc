package nuc.math;

@:structInit
class Vector3 {

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

	public var length(get, set):Float;
	inline function get_length() return Math.sqrt(x * x + y * y + z * z);
	inline function set_length(v:Float) {
		normalize();
		multiply(v);
		return v;
	}

	public var lengthSquared(get, never):Float;
	inline function get_lengthSquared() return x * x + y * y + z * z;
	
	public inline function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		_x = x;
		_y = y;
		_z = z;
	}

	public function set(x:Float, y:Float, z:Float) {
		_x = x;
		_y = y;
		_z = z;
		
		return this;
	}

	public inline function copyFrom(other:Vector3) {
		return set(other.x, other.y, other.z);
	}

	public inline function equals(other:Vector3):Bool {
		return x == other.x && y == other.y && z == other.z;
	}

	public inline function isZero():Bool {
		return x == 0 && y == 0 && z == 0;
	}

	public inline function clone() {
		return new Vector3(x, y, z);
	}

	public inline function normalize() {
		final ls = lengthSquared;
		if(ls != 0) divide(Math.sqrt(ls));
		return this;
	}

	public inline function dot(other:Vector3) {
		return x * other.x + y * other.y + z * other.z;
	}

	public inline function cross(other:Vector3) {
		return set(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x);
	}

	public inline function distance(other:Vector3) {
		return Math.sqrt((other.y - y) * (other.y - y) + (other.x - x) * (other.x - x) + (other.z - z) * (other.z - z));
	}

	public inline function invert() {
		return set(-x, -y, -z);
	}

	public extern overload inline function add(other:Vector3) {
		return set(x + other.x, y + other.y, z + other.z);
	}

	public extern overload inline function add(x:Float, y:Float, z:Float) {
		return set(this.x + x, this.y + y, this.z);
	}

	public extern overload inline function add(v:Float) {
		return set(x + v, y + v, z + v);
	}

	public extern overload inline function subtract(other:Vector3) {
		return set(x - other.x, y - other.y, z - other.z);
	}

	public extern overload inline function subtract(x:Float, y:Float, z:Float) {
		return set(this.x - x, this.y - y, this.z);
	}

	public extern overload inline function subtract(v:Float) {
		return set(x - v, y - v, z - v);
	}

	public extern overload inline function multiply(other:Vector3) {
		return set(x * other.x, y * other.y, z * other.z);
	}

	public extern overload inline function multiply(x:Float, y:Float, z:Float) {
		return set(this.x * x, this.y * y, this.z);
	}

	public extern overload inline function multiply(v:Float) {
		return set(x * v, y * v, z * v);
	}

	public extern overload inline function divide(other:Vector3) {
		return set(x / other.x, y / other.y, z / other.z);
	}

	public extern overload inline function divide(x:Float, y:Float, z:Float) {
		return set(this.x / x, this.y / y, this.z);
	}

	public extern overload inline function divide(v:Float) {
		return set(x / v, y / v, z / v);
	}

	public inline function lerp(other:Vector3, alpha:Float) {
		return set(x + (other.x - x) * alpha, y + (other.y - y) * alpha, z + (other.z - z) * alpha);
	}

	// Multiplies this vector by the given matrix dividing by w, assuming the fourth (w) component of the vector is 1. 
	// This is mostly used to project/unproject vectors via a perspective projection matrix.
	public inline function project(m:Matrix4) {
		final lw = 1 / (x * m._30 + y * m._31 + z * m._32 + m._33);
		return set(
			(x * m._00 + y * m._01 + z * m._02 + m._03) * lw,
			(x * m._10 + y * m._11 + z * m._12 + m._13) * lw,
			(x * m._20 + y * m._21 + z * m._22 + m._23) * lw
		);
	}

	public inline function transformFromMatrix(m:Matrix4) {
		return set(
			x * m._00 + y * m._10 + z * m._20 + m._30, 
			x * m._01 + y * m._11 + z * m._21 + m._31, 
			x * m._02 + y * m._12 + z * m._22 + m._32
		);
	}

	static public extern overload inline function Add(a:Vector3, b:Vector3) {
	    return a.clone().add(b);
	}

	static public extern overload inline function Add(a:Vector3, v:Float) {
	    return a.clone().add(v);
	}

	static public extern overload inline function Subtract(a:Vector3, b:Vector3) {
	    return a.clone().subtract(b);
	}

	static public extern overload inline function Subtract(a:Vector3, v:Float) {
	    return a.clone().subtract(v);
	}

	static public extern overload inline function Multiply(a:Vector3, b:Vector3) {
	    return a.clone().multiply(b);
	}

	static public extern overload inline function Multiply(a:Vector3, v:Float) {
	    return a.clone().multiply(v);
	}

	static public extern overload inline function Divide(a:Vector3, b:Vector3) {
	    return a.clone().divide(b);
	}

	static public extern overload inline function Divide(a:Vector3, v:Float) {
	    return a.clone().divide(v);
	}

	static public inline function Lerp(a:Vector3, b:Vector3, alpha:Float) {
	    return a.clone().lerp(b, alpha);
	}

	static public inline function Distance(a:Vector3, v:Vector3) {
	    return a.distance(v);
	}

}

@:structInit
class Vector3Callback extends Vector3 {

    public var ignoreListeners:Bool = false;
    public var listener:(v:Vector3)->Void;

    public inline function new(x:Float = 0, y:Float = 0, y:Float = 0) {
        super(x, y, z);
    }

    override function set(x:Float, y:Float, z:Float) {
        _x = x;
        _y = y;
		_z = z;
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

    public function listen(f:(v:Vector3)->Void) {
        listener = f;
    }

    inline function callListener() {
        if(listener != null && !ignoreListeners) {
            listener(this);
        }
    }

}

