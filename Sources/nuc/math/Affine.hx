package nuc.math;

import kha.FastFloat;
import kha.simd.Float32x4;

/*
| a | c | tx |
| b | d | ty |
| 0 | 0 | 1  |
 */

abstract Affine(kha.math.FastMatrix3) from kha.math.FastMatrix3 to kha.math.FastMatrix3 {

	public var a(get, set):FastFloat;
	inline function get_a() return this._00; 
	inline function set_a(v:FastFloat) return this._00 = v;

	public var b(get, set):FastFloat;
	inline function get_b() return this._01; 
	inline function set_b(v:FastFloat) return this._01 = v;

	public var c(get, set):FastFloat;
	inline function get_c() return this._10; 
	inline function set_c(v:FastFloat) return this._10 = v;

	public var d(get, set):FastFloat;
	inline function get_d() return this._11; 
	inline function set_d(v:FastFloat) return this._11 = v;

	public var tx(get, set):FastFloat;
	inline function get_tx() return this._20; 
	inline function set_tx(v:FastFloat) return this._20 = v;

	public var ty(get, set):FastFloat;
	inline function get_ty() return this._21; 
	inline function set_ty(v:FastFloat) return this._21 = v;	
	
	public inline function new(a:FastFloat = 1, b:FastFloat = 0, c:FastFloat = 0, d:FastFloat = 1, tx:FastFloat = 0, ty:FastFloat = 0) {
		this = kha.math.FastMatrix3.identity();
		set(a, b, c, d, tx, ty);
	}

	public inline function identity():Affine {
		set(
			1, 0,
			0, 1,
			0, 0
		);

		return  this;
	}

	public inline function set(a:FastFloat, b:FastFloat, c:FastFloat, d:FastFloat, tx:FastFloat, ty:FastFloat):Affine {
		set_a(a);
		set_b(b);
		set_c(c);
		set_d(d);
		set_tx(tx);
		set_ty(ty);

		return this;
	}

	public inline function translate(x:FastFloat, y:FastFloat):Affine {
		tx += x;
		ty += y;

		return this;
	}    

	public inline function prependTranslate(x:FastFloat, y:FastFloat):Affine {
		tx += a * x + c * y;
		ty += b * x + d * y;

		return this;
	}
	
	public inline function scale(x:FastFloat, y:FastFloat):Affine {
		a *= x;
		b *= x;
		c *= y;
		d *= y;

		return this;
	}

	// https://github.com/yoshihitofujiwara/INKjs/blob/master/src/class_geometry/Matrix2.js
	public inline function skew(x:FastFloat, y:FastFloat):Affine {
		final cy:FastFloat = Math.cos(y);
		final sy:FastFloat = Math.sin(y);
		final sx:FastFloat = -Math.sin(x);
		final cx:FastFloat = Math.cos(x);

		#if (cpp && !nuc_no_simd)

		final s1 = Float32x4.loadFast(cy, cy, sx, sx);
		final s2 = Float32x4.loadFast(a, b, a, b);
		final s3 = Float32x4.loadFast(sy, sy, cx, cx);
		final s4 = Float32x4.loadFast(c, d, c, d);

		final out = Float32x4.add(Float32x4.mul(s1, s2), Float32x4.mul(s3, s4));

		a = Float32x4.getFast(out, 0);
		b = Float32x4.getFast(out, 1);
		c = Float32x4.getFast(out, 2);
		d = Float32x4.getFast(out, 3);

		#else

		final a1:FastFloat = a;
		final b1:FastFloat = b;
		final c1:FastFloat = c;
		final d1:FastFloat = d;

		a = cy * a1 + sy * c1;
		b = cy * b1 + sy * d1;
		c = sx * a1 + cx * c1;
		d = sx * b1 + cx * d1;

		#end

		return this;
	}
	
	public inline function rotate(radians:FastFloat):Affine {
		final sin:FastFloat = Math.sin(radians);
		final cos:FastFloat = Math.cos(radians);

		#if (cpp && !nuc_no_simd)

		final s1 = Float32x4.loadFast(a, b, -a, -b);
		final s2 = Float32x4.loadFast(cos, cos, sin, sin);
		final s3 = Float32x4.loadFast(c, d, c, d);
		final s4 = Float32x4.loadFast(sin, sin, cos, cos);

		final out = Float32x4.add(Float32x4.mul(s1, s2), Float32x4.mul(s3, s4));

		a = Float32x4.getFast(out, 0);
		b = Float32x4.getFast(out, 1);
		c = Float32x4.getFast(out, 2);
		d = Float32x4.getFast(out, 3);

		#else

		final a1:FastFloat = a;
		final b1:FastFloat = b;
		final c1:FastFloat = c;
		final d1:FastFloat = d;

		a = a1 * cos + c1 * sin;
		b = b1 * cos + d1 * sin;
		c = -a1 * sin + c1 * cos;
		d = -b1 * sin + d1 * cos;

		#end

		return this;
	}

	public inline function append(m:Affine):Affine {
		final a1:FastFloat = a;
		final b1:FastFloat = b;
		final c1:FastFloat = c;
		final d1:FastFloat = d;

		#if (cpp && !nuc_no_simd)

		final s1 = Float32x4.loadFast(m.a, m.a, m.c, m.c);
		final s2 = Float32x4.loadFast(a1, b1, a1, b1);
		final s3 = Float32x4.loadFast(m.b, m.b, m.d, m.d);
		final s4 = Float32x4.loadFast(c1, d1, c1, d1);

		final out = Float32x4.add(Float32x4.mul(s1, s2), Float32x4.mul(s3, s4));

		a = Float32x4.getFast(out, 0);
		b = Float32x4.getFast(out, 1);
		c = Float32x4.getFast(out, 2);
		d = Float32x4.getFast(out, 3);

		#else

        a  = m.a * a1 + m.b * c1;
        b  = m.a * b1 + m.b * d1;
        c  = m.c * a1 + m.d * c1;
        d  = m.c * b1 + m.d * d1;

		#end

        tx = m.tx * a1 + m.ty * c1 + tx;
        ty = m.tx * b1 + m.ty * d1 + ty;

		return this;
	}

	public inline function prepend(m:Affine):Affine {
		final tx1:FastFloat = tx;

		if (m.a != 1 || m.b != 0 || m.c != 0 || m.d != 1) {

			#if (cpp && !nuc_no_simd)

			final s1 = Float32x4.loadFast(a, a, c, c);
			final s2 = Float32x4.loadFast(m.a, m.b, m.a, m.b);
			final s3 = Float32x4.loadFast(b, b, d, d);
			final s4 = Float32x4.loadFast(m.c, m.d, m.c, m.d);
	
			final out = Float32x4.add(Float32x4.mul(s1, s2), Float32x4.mul(s3, s4));
	
			a = Float32x4.getFast(out, 0);
			b = Float32x4.getFast(out, 1);
			c = Float32x4.getFast(out, 2);
			d = Float32x4.getFast(out, 3);
	
			#else

			final a1:FastFloat = a;
			final c1:FastFloat = c;

			a = a1 * m.a + b * m.c;
			b = a1 * m.b + b * m.d;
			c = c1 * m.a + d * m.c;
			d = c1 * m.b + d * m.d;

			#end
		}

		tx = tx1 * m.a + ty * m.c + m.tx;
		ty = tx1 * m.b + ty * m.d + m.ty;

		return this;
	}

	public inline function orthographic(left:FastFloat, right:FastFloat, bottom:FastFloat, top:FastFloat):Affine {
		var sx:FastFloat = 1.0 / (right - left);
		var sy:FastFloat = 1.0 / (top - bottom);

		set(
			2.0*sx,      0,
			0,           2.0*sy,
			-(right+left)*sx, -(top+bottom)*sy
		);

		return this;
	}

	public inline function invert():Affine {
		var a1:FastFloat = a;
		var b1:FastFloat = b;
		var c1:FastFloat = c;
		var d1:FastFloat = d;
		var tx1:FastFloat = tx;
		var n:FastFloat = a1 * d1 - b1 * c1;

		a = d1 / n;
		b = -b1 / n;
		c = -c1 / n;
		d = a1 / n;
		tx = (c1 * ty - d1 * tx1) / n;
		ty = -(a1 * ty - b1 * tx1) / n;

		return this;
	}

	public inline function copyFrom(other:Affine):Affine {
		set(
			other.a,  other.b,
			other.c,  other.d,
			other.tx, other.ty
		);

		return this;
	}

	public inline function clone():Affine {
		return new Affine(a, b, c, d, tx, ty);
	}

	public inline function fromAffine(m:Affine):Affine {
		set(m.a, m.b, m.c, m.d, m.tx, m.ty);

		return this;
	}

	public inline function getTransformX(x:FastFloat, y:FastFloat):FastFloat {
		return a * x + c * y + tx;
	}

	public inline function getTransformY(x:FastFloat, y:FastFloat):FastFloat {
		return b * x + d * y + ty;
	}

	public inline function applyITRSS(x:FastFloat, y:FastFloat, angle:FastFloat, sx:FastFloat, sy:FastFloat, kx:FastFloat, ky:FastFloat):Affine {
		a = Math.cos(angle + ky) * sx;
		b = Math.sin(angle + ky) * sx;
		c = -Math.sin(angle - kx) * sy;
		d = Math.cos(angle - kx) * sy;

		tx = x;
		ty = y;

		return this;
	}
	
}
