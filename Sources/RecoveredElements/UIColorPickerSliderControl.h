#import <UIKit/UIKit.h>
#import "UIColorPickerColorSlider.h"
#import "UIColorPickerFormatting.h"
NS_ASSUME_NONNULL_BEGIN
/// Reusable title + ColorSlider + CPTextField recovered from SliderControl.
/// The owner supplies component values and gradient endpoints; the row does
/// not flatten, quantize or replace a host's ICC/canonical color model.
@interface UIColorPickerSliderControl : UIControl
@property(nonatomic, copy, readonly) NSString *title;
@property(nonatomic) double value;
@property(nonatomic, strong) UIColor *fromColor,*toColor,*selectedColor;
@property(nonatomic) BOOL showsOpacityBackground,landscapeLayout;
@property(nonatomic, strong, readonly) UIColorPickerColorSlider *slider;
@property(nonatomic, strong, readonly) UITextField *textField;
@property(nonatomic, strong, readonly) UIColorPickerSliderControlStyle *style;
- (instancetype)initWithTitle:(NSString *)title value:(double)value fromColor:(UIColor *)from toColor:(UIColor *)to style:(UIColorPickerSliderControlStyle *)style;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
