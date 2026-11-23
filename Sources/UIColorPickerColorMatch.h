#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN
/// Recovered named-palette selection kernels with explicit CG color transport.
@interface UIColorPickerColorMatch : NSObject
@property(nonatomic, readonly) NSInteger selectedIndex;
@property(nonatomic, readonly) BOOL profileAvailable;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithColors:(NSArray<UIColorValue *> *)colors color:(UIColorValue *)color selectedIndex:(NSInteger)selectedIndex;
- (instancetype)initWithColors:(NSArray<UIColorValue *> *)colors color:(UIColorValue *)color selectedIndex:(NSInteger)selectedIndex matchingColorSpace:(nullable CGColorSpaceRef)matchingColorSpace NS_DESIGNATED_INITIALIZER;
/// The caller retains its existing selection when profileAvailable is NO.
- (NSInteger)_colorIndexInTableView;
- (double)_matchQualityOfColorAtIndex:(NSUInteger)index toColor:(UIColorValue *)color ifBetterThan:(double)best;
@end
NS_ASSUME_NONNULL_END
