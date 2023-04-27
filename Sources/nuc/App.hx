package nuc;

import nuc.utils.ArrayTools;
import kha.System;
import kha.Scheduler;
import kha.Framebuffer;
import kha.WindowOptions;
import kha.WindowOptions.WindowFeatures;

import nuc.input.Keyboard;
import nuc.input.Mouse;
import nuc.input.Gamepad;
import nuc.input.Touch;
import nuc.input.Pen;
import nuc.Window;
import nuc.Cursor;
import nuc.Graphics;
import nuc.Resources;

import nuc.events.AppEvent;
import nuc.events.RenderEvent;
import nuc.events.EventDispatcher;
import nuc.utils.Log;
import nuc.utils.Common.*;

class App {

	static public var events(default, null):EventDispatcher;

	static public var inFocus(default, null):Bool = true;

	static public var screenRotation(get, never):ScreenRotation;
	static inline function get_screenRotation() return System.screenRotation; 

	static public var time(get, never):Float;
	static inline function get_time() return Scheduler.time(); 

	static public var realTime(get, never):Float;
	static inline function get_realTime() return Scheduler.realTime(); 

	static public var frameTime(default, null):Float = 0;
	static public var updateTime(default, null):Float = 0;

	static public var fixedUpdate:Bool = false;

	static public var fixedUpdateTime(get, set):Float;
	static var _fixedUpdateTime:Float = 1/60;

	static inline function get_fixedUpdateTime() return _fixedUpdateTime; 
	static function set_fixedUpdateTime(v:Float):Float {
		if(v != _fixedUpdateTime) {
			Scheduler.removeTimeTask(_fixedUpdateTimeTaskId);
			_fixedUpdateTimeTaskId = Scheduler.addTimeTask(onFixedUpdate, 0, v);
		}
		return _fixedUpdateTime = v;
	}


	static var nextFrameStart:Array<()->Void>;
	static var currentFrameEnd:Array<()->Void>;
	static var _appEvent:AppEvent;
	static var _renderEvent:RenderEvent;

	static var _time:Float = 0;
	static var _lastTime:Float = 0;
	static var _frameTime:Float = 0;
	static var _lastFrameTime:Float = 0;
	static var _fixedUpdateTimeTaskId:Int = 0;

	static var _options:NucOptions;
	static var inited:Bool = false;

	static public function start(options:NucOptions, onReady:()->Void) {
		Log.debug("creating app");

		nuc.utils.Log.assert(!inited, "app is already inited");
		inited = true;

		nextFrameStart = [];
		currentFrameEnd = [];

		var khaOptions = parseOptions(options);
		
		System.start(
			khaOptions, 
			function(_) {
				ready(onReady);
			}
		);
	}

	static public function shutdown() {
		dispose();
		events.fire(AppEvent.SHUTDOWN, _appEvent);

		System.stop();
	}

	static public inline function on<T>(event:nuc.events.EventType<T>, handler:T->Void) {
		events.on(event, handler);
	}

	static public inline function off<T>(event:nuc.events.EventType<T>, handler:T->Void) {
		events.off(event, handler);
	}

	static public function onNextFrameStart(callback:()->Void) {
		nextFrameStart.push(callback);
	}

	static public function onCurrentFrameEnd(callback:()->Void) {
		currentFrameEnd.push(callback);
	}

	static function parseOptions(options:NucOptions):SystemOptions {
		Log.debug('parsing options: $options');

		_options = {};
		_options.title = def(options.title, "nuc game");
		_options.width = def(options.width, 800);
		_options.height = def(options.height, 600);
		_options.vsync = def(options.vsync, false);
		_options.antialiasing = def(options.antialiasing, 1);
		_options.window = def(options.window, {});

		var features:WindowFeatures = None;
		if (_options.window.resizable) features |= WindowFeatures.FeatureResizable;
		if (_options.window.maximizable) features |= WindowFeatures.FeatureMaximizable;
		if (_options.window.minimizable) features |= WindowFeatures.FeatureMinimizable;
		if (_options.window.borderless) features |= WindowFeatures.FeatureBorderless;
		if (_options.window.ontop) features |= WindowFeatures.FeatureOnTop;

		var options:SystemOptions = {
			title: _options.title,
			width: _options.width,
			height: _options.height,
			window: {
				x: _options.window.x,
				y: _options.window.y,
				mode: _options.window.mode,
				windowFeatures: features
			},
			framebuffer: {
				samplesPerPixel: _options.antialiasing,
				verticalSync: _options.vsync
			}
		};

		return options;
	}

