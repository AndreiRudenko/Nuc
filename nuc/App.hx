package nuc;

import kha.System;
import kha.Scheduler;
import kha.Framebuffer;
import kha.WindowOptions;
import kha.WindowOptions.WindowFeatures;

import nuc.Input;
import nuc.Window;
import nuc.Cursor;
import nuc.Graphics;
import nuc.Resources;

import nuc.events.AppEvent;
import nuc.events.RenderEvent;
import nuc.utils.Emitter;
import nuc.utils.Log;
import nuc.utils.Common.*;

class App {

	public var emitter(default, null):Emitter;

	public var window(default, null):Window;
	public var cursor(default, null):Cursor;
	public var graphics(default, null):Graphics;
	public var input(default, null):Input;
	public var resources(default, null):Resources;
	public var audio(default, null):nuc.Audio;

	public var inFocus(default, null):Bool = true;

	public var screenRotation(get, never):ScreenRotation;
	inline function get_screenRotation() return System.screenRotation; 

	public var time(get, never):Float;
	inline function get_time() return Scheduler.time(); 

	public var realTime(get, never):Float;
	inline function get_realTime() return Scheduler.realTime(); 

	public var frameDeltaTime(default, null):Float = 0;
	public var deltaTime(default, null):Float = 0;

	public var fixedUpdateTime(get, set):Float;
	var _fixedUpdateTime:Float = 1/60;
	
	inline function get_fixedUpdateTime() return _fixedUpdateTime; 
	function set_fixedUpdateTime(v:Float):Float {
		if(v != _fixedUpdateTime) {
			Scheduler.removeTimeTask(_fixedUpdateTimeTaskId);
			_fixedUpdateTimeTaskId = Scheduler.addTimeTask(fixedUpdate, 0, v);
		}
		return _fixedUpdateTime = v;
	}

	public var timescale(get, set):Float;
	var _timescale:Float = 1;
	
	inline function get_timescale() return _timescale; 
	function set_timescale(v:Float):Float {
		_timescale = v;
		emitter.emit(AppEvent.TIMESCALE, _timescale);
		return _timescale;
	}

	var _appEvent:AppEvent;
	var _renderEvent:RenderEvent;

	var _time:Float = 0;
	var _lastTime:Float = 0;
	var _frameTime:Float = 0;
	var _lastFrameTime:Float = 0;
	var _fixedUpdateTimeTaskId:Int = 0;

	var _options:NucOptions;

	public function new(options:NucOptions, onReady:()->Void) {
		Log.debug("creating app");

		var khaOptions = parseOptions(options);

		System.start(
			khaOptions, 
			function(_) {
				ready(onReady);
			}
		);
	}

	public function shutdown() {
		dispose();
		System.stop();
	}

	function parseOptions(options:NucOptions):SystemOptions {
		Log.debug('parsing options: $options');

		_options = {};
		_options.title = def(options.title, "nuc game");
		// _options.graphics = def(options.graphics, {});
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

	function ready(onReady:()->Void) {
		Log.debug("ready");

		nuc.Nuc.app = this;
		resources = new Resources();

		#if !nuc_no_default_font
		resources.loadAll(
			[
			"Muli-Regular.ttf",
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

	function init() {
		Log.debug("init");
		
		resources.init();

		_appEvent = new AppEvent();
		_renderEvent = new RenderEvent();

		emitter = new Emitter();
		
		input = new Input();
		window = new Window(0, _options.antialiasing);
		cursor = new Cursor();
		
		Graphics.setup();
		graphics = new Graphics();
		
		audio = new Audio();
		
		_lastTime = time;
		_lastFrameTime = realTime;

		input.init();
		window.init();
		// graphics.init();

		connectEvents();
	}

	function dispose() {
		disconnectEvents();

		window.dispose();
		input.dispose();
		// graphics.dispose();

		resources.dispose();
	}

	function connectEvents() {
		System.notifyOnFrames(render);
		_fixedUpdateTimeTaskId = Scheduler.addTimeTask(fixedUpdate, 0, _fixedUpdateTime);
		System.notifyOnApplicationState(foreground, resume, pause, background, null);
		input.enable();
	}

	function disconnectEvents() {
		Scheduler.removeTimeTask(_fixedUpdateTimeTaskId);
		System.removeFramesListener(render);
		input.disable();
	}


	function render(f:Array<Framebuffer>) {
		Log.verbose("render");
		_time = time;
		_frameTime = realTime;

		deltaTime = _time - _lastTime;
		frameDeltaTime = _frameTime - _lastFrameTime;

		emitter.emit(AppEvent.UPDATE, deltaTime);

		_renderEvent.set(graphics, window.buffer.image.g2, window.buffer.image.g4);

		emitter.emit(RenderEvent.PRERENDER, _renderEvent);
		emitter.emit(RenderEvent.RENDER, _renderEvent);

		Graphics.render(f);
		window.render();

		emitter.emit(RenderEvent.POSTRENDER, _renderEvent);

		_lastTime = time;
		_lastFrameTime = realTime;
	}

	function fixedUpdate() {
		emitter.emit(AppEvent.FIXEDUPDATE, _fixedUpdateTime);
	}

	function foreground() {
		emitter.emit(AppEvent.FOREGROUND, _appEvent);
		inFocus = true;
	}

	function background() {
		emitter.emit(AppEvent.BACKGROUND, _appEvent);
		inFocus = false;
	}

	function pause() {
		emitter.emit(AppEvent.PAUSE, _appEvent);
	}

	function resume() {
		emitter.emit(AppEvent.RESUME, _appEvent);
	}
}

typedef NucOptions = {
	?title:String,
	?width:Int,
	?height:Int,
	?antialiasing:Int,
	?vsync:Bool,
	// ?randomSeed:Int,
	// ?graphics:GraphicsOptions,
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