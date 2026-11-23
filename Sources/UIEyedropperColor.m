#import "UIEyedropperColor.h"
#import <math.h>
#import <string.h>

// BINMAP: original=Eyedropper ida_name=_ColorMake ea=0x2e47 end=0x2e5e
UIEyedropperRGB UIEyedropperColorMake(double r,double g,double b) { UIEyedropperRGB value={r,g,b};return value; }
// BINMAP: original=Eyedropper ida_name=_ColorMakeWithColor ea=0x2e5e end=0x2e92
UIEyedropperRGB UIEyedropperColorMakeWithColor(UIColor *color) {
    UIEyedropperRGB value;[color getRed:&value.r green:&value.g blue:&value.b alpha:NULL];return value;
}
// BINMAP: original=Eyedropper ida_name=_ColorCombineColors ea=0x2e92 end=0x2eb8
UIEyedropperRGB UIEyedropperColorCombineColors(UIEyedropperRGB a,UIEyedropperRGB b) { UIEyedropperRGB value={a.r+b.r,a.g+b.g,a.b+b.b};return value; }
// BINMAP: original=Eyedropper ida_name=_ColorDivide ea=0x2eb8 end=0x2ef8
UIEyedropperRGB UIEyedropperColorDivide(UIEyedropperRGB color,double divisor) { UIEyedropperRGB value={color.r/divisor,color.g/divisor,color.b/divisor};return value; }
// BINMAP: original=Eyedropper ida_name=_ColorEqualToColor ea=0x2ef8 end=0x2f39
BOOL UIEyedropperColorEqualToColor(UIEyedropperRGB a,UIEyedropperRGB b) { return a.r==b.r&&a.g==b.g&&a.b==b.b; }
// BINMAP: original=Eyedropper ida_name=_ColorApproxEqualToColor ea=0x2f39 end=0x2f94
BOOL UIEyedropperColorApproxEqualToColor(UIEyedropperRGB a,UIEyedropperRGB b,double tolerance) { return tolerance>fabs(a.r-b.r)&&tolerance>fabs(a.g-b.g)&&tolerance>fabs(a.b-b.b); }
// BINMAP: original=Eyedropper ida_name=_ColorDistanceToColor ea=0x2f94 end=0x2fd7
double UIEyedropperColorDistanceToColor(UIEyedropperRGB a,UIEyedropperRGB b) { return sqrt((a.b-b.b)*(a.b-b.b)+(a.g-b.g)*(a.g-b.g)+(a.r-b.r)*(a.r-b.r)); }
// BINMAP: original=Eyedropper ida_name=_ColorUIColor ea=0x2fd7 end=0x3007
UIColor * UIEyedropperColorUIColor(UIEyedropperRGB color) { return [UIColor colorWithRed:color.r green:color.g blue:color.b alpha:1]; }
// BINMAP: original=Eyedropper ida_name=_EDLensPositionIsCorner ea=0x4cf9 end=0x4d0a
BOOL UIEyedropperEDLensPositionIsCorner(NSInteger position) { return ((NSUInteger)position-5)<4; }
// BINMAP: original=Eyedropper ida_name=_EDLensPositionIsEdge ea=0x4d0a end=0x4d1a
BOOL UIEyedropperEDLensPositionIsEdge(NSInteger position) { return ((NSUInteger)position-1)<8; }

