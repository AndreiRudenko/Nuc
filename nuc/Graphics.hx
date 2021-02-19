package nuc;

import kha.Framebuffer;
import kha.Kravur;
// import kha.arrays.Int16Array;

import nuc.Nuc;
import nuc.Renderer;

import nuc.render.VertexBuffer;
import nuc.render.IndexBuffer;
import nuc.render.Pipeline;
import nuc.render.VertexStructure;
import nuc.render.Shaders;

import nuc.graphics.Texture;
import nuc.graphics.Font;
import nuc.graphics.Color;

import nuc.math.FastMatrix3;
import nuc.math.Vector2;
import nuc.math.Rectangle;

import nuc.utils.Float32Array;
import nuc.utils.Uint32Array;
// import nuc.utils.Int16Array;
import nuc.utils.DynamicPool;
import nuc.utils.Log;
import nuc.utils.Common.*;
import nuc.utils.FastFloat;

using StringTools;

/*
dynamic geometry batching
static geometry batching

draw lines, fills, images, text
draw custom geometry

 */

@:allow(nuc.App)
class Graphics {

	static public var fontDefault:Font;
	static public var textureDefault:Texture;

	// TODO: hardcoded for now, get from project settings
	static public inline var maxShaderTextures:Int = 8;

	static public inline var vertexSizeMultiTextured:Int = 10;
	static public inline var vertexSizeTexturedF:Int = 9;
	static public inline var vertexSizeTextured:Int = 8;
	static public inline var vertexSizeColored:Int = 6;

	static public var pipelineColored:Pipeline;
	static public var pipelineTextured:Pipeline;
	static public var pipelineTexturedF:Pipeline;
	static public var pipelineMultiTextured:Pipeline;

	static var frameBuffer:Framebuffer;
	static var vertexBuffer:VertexBuffer;
	static var indexBuffer:IndexBuffer;
	static var blitProjection:FastMatrix3;

	// static var currentTarget:Texture = null;

	static public function setup() {
		// colored
		var structure = new VertexStructure();
		structure.add("position", VertexData.Float2);
		structure.add("color", VertexData.Float4);

		pipelineColored = new Pipeline([structure], Shaders.colored_vert, Shaders.colored_frag);
		pipelineColored.setBlending(BlendFactor.BlendOne, BlendFactor.InverseSourceAlpha, BlendOperation.Add);
		pipelineColored.compile();

		// textured
		structure = new VertexStructure();
		structure.add("position", VertexData.Float2);
		structure.add("color", VertexData.Float4);
		structure.add("texCoord", VertexData.Float2);

		pipelineTextured = new Pipeline([structure], Shaders.textured_vert, Shaders.textured_frag);
		pipelineTextured.setBlending(BlendFactor.BlendOne, BlendFactor.InverseSourceAlpha, BlendOperation.Add);
		pipelineTextured.compile();

		// textured use format, for text and image drawing
		structure = new VertexStructure();
		structure.add("position", VertexData.Float2);
		structure.add("color", VertexData.Float4);
		structure.add("texCoord", VertexData.Float2);
		structure.add("texFormat", VertexData.Float1);

		pipelineTexturedF = new Pipeline([structure], Shaders.texturedf_vert, Shaders.texturedf_frag);
		pipelineTexturedF.setBlending(BlendFactor.BlendOne, BlendFactor.InverseSourceAlpha, BlendOperation.Add);
		pipelineTexturedF.compile();

		// multi texture
		structure = new VertexStructure();
		structure.add("position", VertexData.Float2);
		structure.add("color", VertexData.Float4);
		structure.add("texCoord", VertexData.Float2);
		structure.add("texId", VertexData.Float1);
		structure.add("texFormat", VertexData.Float1);

		pipelineMultiTextured = new Pipeline([structure], Shaders.multitextured_vert, Shaders.multitextured8_frag);
		pipelineMultiTextured.setBlending(BlendFactor.BlendOne, BlendFactor.InverseSourceAlpha, BlendOperation.Add);
		pipelineMultiTextured.compile();

		#if !nuc_no_default_font
		fontDefault = Nuc.resources.font("Muli-Regular.ttf");
		#end

		textureDefault = Texture.create(1, 1, TextureFormat.RGBA32);
		var pixels = textureDefault.lock();
		pixels.setInt32(0, 0xffffffff);
		textureDefault.unlock();

		blitProjection = new FastMatrix3();
		initBuffers();
	}

