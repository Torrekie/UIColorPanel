#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN
@interface UIColorValue (AppKitEquality)
/// AppKit numeric panel comparison; canonical isEqual: remains exact CG equality.
/// Catalog/dynamic/pattern class identity has no representation in UIColorValue.
- (BOOL)isEqualForColorPanel:(nullable id)object;
@end
NS_ASSUME_NONNULL_END
