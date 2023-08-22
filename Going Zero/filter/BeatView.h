#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BeatView : NSView{
    float _ratio;
}
-(void)setRatio:(float)ratio;

@end

NS_ASSUME_NONNULL_END
