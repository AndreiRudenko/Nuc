package nuc.math;

@:structInit
class Vector2 {

	public var x(get, set):Float;
	var _x:Float;
	inline function get_x() return _x;
	function set_x(v:Float) return _x = v;

	public var y(get, set):Float;
	var _y:Float;
	inline function get_y() return _y;
	function set_y(v:Float) return _y = v;

	public var length(get, set):Float;
	inline function get_length() return Math.sqrt(x * x + y * y);
	inline function set_length(v:Float) {
		normalize();
		multiply(v);
		return v;
	}

	public var lengthSquared(get, never):Float;
	inline function get_lengthSquared() return x * x + y * y;

	public var angle(get, never):Float;
	inline function get_angle() return Math.atan2(y, x); 
	
	public inline function new(x:Float = 0, y:Float = 0) {
		_x = x;
		_y = y;
	}

	public inline function equals(other:Vector2):Bool {
		return x == other.x && y == other.y;
	}

	public function set(x:Float, y:Float) {
		_x = x;
		_y = y;
		
		return this;
	}
	
	public inline function copyFrom(other:Vector2) {
		return set(other.x, other.y);
	}

	public inline function isZero():Bool {
		return x == 0 && y == 0;
	}

	public inline function clone() {
		return new Vector2(x, y);
	}

	public inline function normalize() {
		final ls = lengthSquared;
		if(ls != 0) divide(Math.sqrt(ls));
		return this;
	}

	public inline function dot(other:Vector2) {
		return x * other.x + y * other.y;
	}

	public inline function cross(other:Vector2) {
		return x * other.y - y * other.x;
	}

	public inline function distance(other:Vector2) {
		return Math.sqrt((other.y - y) * (other.y - y) + (other.x - x) * (other.x - x));
	}

	public inline function invert() {
		return set(-x, -y);
	}

	public extern overload inline function add(other:Vector2) {
		return set(x + other.x, y + other.y);
	}

	public extern overload inline function add(x:Float, y:Float) {
		return set(this.x + x, this.y + y);
	}

	public extern overload inline function add(v:Float) {
		return set(x + v, y + v);
	}

	public extern overload inline function subtract(other:Vector2) {
		return set(x - other.x, y - other.y);
	}

	public extern overload inline function subtract(x:Float, y:Float) {
		return set(this.x - x, this.y - y);
	}

	public extern overload inline function subtract(v:Float) {
		return set(x - v, y - v);
	}

	public extern overload inline function multiply(other:Vector2) {
		return set(x * other.x, y * other.y);
	}

	public extern overload inline function multiply(x:Float, y:Float) {
		return set(this.x * x, this.y * y);
	}

	public extern overload inline function multiply(v:Float) {
		return set(x * v, y * v);
	}

	public extern overload inline function divide(other:Vector2) {
		return set(x / other.x, y / other.y);
	}

	public extern overload inline function divide(x:Float, y:Float) {
		return set(this.x / x, this.y / y);
	}

	public extern overload inline function divide(v:Float) {
		return set(x / v, y / v);
	}

	public inline function perpendicular(clockwise:Bool = true) {
		if(clockwise) {
			set(y, -x);
		} else {
			set(-y, x);
		}
		return this;
	}

	public inline function rotate(radians:Float) {
		var ca = Math.cos(radians);
		var sa = Math.sin(radians);
		return set(ca * x - sa * y, sa * x + ca * y);
	}

	public inline function lerp(other:Vector2, t:Float) {
		return set(x + (other.x - x) * t, y + (other.y - y) * t);
	}

	public inline function transformFromAffine(m:Affine) {
		return set(x * m.a + y * m.c + m.tx, x * m.b + y * m.d + m.ty);
	}
	
	public inline function inverseTransformFromAffine(m:Affine) {
		final a = m.a;
		final b = m.b;
		final c = m.c;
		final d = m.d;
		final tx = m.tx;
		final ty = m.ty;
		final invDet = 1 / (a * d - b * c);
		final worldX = invDet * (d * (x - tx) - c * (y - ty));
		final worldY = invDet * (a * (y - ty) - b * (x - tx));
		return set(worldX, worldY);
	}

	// return angle in radians
	public inline function angleFrom(other:Vector2):Float {
		return Math.atan2(other.y - y, other.x - x);
	}

	// return angle in radians between this vector and other vector
	static public inline function AngleFrom(a:Vector2, b:Vector2):Float {
	    return a.angleFrom(b);
	}

	static public extern overload inline function Add(a:Vector2, b:Vector2) {
	    return a.clone().add(b);
	}

	static public extern overload inline function Add(a:Vector2, v:Float) {
	    return a.clone().add(v);
	}

	static public extern overload inline function Subtract(a:Vector2, b:Vector2) {
	    return a.clone().subtract(b);
	}

	static public extern overload inline function Subtract(a:Vector2, v:Float) {
	    return a.clone().subtract(v);
	}

	static public extern overload inline function Multiply(a:Vector2, b:Vector2) {
	    return a.clone().multiply(b);
	}

	static public extern overload inline function Multiply(a:Vector2, v:Float) {
	    return a.clone().multiply(v);
	}

	static public extern overload inline function Divide(a:Vector2, b:Vector2) {
	    return a.clone().divide(b);
	}

	static public extern overload inline function Divide(a:Vector2, v:Float) {
	    return a.clone().divide(v);
	}

	static public inline function Lerp(a:Vector2, b:Vector2, alpha:Float) {
	    return a.clone().lerp(b, alpha);
	}

	static public inline function Distance(a:Vector2, v:Vector2) {
	    return a.distance(v);
	}

}

@:structInit
class Vector2Callback extends Vector2 {

    public var ignoreListeners:Bool = false;
    public var listener:(v:Vector2)->Void;

    public inline function new(x:Float = 0, y:Float = 0) {
        super(x, y);
    }

    override function set(x:Float, y:Float) {
        _x = x;
        _y = y;
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

    public function listen(f:(v:Vector2)->Void) {
        listener = f;
    }

    inline function callListener() {
        if(listener != null && !ignoreListeners) {
            listener(this);
        }
    }

}

