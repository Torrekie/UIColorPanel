#if defined(UICOLORPANEL_ENABLE_PRIVATE_API) && UICOLORPANEL_ENABLE_PRIVATE_API

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Unsupported entries make the snapshot unavailable for editing. A nonnil replacement
/// contains the native value with only confirmed damage repaired, even if other entries are unsupported.
FOUNDATION_EXPORT NSDictionary * _Nullable UIColorPickerDecodeSystemFavorites(id nativeValue, id _Nullable * _Nonnull replacement);
/// Produces a dense ordered array from the component's sparse slots. Returns nil on loss of color data.
FOUNDATION_EXPORT NSData * _Nullable UIColorPickerEncodeSystemFavorites(NSDictionary *record);

NS_ASSUME_NONNULL_END

#endif