	static function ready(onReady:()->Void) {
		Log.debug("ready");

		Resources.init();

		#if !nuc_no_default_font
		Resources.loadAll(
			[
			"Muli-Regular64.fnt",
			], 
			function() {
				init();
				Log.debug("onReady");
				onReady();
			}
		);
		#else
		init();
		Log.debug("onReady");
		onReady();
		#end
	}

	static function init() {
		Log.debug("init");
		
		Resources.initDefaultResources();

		_appEvent = new AppEvent();
		_renderEvent = new RenderEvent();

		events = new EventDispatcher();

		Keyboard.init();
		Mouse.init();
		Gamepad.init();
		Touch.init();
		Pen.init();

		Window.init(0);
		Cursor.init();
		
		Graphics.setup();
		
		Audio.init();

		connectEvents();

		_lastTime = time;
		_lastFrameTime = realTime;

		events.fire(AppEvent.INIT, _appEvent);
	}

	static function dispose() {
		disconnectEvents();

		Window.dispose();
		Resources.dispose();
	}

	static function connectEvents() {
		System.notifyOnFrames(render);
		_fixedUpdateTimeTaskId = Scheduler.addTimeTask(onFixedUpdate, 0, _fixedUpdateTime);
		System.notifyOnApplicationState(foreground, resume, pause, background, null);
	}

	static function disconnectEvents() {
		Scheduler.removeTimeTask(_fixedUpdateTimeTaskId);
		System.removeFramesListener(render);
	}

	static function render(f:Array<Framebuffer>) {
		Log.verbose("render");
		_time = time;
		_frameTime = realTime;

		updateTime = _time - _lastTime;
		frameTime = _frameTime - _lastFrameTime;

		runCallbacks(nextFrameStart);

		Graphics.setFramebuffer(f);

		if (!fixedUpdate) events.fire(AppEvent.UPDATE, updateTime);

		_renderEvent.set(f[0].g2, f[0].g4);

		events.fire(RenderEvent.PRERENDER, _renderEvent);
		events.fire(RenderEvent.RENDER, _renderEvent);
		events.fire(RenderEvent.POSTRENDER, _renderEvent);

		runCallbacks(currentFrameEnd);

		_lastTime = time;
		_lastFrameTime = realTime;
	}

	static function onFixedUpdate() {
		if (fixedUpdate) events.fire(AppEvent.UPDATE, fixedUpdateTime);
	}

	static function foreground() {
		events.fire(AppEvent.FOREGROUND, _appEvent);
		inFocus = true;
	}

	static function background() {
		events.fire(AppEvent.BACKGROUND, _appEvent);
		inFocus = false;
	}

	static function pause() {
		events.fire(AppEvent.PAUSE, _appEvent);
	}

	static function resume() {
		events.fire(AppEvent.RESUME, _appEvent);
	}

	static function runCallbacks(arr:Array<()->Void>) {
		if (arr.length > 0) {			
			for (c in arr) {
				c();
			}
			ArrayTools.clear(arr);
		}
	}

}

typedef NucOptions = {
	?title:String,
	?width:Int,
	?height:Int,
	?antialiasing:Int,
	?vsync:Bool,
	?window:WindowOptions
};

typedef WindowOptions = {
	?x:Int,
	?y:Int,
	?resizable:Bool,
	?minimizable:Bool,
	?maximizable:Bool,
	?borderless:Bool,
	?ontop:Bool,
	?mode:WindowMode
};