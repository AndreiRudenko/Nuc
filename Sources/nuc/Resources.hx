package nuc;

import nuc.resources.Resource;
import nuc.resources.BytesResource;
import nuc.resources.JsonResource;
import nuc.resources.TextResource;
import nuc.graphics.Texture;
import nuc.graphics.BitmapFont;
import nuc.audio.Sound;

import nuc.utils.Log;

import haxe.io.Path;

@:allow(nuc.App, nuc.resources.Resource)
class Resources {

	static public var textureDefault:Texture;
	static public var fontDefault:BitmapFont;

	static public var cache(default, null):Map<String, Resource>;
	static public var stats:ResourceStats;

	static var assetsPath:String = 'assets';

	static function init() {
		cache = new Map();
		stats = new ResourceStats();
	}

	static function initDefaultResources() {
		textureDefault = Texture.create(1, 1, TextureFormat.RGBA32);
		final pixels = textureDefault.lock();
		pixels.setInt32(0, 0xffffffff);
		textureDefault.unlock();

		#if !nuc_no_default_font
		fontDefault = Resources.getBitmapFont("Muli-Regular64.fnt");
		#end
	}

	static function dispose() {
		unloadAll();
	}

	static public function loadAll(arr:Array<String>, onComplete:()->Void, ?onProgress:(p:Float)->Void, uncompressSound:Bool = true) {
		if(arr.length == 0) {
			if(onProgress != null) onProgress(1);
			onComplete();
			return;
		}

		var progress:Float = 0;
		var count:Int = arr.length;
		var left:Int = count;

		var i:Int = 0;

		var cb:(r:Resource)->Void = null;

		cb = function(r) {
			i++;
			left--;
			progress = 1 - left / count;

			if(onProgress != null) onProgress(progress);
			
			if(i < count) {
				load(arr[i], cb, uncompressSound);
			} else {
				onComplete();
			}

		}

		load(arr[i], cb, uncompressSound);
	}

	static public function unloadAll(?arr:Array<String>) {
		if (arr != null) {
			for (rname in arr) {
				unload(rname);
			}
		} else {
			for (r in cache) {
				if (r.loaded) {
					r.unload();
					r.loaded = false;
				}
			}
			cache = new Map();
		}
	}

	static public function load(name:String, ?onComplete:(r:Resource)->Void, uncompressSound:Bool = true) {
		var res = cache.get(name);
		if(res != null) {
			Log.warning('resource already exists: $name');
			if(onComplete != null) onComplete(res);
			return;
		}

		var ext = Path.extension(name);

		switch (ext) {
			case e if (kha.Assets.imageFormats.indexOf(e) != -1): loadTexture(name, onComplete);
			case e if (kha.Assets.soundFormats.indexOf(e) != -1): loadSound(name, onComplete, uncompressSound);
			case "fnt": loadBitmapFont(name, onComplete);
			case "json": loadJson(name, onComplete);
			case "txt": loadText(name, onComplete);
			default: loadBytes(name, onComplete);
		}
	}

	static public function loadBytes(name:String, ?onComplete:(r:BytesResource)->Void) {
		var res:BytesResource = cast cache.get(name);

		if(res != null) {
			Log.warning('bytes resource already exists: $name');
			// res.ref++;
			if(onComplete != null) onComplete(res);
			return;
		}

		Log.debug('bytes / loading / $name');

		kha.Assets.loadBlobFromPath(
			getResourcePath(name), 
			function(blob:kha.Blob){
				res = new BytesResource(blob);
				res.name = name;
				res.loaded = true;
				add(res);
				if(onComplete != null) onComplete(res);
			},
			onError
		);
	}

	static public function loadText(name:String, ?onComplete:(r:TextResource)->Void) {
		var res:TextResource = cast cache.get(name);

		if(res != null) {
			Log.warning('text resource already exists: $name');
			if(onComplete != null) onComplete(res);
			return;
		}

		Log.debug('text / loading / $name');

		kha.Assets.loadBlobFromPath(
			getResourcePath(name), 
			function(blob:kha.Blob){
				res = new TextResource(blob.toString());
				res.name = name;
				res.blob = blob;
				res.loaded = true;
				add(res);
				if(onComplete != null) onComplete(res);
			},
			onError
		);
	}

	static public function loadJson(name:String, ?onComplete:(r:JsonResource)->Void) {
		var res:JsonResource = cast cache.get(name);

		if(res != null) {
			Log.warning('json resource already exists: $name');
			if(onComplete != null) onComplete(res);
			return;
		}

		Log.debug('json / loading / $name');

		kha.Assets.loadBlobFromPath(
			getResourcePath(name), 
			function(blob:kha.Blob){ // TODO: this blob is not unloaded, memory leak
				res = new JsonResource(haxe.Json.parse(blob.toString()));
				res.name = name;
				res.blob = blob;
				res.loaded = true;
				add(res);
				if(onComplete != null) onComplete(res);
			},
			onError
		);
	}

	static public function loadTexture(name:String, ?onComplete:(r:Texture)->Void) {
		var res:Texture = cast cache.get(name);

		if(res != null) {
			Log.warning('texture resource already exists: $name');
			if(onComplete != null) onComplete(res);
			return;
		}

		Log.debug('texture / loading / $name');

		kha.Assets.loadImageFromPath(
			getResourcePath(name), 
			false, 
			function(img:kha.Image){
				res = new Texture(img);
				res.name = name;
				res.loaded = true;
				add(res);
				if(onComplete != null) onComplete(res);
			},
			onError
		);
	}

