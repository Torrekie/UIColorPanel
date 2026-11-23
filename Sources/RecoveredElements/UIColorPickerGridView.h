#import <UIKit/UIKit.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN

/// Native UIKit adaptation of ColorSwatchPickerView's original 120-color matrix.
/// The matrix stays in its original sRGB order. Programmatic colors are retained exactly.
@interface UIColorPickerGridView : UIControl
@property(nonatomic, strong) UIColorValue *selectedColor;
/// Most recent user sample. Swatches are opaque and converted to selectedColor's profile.
@property(nonatomic, strong, readonly, nullable) UIColorValue *sampledColor;
@property(nonatomic, readonly, getter=isActive) BOOL active;
@end

NS_ASSUME_NONNULL_END
