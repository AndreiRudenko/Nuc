#pragma once

// #include "rcfloats.h"

#include <kinc/threads/atomic.h>
#include <kinc/math/core.h>

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef ANDROID
#define KINC_ATOMIC_EXCHANGE_32(pointer, value) (__sync_swap(pointer, value))
#define KINC_ATOMIC_EXCHANGE_FLOAT(pointer, value) (__sync_swap((volatile int32_t *)pointer, *(int32_t *)&value))
#endif

struct stb_vorbis;

struct NucAudioChannel {
#ifdef KORE_SONY
	volatile int32_t reference_count;
	volatile int32_t position;
	volatile int32_t paused;
	volatile int32_t stopped;
#else
	volatile long reference_count;
	volatile long position;
	volatile long paused;
	volatile long stopped;
#endif
	volatile float volume;
	volatile float pan;
	volatile float l;
	volatile float r;
	volatile float playback_rate;
	float *data;
	int data_length;
	bool looping;
	int sample_rate;
};

struct NucStreamChannel {
#ifdef KORE_SONY
	volatile int32_t reference_count;
	volatile int32_t position;
	volatile int32_t paused;
	volatile int32_t stopped;
#else
	volatile long reference_count;
	volatile long position;
	volatile long paused;
	volatile long stopped;
#endif
	volatile float volume;
	volatile float pan;
	volatile float l;
	volatile float r;
	volatile float playback_rate;
	struct stb_vorbis *vorbis;
	float *buffer;
	bool decoded;
	// bool rate_decoded_hack;
	bool looping;
	int channels;
	// int data_length;
	int sample_rate;
};

void Audio_init();
bool Audio_play(struct NucAudioChannel *channel, bool loop);
bool Audio_stream(struct NucStreamChannel *channel, bool loop);

void NucAudioChannel_playAgain(struct NucAudioChannel *channel);
void NucStreamChannel_playAgain(struct NucStreamChannel *channel);

static struct NucAudioChannel *NucAudioChannel_create(float *floats) {
	// rc_floats_inc(floats);
	struct NucAudioChannel *channel = (struct NucAudioChannel *)malloc(sizeof(struct NucAudioChannel));
	channel->data = floats;
	KINC_ATOMIC_EXCHANGE_32(&channel->reference_count, 1);
	return channel;
}

static void NucAudioChannel_inc(struct NucAudioChannel *channel) {
	KINC_ATOMIC_INCREMENT(&channel->reference_count);
}

static void NucAudioChannel_dec(struct NucAudioChannel *channel) {
	int value = KINC_ATOMIC_DECREMENT(&channel->reference_count);
	if (value == 1) {
		// rc_floats_dec(channel->data);
		free(channel);
	}
}

static void Audio_calcVolume(float volume, float pan, float *l, float *r) {
	float v = (pan + 1.0f) * (float)KINC_PI / 4.0f;
	*l = kinc_cos(v) * volume;
	*r = kinc_sin(v) * volume;
}

static struct NucStreamChannel *NucStreamChannel_create(stb_vorbis *vorbis) {
	// rc_floats_inc(floats);
	struct NucStreamChannel *channel = (struct NucStreamChannel *)malloc(sizeof(struct NucStreamChannel));
	channel->vorbis = vorbis;
	KINC_ATOMIC_EXCHANGE_32(&channel->reference_count, 1);
	return channel;
}

static void NucStreamChannel_inc(struct NucStreamChannel *channel) {
	KINC_ATOMIC_INCREMENT(&channel->reference_count);
}

static void NucStreamChannel_dec(struct NucStreamChannel *channel) {
	int value = KINC_ATOMIC_DECREMENT(&channel->reference_count);
	if (value == 1) {
		// rc_floats_dec(channel->data);
		free(channel);
	}
}


#ifdef __cplusplus
}
#endif
