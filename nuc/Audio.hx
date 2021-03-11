package nuc;

import nuc.audio.Sound;
import nuc.audio.SoundChannel;
import nuc.utils.Float32Array;
import nuc.utils.Math;


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
		var channel = new SoundChannel();
		channel.allocate(sound.uncompressedData, sound.sampleRate, loop);
		channel.volume = volume;
		channel.pan = pan;
		channel.playbackRate = playbackRate;
		playInternal(channel, loop);
		return channel;
	}

	@:functionCode('Audio_play(channel->channel, loop);')
	function playInternal(channel:SoundChannel, loop:Bool) {}

}

#else

class Audio {

	public function new() {}

	public function play(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		return null;
	}

	function playAgain(channel:SoundChannel) {
		
	}

}

#end

