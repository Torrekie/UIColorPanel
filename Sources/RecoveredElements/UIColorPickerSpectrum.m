#import "UIColorPickerSpectrum+Internal.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPickerColorAccessibility.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

// Keep the reference's separate SSE float operations when compiling for arm64.
#pragma STDC FP_CONTRACT OFF

typedef struct { float r,g,b,a; } UIColorPickerSpectrumRGBA;
static const float UIColorPickerSpectrumHueCurve[4]={.47f,0,.68f,1};
static const float UIColorPickerSpectrumHorizontalCurve[4]={.42f,.1f,.83f,.95f};
// Original 0x100037d40 initializes this immutable pair at runtime.
static const CGSize UIColorPickerSpectrumLensSize={33,33};

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10003C205 ea=0x10003c205 end=0x10003c3d6
static float UIColorPickerSpectrumEvaluateCurve(const float *points,float input) {
    float cx=points[0]*3.0f;
    float bx=(points[2]-points[0])*3.0f-cx;
    float ax=(1.0f-cx)-bx;
    float cy=points[1]*3.0f;
    float by=(points[3]-points[1])*3.0f-cy;
    float ay=(1.0f-cy)-by;
    float parameter=input;
    int iterations=8;
    for(;;){
        float difference=((ax*parameter+bx)*parameter+cx)*parameter-input;
        if(fabsf(difference)<.00001f)break;
        float derivative=((3.0f*ax)*parameter+(bx+bx))*parameter+cx;
        if(!(fabs((double)derivative)<.000001)){
            parameter-=difference/derivative;
            if(--iterations!=0)continue;
        }
        parameter=0;
        if(!(input<0)){
            parameter=1;
            if(!(input>1)){
                float lower=0,upper=1;
                int remaining=1023;
                parameter=input;
                do{
                    float error=((ax*parameter+bx)*parameter+cx)*parameter-input;
                    if(fabsf(error)<.00001f)break;
                    if(error<0)lower=parameter;
                    else upper=parameter;
                    parameter=(float)((double)lower+(double)(upper-lower)*.5);
                    if(remaining<=0)break;
                    if(upper>lower)--remaining;
                }while(upper>lower);
            }
        }
        break;
    }
    return ((ay*parameter+by)*parameter+cy)*parameter;
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10003C3D6 ea=0x10003c3d6 end=0x10003c5a7
static float UIColorPickerSpectrumInvertCurve(const float *points,float input) {
    float cx=points[0]*3.0f;
    float bx=(points[2]-points[0])*3.0f-cx;
    float ax=(1.0f-cx)-bx;
    float cy=points[1]*3.0f;
    float by=(points[3]-points[1])*3.0f-cy;
    float ay=(1.0f-cy)-by;
    float parameter=input;
    int iterations=8;
    for(;;){
        float difference=((ay*parameter+by)*parameter+cy)*parameter-input;
        if(fabsf(difference)<.00001f)break;
        float derivative=((3.0f*ay)*parameter+(by+by))*parameter+cy;
        if(!(fabs((double)derivative)<.000001)){
            parameter-=difference/derivative;
            if(--iterations!=0)continue;
        }
        parameter=0;
        if(!(input<0)){
            parameter=1;
            if(!(input>1)){
                float lower=0,upper=1;
                int remaining=1023;
                parameter=input;
                do{
                    float error=((ay*parameter+by)*parameter+cy)*parameter-input;
                    if(fabsf(error)<.00001f)break;
                    if(error<0)lower=parameter;
                    else upper=parameter;
                    parameter=(float)((double)lower+(double)(upper-lower)*.5);
                    if(remaining<=0)break;
                    if(upper>lower)--remaining;
                }while(upper>lower);
            }
        }
        break;
    }
    return ((ax*parameter+bx)*parameter+cx)*parameter;
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10003C5A7 ea=0x10003c5a7 end=0x10003c75f
static UIColorPickerSpectrumRGBA UIColorPickerSpectrumHueColor(float y) {
    float hue=(float)(.5-(double)y*.5);
    if(hue<.16666667f){
        float component=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHueCurve,hue*6.0f);
        return (UIColorPickerSpectrumRGBA){1,component,0,1};
    }
    double value=hue;
    if(hue<.33333334f){
        float component=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHueCurve,(float)(1.0-(value*6.0+-1.0)));
        return (UIColorPickerSpectrumRGBA){component,1,0,1};
    }
    if(value<.5000000149011612){
        float component=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHueCurve,(float)(value*6.0+-2.0));
        return (UIColorPickerSpectrumRGBA){0,1,component,1};
    }
    if(hue<.6666667f){
        float component=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHueCurve,(float)(1.0-(value*6.0+-3.0)));
        return (UIColorPickerSpectrumRGBA){0,component,1,1};
    }
    if(value<.833333358168602){
        float component=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHueCurve,(float)(value*6.0+-4.0));
        return (UIColorPickerSpectrumRGBA){component,0,1,1};
    }
    float component=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHueCurve,(float)(1.0-(value*6.0+-5.0)));
    return (UIColorPickerSpectrumRGBA){1,0,(float)fmax((double)component,1.0/255.0),1};
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10003C75F ea=0x10003c75f end=0x10003c83e
static float UIColorPickerSpectrumHue(UIColorPickerSpectrumRGBA color) {
    float hue;
    // ucomiss/jb includes unordered operands, unlike an ordered < comparison.
    if(!(color.r>=color.g)||!(color.r>=color.b)){
        if(!(color.g>=color.r)||!(color.g>=color.b)){
            hue=0;
            if(!(color.b>=color.r)||!(color.b>=color.g))return hue*60.0f;
            float minimum=isnan(color.r)?color.g:fminf(color.g,color.r);
            hue=(color.r-color.g)/(color.b-minimum)+4.0f;
        }else{
            float minimum=isnan(color.r)?color.b:fminf(color.b,color.r);
            hue=(color.b-color.r)/(color.g-minimum)+2.0f;
        }
    }else{
        float minimum=isnan(color.g)?color.b:fminf(color.b,color.g);
        hue=(color.g-color.b)/(color.r-minimum);
    }
    for(;hue<0;hue+=6.0f){}
    return hue*60.0f;
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10003C83E ea=0x10003c83e end=0x10003c8ec
static float UIColorPickerSpectrumHuePosition(UIColorPickerSpectrumRGBA color) {
    float target=UIColorPickerSpectrumHue(color);
    float step=.5f,y=0;
    int iterations=100;
    for(;;){
        float hue=UIColorPickerSpectrumHue(UIColorPickerSpectrumHueColor(y));
        if(fabsf(target-hue)<.001f)break;
        y+=(target<hue)?step:-step;
        step*=.5f;
        if(--iterations==0)return y;
    }
    return y;
}

@interface UIColorPickerSpectrumRenderer : NSObject
+ (UIColor *)colorAtLocation:(CGPoint)location;
+ (CGPoint)positionForColor:(UIColorPickerSpectrumRGBA)color;
@end

@implementation UIColorPickerSpectrumRenderer
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=+[SpectrumRenderer colorAtLocation:] ea=0x10003c8ec end=0x10003ca62
+ (UIColor *)colorAtLocation:(CGPoint)location {
    float x=(float)location.x;
    UIColorPickerSpectrumRGBA color=UIColorPickerSpectrumHueColor((float)location.y);
    float maximum=isnan(color.r)?color.g:fmaxf(color.g,color.r);
    maximum=isnan(maximum)?color.b:fmaxf(color.b,maximum);
    float amount;
    if(!(x<0)){
        amount=(1.0f-UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHorizontalCurve,fabsf(x)))/maximum;
        color.r*=amount;color.g*=amount;color.b*=amount;
    }else{
        amount=UIColorPickerSpectrumEvaluateCurve(UIColorPickerSpectrumHorizontalCurve,1.0f-fabsf(x));
        color.r=(color.r-maximum)*amount+maximum;
        color.g=(color.g-maximum)*amount+maximum;
        color.b=(color.b-maximum)*amount+maximum;
    }
    return [UIColor colorWithRed:color.r green:color.g blue:color.b alpha:color.a];
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=+[SpectrumRenderer positionForColor:] ea=0x10003ca62 end=0x10003cbf4
+ (CGPoint)positionForColor:(UIColorPickerSpectrumRGBA)color {
    // The original float4 is in xmm0; IDA's inferred ObjC prototype drops it.
    float maximum=isnan(color.g)?color.b:fmaxf(color.b,color.g);
    maximum=isnan(color.r)?maximum:fmaxf(maximum,color.r);
    float x,y;
    if(maximum<1){
        float amount=1.0f/maximum;
        UIColorPickerSpectrumRGBA normalized={amount*color.r,amount*color.g,amount*color.b,color.a};
        y=UIColorPickerSpectrumHuePosition(normalized);
        x=UIColorPickerSpectrumInvertCurve(UIColorPickerSpectrumHorizontalCurve,1.0f-maximum);
    }else{
        float minimum=isnan(color.g)?color.b:fminf(color.b,color.g);
        minimum=isnan(color.r)?minimum:fminf(minimum,color.r);
        float shiftedMinimum=minimum+-1.0f;
        float amount=-shiftedMinimum;
        x=UIColorPickerSpectrumInvertCurve(UIColorPickerSpectrumHorizontalCurve,amount)+-1.0f;
        // The second +1 is present in 0x10003cb80..0x10003cbaf. Preserve it:
        // hue is invariant under this common translation and positive scale.
        UIColorPickerSpectrumRGBA normalized={
            (float)(((double)(color.r-shiftedMinimum)+1.0)/(double)amount),
            (float)(((double)(color.g-shiftedMinimum)+1.0)/(double)amount),
            (float)(((double)(color.b-shiftedMinimum)+1.0)/(double)amount),color.a};
        y=UIColorPickerSpectrumHuePosition(normalized);
    }
    return CGPointMake(x,y);
}
@end

@interface UIColorPickerSpectrumLens ()
- (void)body;
@end

@implementation UIColorPickerSpectrumLens
// BINMAP-ADAPT: UIColorPickerSpectrumLens.init manifest=reimpl/spectrum_api_manifest.json
- (instancetype)init {
    if((self=[super init]))[self body];
    return self;
}

// BINMAP-ADAPT: UIColorPickerSpectrumLens.initWithLayer: manifest=reimpl/spectrum_api_manifest.json
- (instancetype)initWithLayer:(id)layer {
    if((self=[super initWithLayer:layer]))_selectedColor=[(UIColorPickerSpectrumLens *)layer selectedColor];
    return self;
}

// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_100039AC0 ea=0x100039ac0 end=0x100039cb6
- (void)body {
    // The two fills independently retain alpha; only the outer circle has a shadow.
    self.bounds=(CGRect){CGPointZero,UIColorPickerSpectrumLensSize};
    CALayer *background=[CALayer layer];
    background.frame=self.bounds;
    background.backgroundColor=self.selectedColor.CGColor;
    background.cornerRadius=UIColorPickerSpectrumLensSize.height*.5;
    background.shadowColor=UIColor.blackColor.CGColor;
    background.shadowOpacity=.33;background.shadowRadius=2;background.shadowOffset=CGSizeZero;
    CALayer *color=[CALayer layer];
    color.frame=CGRectInset(self.bounds,3,3);
    color.cornerRadius=color.bounds.size.height*.5;
    color.backgroundColor=self.selectedColor.CGColor;
    [self addSublayer:background];
    [self addSublayer:color];
}

// BINMAP-ADAPT: UIColorPickerSpectrumLens.setSelectedColor: manifest=reimpl/spectrum_api_manifest.json
- (void)setSelectedColor:(UIColorValue *)selectedColor {
    _selectedColor=selectedColor;
    [CATransaction begin];[CATransaction setDisableActions:YES];
    self.sublayers.firstObject.backgroundColor=selectedColor.CGColor;
    self.sublayers.lastObject.backgroundColor=selectedColor.CGColor;
    [CATransaction commit];
}
@end

@interface UIColorPickerSpectrum ()
@property(nonatomic, strong, readwrite) UIColorValue *sampledColor;
@property(nonatomic, readwrite, getter=isActive) BOOL active;
@property(nonatomic, readwrite) BOOL editingCancelled;
@property(nonatomic) CGPoint trackingLocation;
@property(nonatomic, strong) UIColorPickerSpectrumLens *lensLayer;
- (UIColor *)colorAtLocation:(CGPoint)location inSize:(CGSize)size;
- (NSValue *)positionForColor:(UIColorValue *)color inSize:(CGSize)size;
- (NSValue *)selectionPosition;
- (void)updateSelectionAtLocation:(CGPoint)location;
- (UIColorPickerSpectrumLens *)makeLens;
@end

@implementation UIColorPickerSpectrum
// BINMAP-ADAPT: UIColorPickerSpectrum.initWithFrame: manifest=reimpl/spectrum_api_manifest.json
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        _selectedColor=[[UIColorValue alloc]initWithCGColor:UIColor.redColor.CGColor];
        _sampledColor=_selectedColor;
        self.opaque=NO;self.contentMode=UIViewContentModeRedraw;
        self.isAccessibilityElement=YES;
        self.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Color Spectrum"];
        self.accessibilityTraits=UIAccessibilityTraitAllowsDirectInteraction;
        _lensLayer=[self makeLens];[self.layer addSublayer:_lensLayer];
    }
    return self;
}

