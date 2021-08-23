package nuc;

import kha.Framebuffer;
import kha.simd.Float32x4;

import nuc.Nuc;

import nuc.graphics.Pipeline;
import nuc.graphics.VertexBuffer;
import nuc.graphics.IndexBuffer;
import nuc.graphics.VertexStructure;
import nuc.graphics.Shaders;

import nuc.graphics.Texture;
import nuc.graphics.Font;
import nuc.graphics.Color;

import nuc.math.FastMatrix3;
import nuc.math.Vector2;
import nuc.math.FastVector2;
import nuc.math.Rectangle;

import nuc.utils.Math;
import nuc.utils.Float32Array;
import nuc.utils.Uint32Array;
import nuc.utils.DynamicPool;
import nuc.utils.Log;
import nuc.utils.Common.*;
import nuc.utils.FastFloat;

using StringTools;

@:allow(nuc.App)
class Graphics {

	static public var pipelineTextured:Pipeline;
	static public var frameBuffer:Framebuffer;

	static var vertexBuffer:VertexBuffer;
	static var indexBuffer:IndexBuffer;
	static var blitProjection:FastMatrix3;

	static public function setup() {
		var structure = new VertexStructure();
		structure.add("position", VertexData.Float2);
		structure.add("color", VertexData.Float4);
		structure.add("texCoord", VertexData.Float2);

		pipelineTextured = new Pipeline([structure], Shaders.textured_vert, Shaders.textured_frag);
		pipelineTextured.setBlending(BlendFactor.BlendOne, BlendFactor.InverseSourceAlpha, BlendOperation.Add);
		pipelineTextured.compile();

		blitProjection = new FastMatrix3();
		initBuffers();
	}

	static public function blit(src:Texture, ?dst:Texture, ?pipeline:Pipeline, 
		clearDst:Bool = true, bilinear:Bool = true,
		scaleX:FastFloat = 1, scaleY:FastFloat = 1, offsetX:FastFloat = 0, offsetY:FastFloat = 0
	) {
		Log.assert(Nuc.graphics.target == null, 'Graphics: has active render target, end before you blit');

		var g:kha.graphics4.Graphics;
		if(dst != null) {
			Log.assert(dst.isRenderTarget, 'Graphics.blit with non renderTarget destination texture');
			g = dst.image.g4;

			if (Texture.renderTargetsInvertedY) {
				blitProjection.orto(0, dst.widthActual, 0, dst.heightActual);
			} else {
				blitProjection.orto(0, dst.widthActual, dst.heightActual, 0);
			}
		} else {
			g = frameBuffer.g4;	
			
			blitProjection.orto(0, frameBuffer.width, frameBuffer.height, 0);
		}

		if(pipeline == null) pipeline = Graphics.pipelineTextured;
		
		setBlitVertices(offsetX, offsetY, src.widthActual * scaleX, src.heightActual * scaleY);

		g.begin();
		if(clearDst) g.clear(Color.BLACK);

		var textureUniform = pipeline.setTexture('tex', src);
		pipeline.setTextureParameters('tex', 
			TextureAddressing.Clamp, TextureAddressing.Clamp, 
			bilinear ? TextureFilter.LinearFilter : TextureFilter.PointFilter, bilinear ? TextureFilter.LinearFilter : TextureFilter.PointFilter,
			MipMapFilter.NoMipFilter
		);
		pipeline.setMatrix3('projectionMatrix', blitProjection);
		pipeline.use(g);
		pipeline.apply(g);

		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);

		g.drawIndexedVertices(0, 6);