	static public function blit(src:Texture, ?dst:Texture, ?pipeline:Pipeline, 
		clearDst:Bool = true, bilinear:Bool = true,
		scaleX:Float = 1, scaleY:Float = 1, offsetX:Float = 0, offsetY:Float = 0
	) {
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

		// if(Nuc.renderer.target != null) Nuc.renderer.target.image.g4.end();

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

		// if(Nuc.renderer.target != null) Nuc.renderer.target.image.g4.begin();
	}

	@:allow(nuc.App)
	static function render(f:Array<Framebuffer>) {
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

	static function setBlitVertices(x:Float, y:Float, w:Float, h:Float) {		
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

	// public var target(get, never):Texture;
	// inline function get_target() return renderer.target;

	public var isDrawing:Bool = false;

	public var stats:RenderStats;

	public var pipeline(get, set):Pipeline;
	var _pipeline:Pipeline;
	inline function get_pipeline() return _pipeline; 
	function set_pipeline(v:Pipeline):Pipeline {
		if(v == null) v = _pipelineDefault;
		if(isDrawing && _pipeline != v) flush();
		return _pipeline = v;
	}

	public var transform(get, set):FastMatrix3;
	var _transform:FastMatrix3;
	inline function get_transform() return _transform; 
	function set_transform(v:FastMatrix3):FastMatrix3 {
		return _transform.copyFrom(v);
	}

	public var scissor(get, set):Rectangle;
	var _scissor:Rectangle;
	inline function get_scissor() return _scissor; 
	function set_scissor(v:Rectangle):Rectangle {
		// if(isDrawing) flush();
		return _scissor.copyFrom(v);
	}

	public var color(get, set):Color;
	var _color:Color = Color.WHITE;
	inline function get_color() return _color; 
	function set_color(v:Color):Color {
		return _color = v;
	}

	public var font(get, set):Font;
	var _font:Font = Graphics.fontDefault;
	inline function get_font() return _font; 
	function set_font(v:Font):Font {
		if(v == null) v = Graphics.fontDefault;
		return _font = v;
	}

	public var fontSize:Int = 16;

	public var opacity(get, set):Float;
	var _opacity:Float = 1;
	inline function get_opacity() return _opacity; 
	function set_opacity(v:Float):Float {
		return _opacity = v;
	}

	public var lineWidth(get, set):Float;
	var _lineWidth:Float = 4;
	inline function get_lineWidth() return _lineWidth; 
	function set_lineWidth(v:Float):Float {
		return _lineWidth = v;
	}

	public var lineJoint(get, set):LineJoint;
	var _lineJoint:LineJoint = LineJoint.BEVEL;
	inline function get_lineJoint() return _lineJoint; 
	function set_lineJoint(v:LineJoint):LineJoint {
		return _lineJoint = v;
	}

	public var lineCap(get, set):LineCap;
	var _lineCap:LineCap = LineCap.BUTT;
	inline function get_lineCap() return _lineCap; 
	function set_lineCap(v:LineCap):LineCap {
		return _lineCap = v;
	}

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

	var _renderer:Renderer;
	var _projection:FastMatrix3;
	// var _states:Array<GraphicsState>;
	// var _savedState:GraphicsState;

	var _scissorStack:Array<Rectangle>;
	var _transformStack:Array<FastMatrix3>;
	var _opacityStack:Array<Float>;

	var _statesPool:DynamicPool<GraphicsState>;
	var _scissorPool:DynamicPool<Rectangle>;
	var _transformPool:DynamicPool<FastMatrix3>;

	var _invertseTransform:FastMatrix3;
	var _invertseTransformDirty:Bool = true;

	var _pipelineDefault:Pipeline;

	var _vertexBuffer:VertexBuffer;
	var _indexBuffer:IndexBuffer;
	var _vertices:Float32Array;
	var _indices:Uint32Array;

	var _verticesMax:Int;
	var _indicesMax:Int;

	var _vertsDraw:Int = 0;
	var _indicesDraw:Int = 0;

	var _vertStartPos:Int = 0;
	var _vertexIdx:Int = 0;
	var _vertPos:Int = 0;
	var _indPos:Int = 0;

	var _inGeometryMode:Bool = false;
	var _textureIdx:Int = 0;
	var _textureFormat:TextureFormat = TextureFormat.RGBA32;

	// var _textureIdSet:Int16Array;
	var _textures:haxe.ds.Vector<Texture>;
	var _texturesCount:Int = 0;
	
	var _bakedQuadCache:AlignedQuad;

	function new(renderer:Renderer, options:GraphicsOptions) {
		_renderer = renderer;

		_verticesMax = def(options.batchVertices, 8192);
		_indicesMax = def(options.batchIndices, 16384);

		_pipeline = Graphics.pipelineMultiTextured;
		_pipelineDefault = _pipeline;

		_vertexBuffer = new VertexBuffer(_verticesMax, _pipelineDefault.inputLayout[0], Usage.DynamicUsage);
		_vertices = _vertexBuffer.lock();
		_indexBuffer = new IndexBuffer(_indicesMax, Usage.DynamicUsage);
		_indices = _indexBuffer.lock();

		_transform = new FastMatrix3();
		_projection = new FastMatrix3();

		setProjection(Nuc.window.width, Nuc.window.height);

		_scissorStack = [];
		_transformStack = [];
		_opacityStack = [];

		_statesPool = new DynamicPool<GraphicsState>(16, function() { return new GraphicsState(); });
		_scissorPool = new DynamicPool<Rectangle>(16, function() { return new Rectangle(); });
		_transformPool = new DynamicPool<FastMatrix3>(16, function() { return new FastMatrix3(); });

		// _textureIdSet = new Int16Array(Texture.maxTextures);
		_textures = new haxe.ds.Vector(Graphics.maxShaderTextures);

		// for (i in 0...Texture.maxTextures) _textureIdSet[i] = -1;
		for (i in 0...Graphics.maxShaderTextures) _textures[i] = null;

		_invertseTransform = new FastMatrix3();
		_bakedQuadCache = new AlignedQuad();

		stats = new RenderStats();
	}

	function init() {}

	function dispose() {
		_renderer = null;
		_pipeline = null;
		_pipelineDefault = null;

		_vertexBuffer.delete();
		_indexBuffer.delete();
		_vertices = null;
		_indices = null;

		_scissorStack = null;
		_transformStack = null;
		_opacityStack = null;

		_statesPool = null;
		_scissorPool = null;
		_transformPool = null;
	}

	// state
	public function begin(?target:Texture) {
		if(target == null) target = Nuc.window.buffer;
		_renderer.begin(target);
		setProjection(target.widthActual, target.heightActual);
		clearTextures();
		stats.reset();
		isDrawing = true;
	}

	public function clear(color:Color = Color.BLACK) {
		_renderer.clear(color);
	}

	public function end() {
		flush();
		_renderer.end();
		isDrawing = false;
	}

	public function flush() {
		if(_vertsDraw == 0) return;

		if(_scissor != null) _renderer.scissor(_scissor.x, _scissor.y, _scissor.w, _scissor.h);

		_pipeline.setMatrix3('projectionMatrix', _projection);

		var i:Int = 0;
		while(i < _texturesCount) {
			_pipeline.setTexture('tex[$i]', _textures[i]);
			_pipeline.setTextureParameters('tex[$i]', _textureAddressing, _textureAddressing, _textureFilter, _textureFilter, _textureMipFilter);
			i++;
		}
		
		_renderer.setPipeline(_pipeline);
		_renderer.applyUniforms(_pipeline);

		_vertexBuffer.unlock(_vertsDraw);
		_vertices = _vertexBuffer.lock();
		_renderer.setVertexBuffer(_vertexBuffer);

		_indexBuffer.unlock(_indicesDraw);
		_indices = _indexBuffer.lock();
		_renderer.setIndexBuffer(_indexBuffer);

		_renderer.draw(0, _indicesDraw);

		_vertsDraw = 0;
		_indicesDraw = 0;

		clearTextures();

		stats.drawCalls++;
	}

	// public function save() {}
	// public function restore() {}
	// public function reset() {}

	// scissor
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
	// transformation
	public function pushTransform(?m:FastMatrix3) {
		_transformStack.push(_transform);
		if(m == null) m = _transform;
		_transform = _transformPool.get();
		_transform.copyFrom(m);
		onTransformUpdate();
	}

	public function popTransform() {
		if(_transformStack.length > 0) {
			_transformPool.put(_transform);
			_transform = _transformStack.pop();
			onTransformUpdate();
		} else {
			Log.warning('pop transform with no transforms left in stack');
		}
	}

	public function applyTransform(m:FastMatrix3) {
		_transform.append(m);
		onTransformUpdate();
	}

	public function translate(x:Float, y:Float) {
		_transform.translate(x, y);
		onTransformUpdate();
	}

	public function prependTranslate(x:Float, y:Float) {
		_transform.prependTranslate(x, y);
		onTransformUpdate();
	}

	public function scale(x:Float, y:Float) {
		_transform.scale(x, y);
		onTransformUpdate();
	}

	public function rotate(radians:Float, ox:Float = 0, oy:Float = 0) {
		if(radians == 0) return;
		
		if(ox != 0 || oy != 0) {
			var m = new FastMatrix3();
			m.translate(ox, oy)
			.rotate(radians)
			.prependTranslate(-ox, -oy)
			.append(_transform);
			_transform.copyFrom(m);
		} else {
			_transform.rotate(radians);
		}
		onTransformUpdate();
	}
	public function shear(x:Float, y:Float, ox:Float = 0, oy:Float = 0) {
		if(x == 0 && y == 0) return;

		if(ox != 0 || oy != 0) {
			var m = new FastMatrix3();
			m.translate(ox, oy)
			.shear(x, y)
			.prependTranslate(-ox, -oy)
			.append(_transform);
			_transform.copyFrom(m);
		} else {
			_transform.shear(x, y);	
		}
		onTransformUpdate();
	}

	public function inverseTransformPointX(x:Float, y:Float):Float {
		return _transform.getTransformX(x, y);
	}

	public function inverseTransformPointY(x:Float, y:Float) {
		return _transform.getTransformY(x, y);
	}

	public function transformPointX(x:Float, y:Float) {
		updateInvertedTransform();
		return _invertseTransform.getTransformX(x, y);
	}
	public function transformPointY(x:Float, y:Float) {
		updateInvertedTransform();
		return _invertseTransform.getTransformY(x, y);
	}

	// opacity
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

	// batch
	// public function beginBatch() {}
	// public function endBatch() {}
	// public function flushBatch() {}

	// // cache
	// public function createCache(verticesCount:Int = 4096, indicesCount:Int = 4096*2):Int {
	// 	return 0;
	// }
	// public function beginCache(id:Int, startGeom:Int = 0) {}
	// public function endCache() {}
	// public function clearCache(id:Int) {}
	// public function disposeCache(id:Int) {}
	// public function drawCache(id:Int, startGeom:Int = 0, count:Int = -1) {}

	// draw
	// public function draw(drawable) {}
	public function drawImage(texture:Texture, x:Float = 0, y:Float = 0, ?w:Float, ?h:Float, rx:Float = 0, ry:Float = 0, ?rw:Float, ?rh:Float) {
		if(texture == null) texture = Graphics.textureDefault;

		final texWidth = texture.widthActual;
		final texHeight = texture.heightActual;

		if(w == null) w = texWidth;
		if(h == null) h = texHeight;

		if(rw == null) rw = texWidth;
		if(rh == null) rh = texHeight;

		final left = rx / texWidth;
		final top = ry / texHeight;
		final right = (rx + rw) / texWidth;
		final bottom = (ry + rh) / texHeight;

		if(!canBatch(4, 6)) flush();
		setTexture(texture);

		beginGeometryInternal(4, 6);

		addVertex(x, y, Color.WHITE, left, top);
		addVertex(x+w, y, Color.WHITE, right, top);
		addVertex(x+w, y+h, Color.WHITE, right, bottom);
		addVertex(x, y+h, Color.WHITE, left, bottom);

		addIndex(0); addIndex(1); addIndex(2);
		addIndex(0); addIndex(2); addIndex(3);

		endGeometry();
	}

	public function drawString(text:String, x:Float, y:Float, spacing:Int = 0) {
		if(text.length == 0) return;

		final texture = _font.getTexture(fontSize);
		final kravur = @:privateAccess _font.font._get(fontSize);

		final image = texture.image;
		final texRatioX:FastFloat = image.width / image.realWidth;
		final texRatioY:FastFloat = image.height / image.realHeight;

		var linePos:Float = 0;
		var charIndex:Int = 0;
		var charQuad:AlignedQuad;

		var x0:FastFloat;
		var y0:FastFloat;
		var x1:FastFloat;
		var y1:FastFloat;

		var left:FastFloat;
		var top:FastFloat;
		var right:FastFloat;
		var bottom:FastFloat;

		if(!canBatch(4, 6)) flush();
		setTexture(texture);

		var i:Int = 0;
		while(i < text.length) {
			charIndex = findCharIndex(text.fastCodeAt(i));
			charQuad = kravur.getBakedQuad(_bakedQuadCache, charIndex, linePos, 0);
			if (charQuad != null) {
				if(charIndex > 0) { // skip space

					x0 = charQuad.x0;
					y0 = charQuad.y0;
					x1 = charQuad.x1;
					y1 = charQuad.y1;

					left = charQuad.s0 * texRatioX;
					top = charQuad.t0 * texRatioY;
					right = charQuad.s1 * texRatioX;
					bottom = charQuad.t1 * texRatioY;

					if(!canBatch(4, 6)) flush();

					beginGeometryInternal(4, 6);

					addVertex(x+x0, y+y0, Color.WHITE, left, top);
					addVertex(x+x1, y+y0, Color.WHITE, right, top);
					addVertex(x+x1, y+y1, Color.WHITE, right, bottom);
					addVertex(x+x0, y+y1, Color.WHITE, left, bottom);

					addIndex(0); addIndex(1); addIndex(2);
					addIndex(0); addIndex(2); addIndex(3);

					endGeometry();
				}
				linePos += charQuad.xadvance + spacing; // TODO: + tracking
			}
			i++;
		}

	}

	inline function findCharIndex(charCode:Int):Int {
		var blocks = KravurImage.charBlocks;
		var offset = 0;
		var start = 0;
		var end = 0;
		var i = 0;
		var idx = 0;
		while(i < blocks.length) {
			start = blocks[i];
			end = blocks[i + 1];
			if (charCode >= start && charCode <= end) {
				idx = offset + charCode - start;
				break;
			}
			offset += end - start + 1;
			i += 2;
		}

		return idx;
	}

	// shapes
	public function drawLine(x0:Float, y0:Float, x1:Float, y1:Float) {}
	public function drawPolyLine(points:Array<Float>) {}
	public function drawCubicBezier(points:Array<Float>, closed:Bool = false, segments:Int = 20) {}

	public function drawTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float) {}
	public function drawRectangle(x:Float, y:Float, w:Float, h:Float) {}
	public function drawCircle(x:Float, y:Float, r:Float) {}
	public function drawEllipse(x:Float, y:Float, rx:Float, ry:Float) {}
	public function drawArc(x:Float, y:Float, radius:Float, angleStart:Float, angle:Float, segments:Int = -1) {}

	public function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float) {}
	public function fillRectangle(x:Float, y:Float, w:Float, h:Float) {}
	public function fillCircle(x:Float, y:Float, r:Float) {}
	public function fillEllipse(x:Float, y:Float, rx:Float, ry:Float) {}
	public function fillArc(x:Float, y:Float, radius:Float, angleStart:Float, angle:Float, segments:Int = -1) {}
	public function fillPolygon(points:Array<Float>, indices:Array<Int>) {}

