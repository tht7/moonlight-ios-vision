#pragma once

#import <AVFoundation/AVFoundation.h>

#include <Limelight.h>

#define HEADER_IDENTIFIER "MNLT"
#define HEADER_IDENTIFIER_SIZE 4
typedef struct __attribute__((__packed__)) {
    char identifier[HEADER_IDENTIFIER_SIZE];
    uint32_t pts;
    uint64_t decodeStartTimeNanos;
} PCMHeader;

@interface AVSBRenderer : NSObject

- (instancetype)initWithConfig:(const OPUS_MULTISTREAM_CONFIGURATION*)opusConfig;
- (void)start;
- (void)stop;
- (void *)getAudioBuffer:(int *)size;
- (bool)submitAudio:(int)bytesWritten opusBytes:(int)opusBytes;
- (void)handleRouteChange:(NSNotification *)notification;
- (void)handleResetNotification:(NSNotification *)notification;
- (void)handleFlushedNotification:(NSNotification *)notification;
- (NSString *)getAudioStatsString;

@end

