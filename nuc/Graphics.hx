package nuc;

import kha.Framebuffer;
import kha.Kravur;
import kha.simd.Float32x4;

import nuc.Nuc;
import nuc.Renderer;

import nuc.render.VertexBuffer;
import nuc.render.IndexBuffer;
import nuc.render.Pipeline;
import nuc.render.VertexStructure;
import nuc.render.Shaders;

import nuc.graphics.Drawable;
import nuc.graphics.Texture;
import nuc.graphics.Font;
import nuc.graphics.Video;
import nuc.graphics.Color;
import nuc.graphics.utils.PolylineRenderer;
import nuc.graphics.utils.ShapeRenderer;
import nuc.graphics.utils.GraphicsState;
import nuc.graphics.utils.DrawStats;
import nuc.graphics.utils.Batcher;

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
class Graphics extends Batcher {

	static public var fontDefault:Font;
	static public var textureDefault:Texture;

	// TODO: hardcoded for now, get from project settings
	static public var maxShaderTextures:Int = 8;

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
		Log.assert(Nuc.renderer.target == null, 'Graphics: has active render target, end before you blit');

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

	public var target(default, null):Texture;

	public var isDrawing:Bool = false;

	public var stats:DrawStats;

	public var pipeline(get, set):Pipeline;
	var _pipeline:Pipeline;
	inline function get_pipeline() return _pipeline; 
	function set_pipeline(v:Pipeline):Pipeline {
		if(v == null) v = _pipelineDefault;
		if(isDrawing && _pipeline != v) flush();
		return _pipeline = v;
	}

