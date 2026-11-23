#import "UIColorPanelFavoriteSwatchView.h"
#import "UIColorValue+SwatchDrawing.h"
#import "UIColorPanelAppearance.h"
@implementation UIColorPanelFavoriteSwatchView
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-5517A0AC1F8E  -[UIColorPanelFavoriteSwatchView initWithFrame:] — UIKit reusable-cell transport with a genuinely unfilled decoration.
- (instancetype)initWithFrame:(CGRect)frame {if((self=[super initWithFrame:frame])){self.opaque=NO;self.backgroundColor=UIColor.clearColor;self.contentView.backgroundColor=UIColor.clearColor;self.contentMode=UIViewContentModeRedraw;}return self;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-548098A995A1  -[UIColorPanelFavoriteSwatchView setColor:] — canonical transport and UIKit invalidation.
- (void)setColor:(UIColorValue *)color {_color=color;[self setNeedsDisplay];}
// BINMAP-ADAPT: UIColorPanelFavoriteSwatchView.setUsesCircularPresentation: manifest=reimpl/polish_appearance_extras.json
- (void)setUsesCircularPresentation:(BOOL)circular {if(_usesCircularPresentation==circular)return;_usesCircularPresentation=circular;[self setNeedsDisplay];}
// BINMAP-ADAPT: UIColorPanelFavoriteSwatchView.setSelected: manifest=reimpl/ui_ux_repairs_extras.json
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.accessibilityTraits=(self.accessibilityTraits&~UIAccessibilityTraitSelected)|(selected?UIAccessibilityTraitSelected:0);
    [self setNeedsDisplay];
}
// BINMAP-ADAPT: UIColorPanelFavoriteSwatchView.tintColorDidChange manifest=reimpl/ui_ux_repairs_extras.json
- (void)tintColorDidChange {[super tintColorDidChange];[self setNeedsDisplay];}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchView drawRect:] ea=0x1840458b4 end=0x1840459e4
- (void)drawRect:(CGRect)rect {
    CGRect bounds=self.bounds;BOOL circular=self.usesCircularPresentation;CGContextRef context=UIGraphicsGetCurrentContext();
    if(circular){CGFloat diameter=MIN(30,MIN(bounds.size.width,bounds.size.height));bounds=CGRectMake(CGRectGetMidX(bounds)-diameter/2,CGRectGetMidY(bounds)-diameter/2,diameter,diameter);}
    // BINNOTE: Authorized appearance adaptation shares the smooth outline between alpha clipping and border.
    UIBezierPath *path=circular?[UIBezierPath bezierPathWithOvalInRect:bounds]:[UIColorPanelAppearance smoothPathForRect:bounds radius:MIN(8,MAX(2,MIN(bounds.size.width,bounds.size.height)*2/13))];
    // BINMAP-ADAPT: expanded-manager dots use the recovered native footer's color ring and clear gap.
    if(circular&&self.selected){CGFloat inset=bounds.size.width/10;[path appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds,inset,inset)]bezierPathByReversingPath]];[path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds,2*inset,2*inset)]];}
    CGContextSaveGState(context);CGContextAddPath(context,path.CGPath);CGContextClip(context);
    // Composite the opaque alpha-background/color/border once through the
    // antialiased outline; repeated source-over draws otherwise multiply edge
    // coverage and make the silhouette depend on the stored color alpha.
    CGContextBeginTransparencyLayer(context,NULL);
    if(self.color){
        // BINMAP-BLOCK: invoke_ea=0x1840459e4 parent_ea=0x1840458b4 reconstructed_as=block_literal
        void (^drawColor)(void)=^{[self.color drawSwatchInRect:bounds];};drawColor();
    }
    if(!circular){
        UIColor *stroke;if(@available(iOS 13.0,*))stroke=UIColor.tertiaryLabelColor;else stroke=[UIColor colorWithWhite:.35 alpha:.3];
        CGContextSetStrokeColorWithColor(context,stroke.CGColor);CGContextSetLineWidth(context,2);CGContextAddPath(context,path.CGPath);CGContextStrokePath(context);
        // BINNOTE: UIKit selection stays inside the existing outline; the white
        // inner band distinguishes the ring when the stored color matches the tint.
        if(self.selected){
            CGFloat selectionWidth=MIN(6,MIN(bounds.size.width,bounds.size.height)/3);
            CGContextSetStrokeColorWithColor(context,UIColor.whiteColor.CGColor);CGContextSetLineWidth(context,selectionWidth);CGContextAddPath(context,path.CGPath);CGContextStrokePath(context);
            CGContextSetStrokeColorWithColor(context,self.tintColor.CGColor);CGContextSetLineWidth(context,selectionWidth/2);CGContextAddPath(context,path.CGPath);CGContextStrokePath(context);
        }
    }
    CGContextEndTransparencyLayer(context);CGContextRestoreGState(context);
}
// BINMAP: original=AppKit ida_name=+[NSColorPanelFavoriteSwatchView intrinsicContentSize] ea=0x184045a74 end=0x184045a80
+ (CGSize)intrinsicContentSize {return CGSizeMake(13,13);}
@end
