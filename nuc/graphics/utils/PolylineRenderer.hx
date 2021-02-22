package nuc.graphics.utils;

import nuc.graphics.Color;
import nuc.math.FastMatrix3;
import nuc.math.FastVector2;
import nuc.utils.FastFloat;
import nuc.utils.Math;
import nuc.utils.DynamicPool;

class PolylineRenderer {

	public var lineWidth:FastFloat = 4;
	public var lineJoint:LineJoint = LineJoint.BEVEL;
	public var lineCap:LineCap = LineCap.BUTT;
	public var segmentSmooth:FastFloat = 5;
	public var miterMinAngle:FastFloat = 10/180;
	public var transformScale:FastFloat = 1;

	var g:Graphics;
	var _polySegmentPool:DynamicPool<PolySegment>;

	public function new(g:Graphics) {
		this.g = g;
		_polySegmentPool = new DynamicPool<PolySegment>(64, function() { return new PolySegment(); });
	}

	// public function setup(lineWidth:FastFloat, jointStyle:LineJoint, lineCap:LineCap, transformScale:FastFloat, segmentSmooth:FastFloat, miterMinAngle:FastFloat) {
	// 	this.lineWidth = lineWidth;
	// 	this.lineJoint = lineJoint;
	// 	this.lineCap = lineCap;
	// 	this.transformScale = transformScale;
	// 	this.segmentSmooth = segmentSmooth;
	// 	this.miterMinAngle = miterMinAngle;
	// }

	// shapes
	public function drawLine(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat) {
		drawPolyLine([x0, y0, x1, y1], false);
	}

