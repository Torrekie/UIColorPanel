#import "UIColorPickerColorSlider.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "UIColorPickerFormatting.h"
static NSDictionary<NSNumber *,UIImage *> *opacityCache;
static dispatch_once_t opacityCacheOnce;
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002E880 ea=0x10002e880 end=0x10002e899
static void UIColorPickerInitializeOpacityCache(void *context) {opacityCache=@{};}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100034C10 ea=0x100034c10 end=0x100035019
UIImage *UIColorPickerOpacityTile(CGFloat height) {
    dispatch_once_f(&opacityCacheOnce,NULL,UIColorPickerInitializeOpacityCache);
    UIImage *cached=opacityCache[@(height)];if(cached)return cached;
    CGFloat side=height/3.0;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side+side,side+side),NO,0);
    CGContextRef context=UIGraphicsGetCurrentContext();if(!context)__builtin_trap();
    CGContextSaveGState(context);
    CGContextAddRect(context,CGRectMake(0,0,side,side));
    CGContextAddRect(context,CGRectMake(side,side,side,side));
    CGContextSetFillColorWithColor(context,[[UIColor alloc]initWithDisplayP3Red:.851 green:.847 blue:.855 alpha:1].CGColor);
    CGContextFillPath(context);CGContextRestoreGState(context);
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();if(!image)__builtin_trap();
    UIGraphicsEndImageContext();
    image=[image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
    // The original replaces its dictionary with this singleton, not an LRU.
    opacityCache=@{@(height):image};return image;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000301F0 ea=0x1000301f0 end=0x1000303b6
double UIColorPickerVisualSliderValue(double value, BOOL rightToLeft) {return rightToLeft?1.0-value:value;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000303F0 ea=0x1000303f0 end=0x100030485
CGPoint UIColorPickerKnobPosition(CGSize size,double value,BOOL rightToLeft) {
    return CGPointMake((size.width-size.height)*UIColorPickerVisualSliderValue(value,rightToLeft)+size.height*.5,size.height*.5);
}
@interface UIColorPickerSliderKnob ()
@property(nonatomic, strong) CALayer *whiteCircle,*colorCircle;
@end
@implementation UIColorPickerSliderKnob
// BINMAP-ADAPT: UIColorPickerSliderKnob.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {if((self=[super initWithFrame:frame])){self.userInteractionEnabled=NO;self.isAccessibilityElement=NO;_selectedColor=UIColor.redColor;[self body];}return self;}
// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_100030440 ea=0x100030440 end=0x10003066f
- (void)body {
    self.whiteCircle=[CALayer layer];
    self.whiteCircle.shadowColor=UIColor.blackColor.CGColor;self.whiteCircle.shadowOpacity=.33;self.whiteCircle.shadowRadius=2;self.whiteCircle.shadowOffset=CGSizeZero;
    [self.layer addSublayer:self.whiteCircle];self.colorCircle=[CALayer layer];[self.whiteCircle addSublayer:self.colorCircle];
}
// BINMAP-ADAPT: UIColorPickerSliderKnob.layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];[CATransaction begin];[CATransaction setDisableActions:YES];
    UIColor *circleBackground=UIColor.whiteColor;if(@available(iOS 13.0,*)){circleBackground=[UIColor.systemBackgroundColor resolvedColorWithTraitCollection:self.traitCollection];}
    self.whiteCircle.backgroundColor=circleBackground.CGColor;
    self.whiteCircle.frame=CGRectInset(self.bounds,2,2);self.whiteCircle.cornerRadius=self.whiteCircle.bounds.size.height*.5;
    self.colorCircle.frame=CGRectInset(self.whiteCircle.bounds,3,3);self.colorCircle.cornerRadius=self.colorCircle.bounds.size.height*.5;self.colorCircle.backgroundColor=self.selectedColor.CGColor;
    [CATransaction commit];
}
// BINMAP-ADAPT: UIColorPickerSliderKnob.traitCollectionDidChange:
- (void)traitCollectionDidChange:(UITraitCollection *)previous {[super traitCollectionDidChange:previous];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerSliderKnob.setSelectedColor:
- (void)setSelectedColor:(UIColor *)selectedColor {_selectedColor=selectedColor;[self setNeedsLayout];}
@end
@implementation UIColorPickerOpacityBackground
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002E8C0 ea=0x10002e8c0 end=0x10002e913
- (UIImage *)body {return self.bounds.size.height>0?UIColorPickerOpacityTile(self.bounds.size.height):nil;}
// BINMAP-ADAPT: UIColorPickerOpacityBackground.layoutSubviews
- (void)layoutSubviews {[super layoutSubviews];self.image=[self body];self.isAccessibilityElement=self.image!=nil;}
@end
@interface UIColorPickerColorSlider ()
@property(nonatomic, strong) UIView *capsule;
@property(nonatomic, strong) UIColorPickerOpacityBackground *checker;
@property(nonatomic, strong) CAGradientLayer *gradient;
@property(nonatomic, strong) UIColorPickerSliderKnob *knob;
@property(nonatomic) CGPoint trackingOrigin;
@property(nonatomic) BOOL acceptsTrackedTouch;
@property(nonatomic, readwrite, getter=isActive) BOOL active;
@property(nonatomic) BOOL performingAnimatedUpdates;
@property(nonatomic) NSUInteger positionAnimationSequence;
@property(nonatomic) CGRect positionAnimationBounds;
@property(nonatomic) UIUserInterfaceLayoutDirection positionAnimationDirection;
@end
@implementation UIColorPickerColorSlider
// BINMAP-ADAPT: UIColorPickerColorSlider.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){_fromColor=UIColor.blackColor;_toColor=UIColor.whiteColor;_selectedColor=UIColor.redColor;_showsOpacityBackground=YES;[self body];}return self;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002EB80 ea=0x10002eb80 end=0x10002ee3c
- (void)body {
    self.isAccessibilityElement=YES;self.accessibilityTraits=UIAccessibilityTraitAdjustable;
    self.capsule=[UIView new];self.capsule.userInteractionEnabled=NO;self.capsule.accessibilityElementsHidden=YES;self.capsule.clipsToBounds=YES;[self addSubview:self.capsule];
    self.checker=[UIColorPickerOpacityBackground new];[self.capsule addSubview:self.checker];
    self.gradient=[CAGradientLayer layer];[self.capsule.layer addSublayer:self.gradient];
    self.knob=[UIColorPickerSliderKnob new];[self addSubview:self.knob];
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002EE60 ea=0x10002ee60 end=0x10002f2f3
- (void)geometryBody:(CGSize)size {[self stackForSize:size];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002F4D0 ea=0x10002f4d0 end=0x10002faf0
- (void)stackForSize:(CGSize)size {
    BOOL rtl=self.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft;
    self.capsule.frame=(CGRect){CGPointZero,size};self.capsule.layer.cornerRadius=size.height*.5;
    self.checker.frame=self.capsule.bounds;self.checker.hidden=!self.showsOpacityBackground;
    self.gradient.frame=self.capsule.bounds;self.gradient.colors=@[(__bridge id)self.fromColor.CGColor,(__bridge id)self.toColor.CGColor];
    // BINNOTE: Original SwiftUI UnitPoint gradient endpoints render in the
    // same physical direction in RTL. Its PositionModifier mirrors a logical
    // position, then SwiftUI position layout mirrors it again. UIKit has no
    // second mapping: preserve the recovered logical helper, convert here.
    self.gradient.startPoint=CGPointMake(0,.5);self.gradient.endPoint=CGPointMake(1,.5);
    self.knob.bounds=CGRectMake(0,0,size.height,size.height);CGPoint position=UIColorPickerKnobPosition(size,self.value,rtl);if(rtl)position.x=size.width-position.x;self.knob.center=position;self.knob.selectedColor=self.selectedColor;
}
// BINMAP-ADAPT: UIColorPickerColorSlider.layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
    if(!CGRectEqualToRect(self.bounds,self.positionAnimationBounds)||self.effectiveUserInterfaceLayoutDirection!=self.positionAnimationDirection)[self cancelPresentationAnimation];
    [CATransaction begin];[CATransaction setDisableActions:YES];[self geometryBody:self.bounds.size];[CATransaction commit];
}
// BINMAP-ADAPT: UIColorPickerColorSlider.animateChangesToSliders:updates: manifest=reimpl/slider_animation_extras.json
+ (void)animateChangesToSliders:(NSArray<UIColorPickerColorSlider *> *)sliders updates:(void (^)(void))updates {
    NSMutableArray *snapshots=[NSMutableArray new];
    for(UIColorPickerColorSlider *slider in sliders){
        [slider.superview layoutIfNeeded];[slider layoutIfNeeded];
        [snapshots addObject:@{@"position":[NSValue valueWithCGPoint:slider.knob.layer.position],@"bounds":[NSValue valueWithCGRect:slider.bounds],@"parent":slider.superview?:NSNull.null,@"window":slider.window?:NSNull.null,@"nested":@(slider.performingAnimatedUpdates)}];
        slider.performingAnimatedUpdates=YES;
    }
    @try{updates();}@finally{for(NSUInteger index=0;index<sliders.count;index++)sliders[index].performingAnimatedUpdates=[snapshots[index][@"nested"]boolValue];}
    for(NSUInteger index=0;index<sliders.count;index++){
        UIColorPickerColorSlider *slider=sliders[index];NSDictionary *snapshot=snapshots[index];
        if([snapshot[@"nested"]boolValue])continue;
        [slider.superview layoutIfNeeded];[slider layoutIfNeeded];[slider.knob layoutIfNeeded];
        BOOL retained=slider.window&&!slider.window.hidden&&slider.window==snapshot[@"window"]&&slider.superview==snapshot[@"parent"]&&CGRectEqualToRect(slider.bounds,[snapshot[@"bounds"] CGRectValue]);
        if(!retained||!UIView.areAnimationsEnabled){[slider cancelPresentationAnimation];continue;}
        CGPoint previous=[snapshot[@"position"] CGPointValue],target=slider.knob.layer.position;
        if(CGPointEqualToPoint(previous,target))continue;
        // The inspected SwiftUI default is .35s easeInOut. Retain earlier
        // additive deltas to reproduce its observed continued motion on retarget.
        // This public adaptation does not call SwiftUI's private blending code.
        CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"position"];
        animation.additive=YES;animation.fromValue=[NSValue valueWithCGPoint:CGPointMake(previous.x-target.x,previous.y-target.y)];animation.toValue=[NSValue valueWithCGPoint:CGPointZero];
        animation.duration=.35;animation.timingFunction=[CAMediaTimingFunction functionWithControlPoints:.42 :0 :.58 :1];
        slider.positionAnimationBounds=slider.bounds;slider.positionAnimationDirection=slider.effectiveUserInterfaceLayoutDirection;
        [slider.knob.layer addAnimation:animation forKey:[NSString stringWithFormat:@"UIColorPicker.position.%lu",(unsigned long)++slider.positionAnimationSequence]];
    }
}
// BINMAP-ADAPT: UIColorPickerColorSlider.cancelPresentationAnimation manifest=reimpl/slider_animation_extras.json
- (void)cancelPresentationAnimation {
    if(self.performingAnimatedUpdates)return;
    for(NSString *key in self.knob.layer.animationKeys)if([key hasPrefix:@"UIColorPicker.position."])[self.knob.layer removeAnimationForKey:key];
}
// BINMAP-ADAPT: UIColorPickerColorSlider.accessibilityActivationPoint
- (CGPoint)accessibilityActivationPoint {
    if(!self.window)return [super accessibilityActivationPoint];
    CGRect frame=UIAccessibilityConvertFrameToScreenCoordinates((CGRect){self.knob.center,CGSizeZero},self);
    CGFloat scale=self.window.screen.scale;return CGPointMake(round(frame.origin.x*scale)/scale,round(frame.origin.y*scale)/scale);
}
// BINMAP-ADAPT: UIColorPickerColorSlider.intrinsicContentSize
- (CGSize)intrinsicContentSize {return CGSizeMake(UIViewNoIntrinsicMetric,36);}
// BINMAP-ADAPT: UIColorPickerColorSlider.setValue:
- (void)setValue:(double)value {[self cancelPresentationAnimation];_value=value;[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerColorSlider.setFromColor:
- (void)setFromColor:(UIColor *)color {[self cancelPresentationAnimation];_fromColor=color;[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerColorSlider.setToColor:
- (void)setToColor:(UIColor *)color {[self cancelPresentationAnimation];_toColor=color;[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerColorSlider.setSelectedColor:
- (void)setSelectedColor:(UIColor *)color {[self cancelPresentationAnimation];_selectedColor=color;[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerColorSlider.setShowsOpacityBackground:
- (void)setShowsOpacityBackground:(BOOL)show {_showsOpacityBackground=show;[self setNeedsLayout];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002FAF0 ea=0x10002faf0 end=0x10002fe62
- (void)dragChangedAtPoint:(CGPoint)point {
    CGFloat width=self.bounds.size.width,height=self.bounds.size.height;
    double x=fmin(point.x,width-height*.5);x=x>=height*.5?x:height*.5;
    os_signpost_interval_begin(UIColorPickerLog(),UIColorPickerSignpostID(),"Update slider value");
    BOOL alreadyActive=self.active;self.active=YES;if(self.activeBinding)self.activeBinding(YES);
    if(!alreadyActive)[self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    double value=(x-height*.5)/(width-height);self.value=fmin(value>=0?value:0,1);
    // BINNOTE: Original drag math has no RTL branch; PositionModifier does.
    // Preserve it rather than silently correcting an unverified native behavior.
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    os_signpost_interval_end(UIColorPickerLog(),UIColorPickerSignpostID(),"Update slider value");
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002FE70 ea=0x10002fe70 end=0x10002ff35
- (void)dragEnded {self.active=NO;if(self.activeBinding)self.activeBinding(NO);[self sendActionsForControlEvents:UIControlEventEditingDidEnd];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002FF40 ea=0x10002ff40 end=0x100030165
- (void)adjustAccessibilityDirection:(NSInteger)direction {
    if(direction==0)self.value=fmin(self.value+.1,1);
    else if(direction==1){double value=self.value-.1;self.value=value>=0?value:0;}
    else return;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
// BINMAP-ADAPT: UIColorPickerColorSlider.beginTrackingWithTouch:withEvent:
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {self.trackingOrigin=[touch locationInView:self];self.acceptsTrackedTouch=self.enabled;return self.acceptsTrackedTouch;}
// BINMAP-ADAPT: UIColorPickerColorSlider.continueTrackingWithTouch:withEvent:
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(!self.acceptsTrackedTouch)return NO;
    CGPoint point=[touch locationInView:self];if(self.active||hypot(point.x-self.trackingOrigin.x,point.y-self.trackingOrigin.y)>=10)[self dragChangedAtPoint:point];return YES;
}
// BINMAP-ADAPT: UIColorPickerColorSlider.endTrackingWithTouch:withEvent:
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {self.acceptsTrackedTouch=NO;if(self.active)[self dragEnded];}
// BINMAP-ADAPT: UIColorPickerColorSlider.cancelTrackingWithEvent:
- (void)cancelTrackingWithEvent:(UIEvent *)event {self.acceptsTrackedTouch=NO;if(self.active)[self dragEnded];[self sendActionsForControlEvents:UIControlEventTouchCancel];}
// BINMAP-ADAPT: UIColorPickerColorSlider.accessibilityIncrement
- (void)accessibilityIncrement {[self adjustAccessibilityDirection:0];}
// BINMAP-ADAPT: UIColorPickerColorSlider.accessibilityDecrement
- (void)accessibilityDecrement {[self adjustAccessibilityDirection:1];}
// BINMAP-ADAPT: UIColorPickerColorSlider.traitCollectionDidChange:
- (void)traitCollectionDidChange:(UITraitCollection *)previous {[super traitCollectionDidChange:previous];[self setNeedsLayout];}
@end