	// geometry
	public inline function beginGeometry(texture:Texture, verticesCount:Int, indicesCount:Int) {
		if(texture == null) texture = Graphics.textureDefault;
		if(!canBatch(verticesCount, indicesCount)) flush();
		setTexture(texture);
		beginGeometryInternal(verticesCount, indicesCount);
	}

	function canBatch(verticesCount:Int, indicesCount:Int):Bool {
		if(verticesCount >= _verticesMax || indicesCount >= _indicesMax) {
			throw('Graphics: can`t batch geometry with vertices(${verticesCount}/$_verticesMax), indices($indicesCount/$_indicesMax)');
		}
		return _vertPos + verticesCount < _verticesMax && _indPos + indicesCount < _indicesMax;
	}

	function beginGeometryInternal(verticesCount:Int, indicesCount:Int) {
		Log.assert(isDrawing, 'Graphics: begin must be called before beginGeometry');
		Log.assert(!_inGeometryMode, 'Graphics: endGeometry must be called before beginGeometry');
		_inGeometryMode = true;

		// if(verticesCount >= _verticesMax || indicesCount >= _indicesMax) {
		// 	throw('Graphics: can`t batch geometry with vertices(${verticesCount}/$_verticesMax), indices($indicesCount/$_indicesMax)');
		// } else if(_vertPos + verticesCount >= _verticesMax || _indPos + indicesCount >= _indicesMax) {
		// 	flush();
		// }

		_vertStartPos = _vertsDraw;
		_vertPos = _vertsDraw;
		_indPos = _indicesDraw;

		_vertsDraw += verticesCount;
		_indicesDraw += indicesCount;

		stats.geometry++;
		stats.vertices += verticesCount;
		stats.indices += indicesCount;
	}

