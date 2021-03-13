#include <kinc/pch.h>

#define STB_VORBIS_HEADER_ONLY
#include <kinc/audio1/stb_vorbis.c>

#include "audio1.h"

#include <kinc/audio2/audio.h>
#include <kinc/threads/mutex.h>

#include <math.h>
#include <stdlib.h>
#include <string.h>

#define CHANNEL_COUNT 64

static kinc_mutex_t mutex;

struct NucAudioChannel *soundChannels[CHANNEL_COUNT];
struct NucStreamChannel *streamChannels[CHANNEL_COUNT];

struct NucAudioChannel *internalSoundChannels[CHANNEL_COUNT];
struct NucStreamChannel *internalStreamChannels[CHANNEL_COUNT];

static float round_float(float value) {
	return floorf(value + 0.5f);
}

static int maxi(int a, int b) {
	return a > b ? a : b;
}

static int mini(int a, int b) {
	return a < b ? a : b;
}

static float maxf(float a, float b) {
	return a > b ? a : b;
}

static float minf(float a, float b) {
	return a < b ? a : b;
}

static int sampleLength(struct NucAudioChannel *channel, int sampleRate) {
	int value = (int)ceilf((float)channel->data_length * ((float)sampleRate / (float)channel->sample_rate));
	return value % 2 == 0 ? value : value + 1;
}

static float lerp(float v0, float v1, float t) {
	return (1.0f - t) * v0 + t * v1;
}

static float sample(struct NucAudioChannel *channel, int position, int sampleRate) {
	bool even = position % 2 == 0;
	float factor = (float)channel->sample_rate / (float)sampleRate * channel->playback_rate;

	if (even) {
		position /= 2;
		float pos = factor * position;
		int pos1 = (int)floorf(pos);
		int pos2 = pos1 + 1;
		pos1 *= 2;
		pos2 *= 2;

		int minimum = 0;
		int maximum = channel->data_length - 1;
		maximum = maximum % 2 == 0 ? maximum : maximum - 1;

		float a = (pos1 < minimum || pos1 > maximum) ? 0 : channel->data[pos1];
		float b = (pos2 < minimum || pos2 > maximum) ? 0 : channel->data[pos2];
		return lerp(a, b, pos - floorf(pos));
	}
	else {
		position /= 2;
		float pos = factor * position;
		int pos1 = (int)floorf(pos);
		int pos2 = pos1 + 1;
		pos1 = pos1 * 2 + 1;
		pos2 = pos2 * 2 + 1;

		int minimum = 1;
		int maximum = channel->data_length - 1;
		maximum = maximum % 2 != 0 ? maximum : maximum - 1;

		float a = (pos1 < minimum || pos1 > maximum) ? 0 : channel->data[pos1];
		float b = (pos2 < minimum || pos2 > maximum) ? 0 : channel->data[pos2];
		return lerp(a, b, pos - floorf(pos));
	}
}

void NucAudioChannel_nextSamples(struct NucAudioChannel *channel, float *requestedSamples, int requestedLength, int sampleRate) {
	const int start_position = channel->position;
	int position = start_position;

	if (channel->paused || channel->stopped) {
		for (int i = 0; i < requestedLength; ++i) {
			requestedSamples[i] = 0;
		}
		return;
	}

	int requestedSamplesIndex = 0;
	while (requestedSamplesIndex < requestedLength) {
		int iterations = mini(sampleLength(channel, sampleRate) - position, requestedLength - requestedSamplesIndex);
		for (int i = 0; i < iterations; ++i) {
			requestedSamples[requestedSamplesIndex++] = sample(channel, position++, sampleRate);
		}

		if (position >= sampleLength(channel, sampleRate)) {
			position = 0;
			if (!channel->looping) {
				channel->stopped = true;
				break;
			}
		}
	}

	KINC_ATOMIC_COMPARE_EXCHANGE(&channel->position, start_position, position);

	while (requestedSamplesIndex < requestedLength) {
		requestedSamples[requestedSamplesIndex++] = 0;
	}
}

