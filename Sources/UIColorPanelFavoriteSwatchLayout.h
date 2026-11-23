#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *const UIColorPanelEmptySwatchKind;
@interface UIColorPanelFavoriteSwatchLayout : UICollectionViewLayout
@property(nonatomic) CGSize itemSize;
@property(nonatomic) CGFloat itemSpacing;
@property(nonatomic) UIEdgeInsets sectionInset;
/// UIKit12 equivalent of the native picker's fixed-size, horizontally paged groups.
@property(nonatomic) BOOL nativePickerPresentation;
@property(nonatomic,strong,nullable) NSIndexPath *dropTargetIndexPath;
- (NSInteger)numberOfItemsFittingInBoundsWidth:(CGFloat)width;
- (CGRect)enclosingBounds;
- (UICollectionViewLayoutAttributes *)layoutAttributesForDropTargetAtPoint:(CGPoint)point;
- (UICollectionViewLayoutAttributes *)layoutAttributesForInterItemGapBeforeIndexPath:(NSIndexPath *)indexPath;
@end
NS_ASSUME_NONNULL_END