// BINMAP-ADAPT: UIColorPickerSpectrum.initWithCoder: manifest=reimpl/spectrum_api_manifest.json
- (instancetype)initWithCoder:(NSCoder *)coder {
    if((self=[super initWithCoder:coder])){
        _selectedColor=[[UIColorValue alloc]initWithCGColor:UIColor.redColor.CGColor];
        _sampledColor=_selectedColor;
        self.opaque=NO;self.contentMode=UIViewContentModeRedraw;
        self.isAccessibilityElement=YES;
        self.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Color Spectrum"];
        self.accessibilityTraits=UIAccessibilityTraitAllowsDirectInteraction;
        _lensLayer=[self makeLens];[self.layer addSublayer:_lensLayer];
    }
    return self;
}

// BINMAP-ADAPT: UIColorPickerSpectrum.setSelectedColor: manifest=reimpl/spectrum_api_manifest.json
- (void)setSelectedColor:(UIColorValue *)color {
    _selectedColor=color;_sampledColor=color;
    // Canonical values, including extended components/profile, remain intact.
    [self setNeedsLayout];
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000113D0 ea=0x1000113d0 end=0x100011454
- (UIColor *)colorAtLocation:(CGPoint)location inSize:(CGSize)size {
    double x=fmax(fmin(location.x/size.width+location.x/size.width+-1.0,1.0),-1.0);
    double y=fmax(fmin(-(location.y/size.height+location.y/size.height+-1.0),1.0),-1.0);
    return [UIColorPickerSpectrumRenderer colorAtLocation:CGPointMake(x,y)];
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100011460 ea=0x100011460 end=0x100011d96
- (NSValue *)positionForColor:(UIColorValue *)color inSize:(CGSize)size {
    // SomeColor's conversion is replaced by the component's canonical bridge;
    // it supplies RGB without changing the original selectedColor.
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGFloat components[4];
    BOOL converted=[color getRGBComponents:components inColorSpace:space error:NULL];
    CGColorSpaceRelease(space);
    if(!converted)return nil;
    NSUInteger black=0,white=0;
    for(NSUInteger index=0;index<3;index++){
        if(components[index]<.001)black++;
        if(components[index]>.999)white++;
    }
    if((black==0&&white==0)||black==3||white==3)return nil;
    UIColorPickerSpectrumRGBA rgba={(float)components[0],(float)components[1],(float)components[2],(float)components[3]};
    CGPoint position=[UIColorPickerSpectrumRenderer positionForColor:rgba];
    return [NSValue valueWithCGPoint:CGPointMake((position.x+1.0)*.5*size.width,size.height-(position.y+1.0)*.5*size.height)];
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100036BB0 ea=0x100036bb0 end=0x100036d2e
- (NSValue *)selectionPosition {
    // GestureState<DragGesture.Value?> becomes UIControl's active sample;
    // the idle Binding<SomeColor> branch keeps its optional inverse position.
    if(self.active)return [NSValue valueWithCGPoint:self.trackingLocation];
    return [self positionForColor:self.selectedColor inSize:self.bounds.size];
}

// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_100038590 ea=0x100038590 end=0x100038981
- (void)updateSelectionAtLocation:(CGPoint)location {
    self.trackingLocation=location;
    UIColor *opaque=[self colorAtLocation:location inSize:self.bounds.size];
    CGColorSpaceRef space=CGColorGetColorSpace(self.selectedColor.CGColor);
    CGColorRef converted=CGColorCreateCopyByMatchingToColorSpace(space,kCGRenderingIntentPerceptual,opaque.CGColor,NULL);
    // Original15.5 converts to the current sRGB/P3 profile before replacing
    // alpha. As in Grid, other compatible ICC/model spaces use public CG
    // transport; failed conversions leave the current selection unchanged.
    if(!converted)return;
    CGColorRef candidate=CGColorCreateCopyWithAlpha(converted,CGColorGetAlpha(self.selectedColor.CGColor));
    CGColorRelease(converted);
    UIColorValue *sample=[[UIColorValue alloc]initWithCGColor:candidate];
    CGColorRelease(candidate);
    BOOL changed=![sample isEqual:self.selectedColor];
    self.sampledColor=sample;
    if(changed)UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,self.accessibilityValue);
    // The host target/action replaces Binding.wrappedValue.setter, after the
    // original's announcement. The host applies the candidate and ICC policy.
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self setNeedsLayout];
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100037D90 ea=0x100037d90 end=0x100037f4e
- (UIColorPickerSpectrumLens *)makeLens {
    UIColorPickerSpectrumLens *lens=[UIColorPickerSpectrumLens new];
    lens.selectedColor=self.selectedColor;
    lens.bounds=(CGRect){CGPointZero,UIColorPickerSpectrumLensSize};
    return lens;
}

// BINMAP-ADAPT: UIColorPickerSpectrum.layoutSubviews manifest=reimpl/spectrum_api_manifest.json
- (void)layoutSubviews {
    [super layoutSubviews];
    NSValue *position=[self selectionPosition];
    [CATransaction begin];[CATransaction setDisableActions:YES];
    self.lensLayer.hidden=position==nil;
    if(position){
        CGPoint point=position.CGPointValue;
        point.x=fmin(self.bounds.size.width,fmax(0,point.x))+self.bounds.origin.x;
        point.y=fmin(self.bounds.size.height,fmax(0,point.y))+self.bounds.origin.y;
        self.lensLayer.position=point;
    }
    self.lensLayer.selectedColor=self.selectedColor;
    [CATransaction commit];
}

// BINMAP-ADAPT: UIColorPickerSpectrum.drawRect: manifest=reimpl/spectrum_api_manifest.json
- (void)drawRect:(CGRect)rect {
    CGSize size=self.bounds.size;
    if(size.width<=0||size.height<=0)return;
    CGFloat scale=self.contentScaleFactor;
    size_t width=(size_t)ceil(size.width*scale),height=(size_t)ceil(size.height*scale);
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef bitmap=CGBitmapContextCreate(NULL,width,height,8,width*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if(!bitmap)return;
    unsigned char *pixels=CGBitmapContextGetData(bitmap);
    // BINNOTE: The public bitmap adapter uses pixel-center samples. Original
    // Metal texture dispatch/raster edge coverage is not reconstructed here.
    for(size_t y=0;y<height;y++){@autoreleasepool{
        for(size_t x=0;x<width;x++){
            CGPoint location=CGPointMake(((double)x+.5)/(double)width*size.width,((double)y+.5)/(double)height*size.height);
            UIColor *color=[self colorAtLocation:location inSize:size];
            CGFloat red,green,blue,alpha;
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            size_t offset=(y*width+x)*4;
            pixels[offset]=(unsigned char)lround(red*255.0);
            pixels[offset+1]=(unsigned char)lround(green*255.0);
            pixels[offset+2]=(unsigned char)lround(blue*255.0);
            pixels[offset+3]=255;
        }
    }}
    CGImageRef image=CGBitmapContextCreateImage(bitmap);
    CGContextRelease(bitmap);
    if(!image)return;
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    // SwiftUI's circular clip meets each edge exactly 8 pt from the corner.
    CGPathRef clip=CGPathCreateWithRoundedRect(self.bounds,8,8,NULL);
    CGContextAddPath(context,clip);
    CGContextClip(context);
    CGPathRelease(clip);
    [[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]drawInRect:self.bounds];
    CGContextRestoreGState(context);
    CGImageRelease(image);
}

// BINMAP-ADAPT: UIColorPickerSpectrum.beginTrackingWithTouch:withEvent: manifest=reimpl/spectrum_api_manifest.json
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(!self.enabled||self.bounds.size.width<=0||self.bounds.size.height<=0)return NO;
    _editingCancelled=NO;_active=YES;
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if(!self.active)return NO;
    CGPoint point=[touch locationInView:self];
    [self updateSelectionAtLocation:CGPointMake(point.x-self.bounds.origin.x,point.y-self.bounds.origin.y)];
    return self.active;
}

// BINMAP-ADAPT: UIColorPickerSpectrum.continueTrackingWithTouch:withEvent: manifest=reimpl/spectrum_api_manifest.json
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(!self.active)return NO;
    CGPoint point=[touch locationInView:self];
    [self updateSelectionAtLocation:CGPointMake(point.x-self.bounds.origin.x,point.y-self.bounds.origin.y)];
    return self.active;
}

// BINMAP-ADAPT: UIColorPickerSpectrum.endTrackingWithTouch:withEvent: manifest=reimpl/spectrum_api_manifest.json
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(!self.active)return;
    // Original onEnded closure 0x100037b50 only clears active state.
    _active=NO;_editingCancelled=NO;
    [self setNeedsLayout];
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
}

