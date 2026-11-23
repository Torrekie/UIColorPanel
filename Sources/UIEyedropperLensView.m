#import "UIEyedropperLensView.h"
#import "UIColorPanelAppearance.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface UIEyedropperGridView () { NSInteger _cellCount; }
@end
@implementation UIEyedropperGridView
@synthesize strokeColor=_strokeColor;
// BINMAP: original=Eyedropper ida_name=-[EDGridView initWithWithCellCount:] ea=0x2a3f end=0x2abe
- (instancetype)initWithWithCellCount:(NSInteger)count { if((self=[super init])){_cellCount=count;_strokeColor=UIColor.whiteColor;}return self; }
// BINMAP: original=Eyedropper ida_name=-[EDGridView setStrokeColor:] ea=0x2abe end=0x2b06
- (void)setStrokeColor:(UIColor *)color { _strokeColor=color;[self setNeedsDisplay]; }
// BINMAP: original=Eyedropper ida_name=-[EDGridView drawRect:] ea=0x2b06 end=0x2c59
- (void)drawRect:(CGRect)rect {
    CGContextRef context=UIGraphicsGetCurrentContext();CGContextSetStrokeColorWithColor(context,_strokeColor.CGColor);
    CGFloat width=self.bounds.size.width,height=self.bounds.size.height,step=width/_cellCount;
    for(CGFloat x=step;x<width;x+=step){CGPoint points[2]={{x,0},{x,height}};CGContextStrokeLineSegments(context,points,2);}
    for(CGFloat y=step;y<height;y+=step){CGPoint points[2]={{0,y},{height,y}};CGContextStrokeLineSegments(context,points,2);}
}
@end