	public function addVertex(x:Float, y:Float, c:Color = Color.WHITE, u:Float = 0, v:Float = 0) {
		_vertexIdx = _vertPos * Graphics.vertexSizeMultiTextured;

		_vertices[_vertexIdx + 0] = _transform.getTransformX(x, y);
		_vertices[_vertexIdx + 1] = _transform.getTransformY(x, y);

		c.multiply(_color);

		_vertices[_vertexIdx + 2] = c.r;
		_vertices[_vertexIdx + 3] = c.g;
		_vertices[_vertexIdx + 4] = c.b;
		_vertices[_vertexIdx + 5] = c.a * _opacity;

		_vertices[_vertexIdx + 6] = u;
		_vertices[_vertexIdx + 7] = v;

		_vertices[_vertexIdx + 8] = _textureIdx;
		_vertices[_vertexIdx + 9] = _textureFormat;

		_vertPos++;
	}

	public function addIndex(i:Int) {
		_indices[_indPos++] = _vertStartPos + i;
	}

	public function endGeometry() {
		Log.assert(_inGeometryMode, 'Graphics: beginGeometry must be called before endGeometry');
		Log.assert(_vertPos == _vertsDraw, 'Graphics: added vertices($_vertPos) not equals of requested($_vertsDraw) in beginGeometry');
		Log.assert(_indPos == _indicesDraw, 'Graphics: added indicies($_indPos) is not equals of requested($_indicesDraw) in beginGeometry');
		_inGeometryMode = false;
	}

