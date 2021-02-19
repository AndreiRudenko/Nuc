package nuc;

import nuc.App;
import nuc.Graphics;
import nuc.events.WindowEvent;
import nuc.graphics.Texture;
import nuc.math.Vector2;
import nuc.utils.Log;

typedef ScreenRotation = kha.ScreenRotation;
typedef WindowMode = kha.WindowMode;

@:allow(nuc.App)
class Window {

	static public var all(default, null):Array<Window> = [];

	static public function create(?win:WindowOptions):Window {
		// TODO: smart id creation, looks like in kha is bug if we destroy create and get by id
		// var w = kha.Window.create();
		// var id = all.length;
		// all.push(new Window(id))
		return null;
	}

	static public function destroy(window:Window) {
		window.dispose();
		kha.Window.destroy(window._window);
	}

	static public function get(index:Int):Window {
		return all[index];
	}

	public var x(get, never):Int;
	inline function get_x() return _window.x;

	public var y(get, never):Int;
	inline function get_y() return _window.y;

	public var width(get, never):Int;
	inline function get_width() return _window.width;

	public var height(get, never):Int;
	inline function get_height() return _window.height;

	public var mid(default, null):Vector2;

	public var antialiasing(get, set):Int;
	var _antialiasing:Int = 1;
	inline function get_antialiasing() return _antialiasing;
	function set_antialiasing(v:Int):Int {
		// Log.assert(!Nuc.renderer.isRendering, 'you cant change antialiasing while rendering');
		_antialiasing = v;
		updateBufferSize();
		return v;
	}

	public var fullscreen(get, set):Bool;
	inline function get_fullscreen() return _window.mode == WindowMode.Fullscreen;
	function set_fullscreen(v:Bool):Bool {
		if(v) {
			if(!fullscreen) _window.mode = WindowMode.Fullscreen;
		} else if(fullscreen) {
			_window.mode = WindowMode.Windowed;
		}

		return v;
	}

	public var buffer(default, null):Texture;

	var _windowId:Int = 0; // TODO: multiple windows ?
	var _window:kha.Window;
	var _windowEvent:WindowEvent;

	function new(id:Int, antialiasing:Int) {
		// all[id] = this;
		_windowId = id;
		_antialiasing = antialiasing;
		_window = kha.Window.get(_windowId);
		_window.notifyOnResize(onResize);
		mid = new Vector2();
		_windowEvent = new WindowEvent();
	}

	public function resize(w:Int, h:Int) {
		_window.resize(w, h);
		updateBufferSize();
	}

	function onResize(w:Int, h:Int) {
		_windowEvent.set(_windowId, x, y, w, h);
		Nuc.app.emitter.emit(WindowEvent.RESIZE, _windowEvent);
	}

	function init() {
		updateBufferSize();
	}

	function dispose() {
		// all[_windowId] = null;
		if(buffer != null) {
			buffer.unload();
			Nuc.resources.remove(buffer);
		}
		mid = null;
	}

	function render() {
		Graphics.blit(buffer);
	}

	function updateBufferSize() {
		if(buffer != null) {
			buffer.unload();
			Nuc.resources.remove(buffer);
		}

		buffer = Texture.createRenderTarget(
			width, 
			height, 
			TextureFormat.RGBA32, 
			DepthStencilFormat.NoDepthAndStencil,
			_antialiasing
		);
		
		buffer.name = 'windowbuffer';
		buffer.ref();
		Nuc.resources.add(buffer);

		mid.set(width*0.5, height*0.5);
	}

}