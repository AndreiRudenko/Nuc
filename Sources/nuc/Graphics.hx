package nuc;

import nuc.graphics.ScissorStack;
import kha.Framebuffer;
import kha.simd.Float32x4;

import nuc.rendering.Pipeline;
import nuc.rendering.VertexBuffer;
import nuc.rendering.IndexBuffer;
import nuc.rendering.VertexStructure;
import nuc.rendering.Shaders;

import nuc.graphics.Texture;
import nuc.graphics.Color;

import nuc.math.Matrix4;
import nuc.math.Vector2;
import nuc.math.Rectangle;

import nuc.utils.Math;
import nuc.utils.Float32Array;
import nuc.utils.Uint32Array;
import nuc.utils.DynamicPool;
import nuc.utils.Log;
import nuc.utils.Common.*;

using StringTools;

@:allow(nuc.App)
class Graphics {

	static public var pipelineTextured(default, null):Pipeline;
	static var frameBuffer(default, null):Framebuffer;

	static var vertexBuffer:VertexBuffer;
	static var indexBuffer:IndexBuffer;
	static var blitProjection:Matrix4;

	@:allow(nuc.App)
	static function setup() {
		var structure = new VertexStructure();
		structure.add("position", VertexData.Float32_2X);
		structure.add("color", VertexData.UInt8_4X_Normalized);
		structure.add("texCoord", VertexData.Float32_2X);

		pipelineTextured = new Pipeline([structure], Shaders.textured_vert, Shaders.textured_frag);
		pipelineTextured.setBlending(BlendFactor.BlendOne, BlendFactor.InverseSourceAlpha, BlendOperation.Add);
		pipelineTextured.compile();

		blitProjection = new Matrix4();
		initBuffers();
	}

	static public function blit(src:Texture, ?dst:Texture, ?pipeline:Pipeline, 
		clearDst:Bool = true, bilinear:Bool = true,
		scaleX:Float = 1, scaleY:Float = 1, offsetX:Float = 0, offsetY:Float = 0
	) {
		Log.assert(g4 == null, 'Graphics: has active render target, end before you blit');

		var g:kha.graphics4.Graphics;
		if(dst != null) {
			Log.assert(dst.isRenderTarget, 'Graphics.blit with non renderTarget destination texture');
			g = dst.image.g4;
			
			if (Texture.renderTargetsInvertedY) {
				blitProjection.orthographic(0, dst.widthActual, 0, dst.heightActual, 0.1, 1000);
			} else {
				blitProjection.orthographic(0, dst.widthActual, dst.heightActual, 0, 0.1, 1000);
			}
		} else {
			g = frameBuffer.g4;	
			
			blitProjection.orthographic(0, frameBuffer.width, frameBuffer.height, 0, 0.1, 1000);
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
		pipeline.setMatrix4('projectionMatrix', blitProjection);
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
		final pipeline = Graphics.pipelineTextured;
		vertexBuffer = new VertexBuffer(4, pipeline.inputLayout[0], Usage.StaticUsage);

		final vertices = vertexBuffer.lock();
		// color
		vertices.setUint32(2 * 4, 0xFFFFFFFF);
		vertices.setUint32(7 * 4, 0xFFFFFFFF);
		vertices.setUint32(12 * 4, 0xFFFFFFFF);
		vertices.setUint32(17 * 4, 0xFFFFFFFF);
		
		// uv
		vertices.setFloat32(3 * 4, 0); 
		vertices.setFloat32(4 * 4, 0);

		vertices.setFloat32(8 * 4, 1); 
		vertices.setFloat32(9 * 4, 0);

		vertices.setFloat32(13 * 4, 1); 
		vertices.setFloat32(14 * 4, 1);

		vertices.setFloat32(18 * 4, 0); 
		vertices.setFloat32(19 * 4, 1);

		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(6, Usage.StaticUsage);

		final indices = indexBuffer.lock();
		indices[0] = 0; indices[1] = 1; indices[2] = 2;
		indices[3] = 0; indices[4] = 2; indices[5] = 3;
		indexBuffer.unlock();
	}

	static function setBlitVertices(x:Float, y:Float, w:Float, h:Float) {		
		var vertices = vertexBuffer.lock();
		vertices.setFloat32(0 * 4, x);
		vertices.setFloat32(1 * 4, y);

		vertices.setFloat32(5 * 4, x + w);
		vertices.setFloat32(6 * 4, y);

		vertices.setFloat32(10 * 4, x + w);
		vertices.setFloat32(11 * 4, y + h);

		vertices.setFloat32(15 * 4, x);
		vertices.setFloat32(16 * 4, y + h);
		vertexBuffer.unlock();
	}

	static var g4:kha.graphics4.Graphics;

	static public function begin(?target:Texture) {
		Log.assert(g4 == null, 'Graphics: end before you begin');

		if (target == null) {
			g4 = frameBuffer.g4;
		} else {
			Log.assert(target.isRenderTarget, 'Graphics: begin with non renderTarget texture');
			g4 = target.image.g4;
		}
		g4.begin();
	}

	static public function clear(?clearColor:Color) {
		Log.assert(g4 != null, 'Graphics: begin before you clear');
		g4.clear(clearColor != null ? clearColor : Color.BLACK);
	}

	static public function end() {
		Log.assert(g4 != null, 'Graphics: begin before you end');
		g4.end();
		g4 = null;
	}

	static public function viewport(x:Float, y:Float, w:Float, h:Float) {
		Log.assert(g4 != null, 'Graphics: begin before you set viewport');
		g4.viewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
	}

	static public function scissor(x:Float, y:Float, w:Float, h:Float) {
		Log.assert(g4 != null, 'Graphics: begin before you set scissor');
		g4.scissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
	}

	static public function disableScissor() {
		g4.disableScissor();
	}

	static public function setVertexBuffer(vertexBuffer:VertexBuffer) {
		Log.assert(g4 != null, 'Graphics: begin before you setVertexBuffer');
		g4.setVertexBuffer(vertexBuffer);
	}

	static public function setVertexBuffers(vertexBuffers:Array<VertexBuffer>) {
		Log.assert(g4 != null, 'Graphics: begin before you setVertexBuffers');
		g4.setVertexBuffers(vertexBuffers);
	}

	static public function setIndexBuffer(indexBuffer:IndexBuffer) {
		Log.assert(g4 != null, 'Graphics: begin before you setIndexBuffer');
		g4.setIndexBuffer(indexBuffer);
	}

	static public function setPipeline(pipeline:Pipeline) {
		Log.assert(g4 != null, 'Graphics: begin before you usePipeline');
		pipeline.use(g4);
	}

	static public function applyUniforms(pipeline:Pipeline) {
		Log.assert(g4 != null, 'Graphics: begin before you applyUniforms');
		pipeline.apply(g4);
	}

	static public function draw(start:Int = 0, count:Int = -1) {
		Log.assert(g4 != null, 'Graphics: begin before you draw');
		g4.drawIndexedVertices(start, count);
	}

	static public function drawInstanced(instances:Int, start:Int = 0, count:Int = -1) {
		Log.assert(g4 != null, 'Graphics: begin before you draw');
		g4.drawIndexedVerticesInstanced(instances, start, count);
	}
}