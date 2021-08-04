package nuc.graphics;

import kha.simd.Float32x4;


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

using StringTools;

class SpriteBatch extends Canvas {

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
	public var fontScale:Float = 1;

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
	var _vertices:Float32Array;
	var _vertexBuffer:VertexBuffer;
	var _indexBuffer:IndexBuffer;

	var _projection:FastMatrix3;
	var _lastTexture:Texture;
	var _textureDefault:Texture;
	var _graphics:Graphics;

	var _bakedQuadCache:CQuad;

	var _bufferIdx:Int = 0;
	var _bufferSize:Int = 0;

	public function new(size:Int = 8192) {
		super();
		_graphics = Nuc.graphics;
		_pipelineDefault = Graphics.pipelineTextured;

		_bufferSize = size;
		_opacityStack = [];
		_scissorStack = [];
		_projection = new FastMatrix3();
		_scissorPool = new DynamicPool<Rectangle>(16, function() { return new Rectangle(); });

		_bakedQuadCache = new CQuad();

		_vertexBuffer = new VertexBuffer(_bufferSize * 4, _pipelineDefault.inputLayout[0], Usage.DynamicUsage);
		_vertices = _vertexBuffer.lock();

		_indexBuffer = new IndexBuffer(_bufferSize * 3 * 2, Usage.StaticUsage);
		var indices = _indexBuffer.lock();
		for (i in 0..._bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		_indexBuffer.unlock();

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
		_bakedQuadCache = null;
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

		_vertexBuffer.unlock(_bufferIdx * 4);
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

		_graphics.draw(0, _bufferIdx * 6);

		_vertices = _vertexBuffer.lock();
		if (_scissor != null) _graphics.disableScissor();

		_lastTexture = null;
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

	public function drawImage(texture:Texture, x:FastFloat = 0, y:FastFloat = 0, ?w:FastFloat, ?h:FastFloat, rx:FastFloat = 0, ry:FastFloat = 0, ?rw:FastFloat, ?rh:FastFloat) {
		Log.assert(isDrawing, 'Graphics: begin must be called before beginGeometry');
		
		if(texture == null) texture = _textureDefault;
		if (_bufferIdx + 1 >= _bufferSize || _lastTexture != texture) flush();

		_lastTexture = texture;

		final texRatioW:FastFloat = texture.width / texture.widthActual;
		final texRatioH:FastFloat = texture.height / texture.heightActual;

		final texWidth:FastFloat = texture.widthActual * texRatioW;
		final texHeight:FastFloat = texture.heightActual * texRatioH;

		if(w == null) w = texWidth;
		if(h == null) h = texHeight;

		if(rw == null) rw = texWidth;
		if(rh == null) rh = texHeight;

		addQuadGeometry(
			x, y, 
			w, h, 
			_color, 
			rx/texWidth, ry/texHeight,
			rw/texWidth, rh/texHeight
		);
	}

	public function drawString(text:String, x:FastFloat, y:FastFloat, spacing:Int = 0) {
		if(text.length == 0) return;
		
		var scaledFontSize:Int = Math.round(fontSize*fontScale);
		var scaleDiff:Float = fontSize / scaledFontSize;

		final fontImage = font.getFontImage(scaledFontSize);
		final texture = fontImage.texture;

		if (_lastTexture != texture) flush();
		_lastTexture = texture;

		final texRatioW:FastFloat = texture.width / texture.widthActual;
		final texRatioH:FastFloat = texture.height / texture.heightActual;

		var linePos:FastFloat = 0;
		var charIndex:Int = 0;
		var charQuad:CQuad;

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
			charQuad = fontImage.getBakedQuad(_bakedQuadCache, charIndex, linePos, 0);
			if (charQuad != null) {
				if(charIndex > 0) { // skip space
					if (_bufferIdx + 1 >= _bufferSize) flush();

					x0 = charQuad.x0 * scaleDiff;
					y0 = charQuad.y0 * scaleDiff;
					x1 = charQuad.x1 * scaleDiff;
					y1 = charQuad.y1 * scaleDiff;

					left = charQuad.s0 * texRatioW;
					top = charQuad.t0 * texRatioH;
					right = charQuad.s1 * texRatioW;
					bottom = charQuad.t1 * texRatioH;

					addQuadGeometry(
						x+x0, y+y0, 
						x1-x0, y1-y0, 
						_color, 
						left, top, 
						right-left, bottom-top
					);
				}
				linePos += charQuad.xadvance + spacing; // TODO: + tracking
			}
			i++;
		}
	}

	inline function findCharIndex(charCode:Int):Int {
		var blocks = FontImage.charBlocks;
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
	
	function addQuadGeometry(
		x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat, 
		c:Color = Color.WHITE, 
		rx:FastFloat, ry:FastFloat, rw:FastFloat, rh:FastFloat
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

		var p0x:FastFloat;
		var p0y:FastFloat;
		var p1x:FastFloat;
		var p1y:FastFloat;
		var p2x:FastFloat;
		var p2y:FastFloat;
		var p3x:FastFloat;
		var p3y:FastFloat;

		final xw:FastFloat = x + w;
		final yh:FastFloat = y + h;

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

		p0x = Float32x4.getFast(simdX, 0);
		p0y = Float32x4.getFast(simdY, 0);

		p1x = Float32x4.getFast(simdX, 1);
		p1y = Float32x4.getFast(simdY, 1);

		p2x = Float32x4.getFast(simdX, 2);
		p2y = Float32x4.getFast(simdY, 2);

		p3x = Float32x4.getFast(simdX, 3);
		p3y = Float32x4.getFast(simdY, 3);

		#else

		final t = _transform;

		p0x = t.getTransformX(x, y);
		p0y = t.getTransformY(x, y);

		p1x = t.getTransformX(xw, y);
		p1y = t.getTransformY(xw, y);

		p2x = t.getTransformX(xw, yh);
		p2y = t.getTransformY(xw, yh);

		p3x = t.getTransformX(x, yh);
		p3y = t.getTransformY(x, yh);
		
		#end

		final r:FastFloat = c.r;
		final g:FastFloat = c.g;
		final b:FastFloat = c.b;
		final a:FastFloat = c.a * _opacity;

		setBufferQuadVertices(p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y, r, g, b, a, rx, ry, rx+rw, ry+rh);
		
		_bufferIdx++;
	}

	function setBufferQuadVertices(
		p0x:FastFloat, p0y:FastFloat, 
		p1x:FastFloat, p1y:FastFloat, 
		p2x:FastFloat, p2y:FastFloat, 
		p3x:FastFloat, p3y:FastFloat, 
		r:FastFloat, g:FastFloat, b:FastFloat, a:FastFloat, 
		u0:FastFloat, v0:FastFloat, u1:FastFloat, v1:FastFloat
	) {
		final idx = _bufferIdx * 4 * _vertexSize;
		_vertices[idx + 0] = p0x;
		_vertices[idx + 1] = p0y;
		_vertices[idx + 2] = r;
		_vertices[idx + 3] = g;
		_vertices[idx + 4] = b;
		_vertices[idx + 5] = a;
		_vertices[idx + 6] = u0;
		_vertices[idx + 7] = v0;

		_vertices[idx + 8] = p1x;
		_vertices[idx + 9] = p1y;
		_vertices[idx + 10] = r;
		_vertices[idx + 11] = g;
		_vertices[idx + 12] = b;
		_vertices[idx + 13] = a;
		_vertices[idx + 14] = u1;
		_vertices[idx + 15] = v0;

		_vertices[idx + 16] = p2x;
		_vertices[idx + 17] = p2y;
		_vertices[idx + 18] = r;
		_vertices[idx + 19] = g;
		_vertices[idx + 20] = b;
		_vertices[idx + 21] = a;
		_vertices[idx + 22] = u1;
		_vertices[idx + 23] = v1;

		_vertices[idx + 24] = p3x;
		_vertices[idx + 25] = p3y;
		_vertices[idx + 26] = r;
		_vertices[idx + 27] = g;
		_vertices[idx + 28] = b;
		_vertices[idx + 29] = a;
		_vertices[idx + 30] = u0;
		_vertices[idx + 31] = v1;
	}
}
