#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#ifndef UICOLORPANEL_ENABLE_PRIVATE_API
#define UICOLORPANEL_ENABLE_PRIVATE_API 0
#endif

NS_ASSUME_NONNULL_BEGIN
/// Shared UIKit appearance/resources. Color archives and canonical values never use these formatters.
@interface UIColorPanelAppearance : NSObject
/// Main-bundle UIColorPanelKit.strings overrides the component table. Missing entries fall back to English/key.
+ (NSString *)localizedString:(NSString *)englishKey;
+ (NSBundle *)resourceBundle;
/// Mode icons prefer available SF Symbols on iOS13+; authored geometry supplies older-system fallbacks and action icons.
/// Returns a template image using native symbol metrics or a square authored canvas at the requested point size.
+ (UIImage *)imageForSymbol:(NSString *)name size:(CGFloat)size;
/// Public, self-authored smooth approximation for shared clipping/stroking. Not an exact CoreAnimation curve.
+ (UIBezierPath *)smoothPathForRect:(CGRect)rect radius:(CGFloat)radius;
/// Own view/layer only: 13+ public continuous corners; 12 public approximate mask. Call again after bounds changes.
+ (void)applyCornersToView:(UIView *)view radius:(CGFloat)radius useSPI:(BOOL)useSPI;
/// digits=0 rounds for integer display; otherwise g-style significant digits with locale-aware decimal/scientific notation.
+ (NSString *)formatNumber:(double)number significantDigits:(NSUInteger)digits;
+ (NSString *)formatNumber:(double)number significantDigits:(NSUInteger)digits locale:(nullable NSLocale *)locale;
/// Complete finite number only; no grouping separators or partial parses. nil locale means currentLocale.
+ (nullable NSNumber *)parseNumber:(NSString *)text;
+ (nullable NSNumber *)parseNumber:(NSString *)text locale:(nullable NSLocale *)locale;
@end
NS_ASSUME_NONNULL_END
