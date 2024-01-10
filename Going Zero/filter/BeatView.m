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
    
    NSRect rect = self.bounds;
    if (_offBeat){
        [[NSColor cyanColor] set];
    }else{
        [[NSColor orangeColor] set];
    }
    rect.size.width *= _ratio;
    NSRectFill(rect);
}

@end