	public function drawTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		drawPolyLine([x0, y0, x1, y1, x2, y2], true);
	}

	public function drawRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		if(w == 0 || h == 0) return;
		drawPolyLine([x, y, x+w, y, x+w, y+h, x, y+h], true);
	}

	public function drawEllipse(x:FastFloat, y:FastFloat, rx:FastFloat, ry:FastFloat, segments:Int) {
		if(ry == 0 || rx == 0) return;
		if(segments <= 0) {
			var scale = Math.sqrt(transformScale * Math.max(rx, ry));
			segments = Std.int(scale * segmentSmooth);
		}

		if(segments < 3) segments = 3;
		
		var theta:FastFloat = Math.TAU / segments;
		
		var c:FastFloat = Math.cos(theta);
		var s:FastFloat = Math.sin(theta);

		var px:FastFloat = 1;
		var py:FastFloat = 0;
		var t:FastFloat = 0;

		var points = [];

		var i:Int = 0;
		while(i < segments) {
			points.push(x + px * rx);
			points.push(y + py * ry);

			t = px;
			px = c * px - s * py;
			py = s * t + c * py;

			i++;
		}

		drawPolyLine(points, true);
	}

	public function drawArc(x:FastFloat, y:FastFloat, radius:FastFloat, angleStart:FastFloat, angle:FastFloat, segments:Int) {
		if(radius == 0 || angle == 0) return;
		
		var absAngle:FastFloat = Math.abs(angle);

		if(segments <= 0) {
			if(absAngle > Math.TAU) absAngle = Math.TAU;
			var angleScale = absAngle / Math.TAU;
			var scale = Math.sqrt(transformScale * radius * angleScale);
			segments = Std.int(scale * segmentSmooth);
		}

		if(segments < 3) segments = 3;

		var theta:FastFloat = absAngle / segments;
		
		var c:FastFloat = Math.cos(theta);
		var s:FastFloat = Math.sin(theta);

		var px:FastFloat = Math.cos(angleStart);
		var py:FastFloat = Math.sin(angleStart);
		var t:FastFloat = 0;

		var segsAdd = 0;

		if(absAngle < Math.TAU) segsAdd = 1;
		
		var points = [];

		var i:Int = 0;
		while(i < segments) {
			points.push(x + px * radius);
			points.push(y + py * radius);
			t = px;
			if(angle > 0) {
				px = px * c - py * s;
				py = t * s + py * c;
			} else {
				px = px * c + py * s;
				py = -t * s + py * c;
			}
			i++;
		}

		if(absAngle < Math.TAU) {
			points.push(x + px * radius);
			points.push(y + py * radius);
		}

		points.push(x);
		points.push(y);

		drawPolyLine(points, true);
	}

	// https://github.com/Feirell/2d-bezier/blob/master/lib/cubic-bezier.js
	public function drawCubicBezier(points:Array<FastFloat>, closed:Bool, segments:Int) {
		var drawPoints:Array<FastFloat> = [];

		var ax:FastFloat;
		var ay:FastFloat;

		var bx:FastFloat;
		var by:FastFloat;

		var cx:FastFloat;
		var cy:FastFloat;

		var dx:FastFloat;
		var dy:FastFloat;

		var t:FastFloat;
		var omt:FastFloat;

		var x:FastFloat;
		var y:FastFloat;

		var i = 0;
		var j = 0;
		while(i < points.length) {
			ax = points[i++]; ay = points[i++];
			bx = points[i++]; by = points[i++];
			cx = points[i++]; cy = points[i++];
			dx = points[i++]; dy = points[i++];

			j = 0;
			while(j <= segments) {
				t = j / segments;
				omt = 1 - t;

				x = omt * omt * omt * ax +
					3 * t * omt * omt * bx +
					3 * t * t * omt * cx +
					t * t * t * dx;

				y = omt * omt * omt * ay +
					3 * t * omt * omt * by +
					3 * t * t * omt * cy +
					t * t * t * dy;

				drawPoints.push(x);
				drawPoints.push(y);
				j++;
			}
		}
		drawPolyLine(drawPoints, closed);
	}

	// based on https://github.com/CrushedPixel/Polyline2D
	public function drawPolyLine(points:Array<FastFloat>, closed:Bool = false) {
		var thickness = lineWidth / 2;

		var tScale = Math.sqrt(transformScale * thickness);
		var s = Std.int(transformScale * segmentSmooth);
		var roundMinAngle:FastFloat = Math.TAU / s;

		var segments:Array<PolySegment> = [];

		var p0x:FastFloat;
		var p0y:FastFloat;
		var p1x:FastFloat;
		var p1y:FastFloat;
		var seg:PolySegment;

		var i:Int = 0;
		while (i < points.length - 3) {
			p0x = points[i];
			p0y = points[i + 1];
			p1x = points[i + 2];
			p1y = points[i + 3];

			if(p0x != p1x || p0y != p1y) {
				seg = _polySegmentPool.get();
				seg.set(p0x, p0y, p1x, p1y, thickness);
				segments.push(seg);
			}
			i += 2;
		}

		if (closed) {
			p0x = points[points.length - 2];
			p0y = points[points.length - 1];
			p1x = points[0];
			p1y = points[1];

			if(p0x != p1x || p0y != p1y) {
				seg = _polySegmentPool.get();
				seg.set(p0x, p0y, p1x, p1y, thickness);
				segments.push(seg);
			}
		}

		if (segments.length == 0) return;
		
		var firstSegment = segments[0];
		var lastSegment = segments[segments.length - 1];

		var pathStart1 = firstSegment.edge1.a;
		var pathStart2 = firstSegment.edge2.a;
		var pathEnd1 = lastSegment.edge1.b;
		var pathEnd2 = lastSegment.edge2.b;

		if (closed) {
			drawJoint(lastSegment, firstSegment, pathEnd1, pathEnd2, pathStart1, pathStart2, roundMinAngle, miterMinAngle);
		} else if (lineCap == LineCap.SQUARE) {
			pathStart1.subtract(FastVector2.MultiplyScalar(firstSegment.edge1.direction(), thickness));
			pathStart2.subtract(FastVector2.MultiplyScalar(firstSegment.edge2.direction(), thickness));
			pathEnd1.add(FastVector2.MultiplyScalar(lastSegment.edge1.direction(), thickness));
			pathEnd2.add(FastVector2.MultiplyScalar(lastSegment.edge2.direction(), thickness));
		} else if (lineCap == LineCap.ROUND) {
			drawTriangleFan(firstSegment.center.a, firstSegment.center.a, firstSegment.edge1.a, firstSegment.edge2.a, false, roundMinAngle);
			drawTriangleFan(lastSegment.center.b, lastSegment.center.b, lastSegment.edge1.b, lastSegment.edge2.b, true, roundMinAngle);
		}

		var start1 = pathStart1.clone();
		var start2 = pathStart2.clone();
		var nextStart1 = new FastVector2(0, 0);
		var nextStart2 = new FastVector2(0, 0);
		var end1 = new FastVector2(0, 0);
		var end2 = new FastVector2(0, 0);

		i = 0;
		while(i < segments.length) {
			var segment = segments[i];

			if (i + 1 == segments.length) {
				end1.copyFrom(pathEnd1);
				end2.copyFrom(pathEnd2);
			} else {
				drawJoint(segment, segments[i + 1], end1, end2, nextStart1, nextStart2, roundMinAngle, miterMinAngle);
			}

			g.beginGeometry(null, 4, 6);

			g.addVertex(start1.x, start1.y, Color.WHITE);
			g.addVertex(end1.x, end1.y, Color.WHITE);
			g.addVertex(end2.x, end2.y, Color.WHITE);
			g.addVertex(start2.x, start2.y, Color.WHITE);

			g.addIndex(0);
			g.addIndex(1);
			g.addIndex(2);

			g.addIndex(0);
			g.addIndex(2);
			g.addIndex(3);

			g.endGeometry();

			start1.copyFrom(nextStart1);
			start2.copyFrom(nextStart2);

			_polySegmentPool.put(segment);
			i++;
		}
	}

	inline function drawJoint(segment1:PolySegment, segment2:PolySegment, end1:FastVector2, end2:FastVector2, nextStart1:FastVector2, nextStart2:FastVector2, roundMinAngle:FastFloat, miterMinAngle:FastFloat) {
		var dir1 = segment1.center.direction();
		var dir2 = segment2.center.direction();

		var dot = dir1.dot(dir2);
		var clockwise = dir1.cross(dir2) < 0;

		if (lineJoint == LineJoint.MITER && dot < -1 + miterMinAngle) lineJoint = LineJoint.BEVEL;

		var inner1:LineSegment = null;
		var inner2:LineSegment = null;
		var outer1:LineSegment = null;
		var outer2:LineSegment = null;

		if (clockwise) {
			outer1 = segment1.edge1;
			outer2 = segment2.edge1;
			inner1 = segment1.edge2;
			inner2 = segment2.edge2;
		} else {
			outer1 = segment1.edge2;
			outer2 = segment2.edge2;
			inner1 = segment1.edge1;
			inner2 = segment2.edge1;
		}

		var iVec = segment1.center.b.clone();
		var innerSecOpt = LineSegment.intersection(inner1, inner2, false, iVec);
		var innerSec:FastVector2 = inner1.b;
		var innerStart:FastVector2 = inner2.a;

		if(innerSecOpt) {
			innerSec = iVec;
			innerStart = innerSec;
		}

		if (clockwise) {
			end1.copyFrom(outer1.b);
			end2.copyFrom(innerSec);

			nextStart1.copyFrom(outer2.a);
			nextStart2.copyFrom(innerStart);
		} else {
			end1.copyFrom(innerSec);
			end2.copyFrom(outer1.b);

			nextStart1.copyFrom(innerStart);
			nextStart2.copyFrom(outer2.a);
		}

		if(lineJoint == LineJoint.MITER){
			var oVec = new FastVector2(0, 0);
			if(LineSegment.intersection(outer1, outer2, true, oVec)) {
				g.beginGeometry(null, 4, 6);

				g.addVertex(outer1.b.x, outer1.b.y, Color.WHITE);
				g.addVertex(oVec.x, oVec.y, Color.WHITE);
				g.addVertex(outer2.a.x, outer2.a.y, Color.WHITE);
				g.addVertex(iVec.x, iVec.y, Color.WHITE);

				g.addIndex(0);
				g.addIndex(1);
				g.addIndex(2);

				g.addIndex(0);
				g.addIndex(2);
				g.addIndex(3);

				g.endGeometry();
			}
		} else if(lineJoint == LineJoint.BEVEL) {
			g.beginGeometry(null, 3, 3);

			g.addVertex(outer1.b.x, outer1.b.y, Color.WHITE);
			g.addVertex(outer2.a.x, outer2.a.y, Color.WHITE);
			g.addVertex(iVec.x, iVec.y, Color.WHITE);

			g.addIndex(0);
			g.addIndex(1);
			g.addIndex(2);

			g.endGeometry();
		} else if(lineJoint == LineJoint.ROUND) {
			drawTriangleFan(iVec, segment1.center.b, outer1.b, outer2.a, clockwise, roundMinAngle);
		}
	}

	inline function drawTriangleFan(connectTo:FastVector2, origin:FastVector2, start:FastVector2, end:FastVector2, clockwise:Bool, roundMinAngle:FastFloat) {
		var p1x:FastFloat = start.x - origin.x;
		var p1y:FastFloat = start.y - origin.y;

		var p2x:FastFloat = end.x - origin.x;
		var p2y:FastFloat = end.y - origin.y;

		var angle1 = Math.atan2(p1y, p1x);
		var angle2 = Math.atan2(p2y, p2x);

		if (clockwise) {
			if (angle2 > angle1) angle2 = angle2 - Math.TAU;
		} else {
			if (angle1 > angle2) angle1 = angle1 - Math.TAU;
		}

		var jointAngle = angle2 - angle1;

		var numTriangles = Std.int(Math.max(1, Math.abs(jointAngle) / roundMinAngle));
		var theta:FastFloat = jointAngle / numTriangles;
		
		var c:FastFloat = Math.cos(theta);
		var s:FastFloat = Math.sin(theta);

		var px:FastFloat = c * p1x - s * p1y;
		var py:FastFloat = s * p1x + c * p1y;
		var t:FastFloat = 0;
		var i:Int = 0;

		var startPoint:FastVector2 = start.clone();
		var endPoint:FastVector2 = new FastVector2(0,0);

		var lastIdx = numTriangles * 2;
		g.beginGeometry(null, numTriangles * 2 + 1, numTriangles * 3);
		while(i < numTriangles) {
			if (i + 1 == numTriangles) {
				endPoint.copyFrom(end);
			} else {
				endPoint.set(origin.x + px, origin.y + py);
				t = px;
				px = c * px - s * py;
				py = s * t + c * py;
			}

			g.addVertex(startPoint.x, startPoint.y, Color.WHITE);
			g.addVertex(endPoint.x, endPoint.y, Color.WHITE);

			g.addIndex(i * 2);
			g.addIndex(i * 2 + 1);
			g.addIndex(lastIdx);

			startPoint.copyFrom(endPoint);
			i++;
		}
		g.addVertex(connectTo.x, connectTo.y, Color.WHITE);
		g.endGeometry();
	}
}

