#import "UIFavoriteColorsStore.h"

@interface UIFavoriteColorsStore ()
/// Suppress indexed edits before they address an entry in an unsupported, empty snapshot.
@property(nonatomic) BOOL backingReadOnly;
/// Check the latest backing format before publishing changed entries to observers.
@property(nonatomic, copy, nullable) BOOL (^backingAllowsEditing)(void);
@end
