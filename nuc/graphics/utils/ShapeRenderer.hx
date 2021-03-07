package nuc.graphics.utils;

import nuc.graphics.utils.Batcher;
import nuc.utils.FastFloat;
import nuc.utils.Math;
import nuc.math.FastMatrix3;

class ShapeRenderer {

	public var segmentSmooth:FastFloat = 5;
	public var transformScale:FastFloat = 1;

	var b:Batcher;

	public function new(b:Batcher) {
		this.b = b;
	}

	public function fillTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		b.beginGeometry(null, 3, 3);

		b.addVertex(x0, y0);
		b.addVertex(x1, y1);
		b.addVertex(x2, y2);
		b.addIndex(0);
		b.addIndex(1);
		b.addIndex(2);

		b.endGeometry();
	}
	public function fillRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		if(w == 0 || h == 0) return;

		b.beginGeometry(null, 4, 6);
		b.addQuadGeometry(x, y, w, h);
		b.endGeometry();
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

		b.beginGeometry(null, segments+1, segments*3);

		var i:Int = 0;
		while(i < segments) {
			b.addVertex(x + px * rx, y + py * ry);

			t = px;
			px = c * px - s * py;
			py = s * t + c * py;

			b.addIndex(i);
			b.addIndex((i+1) % segments);
			b.addIndex(segments);
			i++;
		}
		b.addVertex(x, y);

		b.endGeometry();
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
		
		b.beginGeometry(null, segments+segsAdd+1, segments*3+3);

		var i:Int = 0;
		while(i < segments) {
			b.addVertex(x + px * radius, y + py * radius);
			t = px;
			if(angle > 0) {
				px = px * c - py * s;
				py = t * s + py * c;
			} else {
				px = px * c + py * s;
				py = -t * s + py * c;
			}

			b.addIndex(i);
			b.addIndex((i+1) % (segments + segsAdd));
			b.addIndex(segments + segsAdd);

			i++;
		}

		if(absAngle < Math.TAU) b.addVertex(x + px * radius, y + py * radius);
		
		b.addVertex(x, y);

		b.addIndex(0);
		b.addIndex(segments);
		b.addIndex(segments + segsAdd);

		b.endGeometry();
	}

	public function fillPolygon(points:Array<FastFloat>, indices:Array<Int>, ?colors:Array<Color>) {
		b.beginGeometry(null, points.length, indices.length);
		var i:Int = 0;
		if(colors != null) {
			while(i < points.length) {
				b.addVertex(points[i], points[i+1], colors[i]);
				i+=2;
			}
		} else {
			while(i < points.length) b.addVertex(points[i++], points[i++]);
		}
		i = 0;
		while(i < indices.length) b.addIndex(indices[i++]);
		b.endGeometry();
	}

}