#import "UIColorPickerColorPreview.h"
#import "UIColorPanelAppearance.h"

@implementation UIColorPickerColorPreview
// BINMAP-ADAPT: UIColorPickerColorPreview.initWithFrame: manifest=reimpl/native_preview_api_manifest.json
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.opaque=NO;self.backgroundColor=UIColor.clearColor;self.contentMode=UIViewContentModeRedraw;
        self.isAccessibilityElement=YES;self.accessibilityTraits=UIAccessibilityTraitImage;
        self.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Current color"];
    }return self;
}
// BINMAP-ADAPT: UIColorPickerColorPreview.setColor: manifest=reimpl/native_preview_api_manifest.json
- (void)setColor:(UIColorValue *)color {_color=color;[self setNeedsDisplay];}
// BINMAP-ADAPT: UIColorPickerColorPreview.drawRect: manifest=reimpl/native_preview_api_manifest.json
- (void)drawRect:(CGRect)rect {
    CGContextRef context=UIGraphicsGetCurrentContext();CGContextSaveGState(context);
    [[UIColorPanelAppearance smoothPathForRect:self.bounds radius:8]addClip];
    [self drawContentInRect:self.bounds];CGContextRestoreGState(context);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100015D20 ea=0x100015d20 end=0x100015f36
- (void)drawContentInRect:(CGRect)rect {
    [UIColor.whiteColor setFill];UIRectFill(rect);
    [UIColor.blackColor setFill];[[self.class diagonalPathForRect:rect]fill];
    CGContextRef context=UIGraphicsGetCurrentContext();CGContextSetFillColorWithColor(context,self.color.CGColor);CGContextFillRect(context,rect);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100015FA0 ea=0x100015fa0 end=0x10001629d
+ (UIBezierPath *)diagonalPathForRect:(CGRect)rect {
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(rect),CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect),CGRectGetMinY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect),CGRectGetMinY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect),CGRectGetMaxY(rect))];
    [path closePath];return path;
}
@end
