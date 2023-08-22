#import "BeatView.h"

@implementation BeatView

- (void)awakeFromNib{
    _ratio = 0.0f;
}

-(void)setRatio:(float)ratio{
    _ratio = ratio;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
        
    [[NSColor blueColor] set];
    NSRectFill(dirtyRect);
    
    NSRect rect = self.bounds;
    [[NSColor orangeColor] set];
    rect.size.width *= _ratio;
    NSRectFill(rect);
}

@end
