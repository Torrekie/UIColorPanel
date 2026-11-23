#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Internal recovered color-name lexicon, including its original localization.
FOUNDATION_EXPORT NSString * _Nullable UIColorPickerAXNameFromColor(CGColorRef color);
// Bit 0 appends the original localized integer luma, without a percent sign.
FOUNDATION_EXPORT NSString * _Nullable UIColorPickerAXColorStringForColor(UIColor *color, unsigned char options);

NS_ASSUME_NONNULL_END
