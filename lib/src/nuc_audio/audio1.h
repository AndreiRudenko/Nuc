#pragma once

// #include "rcfloats.h"

#include <kinc/threads/atomic.h>
#include <kinc/math/core.h>

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

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

void Audio_init();
bool Audio_play(struct NucAudioChannel *channel, bool loop);
void NucAudioChannel_playAgain(struct NucAudioChannel *channel);

static struct NucAudioChannel *NucAudioChannel_create(float *floats) {
	// rc_floats_inc(floats);
	struct NucAudioChannel *channel = (struct NucAudioChannel *)malloc(sizeof(struct NucAudioChannel));
	channel->data = floats;
	// KINC_ATOMIC_EXCHANGE_32(&channel->reference_count, 1);
	return channel;
}

static void NucAudioChannel_inc(struct NucAudioChannel *channel) {
	// KINC_ATOMIC_INCREMENT(&channel->reference_count);
}

static void NucAudioChannel_dec(struct NucAudioChannel *channel) {
	// int value = KINC_ATOMIC_DECREMENT(&channel->reference_count);
	// if (value == 1) {
	// 	rc_floats_dec(channel->data);
	// 	free(channel);
	// }
}

static void NucAudioChannel_calcVolume(struct NucAudioChannel *channel) {
	float pan = channel->pan;
	float volume = channel->volume;
	float v = (pan + 1.0f) * (float)KINC_PI / 4.0f;
	float l = kinc_cos(v) * volume;
	float r = kinc_sin(v) * volume;
	KINC_ATOMIC_EXCHANGE_FLOAT(&channel->l, l);
	KINC_ATOMIC_EXCHANGE_FLOAT(&channel->r, r);
}

#ifdef __cplusplus
}
#endif
