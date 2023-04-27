package nuc.graphics;

import kha.simd.Float32x4;
import kha.Kravur;
import nuc.Resources;
import nuc.Graphics;
import nuc.graphics.Texture;
import nuc.graphics.Color;
import nuc.rendering.VertexBuffer;
import nuc.rendering.IndexBuffer;
import nuc.rendering.Pipeline;
import nuc.graphics.BitmapFont;
import nuc.math.Affine;
import nuc.utils.Math;
import nuc.utils.ByteArray;
import nuc.utils.FastFloat;
import nuc.utils.Log;

using StringTools;

class SpriteBatch extends Batch {

	public var pipeline(default, set):Pipeline;
	function set_pipeline(v:Pipeline) {
		if(isDrawing) flush();
		return pipeline = v;
	}

	public var color(default, set):Color;
	function set_color(v:Color):Color {
		colorBGRA = Color.toBGRA(v);
		return color = v;
	}

	var colorBGRA:Int;

	public var font(get, set):BitmapFont;
	var _font:BitmapFont = Resources.fontDefault;
	inline function get_font() return _font; 
	function set_font(v:BitmapFont):BitmapFont {
		if(v == null) v = Resources.fontDefault;
		return _font = v;
	}
	public var fontSize:Int = 16;
	public var fontSpacing:Float = 0;

	public var textureFilter(default, set):TextureFilter = TextureFilter.PointFilter;
	function set_textureFilter(v:TextureFilter):TextureFilter {
		if(isDrawing && textureFilter != v) flush();
		return textureFilter = v;
	}

	public var textureMipFilter(default, set):MipMapFilter = MipMapFilter.NoMipFilter;
	function set_textureMipFilter(v:MipMapFilter):MipMapFilter {
		if(isDrawing && textureMipFilter != v) flush();
		return textureMipFilter = v;
	}

	public var textureAddressing(default, set):TextureAddressing = TextureAddressing.Clamp;
	function set_textureAddressing(v:TextureAddressing):TextureAddressing {
		if(isDrawing && textureAddressing != v) flush();
		return textureAddressing = v;
	}

	var vertexSize:Int;

	var pipelineDefault:Pipeline;

	var vertices:ByteArray;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;

	var lastTexture:Texture;

	var drawMatrix:Affine;

	var bufferIdx:Int = 0;
	var bufferSize:Int = 0;
	
