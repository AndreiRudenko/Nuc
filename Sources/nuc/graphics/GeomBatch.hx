package nuc.graphics;

import nuc.Graphics;
import nuc.graphics.Texture;
import nuc.graphics.Color;
import nuc.rendering.VertexBuffer;
import nuc.rendering.IndexBuffer;
import nuc.rendering.Pipeline;
import nuc.math.Matrix4;
import nuc.utils.ByteArray;
import nuc.utils.Uint32Array;
import nuc.utils.FastFloat;
import nuc.utils.Log;

class GeomBatch extends Batch {

	public var pipeline(default, set):Pipeline;
	function set_pipeline(v:Pipeline) {
		if(isDrawing) flush();
		return pipeline = v;
	}

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

	var pipelineDefault:Pipeline;

	var vertexBuffer:VertexBuffer;
	var vertices:ByteArray;
	var indexBuffer:IndexBuffer;
	var indices:Uint32Array;

	var verticesMax:Int;
	var indicesMax:Int;

	var vertsDraw:Int = 0;
	var indicesDraw:Int = 0;

	var vertStartPos:Int = 0;
	var bIdx:Int = 0;
	var vertPos:Int = 0;
	var indPos:Int = 0;

	var inGeometryMode:Bool = false;

	var lastTexture:Texture;

	public function new(verticesCount:Int = 8192, indicesCount:Int = 16384) {

		pipelineDefault = Graphics.pipelineTextured;

		verticesMax = verticesCount;
		indicesMax = indicesCount;
	
		vertexBuffer = new VertexBuffer(verticesMax, pipelineDefault.inputLayout[0], Usage.DynamicUsage);
		vertices = vertexBuffer.lock();

		indexBuffer = new IndexBuffer(indicesMax, Usage.DynamicUsage);
		indices = indexBuffer.lock();
	}
	
	public function dispose() {
		indexBuffer.delete();
		vertexBuffer.delete();
		indexBuffer = null;
		vertexBuffer = null;
		pipelineDefault = null;
	}

	override function flush() {
		if(bIdx == 0) return;

		vertexBuffer.unlock(vertsDraw);
		indexBuffer.unlock(indicesDraw);

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

		Graphics.draw(0, indicesDraw);

		vertices = vertexBuffer.lock();
		indices = indexBuffer.lock();

		lastTexture = null;

		vertsDraw = 0;
		indicesDraw = 0;
		bIdx = 0;

		super.flush();
	}

	public function beginGeometry(texture:Texture, verticesCount:Int, indicesCount:Int) {
		begin();
		Log.assert(!inGeometryMode, 'Graphics: endGeometry must be called before beginGeometry');

		if(texture == null) texture = Resources.textureDefault;

		if(verticesCount >= verticesMax || indicesCount >= indicesMax) {
			throw('Graphics: can`t batch geometry with vertices(${verticesCount}/$verticesMax), indices($indicesCount/$indicesMax)');
		} else if(
			vertPos + verticesCount >= verticesMax 
			|| indPos + indicesCount >= indicesMax
			|| lastTexture != texture
		) {
			flush();
		}
		
		inGeometryMode = true;
		lastTexture = texture;

		vertStartPos = vertsDraw;
		vertPos = vertsDraw;
		indPos = indicesDraw;

		vertsDraw += verticesCount;
		indicesDraw += indicesCount;
	}

	public function addVertex(x:FastFloat, y:FastFloat, c:Color = Color.WHITE, u:FastFloat = 0, v:FastFloat = 0) {
		final colorBGRA = Color.toBGRA(c);

		vertices.setFloat32(bIdx, x); bIdx += 4;
		vertices.setFloat32(bIdx, y); bIdx += 4;
		vertices.setUint32(bIdx, colorBGRA); bIdx += 4;
		vertices.setFloat32(bIdx, u); bIdx += 4;
		vertices.setFloat32(bIdx, v); bIdx += 4;

		vertPos++;
	}

	public function addIndex(i:Int) {
		indices[indPos] = vertStartPos + i;
		indPos++;
	}
	
	public function endGeometry() {
		Log.assert(inGeometryMode, 'Graphics: beginGeometry must be called before endGeometry');
		Log.assert(vertPos == vertsDraw, 'Graphics: added vertices($vertPos) not equals of requested($vertsDraw) in beginGeometry');
		Log.assert(indPos == indicesDraw, 'Graphics: added indicies($indPos) is not equals of requested($indicesDraw) in beginGeometry');
		inGeometryMode = false;
	}
}
