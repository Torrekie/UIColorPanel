#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT UIImage *UIColorPickerOpacityTile(CGFloat height);
FOUNDATION_EXPORT double UIColorPickerVisualSliderValue(double value, BOOL rightToLeft);
FOUNDATION_EXPORT CGPoint UIColorPickerKnobPosition(CGSize size, double value, BOOL rightToLeft);
@interface UIColorPickerSliderKnob : UIView
@property(nonatomic, strong) UIColor *selectedColor;
- (void)body;
@end
@interface UIColorPickerOpacityBackground : UIImageView
- (nullable UIImage *)body;
@end
/// Public UIKit port of the original SwiftUI ColorSlider. A tap does not jump
/// the value: the original installs a DragGesture with minimumDistance 10.
@interface UIColorPickerColorSlider : UIControl
@property(nonatomic) double value;
@property(nonatomic, strong) UIColor *fromColor, *toColor, *selectedColor;
@property(nonatomic) BOOL showsOpacityBackground;
@property(nonatomic, readonly, getter=isActive) BOOL active;
@property(nonatomic, copy, nullable) void (^activeBinding)(BOOL active);
/// Host transaction used by color-space choices and completed sampling.
/// Values and callbacks update once; only the existing knob presentation moves.
+ (void)animateChangesToSliders:(NSArray<UIColorPickerColorSlider *> *)sliders updates:(void (^)(void))updates NS_SWIFT_NAME(animateChanges(to:updates:));
- (void)cancelPresentationAnimation;
- (void)dragChangedAtPoint:(CGPoint)point;
- (void)dragEnded;
- (void)adjustAccessibilityDirection:(NSInteger)direction;
@end
NS_ASSUME_NONNULL_END