private class LineSegment {

	public var a:FastVector2;
	public var b:FastVector2;

	public inline function new(a:FastVector2, b:FastVector2) {
		this.a = a;
		this.b = b;
	}

	public inline function direction(normalized:Bool = true):FastVector2 {
		var vec = new FastVector2(b.x - a.x, b.y - a.y);
		if(normalized) vec.normalize();
		return vec;
	}

	public static function intersection(segA:LineSegment, segB:LineSegment, infiniteLines:Bool, into:FastVector2):Bool {
		var r = segA.direction(false);
		var s = segB.direction(false);

		var originDist = FastVector2.Subtract(segB.a, segA.a);

		var uNumerator:FastFloat = originDist.cross(r);
		var denominator:FastFloat = r.cross(s);

		// if (Math.abs(denominator) < 0.0001) {
		if (Math.abs(denominator) <= 0) return false;

		var u:FastFloat = uNumerator / denominator;
		var t:FastFloat = originDist.cross(s) / denominator;

		if (!infiniteLines && (t < 0 || t > 1 || u < 0 || u > 1)) return false;

		into.x = segA.a.x + r.x * t;
		into.y = segA.a.y + r.y * t;

		return true;
	}

}

private class PolySegment {

	public var center:LineSegment;
	public var edge1:LineSegment;
	public var edge2:LineSegment;