// BINMAP-ADAPT: UIColorPickerSpectrum.cancelTrackingWithEvent: manifest=reimpl/spectrum_api_manifest.json
- (void)cancelTrackingWithEvent:(UIEvent *)event {
    if(!self.active)return;
    _active=NO;_editingCancelled=YES;
    [self setNeedsLayout];
    [self sendActionsForControlEvents:UIControlEventTouchCancel];
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
}

// BINMAP-ADAPT: UIColorPickerSpectrum.setEnabled: manifest=reimpl/spectrum_api_manifest.json
- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if(!enabled&&self.active)[self cancelTrackingWithEvent:nil];
}

// BINMAP-ADAPT: UIColorPickerSpectrum.willMoveToWindow: manifest=reimpl/spectrum_api_manifest.json
- (void)willMoveToWindow:(UIWindow *)window {
    if(!window&&self.active)[self cancelTrackingWithEvent:nil];
    [super willMoveToWindow:window];
}

// BINMAP-ADAPT: UIColorPickerSpectrum.accessibilityFrame manifest=reimpl/spectrum_api_manifest.json
- (CGRect)accessibilityFrame {
    if(!self.window)return [super accessibilityFrame];
    CGRect bounds=self.bounds;
    if(!self.lensLayer.hidden)bounds=CGRectUnion(bounds,self.lensLayer.frame);
    CGRect frame=UIAccessibilityConvertFrameToScreenCoordinates(bounds,self);
    CGFloat scale=self.window.screen.scale;
    CGFloat left=floor(CGRectGetMinX(frame)*scale)/scale,top=floor(CGRectGetMinY(frame)*scale)/scale;
    return CGRectMake(left,top,ceil(CGRectGetMaxX(frame)*scale)/scale-left,ceil(CGRectGetMaxY(frame)*scale)/scale-top);
}

// BINMAP-ADAPT: UIColorPickerSpectrum.accessibilityActivationPoint manifest=reimpl/spectrum_api_manifest.json
- (CGPoint)accessibilityActivationPoint {
    if(!self.window)return [super accessibilityActivationPoint];
    CGRect frame=UIAccessibilityConvertFrameToScreenCoordinates(self.bounds,self);
    CGFloat scale=self.window.screen.scale;
    return CGPointMake(round(CGRectGetMidX(frame)*scale)/scale,round(CGRectGetMidY(frame)*scale)/scale);
}

// BINMAP-ADAPT: UIColorPickerSpectrum.accessibilityValue manifest=reimpl/spectrum_api_manifest.json
- (NSString *)accessibilityValue {
    UIColorValue *color=self.active?self.sampledColor:self.selectedColor;
    return UIColorPickerAXColorStringForColor(color.UIColor,1);
}

// BINMAP-ADAPT: UIColorPickerSpectrum.traitCollectionDidChange: manifest=reimpl/spectrum_api_manifest.json
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    [self setNeedsLayout];
}
@end
