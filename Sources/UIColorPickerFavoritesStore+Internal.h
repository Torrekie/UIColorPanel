#import "UIColorPickerFavoritesStore.h"

// Default app-local library for embedded panels, the shared panel and the iOS 12–13 Well.
static NSString * _Nonnull const UIColorPanelLocalFavoritesKey = @"UIColorPanel.SavedColors.v2";

/// A fresh native-style library in the current display gamut, in version-one sparse format.
FOUNDATION_EXPORT NSDictionary * _Nonnull UIColorPickerDefaultFavoritesRecord(void);

#if UICOLORPANEL_ENABLE_PRIVATE_API
@interface UIColorPickerFavoritesStore (SystemPicker)
+ (nullable instancetype)systemPickerStoreIfAccessible;
@property(nonatomic, readonly, getter=isSystemPickerStore) BOOL systemPickerStore;
/// Rejects stale edits and unrepresentable records, and notifies only after a successful write.
- (BOOL)tryWriteRecord:(nonnull id)record;
@end
#endif
