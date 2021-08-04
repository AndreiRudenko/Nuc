package nuc.graphics;

import nuc.Nuc;
import nuc.graphics.Texture;
import nuc.graphics.Font;
import nuc.graphics.Color;

import nuc.Graphics;
import nuc.graphics.VertexBuffer;
import nuc.graphics.IndexBuffer;
import nuc.graphics.Pipeline;
import nuc.graphics.VertexStructure;
import nuc.graphics.Shaders;

import nuc.math.FastMatrix3;
import nuc.math.Vector2;
import nuc.math.FastVector2;
import nuc.math.Rectangle;
import nuc.Resources;

import nuc.utils.DynamicPool;
import nuc.utils.Math;
import nuc.utils.Float32Array;
import nuc.utils.Uint32Array;
import nuc.utils.FastFloat;
import nuc.utils.Log;

class GeomBatch extends Canvas {

	public var target(default, null):Texture;
	public var isDrawing(default, null):Bool = false;
	
	public var renderCalls(default, null):Int = 0;

	public var pipeline(get, set):Pipeline;
	var _pipeline:Pipeline;
	inline function get_pipeline() return _pipeline;
	function set_pipeline(v:Pipeline) {
		if(isDrawing) flush();
		return _pipeline = v;
	}
	
	public var scissor(get, set):Rectangle;
	var _scissor:Rectangle;
	inline function get_scissor() return _scissor; 
	function set_scissor(v:Rectangle):Rectangle {
		if(isDrawing) flush();
		return _scissor.copyFrom(v);
	}

	public var color(get, set):Color;
	var _color:Color = Color.WHITE;
	inline function get_color() return _color; 
	function set_color(v:Color):Color {
		return _color = v;
	}

	public var opacity(get, set):Float;
	var _opacity:Float = 1;
	inline function get_opacity() return _opacity; 
	function set_opacity(v:Float):Float {
		return _opacity = v;
	}

	public var font(get, set):Font;
	var _font:Font = Resources.fontDefault;
	inline function get_font() return _font; 
	function set_font(v:Font):Font {
		if(v == null) v = Resources.fontDefault;
		return _font = v;
	}
	
	public var fontSize:Int = 16;

	public var textureFilter(get, set):TextureFilter;
	var _textureFilter:TextureFilter = TextureFilter.PointFilter;
	inline function get_textureFilter() return _textureFilter; 
	function set_textureFilter(v:TextureFilter):TextureFilter {
		if(isDrawing) flush();
		return _textureFilter = v;
	}

	public var textureMipFilter(get, set):MipMapFilter;
	var _textureMipFilter:MipMapFilter = MipMapFilter.NoMipFilter;
	inline function get_textureMipFilter() return _textureMipFilter; 
	function set_textureMipFilter(v:MipMapFilter):MipMapFilter {
		if(isDrawing) flush();
		return _textureMipFilter = v;
	}

	public var textureAddressing(get, set):TextureAddressing;
	var _textureAddressing:TextureAddressing = TextureAddressing.Clamp;
	inline function get_textureAddressing() return _textureAddressing; 
	function set_textureAddressing(v:TextureAddressing):TextureAddressing {
		if(isDrawing) flush();
		return _textureAddressing = v;
	}

	final _vertexSize:Int = 8;

	var _opacityStack:Array<Float>;
	var _scissorStack:Array<Rectangle>;
	var _scissorPool:DynamicPool<Rectangle>;

	var _pipelineDefault:Pipeline;
	var _vertexBuffer:VertexBuffer;
	var _vertices:Float32Array;
	var _indexBuffer:IndexBuffer;
	var _indices:Uint32Array;

	var _verticesMax:Int;
	var _indicesMax:Int;

	var _vertsDraw:Int = 0;
	var _indicesDraw:Int = 0;

	var _vertStartPos:Int = 0;
	var _bufferIdx:Int = 0;
	var _vertPos:Int = 0;
	var _indPos:Int = 0;

	var _inGeometryMode:Bool = false;

	var _projection:FastMatrix3;
	var _lastTexture:Texture;
	var _textureDefault:Texture;
	var _graphics:Graphics;

	public function new(vertices:Int = 8192, indices:Int = 16384) {
		super();
		_graphics = Nuc.graphics;
		_pipelineDefault = Graphics.pipelineTextured;

		_verticesMax = vertices;
		_indicesMax = indices;

		_opacityStack = [];
		_scissorStack = [];
		_projection = new FastMatrix3();
		_scissorPool = new DynamicPool<Rectangle>(16, function() { return new Rectangle(); });

		_vertexBuffer = new VertexBuffer(_verticesMax, _pipelineDefault.inputLayout[0], Usage.DynamicUsage);
		_vertices = _vertexBuffer.lock();

		_indexBuffer = new IndexBuffer(_indicesMax, Usage.DynamicUsage);
		_indices = _indexBuffer.lock();

		_textureDefault = Texture.create(1, 1, TextureFormat.RGBA32);
		var pixels = _textureDefault.lock();
		pixels.setInt32(0, 0xffffffff);
		_textureDefault.unlock();
	}
	
	public function dispose() {
		_indexBuffer.delete();
		_vertexBuffer.delete();
		_indexBuffer = null;
		_vertexBuffer = null;
		_pipelineDefault = null;
		_projection = null;
		_scissorPool = null;
		_scissorStack = null;
		_opacityStack = null;
		_textureDefault = null;
	}

