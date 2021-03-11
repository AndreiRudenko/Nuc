package nuc;

import nuc.App;

class Nuc {

	@:allow(nuc.App)
	static public var app(default, null):nuc.App;

	static public var display(get, never):nuc.Display;
	static public var window(get, never):nuc.Window;
	static public var cursor(get, never):nuc.Cursor;
	static public var graphics(get, never):nuc.Graphics;
	static public var renderer(get, never):nuc.Renderer;
	static public var input(get, never):nuc.Input;
	static public var resources(get, never):nuc.Resources;
	static public var audio(get, never):nuc.Audio;

	static inline function get_display() return Display.primary;
	static inline function get_window() return app.window;
	static inline function get_cursor() return app.cursor;
	static inline function get_graphics() return app.graphics;
	static inline function get_renderer() return app.renderer;
	static inline function get_input() return app.input;
	static inline function get_resources() return app.resources;
	static inline function get_audio() return app.audio;

	static public var time(get, never):Float;
	static inline function get_time() return app.time;

	static public var realTime(get, never):Float;
	static inline function get_realTime() return app.realTime;

	static public var frameDeltaTime(get, never):Float;
	static inline function get_frameDeltaTime() return app.frameDeltaTime;

	static public var deltaTime(get, never):Float;
	static inline function get_deltaTime() return app.deltaTime;

	static public var fixedUpdateTime(get, set):Float;
	static inline function get_fixedUpdateTime() return app.fixedUpdateTime;
	static inline function set_fixedUpdateTime(v:Float) return app.fixedUpdateTime = v;

	static var inited:Bool = false;

	static public function init(options:NucOptions, onReady:()->Void) {
		nuc.utils.Log.assert(!inited, "app is already inited");
		inited = true;
		new App(options, onReady);
	}

	static public inline function on<T>(event:nuc.utils.EventType<T>, handler:T->Void, priority:Int = 0) {
		app.emitter.on(event, handler, priority);
	}

	static public inline function off<T>(event:nuc.utils.EventType<T>, handler:T->Void):Bool {
		return app.emitter.off(event, handler);
	}

}