	// mesh
	public function drawMesh(mesh) {}
	public function drawMeshInstanced(mesh, instances:Int) {}

	function setProjection(width:Float, height:Float) {
		if (Texture.renderTargetsInvertedY) {
			_projection.orto(0, width, 0, height);
		} else {
			_projection.orto(0, width, height, 0);
		}
	}

	inline function onTransformUpdate() {
		_invertseTransformDirty = true;
	}

	inline function updateInvertedTransform() {
		if(_invertseTransformDirty) {
			_invertseTransform.copyFrom(_transform);
			_invertseTransform.invert();
			_invertseTransformDirty = false;
		}
	}

	function setTexture(texture:Texture) {
		_textureIdx = getTextureIdx(texture);
		_textureFormat = texture.format;

		if(_textureIdx < 0) {
			if(_texturesCount >= Graphics.maxShaderTextures) flush();

			_textureIdx = _texturesCount;
			_textures[_textureIdx] = texture;
			// _textureIdSet[texture.id] = _textureIdx;

			_texturesCount++;
			// stats.textures++;
		}
	}

	function getTextureIdx(texture:Texture):Int {
		var i:Int = 0;
		while(i < _texturesCount) {
			if(_textures[i] == texture) return i;
			i++;
		}
		return -1;
		// return _textureIdSet[texture.id];
	}

