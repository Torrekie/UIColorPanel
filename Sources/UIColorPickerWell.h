#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UIColorPickerWellShape) {
    UIColorPickerWellShapeCircle,
    UIColorPickerWellShapeRoundedRectangle,
};

typedef NS_ENUM(NSInteger, UIColorPickerWellCenterAlphaAppearance) {
    /// Original UIKit composition over the ring image. Default.
    UIColorPickerWellCenterAlphaAppearanceNativeCompositing = 0,
    /// The unchanged selected color over an opaque black/white diagonal backing.
    UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground = 1,
    /// The unchanged selected color over an opaque white/light-gray checkerboard.
    UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground = 2,
};

/// Independent UIKit UIColorWell recovery, available on iOS12 and later.
/// User selections send UIControlEventValueChanged; programmatic assignments do not.
@interface UIColorPickerWell : UIControl
/// nil shows the original gradient without a selected-color border. Default nil.
@property (nonatomic, strong, nullable) UIColor *selectedColor;
/// Title used when presenting the picker. Default nil.
@property (nonatomic, copy, nullable) NSString *title;
/// Whether users can pick translucent colors. Changing this leaves selectedColor intact.
@property (nonatomic) BOOL supportsAlpha;
/// Circle follows the iOS15 drawing bounds, independently clamped to 28–36pt.
/// Rounded rectangles use this view's bounds and the component's smooth corners.
/// The intrinsic size remains the original square size for either shape.
@property (nonatomic) UIColorPickerWellShape shape;
/// Center composition, independent of shape and supportsAlpha. Default NativeCompositing.
/// Reference backings affect appearance only: selectedColor, its color space/alpha,
/// UIView.alpha and ValueChanged remain unchanged. nil never adds a reference backing;
/// a nonnil color at alpha zero reveals the chosen backing. Opaque colors omit it.
/// Shape/style are archived.
@property (nonatomic) UIColorPickerWellCenterAlphaAppearance centerAlphaAppearance;
@end

NS_ASSUME_NONNULL_END