void NucAudioChannel_playAgain(struct NucAudioChannel *channel) {
	kinc_mutex_lock(&mutex);
	int i;
	bool foundChannel = false;
	for (i = 0; i < CHANNEL_COUNT; ++i) {
		if (soundChannels[i] == NULL) {
			NucAudioChannel_inc(channel);
			soundChannels[i] = channel;
			foundChannel = true;
			break;
		}
		if (soundChannels[i] == channel) {
			foundChannel = true;
			break;
		}
		if (soundChannels[i]->paused || soundChannels[i]->stopped) {
			NucAudioChannel_dec(soundChannels[i]);
			NucAudioChannel_inc(channel);
			soundChannels[i] = channel;
			foundChannel = true;
			break;
		}
	}
	++i;
	for (; i < CHANNEL_COUNT; ++i) {
		if (soundChannels[i] == channel) {
			NucAudioChannel_dec(soundChannels[i]);
			soundChannels[i] = NULL;
		}
	}
	if (!foundChannel) {
		for (i = 0; i < CHANNEL_COUNT; ++i) {
			if (soundChannels[i] == NULL) {
				NucAudioChannel_inc(channel);
				soundChannels[i] = channel;
				foundChannel = true;
				break;
			}
			if (soundChannels[i] == channel) {
				foundChannel = true;
				break;
			}
			if (soundChannels[i]->paused || soundChannels[i]->stopped || soundChannels[i]->volume == 0.0f) {
				NucAudioChannel_dec(soundChannels[i]);
				NucAudioChannel_inc(channel);
				soundChannels[i] = channel;
				foundChannel = true;
				break;
			}
		}
	}
	kinc_mutex_unlock(&mutex);
}

float NucAudioChannel_length_in_seconds(struct NucAudioChannel *channel) {
	return channel->data_length / (float)kinc_a2_samples_per_second / 2.0f; // Stereo
}

// stream
void NucStreamChannel_nextSamples(struct NucStreamChannel *channel, float *requestedSamples, int requestedLength, int sampleRate) {
	if (channel->vorbis == NULL) return;

	int channels = 2;

	int read = stb_vorbis_get_samples_float_interleaved(channel->vorbis, channels, requestedSamples, requestedLength);
	if (read < requestedLength / channels) {
		if (channel->looping) {
			stb_vorbis_seek_start(channel->vorbis);
		} else {
			channel->stopped = true;
		}

		for (int i = read * channels; i < requestedLength; ++i) {
			requestedSamples[i] = 0;
		}
	}
}

void NucStreamChannel_playAgain(struct NucStreamChannel *channel) {
	kinc_mutex_lock(&mutex);

	if (channel->vorbis != NULL) {
		if (channel->stopped) {
			channel->stopped = false;
			stb_vorbis_seek_start(channel->vorbis);
		}
	}

	int i;
	bool foundChannel = false;
	for (i = 0; i < CHANNEL_COUNT; ++i) {
		if (streamChannels[i] == NULL) {
			NucStreamChannel_inc(channel);
			streamChannels[i] = channel;
			foundChannel = true;
			break;
		}
		if (streamChannels[i] == channel) {
			foundChannel = true;
			break;
		}
		if (streamChannels[i]->paused || streamChannels[i]->stopped) {
			NucStreamChannel_dec(streamChannels[i]);
			NucStreamChannel_inc(channel);
			streamChannels[i] = channel;
			foundChannel = true;
			break;
		}
	}
	++i;
	for (; i < CHANNEL_COUNT; ++i) {
		if (streamChannels[i] == channel) {
			NucStreamChannel_dec(streamChannels[i]);
			streamChannels[i] = NULL;
		}
	}
	if (!foundChannel) {
		for (i = 0; i < CHANNEL_COUNT; ++i) {
			if (streamChannels[i] == NULL) {
				NucStreamChannel_inc(channel);
				streamChannels[i] = channel;
				foundChannel = true;
				break;
			}
			if (streamChannels[i] == channel) {
				foundChannel = true;
				break;
			}
			if (streamChannels[i]->paused || streamChannels[i]->stopped || streamChannels[i]->volume == 0.0f) {
				NucStreamChannel_dec(streamChannels[i]);
				NucStreamChannel_inc(channel);
				streamChannels[i] = channel;
				foundChannel = true;
				break;
			}
		}
	}
	kinc_mutex_unlock(&mutex);
}

struct Buffer {
	int size;
	int write_location;
	int samples_per_second;
	float *data;
};

float *sampleCache1 = NULL;
float *sampleCache2 = NULL;
int sampleCacheSize = 0;

static void allocateSampleCache(int size) {
	free(sampleCache1);
	free(sampleCache2);
	sampleCacheSize = size;
	sampleCache1 = (float *)malloc(size * sizeof(float));
	sampleCache2 = (float *)malloc(size * sizeof(float));
}