	public function new() {
		center = new LineSegment(new FastVector2(0,0), new FastVector2(0,0));
		edge1 = new LineSegment(new FastVector2(0,0), new FastVector2(0,0));
		edge2 = new LineSegment(new FastVector2(0,0), new FastVector2(0,0));
	}

	public function set(p0x:FastFloat, p0y:FastFloat, p1x:FastFloat, p1y:FastFloat, thickness:FastFloat) {
		center.a.set(p0x, p0y);
		center.b.set(p1x, p1y);

		var dx:FastFloat = p1x - p0x;
		var dy:FastFloat = p1y - p0y;

		var len:FastFloat = Math.sqrt(dx * dx + dy * dy);
		var tmp:FastFloat = dx;

		dx = -(dy / len) * thickness;
		dy = (tmp / len) * thickness;

		edge1.a.set(p0x + dx, p0y + dy);
		edge1.b.set(p1x + dx, p1y + dy);

		edge2.a.set(p0x - dx, p0y - dy);
		edge2.b.set(p1x - dx, p1y - dy);
	}

}


enum abstract LineJoint(Int) {
	var MITER;
	var BEVEL;
	var ROUND;
}

enum abstract LineCap(Int) from Int to Int {
	var BUTT;
	var SQUARE;
	var ROUND;
	// var JOINT;
}
