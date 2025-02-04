//
//  Connection.h
//  Moonlight
//
//  Created by Diego Waxemberg on 1/19/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//

#import "AnyVideoDecoderRenderer.h"
// Will be handled from Swift
@class StreamConfiguration;
#import "CoreAudioRenderer.h"
#import "AQRenderer.h"
#import "AVSBRenderer.h"
#import "VideoDecoderRenderer.h"

#define CONN_TEST_SERVER "ios.conntest.moonlight-stream.org"

typedef struct {
    CFTimeInterval startTime;
    CFTimeInterval endTime;
    int totalFrames;
    int receivedFrames;
    int networkDroppedFrames;
    int totalHostProcessingLatency;
    int framesWithHostProcessingLatency;
    int maxHostProcessingLatency;
    int minHostProcessingLatency;
    double iosDecodeTime;
} video_stats_t;

static volatile int volume = 127;
//void setVolume(int newVol);

int DrSubmitDecodeUnit(PDECODE_UNIT decodeUnit);

typedef struct {
    uint32_t opusBytesReceived;                 // total Opus bytes received
    double opusKbitsPerSec;                     // current Opus bitrate in kbps, not including FEC overhead
    uint32_t decodedSamples;                    // total packets decoded
    uint32_t droppedSamples;                    // total packets lost to the network
    uint64_t decodeDurationUs;                  // cumulative render time, microseconds
    uint32_t lastRtt;                           // network latency from enet, milliseconds
    CFTimeInterval startTime;                   // timestamp stats were started, microseconds
} audio_stats_t;

@interface Connection : NSOperation <NSStreamDelegate>

-(id) initWithConfig:(StreamConfiguration*)config renderer:(id<AnyVideoDecoderRenderer> __strong)myRenderer connectionCallbacks:(id<ConnectionCallbacks>)callbacks;
-(void) terminate;
-(void) main;
-(BOOL) getVideoStats:(video_stats_t*)stats;
-(NSString *) getAudioStatsString;
-(NSString*) getActiveCodecName;

@end
