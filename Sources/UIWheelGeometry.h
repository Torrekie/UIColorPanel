#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
@class UIColorValue;

NS_ASSUME_NONNULL_BEGIN
/// Recovered AppKit wheel coordinates: x right, y up. The caller supplies square bounds.
@interface UIWheelGeometry : NSObject
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGFloat brightness;
@property (nonatomic) CGFloat alpha;
/// Borrowed RGB space. The caller keeps it alive for the geometry's lifetime.
@property (nonatomic, assign) CGColorSpaceRef colorSpace;
- (nullable UIColorValue *)_brightColorFromPoint:(CGPoint)point fullBrightness:(BOOL)fullBrightness;
- (CGPoint)_pointFromColor:(nullable UIColorValue *)color;
@end
NS_ASSUME_NONNULL_END