	public function new(size:Int = 8192) {
		pipelineDefault = Graphics.pipelineTextured;
		
		vertexSize = pipelineDefault.inputLayout[0].byteSize();
		bufferSize = size;
		
		color = Color.WHITE;
		drawMatrix = new Affine();

		vertexBuffer = new VertexBuffer(bufferSize * 4, pipelineDefault.inputLayout[0], Usage.DynamicUsage);
		vertices = vertexBuffer.lock();

		indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
		var indices = indexBuffer.lock();
		for (i in 0...bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		indexBuffer.unlock();
	}

	override function flush() {
		if(bufferIdx == 0) return;

		vertexBuffer.unlock(bufferIdx * 4);
		final currentPipeline = pipeline != null ? pipeline : pipelineDefault;

		currentPipeline.setMatrix3('projectionMatrix', camera.projectionViewMatrix);
		currentPipeline.setTexture('tex', lastTexture);
		currentPipeline.setTextureParameters(
			'tex', 
			textureAddressing, textureAddressing, 
			textureFilter, textureFilter, 
			textureMipFilter
		);

		Graphics.setPipeline(currentPipeline);
		Graphics.applyUniforms(currentPipeline);
		Graphics.setVertexBuffer(vertexBuffer);
		Graphics.setIndexBuffer(indexBuffer);

		Graphics.draw(0, bufferIdx * 6);

		vertices = vertexBuffer.lock();

		lastTexture = null;
		bufferIdx = 0;

		super.flush();
	}

	public function dispose() {
		indexBuffer.delete();
		vertexBuffer.delete();
		indexBuffer = null;
		vertexBuffer = null;
		pipelineDefault = null;
		drawMatrix = null;
	}

	// Image drawing
	public extern overload inline function drawImage(
		texture:Texture,
		x:FastFloat = 0, y:FastFloat = 0,
		?width:FastFloat, ?height:FastFloat,
		regionX:FastFloat = 0, regionY:FastFloat = 0, ?regionW:FastFloat, ?regionH:FastFloat
	) {
		begin();
		if(width == 0 || height == 0) return;
		drawImageInternal(texture, null, x, y, width, height, regionX, regionY, regionW, regionH);
	}

	public extern overload inline function drawImage(
		texture:Texture,
		x:FastFloat = 0, y:FastFloat = 0, 
		?width:FastFloat, ?height:FastFloat, 
		angle:FastFloat = 0, 
		originX:FastFloat = 0, originY:FastFloat = 0, 
		skewX:FastFloat = 0, skewY:FastFloat = 0, 
		regionX:FastFloat = 0, regionY:FastFloat = 0, ?regionW:FastFloat, ?regionH:FastFloat
	) {
		begin();
		if(width == 0 || height == 0) return;
		drawMatrix.applyITRSS(x, y, angle, 1, 1, skewX, skewY);
		drawImageInternal(texture, drawMatrix, -originX, -originY, width, height, regionX, regionY, regionW, regionH);
	}

	public extern overload inline function drawImage(
		texture:Texture,
		matrix:Affine,
		x:FastFloat = 0, y:FastFloat = 0, 
		?width:FastFloat, ?height:FastFloat, 
		regionX:FastFloat = 0, regionY:FastFloat = 0, ?regionW:FastFloat, ?regionH:FastFloat
	) {
		begin();
		if(width == 0 || height == 0) return;
		drawImageInternal(texture, matrix, x, y, width, height, regionX, regionY, regionW, regionH);
	}

	// Image Region drawing
	public extern overload inline function drawImage(
		tr:TextureRegion,
		x:FastFloat = 0, y:FastFloat = 0,
		?width:FastFloat, ?height:FastFloat
	) {
		begin();
		if(width == 0 || height == 0) return;
		drawImageInternal(tr.texture, null, x, y, width, height, tr.x, tr.y, tr.width, tr.height);
	}

	public extern overload inline function drawImage(
		tr:TextureRegion,
		x:FastFloat = 0, y:FastFloat = 0, 
		?width:FastFloat, ?height:FastFloat, 
		angle:FastFloat = 0, 
		originX:FastFloat = 0, originY:FastFloat = 0, 
		skewX:FastFloat = 0, skewY:FastFloat = 0
	) {
		begin();
		if(width == 0 || height == 0) return;
		drawMatrix.applyITRSS(x, y, angle, 1, 1, skewX, skewY);
		drawImageInternal(tr.texture, drawMatrix, -originX, -originY, width, height, tr.x, tr.y, tr.width, tr.height);
	}
	
	public extern overload inline function drawImage(
		tr:TextureRegion,
		matrix:Affine,
		x:FastFloat = 0, y:FastFloat = 0, 
		?width:FastFloat, ?height:FastFloat
	) {
		begin();
		if(width == 0 || height == 0) return;
		drawImageInternal(tr.texture, matrix, x, y, width, height, tr.x, tr.y, tr.width, tr.height);
	}

	// Text drawing
	public extern overload inline function drawString(text:String, x:Float, y:FastFloat) {
		begin();
		drawStringInternal(text, null, x, y);
	}

	public extern overload inline function drawString(
		text:String, 
		x:Float, y:FastFloat, 
		scaleX:FastFloat = 1, scaleY:FastFloat = 1, 
		angle:FastFloat = 0, 
		originX:FastFloat = 0, originY:FastFloat = 0, 
		skewX:FastFloat = 0, skewY:FastFloat = 0
	) {
		begin();
		if(scaleX == 0 || scaleY == 0) return;
		drawMatrix.applyITRSS(x, y, angle, scaleX, scaleY, skewX, skewY);
		drawStringInternal(text, drawMatrix, 0, 0);
	}

	public extern overload inline function drawString(text:String, matrix:Affine) {
		drawStringInternal(text, matrix, 0, 0);
	}

	function drawImageInternal(
		texture:Texture, 
		matrix:Affine, 
		offsetX:FastFloat, offsetY:FastFloat, 
		?width:FastFloat, ?height:FastFloat,
		regionX:FastFloat, regionY:FastFloat, ?regionW:FastFloat, ?regionH:FastFloat
	) {
		if(texture == null) texture = Resources.textureDefault;
		if (bufferIdx + 1 >= bufferSize || lastTexture != texture) flush();

		lastTexture = texture;

		final texRatioW:FastFloat = texture.width / texture.widthActual;
		final texRatioH:FastFloat = texture.height / texture.heightActual;

		final texWidth:FastFloat = texture.widthActual * texRatioW;
		final texHeight:FastFloat = texture.heightActual * texRatioH;

		if(width == null) width = texWidth;
		if(height == null) height = texHeight;

		if(regionW == null) regionW = texWidth;
		if(regionH == null) regionH = texHeight;
		
		addQuadGeometry(
			matrix, 
			offsetX, offsetY, 
			width, height, 
			regionX/texWidth, regionY/texHeight,
			regionW/texWidth, regionH/texHeight
		);
	}

	function drawStringInternal(text:String, matrix:Affine, offsetX:FastFloat, offsetY:FastFloat) {
		if(text.length == 0 || fontSize <= 0) return;
		
		var currentX:FastFloat = 0;
		var currentY:FastFloat = 0;
		var charCode:Int = 0;
		var char:BitmapChar;
		var charPage:Int = -1;

		final scaleDiff:Float = fontSize / font.fontSize;

		var i:Int = 0;
		while(i < text.length) {
			charCode = text.fastCodeAt(i);
			char = font.chars.get(charCode);
			if (char != null) {
				if(charCode > 0) { // skip space
					if (bufferIdx + 1 >= bufferSize) flush();

					if (charPage != char.page) {
						charPage = char.page;
						final texture = font.textures[char.page];
						if (lastTexture != texture) flush();
						lastTexture = texture;
					}

					final srcX = (char.x / lastTexture.width);
					final srcY = (char.y / lastTexture.height);
					final srcWidth = (char.width / lastTexture.width);
					final srcHeight = (char.height / lastTexture.height);

					final x = (currentX + char.xoffset) * scaleDiff;
					final y = (currentY + char.yoffset) * scaleDiff;
					
					final w = char.width * scaleDiff;
					final h = char.height * scaleDiff;

					addQuadGeometry(
						matrix, 
						offsetX+x, offsetY+y, 
						w, h, 
						srcX, srcY, 
						srcWidth, srcHeight
					);
				}
				currentX += char.xadvance + fontSpacing;
			}
			i++;
		}
	}

	inline function addQuadGeometry(
		m:Affine,
		x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat, 
		rx:FastFloat, ry:FastFloat, rw:FastFloat, rh:FastFloat
	) {

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

		if (m == null) {
			p0x = x;
			p0y = y;

			p1x = xw;
			p1y = y;

			p2x = xw;
			p2y = yh;

			p3x = x;
			p3y = yh;
		} else {
			#if (cpp && !nuc_no_simd)

			// simd
			// p0x = a * x   + c * y   + tx
			// p1x = a * x+w + c * y   + tx
			// p2x = a * x+w + c * y+h + tx
			// p3x = a * x   + c * y+h + tx

			// p0y = b * x   + d * y   + ty
			// p1y = b * x+w + d * y   + ty
			// p2y = b * x+w + d * y+h + ty
			// p3y = b * x   + d * y+h + ty

			final ma = Float32x4.loadAllFast(m.a);
			final mb = Float32x4.loadAllFast(m.b);
			final mc = Float32x4.loadAllFast(m.c);
			final md = Float32x4.loadAllFast(m.d);

			final mtx = Float32x4.loadAllFast(m.tx);
			final mty = Float32x4.loadAllFast(m.ty);

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

			p0x = m.getTransformX(x, y);
			p0y = m.getTransformY(x, y);

			p1x = m.getTransformX(xw, y);
			p1y = m.getTransformY(xw, y);

			p2x = m.getTransformX(xw, yh);
			p2y = m.getTransformY(xw, yh);

			p3x = m.getTransformX(x, yh);
			p3y = m.getTransformY(x, yh);
			
			#end
		}

		setBufferQuadVertices(p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y, rx, ry, rx+rw, ry+rh);
		
		bufferIdx++;
	}

	function setBufferQuadVertices(
		p0x:FastFloat, p0y:FastFloat, 
		p1x:FastFloat, p1y:FastFloat, 
		p2x:FastFloat, p2y:FastFloat, 
		p3x:FastFloat, p3y:FastFloat, 
		u0:FastFloat, v0:FastFloat, u1:FastFloat, v1:FastFloat
	) {
		var idx = bufferIdx * vertexSize * 4;

		vertices.setFloat32(idx, p0x); idx += 4;
		vertices.setFloat32(idx, p0y); idx += 4;
		vertices.setUint32(idx, colorBGRA); idx += 4;
		vertices.setFloat32(idx, u0); idx += 4;
		vertices.setFloat32(idx, v0); idx += 4;

		vertices.setFloat32(idx, p1x); idx += 4;
		vertices.setFloat32(idx, p1y); idx += 4;
		vertices.setUint32(idx, colorBGRA); idx += 4;
		vertices.setFloat32(idx, u1); idx += 4;
		vertices.setFloat32(idx, v0); idx += 4;

		vertices.setFloat32(idx, p2x); idx += 4;
		vertices.setFloat32(idx, p2y); idx += 4;
		vertices.setUint32(idx, colorBGRA); idx += 4;
		vertices.setFloat32(idx, u1); idx += 4;
		vertices.setFloat32(idx, v1); idx += 4;

		vertices.setFloat32(idx, p3x); idx += 4;
		vertices.setFloat32(idx, p3y); idx += 4;
		vertices.setUint32(idx, colorBGRA); idx += 4;
		vertices.setFloat32(idx, u0); idx += 4;
		vertices.setFloat32(idx, v1); idx += 4;
	}

}