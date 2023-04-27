package nuc.utils;

import nuc.utils.Math;

class Intersect {

	// TODO test this

	static public inline function distanceSq(dx:Float, dy:Float) {
		return dx * dx + dy * dy;
	}

	static public inline function distance(dx:Float, dy:Float) {
		return sqrt(distanceSq(dx,dy));
	}

	static public inline function pointInRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool {
		return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
	}

	static public inline function pointInCircle(px:Float, py:Float, cx:Float, cy:Float, cr:Float):Bool {
		return (px - cx) * (px - cx) + (py - cy) * (py - cy) <= cr * cr;
	}

	// point in triangle
	static public function pointInTriangle(px:Float, py:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Bool {
		var asX:Float = px - x1;
		var asY:Float = py - y1;
		var sAB:Float = (x2 - x1) * asY - (y2 - y1) * asX > 0;
		if ((x3 - x1) * asY - (y3 - y1) * asX > 0 == sAB) return false;
		if ((x3 - x2) * (py - y2) - (y3 - y2) * (px - x2) > 0 != sAB) return false;
		return true;
	}

	static public function pointInPolygon(px:Float, py:Float, poly:Array<Float>):Bool {
		var numVertices = poly.length / 2;
		var j = numVertices - 1;
		var isInside = false;
	
		for (i in 0...numVertices) {
			var x1 = poly[j * 2];
			var y1 = poly[j * 2 + 1];
			var x2 = poly[i * 2];
			var y2 = poly[i * 2 + 1];
	
			var intersect = ((y1 > py) != (y2 > py)) && (px < (x2 - x1) * (py - y1) / (y2 - y1) + x1);
	
			if (intersect) {
				isInside = !isInside;
			}
	
			j = i;
		}
	
		return isInside;
	}

	static public inline function rectRect(rx1:Float, ry1:Float, rw1:Float, rh1:Float, rx2:Float, ry2:Float, rw2:Float, rh2:Float):Bool {
		return rx1 < rx2 + rw2 && rx1 + rw1 > rx2 && ry1 < ry2 + rh2 && ry1 + rh1 > ry2;
	}

	static public inline function circleCircle(cx1:Float, cy1:Float, cr1:Float, cx2:Float, cy2:Float, cr2:Float):Bool {
		return (cx1 - cx2) * (cx1 - cx2) + (cy1 - cy2) * (cy1 - cy2) <= (cr1 + cr2) * (cr1 + cr2);
	}

	static public inline function lineLine(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		var uA:Float = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1));
		var uB:Float = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1));

		return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1;
	}

	static public function circleRect(cx:Float, cy:Float, cr:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool {
		var testX:Float = cx;
		var testY:Float = cy;

		if (cx < rx) {
			testX = rx;
		} else if (cx > rx + rw) {
			testX = rx + rw;
		}
		if (cy < ry) {
			testY = ry;
		} else if (cy > ry + rh) {
			testY = ry + rh;
		}

		return (cx - testX) * (cx - testX) + (cy - testY) * (cy - testY) <= cr * cr;
	}

	static public function lineRect(x1:Float, y1:Float, x2:Float, y2:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool {
		if (pointInRect(x1, y1, rx, ry, rw, rh) || pointInRect(x2, y2, rx, ry, rw, rh)) return true;

		if (lineLine(x1, y1, x2, y2, rx, ry, rx + rw, ry)) return true;
		if (lineLine(x1, y1, x2, y2, rx + rw, ry, rx + rw, ry + rh)) return true;
		if (lineLine(x1, y1, x2, y2, rx + rw, ry + rh, rx, ry + rh)) return true;
		if (lineLine(x1, y1, x2, y2, rx, ry + rh, rx, ry)) return true;
		
		return false;
	}
	
	static public function circleLine(cx:Float, cy:Float, cr:Float, x1:Float, y1:Float, x2:Float, y2:Float):Bool {
		if (pointInCircle(x1, y1, cx, cy, cr) || pointInCircle(x2, y2, cx, cy, cr)) return true;
	
		var dx:Float = x2 - x1;
		var dy:Float = y2 - y1;
		var a:Float = dx * dx + dy * dy;
		var b:Float = 2 * (dx * (x1 - cx) + dy * (y1 - cy));
		var c:Float = (x1 - cx) * (x1 - cx) + (y1 - cy) * (y1 - cy) - cr * cr;
		var bb4ac:Float = b * b - 4 * a * c;
	
		if (bb4ac < 0) return false;
		return true;
	}

}