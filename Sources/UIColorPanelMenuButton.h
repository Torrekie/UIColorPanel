#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Internal popup-control bridge. iOS13 exposes a native menu on touch and hold;
/// iOS14+ exposes it as the primary action. Older-system taps use a native list.
@interface UIColorPanelMenuButton : UIButton

/// NO: current value plus an independently laid-out trailing chevron.
/// YES: a centered More icon. The caller supplies a contextual AX label.
@property(nonatomic) BOOL displaysMoreActions;

/// Providers must capture their owning controller weakly. Menus are rebuilt
/// immediately before presentation so checkmarks and enabled states stay current.
@property(nonatomic, copy, nullable) UIMenu * _Nullable (^menuProvider)(void) API_AVAILABLE(ios(13.0));

/// Set menuProvider before querying this property. A true result means the
/// caller should not attach its touch-up-inside action-sheet fallback.
@property(nonatomic, readonly) BOOL usesPrimaryMenu;

+ (UIStackView *)headerWithSelectionButton:(UIColorPanelMenuButton *)selection actionsButton:(UIColorPanelMenuButton *)actions;

- (void)reloadMenu;

@end

NS_ASSUME_NONNULL_END
