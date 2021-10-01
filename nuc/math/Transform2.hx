package nuc.math;

/*
| a | c | tx |
| b | d | ty |
| 0 | 0 | 1  |
 */
 
class Transform2 {

	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx:Float;
	public var ty:Float;

	public function new(a:Float = 1, b:Float = 0, c:Float = 0, d:Float = 1, tx:Float = 0, ty:Float = 0) {
		set(a, b, c, d, tx, ty);
	}

	public inline function identity():Transform2 {
		set(
			1, 0,
			0, 1,
			0, 0
		);

		return this;
	}

	public inline function set(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Transform2 {
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;

		return this;
	}

	public inline function translate(x:Float, y:Float):Transform2 {
		tx += x;
		ty += y;

		return this;
	}    

	public inline function prependTranslate(x:Float, y:Float):Transform2 {
		tx = a * x + c * y + tx;
		ty = b * x + d * y + ty;

		return this;
	}
	
	public inline function scale(x:Float, y:Float):Transform2 {
		a *= x;
		b *= x;
		tx *= x;
		c *= y;
		d *= y;
		ty *= y;

		return this;
	}

	// https://github.com/yoshihitofujiwara/INKjs/blob/master/src/class_geometry/Matrix2.js
	public inline function shear(x:Float, y:Float):Transform2 {
		var cy:Float = Math.cos(y);
		var sy:Float = Math.sin(y);
		var sx:Float = -Math.sin(x);
		var cx:Float = Math.cos(x);

		var a1:Float = a;
		var b1:Float = b;
		var c1:Float = c;
		var d1:Float = d;

		a = (cy * a1) + (sy * c1);
		b = (cy * b1) + (sy * d1);
		c = (sx * a1) + (cx * c1);
		d = (sx * b1) + (cx * d1);

		return this;
	}
	
	public inline function rotate(radians:Float):Transform2 {
		var sin:Float = Math.sin(radians);
		var cos:Float = Math.cos(radians);

		var a1:Float = a;
		var b1:Float = b;
		var c1:Float = c;
		var d1:Float = d;

		a = a1 * cos + c1 * sin;
		b = b1 * cos + d1 * sin;
		c = -a1 * sin + c1 * cos;
		d = -b1 * sin + d1 * cos;

		return this;
	}

	public inline function append(m:Transform2):Transform2 {
        var a1 = a;
        var b1 = b;
        var c1 = c;
        var d1 = d;

        a  = m.a * a1 + m.b * c1;
        b  = m.a * b1 + m.b * d1;
        c  = m.c * a1 + m.d * c1;
        d  = m.c * b1 + m.d * d1;

        tx = m.tx * a1 + m.ty * c1 + tx;
        ty = m.tx * b1 + m.ty * d1 + ty;

		return this;
	}

	public inline function prepend(m:Transform2):Transform2 {
	    var tx1 = tx;

	    if (m.a != 1 || m.b != 0 || m.c != 0 || m.d != 1) {
	        var a1 = a;
	        var c1 = c;

	        a = a1 * m.a + b * m.c;
	        b = a1 * m.b + b * m.d;
	        c = c1 * m.a + d * m.c;
	        d = c1 * m.b + d * m.d;
	    }

	    tx = tx1 * m.a + ty * m.c + m.tx;
	    ty = tx1 * m.b + ty * m.d + m.ty;

	    return this;
	}

	public inline function orto(left:Float, right:Float, bottom:Float, top:Float):Transform2 {
		var sx:Float = 1.0 / (right - left);
		var sy:Float = 1.0 / (top - bottom);

		set(
			2.0*sx,      0,
			0,           2.0*sy,
			-(right+left)*sx, -(top+bottom)*sy
		);

		return this;
	}

	public inline function invert():Transform2 {
		var a1:Float = a;
		var b1:Float = b;
		var c1:Float = c;
		var d1:Float = d;
		var tx1:Float = tx;
		var n:Float = a1 * d1 - b1 * c1;

		a = d1 / n;
		b = -b1 / n;
		c = -c1 / n;
		d = a1 / n;
		tx = (c1 * ty - d1 * tx1) / n;
		ty = -(a1 * ty - b1 * tx1) / n;

		return this;
	}

	public inline function copyFrom(other:Transform2):Transform2 {
		set(
			other.a,  other.b,
			other.c,  other.d,
			other.tx, other.ty
		);

		return this;
	}

	public inline function clone():Transform2 {
		return new Transform2(a, b, c, d, tx, ty);
	}

	public inline function fromFastTransform2(m:FastTransform2):Transform2 {
		set(m.a, m.b, m.c, m.d, m.tx, m.ty);
		return this;
	}

	public inline function getTransformX(x:Float, y:Float):Float {
		return a * x + c * y + tx;
	}

	public inline function getTransformY(x:Float, y:Float):Float {
		return b * x + d * y + ty;
	}

	public function setTransform(x:Float, y:Float, angle:Float, sx:Float, sy:Float, ox:Float, oy:Float, kx:Float, ky:Float):Transform2 {
		var sin:Float = Math.sin(angle);
		var cos:Float = Math.cos(angle);

		a = cos * sx - ky * sin * sy;
		b = sin * sx + ky * cos * sy;
		c = kx * cos * sx - sin * sy;
		d = kx * sin * sx + cos * sy;
		tx = x - ox * a - oy * c;
		ty = y - ox * b - oy * d;
		
		return this;
	}
	
}