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
	
	static public var x(get, never):Int;
	static inline function get_x() return _window.x;

	static public var y(get, never):Int;
	static inline function get_y() return _window.y;

	static public var width(get, never):Int;
	static inline function get_width() return _window.width;

	static public var height(get, never):Int;
	static inline function get_height() return _window.height;

	static public var mid(default, null):Vector2;

	static public var fullscreen(get, set):Bool;
	static inline function get_fullscreen() return _window.mode == WindowMode.Fullscreen;
	static function set_fullscreen(v:Bool):Bool {
		if(v) {
			if(!fullscreen) _window.mode = WindowMode.Fullscreen;
		} else if(fullscreen) {
			_window.mode = WindowMode.Windowed;
		}
		return v;
	}

	static var _windowId:Int = 0; // TODO: multiple windows ?
	static var _window:kha.Window;
	static var _windowEvent:WindowEvent;

	static function init(id:Int) {
		// all[id] = this;
		_windowId = id;
		_window = kha.Window.get(_windowId);
		_window.notifyOnResize(onResize);
		mid = new Vector2();
		_windowEvent = new WindowEvent();
		updateMidSize();
	}

	static public function resize(w:Int, h:Int) {
		_window.resize(w, h);
		updateMidSize();
	}

	static function onResize(w:Int, h:Int) {
		_windowEvent.set(_windowId, x, y, w, h);
		nuc.App.events.fire(WindowEvent.RESIZE, _windowEvent);
	}

	static function dispose() {
		// all[_windowId] = null;
		mid = null;
	}

	static function updateMidSize() {
		mid.set(width*0.5, height*0.5);
	}

}