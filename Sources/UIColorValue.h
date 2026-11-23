#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <TargetConditionals.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSErrorDomain const UIColorValueErrorDomain;
typedef NS_ERROR_ENUM(UIColorValueErrorDomain, UIColorValueError) {
    UIColorValueErrorUnsupportedSpace = 1,
    UIColorValueErrorConversionFailed,
    UIColorValueErrorInvalidArchive
};

/// An immutable color whose canonical representation is the original CGColor.
@interface UIColorValue : NSObject <NSCopying>
@property (nonatomic, readonly) CGColorRef CGColor;
#if TARGET_OS_IOS
@property (nonatomic, readonly) UIColor *UIColor;
#endif
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCGColor:(CGColorRef)color NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithPropertyList:(id)propertyList error:(NSError * _Nullable * _Nullable)error;
/// Returns nil for alpha outside [0, 1] or a non-finite alpha. RGB components are never clamped.
- (nullable UIColorValue *)copyWithAlpha:(CGFloat)alpha;
- (nullable UIColorValue *)colorByConvertingToSpace:(CGColorSpaceRef)space error:(NSError * _Nullable * _Nullable)error;
/// The target must be an RGB color space; components contains R, G, B, alpha.
- (BOOL)getRGBComponents:(CGFloat * _Nonnull)components inColorSpace:(CGColorSpaceRef)space error:(NSError * _Nullable * _Nullable)error;
/// Pattern colors are retained in memory but cannot be converted or persisted by this component.
- (nullable NSDictionary<NSString *, id> *)propertyListRepresentationWithError:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
