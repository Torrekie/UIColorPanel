#import <UIKit/UIKit.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN

/// Analytic Spectrum recovered from iOS14.5, with the iOS15.5 lens appearance.
/// The owner applies sampledColor and decides how it enters the host ICC model.
@interface UIColorPickerSpectrum : UIControl
/// Retains the canonical input, updates the idle lens, and sends no actions.
@property(nonatomic, strong) UIColorValue *selectedColor;
/// The latest gesture candidate, retaining the selected input's alpha.
/// Assigning selectedColor also synchronizes this value to the exact input.
@property(nonatomic, strong, readonly) UIColorValue *sampledColor;
@property(nonatomic, readonly, getter=isActive) BOOL active;
/// Available during EditingDidEnd. Cancellation retains the last sample.
@property(nonatomic, readonly) BOOL editingCancelled;
// Touch tracking sends EditingDidBegin, ValueChanged, then EditingDidEnd.
// Cancellation additionally sends TouchCancel before EditingDidEnd.
@end

NS_ASSUME_NONNULL_END