static void mix(kinc_a2_buffer_t *buffer, int samples) {
	if (sampleCacheSize < samples) {
		allocateSampleCache(samples * 2);
	}

	for (int i = 0; i < samples; ++i) {
		sampleCache2[i] = 0;
	}

	kinc_mutex_lock(&mutex);
	for (int i = 0; i < CHANNEL_COUNT; ++i) {
		if (soundChannels[i] != NULL) {
			NucAudioChannel_inc(soundChannels[i]);
		}
		if (streamChannels[i] != NULL) {
			NucStreamChannel_inc(streamChannels[i]);
		}

		internalSoundChannels[i] = soundChannels[i];
		internalStreamChannels[i] = streamChannels[i];
	}
	kinc_mutex_unlock(&mutex);


	for (int i = 0; i < CHANNEL_COUNT; ++i) {
		struct NucAudioChannel *channel = internalSoundChannels[i];
		if (channel == NULL || channel->paused || channel->stopped) {
			continue;
		}
		NucAudioChannel_nextSamples(channel, sampleCache1, samples, kinc_a2_samples_per_second);
		for (int j = 0; j < samples; j+=2) {
			sampleCache2[j] += sampleCache1[j] * channel->l;
			sampleCache2[j+1] += sampleCache1[j+1] * channel->r;
		}
	}

	for (int i = 0; i < CHANNEL_COUNT; ++i) {
		struct NucStreamChannel *channel = internalStreamChannels[i];
		if (channel == NULL || channel->paused || channel->stopped) {
			continue;
		}

		NucStreamChannel_nextSamples(channel, sampleCache1, samples, kinc_a2_samples_per_second);
		for (int j = 0; j < samples; j+=2) {
			sampleCache2[j] += sampleCache1[j] * channel->l;
			sampleCache2[j+1] += sampleCache1[j+1] * channel->r;
		}

	}

	for (int i = 0; i < CHANNEL_COUNT; ++i) {
		if (internalSoundChannels[i] != NULL) {
			NucAudioChannel_dec(internalSoundChannels[i]);
			internalSoundChannels[i] = NULL;
		}
		if (internalStreamChannels[i] != NULL) {
			NucStreamChannel_dec(internalStreamChannels[i]);
			internalStreamChannels[i] = NULL;
		}
	}

	for (int i = 0; i < samples; ++i) {
		*(float *)&buffer->data[buffer->write_location] = maxf(minf(sampleCache2[i], 1.0f), -1.0f);
		buffer->write_location += 4;
		if (buffer->write_location >= buffer->data_size) {
			buffer->write_location = 0;
		}
	}
}

void Audio_init() {
	kinc_mutex_init(&mutex);
	allocateSampleCache(512);
	memset(soundChannels, 0, sizeof(soundChannels));
	memset(streamChannels, 0, sizeof(streamChannels));
	memset(internalSoundChannels, 0, sizeof(internalSoundChannels));
	memset(internalStreamChannels, 0, sizeof(internalStreamChannels));
	kinc_a2_set_callback(mix);
}

bool Audio_play(struct NucAudioChannel *channel, bool loop) {
	bool foundChannel = false;

	kinc_mutex_lock(&mutex);
	channel->looping = loop;
	for (int i = 0; i < CHANNEL_COUNT; ++i) {
		if (soundChannels[i] == NULL || soundChannels[i]->paused || soundChannels[i]->stopped) {
			if (soundChannels[i] != NULL) {
				NucAudioChannel_dec(soundChannels[i]);
			}
			NucAudioChannel_inc(channel);
			soundChannels[i] = channel;
			foundChannel = true;
			break;
		}
	}
	if (!foundChannel) {
		for (int i = 0; i < CHANNEL_COUNT; ++i) {
			if (soundChannels[i] == NULL || soundChannels[i]->paused || soundChannels[i]->stopped || soundChannels[i]->volume == 0.0f) {
				if (soundChannels[i] != NULL) {
					NucAudioChannel_dec(soundChannels[i]);
				}
				NucAudioChannel_inc(channel);
				soundChannels[i] = channel;
				foundChannel = true;
				break;
			}
		}
	}
	kinc_mutex_unlock(&mutex);

	return foundChannel;
}

bool Audio_stream(struct NucStreamChannel *channel, bool loop) {
	bool foundChannel = false;

	kinc_mutex_lock(&mutex);
	channel->looping = loop;
	for (int i = 0; i < CHANNEL_COUNT; ++i) {
		if (streamChannels[i] == NULL || streamChannels[i]->paused || streamChannels[i]->stopped) {
			if (streamChannels[i] != NULL) {
				NucStreamChannel_dec(streamChannels[i]);
			}
			NucStreamChannel_inc(channel);
			streamChannels[i] = channel;
			foundChannel = true;
			break;
		}
	}
	if (!foundChannel) {
		for (int i = 0; i < CHANNEL_COUNT; ++i) {
			if (streamChannels[i] == NULL || streamChannels[i]->paused || streamChannels[i]->stopped || streamChannels[i]->volume == 0.0f) {
				if (streamChannels[i] != NULL) {
					NucStreamChannel_dec(streamChannels[i]);
				}
				NucStreamChannel_inc(channel);
				streamChannels[i] = channel;
				foundChannel = true;
				break;
			}
		}
	}
	kinc_mutex_unlock(&mutex);

	return foundChannel;
}
