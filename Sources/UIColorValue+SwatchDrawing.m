#import "UIColorValue+SwatchDrawing.h"
@implementation UIColorValue (SwatchDrawing)
#if TARGET_OS_IOS
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-FAAA5269179C  -[UIColorValue(SwatchDrawing) drawSwatchInRect:] — UIKit current-context transport; ordinary view drawing uses native screen presentation.
- (void)drawSwatchInRect:(CGRect)rect {
    [self drawSwatchInRect:rect context:UIGraphicsGetCurrentContext() drawingToScreen:YES flipped:YES];
}
#endif
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-651F0EA4A78F  -[UIColorValue(SwatchDrawing) drawSwatchInRect:context:drawingToScreen:flipped:] — approved imported NSColor.drawSwatchInRect: CG bridge; native branch at0x18394c4d8 is evidence, not an imported-class replacement.
- (void)drawSwatchInRect:(CGRect)rect context:(CGContextRef)context drawingToScreen:(BOOL)screen flipped:(BOOL)flipped {
    if(!context)return;
    if(CGColorGetAlpha(self.CGColor)==1 || !screen){CGContextSetFillColorWithColor(context,self.CGColor);CGContextFillRect(context,rect);}
    else {
        CGContextSetGrayFillColor(context,1,1);CGContextFillRect(context,rect);
        CGContextSetGrayFillColor(context,0,1);
        if(flipped){CGContextMoveToPoint(context,CGRectGetMinX(rect),CGRectGetMaxY(rect));CGContextAddLineToPoint(context,CGRectGetMinX(rect),CGRectGetMinY(rect));CGContextAddLineToPoint(context,CGRectGetMaxX(rect),CGRectGetMinY(rect));}
        else {CGContextMoveToPoint(context,CGRectGetMinX(rect),CGRectGetMinY(rect));CGContextAddLineToPoint(context,CGRectGetMinX(rect),CGRectGetMaxY(rect));CGContextAddLineToPoint(context,CGRectGetMaxX(rect),CGRectGetMaxY(rect));}
        CGContextClosePath(context);CGContextFillPath(context);
        CGContextSetFillColorWithColor(context,self.CGColor);CGContextSetBlendMode(context,kCGBlendModeNormal);CGContextFillRect(context,rect);
    }
}
@end
