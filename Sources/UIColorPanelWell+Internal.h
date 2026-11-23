#import "UIColorPanelWell.h"

NS_ASSUME_NONNULL_BEGIN
/// Recovered provider/lifecycle bridge; not part of the installed component API.
@interface UIColorPanelWell (UIColorPanelInternal)
+ (void)_deactivateAllColorWells;
+ (nullable UIColorPanelWell *)_exclusiveColorPanelOwner;
+ (void)colorPanelColorChanged:(NSNotification *)notification;
- (BOOL)_ownsColorPanelExclusively;
- (BOOL)_shouldOrderFront;
- (instancetype)_takeColorFrom:(id)sender andSendAction:(BOOL)sendAction;
- (instancetype)_takeColorFromAndSendActionIfContinuous:(id)sender;
- (instancetype)_takeColorFromDoAction:(id)sender;
- (void)windowWillClose:(NSNotification *)notification;
@end
NS_ASSUME_NONNULL_END
