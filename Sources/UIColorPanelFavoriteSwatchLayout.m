#import "UIColorPanelFavoriteSwatchLayout.h"
#import "UIColorPanelFavoriteSwatchView.h"
#import <math.h>
NSString *const UIColorPanelEmptySwatchKind=@"emptySwatch";
@implementation UIColorPanelFavoriteSwatchLayout
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout init] ea=0x184045b34 end=0x184045ba0
- (instancetype)init {if((self=[super init]))[self registerClass:UIColorPanelFavoriteSwatchView.class forDecorationViewOfKind:UIColorPanelEmptySwatchKind];return self;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout layoutAttributesForDecorationViewOfKind:atIndexPath:] ea=0x184045ba0 end=0x184045ce0
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if(self.nativePickerPresentation)return nil;
    if(![kind isEqualToString:UIColorPanelEmptySwatchKind])return nil;
    NSInteger columns=[self numberOfItemsFittingInBoundsWidth:self.enclosingBounds.size.width];
    UICollectionViewLayoutAttributes *attributes=[UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:kind withIndexPath:indexPath];NSInteger index=indexPath.item;
    if(self.dropTargetIndexPath&&self.dropTargetIndexPath.item<=index)index++;
    attributes.frame=CGRectMake(self.sectionInset.left+(self.itemSize.width+self.itemSpacing)*(index%columns),self.sectionInset.top+(self.itemSize.height+self.itemSpacing)*(index/columns),self.itemSize.width,self.itemSize.height);return attributes;
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout numberOfItemsFittingInBoundsWidth:] ea=0x184045ce0 end=0x184045d58
- (NSInteger)numberOfItemsFittingInBoundsWidth:(CGFloat)width {NSInteger result=(NSInteger)floor((width-self.sectionInset.left-self.sectionInset.right+self.itemSpacing)/(self.itemSize.width+self.itemSpacing));return result<=1?1:result;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout layoutAttributesForElementsInRect:] ea=0x184045d58 end=0x184045f4c
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger count=[self.collectionView numberOfItemsInSection:0];NSMutableArray *result=[NSMutableArray arrayWithCapacity:count];
    for(NSInteger index=0;index<count;index++){UICollectionViewLayoutAttributes *attributes=[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];if(CGRectIntersectsRect(attributes.frame,rect))[result addObject:attributes];}
    if(self.nativePickerPresentation)return result;
    CGRect bounds=self.enclosingBounds;NSInteger rows=(NSInteger)((bounds.size.height-self.sectionInset.top-self.sectionInset.bottom+self.itemSpacing)/(self.itemSize.height+self.itemSpacing));NSInteger columns=[self numberOfItemsFittingInBoundsWidth:bounds.size.width];NSInteger occupied=count+(self.dropTargetIndexPath?1:0);NSInteger empty=columns*rows-occupied;
    if(columns*rows<=occupied){NSInteger remainder=occupied%columns;if(remainder==0)return result;empty=columns-remainder;}
    for(NSInteger index=0;index<empty;index++){UICollectionViewLayoutAttributes *attributes=[self layoutAttributesForDecorationViewOfKind:UIColorPanelEmptySwatchKind atIndexPath:[NSIndexPath indexPathForItem:count+index inSection:0]];if(CGRectIntersectsRect(attributes.frame,rect))[result addObject:attributes];}return result;
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout layoutAttributesForItemAtIndexPath:] ea=0x184045f4c end=0x184046064
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns=[self numberOfItemsFittingInBoundsWidth:self.enclosingBounds.size.width];UICollectionViewLayoutAttributes *attributes=[UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];NSInteger index=indexPath.item;if(self.dropTargetIndexPath&&self.dropTargetIndexPath.item<=index)index++;
    if(self.nativePickerPresentation){
        CGRect bounds=self.enclosingBounds;
        NSInteger rows=MAX(1,(NSInteger)floor((bounds.size.height+self.itemSpacing)/(self.itemSize.height+self.itemSpacing)));
        NSInteger capacity=columns*rows,page=index/capacity,within=index%capacity;
        attributes.frame=CGRectMake(page*(bounds.size.width+self.itemSpacing)+(self.itemSize.width+self.itemSpacing)*(within%columns),(self.itemSize.height+self.itemSpacing)*(within/columns),self.itemSize.width,self.itemSize.height);
        return attributes;
    }
    attributes.frame=CGRectMake(self.sectionInset.left+(self.itemSize.width+self.itemSpacing)*(index%columns),self.sectionInset.top+(self.itemSize.height+self.itemSpacing)*(index/columns),self.itemSize.width,self.itemSize.height);return attributes;
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout shouldInvalidateLayoutForBoundsChange:] ea=0x184046064 end=0x18404606c
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {return YES;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout enclosingBounds] ea=0x18404606c end=0x18404609c
- (CGRect)enclosingBounds {return self.collectionView.bounds;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout collectionViewContentSize] ea=0x18404609c end=0x184046164
- (CGSize)collectionViewContentSize {
    CGRect bounds=self.enclosingBounds;
    if(self.nativePickerPresentation){
        NSInteger columns=[self numberOfItemsFittingInBoundsWidth:bounds.size.width];
        NSInteger rows=MAX(1,(NSInteger)floor((bounds.size.height+self.itemSpacing)/(self.itemSize.height+self.itemSpacing)));
        NSInteger count=[self.collectionView numberOfItemsInSection:0],pages=MAX(1,(NSInteger)ceil((double)count/(columns*rows)));
        return CGSizeMake(bounds.size.width+(pages-1)*(bounds.size.width+self.itemSpacing),bounds.size.height);
    }
    NSInteger rows=(NSInteger)ceil((double)[self.collectionView numberOfItemsInSection:0]/[self numberOfItemsFittingInBoundsWidth:bounds.size.width]);if(rows<=1)rows=1;CGFloat height=rows*(self.itemSize.height+self.itemSpacing)-self.itemSpacing+self.sectionInset.top+self.sectionInset.bottom;return CGSizeMake(bounds.size.width,MAX(floor(bounds.size.height),height));
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout layoutAttributesForDropTargetAtPoint:] ea=0x184046164 end=0x184046288
- (UICollectionViewLayoutAttributes *)layoutAttributesForDropTargetAtPoint:(CGPoint)point {
    if(self.nativePickerPresentation){
        CGRect bounds=self.enclosingBounds;NSInteger columns=[self numberOfItemsFittingInBoundsWidth:bounds.size.width];
        NSInteger rows=MAX(1,(NSInteger)floor((bounds.size.height+self.itemSpacing)/(self.itemSize.height+self.itemSpacing)));
        CGFloat stride=bounds.size.width+self.itemSpacing;NSInteger page=(NSInteger)floor(point.x/stride);CGFloat x=point.x-page*stride;
        NSInteger column=MIN(columns-1,MAX(0,(NSInteger)((x+self.itemSpacing)/(self.itemSize.width+self.itemSpacing))));
        NSInteger row=MIN(rows-1,MAX(0,(NSInteger)((point.y+self.itemSpacing)/(self.itemSize.height+self.itemSpacing))));
        NSInteger count=[self.collectionView numberOfItemsInSection:0],index=MIN(MAX(0,page*columns*rows+row*columns+column),MAX(0,count-1));
        return [self layoutAttributesForInterItemGapBeforeIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    }
    NSInteger row=(NSInteger)((point.y-self.sectionInset.top+self.itemSpacing)/(self.itemSize.height+self.itemSpacing));NSInteger column=(NSInteger)((point.x-self.sectionInset.left+self.itemSpacing)/(self.itemSize.width+self.itemSpacing));NSInteger columns=[self numberOfItemsFittingInBoundsWidth:self.enclosingBounds.size.width];NSInteger index=MIN(column,columns)+columns*row;index=MIN(index,[self.collectionView numberOfItemsInSection:0]);return [self layoutAttributesForInterItemGapBeforeIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoriteSwatchLayout layoutAttributesForInterItemGapBeforeIndexPath:] ea=0x184046288 end=0x1840462d8
- (UICollectionViewLayoutAttributes *)layoutAttributesForInterItemGapBeforeIndexPath:(NSIndexPath *)indexPath {UICollectionViewLayoutAttributes *item=[self layoutAttributesForItemAtIndexPath:indexPath];UICollectionViewLayoutAttributes *gap=[UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"interItemGap" withIndexPath:indexPath];gap.frame=item.frame;return gap;}
// BINMAP-ADAPT: id=native-favorites-uikit-12 — fixed-size native groups with section interGroupSpacing; iOS12 equivalent of groupPaging.
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposed withScrollingVelocity:(CGPoint)velocity {
    if(!self.nativePickerPresentation)return [super targetContentOffsetForProposedContentOffset:proposed withScrollingVelocity:velocity];CGFloat stride=self.enclosingBounds.size.width+self.itemSpacing;CGFloat maximum=MAX(0,self.collectionViewContentSize.width-self.enclosingBounds.size.width);return CGPointMake(MIN(maximum,MAX(0,round(proposed.x/stride)*stride)),0);
}
@end
