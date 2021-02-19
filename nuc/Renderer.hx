package nuc;

import nuc.graphics.Texture;
import nuc.graphics.Color;
import nuc.utils.Log;

import nuc.render.VertexBuffer;
import nuc.render.IndexBuffer;
import nuc.render.Pipeline;
import nuc.render.VertexStructure;
import nuc.render.Shaders;

class Renderer {

	public var target(default, null):Texture;
	var _g4:kha.graphics4.Graphics;

	public function new() {}

	public function begin(?target:Texture) {
		if(target == null) target = Nuc.window.buffer;
		
		Log.assert(target.isRenderTarget, 'Graphics: begin with non renderTarget texture');
		this.target = target;
		_g4 = target.image.g4;
		_g4.begin();
	}

	public function clear(?clearColor:Color) {
		Log.assert(target != null, 'Graphics: no active target, begin before you clear');
		_g4.clear(clearColor != null ? clearColor : Color.BLACK);
	}

	public function end() {
		Log.assert(target != null, 'Graphics: no active target, begin before you end');
		_g4.end();
		target = null;
		_g4 = null;
	}

	public function viewport(x:Float, y:Float, w:Float, h:Float) {
		Log.assert(target != null, 'Graphics: no active target, begin before you set viewport');
		_g4.viewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
	}

	public function scissor(x:Float, y:Float, w:Float, h:Float) {
		Log.assert(target != null, 'Graphics: no active target, begin before you set scissor');
		_g4.scissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
	}

	public function disableScissor() {
		_g4.disableScissor();
	}

	public function setVertexBuffer(vertexBuffer:VertexBuffer) {
		Log.assert(target != null, 'Graphics: no active target, begin before you setVertexBuffer');
		_g4.setVertexBuffer(vertexBuffer);
	}

	public function setVertexBuffers(vertexBuffers:Array<VertexBuffer>) {
		Log.assert(target != null, 'Graphics: no active target, begin before you setVertexBuffers');
		_g4.setVertexBuffers(vertexBuffers);
	}

	public function setIndexBuffer(indexBuffer:IndexBuffer) {
		Log.assert(target != null, 'Graphics: no active target, begin before you setIndexBuffer');
		_g4.setIndexBuffer(indexBuffer);
	}

	public function setPipeline(pipeline:Pipeline) {
		Log.assert(target != null, 'Graphics: no active target, begin before you usePipeline');
		pipeline.use(_g4);
	}

	public function applyUniforms(pipeline:Pipeline) {
		Log.assert(target != null, 'Graphics: no active target, begin before you applyUniforms');
		pipeline.apply(_g4);
	}

	public function draw(start:Int = 0, count:Int = -1) {
		Log.assert(target != null, 'Graphics: no active target, begin before you draw');
		_g4.drawIndexedVertices(start, count);
	}

	public function drawInstanced(instances:Int, start:Int = 0, count:Int = -1) {
		Log.assert(target != null, 'Graphics: no active target, begin before you draw');
		_g4.drawIndexedVerticesInstanced(instances, start, count);
	}
}