#import <UIKit/UIKit.h>
#import "UIColorValue.h"
#import "RecoveredElements/UIColorPickerColorSlider.h"

@interface UIColorPickerWheelView : UIControl
@property(nonatomic) CGFloat hue, saturation, brightness;
@property(nonatomic,strong) UIColorValue *colorValue;
@end

@interface UIColorPickerUserView : UIControl
@property(nonatomic, strong) UIImage *image;
/// Canonical indicator color. Nil keeps the standalone sampler's sampled color.
@property(nonatomic, strong, nullable) UIColorValue *selectedColor;
@property(nonatomic, strong, readonly) UIColorValue *sampledColor;
/// View coordinates, reprojected with the displayed image after bounds changes.
/// A negative x clears the indicator location without changing sampledColor.
@property(nonatomic) CGPoint samplePoint;
@property(nonatomic, copy) NSString *sampleLabel;
@end

@interface UIModeIcon : NSObject
+ (UIImage *)imageForMode:(NSInteger)mode;
@end

@interface UIColorPanelColorWell : UIButton
@property(nonatomic) BOOL pencil;
@property(nonatomic, strong) UIColorValue *color;
/// Default NO retains the original decoration. YES centers an at-most30pt color dot.
@property(nonatomic) BOOL usesCircularPresentation;
- (BOOL)drawColor;
- (BOOL)_drawWithStrokeColor:(UIColor *)strokeColor;
- (void)drawWellInside:(CGRect)rect;
@end

@interface UIGradientSlider : UIColorPickerColorSlider
@property(nonatomic,copy) NSArray<UIColor *> *gradientColors;
/// Internal value direction differs from the spoken/adjustable brightness direction.
@property(nonatomic) BOOL accessibilityValueReversed;
@end
