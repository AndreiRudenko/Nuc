package nuc.graphics;

import nuc.math.Rectangle;
import nuc.utils.DynamicPool;
import nuc.utils.Log;

class ScissorStack {

	static public var scissor(get, never):Rectangle;
	static var _scissors:Array<Rectangle> = [];
	static inline function get_scissor() return _scissors[_scissors.length-1]; 

	static var scissorPool:DynamicPool<Rectangle> = new DynamicPool<Rectangle>(16, function() {return new Rectangle();});

	static public function pushScissor(x:Float, y:Float, w:Float, h:Float, clipFromLast:Bool = false) {
		var s = scissorPool.get().set(x, y, w, h);
		if(clipFromLast) {
			var lastScissor = scissor;
			if(lastScissor != null) s.clamp(lastScissor);
		}
		_scissors.push(s);
		Graphics.scissor(x, y, w, h);
	}

	static public function popScissor() {
		if(_scissors.length > 0) {
			scissorPool.put(_scissors.pop());
			if (_scissors.length == 0) {
				Graphics.disableScissor();
			} else {
				var s = scissor;
				Graphics.scissor(s.x, s.y, s.w, s.h);
			}
		} else {
			Log.warning('ScissorStack.popScissor with no scissors left in stack');
		}
	}
    
}