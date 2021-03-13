package nuc;

import nuc.audio.Sound;
import nuc.audio.SoundChannel;
import nuc.audio.StreamChannel;
import nuc.utils.Float32Array;
import nuc.utils.Log;
// import nuc.utils.Math;

#if cpp
@:cppFileCode('
#include <kinc/pch.h>
#include <kinc/audio2/audio.h>
#include <nuc_audio/audio1.h>
')
class Audio {

	static public var samplesPerSecond(get, never):Int;
	static inline function get_samplesPerSecond() return kha.audio2.Audio.samplesPerSecond;

	@:functionCode('Audio_init();')
	static function _init():Void {}

	public function new() {
		_init();
	}

	public function play(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.uncompressedData != null, "Sound uncompressedData must be not null");

		var channel = new SoundChannel();
		channel.init(sound.uncompressedData, sound.sampleRate, loop);
		channel.volume = volume;
		channel.pan = pan;
		channel.playbackRate = playbackRate;
		playInternal(channel, loop);
		return channel;
	}

	@:functionCode('Audio_play(channel->channel, loop);')
	function playInternal(channel:SoundChannel, loop:Bool) {}

	public function stream(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.compressedData != null, "Sound compressedData must be not null");

		var channel = new StreamChannel();
		channel.init(sound.compressedData, loop);	
		channel.volume = volume;
		channel.pan = pan;
		// channel.playbackRate = playbackRate;
		streamInternal(channel, loop);
		return channel;
	}

	@:functionCode('Audio_stream(channel->channel, loop);')
	function streamInternal(channel:StreamChannel, loop:Bool) {}

}

#else

class Audio {

	static public var samplesPerSecond(get, never):Int;
	static inline function get_samplesPerSecond() return kha.audio2.Audio.samplesPerSecond;
	
	public function new() {}

	public function play(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.uncompressedData != null, "Sound uncompressedData must be not null");

		return null;
	}

	public function stream(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.compressedData != null, "Sound compressedData must be not null");

		return null;
	}

	function playAgain(channel:SoundChannel) {
		
	}

}

#end

