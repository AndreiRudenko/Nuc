package nuc.audio;

import haxe.io.Bytes;
import nuc.utils.Float32Array;
import nuc.utils.Math;
import nuc.resources.Resource;
import nuc.Resources;

#if cpp

@:cppFileCode('
#include <kinc/pch.h>
#include <kinc/audio2/audio.h>
#include <kinc/math/core.h>
#include <nuc_audio/audio1.h>
#include <math.h>

static int maxi(int a, int b) { return a > b ? a : b; }
static int mini(int a, int b) { return a < b ? a : b; }
static double maxd(double a, double b) { return a > b ? a : b; }
static double mind(double a, double b) { return a < b ? a : b; }
static double roundd(double value) { return floor(value + 0.5); }
static int sampleLength(NucAudioChannel *channel, int sampleRate) {
	int value = (int)ceilf((float)channel->data_length * ((float)sampleRate / (float)channel->sample_rate));
	return value % 2 == 0 ? value : value + 1;
}
')
@:headerCode('struct NucAudioChannel;')
@:headerClassCode("NucAudioChannel *channel;")
class SoundChannel implements nuc.audio.AudioChannel {

	public var volume(get, set):Float;
	@:functionCode('return channel->volume;')
	function get_volume() return 0;
	@:functionCode('
		float value = (float)v;

		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->volume, value);
		NucAudioChannel_calcVolume(channel);

		return v;
	')
	function set_volume(v:Float) return 0;
	
	public var pan(get, set):Float;
	function get_pan() return 0;
	@:functionCode('
		float value = kinc_clamp((float)v, -1.0f, 1.0f);

		KINC_ATOMIC_EXCHANGE_FLOAT(&channel->pan, value);
		NucAudioChannel_calcVolume(channel);

		return (Float)value;
	')
	function set_pan(v:Float) return 0;
	
	public var position(get, set):Float;
	@:functionCode('return (double)channel->position / (double)kinc_a2_samples_per_second / 2.0;')
	function get_position() return 0;
	@:functionCode('
		int pos = (int)roundd(value * (double)kinc_a2_samples_per_second * 2.0);
		pos = pos % 2 == 0 ? pos : pos + 1;
		KINC_ATOMIC_EXCHANGE_32(&channel->position, maxi(mini(pos, sampleLength(channel, kinc_a2_samples_per_second)), 0));
		return value;
	')
	function set_position(value:Float) return 0;

	public var playbackRate(get, set):Float;
	@:functionCode('return channel->playback_rate;')
	function get_playbackRate() return 0;
	@:functionCode('float value = (float)v; KINC_ATOMIC_EXCHANGE_FLOAT(&channel->playback_rate, value); return v;')
	function set_playbackRate(v:Float) {
		return 0;
	}

	public var finished(get, null):Bool;
	@:functionCode('return channel->stopped;')
	function get_finished() return false;

	public var length(get, null):Float;
	@:functionCode('return (double)channel->data_length / (double)channel->sample_rate / 2.0;') // 44.1 khz in stereo
	function get_length() return 0;

	public function new() {
		cpp.vm.Gc.setFinalizer(this, cpp.Function.fromStaticFunction(finalize));
	}

	@:functionCode('NucAudioChannel_dec(channel->channel);')
	@:void static function finalize(channel:SoundChannel):Void {}

	@:functionCode('
		channel = NucAudioChannel_create(buffer->self.data);
		channel->data_length = buffer->self.myLength;

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
		channel->sample_rate = sampleRate;

		KINC_ATOMIC_EXCHANGE_32(&channel->position , 0);
	')
	public function allocate(buffer:Float32Array, sampleRate:Int, looping:Bool):Void {}

	@:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->paused, false); KINC_ATOMIC_EXCHANGE_32(&channel->stopped, false); NucAudioChannel_playAgain(channel);')
	public function play():Void {}

	@:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->paused, true);')
	public function pause():Void {}

	@:functionCode('KINC_ATOMIC_EXCHANGE_32(&channel->stopped, true); KINC_ATOMIC_EXCHANGE_32(&channel->position, 0);')
	public function stop():Void {}

}

#else

class SoundChannel implements AudioChannel {

	public var volume(get, set):Float;
	private function get_volume() return 0;
	private function set_volume(value:Float) {
		return 0;
	}

	public var pan(get, set):Float;
	private function get_pan() return 0;
	private function set_pan(value:Float) {
		return 0;
	}

	public var position(get, set):Float;
	private function get_position() return 0;
	private function set_position(value:Float) {
		return 0;
	}

	public var playbackRate(get, set):Float;
	private function get_playbackRate() return 0;
	private function set_playbackRate(value:Float) {
		return 0;
	}

	public var finished(get, null):Bool;
	private function get_finished() return false;

	public var length(get, null):Float;
	private function get_length() return 0;

	public function new() {

	}

	public function play() {

	}

	public function pause() {

	}

	public function stop() {

	}

}

#end

