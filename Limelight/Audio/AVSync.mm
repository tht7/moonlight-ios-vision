#import "AVSync.h"
#import "CoreAudioHelpers.h"

@implementation AVSync
{
    CMTime           _audioPts;
    CFTimeInterval   _audioPtsUpdateTime;
    CMTime           _videoPts;
    CFTimeInterval   _videoPtsUpdateTime;
    dispatch_queue_t _syncQueue;
}

-(instancetype)init
{
    self = [super init];

    _syncQueue = dispatch_queue_create("com.moonlight.AVSync",
                                        dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,
                                                                                QOS_CLASS_USER_INITIATED, 0));
    return self;
}

-(void)setAudioPts:(uint32_t)pts
{
    dispatch_barrier_async(_syncQueue, ^{
        self->_audioPts = CMTimeMake(pts, 1000);
        self->_audioPtsUpdateTime = CACurrentMediaTime();
    });
}

-(void)setVideoPts:(uint32_t)pts
{
    dispatch_barrier_async(_syncQueue, ^{
        self->_videoPts = CMTimeMake(pts, 1000);
        self->_videoPtsUpdateTime = CACurrentMediaTime();
    });
}

-(double)getAudioVideoSyncOffset
{
    __block double offset = 0.0;

    dispatch_barrier_sync(_syncQueue, ^{
        offset = CMTimeGetSeconds( CMTimeSubtract(_videoPts, _audioPts) );
    });

    return offset;
}

@end
