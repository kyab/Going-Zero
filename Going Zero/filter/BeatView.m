#import "BeatView.h"

@implementation BeatView

- (void)awakeFromNib{
    _ratio = 0.0f;
}

-(void)setRatio:(float)ratio offBeat:(Boolean)offBeat{
    _ratio = ratio;
    _offBeat = offBeat;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
        
    [[NSColor blueColor] set];
    NSRectFill(self.bounds);

    [[NSColor orangeColor] set];
    NSRect rect = self.bounds;
    rect.size.width *= _ratio;
    NSRectFill(rect);
}

@end
