#pragma once

#import <AVFoundation/AVFoundation.h>

#include <Limelight.h>

@interface AVSync : NSObject

- (void)setAudioPts:(uint32_t)pts;
- (void)setVideoPts:(uint32_t)pts;
- (double)getAudioVideoSyncOffset;

@end