	function clearTextures() {
		var i:Int = 0;
		while(i < _texturesCount) {
			// _textureIdSet[_textures[i].id] = -1;
			_textures[i] = null;
			i++;
		}
		_texturesCount = 0;
	}

}

@:allow(nuc.Graphics)
class GraphicsState {

	public var id(get, never):Int;
	public var target(default, null):Texture;

	public var pipeline(default, null):Pipeline;
	public var viewport(default, null):Rectangle;
	public var projection(default, null):FastMatrix3;
	public var transform(default, null):FastMatrix3;
	public var scissor(default, null):Rectangle;
	public var color(default, null):Color;
	public var opacity(default, null):Float;
	public var lineWidth(default, null):Float;
	public var lineJoint(default, null):LineJoint;
	public var lineCap(default, null):LineCap;
	public var textureFilter(default, null):TextureFilter;
	public var textureMipFilter(default, null):MipMapFilter;
	public var textureAddressing(default, null):TextureAddressing;

	// public var font(default, null):FontResource;
	// public var fontSize(default, null):Int;

	public var useScissor(default, null):Bool = false;

	public function new() {
		viewport = new Rectangle();
		projection = new FastMatrix3();
		transform = new FastMatrix3();
		scissor = new Rectangle();
		color = new Color();
	}

