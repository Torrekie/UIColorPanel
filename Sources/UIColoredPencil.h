#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import <UIKit/UIKit.h>
#import "UIColorValue.h"
@class UIColorPickerPencilView;
NS_ASSUME_NONNULL_BEGIN
@interface UIColoredPencil : UIAccessibilityElement
@property(nonatomic, readonly, copy) NSString *name;
@property(nonatomic, readonly, strong) UIColorValue *color;
@property(nonatomic, readonly, strong, nullable) UIImage *image;
@property(nonatomic, weak, nullable) UIColorPickerPencilView *owningPencilView;
- (instancetype)initWithName:(NSString *)name color:(UIColorValue *)color image:(nullable UIImage *)image;
- (NSNumber *)colorPanelAccessibilityValueAttribute;
- (void)colorPanelAccessibilityPerformAction:(NSString *)action;
@end
NS_ASSUME_NONNULL_END
#endif
