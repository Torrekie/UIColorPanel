#import "UIColorPanelTypes.h"
#import "UIColorPanelAppearance.h"
#import "UIColorSurface.h"
#import "UIWheelGeometry.h"
#import "UIColorValue+SwatchDrawing.h"
#import "RecoveredElements/UIColorPickerSpectrum+Internal.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface UIColorPickerWheelView ()
@property(nonatomic) BOOL acceptsTrackedTouch;
@property(nonatomic, strong) UIColorPickerSpectrumLens *lensLayer;
@end

@implementation UIColorPickerWheelView
// BINMAP-ADAPT: UIColorPickerWheelView.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _brightness = 1; self.backgroundColor = UIColor.clearColor;self.contentMode=UIViewContentModeRedraw;
        _lensLayer=[UIColorPickerSpectrumLens new];_lensLayer.hidden=YES;[self.layer addSublayer:_lensLayer];
        self.isAccessibilityElement = YES; self.accessibilityLabel = [UIColorPanelAppearance localizedString:@"Color wheel"];
        self.accessibilityTraits = UIAccessibilityTraitAdjustable;
        self.accessibilityHint = [UIColorPanelAppearance localizedString:@"Adjusts hue. Use hue and saturation sliders for precise values."];
    } return self;
}
// BINMAP-ADAPT: UIColorPickerWheelView.setColorValue: manifest=reimpl/spectrum_api_manifest.json
- (void)setColorValue:(UIColorValue *)colorValue {_colorValue=colorValue;[self setNeedsLayout];[self setNeedsDisplay];}
// BINMAP-ADAPT: UIColorPickerWheelView.layoutSubviews manifest=reimpl/spectrum_api_manifest.json
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat size=MIN(self.bounds.size.width,self.bounds.size.height);
    [CATransaction begin];[CATransaction setDisableActions:YES];
    self.lensLayer.hidden=!self.colorValue||size<=0;
    if(!self.lensLayer.hidden){
        CGRect circle=CGRectMake(CGRectGetMidX(self.bounds)-size*.5,CGRectGetMidY(self.bounds)-size*.5,size,size);
        UIWheelGeometry *geometry=[UIWheelGeometry new];geometry.bounds=CGRectMake(0,0,size,size);geometry.brightness=self.brightness;geometry.alpha=CGColorGetAlpha(self.colorValue.CGColor);geometry.colorSpace=CGColorGetColorSpace(self.colorValue.CGColor);
        CGPoint original=[geometry _pointFromColor:self.colorValue];
        self.lensLayer.position=CGPointMake(CGRectGetMinX(circle)+original.x,CGRectGetMaxY(circle)-original.y);
        self.lensLayer.selectedColor=self.colorValue;
    }
    [CATransaction commit];
}
// BINMAP-ADAPT: UIColorPickerWheelView.drawRect:
- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    CGRect circle = CGRectMake(CGRectGetMidX(self.bounds)-size*.5,CGRectGetMidY(self.bounds)-size*.5,size,size);
    // UIKit raster bridge for the native wheel drawing service; geometry uses full native bounds.
    size_t n = MAX(1, (size_t)ceil(size * self.contentScaleFactor));
    float *pixels = calloc(n*n*4,sizeof(float));
    for (size_t y=0;y<n;y++) for (size_t x=0;x<n;x++) {
        double dx = (2.0*x+1)/n-1, dy = (2.0*y+1)/n-1, s=hypot(dx,dy);
        if (s>1) continue;
        double h=atan2(-dy,dx)/(2*M_PI); if(h<0) h+=1;
        s=MIN(1,s*size/(size-4));
        double sector=h*6, chroma=self.brightness*s, secondary=chroma*(1-fabs(fmod(sector,2)-1));
        double r=0,g=0,b=0,m=self.brightness-chroma;
        switch((int)sector%6){case 0:r=chroma;g=secondary;break;case 1:r=secondary;g=chroma;break;case 2:g=chroma;b=secondary;break;case 3:g=secondary;b=chroma;break;case 4:r=secondary;b=chroma;break;case 5:r=chroma;b=secondary;break;}
        size_t i=(y*n+x)*4; pixels[i]=r+m;pixels[i+1]=g+m;pixels[i+2]=b+m;pixels[i+3]=1;
    }
    CGColorSpaceRef space=self.colorValue?CGColorSpaceRetain(CGColorGetColorSpace(self.colorValue.CGColor)):CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    // Extended RGB profiles require floating components; RGBA8 silently produced an empty disk.
    CGContextRef bitmap=CGBitmapContextCreate(pixels,n,n,32,n*4*sizeof(float),space,kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents|kCGBitmapByteOrder32Little);
    CGImageRef disk=CGBitmapContextCreateImage(bitmap);
    CGContextSaveGState(c); CGContextTranslateCTM(c,0,CGRectGetMaxY(circle)+CGRectGetMinY(circle)); CGContextScaleCTM(c,1,-1); CGContextDrawImage(c,circle,disk); CGContextRestoreGState(c);
    CGImageRelease(disk);CGContextRelease(bitmap);CGColorSpaceRelease(space);free(pixels);
    [[UIColor colorWithWhite:0.55 alpha:0.7] setStroke]; UIBezierPath *edge=[UIBezierPath bezierPathWithOvalInRect:circle];[edge stroke];
    self.accessibilityValue=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Hue %@ degrees, saturation %@ percent"],[UIColorPanelAppearance formatNumber:self.hue*360 significantDigits:0],[UIColorPanelAppearance formatNumber:self.saturation*100 significantDigits:0]];
}
// BINMAP-ADAPT: UIColorPickerWheelView.updateTouch:
- (BOOL)updateTouch:(UITouch *)touch {
    CGPoint p=[touch locationInView:self];CGFloat size=MIN(self.bounds.size.width,self.bounds.size.height);
    CGRect circle=CGRectMake(CGRectGetMidX(self.bounds)-size*.5,CGRectGetMidY(self.bounds)-size*.5,size,size);
    UIWheelGeometry *geometry=[UIWheelGeometry new];geometry.bounds=CGRectMake(0,0,size,size);geometry.brightness=self.brightness;
    geometry.alpha=CGColorGetAlpha(self.colorValue.CGColor);geometry.colorSpace=CGColorGetColorSpace(self.colorValue.CGColor);
    self.colorValue=[geometry _brightColorFromPoint:CGPointMake(p.x-circle.origin.x,CGRectGetMaxY(circle)-p.y) fullBrightness:NO];
    [self setNeedsDisplay];[self sendActionsForControlEvents:UIControlEventValueChanged];return YES;
}
// BINMAP-ADAPT: UIColorPickerWheelView.beginTrackingWithTouch:withEvent:
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event { self.acceptsTrackedTouch=YES;[self sendActionsForControlEvents:UIControlEventEditingDidBegin];return [self updateTouch:touch]; }
// BINMAP-ADAPT: UIColorPickerWheelView.continueTrackingWithTouch:withEvent:
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event { return self.acceptsTrackedTouch?[self updateTouch:touch]:NO; }
// BINMAP-ADAPT: UIColorPickerWheelView.endTrackingWithTouch:withEvent:
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {self.acceptsTrackedTouch=NO;}
// BINMAP-ADAPT: UIColorPickerWheelView.cancelTrackingWithEvent:
- (void)cancelTrackingWithEvent:(UIEvent *)event {self.acceptsTrackedTouch=NO;}
// BINMAP-ADAPT: UIColorPickerWheelView.accessibilityIncrement
- (void)accessibilityIncrement {
    self.hue=fmod(self.hue+1.0/36,1);
    CGFloat size=MIN(self.bounds.size.width,self.bounds.size.height),center=floor(size/2);
    UIWheelGeometry *geometry=[UIWheelGeometry new];geometry.bounds=CGRectMake(0,0,size,size);geometry.brightness=self.brightness;geometry.alpha=CGColorGetAlpha(self.colorValue.CGColor);geometry.colorSpace=CGColorGetColorSpace(self.colorValue.CGColor);
    self.colorValue=[geometry _brightColorFromPoint:CGPointMake(center+cos(self.hue*M_PI*2)*(center-2)*self.saturation,center+sin(self.hue*M_PI*2)*(center-2)*self.saturation) fullBrightness:NO];
    [self setNeedsDisplay];[self sendActionsForControlEvents:UIControlEventValueChanged];
}
// BINMAP-ADAPT: UIColorPickerWheelView.accessibilityDecrement
- (void)accessibilityDecrement {
    self.hue=fmod(self.hue+35.0/36,1);
    CGFloat size=MIN(self.bounds.size.width,self.bounds.size.height),center=floor(size/2);
    UIWheelGeometry *geometry=[UIWheelGeometry new];geometry.bounds=CGRectMake(0,0,size,size);geometry.brightness=self.brightness;geometry.alpha=CGColorGetAlpha(self.colorValue.CGColor);geometry.colorSpace=CGColorGetColorSpace(self.colorValue.CGColor);
    self.colorValue=[geometry _brightColorFromPoint:CGPointMake(center+cos(self.hue*M_PI*2)*(center-2)*self.saturation,center+sin(self.hue*M_PI*2)*(center-2)*self.saturation) fullBrightness:NO];
    [self setNeedsDisplay];[self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end

@interface UIColorPickerUserView ()
@property(nonatomic) BOOL acceptsTrackedTouch;
@property(nonatomic) CGPoint normalizedSamplePoint;
@property(nonatomic, strong) UIColorPickerSpectrumLens *lensLayer;
- (BOOL)sampleAtPoint:(CGPoint)point beginEditing:(BOOL)beginEditing;
@end

@implementation UIColorPickerUserView
// BINMAP-ADAPT: UIColorPickerUserView.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        self.backgroundColor=[UIColor colorWithWhite:0.12 alpha:1];self.isAccessibilityElement=YES;self.accessibilityTraits=UIAccessibilityTraitButton;
        self.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Image sampler"];self.accessibilityValue=[UIColorPanelAppearance localizedString:@"No pixel selected"];self.accessibilityHint=[UIColorPanelAppearance localizedString:@"Activate to select the center pixel. Use actions to move five image pixels."];
        NSMutableArray *actions=[NSMutableArray array];
        for(NSString *name in @[@"Move left",@"Move right",@"Move up",@"Move down"])[actions addObject:[[UIAccessibilityCustomAction alloc]initWithName:[UIColorPanelAppearance localizedString:name] target:self selector:@selector(accessibilityMove:)]];
        self.accessibilityCustomActions=actions;_normalizedSamplePoint=CGPointMake(-1,-1);self.layer.needsDisplayOnBoundsChange=YES;
        _lensLayer=[UIColorPickerSpectrumLens new];_lensLayer.hidden=YES;[self.layer addSublayer:_lensLayer];
    }return self;
}
// BINMAP-ADAPT: UIColorPickerUserView.setImage:
- (void)setImage:(UIImage *)image {_image=image;_normalizedSamplePoint=CGPointMake(-1,-1);_sampledColor=nil;self.accessibilityValue=[UIColorPanelAppearance localizedString:image?@"No pixel selected":@"No image selected"];[self setNeedsDisplay];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerUserView.setSelectedColor: manifest=reimpl/spectrum_api_manifest.json
- (void)setSelectedColor:(UIColorValue *)selectedColor {_selectedColor=selectedColor;[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerUserView.setContentMode: manifest=reimpl/spectrum_api_manifest.json
- (void)setContentMode:(UIViewContentMode)contentMode {[super setContentMode:contentMode];self.layer.needsDisplayOnBoundsChange=YES;[self setNeedsDisplay];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerUserView.setSamplePoint: manifest=reimpl/spectrum_api_manifest.json
- (void)setSamplePoint:(CGPoint)samplePoint {
    if(samplePoint.x<0||!isfinite(samplePoint.x)||!isfinite(samplePoint.y)||self.image.size.width<=0||self.image.size.height<=0||self.bounds.size.width<=0||self.bounds.size.height<=0){
        _normalizedSamplePoint=CGPointMake(-1,-1);
    }else{
        CGFloat scale=MIN(self.bounds.size.width/self.image.size.width,self.bounds.size.height/self.image.size.height);
        CGRect display=self.contentMode==UIViewContentModeScaleToFill?self.bounds:CGRectMake(CGRectGetMidX(self.bounds)-self.image.size.width*scale*.5,CGRectGetMidY(self.bounds)-self.image.size.height*scale*.5,self.image.size.width*scale,self.image.size.height*scale);
        _normalizedSamplePoint=CGPointMake((samplePoint.x-display.origin.x)/display.size.width,(samplePoint.y-display.origin.y)/display.size.height);
    }
    [self setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPickerUserView.samplePoint manifest=reimpl/spectrum_api_manifest.json
- (CGPoint)samplePoint {
    if(self.normalizedSamplePoint.x<0||self.image.size.width<=0||self.image.size.height<=0||self.bounds.size.width<=0||self.bounds.size.height<=0)return CGPointMake(-1,-1);
    CGFloat scale=MIN(self.bounds.size.width/self.image.size.width,self.bounds.size.height/self.image.size.height);
    CGRect display=self.contentMode==UIViewContentModeScaleToFill?self.bounds:CGRectMake(CGRectGetMidX(self.bounds)-self.image.size.width*scale*.5,CGRectGetMidY(self.bounds)-self.image.size.height*scale*.5,self.image.size.width*scale,self.image.size.height*scale);
    return CGPointMake(display.origin.x+self.normalizedSamplePoint.x*display.size.width,display.origin.y+self.normalizedSamplePoint.y*display.size.height);
}
// BINMAP-ADAPT: UIColorPickerUserView.layoutSubviews manifest=reimpl/spectrum_api_manifest.json
- (void)layoutSubviews {
    [super layoutSubviews];CGPoint point=self.samplePoint;
    UIColorValue *color=self.selectedColor?:self.sampledColor;
    [CATransaction begin];[CATransaction setDisableActions:YES];
    self.lensLayer.hidden=point.x<0||!color;
    if(!self.lensLayer.hidden){self.lensLayer.position=point;self.lensLayer.selectedColor=color;}
    [CATransaction commit];
}
// BINMAP-ADAPT: UIColorPickerUserView.drawRect:
- (void)drawRect:(CGRect)rect {
    if(!self.image) return;
    CGFloat scale=MIN(self.bounds.size.width/self.image.size.width,self.bounds.size.height/self.image.size.height);
    CGRect r=self.contentMode==UIViewContentModeScaleToFill?self.bounds:CGRectMake(CGRectGetMidX(self.bounds)-self.image.size.width*scale*.5,CGRectGetMidY(self.bounds)-self.image.size.height*scale*.5,self.image.size.width*scale,self.image.size.height*scale);
    [self.image drawInRect:r];
}
// BINMAP-ADAPT: UIColorPickerUserView.sampleAtPoint:
- (BOOL)sampleAtPoint:(CGPoint)point { return [self sampleAtPoint:point beginEditing:NO]; }
// BINMAP-ADAPT: UIColorPickerUserView.sampleAtPoint:beginEditing:
- (BOOL)sampleAtPoint:(CGPoint)point beginEditing:(BOOL)beginEditing {
    if(!self.image.CGImage || !isfinite(point.x) || !isfinite(point.y) || self.image.size.width<=0 || self.image.size.height<=0 || self.bounds.size.width<=0 || self.bounds.size.height<=0) return NO;
    CGFloat scale=MIN(self.bounds.size.width/self.image.size.width,self.bounds.size.height/self.image.size.height);
    CGRect display=self.contentMode==UIViewContentModeScaleToFill?self.bounds:CGRectMake(CGRectGetMidX(self.bounds)-self.image.size.width*scale*.5,CGRectGetMidY(self.bounds)-self.image.size.height*scale*.5,self.image.size.width*scale,self.image.size.height*scale);
    if(!CGRectContainsPoint(display,point)) return NO;
    CGFloat rawWidth=CGImageGetWidth(self.image.CGImage),rawHeight=CGImageGetHeight(self.image.CGImage);
    UIImageOrientation orientation=self.image.imageOrientation;
    BOOL rotated=orientation==UIImageOrientationLeft||orientation==UIImageOrientationRight||orientation==UIImageOrientationLeftMirrored||orientation==UIImageOrientationRightMirrored;
    CGFloat width=rotated?rawHeight:rawWidth,height=rotated?rawWidth:rawHeight;
    CGFloat x=MIN(width-1,MAX(0,floor((point.x-display.origin.x)/display.size.width*width)));
    CGFloat y=MIN(height-1,MAX(0,floor((point.y-display.origin.y)/display.size.height*height)));
    CGPoint rawPixel=CGPointMake(x,y);
    switch(orientation){
        case UIImageOrientationUp:break;
        case UIImageOrientationDown:rawPixel=CGPointMake(rawWidth-1-x,rawHeight-1-y);break;
        case UIImageOrientationLeft:rawPixel=CGPointMake(rawWidth-1-y,x);break;
        case UIImageOrientationRight:rawPixel=CGPointMake(y,rawHeight-1-x);break;
        case UIImageOrientationUpMirrored:rawPixel=CGPointMake(rawWidth-1-x,y);break;
        case UIImageOrientationDownMirrored:rawPixel=CGPointMake(x,rawHeight-1-y);break;
        case UIImageOrientationLeftMirrored:rawPixel=CGPointMake(y,x);break;
        case UIImageOrientationRightMirrored:rawPixel=CGPointMake(rawWidth-1-y,rawHeight-1-x);break;
    }
    CGImageRef pixel=CGImageCreateWithImageInRect(self.image.CGImage,CGRectMake(rawPixel.x,rawPixel.y,1,1));if(!pixel)return NO;
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);if(!space){CGImageRelease(pixel);return NO;}
    float rgba[4];CGContextRef context=CGBitmapContextCreate(rgba,1,1,32,sizeof(rgba),space,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
    if(!context){CGImageRelease(pixel);CGColorSpaceRelease(space);return NO;}
    // Draw one unrotated source pixel. Rotation is an exact coordinate mapping,
    // so neither image interpolation nor a CI backend participates in ordinary sampling.
    for(NSUInteger i=0;i<4;i++)rgba[i]=NAN;
    CGContextSetBlendMode(context,kCGBlendModeCopy);CGContextSetInterpolationQuality(context,kCGInterpolationNone);
    CGContextDrawImage(context,CGRectMake(0,0,1,1),pixel);CGContextRelease(context);
    CGImageAlphaInfo alphaInfo=CGImageGetAlphaInfo(self.image.CGImage);
    if(rgba[3]==0&&(alphaInfo==kCGImageAlphaFirst||alphaInfo==kCGImageAlphaLast)){
        // A premultiplied draw cannot recover a straight-alpha source's hidden
        // RGB at alpha zero. Retain the straight CI path only for this case;
        // an unwritten result stays NaN and leaves the previous selection intact.
        CIImage *image=[[CIImage alloc]initWithCGImage:pixel];
        CIContext *straightContext=[CIContext contextWithOptions:@{kCIContextWorkingColorSpace:(__bridge id)space,kCIContextOutputPremultiplied:@NO}];
        for(NSUInteger i=0;i<4;i++)rgba[i]=NAN;
        [straightContext render:image toBitmap:rgba rowBytes:sizeof(rgba) bounds:image.extent format:kCIFormatRGBAf colorSpace:space];
        if(rgba[3]!=0){CGImageRelease(pixel);CGColorSpaceRelease(space);return NO;}
    }else if(rgba[3]>0){
        rgba[0]/=rgba[3];rgba[1]/=rgba[3];rgba[2]/=rgba[3];
    }
    CGImageRelease(pixel);
    if(!isfinite(rgba[0])||!isfinite(rgba[1])||!isfinite(rgba[2])||!isfinite(rgba[3])||((alphaInfo==kCGImageAlphaNone||alphaInfo==kCGImageAlphaNoneSkipFirst||alphaInfo==kCGImageAlphaNoneSkipLast)&&rgba[3]!=1)){CGColorSpaceRelease(space);return NO;}
    CGFloat components[]={rgba[0],rgba[1],rgba[2],rgba[3]};
    CGColorRef color=CGColorCreate(space,components);CGColorSpaceRelease(space);if(!color)return NO;
    UIColorValue *sampledColor=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);if(!sampledColor)return NO;
    if(beginEditing)[self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    _sampledColor=sampledColor;
    self.samplePoint=point;
    self.accessibilityValue=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Pixel %@, %@. Red %@, green %@, blue %@, opacity %@ percent"],[UIColorPanelAppearance formatNumber:(long)(x+1) significantDigits:0],[UIColorPanelAppearance formatNumber:(long)(y+1) significantDigits:0],[UIColorPanelAppearance formatNumber:components[0] significantDigits:5],[UIColorPanelAppearance formatNumber:components[1] significantDigits:5],[UIColorPanelAppearance formatNumber:components[2] significantDigits:5],[UIColorPanelAppearance formatNumber:components[3]*100 significantDigits:5]];
    [self setNeedsDisplay];[self sendActionsForControlEvents:UIControlEventValueChanged];return YES;
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-SAMPLE-AX-01 manifest=reimpl/color_model_extras.json
- (BOOL)accessibilityMove:(UIAccessibilityCustomAction *)action {
    if(!self.image.CGImage||self.image.size.width<=0||self.image.size.height<=0||self.bounds.size.width<=0||self.bounds.size.height<=0)return NO;
    CGFloat scale=MIN(self.bounds.size.width/self.image.size.width,self.bounds.size.height/self.image.size.height);
    CGRect display=self.contentMode==UIViewContentModeScaleToFill?self.bounds:CGRectMake(CGRectGetMidX(self.bounds)-self.image.size.width*scale*.5,CGRectGetMidY(self.bounds)-self.image.size.height*scale*.5,self.image.size.width*scale,self.image.size.height*scale);
    UIImageOrientation orientation=self.image.imageOrientation;
    BOOL rotated=orientation==UIImageOrientationLeft||orientation==UIImageOrientationRight||orientation==UIImageOrientationLeftMirrored||orientation==UIImageOrientationRightMirrored;
    CGFloat pixelWidth=rotated?CGImageGetHeight(self.image.CGImage):CGImageGetWidth(self.image.CGImage);
    CGFloat pixelHeight=rotated?CGImageGetWidth(self.image.CGImage):CGImageGetHeight(self.image.CGImage);
    CGFloat dx=display.size.width/pixelWidth,dy=display.size.height/pixelHeight;
    CGPoint point=self.samplePoint.x>=0?self.samplePoint:CGPointMake(CGRectGetMidX(display),CGRectGetMidY(display));
    if([action.name isEqualToString:[UIColorPanelAppearance localizedString:@"Move left"]])point.x-=5*dx;
    else if([action.name isEqualToString:[UIColorPanelAppearance localizedString:@"Move right"]])point.x+=5*dx;
    else if([action.name isEqualToString:[UIColorPanelAppearance localizedString:@"Move up"]])point.y-=5*dy;
    else if([action.name isEqualToString:[UIColorPanelAppearance localizedString:@"Move down"]])point.y+=5*dy;
    else return NO;
    point.x=MAX(CGRectGetMinX(display)+dx/2,MIN(CGRectGetMaxX(display)-dx/2,point.x));
    point.y=MAX(CGRectGetMinY(display)+dy/2,MIN(CGRectGetMaxY(display)-dy/2,point.y));
    return [self sampleAtPoint:point];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-SAMPLE-AX-02 manifest=reimpl/color_model_extras.json
- (BOOL)accessibilityActivate {
    CGPoint point=self.samplePoint.x>=0?self.samplePoint:CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds));
    return [self sampleAtPoint:point];
}
// BINMAP-ADAPT: UIColorPickerUserView.beginTrackingWithTouch:withEvent:
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {self.acceptsTrackedTouch=YES;if(![self sampleAtPoint:[touch locationInView:self] beginEditing:YES])self.acceptsTrackedTouch=NO;return self.acceptsTrackedTouch;}
// BINMAP-ADAPT: UIColorPickerUserView.continueTrackingWithTouch:withEvent:
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {if(!self.acceptsTrackedTouch)return NO;[self sampleAtPoint:[touch locationInView:self]];return YES;}
// BINMAP-ADAPT: UIColorPickerUserView.endTrackingWithTouch:withEvent:
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {self.acceptsTrackedTouch=NO;}
// BINMAP-ADAPT: UIColorPickerUserView.cancelTrackingWithEvent:
- (void)cancelTrackingWithEvent:(UIEvent *)event {self.acceptsTrackedTouch=NO;}
@end

@implementation UIModeIcon
// BINMAP-ADAPT: UIModeIcon.imageForMode:
+ (UIImage *)imageForMode:(NSInteger)mode {
    NSArray *symbols=@[@"wheel",@"sliders",@"palette",@"image",UICOLORPANEL_ENABLE_PENCILS ? @"pencils" : @"grid",@"eyedropper"];
    NSString *name=mode>=0&&mode<(NSInteger)symbols.count?symbols[(NSUInteger)mode]:@"ellipsis.circle";
    return[UIColorPanelAppearance imageForSymbol:name size:mode==5?20:24];
}
@end

@implementation UIColorPanelColorWell
// BINMAP-ADAPT: UIColorPanelColorWell.setUsesCircularPresentation: manifest=reimpl/polish_appearance_extras.json
- (void)setUsesCircularPresentation:(BOOL)circular {
    if(_usesCircularPresentation==circular)return;_usesCircularPresentation=circular;
    if(circular){self.opaque=NO;self.contentMode=UIViewContentModeRedraw;}[self setNeedsDisplay];
}
// BINMAP-ADAPT: UIColorPanelColorWell.setSelected: manifest=reimpl/polish_appearance_extras.json
- (void)setSelected:(BOOL)selected {[super setSelected:selected];if(self.usesCircularPresentation)[self setNeedsDisplay];}
// BINMAP-ADAPT: UIColorPanelColorWell.drawRect:
- (void)drawRect:(CGRect)rect { [self drawColor]; }
// BINMAP: original=AppKit ida_name=-[NSColorPanelColorWell _drawWithStrokeColor:] ea=0x183b20a44 end=0x183b20bb0
- (BOOL)_drawWithStrokeColor:(UIColor *)strokeColor {
    if(!UIGraphicsGetCurrentContext())return NO;
    // BINNOTE: User-authorized UIKit appearance change; the original color drawing block remains intact.
    CGRect bounds=self.bounds;BOOL circular=self.usesCircularPresentation;
    if(circular){CGFloat diameter=MIN(30,MIN(bounds.size.width,bounds.size.height));bounds=CGRectMake(CGRectGetMidX(bounds)-diameter/2,CGRectGetMidY(bounds)-diameter/2,diameter,diameter);}
    UIBezierPath *path=circular?[UIBezierPath bezierPathWithOvalInRect:bounds]:[UIColorPanelAppearance smoothPathForRect:bounds radius:6];
    // BINMAP-ADAPT: opt-in native-favorite mask geometry; the default decoration stays intact.
    if(circular&&self.selected){CGFloat inset=bounds.size.width/10;[path appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds,inset,inset)]bezierPathByReversingPath]];[path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds,2*inset,2*inset)]];}
    CGContextRef context=UIGraphicsGetCurrentContext();CGContextSaveGState(context);[path addClip];
    if(circular)CGContextBeginTransparencyLayer(context,NULL);
    void (^draw)(void)=^{ // BINMAP-BLOCK: original=AppKit ea=0x183b20bb0 parent=0x183b20a44
        [self drawWellInside:bounds];
    };draw();
    if(circular)CGContextEndTransparencyLayer(context);else{[strokeColor setStroke];path.lineWidth=2;[path stroke];}CGContextRestoreGState(context);return YES;
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelColorWell drawColor] ea=0x183b20bc4 end=0x183b20c08
- (BOOL)drawColor {
    UIColor *stroke;if(@available(iOS 13.0,*))stroke=UIColor.tertiaryLabelColor;else stroke=[UIColor colorWithWhite:.5 alpha:1];return[self _drawWithStrokeColor:stroke];
}
// BINMAP-ADAPT: UIColorPanelColorWell.drawWellInside:
- (void)drawWellInside:(CGRect)rect { [self.color drawSwatchInRect:rect]; }
@end

// Own-source composition hooks already implemented by the recovered UIKit port.
// This declaration exposes no Apple SPI and leaves its BINMAP implementations intact.
@interface UIColorPickerColorSlider (UIColorPanelRendering)
@property(nonatomic,strong,readonly) CAGradientLayer *gradient;
- (void)stackForSize:(CGSize)size;
@end
@implementation UIGradientSlider {
    double _unclampedValue;
}
// BINMAP-ADAPT: UIGradientSlider.initWithFrame: manifest=reimpl/touch_slider_extras.json
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        _gradientColors=@[self.fromColor,self.toColor];self.showsOpacityBackground=NO;
    }return self;
}
// BINMAP-ADAPT: UIGradientSlider.setValue: manifest=reimpl/touch_slider_extras.json
- (void)setValue:(double)value {_unclampedValue=value;[super setValue:fmin(fmax(value,0),1)];}
// BINMAP-ADAPT: UIGradientSlider.setGradientColors: manifest=reimpl/touch_slider_extras.json
- (void)setGradientColors:(NSArray<UIColor *> *)colors {[self cancelPresentationAnimation];_gradientColors=[colors copy];[self setNeedsLayout];}
// BINMAP-ADAPT: UIGradientSlider.stackForSize: manifest=reimpl/touch_slider_extras.json
- (void)stackForSize:(CGSize)size {
    [super stackForSize:size];
    NSMutableArray *colors=[NSMutableArray arrayWithCapacity:self.gradientColors.count];
    for(UIColor *color in self.gradientColors)[colors addObject:(__bridge id)color.CGColor];
    self.gradient.colors=colors;
}
// BINMAP-ADAPT: UIGradientSlider.setEnabled: manifest=reimpl/touch_slider_extras.json
- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];self.alpha=enabled?1:.45;
    self.accessibilityTraits=enabled?(self.accessibilityTraits&~UIAccessibilityTraitNotEnabled):(self.accessibilityTraits|UIAccessibilityTraitNotEnabled);
}
// BINMAP-ADAPT: UIGradientSlider.pointInside:withEvent: manifest=reimpl/touch_slider_extras.json
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {return CGRectContainsPoint(CGRectInset(self.bounds,0,-4),point);}
// BINMAP-ADAPT: UIGradientSlider.accessibilityIncrement manifest=reimpl/touch_slider_extras.json
- (void)accessibilityIncrement {
    if(!self.enabled)return;
    // An unchanged visual endpoint must not replace an extended source value.
    if(self.accessibilityValueReversed?_unclampedValue<0:_unclampedValue>1)return;
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if(self.accessibilityValueReversed)[super accessibilityDecrement];else[super accessibilityIncrement];
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
}
// BINMAP-ADAPT: UIGradientSlider.accessibilityDecrement manifest=reimpl/touch_slider_extras.json
- (void)accessibilityDecrement {
    if(!self.enabled)return;
    if(self.accessibilityValueReversed?_unclampedValue>1:_unclampedValue<0)return;
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if(self.accessibilityValueReversed)[super accessibilityIncrement];else[super accessibilityDecrement];
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
}
@end
