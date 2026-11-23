#import <UIKit/UIKit.h>
#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN
/// nil is an empty decoration, distinct from an occupied color with alpha zero.
@interface UIColorPanelFavoriteSwatchView : UICollectionViewCell
@property(nonatomic,strong,nullable) UIColorValue *color;
/// Default NO preserves legacy decorations. YES centers a 30pt dot in the existing cell.
@property(nonatomic) BOOL usesCircularPresentation;
+ (CGSize)intrinsicContentSize;
@end
NS_ASSUME_NONNULL_END
