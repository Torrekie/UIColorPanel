#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import <UIKit/UIKit.h>
#import "UIColorPickerPencils.h"
#import "UIColoredPencil.h"
NS_ASSUME_NONNULL_BEGIN
/// Native 12-column, four-row overlapping pencil display. Bounds use UIKit's
/// top-down coordinates, matching the original flipped AppKit pencil view.
@interface UIColorPickerPencilView : UIControl
@property(nonatomic, strong) UIColorValue *color;
@property(nonatomic, readonly, copy) NSString *localizedColorNameComponent;
@property(nonatomic, weak, nullable) UIColorPickerPencils *controllingPicker;
@property(nonatomic, copy, nullable) UIColorPencilImageProvider imageProvider;
/// The UIKit owner moves focus forward/backward and returns YES after a successful handoff.
/// Without a handler, this view leaves Tab navigation to UIKit.
@property(nonatomic, copy, nullable) BOOL (^keyboardFocusNavigationHandler)(BOOL backwards);
@property(nonatomic) BOOL selectedPencilStaysUp;
@property(nonatomic) BOOL lowerHoveredPencil;
/// Original optional feature defaults are NO; normal operation uses full-resolution layers.
@property(nonatomic) BOOL use_spi;
@property(nonatomic) BOOL strictAspectRatio;
@property(nonatomic) BOOL prerenderScaledPencilRepresentations;
- (NSArray<UIColoredPencil *> *)_pencils;
- (nullable UIColoredPencil *)_selectedPencil;
- (nullable UIColoredPencil *)_pencilWithColor:(UIColorValue *)color;
- (CGRect)_calculateFrameForPencil:(UIColoredPencil *)pencil atRow:(NSInteger)row column:(NSInteger)column;
- (CGRect)_unobscuredFrameOfPencil:(UIColoredPencil *)pencil;
- (nullable UIColoredPencil *)_pencilAtViewPoint:(CGPoint)point;
- (void)_selectPencil:(nullable UIColoredPencil *)pencil updateSelection:(BOOL)update animate:(BOOL)animate;
- (void)_hoverPencil:(nullable UIColoredPencil *)pencil;
- (void)_updatePencilsFromColorList;
- (void)moveUp:(nullable id)sender;
- (void)moveDown:(nullable id)sender;
- (void)moveLeft:(nullable id)sender;
- (void)moveRight:(nullable id)sender;
@end
NS_ASSUME_NONNULL_END
#endif