	function reset() {
		target = null;
		pipeline = null;

		var dst = Nuc.window.buffer;

		if (Texture.renderTargetsInvertedY) {
			projection.orto(0, dst.widthActual, 0, dst.heightActual);
		} else {
			projection.orto(0, dst.widthActual, dst.heightActual, 0);
		}

		viewport.set(0, 0, dst.widthActual, dst.heightActual);
		scissor.set(0, 0, dst.widthActual, dst.heightActual);

		transform.identity();

		color = Color.BLACK;
		opacity = 1;

		lineWidth = 4;
		lineJoint = LineJoint.BEVEL;
		lineCap = LineCap.BUTT;

		textureFilter = TextureFilter.PointFilter;
		textureMipFilter = MipMapFilter.NoMipFilter;
		textureAddressing = TextureAddressing.Clamp;

		useScissor = false;
	}

	function copyFrom(other:GraphicsState) {
		target = other.target;

		pipeline = other.pipeline;

		viewport.copyFrom(other.viewport);
		projection.copyFrom(other.projection);
		transform.copyFrom(other.transform);
		scissor.copyFrom(other.scissor);

		color = other.color;
		opacity = other.opacity;

		lineWidth = other.lineWidth;
		lineJoint = other.lineJoint;
		lineCap = other.lineCap;

		textureFilter = other.textureFilter;
		textureMipFilter = other.textureMipFilter;
		textureAddressing = other.textureAddressing;

		useScissor = other.useScissor;
	}

	function get_id() {
		return target != null ? target.id : -1;
	}
	
}

class RenderStats {

	public var drawCalls:Int = 0;
	public var vertices:Int = 0;
	public var indices:Int = 0;

	public var geometry:Int = 0;
	public var textureSwitchCount:Int = 0;

	public function new() {}

	public function reset() {
		drawCalls = 0;
		vertices = 0;
		indices = 0;
		geometry = 0;
		textureSwitchCount = 0;
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

typedef GraphicsOptions = {
	?batchVertices:Int,
	?batchIndices:Int
};

// class TestAPI {

// 	public function new() {
// 		var g = nuc.Nuc.graphics;

// 		g.beginCache(0);
// 		g.drawRectangle(123, 74, 160, 80);
// 		g.endCache();

// 		g.begin();

// 		g.beginBatch();

// 		g.color = -1;
// 		g.drawImage('img', 128, 256, 64, 64);

// 		g.beginGeometry('img1', 4, 6);
		
// 		g.addVertex(0, 0);
// 		g.addVertex(0, 64);
// 		g.addVertex(64, 64);
// 		g.addVertex(64, 0);

// 		g.addIndex(0);
// 		g.addIndex(1);
// 		g.addIndex(2);
// 		g.addIndex(0);
// 		g.addIndex(2);
// 		g.addIndex(3);

// 		g.endGeometry();

// 		g.endBatch();

// 		g.drawCache(0);

// 		g.end();

// 	}

// }