@implementation UIEyedropperSurface
@end
@implementation UIEyedropperColorAnalyzer
// BINMAP: original=Eyedropper ida_name=-[EDColorAnalyzer colorAtCenterOfSurface:offset:] ea=0x7648 end=0x780d
- (UIColor *)colorAtCenterOfSurface:(UIEyedropperSurface *)surface offset:(CGPoint)offset {
    const uint8_t *base=surface.data.bytes;
    NSUInteger x=(NSUInteger)((double)(surface.width>>1)+offset.x),y=(NSUInteger)((double)(surface.height>>1)+offset.y);
    const uint8_t *pixel=base+y*surface.bytesPerRow+4*x;
    UIEyedropperRGB color;
    if(surface.pixelFormat==UIEyedropperPixelFormatBGRA8){
        color=UIEyedropperColorMake(pixel[2]/255.0,pixel[1]/255.0,pixel[0]/255.0);
    }else if(surface.pixelFormat==UIEyedropperPixelFormatW30R){
        uint32_t packed;memcpy(&packed,pixel,sizeof(packed));
        color=UIEyedropperColorMake((float)((float)((packed>>20)&1023)-384.0f)/510.0f,(float)((float)((packed>>10)&1023)-384.0f)/510.0f,(float)((float)(packed&1023)-384.0f)/510.0f);
    }else return nil;
    return UIEyedropperColorUIColor(color);
}
@end

@interface UIEyedropperSample ()
@property(nonatomic,strong,readwrite) UIColorValue *color;
@property(nonatomic,strong,readwrite) UIImage *magnifiedPixels;
@property(nonatomic,readwrite) CGPoint pixel;
@end
@implementation UIEyedropperSample
@end