	public function begin(?target:Texture) {
		this.target = target;
		_graphics.begin(target);
		setProjection();
		isDrawing = true;
		renderCalls = 0;
	}

	public function clear(color:Color = Color.BLACK) {
		_graphics.clear(color);
	}

	public function end() {
		flush();
		_graphics.end();
		this.target = null;
		isDrawing = false;
	}

	public function flush() {
		if(_bufferIdx == 0) return;

		_vertexBuffer.unlock(_vertsDraw);
		_indexBuffer.unlock(_indicesDraw);

		final currentPipeline = _pipeline != null ? _pipeline : _pipelineDefault;

		if(_scissor != null) _graphics.scissor(_scissor.x, _scissor.y, _scissor.w, _scissor.h);

		currentPipeline.setMatrix3('projectionMatrix', _projection);
		currentPipeline.setTexture('tex', _lastTexture);
		currentPipeline.setTextureParameters(
			'tex', 
			_textureAddressing, _textureAddressing, 
			_textureFilter, _textureFilter, 
			_textureMipFilter
		);

		_graphics.setPipeline(currentPipeline);
		_graphics.applyUniforms(currentPipeline);
		_graphics.setVertexBuffer(_vertexBuffer);
		_graphics.setIndexBuffer(_indexBuffer);

		_graphics.draw(0, _indicesDraw);

		_vertices = _vertexBuffer.lock();
		_indices = _indexBuffer.lock();

		if (_scissor != null) _graphics.disableScissor();

		_lastTexture = null;

		_vertsDraw = 0;
		_indicesDraw = 0;
		_bufferIdx = 0;

		renderCalls++;
	}

	public function pushScissor(x:Float, y:Float, w:Float, h:Float, clipFromLast:Bool = false) {
		var s = _scissorPool.get().set(x, y, w, h);
		if(_scissor != null) {
			_scissorStack.push(_scissor);
			if(clipFromLast) s.clamp(_scissor);	
		}
		// TODO: compare scissors
		if(isDrawing) flush();
		_scissor = s;
	}

	public function popScissor() {
		if(_scissor != null) {
			if(isDrawing) flush();
			_scissorPool.put(_scissor);
			_scissor = _scissorStack.pop();
		} else {
			Log.warning('pop scissor with no scissors left in stack');
		}
	}
	public function pushOpacity(v:Float) {
		_opacityStack.push(_opacity);
		_opacity = v;
	}

	public function popOpacity() {
		if(_opacityStack.length > 0) {
			_opacity = _opacityStack.pop();
		} else {
			Log.warning('pop opacity with no opacity left in stack');
		}
	}

	public function beginGeometry(texture:Texture, verticesCount:Int, indicesCount:Int) {
		Log.assert(isDrawing, 'Graphics: begin must be called before beginGeometry');
		Log.assert(!_inGeometryMode, 'Graphics: endGeometry must be called before beginGeometry');

		if(texture == null) texture = _textureDefault;

		if(verticesCount >= _verticesMax || indicesCount >= _indicesMax) {
			throw('Graphics: can`t batch geometry with vertices(${verticesCount}/$_verticesMax), indices($indicesCount/$_indicesMax)');
		} else if(
			_vertPos + verticesCount >= _verticesMax 
			|| _indPos + indicesCount >= _indicesMax
			|| _lastTexture != texture
		) {
			flush();
		}
		_inGeometryMode = true;
		_lastTexture = texture;

		_vertStartPos = _vertsDraw;
		_vertPos = _vertsDraw;
		_indPos = _indicesDraw;

		_vertsDraw += verticesCount;
		_indicesDraw += indicesCount;
	}

	public function addVertex(x:FastFloat, y:FastFloat, c:Color = Color.WHITE, u:FastFloat = 0, v:FastFloat = 0) {
		_bufferIdx = _vertPos * _vertexSize;

		_vertices[_bufferIdx + 0] = _transform.getTransformX(x, y);
		_vertices[_bufferIdx + 1] = _transform.getTransformY(x, y);

		c.multiply(_color);

		_vertices[_bufferIdx + 2] = c.r;
		_vertices[_bufferIdx + 3] = c.g;
		_vertices[_bufferIdx + 4] = c.b;
		_vertices[_bufferIdx + 5] = c.a * _opacity;

		_vertices[_bufferIdx + 6] = u;
		_vertices[_bufferIdx + 7] = v;

		_vertPos++;
	}

	public function addIndex(i:Int) {
		_indices[_indPos] = _vertStartPos + i;
		_indPos++;
	}
	
	public function endGeometry() {
		Log.assert(_inGeometryMode, 'Graphics: beginGeometry must be called before endGeometry');
		Log.assert(_vertPos == _vertsDraw, 'Graphics: added vertices($_vertPos) not equals of requested($_vertsDraw) in beginGeometry');
		Log.assert(_indPos == _indicesDraw, 'Graphics: added indicies($_indPos) is not equals of requested($_indicesDraw) in beginGeometry');
		_inGeometryMode = false;
	}

	function setProjection() {
		if (target == null) {
			_projection.orto(0, Graphics.frameBuffer.width, Graphics.frameBuffer.height, 0);
		} else {
			if(Texture.renderTargetsInvertedY) {
				_projection.orto(0, target.width, 0, target.height);
			} else {
				_projection.orto(0, target.width, target.height, 0);
			}
		}
	}

}
