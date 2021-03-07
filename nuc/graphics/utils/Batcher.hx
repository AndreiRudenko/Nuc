package nuc.graphics.utils;

import nuc.utils.FastFloat;
import nuc.graphics.Color;

class Batcher {

	public function beginGeometry(texture:Texture, verticesCount:Int, indicesCount:Int) {}
	public function addVertex(x:FastFloat, y:FastFloat, c:Color = Color.WHITE, u:FastFloat = 0, v:FastFloat = 0) {}
	public function addQuadGeometry(x:FastFloat, y:FastFloat, w:FastFloat, h:FastFloat, c:Color = Color.WHITE, rx:FastFloat = 0, ry:FastFloat = 0, rw:FastFloat = 0, rh:FastFloat = 0) {}
	public function addIndex(i:Int) {}
	public function endGeometry() {}

}
