package nuc.audio;

import haxe.io.Bytes;
import nuc.utils.Float32Array;
import nuc.utils.Math;
import nuc.resources.Resource;
import nuc.Resources;

#if cpp
@:cppFileCode('
#define STB_VORBIS_HEADER_ONLY
#include <kinc/pch.h>
#include <kinc/audio2/audio.h>
#include <kinc/math/core.h>
#include <math.h>
#include <nuc_audio/audio1.h>
#include <kinc/audio1/stb_vorbis.c>
')
@:headerCode('struct NucStreamChannel;')
@:headerClassCode("NucStreamChannel *channel;")
class StreamChannel implements nuc.audio.AudioChannel {

	public var volume(get, set):Float;
	@:functionCode('return channel->volume;')
	function get_volume() return 0;
	@:functionCode('
		float value = (float)v;

		if(value < 0.0f) {
			value = 0.0f; 
		}

		float l;
		float r;
		Audio_calcVolume(value, channel->pan, &l, &r);

		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->volume, value);
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->l, l);
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->r, r);

		return (Float)value;
	')
	function set_volume(v:Float) return 0;
	
	public var pan(get, set):Float;
	@:functionCode('return channel->pan;')
	function get_pan() return 0;
	@:functionCode('
		float value = kinc_clamp((float)v, -1.0f, 1.0f);

		float l;
		float r;
		Audio_calcVolume(channel->volume, value, &l, &r);

		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->pan, value);
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->l, l);
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->r, r);

		return (Float)value;
	')
	function set_pan(v:Float) return 0;
	
	public var position(get, set):Float;
	@:functionCode('
		if (channel->vorbis == NULL) return 0;
		return stb_vorbis_get_sample_offset(channel->vorbis) / stb_vorbis_stream_length_in_samples(channel->vorbis);
	')
	function get_position() return 0;
	@:functionCode("
		if (channel->vorbis == NULL) return value;
		unsigned int rate = stb_vorbis_get_info(channel->vorbis).sample_rate;
		stb_vorbis_seek_frame(channel->vorbis, rate * value);
		return value;
	")
	function set_position(value:Float) return 0;

	public var playbackRate(get, set):Float;
	@:functionCode('return channel->playback_rate;')
	function get_playbackRate() return 0;
	@:functionCode('float value = (float)v; KINC_ATOMIC_EXCHANGE_FLOAT(&channel->playback_rate, value); return v;')
	function set_playbackRate(v:Float) return 0;

	public var finished(get, null):Bool;
	@:functionCode('return channel->stopped;')
	function get_finished() return false;

	public var length(get, null):Float;
	@:functionCode('
		if (channel->vorbis == NULL) return 0;
		return stb_vorbis_stream_length_in_seconds(channel->vorbis);
	')
	function get_length() return 0;

	public function new() {
		cpp.vm.Gc.setFinalizer(this, cpp.Function.fromStaticFunction(finalize));
	}

	@:functionCode('NucStreamChannel_dec(channel->channel);')
	@:void static function finalize(channel:StreamChannel):Void {}

	@:functionCode('
		stb_vorbis *vorbis;
		vorbis = stb_vorbis_open_memory(data->b->Pointer(), data->length, NULL, NULL);

		channel = NucStreamChannel_create(vorbis);

		if(vorbis != NULL) {
			stb_vorbis_info info = stb_vorbis_get_info(channel->vorbis);

			channel->channels = info.channels;
			channel->sample_rate = info.sample_rate;
		} else {
			channel->channels = 2;
			channel->sample_rate = 44100;
		}

		float volume = 1.0f;
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->volume, volume);

		float pan = 0.0f;
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->pan, pan);

		float lr = 0.7071f;
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->l, lr);
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->r, lr);

		float playback_rate = 1.0f;
		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->playback_rate, playback_rate);

		KINC_ATOMIC_EXCHANGE_32(&channel->paused, false);
		KINC_ATOMIC_EXCHANGE_32(&channel->stopped, false);
		channel->looping = looping;

		KINC_ATOMIC_EXCHANGE_32(&channel->position , 0);
	')
	public function init(data:Bytes, looping:Bool):Void {}

	// @:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->paused, false); KINC_ATOMIC_EXCHANGE_32(&channel->stopped, false); NucStreamChannel_playAgain(channel);')
	@:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->paused, false); NucStreamChannel_playAgain(channel);')
	public function play():Void {}

	@:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->paused, true);')
	public function pause():Void {}

	@:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->stopped, true); KINC_ATOMIC_EXCHANGE_32(&channel->position, 0);')
	public function stop():Void {}
}

#else

class StreamChannel implements nuc.audio.AudioChannel {

	public var volume(get, set):Float;
	var _volume:Float = 1;
	inline function get_volume() return _volume;
	function set_volume(v:Float) {
		_volume = v;
		if(_volume < 0) _volume = 0;
		calcVolume();
		return _volume;
	}

	public var pan(get, set):Float;
	var _pan:Float = 0;
	inline function get_pan() return _pan;
	function set_pan(v:Float) {
		_pan = Math.clamp(v, -1, 1);
		calcVolume();
		return _pan;
	}

	public var position(get, set):Float;
	var _position:Float = 0;
	inline function get_position() return _position;
	function set_position(v:Float) {
		return _position = v;
	}

	public var playbackRate(get, set):Float;
	var _playbackRate:Float = 1;
	inline function get_playbackRate() return _playbackRate;
	function set_playbackRate(v:Float) {
		return _playbackRate = v;
	}

	public var finished(get, never):Bool;
	function get_finished() return stopped;

	public var length(get, never):Float;
	function get_length() return data.length / Audio.samplesPerSecond / 2; // 44.1 khz in stereo

	var data:Float32Array = null;

	var l:Float = 0.7071;
	var r:Float = 0.7071;

	var paused:Bool = false;
	var stopped:Bool = false;
	var looping:Bool = false;

	public function new() {

	}

	public function play() {
		paused = false;
		stopped = false;
		// Nuc.audio.streamAgain(this);
	}

	public function pause() {
		paused = true;
	}

	public function stop() {
		stopped = true;
	}

	function calcVolume() {
		var a = (_pan + 1) * Math.PI / 4;
		l = Math.cos(a) * _volume;
		r = Math.sin(a) * _volume;
	}

}

#end