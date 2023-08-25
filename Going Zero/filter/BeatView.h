#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BeatView : NSView{
    float _ratio;
    Boolean _offBeat;
}
-(void)setRatio:(float)ratio offBeat:(Boolean)offBeat;

@end

NS_ASSUME_NONNULL_END
