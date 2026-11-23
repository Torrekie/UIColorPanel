#import "UIColorPickerSpectrum.h"
#import <QuartzCore/CALayer.h>

NS_ASSUME_NONNULL_BEGIN
/// Shared composition of the recovered iOS15.5 33pt lens. Owners supply its
/// position/visibility; this implementation layer adds no touch or AX target.
@interface UIColorPickerSpectrumLens : CALayer
@property(nonatomic, strong, nullable) UIColorValue *selectedColor;
@end
NS_ASSUME_NONNULL_END
