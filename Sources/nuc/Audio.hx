package nuc;

import haxe.ds.Vector;

import nuc.audio.Sound;
import nuc.audio.AudioChannel;
import nuc.audio.SoundChannel;
import nuc.audio.StreamChannel;
import nuc.utils.Float32Array;
import nuc.utils.Math;
import nuc.utils.Log;

#if cpp
@:cppFileCode('
#include <kinc/audio2/audio.h>
#include <nuclib/audio1.h>
')
class Audio {

	static public var samplesPerSecond(get, never):Int;
	static inline function get_samplesPerSecond() return kha.audio2.Audio.samplesPerSecond;

	@:allow(nuc.App)
	@:functionCode('Audio_init();')
	static function init():Void {}

	static public function play(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.uncompressedData != null, "Sound uncompressedData must be not null");

		var channel = new SoundChannel();
		channel.init(sound.uncompressedData, sound.uncompressedData.length, sound.sampleRate, loop);
		channel.volume = volume;
		channel.pan = pan;
		channel.playbackRate = playbackRate;
		playInternal(channel, loop);
		return channel;
	}

	@:functionCode('Audio_play(channel->channel, loop);')
	static function playInternal(channel:SoundChannel, loop:Bool) {}

	static public function stream(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
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
	static function streamInternal(channel:StreamChannel, loop:Bool) {}

}

#else

class Audio {

	static public var samplesPerSecond(get, never):Int;
	static inline function get_samplesPerSecond() return kha.audio2.Audio.samplesPerSecond;

	static inline var channelCount: Int = 32;

	static var soundChannels:Vector<SoundChannel>;
	static var streamChannels:Vector<StreamChannel>;

	static var internalSoundChannels:Vector<SoundChannel>;
	static var internalStreamChannels:Vector<StreamChannel>;
	static var sampleCache1:kha.arrays.Float32Array;
	static var sampleCache2:kha.arrays.Float32Array;

	@:allow(nuc.App)
	static function init() {
		soundChannels = new Vector<SoundChannel>(channelCount);
		streamChannels = new Vector<StreamChannel>(channelCount);
		internalSoundChannels = new Vector<SoundChannel>(channelCount);
		internalStreamChannels = new Vector<StreamChannel>(channelCount);
		sampleCache1 = new Float32Array(512);
		sampleCache2 = new Float32Array(512);

		kha.audio2.Audio.audioCallback = mix;
	}

	static public function play(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.uncompressedData != null, "Sound uncompressedData must be not null");

		var channel:SoundChannel = null;

		for (i in 0...channelCount) {
			if (soundChannels[i] == null || soundChannels[i].paused || soundChannels[i].stopped) {
				channel = new SoundChannel(sound.uncompressedData, sound.sampleRate, loop);
				channel.volume = volume;
				channel.pan = pan;
				channel.playbackRate = playbackRate;
				soundChannels[i] = channel;
				break;
			}
		}

		return channel;
	}

	static public function stream(sound:Sound, volume:Float = 1, pan:Float = 0, playbackRate:Float = 1, loop:Bool = false):nuc.audio.AudioChannel {
		Log.assert(sound.compressedData != null, "Sound compressedData must be not null");

		var channel:StreamChannel = null;

		for (i in 0...channelCount) {
			if (streamChannels[i] == null || streamChannels[i].paused || streamChannels[i].stopped) {
				channel = new StreamChannel(sound.compressedData, loop);
				channel.volume = volume;
				channel.pan = pan;
				channel.playbackRate = playbackRate;
				streamChannels[i] = channel;
				break;
			}
		}

		return channel;
	}

	@:allow(nuc.audio.SoundChannel)
	static function playAgain(channel:SoundChannel) {
		for (i in 0...channelCount) {
			if (soundChannels[i] == channel) {
				soundChannels[i] = null;
			}
		}
		for (i in 0...channelCount) {
			if (soundChannels[i] == null || soundChannels[i].finished || soundChannels[i] == channel) {
				soundChannels[i] = channel;
				break;
			}
		}
	}

	@:allow(nuc.audio.StreamChannel)
	static function streamAgain(channel:StreamChannel) {
		for (i in 0...channelCount) {
			if (streamChannels[i] == channel) {
				streamChannels[i] = null;
			}
		}
		for (i in 0...channelCount) {
			if (streamChannels[i] == null || streamChannels[i].finished || streamChannels[i] == channel) {
				streamChannels[i] = channel;
				break;
			}
		}
	}

	static function mix(samplesBox:kha.internal.IntBox, buffer:kha.audio2.Buffer) {
		var samples = samplesBox.value;
		if (sampleCache1.length < samples) {
			sampleCache1 = new kha.arrays.Float32Array(samples * 2);
			sampleCache2 = new kha.arrays.Float32Array(samples * 2);
		}

		var i:Int = 0;
		while(i < samples) {
			sampleCache2[i] = 0;
			i++;
		}

		i = 0;
		while(i < channelCount) {
			internalSoundChannels[i] = soundChannels[i];
			internalStreamChannels[i] = streamChannels[i];
			i++;
		}

		for (channel in internalSoundChannels) {
			if (channel == null || channel.paused || channel.stopped) continue;
			channel.nextSamples(sampleCache1, samples, buffer.samplesPerSecond);
			i = 0;
			while(i < samples) {
				sampleCache2[i] += sampleCache1[i] * channel.l;
				sampleCache2[i+1] += sampleCache1[i+1] * channel.r;
				i += 2;
			}
		}

		for (channel in internalStreamChannels) {
			if (channel == null || channel.paused || channel.stopped) continue;
			channel.nextSamples(sampleCache1, samples, buffer.samplesPerSecond);
			i = 0;
			while(i < samples) {
				sampleCache2[i] += sampleCache1[i] * channel.l;
				sampleCache2[i+1] += sampleCache1[i+1] * channel.r;
				i += 2;
			}
		}

		for (i in 0...samples) {
			buffer.data.set(buffer.writeLocation, Math.max(Math.min(sampleCache2[i], 1.0), -1.0));
			buffer.writeLocation += 1;
			if (buffer.writeLocation >= buffer.size) buffer.writeLocation = 0;
		}
	}

}

#end

