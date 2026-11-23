#import <UIKit/UIKit.h>
#import <os/log.h>
#import <os/signpost.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT os_log_t UIColorPickerLog(void);
FOUNDATION_EXPORT os_signpost_id_t UIColorPickerSignpostID(void);
/// These conversions preserve the iOS14.5 picker rules, including truncation,
/// optional parse failure and locale-specific percentage symbols.
FOUNDATION_EXPORT NSString *UIColorPickerIntegerText(double value);
FOUNDATION_EXPORT NSNumber * _Nullable UIColorPickerIntegerValue(NSString *text);
FOUNDATION_EXPORT BOOL UIColorPickerCanEditInteger(NSString *text, NSRange range, NSString *replacement);
FOUNDATION_EXPORT NSString *UIColorPickerPercentageText(double value);
FOUNDATION_EXPORT NSNumber * _Nullable UIColorPickerPercentageValue(NSString *text);
FOUNDATION_EXPORT BOOL UIColorPickerCanEditPercentage(NSString *text, NSRange range, NSString *replacement);
FOUNDATION_EXPORT BOOL UIColorPickerPercentageCharactersAllowed(NSString *text);
/// Original Scribble tolerance transform; the public port cannot install its SPI hook.
FOUNDATION_EXPORT UIEdgeInsets UIColorPickerScribbleHitTolerance(UIEdgeInsets defaultInsets);
/// The original range uses grapheme ordinals, not UTF16 offsets.
FOUNDATION_EXPORT NSRange UIColorPickerFirstNumberRange(NSString *text);
@interface UIColorPickerSliderControlStyle : NSObject
@property(nonatomic, copy) NSString *(^floatToTextMapping)(double value);
@property(nonatomic, copy) NSNumber * _Nullable (^textToFloatMapping)(NSString *text);
@property(nonatomic, copy) BOOL (^shouldChangeCharacters)(NSString *text, NSRange range, NSString *replacement);
@property(nonatomic, readonly) BOOL percentage;
+ (instancetype)integerStyle;
+ (instancetype)percentageStyle;
- (NSString *)textForValue:(double)value;
- (nullable NSNumber *)valueForText:(NSString *)text;
- (BOOL)canEditText:(NSString *)text range:(NSRange)range replacement:(NSString *)replacement;
@end
NS_ASSUME_NONNULL_END
