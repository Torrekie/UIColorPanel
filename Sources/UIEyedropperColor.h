#import <UIKit/UIKit.h>
#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN

typedef struct { double r,g,b; } UIEyedropperRGB;
FOUNDATION_EXPORT UIEyedropperRGB UIEyedropperColorMake(double r,double g,double b);
FOUNDATION_EXPORT UIEyedropperRGB UIEyedropperColorMakeWithColor(UIColor *color);
FOUNDATION_EXPORT UIEyedropperRGB UIEyedropperColorCombineColors(UIEyedropperRGB a,UIEyedropperRGB b);
FOUNDATION_EXPORT UIEyedropperRGB UIEyedropperColorDivide(UIEyedropperRGB color,double divisor);
FOUNDATION_EXPORT BOOL UIEyedropperColorEqualToColor(UIEyedropperRGB a,UIEyedropperRGB b);
FOUNDATION_EXPORT BOOL UIEyedropperColorApproxEqualToColor(UIEyedropperRGB a,UIEyedropperRGB b,double tolerance);
FOUNDATION_EXPORT double UIEyedropperColorDistanceToColor(UIEyedropperRGB a,UIEyedropperRGB b);
FOUNDATION_EXPORT UIColor *UIEyedropperColorUIColor(UIEyedropperRGB color);
FOUNDATION_EXPORT BOOL UIEyedropperEDLensPositionIsCorner(NSInteger position);
FOUNDATION_EXPORT BOOL UIEyedropperEDLensPositionIsEdge(NSInteger position);

typedef NS_ENUM(uint32_t,UIEyedropperPixelFormat) {
    UIEyedropperPixelFormatBGRA8=0x42475241,
    UIEyedropperPixelFormatW30R=0x77333072
};

/// Public byte-buffer transport for the original IOSurface metadata imports.
@interface UIEyedropperSurface : NSObject
@property(nonatomic,copy) NSData *data;
@property(nonatomic) NSUInteger width,height,bytesPerRow;
@property(nonatomic) UIEyedropperPixelFormat pixelFormat;
@end

@interface UIEyedropperColorAnalyzer : NSObject
- (nullable UIColor *)colorAtCenterOfSurface:(UIEyedropperSurface *)surface offset:(CGPoint)offset;
@end

@interface UIEyedropperSample : NSObject
@property(nonatomic,strong,readonly) UIColorValue *color;
@property(nonatomic,strong,readonly) UIImage *magnifiedPixels;
@property(nonatomic,readonly) CGPoint pixel;
@end

@interface UIEyedropperPixelReader : NSObject
/// The original opaque BGRA8/packed10-bit branch; validation lives in this adapter.
+ (nullable UIColorValue *)colorAtX:(NSUInteger)x y:(NSUInteger)y inData:(NSData *)data width:(NSUInteger)width height:(NSUInteger)height bytesPerRow:(NSUInteger)stride pixelFormat:(UIEyedropperPixelFormat)format;
/// Uses at most two9x9 float buffers; integer pixel permutation honors image orientation. Alpha composites onto white.
+ (nullable UIEyedropperSample *)sampleImage:(UIImage *)image atPixel:(CGPoint)pixel;
@end
NS_ASSUME_NONNULL_END
