#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import <UIKit/UIKit.h>
#import "UIColorValue.h"
#import "UIColorList.h"
@class UIColorPickerPencilView;
NS_ASSUME_NONNULL_BEGIN
typedef UIImage * _Nullable (^UIColorPencilImageProvider)(NSString *resourceName);
/// Native Pencils provider boundary. selectionHandler bridges an embedded controller;
/// without one, colorPanel receives setColorValue: through the original selection route.
@interface UIColorPickerPencils : NSObject
@property(nonatomic, readonly, strong) UIView *containerView;
@property(nonatomic, readonly, strong) UILabel *colorNameTextField;
@property(nonatomic, readonly, strong) UIColorPickerPencilView *pencilView;
@property(nonatomic, weak, nullable) id colorPanel;
@property(nonatomic, copy, nullable) void (^selectionHandler)(UIColorValue *color);
@property(nonatomic, copy, nullable) UIColorPencilImageProvider imageProvider;
- (instancetype)initWithPickerMask:(UIColorPanelOptions)mask colorPanel:(nullable id)panel;
- (UIView *)provideNewView:(BOOL)initial;
- (BOOL)supportsMode:(UIColorPanelMode)mode;
- (UIColorPanelMode)currentMode;
- (CGSize)minContentSize;
- (NSString *)buttonToolTip;
- (void)setColor:(UIColorValue *)color;
- (void)changeColor:(UIColorPickerPencilView *)sender;
- (void)changeDisplayedColorName:(UIColorPickerPencilView *)sender;
@end
NS_ASSUME_NONNULL_END
#endif