	static public function loadBitmapFont(name:String, ?onComplete:(r:BitmapFont)->Void) {
		var res:BitmapFont = cast cache.get(name);

		if(res != null) {
			Log.warning('BitmapFont resource already exists and loaded: $name');
			if(onComplete != null) onComplete(res);
			return;
		}

		Log.debug('BitmapFont / loading / $name');

		kha.Assets.loadBlobFromPath(
			getResourcePath(name),
			function(b:kha.Blob){
				final data = haxe.Json.parse(b.toString());
				if(onComplete != null) {
					final textures:Array<Texture> = [];
					loadTextures(
						data.pages, 
						function(r) {
							textures.push(r);
						},
						function() {
							res = new BitmapFont(data, textures);
							res.name = name;
							res.blob = b;
							res.loaded = true;
							add(res);
							onComplete(res);
						}
					);
				}
			},
			onError
		);
	}

	static public function loadSound(name:String, ?onComplete:(r:Sound)->Void, uncompress:Bool = true) {
		var res:Sound = cast cache.get(name);

		if(res != null) {
			Log.warning('sound resource already exists: $name');
			if(onComplete != null) onComplete(res);
			return;
		}

		Log.debug('sound / loading / $name');

		kha.Assets.loadSoundFromPath(
			getResourcePath(name), 
			function(snd:kha.Sound){
				if(uncompress) {
					snd.uncompress(function() {
						res = new Sound(snd);
						res.name = name;
						res.loaded = true;
						add(res);
						if(onComplete != null) onComplete(res);
					});
				} else {
					res = new Sound(snd);
					res.name = name;
					res.loaded = true;
					add(res);
					if(onComplete != null) onComplete(res);
				}
			},
			onError
		);
	}

	static public function add(resource:Resource) {
		Log.assert(!cache.exists(resource.name));

		cache.set(resource.name, resource);

		updateStats(resource, 1);
	}

	static public function remove(resource:Resource):Bool {
		Log.assert(cache.exists(resource.name));

		updateStats(resource, -1);
		
		return cache.remove(resource.name);
	}

	static public function unload(name:String):Bool {
		var res = get(name);
		if(res != null && res.loaded) {
			res.unload();
			res.loaded = false;
			cache.remove(res.name);
			return true;
		}

		return false;
	}

	static function loadTextures(list:Array<String>, onLoad:(r:Texture)->Void, onComplete:()->Void) {
		var count:Int = list.length;
		var i:Int = 0;
		var cb:(r:Texture)->Void = null;

		cb = function(r) {
			onLoad(r);
			i++;
			
			if(i < count) {
				loadTexture(list[i], cb);
			} else {
				onComplete();
			}
		}

		loadTexture(list[i], cb);
	}

	static public inline function has(name:String):Bool return cache.exists(name);

	static public function get(name:String):Resource return fetch(name);
	static public function getBytes(name:String):BytesResource return fetch(name);
	static public function getText(name:String):TextResource return fetch(name);
	static public function getJson(name:String):JsonResource return fetch(name);
	static public function getTexture(name:String):Texture return fetch(name);
	static public function getBitmapFont(name:String):BitmapFont return fetch(name);
	static public function getSound(name:String):Sound return fetch(name);

	static inline function fetch<T>(name:String):T {
		var res:T = cast cache.get(name);
		if(res == null) Log.warning('failed to get resource: $name');
		return res;
	}

	static inline function updateStats(_res:Resource, _offset:Int) {
		switch(_res.resourceType) {
			case ResourceType.UNKNOWN:          stats.unknown   += _offset;
			case ResourceType.BYTES:            stats.bytes     += _offset;
			case ResourceType.TEXT:             stats.texts     += _offset;
			case ResourceType.JSON:             stats.jsons     += _offset;
			case ResourceType.TEXTURE:          stats.textures  += _offset;
			case ResourceType.RENDERTEXTURE:    stats.rtt       += _offset;
			case ResourceType.FONT:             stats.fonts     += _offset;
			case ResourceType.SOUND:            stats.sounds    += _offset;
			default:
		}

		stats.total += _offset;
	}

	static inline function getResourcePath(path:String):String {
		return Path.join([assetsPath, path]);
	}
	
	static function onError(err:kha.AssetError) { // TODO: remove from path assetsPath
		Log.warning('failed to load resource: ${err.url}');
	}

}

class ResourceStats {

	public var total:Int = 0;
	public var fonts:Int = 0;
	public var textures:Int = 0;
	public var rtt:Int = 0;
	public var texts:Int = 0;
	public var jsons:Int = 0;
	public var bytes:Int = 0;
	public var sounds:Int = 0;
	public var unknown:Int = 0;

	public function new() {} 

	function toString() {
		return
			"Resource Statistics\n" +
			"\ttotal : " + total + "\n" +
			"\ttexture : " + textures + "\n" +
			"\trender texture : " + rtt + "\n" +
			"\tfont : " + fonts + "\n" +
			"\ttext : " + texts + "\n" +
			"\tjson : " + jsons + "\n" +
			"\tbytes : " + bytes + "\n" +
			"\tsounds : " + sounds + "\n" +
			"\tunknown : " + unknown;
	} 

	public function reset() {
		total = 0;
		fonts = 0;
		textures = 0;
		rtt = 0;
		texts = 0;
		jsons = 0;
		bytes = 0;
		sounds = 0;
		unknown = 0;
	} 

}

enum abstract ResourceType(Int) {
	var UNKNOWN;
	var TEXT;
	var JSON;
	var BYTES;
	var TEXTURE;
	var RENDERTEXTURE;
	var FONT;
	var SOUND;
}