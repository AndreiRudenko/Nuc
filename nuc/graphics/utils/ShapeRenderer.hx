package nuc.graphics.utils;

import nuc.utils.FastFloat;
import nuc.utils.Math;
import nuc.math.FastMatrix3;

class ShapeRenderer {

	public var segmentSmooth:FastFloat = 5;
	public var transformScale:FastFloat = 1;

	var g:Graphics;

	public function new(g:Graphics) {
		this.g = g;
	}

	public function fillTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		g.beginGeometry(null, 3, 3);

		g.addVertex(x0, y0);
		g.addVertex(x1, y1);
		g.addVertex(x2, y2);
		g.addIndex(0);
		g.addIndex(1);
		g.addIndex(2);

		g.endGeometry();
	}
	public function fillRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		if(w == 0 || h == 0) return;

		g.beginGeometry(null, 4, 6);

		g.addVertex(x, y);
		g.addVertex(x+w, y);
		g.addVertex(x+w, y+h);
		g.addVertex(x, y+h);
		g.addIndex(0);
		g.addIndex(1);
		g.addIndex(2);
		g.addIndex(0);
		g.addIndex(2);
		g.addIndex(3);

		g.endGeometry();
	}

	public function fillEllipse(x:FastFloat, y:FastFloat, rx:FastFloat, ry:FastFloat, segments:Int) {
		if(rx == 0 || ry == 0) return;

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

		g.beginGeometry(null, segments+1, segments*3);

		var i:Int = 0;
		while(i < segments) {
			g.addVertex(x + px * rx, y + py * ry);

			t = px;
			px = c * px - s * py;
			py = s * t + c * py;

			g.addIndex(i);
			g.addIndex((i+1) % segments);
			g.addIndex(segments);
			i++;
		}
		g.addVertex(x, y);

		g.endGeometry();
	}

	public function fillArc(x:FastFloat, y:FastFloat, radius:FastFloat, angleStart:FastFloat, angle:FastFloat, segments:Int) {
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
		
		g.beginGeometry(null, segments+segsAdd+1, segments*3+3);

		var i:Int = 0;
		while(i < segments) {
			g.addVertex(x + px * radius, y + py * radius);
			t = px;
			if(angle > 0) {
				px = px * c - py * s;
				py = t * s + py * c;
			} else {
				px = px * c + py * s;
				py = -t * s + py * c;
			}

			g.addIndex(i);
			g.addIndex((i+1) % (segments + segsAdd));
			g.addIndex(segments + segsAdd);

			i++;
		}

		if(absAngle < Math.TAU) g.addVertex(x + px * radius, y + py * radius);
		
		g.addVertex(x, y);

		g.addIndex(0);
		g.addIndex(segments);
		g.addIndex(segments + segsAdd);

		g.endGeometry();
	}

	public function fillPolygon(points:Array<FastFloat>, indices:Array<Int>, ?colors:Array<Color>) {
		g.beginGeometry(null, points.length, indices.length);
		var i:Int = 0;
		if(colors != null) {
			while(i < points.length) {
				g.addVertex(points[i], points[i+1], colors[i]);
				i+=2;
			}
		} else {
			while(i < points.length) g.addVertex(points[i++], points[i++]);
		}
		i = 0;
		while(i < indices.length) g.addIndex(indices[i++]);
		g.endGeometry();
	}

}