package nuc.graphics.utils;

import nuc.render.Pipeline;

import nuc.graphics.Texture;
import nuc.graphics.Font;
import nuc.graphics.Color;

import nuc.math.FastMatrix3;
import nuc.math.Rectangle;
import nuc.graphics.utils.PolylineRenderer;

@:allow(nuc.Graphics)
class GraphicsState {

	public var target(default, null):Texture;

	public var pipeline(default, null):Pipeline;
	public var viewport(default, null):Rectangle;
	public var projection(default, null):FastMatrix3;
	public var transform(default, null):FastMatrix3;
	public var view(default, null):FastMatrix3;
	public var scissor(default, null):Rectangle;
	public var color(default, null):Color;
	public var opacity(default, null):Float;
	public var lineWidth(default, null):Float;
	public var lineJoint(default, null):LineJoint;
	public var lineCap(default, null):LineCap;
	public var textureFilter(default, null):TextureFilter;
	public var textureMipFilter(default, null):MipMapFilter;
	public var textureAddressing(default, null):TextureAddressing;
	public var segmentSmooth(default, null):Float;
	public var miterMinAngle(default, null):Float;
	public var font(default, null):Font;
	public var fontSize(default, null):Int;

	public var useScissor(default, null):Bool = false;

	public function new() {
		view = new FastMatrix3();
		transform = new FastMatrix3();
		scissor = new Rectangle();
		color = new Color();
	}

	function reset() {
		target = null;
		pipeline = null;

		scissor.set(0, 0, 0, 0);

		transform.identity();

		color = Color.BLACK;
		opacity = 1;

		textureFilter = TextureFilter.PointFilter;
		textureMipFilter = MipMapFilter.NoMipFilter;
		textureAddressing = TextureAddressing.Clamp;

		lineWidth = 4;
		lineJoint = LineJoint.BEVEL;
		lineCap = LineCap.BUTT;

		segmentSmooth = 5;
		miterMinAngle = 10;

		font = null;
		fontSize = 16;

		useScissor = false;
	}
	
}