		g.setTexture(textureUniform.location, null);
		g.end();
	}

	@:allow(nuc.App)
	static function setFramebuffer(f:Array<Framebuffer>) {
		frameBuffer = f[0];
	}

	static function initBuffers() {
		var pipeline = Graphics.pipelineTextured;
		vertexBuffer = new VertexBuffer(4, pipeline.inputLayout[0], Usage.StaticUsage);

		var vertices = vertexBuffer.lock();
		// color
		vertices[2] = 1; vertices[3] = 1; vertices[4] = 1; vertices[5] = 1;
		vertices[10] = 1; vertices[11] = 1; vertices[12] = 1; vertices[13] = 1;
		vertices[18] = 1; vertices[19] = 1; vertices[20] = 1; vertices[21] = 1;
		vertices[26] = 1; vertices[27] = 1; vertices[28] = 1; vertices[29] = 1;
		// uv
		vertices[6] = 0; vertices[7] = 0;
		vertices[14] = 1; vertices[15] = 0;
		vertices[22] = 1; vertices[23] = 1;
		vertices[30] = 0; vertices[31] = 1;
		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(6, Usage.StaticUsage);

		var indices = indexBuffer.lock();
		indices[0] = 0; indices[1] = 1; indices[2] = 2;
		indices[3] = 0; indices[4] = 2; indices[5] = 3;
		indexBuffer.unlock();
	}

	static function setBlitVertices(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {		
		var vertices = vertexBuffer.lock();
		vertices[0] = x;
		vertices[1] = y;

		vertices[8] = x + w;
		vertices[9] = y;

		vertices[16] = x + w;
		vertices[17] = y + h;

		vertices[24] = x;
		vertices[25] = y + h;
		vertexBuffer.unlock();
	}
	
	public var target(default, null):Texture;
	var _g4:kha.graphics4.Graphics;

	public function new() {}

	public function begin(?target:Texture) {
		this.target = target;

		if (target == null) {
			_g4 = frameBuffer.g4;
		} else {
			Log.assert(target.isRenderTarget, 'Graphics: begin with non renderTarget texture');
			_g4 = target.image.g4;
		}
		_g4.begin();
	}

	public function clear(?clearColor:Color) {
		Log.assert(_g4 != null, 'Graphics: begin before you clear');
		_g4.clear(clearColor != null ? clearColor : Color.BLACK);
	}

	public function end() {
		Log.assert(_g4 != null, 'Graphics: begin before you end');
		_g4.end();
		target = null;
		_g4 = null;
	}

	public function viewport(x:Float, y:Float, w:Float, h:Float) {
		Log.assert(_g4 != null, 'Graphics: begin before you set viewport');
		_g4.viewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
	}

	public function scissor(x:Float, y:Float, w:Float, h:Float) {
		Log.assert(_g4 != null, 'Graphics: begin before you set scissor');
		_g4.scissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
	}

	public function disableScissor() {
		_g4.disableScissor();
	}

	public function setVertexBuffer(vertexBuffer:VertexBuffer) {
		Log.assert(_g4 != null, 'Graphics: begin before you setVertexBuffer');
		_g4.setVertexBuffer(vertexBuffer);
	}

	public function setVertexBuffers(vertexBuffers:Array<VertexBuffer>) {
		Log.assert(_g4 != null, 'Graphics: begin before you setVertexBuffers');
		_g4.setVertexBuffers(vertexBuffers);
	}

	public function setIndexBuffer(indexBuffer:IndexBuffer) {
		Log.assert(_g4 != null, 'Graphics: begin before you setIndexBuffer');
		_g4.setIndexBuffer(indexBuffer);
	}

	public function setPipeline(pipeline:Pipeline) {
		Log.assert(_g4 != null, 'Graphics: begin before you usePipeline');
		pipeline.use(_g4);
	}

	public function applyUniforms(pipeline:Pipeline) {
		Log.assert(_g4 != null, 'Graphics: begin before you applyUniforms');
		pipeline.apply(_g4);
	}

	public function draw(start:Int = 0, count:Int = -1) {
		Log.assert(_g4 != null, 'Graphics: begin before you draw');
		_g4.drawIndexedVertices(start, count);
	}

	public function drawInstanced(instances:Int, start:Int = 0, count:Int = -1) {
		Log.assert(_g4 != null, 'Graphics: begin before you draw');
		_g4.drawIndexedVerticesInstanced(instances, start, count);
	}
	
}
