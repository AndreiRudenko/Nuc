package nuc.audio;

import haxe.io.Bytes;
import nuc.utils.Float32Array;
import nuc.utils.Math;
import nuc.resources.Resource;
import nuc.Audio;

#if cpp
@:cppFileCode('
#define STB_VORBIS_HEADER_ONLY
#include <kinc/audio2/audio.h>
#include <kinc/math/core.h>
#include <math.h>
#include <nuclib/audio1.h>
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

import kha.audio2.ogg.vorbis.Reader;

@:allow(nuc.Audio)
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
	inline function get_position() {
		#if (kha_no_ogg)
		return 0.0;
		#else
		return reader.currentMillisecond / 1000.0;
		#end
	}
	function set_position(v:Float) {
		#if (kha_no_ogg)
		return 0.0;
		#else
		reader.currentMillisecond = v * 1000;
		return v;
		#end
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
	function get_length() {
		#if (kha_no_ogg)
		return 0.0;
		#else
		return reader.totalMillisecond / 1000.0;
		#end
	}

	#if (!kha_no_ogg)
	var reader:Reader;
	#end

	var data:Bytes = null;

	var l:Float = 0.7071;
	var r:Float = 0.7071;

	var paused:Bool = false;
	var stopped:Bool = false;
	var looping:Bool = false;

	public function new(data:Bytes, loop:Bool) {
		this.data = data;
		looping = loop;
		#if (!kha_no_ogg)
		reader = Reader.openFromBytes(data);
		#end
	}

	public function play() {
		paused = false;
		stopped = false;
		Audio.streamAgain(this);
	}

	public function pause() {
		paused = true;
	}

	public function stop() {
		stopped = true;
		reader.currentMillisecond = 0;
	}

	function nextSamples(requestedSamples:Float32Array, requestedLength:Int, sampleRate:Int) {
		// if (paused || stopped) {
		// 	for (i in 0...requestedLength) {
		// 		requestedSamples[i] = 0;
		// 	}
		// 	return;
		// }

		#if (!kha_no_ogg)
		var count = reader.read(requestedSamples, Std.int(requestedLength / 2), 2, sampleRate, true) * 2;
		if (count < requestedLength) {
			if (looping) {
				reader.currentMillisecond = 0;
			} else {
				stop();
			}

			for (i in count...requestedLength) {
				requestedSamples[i] = 0;
			}
		}
		#end
	}

	function calcVolume() {
		var a = (_pan + 1) * Math.PI / 4;
		l = Math.cos(a) * _volume;
		r = Math.sin(a) * _volume;
	}

}

#end