package nuc.graphics;

import nuc.utils.Log;

class Batch {

    static public var current(default, null):Batch;

	public var isDrawing(default, null):Bool = false;
	public var renderCalls(default, null):Int = 0;

	var camera:Camera;

    final function begin() {
		Log.assert(Camera.current != null, 'No camera set, call Camera.begin() before drawing.');

		if (current != this) {
			if (current != null) current.end();
            current = this;
            isDrawing = true;
            camera = Camera.current;
            renderCalls = 0;

            onBegin();
		}
    }
    
    @:allow(nuc.graphics.Camera)
    final function end() {
        flush();
        onEnd();
        current = null;
		isDrawing = false;
    }

	function onBegin() {}
	function onEnd() {}
    
	public function flush() {
		renderCalls++;
        camera.renderCalls++;
    }
}