@interface UIEyedropperLensView () {
    UIEyedropperRGB _hoverColor;
    CGFloat _hoverColorBrightness;
    BOOL _shouldChangeAlphaWhenDismissing;
}
@property(nonatomic,strong) UIView *hoverColorRingView,*ringBorderView,*screenshotSurfaceView,*hoverColorCenterView;
@property(nonatomic,strong) UIEyedropperGridView *gridView;
@property(nonatomic,readwrite) NSInteger lensState;
@end
@implementation UIEyedropperLensView
@synthesize sample=_sample;
// BINMAP-ADAPT: UIEyedropperLensView.initWithFrame: — original0x3008 geometry; public layers, no private update masks or system display link/source.
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        [self updateLensState:2];self.layer.shadowColor=UIColor.blackColor.CGColor;self.layer.shadowOpacity=.3;self.layer.shadowRadius=20;self.layer.shadowOffset=CGSizeMake(0,1);
        _hoverColorRingView=[UIView new];_hoverColorRingView.backgroundColor=UIColor.clearColor;_hoverColorRingView.layer.borderColor=UIColor.whiteColor.CGColor;_hoverColorRingView.layer.borderWidth=3;_hoverColorRingView.userInteractionEnabled=NO;[self addSubview:_hoverColorRingView];
        _ringBorderView=[UIView new];_ringBorderView.clipsToBounds=YES;_ringBorderView.backgroundColor=UIColor.whiteColor;_ringBorderView.layer.borderWidth=12;[self addSubview:_ringBorderView];
        _screenshotSurfaceView=[UIView new];_screenshotSurfaceView.clipsToBounds=YES;_screenshotSurfaceView.layer.magnificationFilter=kCAFilterNearest;_screenshotSurfaceView.userInteractionEnabled=NO;[self addSubview:_screenshotSurfaceView];
        _gridView=[[UIEyedropperGridView alloc]initWithWithCellCount:9];_gridView.clipsToBounds=YES;_gridView.layer.magnificationFilter=kCAFilterNearest;_gridView.userInteractionEnabled=NO;_gridView.backgroundColor=UIColor.clearColor;[self addSubview:_gridView];
        _hoverColorCenterView=[UIView new];_hoverColorCenterView.layer.borderWidth=4;_hoverColorCenterView.layer.cornerRadius=2;[self addSubview:_hoverColorCenterView];
        _hoverColor=UIEyedropperColorMake(0,0,0);self.accessibilityIdentifier=@"ui.eyedropper.lens";
    }return self;
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView _layoutStaticElements] ea=0x36d8 end=0x3e7f
- (void)_layoutStaticElements {
    self.ringBorderView.frame=CGRectInset(self.bounds,62,62);self.ringBorderView.layer.cornerRadius=self.ringBorderView.bounds.size.width*.5;
    self.screenshotSurfaceView.frame=CGRectInset(self.bounds,79,79);self.screenshotSurfaceView.layer.cornerRadius=self.screenshotSurfaceView.bounds.size.width*.5;
    self.gridView.frame=CGRectInset(self.bounds,79,79);self.gridView.layer.cornerRadius=self.screenshotSurfaceView.bounds.size.width*.5;
    CGFloat border=self.hoverColorCenterView.layer.borderWidth,cell=self.screenshotSurfaceView.bounds.size.width/9;
    self.hoverColorCenterView.frame=CGRectMake(-border,-border,cell+border,cell+border);self.hoverColorCenterView.center=self.ringBorderView.center;
    UIColor *stroke=_hoverColorBrightness<=.9?[UIColor colorWithWhite:1 alpha:.7]:[UIColor colorWithWhite:.4 alpha:.7];
    UIColor *background=_hoverColorBrightness<=.9?[UIColor colorWithWhite:1 alpha:1]:[UIColor colorWithWhite:.6 alpha:1];
    self.hoverColorCenterView.layer.borderColor=stroke.CGColor;self.ringBorderView.layer.borderColor=UIEyedropperColorUIColor(_hoverColor).CGColor;
    self.hoverColorCenterView.layer.borderColor=background.CGColor;self.ringBorderView.layer.backgroundColor=background.CGColor;self.gridView.strokeColor=stroke;
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView layoutSubviews] ea=0x3e95 end=0x3fc1
- (void)layoutSubviews {
    [super layoutSubviews];[self _layoutStaticElements];
    switch(_lensState){case 0:self.hidden=NO;self.alpha=1;break;case 1:if(_shouldChangeAlphaWhenDismissing)self.alpha=0;break;case 2:self.hidden=YES;self.alpha=0;self.center=self.lastPosition;break;case 3:self.center=self.lastPosition;break;default:return;}
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView updateLensState:] ea=0x3fd4 end=0x3feb
- (void)updateLensState:(NSInteger)state { if(_lensState!=state)_lensState=state; }
// BINMAP: original=Eyedropper ida_name=-[EDLensView _lensViewLocalCenter] ea=0x3feb end=0x4008
- (CGPoint)_lensViewLocalCenter { return self.screenshotSurfaceView.center; }
// BINMAP-ADAPT: UIEyedropperLensView.accessibilityLabel — localization of native label0x4008.
- (NSString *)accessibilityLabel { return [UIColorPanelAppearance localizedString:@"Eyedropper hovering over color"]; }
// BINMAP-ADAPT: UIEyedropperLensView.accessibilityValue — original RGB values remain unclamped; presentation localization is independent.
- (NSString *)accessibilityValue { return [NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"RGB value is R: %.2f., G: %.2f., B: %.2f."],_hoverColor.r,_hoverColor.g,_hoverColor.b]; }
// BINMAP-ADAPT: UIEyedropperLensView.accessibilityTraits — explicit usable public AX traits rather than the original ambiguous flag expression0x4055.
- (UIAccessibilityTraits)accessibilityTraits { return UIAccessibilityTraitButton|UIAccessibilityTraitUpdatesFrequently; }
// BINMAP: original=Eyedropper ida_name=-[EDLensView isAccessibilityElement] ea=0x407c end=0x4084
- (BOOL)isAccessibilityElement { return YES; }
// BINMAP: original=Eyedropper ida_name=-[EDLensView presentAtLocation:] ea=0x4173 end=0x4375
- (void)presentAtLocation:(CGPoint)location {
    if(_lensState==2){self.lastPosition=location;[self setNeedsLayout];[self layoutIfNeeded];[self updateLensState:0];[self setNeedsLayout];}
    else{
        CGFloat scale=UIScreen.mainScreen.scale,dx=location.x-self.lastPosition.x,dy=location.y-self.lastPosition.y;
        if(fabs(dx)>=200||fabs(dy)>=200){[self _dismissAndRemoveAlpha:YES];[self.delegate lensViewDidDismiss:self];}
        else{CGPoint point=self.lastPosition;if(fabs(dx)<=fabs(dy)){if(dy>60)point.y+=1/scale;else if(dy<60)point.y-=1/scale;}else{if(dx>60)point.x+=1/scale;else if(dx<60)point.x-=1/scale;}self.lastPosition=point;[self setNeedsLayout];}
    }
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView tappedCenter:] ea=0x4375 end=0x43ac
- (void)tappedCenter:(id)sender { if(self.floatingMode)[self dismiss]; }
// BINMAP: original=Eyedropper ida_name=-[EDLensView dismiss] ea=0x43ac end=0x4482
- (void)dismiss { [self.delegate lensView:self didSelectColor:UIEyedropperColorUIColor(_hoverColor)];[self _dismissAndRemoveAlpha:YES];[self.delegate lensViewDidDismiss:self]; }
// BINMAP-ADAPT: UIEyedropperLensView._dismissAndRemoveAlpha: — private spring import replaced with public animation; original lexical blocks retained here.
- (void)_dismissAndRemoveAlpha:(BOOL)removeAlpha {
    _shouldChangeAlphaWhenDismissing=removeAlpha;[self updateLensState:1];[self setNeedsLayout];
    [UIView animateWithDuration:.25 delay:0 usingSpringWithDamping:.85 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // BINMAP-BLOCK: original=Eyedropper invoke_ea=0x4542 parent_ea=0x4482 reconstructed_as=block_literal
        [self layoutIfNeeded];
    } completion:^(BOOL finished){
        // BINMAP-BLOCK: original=Eyedropper invoke_ea=0x456a parent_ea=0x4482 reconstructed_as=block_literal; no system display link exists in frozen-source adapter.
        [self updateLensState:2];[self setNeedsLayout];
    }];
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView _isScreenScaleEven] ea=0x47d3 end=0x4825
- (BOOL)_isScreenScaleEven { return (((int)UIScreen.mainScreen.scale)&1)==0; }
// BINMAP-ADAPT: UIEyedropperLensView._displayLinkFired — private screen-render import0x4825 replaced by an explicit snapshot provider, invoked when position changes.
- (void)_displayLinkFired {
    if(!self.samplingHandler)return;
    // Frozen snapshots refresh synchronously at the requested model position;
    // there is no system display-link pass to catch a previous presentation frame.
    CGRect frame=self.frame;
    self.sample=self.samplingHandler(CGPointMake(CGRectGetMidX(frame),CGRectGetMidY(frame)));
}
// BINMAP-ADAPT: UIEyedropperLensView.setSample: — transport source snapshot into original surface/hover state.
- (void)setSample:(UIEyedropperSample *)sample {
    _sample=sample;self.screenshotSurfaceView.layer.contents=(__bridge id)sample.magnifiedPixels.CGImage;
    if(sample){_hoverColor=UIEyedropperColorMakeWithColor(sample.color.UIColor);_hoverColorBrightness=_hoverColor.r*.3+_hoverColor.g*.59+_hoverColor.b*.11;}
    [self setNeedsLayout];
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView _lensPosition] ea=0x4d1a end=0x5093
- (NSInteger)_lensPosition {
    CGRect frame=self.frame,bounds=self.superview.bounds;
    if(CGRectGetMinY(bounds)<=CGRectGetMinY(frame)){
        if(CGRectGetMaxY(frame)<=CGRectGetMaxY(bounds)){if(CGRectGetMinX(bounds)<=CGRectGetMinX(frame))return 2*(CGRectGetMaxX(frame)>CGRectGetMaxX(bounds));return 1;}
        if(CGRectGetMinX(bounds)<=CGRectGetMinX(frame))return 4*(CGRectGetMaxX(frame)>CGRectGetMaxX(bounds))+4;return 7;
    }
    if(CGRectGetMinX(bounds)<=CGRectGetMinX(frame))return 3*(CGRectGetMaxX(frame)>CGRectGetMaxX(bounds))+3;return 5;
}
// BINMAP: original=Eyedropper ida_name=-[EDLensView pointInside:withEvent:] ea=0x5093 end=0x50fb
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event { return CGRectContainsPoint(self.ringBorderView.frame,point); }
@end
