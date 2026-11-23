#import <UIKit/UIKit.h>
@class UIColorPickerSwatchesView;
NS_ASSUME_NONNULL_BEGIN
/// Accessible presentation of the same indexed favorites model and interaction view.
@interface UIColorPanelSavedColorsController : UIViewController
@property(nonatomic, copy, nullable) void (^restorationHandler)(void);
- (instancetype)initWithSwatchesView:(UIColorPickerSwatchesView *)view;
- (void)refreshActions;
@end
NS_ASSUME_NONNULL_END