@implementation UIEyedropperPixelReader
// BINMAP-ADAPT: UIEyedropperPixelReader.colorAtX:y:inData:width:height:bytesPerRow:pixelFormat:
+ (UIColorValue *)colorAtX:(NSUInteger)x y:(NSUInteger)y inData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)stride pixelFormat:(UIEyedropperPixelFormat)format {
    if(!width||!height||width>NSUIntegerMax/4||stride<width*4||height>NSUIntegerMax/stride||data.length<height*stride||x>=width||y>=height)return nil;
    if(format!=UIEyedropperPixelFormatBGRA8&&format!=UIEyedropperPixelFormatW30R)return nil;
    UIEyedropperSurface *surface=[UIEyedropperSurface new];surface.data=data;surface.width=width;surface.height=height;surface.bytesPerRow=stride;surface.pixelFormat=format;
    UIColor *color=[[UIEyedropperColorAnalyzer new]colorAtCenterOfSurface:surface offset:CGPointMake((double)x-(width>>1),(double)y-(height>>1))];
    return color?[[UIColorValue alloc]initWithCGColor:color.CGColor]:nil;
}
// BINMAP-ADAPT: UIEyedropperPixelReader.sampleImage:atPixel:
+ (UIEyedropperSample *)sampleImage:(UIImage *)image atPixel:(CGPoint)pixel {
    if(!image.CGImage||!isfinite(pixel.x)||!isfinite(pixel.y))return nil;
    CGFloat rawWidth=CGImageGetWidth(image.CGImage),rawHeight=CGImageGetHeight(image.CGImage);
    BOOL swapsAxes=image.imageOrientation==UIImageOrientationLeft||image.imageOrientation==UIImageOrientationRight||image.imageOrientation==UIImageOrientationLeftMirrored||image.imageOrientation==UIImageOrientationRightMirrored;
    CGFloat width=swapsAxes?rawHeight:rawWidth,height=swapsAxes?rawWidth:rawHeight;
    if(width<=0||height<=0)return nil;
    pixel.x=MAX(0,MIN(width-1,floor(pixel.x)));pixel.y=MAX(0,MIN(height-1,floor(pixel.y)));
    CGPoint rawPixel=pixel;
    switch(image.imageOrientation){
        case UIImageOrientationUp:break;
        case UIImageOrientationDown:rawPixel=CGPointMake(rawWidth-1-pixel.x,rawHeight-1-pixel.y);break;
        case UIImageOrientationLeft:rawPixel=CGPointMake(rawWidth-1-pixel.y,pixel.x);break;
        case UIImageOrientationRight:rawPixel=CGPointMake(pixel.y,rawHeight-1-pixel.x);break;
        case UIImageOrientationUpMirrored:rawPixel=CGPointMake(rawWidth-1-pixel.x,pixel.y);break;
        case UIImageOrientationDownMirrored:rawPixel=CGPointMake(pixel.x,rawHeight-1-pixel.y);break;
        case UIImageOrientationLeftMirrored:rawPixel=CGPointMake(pixel.y,pixel.x);break;
        case UIImageOrientationRightMirrored:rawPixel=CGPointMake(rawWidth-1-pixel.y,rawHeight-1-pixel.x);break;
    }
    CGRect region=CGRectIntersection(CGRectMake(rawPixel.x-4,rawPixel.y-4,9,9),CGRectMake(0,0,rawWidth,rawHeight));
    CGImageRef source=CGImageCreateWithImageInRect(image.CGImage,region);if(!source)return nil;
    float rawPixels[9*9*4]={0},pixels[9*9*4];CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
    CGContextRef context=CGBitmapContextCreate(rawPixels,9,9,32,9*4*sizeof(float),space,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
    if(!context){CGImageRelease(source);CGColorSpaceRelease(space);return nil;}
    CGContextSetRGBFillColor(context,1,1,1,1);CGContextFillRect(context,CGRectMake(0,0,9,9));
    CGContextTranslateCTM(context,0,9);CGContextScaleCTM(context,1,-1);CGContextSetInterpolationQuality(context,kCGInterpolationNone);
    // Convert only a bounded raw-pixel region, without a rotation or mirror in
    // the drawing transform. Both transformed UIImage and CGImage probes had
    // mis-sampled the final source pixel; their underlying cause is unconfirmed.
    CGContextTranslateCTM(context,region.origin.x-rawPixel.x+4,region.origin.y-rawPixel.y+4);
    CGContextTranslateCTM(context,0,region.size.height);CGContextScaleCTM(context,1,-1);
    CGContextDrawImage(context,CGRectMake(0,0,region.size.width,region.size.height),source);CGImageRelease(source);
    CGContextRelease(context);
    // Orientation is an exact permutation of the already color-converted
    // 9x9 float tile. No source resampling or orientation-dependent edge draw.
    for(NSInteger y=0;y<9;y++)for(NSInteger x=0;x<9;x++){
        NSInteger dx=x-4,dy=y-4,rx=dx,ry=dy;
        switch(image.imageOrientation){
            case UIImageOrientationUp:break;
            case UIImageOrientationDown:rx=-dx;ry=-dy;break;
            case UIImageOrientationLeft:rx=-dy;ry=dx;break;
            case UIImageOrientationRight:rx=dy;ry=-dx;break;
            case UIImageOrientationUpMirrored:rx=-dx;ry=dy;break;
            case UIImageOrientationDownMirrored:rx=dx;ry=-dy;break;
            case UIImageOrientationLeftMirrored:rx=dy;ry=dx;break;
            case UIImageOrientationRightMirrored:rx=-dy;ry=-dx;break;
        }
        memcpy(pixels+(y*9+x)*4,rawPixels+((ry+4)*9+rx+4)*4,4*sizeof(float));
    }
    float *center=pixels+(4*9+4)*4;CGFloat components[4]={center[0],center[1],center[2],1};
    if(!isfinite(components[0])||!isfinite(components[1])||!isfinite(components[2])){CGColorSpaceRelease(space);return nil;}
    CGColorRef color=CGColorCreate(space,components);
    CGContextRef patchContext=CGBitmapContextCreate(pixels,9,9,32,9*4*sizeof(float),space,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);CGColorSpaceRelease(space);
    CGImageRef patch=patchContext?CGBitmapContextCreateImage(patchContext):NULL;if(patchContext)CGContextRelease(patchContext);
    if(!color||!patch){if(color)CGColorRelease(color);if(patch)CGImageRelease(patch);return nil;}
    UIEyedropperSample *sample=[UIEyedropperSample new];sample.color=[[UIColorValue alloc]initWithCGColor:color];sample.magnifiedPixels=[UIImage imageWithCGImage:patch scale:1 orientation:UIImageOrientationUp];sample.pixel=pixel;CGColorRelease(color);CGImageRelease(patch);return sample;
}
@end
