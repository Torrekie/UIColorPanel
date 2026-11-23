#import <UIKit/UIKit.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN
/// The picker-internal diagonal preview. This does not present a picker or own color.
@interface UIColorPickerColorPreview : UIView
@property(nonatomic,strong) UIColorValue *color;
@end
NS_ASSUME_NONNULL_END
