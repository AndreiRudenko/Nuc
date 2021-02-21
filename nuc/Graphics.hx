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
import nuc.math.FastVector2;
import nuc.math.Rectangle;

import nuc.utils.Math;
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
		scaleX:FastFloat = 1, scaleY:FastFloat = 1, offsetX:FastFloat = 0, offsetY:FastFloat = 0
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

	public var segmentSmooth(default, set):Float = 5;
	function set_segmentSmooth(v:Float) {
		segmentSmooth = Math.max(1, v);
		return segmentSmooth;
	}

	public var miterMinAngle(default, set):Float = 10; // degrees
	function set_miterMinAngle(v:Float) {
		miterMinAngle = Math.clamp(v, 0.01, 180);
		_miterMinAngleRadians = miterMinAngle / 180;
		return miterMinAngle;
	}

	var _miterMinAngleRadians:Float = 10/180;


	var _renderer:Renderer;
	var _projection:FastMatrix3;

	var _savedState:GraphicsState;
	var _wasSaved:Bool = false;

	var _scissorStack:Array<Rectangle>;
	var _transformStack:Array<FastMatrix3>;
	var _opacityStack:Array<Float>;

	var _scissorPool:DynamicPool<Rectangle>;
	var _transformPool:DynamicPool<FastMatrix3>;
	var _polySegmentPool:DynamicPool<PolySegment>;

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
	var _lastTexture:Texture;
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

		_polySegmentPool = new DynamicPool<PolySegment>(64, function() { return new PolySegment(); });
		_scissorPool = new DynamicPool<Rectangle>(16, function() { return new Rectangle(); });
		_transformPool = new DynamicPool<FastMatrix3>(16, function() { return new FastMatrix3(); });

		_lastTexture = null;
		// _textureIdSet = new Int16Array(Texture.maxTextures);
		_textures = new haxe.ds.Vector(Graphics.maxShaderTextures);

		// for (i in 0...Texture.maxTextures) _textureIdSet[i] = -1;
		for (i in 0...Graphics.maxShaderTextures) _textures[i] = null;

		_invertseTransform = new FastMatrix3();
		_bakedQuadCache = new AlignedQuad();

		_savedState = new GraphicsState();
		_wasSaved = false;

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

	public function save() {
		_savedState.target = _target;
		_savedState.pipeline = _pipeline;
		_savedState.transform.copyFrom(_transform);

		_savedState.color = _color;
		_savedState.opacity = _opacity;

		_savedState.textureFilter = _textureFilter;
		_savedState.textureMipFilter = _textureMipFilter;
		_savedState.textureAddressing = _textureAddressing;

		_savedState.lineWidth = _lineWidth;
		_savedState.lineJoint = _lineJoint;
		_savedState.lineCap = _lineCap;

		_savedState.segmentSmooth = _segmentSmooth;
		_savedState.miterMinAngle = _miterMinAngle;

		if(_scissor != null) {
			_savedState.useScissor = true;
			_savedState.scissor.copyFrom(_scissor);
		} else {
			_savedState.useScissor = false;
		}

		_wasSaved = true;

		flush();
	}

	public function restore() {		
		_target = _savedState.target;
		_pipeline = _savedState.pipeline;
		_transform.copyFrom(_savedState.transform);

		_color = _savedState.color;
		_opacity = _savedState.opacity;

		_textureFilter = _savedState.textureFilter;
		_textureMipFilter = _savedState.textureMipFilter;
		_textureAddressing = _savedState.textureAddressing;

		_lineWidth = _savedState.lineWidth;
		_lineJoint = _savedState.lineJoint;
		_lineCap = _savedState.lineCap;

		_segmentSmooth = _savedState.segmentSmooth;
		_miterMinAngle = _savedState.miterMinAngle;

		if(_savedState.useScissor != null) {
			_scissor.copyFrom(_savedState.scissor);
		}

		_wasSaved = false;

		flush();
	}

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

	public function translate(x:FastFloat, y:FastFloat) {
		_transform.translate(x, y);
		onTransformUpdate();
	}

	public function prependTranslate(x:FastFloat, y:FastFloat) {
		_transform.prependTranslate(x, y);
		onTransformUpdate();
	}

	public function scale(x:FastFloat, y:FastFloat) {
		_transform.scale(x, y);
		onTransformUpdate();
	}

	public function rotate(radians:FastFloat, ox:FastFloat = 0, oy:FastFloat = 0) {
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
	public function shear(x:FastFloat, y:FastFloat, ox:FastFloat = 0, oy:FastFloat = 0) {
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

	public function inverseTransformPointX(x:FastFloat, y:FastFloat):FastFloat {
		return _transform.getTransformX(x, y);
	}

	public function inverseTransformPointY(x:FastFloat, y:FastFloat):FastFloat {
		return _transform.getTransformY(x, y);
	}

	public function transformPointX(x:FastFloat, y:FastFloat):FastFloat {
		updateInvertedTransform();
		return _invertseTransform.getTransformX(x, y);
	}
	public function transformPointY(x:FastFloat, y:FastFloat):FastFloat {
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
	public function drawImage(texture:Texture, x:FastFloat = 0, y:FastFloat = 0, ?w:FastFloat, ?h:FastFloat, rx:FastFloat = 0, ry:FastFloat = 0, ?rw:FastFloat, ?rh:FastFloat) {
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

		beginGeometry(texture, 4, 6);

		addVertex(x, y, Color.WHITE, left, top);
		addVertex(x+w, y, Color.WHITE, right, top);
		addVertex(x+w, y+h, Color.WHITE, right, bottom);
		addVertex(x, y+h, Color.WHITE, left, bottom);

		addIndex(0); addIndex(1); addIndex(2);
		addIndex(0); addIndex(2); addIndex(3);

		endGeometry();
	}

	public function drawString(text:String, x:FastFloat, y:FastFloat, spacing:Int = 0) {
		if(text.length == 0) return;

		final texture = _font.getTexture(fontSize);
		final kravur = @:privateAccess _font.font._get(fontSize);

		final image = texture.image;
		final texRatioX:FastFloat = image.width / image.realWidth;
		final texRatioY:FastFloat = image.height / image.realHeight;

		var linePos:FastFloat = 0;
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

					beginGeometry(texture, 4, 6);

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
	public function drawLine(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat) {
		drawPolyLineInternal([x0, y0, x1, y1], false);
	}

	public function drawTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		drawPolyLineInternal([x0, y0, x1, y1, x2, y2], true);
	}

	public function drawRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		if(w == 0 || h == 0) return;
		drawPolyLineInternal([x, y, x+w, y, x+w, y+h, x, y+h], true);
	}

	public function drawCircle(x:FastFloat, y:FastFloat, r:FastFloat, segments:Int = -1) {
		drawEllipse(x, y, r, r, segments);
	}

	public function drawEllipse(x:FastFloat, y:FastFloat, rx:FastFloat, ry:FastFloat, segments:Int = -1) {
		if(ry == 0 || rx == 0) return;
		if(segments <= 0) {
			var scale = Math.sqrt((_transform.a * _transform.a + _transform.b * _transform.b) * Math.max(rx, ry));
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

	public function drawArc(x:FastFloat, y:FastFloat, radius:FastFloat, angleStart:FastFloat, angle:FastFloat, segments:Int = -1) {
		if(radius == 0 || angle == 0) return;
		
		var absAngle:FastFloat = Math.abs(angle);

		if(segments <= 0) {
			if(absAngle > Math.TAU) absAngle = Math.TAU;
			var angleScale = absAngle / Math.TAU;
			var scale = Math.sqrt((_transform.a * _transform.a + _transform.b * _transform.b) * radius * angleScale);
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

		drawPolyLineInternal(points, true);
	}

	public function drawPolyLine(points:Array<FastFloat>, closed:Bool = false) {
		drawPolyLineInternal(points, closed);
	}

	// https://github.com/Feirell/2d-bezier/blob/master/lib/cubic-bezier.js
	public function drawCubicBezier(points:Array<FastFloat>, closed:Bool = false, segments:Int = 20) {
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
		drawPolyLineInternal(drawPoints, closed);
	}

	public function fillTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		beginGeometry(null, 3, 3);

		addVertex(x0, y0);
		addVertex(x1, y1);
		addVertex(x2, y2);
		addIndex(0);
		addIndex(1);
		addIndex(2);

		endGeometry();
	}
	public function fillRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		if(w == 0 || h == 0) return;

		beginGeometry(null, 4, 6);

		addVertex(x, y);
		addVertex(x+w, y);
		addVertex(x+w, y+h);
		addVertex(x, y+h);
		addIndex(0);
		addIndex(1);
		addIndex(2);
		addIndex(0);
		addIndex(2);
		addIndex(3);

		endGeometry();
	}

	public function fillCircle(x:FastFloat, y:FastFloat, r:FastFloat, segments:Int = -1) {
		fillEllipse(x, y, r, r, segments);
	}

	public function fillEllipse(x:FastFloat, y:FastFloat, rx:FastFloat, ry:FastFloat, segments:Int = -1) {
		if(rx == 0 || ry == 0) return;

		if(segments <= 0) {
			var scale = Math.sqrt((_transform.a * _transform.a + _transform.b * _transform.b) * Math.max(rx, ry));
			segments = Std.int(scale * segmentSmooth);
		}

		if(segments < 3) segments = 3;
		
		var theta:FastFloat = Math.TAU / segments;
		
		var c:FastFloat = Math.cos(theta);
		var s:FastFloat = Math.sin(theta);

		var px:FastFloat = 1;
		var py:FastFloat = 0;
		var t:FastFloat = 0;

		beginGeometry(null, segments+1, segments*3);

		var i:Int = 0;
		while(i < segments) {
			addVertex(x + px * rx, y + py * ry);

			t = px;
			px = c * px - s * py;
			py = s * t + c * py;

			addIndex(i);
			addIndex((i+1) % segments);
			addIndex(segments);
			i++;
		}
		addVertex(x, y);

		endGeometry();
	}

	public function fillArc(x:FastFloat, y:FastFloat, radius:FastFloat, angleStart:FastFloat, angle:FastFloat, segments:Int = -1) {
		if(radius == 0 || angle == 0) return;
		
		var absAngle:FastFloat = Math.abs(angle);

		if(segments <= 0) {
			if(absAngle > Math.TAU) absAngle = Math.TAU;
			var angleScale = absAngle / Math.TAU;
			var scale = Math.sqrt((_transform.a * _transform.a + _transform.b * _transform.b) * radius * angleScale);
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
		
		beginGeometry(null, segments+segsAdd+1, segments*3+3);

		var i:Int = 0;
		while(i < segments) {
			addVertex(x + px * radius, y + py * radius);
			t = px;
			if(angle > 0) {
				px = px * c - py * s;
				py = t * s + py * c;
			} else {
				px = px * c + py * s;
				py = -t * s + py * c;
			}

			addIndex(i);
			addIndex((i+1) % (segments + segsAdd));
			addIndex(segments + segsAdd);

			i++;
		}

		if(absAngle < Math.TAU) addVertex(x + px * radius, y + py * radius);
		
		addVertex(x, y);

		addIndex(0);
		addIndex(segments);
		addIndex(segments + segsAdd);

		endGeometry();
	}

	public function fillPolygon(points:Array<FastFloat>, indices:Array<Int>) {
		beginGeometry(null, points.length, indices.length);
		var i:Int = 0;
		while(i < points.length) addVertex(points[i++], points[i++]);
		i = 0;
		while(i < indices.length) addIndex(indices[i++]);
		endGeometry();
	}

	// geometry
	public function beginGeometry(texture:Texture, verticesCount:Int, indicesCount:Int) {
		Log.assert(isDrawing, 'Graphics: begin must be called before beginGeometry');
		Log.assert(!_inGeometryMode, 'Graphics: endGeometry must be called before beginGeometry');
		_inGeometryMode = true;

		if(texture == null) texture = Graphics.textureDefault;

		if(verticesCount >= _verticesMax || indicesCount >= _indicesMax) {
			throw('Graphics: can`t batch geometry with vertices(${verticesCount}/$_verticesMax), indices($indicesCount/$_indicesMax)');
		} else if(_vertPos + verticesCount >= _verticesMax || _indPos + indicesCount >= _indicesMax) {
			flush();
		}

		if(_lastTexture != texture) setTexture(texture);
		
		_vertStartPos = _vertsDraw;
		_vertPos = _vertsDraw;
		_indPos = _indicesDraw;

		_vertsDraw += verticesCount;
		_indicesDraw += indicesCount;

		stats.geometry++;
		stats.vertices += verticesCount;
		stats.indices += indicesCount;
	}

	public function addVertex(x:FastFloat, y:FastFloat, c:Color = Color.WHITE, u:FastFloat = 0, v:FastFloat = 0) {
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
			if(_texturesCount >= Graphics.maxShaderTextures) {
				flush();
				stats.textureSwitchCount++;
			}

			_textureIdx = _texturesCount;
			_textures[_textureIdx] = texture;
			// _textureIdSet[texture.id] = _textureIdx;

			_lastTexture = texture;

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
		_lastTexture = null;
		_texturesCount = 0;
	}


	// based on https://github.com/CrushedPixel/Polyline2D
	function drawPolyLineInternal(points:Array<FastFloat>, closed:Bool = false) {
		var thickness = lineWidth / 2;

		var tScale = Math.sqrt((_transform.a * _transform.a + _transform.b * _transform.b) * thickness);
		var s = Std.int(tScale * segmentSmooth);
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
			drawJoint(lastSegment, firstSegment, lineJoint, pathEnd1, pathEnd2, pathStart1, pathStart2, roundMinAngle);
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
				drawJoint(segment, segments[i + 1], lineJoint, end1, end2, nextStart1, nextStart2, roundMinAngle);
			}

			beginGeometry(null, 4, 6);

			addVertex(start1.x, start1.y, color);
			addVertex(end1.x, end1.y, color);
			addVertex(end2.x, end2.y, color);
			addVertex(start2.x, start2.y, color);

			addIndex(0);
			addIndex(1);
			addIndex(2);

			addIndex(0);
			addIndex(2);
			addIndex(3);

			endGeometry();

			start1.copyFrom(nextStart1);
			start2.copyFrom(nextStart2);

			_polySegmentPool.put(segment);
			i++;
		}
	}

	inline function drawJoint(segment1:PolySegment, segment2:PolySegment, jointStyle:LineJoint, end1:FastVector2, end2:FastVector2, nextStart1:FastVector2, nextStart2:FastVector2, roundMinAngle:FastFloat) {
		var dir1 = segment1.center.direction();
		var dir2 = segment2.center.direction();

		var dot = dir1.dot(dir2);
		var clockwise = dir1.cross(dir2) < 0;

		if (jointStyle == LineJoint.MITER && dot < -1 + _miterMinAngleRadians) jointStyle = LineJoint.BEVEL;

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

		if(jointStyle == LineJoint.MITER){
			var oVec = new FastVector2(0, 0);
			if(LineSegment.intersection(outer1, outer2, true, oVec)) {
				beginGeometry(null, 4, 6);

				addVertex(outer1.b.x, outer1.b.y, color);
				addVertex(oVec.x, oVec.y, color);
				addVertex(outer2.a.x, outer2.a.y, color);
				addVertex(iVec.x, iVec.y, color);

				addIndex(0);
				addIndex(1);
				addIndex(2);

				addIndex(0);
				addIndex(2);
				addIndex(3);

				endGeometry();
			}
		} else if(jointStyle == LineJoint.BEVEL) {
			beginGeometry(null, 3, 3);

			addVertex(outer1.b.x, outer1.b.y, color);
			addVertex(outer2.a.x, outer2.a.y, color);
			addVertex(iVec.x, iVec.y, color);

			addIndex(0);
			addIndex(1);
			addIndex(2);

			endGeometry();
		} else if(jointStyle == LineJoint.ROUND) {
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
		beginGeometry(null, numTriangles * 2 + 1, numTriangles * 3);
		while(i < numTriangles) {
			if (i + 1 == numTriangles) {
				endPoint.copyFrom(end);
			} else {
				endPoint.set(origin.x + px, origin.y + py);
				t = px;
				px = c * px - s * py;
				py = s * t + c * py;
			}

			addVertex(startPoint.x, startPoint.y, color);
			addVertex(endPoint.x, endPoint.y, color);

			addIndex(i * 2);
			addIndex(i * 2 + 1);
			addIndex(lastIdx);

			startPoint.copyFrom(endPoint);
			i++;
		}
		addVertex(connectTo.x, connectTo.y, color);
		endGeometry();
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
	public var segmentSmooth(default, null):Float;
	public var miterMinAngle(default, null):Float;
	public var font(default, null):FontResource;
	public var fontSize(default, null):Int;

	public var useScissor(default, null):Bool = false;

	public function new() {
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

		font = 16;
		fontSize = 16;

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

		textureFilter = other.textureFilter;
		textureMipFilter = other.textureMipFilter;
		textureAddressing = other.textureAddressing;

		lineWidth = other.lineWidth;
		lineJoint = other.lineJoint;
		lineCap = other.lineCap;

		segmentSmooth = other.segmentSmooth;
		miterMinAngle = other.miterMinAngle;

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