	public var view(get, set):FastMatrix3;
	var _view:FastMatrix3;
	inline function get_view() return _view; 
	function set_view(v:FastMatrix3):FastMatrix3 {
		if(isDrawing) flush();
		return _view.copyFrom(v);
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
		if(isDrawing) flush();
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
	inline function get_lineWidth() return _polylineRenderer.lineWidth; 
	inline function set_lineWidth(v:Float) return _polylineRenderer.lineWidth = v;
	
	public var lineJoint(get, set):LineJoint;
	inline function get_lineJoint() return _polylineRenderer.lineJoint; 
	inline function set_lineJoint(v:LineJoint) return _polylineRenderer.lineJoint = v;
	
	public var lineCap(get, set):LineCap;
	inline function get_lineCap() return _polylineRenderer.lineCap;
	inline function set_lineCap(v:LineCap)return _polylineRenderer.lineCap = v;

	public var segmentSmooth(get, set):Float;
	inline function get_segmentSmooth() return _polylineRenderer.segmentSmooth;
	inline function set_segmentSmooth(v:Float) return _polylineRenderer.segmentSmooth = Math.max(1, v);
	
	public var miterMinAngle(default, set):Float = 10; // degrees
	function set_miterMinAngle(v:Float) {
		miterMinAngle = Math.clamp(v, 0.01, 180);
		_polylineRenderer.miterMinAngle = miterMinAngle / 180;
		return miterMinAngle;
	}

	var _miterMinAngleRadians:Float = 10/180;

	var _renderer:Renderer;
	var _projection:FastMatrix3;
	var _combined:FastMatrix3;

	var _savedState:GraphicsState;
	var _wasSaved:Bool = false;

	var _scissorStack:Array<Rectangle>;
	var _transformStack:Array<FastMatrix3>;
	var _opacityStack:Array<Float>;

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

	var _lastTexture:Texture;
	var _textures:haxe.ds.Vector<Texture>;
	var _texturesCount:Int = 0;
	
	var _bakedQuadCache:AlignedQuad;
	var _polylineRenderer:PolylineRenderer;
	var _shapeRenderer:ShapeRenderer;

	function new(renderer:Renderer, options:GraphicsOptions) {
		_renderer = renderer;
		_polylineRenderer = new PolylineRenderer(this);
		_shapeRenderer = new ShapeRenderer(this);

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
		_view = new FastMatrix3();
		_combined = new FastMatrix3();

		setProjection(Nuc.window.width, Nuc.window.height);

		_scissorStack = [];
		_transformStack = [];
		_opacityStack = [];

		_scissorPool = new DynamicPool<Rectangle>(16, function() { return new Rectangle(); });
		_transformPool = new DynamicPool<FastMatrix3>(16, function() { return new FastMatrix3(); });

		_lastTexture = null;
		_textures = new haxe.ds.Vector(Graphics.maxShaderTextures);

		for (i in 0...Graphics.maxShaderTextures) _textures[i] = null;

		_invertseTransform = new FastMatrix3();
		_bakedQuadCache = new AlignedQuad();

		_savedState = new GraphicsState();
		_wasSaved = false;

		stats = new DrawStats();
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
		this.target = target;
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
		this.target = null;
		isDrawing = false;
	}

	public function flush() {
		if(_vertsDraw == 0) return;

		if(_scissor != null) _renderer.scissor(_scissor.x, _scissor.y, _scissor.w, _scissor.h);

		_combined.copyFrom(_projection).append(_view);
		_pipeline.setMatrix3('projectionMatrix', _combined);

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
		_savedState.target = target;
		_savedState.pipeline = _pipeline;
		_savedState.transform.copyFrom(_transform);
		_savedState.view.copyFrom(_view);

		_savedState.color = _color;
		_savedState.opacity = _opacity;

		_savedState.textureFilter = _textureFilter;
		_savedState.textureMipFilter = _textureMipFilter;
		_savedState.textureAddressing = _textureAddressing;

		_savedState.lineWidth = lineWidth;
		_savedState.lineJoint = lineJoint;
		_savedState.lineCap = lineCap;

		_savedState.segmentSmooth = segmentSmooth;
		_savedState.miterMinAngle = miterMinAngle;

		_savedState.font = _font;
		_savedState.fontSize = fontSize;

		if(_scissor != null) {
			_savedState.useScissor = true;
			_savedState.scissor.copyFrom(_scissor);
		} else {
			_savedState.useScissor = false;
		}

		_wasSaved = true;

		if(isDrawing) flush();
	}

	public function restore() {		
		_pipeline = _savedState.pipeline;
		_transform.copyFrom(_savedState.transform);
		_view.copyFrom(_savedState.view);

		_color = _savedState.color;
		_opacity = _savedState.opacity;

		_textureFilter = _savedState.textureFilter;
		_textureMipFilter = _savedState.textureMipFilter;
		_textureAddressing = _savedState.textureAddressing;

		lineWidth = _savedState.lineWidth;
		lineJoint = _savedState.lineJoint;
		lineCap = _savedState.lineCap;

		segmentSmooth = _savedState.segmentSmooth;
		miterMinAngle = _savedState.miterMinAngle;

		_font = _savedState.font;
		fontSize = _savedState.fontSize;

		if(_savedState.useScissor) _scissor.copyFrom(_savedState.scissor);
		
		_wasSaved = false;

		if(isDrawing) {
			flush();

			if(_savedState.target != null) {
				end();
				begin(_savedState.target);
			}
		}
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

	// draw
	public function draw(drawable:Drawable) {
		drawable.draw(this);
	}

	public function drawImage(texture:Texture, x:FastFloat = 0, y:FastFloat = 0, ?w:FastFloat, ?h:FastFloat, rx:FastFloat = 0, ry:FastFloat = 0, ?rw:FastFloat, ?rh:FastFloat) {
		if(texture == null) texture = Graphics.textureDefault;

		final texWidth = texture.widthActual;
		final texHeight = texture.heightActual;

		if(w == null) w = texWidth;
		if(h == null) h = texHeight;

		if(rw == null) rw = texWidth;
		if(rh == null) rh = texHeight;

		beginGeometry(texture, 4, 6);

		addQuadGeometry(
			x, y, 
			w, h, 
			Color.WHITE, 
			rx/texWidth, ry/texHeight,
			rh/texWidth, rw/texHeight
		);

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

					addQuadGeometry(
						x+x0, y+y0, 
						x1-x0, y1-y0, 
						Color.WHITE, 
						left, top,
						right-left, bottom-top
					);

					endGeometry();
				}
				linePos += charQuad.xadvance + spacing; // TODO: + tracking
			}
			i++;
		}
	}

	public function drawVideo(video:Video, x:FastFloat = 0, y:FastFloat = 0, ?w:FastFloat, ?h:FastFloat) {

	}

	// shapes
	public inline function drawLine(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat) {
		_polylineRenderer.drawLine(x0, y0, x1, y1);
	}

	public inline function drawTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		_polylineRenderer.drawTriangle(x0, y0, x1, y1, x2, y2);
	}

	public inline function drawRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		_polylineRenderer.drawRectangle(x, y, w, h);
	}

	public inline function drawCircle(x:FastFloat, y:FastFloat, r:FastFloat, segments:Int = -1) {
		_polylineRenderer.transformScale = getScale();
		_polylineRenderer.drawEllipse(x, y, r, r, segments);
	}

	public inline function drawEllipse(x:FastFloat, y:FastFloat, rx:FastFloat, ry:FastFloat, segments:Int = -1) {
		_polylineRenderer.transformScale = getScale();
		_polylineRenderer.drawEllipse(x, y, rx, ry, segments);
	}

	public inline function drawArc(x:FastFloat, y:FastFloat, radius:FastFloat, angleStart:FastFloat, angle:FastFloat, segments:Int = -1) {
		_polylineRenderer.transformScale = getScale();
		_polylineRenderer.drawArc(x, y, radius, angleStart, angle, segments);
	}

	public inline function drawPolyLine(points:Array<FastFloat>, closed:Bool = false) {
		_polylineRenderer.transformScale = getScale();
		_polylineRenderer.drawPolyLine(points, closed);
	}

	public inline function drawCubicBezier(points:Array<FastFloat>, closed:Bool = false, segments:Int = 20) {
		_polylineRenderer.drawCubicBezier(points, closed, segments);
	}

	public inline function fillTriangle(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat, x2:FastFloat, y2:FastFloat) {
		_shapeRenderer.fillTriangle(x0, y0, x1, y1, x2, y2);
	}
	public inline function fillRectangle(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat) {
		_shapeRenderer.fillRectangle(x, y, w, h);
	}

	public inline function fillCircle(x:FastFloat, y:FastFloat, r:FastFloat, segments:Int = -1) {
		_shapeRenderer.transformScale = getScale();
		_shapeRenderer.fillEllipse(x, y, r, r, segments);
	}

	public inline function fillEllipse(x:FastFloat, y:FastFloat, rx:FastFloat, ry:FastFloat, segments:Int = -1) {
		_shapeRenderer.transformScale = getScale();
		_shapeRenderer.fillEllipse(x, y, rx, ry, segments);
	}

	public inline function fillArc(x:FastFloat, y:FastFloat, radius:FastFloat, angleStart:FastFloat, angle:FastFloat, segments:Int = -1) {
		_shapeRenderer.transformScale = getScale();
		_shapeRenderer.fillArc(x, y, radius, angleStart, angle, segments);
	}

	public inline function fillPolygon(points:Array<FastFloat>, indices:Array<Int>, ?colors:Array<Color>) {
		_shapeRenderer.fillPolygon(points, indices, colors);
	}

	// geometry
	override function beginGeometry(texture:Texture, verticesCount:Int, indicesCount:Int) {
		Log.assert(isDrawing, 'Graphics: begin must be called before beginGeometry');
		Log.assert(!_inGeometryMode, 'Graphics: endGeometry must be called before beginGeometry');

		if(verticesCount >= _verticesMax || indicesCount >= _indicesMax) {
			throw('Graphics: can`t batch geometry with vertices(${verticesCount}/$_verticesMax), indices($indicesCount/$_indicesMax)');
		} else if(_vertPos + verticesCount >= _verticesMax || _indPos + indicesCount >= _indicesMax) {
			flush();
		}

		_inGeometryMode = true;

		if(texture == null) texture = Graphics.textureDefault;

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

	override function addQuadGeometry(
		x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat, 
		c:Color = Color.WHITE, 
		rx:FastFloat = 0, ry:FastFloat = 0, rw:FastFloat = 0, rh:FastFloat = 0
	) {
		// simd
		// p0x = a * x   + c * y   + tx
		// p1x = a * x+w + c * y   + tx
		// p2x = a * x+w + c * y+h + tx
		// p3x = a * x   + c * y+h + tx

		// p0y = b * x   + d * y   + ty
		// p1y = b * x+w + d * y   + ty
		// p2y = b * x+w + d * y+h + ty
		// p3y = b * x   + d * y+h + ty

		final n = _vertPos * Graphics.vertexSizeMultiTextured;

		final xw:FastFloat = x + w;
		final yh:FastFloat = y + h;
		var r:FastFloat = 1;
		var g:FastFloat = 1;
		var b:FastFloat = 1;
		var a:FastFloat = 1;

		#if cpp
		final ma = Float32x4.loadAllFast(_transform.a);
		final mb = Float32x4.loadAllFast(_transform.b);
		final mc = Float32x4.loadAllFast(_transform.c);
		final md = Float32x4.loadAllFast(_transform.d);

		final mtx = Float32x4.loadAllFast(_transform.tx);
		final mty = Float32x4.loadAllFast(_transform.ty);

		final xx = Float32x4.loadFast(x, xw, xw, x);
		final yy = Float32x4.loadFast(y, y, yh, yh);

		final simdX = Float32x4.add(Float32x4.add(Float32x4.mul(ma, xx), Float32x4.mul(mc, yy)), mtx);
		final simdY = Float32x4.add(Float32x4.add(Float32x4.mul(mb, xx), Float32x4.mul(md, yy)), mty);

		final p0x = Float32x4.getFast(simdX, 0);
		final p0y = Float32x4.getFast(simdY, 0);

		final p1x = Float32x4.getFast(simdX, 1);
		final p1y = Float32x4.getFast(simdY, 1);

		final p2x = Float32x4.getFast(simdX, 2);
		final p2y = Float32x4.getFast(simdY, 2);

		final p3x = Float32x4.getFast(simdX, 3);
		final p3y = Float32x4.getFast(simdY, 3);

		_vertices[n + 0] = p0x; 
		_vertices[n + 1] = p0y; 

		_vertices[n + 10] = p1x; 
		_vertices[n + 11] = p1y; 

		_vertices[n + 20] = p2x; 
		_vertices[n + 21] = p2y; 

		_vertices[n + 30] = p3x; 
		_vertices[n + 31] = p3y; 

		final ca = Float32x4.loadFast(c.rB, c.gB, c.bB, c.aB);
		final cb = Float32x4.loadFast(_color.rB, _color.gB, _color.bB, _color.aB);
		final cf = Float32x4.loadAllFast(0xFF);
		final cd = Float32x4.loadAllFast(65280);

		final cc = Float32x4.div(Float32x4.add((Float32x4.mul(ca, cb)), cf), cd);

		r = Float32x4.getFast(cc, 0);
		g = Float32x4.getFast(cc, 1);
		b = Float32x4.getFast(cc, 2);
		a = Float32x4.getFast(cc, 3) * _opacity;

		#else
		final t = _transform;
		final p0x = t.getTransformX(x, y);
		final p0y = t.getTransformY(x, y);

		final p1x = t.getTransformX(xw, y);
		final p1y = t.getTransformY(xw, y);

		final p2x = t.getTransformX(xw, yh);
		final p2y = t.getTransformY(xw, yh);

		final p3x = t.getTransformX(x, yh);
		final p3y = t.getTransformY(x, yh);

		_vertices[n + 0] = p0x; 
		_vertices[n + 1] = p0y; 

		_vertices[n + 10] = p1x; 
		_vertices[n + 11] = p1y; 

		_vertices[n + 20] = p2x; 
		_vertices[n + 21] = p2y; 

		_vertices[n + 30] = p3x; 
		_vertices[n + 31] = p3y; 

		c.multiply(_color);

		r = c.r;
		g = c.g;
		b = c.b;
		a = c.a * _opacity;

		#end

		_vertices[n + 2] = r;
		_vertices[n + 3] = g;
		_vertices[n + 4] = b;
		_vertices[n + 5] = a;

		_vertices[n + 12] = r;
		_vertices[n + 13] = g;
		_vertices[n + 14] = b;
		_vertices[n + 15] = a;

		_vertices[n + 22] = r;
		_vertices[n + 23] = g;
		_vertices[n + 24] = b;
		_vertices[n + 25] = a;

		_vertices[n + 32] = r;
		_vertices[n + 33] = g;
		_vertices[n + 34] = b;
		_vertices[n + 35] = a;

		final rxw:FastFloat = rx + rw;
		final ryh:FastFloat = ry + rh;

		_vertices[n + 6] = rx;
		_vertices[n + 7] = ry;

		_vertices[n + 16] = rxw;
		_vertices[n + 17] = ry;

		_vertices[n + 26] = rxw;
		_vertices[n + 27] = ryh;

		_vertices[n + 36] = rx;
		_vertices[n + 37] = ryh;


		_vertices[n + 8] = _textureIdx;
		_vertices[n + 9] = _textureFormat;

		_vertices[n + 18] = _textureIdx;
		_vertices[n + 19] = _textureFormat;

		_vertices[n + 28] = _textureIdx;
		_vertices[n + 29] = _textureFormat;

		_vertices[n + 38] = _textureIdx;
		_vertices[n + 39] = _textureFormat;

		_vertPos+=4;

		final i = _indPos;
		_indices[i+0] = _vertStartPos + 0;
		_indices[i+1] = _vertStartPos + 1;
		_indices[i+2] = _vertStartPos + 2;
		_indices[i+3] = _vertStartPos + 0;
		_indices[i+4] = _vertStartPos + 2;
		_indices[i+5] = _vertStartPos + 3;

		_indPos += 6;
	}

	override function addVertex(x:FastFloat, y:FastFloat, c:Color = Color.WHITE, u:FastFloat = 0, v:FastFloat = 0) {
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

	override function addIndex(i:Int) {
		_indices[_indPos++] = _vertStartPos + i;
	}

	override function endGeometry() {
		Log.assert(_inGeometryMode, 'Graphics: beginGeometry must be called before endGeometry');
		Log.assert(_vertPos == _vertsDraw, 'Graphics: added vertices($_vertPos) not equals of requested($_vertsDraw) in beginGeometry');
		Log.assert(_indPos == _indicesDraw, 'Graphics: added indicies($_indPos) is not equals of requested($_indicesDraw) in beginGeometry');
		_inGeometryMode = false;
	}

	function getScale() {
		return _transform.a * _transform.a + _transform.b * _transform.b;
	}

	function setProjection(width:Float, height:Float) {
		if (Texture.renderTargetsInvertedY) {
			_projection.orto(0, width, 0, height);
		} else {
			_projection.orto(0, width, height, 0);
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

			_lastTexture = texture;

			_texturesCount++;
		}
	}

	function getTextureIdx(texture:Texture):Int {
		var i:Int = 0;
		while(i < _texturesCount) {
			if(_textures[i] == texture) return i;
			i++;
		}
		return -1;
	}

	function clearTextures() {
		var i:Int = 0;
		while(i < _texturesCount) {
			_textures[i] = null;
			i++;
		}
		_lastTexture = null;
		_texturesCount = 0;
	}
	
}

typedef LineJoint = nuc.graphics.utils.PolylineRenderer.LineJoint;
typedef LineCap = nuc.graphics.utils.PolylineRenderer.LineCap;

typedef GraphicsOptions = {
	?batchVertices:Int,
	?batchIndices:Int
};
