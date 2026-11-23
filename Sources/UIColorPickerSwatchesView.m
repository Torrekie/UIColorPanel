#import "UIColorPickerSwatchesView+Internal.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPickerColorAccessibility.h"
#import "UIColorPanelFavoriteSwatchLayout.h"
#import "UIColorPanelFavoriteSwatchView.h"
#import "UIFavoriteColorsStore+Internal.h"
#import "UIColorArchive.h"
#import "UIColorValue+AppKitEquality.h"
#import "UIColorValue+FavoriteRecord.h"
#import "UIColorPickerFavoritesStore+Internal.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <stdlib.h>
@interface UIColorPickerSwatchAction : UIAccessibilityCustomAction
@property(nonatomic) NSUInteger slot;
@end
@implementation UIColorPickerSwatchAction
@end
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000179D0 ea=0x1000179d0 end=0x100017a18
static BOOL UIColorPickerNativeFavoriteColorsEqual(UIColorValue *first,UIColorValue *second) {
    CGColorRef a=first.CGColor,b=second.CGColor;
    // BINNOTE: SomeColor's exact RGBA/profile-tag equality is generalized to
    // the existing UIColorValue's complete ICC space and component array.
    if(!CFEqual(CGColorGetColorSpace(a),CGColorGetColorSpace(b)))return NO;
    size_t count=CGColorGetNumberOfComponents(a);if(count!=CGColorGetNumberOfComponents(b))return NO;
    const CGFloat *left=CGColorGetComponents(a),*right=CGColorGetComponents(b);
    for(size_t index=0;index<count;index++)if(left[index]!=right[index])return NO;
    return YES;
}
// BINMAP-ADAPT: UIColorPickerFavoritesRecordIsEditable manifest=reimpl/favorites_swatches_refresh_extras.json
static BOOL UIColorPickerFavoritesRecordIsEditable(id record) {
    if (!record || [record isKindOfClass:NSArray.class]) return YES;
    return [record isKindOfClass:NSDictionary.class] && [record[@"version"] isKindOfClass:NSNumber.class] &&
           [record[@"version"] doubleValue] == 1 && [record[@"slots"] isKindOfClass:NSDictionary.class];
}

// BINMAP-ADAPT: UIColorPickerFavoriteSlotIndex manifest=reimpl/favorites_swatches_refresh_extras.json
static NSUInteger UIColorPickerFavoriteSlotIndex(NSString *key) {
    if (![key isKindOfClass:NSString.class] || !key.length) return NSNotFound;
    unsigned long long index = strtoull(key.UTF8String, NULL, 10);
    if (index >= NSIntegerMax || ![key isEqualToString:[@(index) stringValue]]) return NSNotFound;
    return (NSUInteger)index;
}

@interface UIColorPickerNativeFavoriteCell : UICollectionViewCell
@property(nonatomic,strong) UIColorValue *color;
@property(nonatomic,copy,nullable) void (^deletionHandler)(void);
@property(nonatomic,strong) UIView *colorView;
@property(nonatomic,strong) CAShapeLayer *blackHalfLayer;
@property(nonatomic,strong) CAShapeLayer *swatchMaskLayer;
- (void)configureViews;
@end
@implementation UIColorPickerNativeFavoriteCell
// BINMAP-ADAPT: id=native-favorites-uikit-01
- (instancetype)initWithFrame:(CGRect)frame {if((self=[super initWithFrame:frame])){_colorView=[UIView new];_blackHalfLayer=[CAShapeLayer layer];_swatchMaskLayer=[CAShapeLayer layer];[self configureViews];}return self;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002D2E0 ea=0x10002d2e0 end=0x10002d4be
- (void)configureViews {self.contentView.backgroundColor=UIColor.whiteColor;self.blackHalfLayer.fillColor=UIColor.blackColor.CGColor;[self.contentView.layer addSublayer:self.blackHalfLayer];[self.contentView addSubview:self.colorView];self.swatchMaskLayer.fillColor=UIColor.blackColor.CGColor;self.contentView.layer.mask=self.swatchMaskLayer;self.colorView.backgroundColor=self.color.UIColor;self.isAccessibilityElement=YES;}
// BINMAP-ADAPT: id=native-favorites-uikit-02
- (void)setColor:(UIColorValue *)color {_color=color;self.colorView.backgroundColor=color.UIColor;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker21FavoriteColorWellCell setSelected:] ea=0x10002d4f0 end=0x10002d555
- (void)setSelected:(BOOL)selected {[super setSelected:selected];[self setNeedsLayout];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002D560 ea=0x10002d560 end=0x10002dbd7
- (void)layoutSubviews {
    [super layoutSubviews];CGRect bounds=self.bounds;self.colorView.frame=bounds;self.blackHalfLayer.frame=bounds;self.swatchMaskLayer.frame=bounds;
    UIBezierPath *half=[UIBezierPath bezierPath];[half moveToPoint:CGPointMake(CGRectGetMinX(bounds),CGRectGetMinY(bounds))];[half addLineToPoint:CGPointMake(CGRectGetMinX(bounds),CGRectGetMinY(bounds))];[half addLineToPoint:CGPointMake(CGRectGetMinX(bounds),CGRectGetMaxY(bounds))];[half addLineToPoint:CGPointMake(CGRectGetMaxX(bounds),CGRectGetMinY(bounds))];[half closePath];self.blackHalfLayer.path=half.CGPath;
    UIBezierPath *mask=[UIBezierPath bezierPathWithOvalInRect:bounds];if(self.selected){[mask appendPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds,3,3)]bezierPathByReversingPath]];[mask appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds,6,6)]];}self.swatchMaskLayer.path=mask.CGPath;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker21FavoriteColorWellCell canBecomeFirstResponder] ea=0x10002dc10 end=0x10002dc18
- (BOOL)canBecomeFirstResponder {return YES;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker21FavoriteColorWellCell canPerformAction:withSender:] ea=0x10002dc20 end=0x10002dce5
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {return action==@selector(delete:)&&self.deletionHandler!=nil;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker21FavoriteColorWellCell delete:] ea=0x10002dcf0 end=0x10002dda1
- (void)delete:(id)sender {if(self.deletionHandler)self.deletionHandler();}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker21FavoriteColorWellCell accessibilityLabel] ea=0x10002ddd0 end=0x10002de6f
- (NSString *)accessibilityLabel {
    return UIColorPickerAXColorStringForColor(self.color.UIColor,1);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10002DEC0 ea=0x10002dec0 end=0x10002df58
- (UIAccessibilityTraits)accessibilityTraits {return UIAccessibilityTraitButton|(self.selected?UIAccessibilityTraitSelected:0);}
@end
@interface UIColorPickerNativeAddCell : UICollectionViewCell
@property(nonatomic,strong) CAShapeLayer *swatchMaskLayer;
@property(nonatomic,strong) CAShapeLayer *plusLayer;
- (void)configureViews;
@end
@implementation UIColorPickerNativeAddCell
// BINMAP-ADAPT: id=native-favorites-uikit-03
- (instancetype)initWithFrame:(CGRect)frame {if((self=[super initWithFrame:frame])){_swatchMaskLayer=[CAShapeLayer layer];_plusLayer=[CAShapeLayer layer];[self configureViews];}return self;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000245F0 ea=0x1000245f0 end=0x1000249eb
- (void)configureViews {self.contentView.backgroundColor=[UIColor colorWithWhite:.85 alpha:1];self.swatchMaskLayer.fillColor=UIColor.blackColor.CGColor;self.contentView.layer.mask=self.swatchMaskLayer;self.plusLayer.fillColor=nil;self.plusLayer.strokeColor=[UIColor colorWithWhite:.29 alpha:1].CGColor;self.plusLayer.lineWidth=2.5;self.plusLayer.lineCap=kCALineCapRound;[self.contentView.layer addSublayer:self.plusLayer];self.isAccessibilityElement=YES;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000249F0 ea=0x1000249f0 end=0x100024b61
- (void)layoutSubviews {[super layoutSubviews];CGFloat diameter=MIN(CGRectGetWidth(self.bounds),CGRectGetHeight(self.bounds));CGRect circle=CGRectMake(0,0,diameter,diameter);self.swatchMaskLayer.frame=circle;self.swatchMaskLayer.path=[UIBezierPath bezierPathWithOvalInRect:circle].CGPath;self.plusLayer.frame=self.bounds;CGPoint center=CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds));UIBezierPath *plus=[UIBezierPath bezierPath];[plus moveToPoint:CGPointMake(center.x-7,center.y)];[plus addLineToPoint:CGPointMake(center.x+7,center.y)];[plus moveToPoint:CGPointMake(center.x,center.y-7)];[plus addLineToPoint:CGPointMake(center.x,center.y+7)];self.plusLayer.path=plus.CGPath;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker12AddColorCell accessibilityLabel] ea=0x100024bc0 end=0x100024c3b
- (NSString *)accessibilityLabel {return [UIColorPanelAppearance localizedString:@"Add selected color to favorites"];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtC27com_apple_UIKit_ColorPicker12AddColorCell accessibilityTraits] ea=0x100024c50 end=0x100024c7a
- (UIAccessibilityTraits)accessibilityTraits {return UIAccessibilityTraitButton;}
@end
@interface UIColorPickerSwatchesView () <UICollectionViewDataSource,UICollectionViewDelegate,UIDragInteractionDelegate,UIDropInteractionDelegate,UIContextMenuInteractionDelegate> {
    NSUInteger _dropGeneration;
    BOOL _writingFavoritesStore;
    BOOL _nativeDefaultsInitialized;
    BOOL _refreshingFavoritesRecord;
    id _loadedFavoritesRecord;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    NSArray *_lastSystemSlots;
#endif
}
@property(nonatomic,strong,readwrite) UICollectionView *collectionView;
@property(nonatomic,strong,readwrite) UIColorPanelFavoriteSwatchLayout *favoriteLayout;
@property(nonatomic,strong,readwrite) UIFavoriteColorsStore *favoriteStore;
@property(nonatomic,copy) NSArray<UIColorValue *> *savedColors;
@property(nonatomic,copy) NSArray<NSNumber *> *savedColorsStoreIndexes;
@property(nonatomic,strong) NSMutableDictionary<NSString *,id> *unrestoredSlotRecords;
@property(nonatomic,strong) UILongPressGestureRecognizer *nativeDeleteGesture;
@property(nonatomic,strong) UILongPressGestureRecognizer *managerMenuGesture;
@property(nonatomic,strong) id<UIInteraction> managerMenuInteraction;
@property(nonatomic,strong) UIDragInteraction *managerDragInteraction;
@property(nonatomic,strong) UIDropInteraction *managerDropInteraction;
- (void)updateNativeSelection;
- (void)updateCurrentColorActions;
- (BOOL)canWriteFavorites;
- (id)repairDefaultsRecord:(id)record;
- (void)writeDefaultsRecord:(NSDictionary *)record;
- (void)deleteNativeFavoriteAtSlot:(NSUInteger)slot;
- (void)seedNativeFavorites;
- (BOOL)persistSlots;
- (void)loadSlotsFromRecord:(id)saved initializeIfMissing:(BOOL)initialize;
@end
@implementation UIColorPickerSwatchesView
@synthesize savedColors=_savedColors;
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-83A1E592F9C1  UIColorPickerSwatchesView.initWithFrame: — public UIKit facade, local backing and drag/menu/AX imports; native logical coordinates are uniformly scaled by the canvas.
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        _logicalScale=1;_supportsAlpha=YES;_currentColor=[[UIColorValue alloc]initWithCGColor:UIColor.blackColor.CGColor];_savedColors=@[];_savedColorsStoreIndexes=@[];_unrestoredSlotRecords=[NSMutableDictionary new];
        _favoriteStore=[UIFavoriteColorsStore new];__weak typeof(self) weakSelf=self;_favoriteStore.backingAllowsEditing=^BOOL {typeof(self) owner=weakSelf;return !owner||[owner canWriteFavorites];};_favoriteStore.backingWriter=^(NSArray *colors){[weakSelf persistSlots];};
        _favoriteLayout=[UIColorPanelFavoriteSwatchLayout new];_favoriteLayout.itemSize=CGSizeMake(13,13);_favoriteLayout.itemSpacing=1;_favoriteLayout.sectionInset=UIEdgeInsetsMake(8,10,8,10);
        _collectionView=[[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:_favoriteLayout];_collectionView.backgroundColor=UIColor.clearColor;_collectionView.dataSource=self;_collectionView.delegate=self;_collectionView.alwaysBounceHorizontal=NO;_collectionView.alwaysBounceVertical=NO;_collectionView.showsHorizontalScrollIndicator=NO;_collectionView.showsVerticalScrollIndicator=YES;_collectionView.clipsToBounds=YES;_collectionView.accessibilityIdentifier=@"ui.saved.favorites";
        [_collectionView registerClass:UIColorPanelFavoriteSwatchView.class forCellWithReuseIdentifier:@"favoriteSwatch"];[self addSubview:_collectionView];
        [_collectionView registerClass:UIColorPickerNativeFavoriteCell.class forCellWithReuseIdentifier:@"nativeFavorite"];[_collectionView registerClass:UIColorPickerNativeAddCell.class forCellWithReuseIdentifier:@"nativeAdd"];
        _nativeDeleteGesture=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showNativeDeleteCallout:)];_nativeDeleteGesture.enabled=NO;[_collectionView addGestureRecognizer:_nativeDeleteGesture];
        _managerDragInteraction=[[UIDragInteraction alloc]initWithDelegate:self];_managerDragInteraction.enabled=YES;[_collectionView addInteraction:_managerDragInteraction];_managerDropInteraction=[[UIDropInteraction alloc]initWithDelegate:self];[_collectionView addInteraction:_managerDropInteraction];
        if(@available(iOS 13.0,*)){_managerMenuInteraction=[[UIContextMenuInteraction alloc]initWithDelegate:self];[_collectionView addInteraction:_managerMenuInteraction];}
        else {_managerMenuGesture=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showContextMenu:)];[_collectionView addGestureRecognizer:_managerMenuGesture];}
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_favoritesDidChange:) name:UIFavoriteColorsDidChangeNotification object:_favoriteStore];[self reloadSlots];
    }return self;
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-C0745D84987E  UIColorPickerSwatchesView.dealloc — UIKit facade observer ownership.
- (void)dealloc {[NSNotificationCenter.defaultCenter removeObserver:self];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-87DD80BF261E  UIColorPickerSwatchesView.intrinsicContentSize — existing manager48; native picker88 accommodates two30pt rows with18pt spacing.
- (CGSize)intrinsicContentSize {return CGSizeMake(UIViewNoIntrinsicMetric,(self.usesNativePickerPresentation?88:48)*self.logicalScale);}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-1258BEE78FC8  UIColorPickerSwatchesView.layoutSubviews — transform the complete native collection once; no mixed13/44 cell dimensions.
- (void)layoutSubviews {[super layoutSubviews];CGFloat scale=self.logicalScale;self.collectionView.transform=CGAffineTransformIdentity;CGRect bounds=self.collectionView.bounds;bounds.size=CGSizeMake(self.bounds.size.width/scale,self.bounds.size.height/scale);self.collectionView.bounds=bounds;self.collectionView.center=CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds));self.collectionView.transform=CGAffineTransformMakeScale(scale,scale);[self.favoriteLayout invalidateLayout];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-DD8DACBC8A8C  UIColorPickerSwatchesView.setLogicalScale: — explicit coherent host scale bridge.
- (void)setLogicalScale:(CGFloat)scale {if(!isfinite(scale)||scale<=0||scale==_logicalScale)return;_logicalScale=scale;[self invalidateIntrinsicContentSize];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPickerSwatchesView.setUsesCircularManagerPresentation: manifest=reimpl/polish_appearance_extras.json
- (void)setUsesCircularManagerPresentation:(BOOL)circular {
    if(_usesCircularManagerPresentation==circular)return;_usesCircularManagerPresentation=circular;
    for(UICollectionViewCell *cell in self.collectionView.visibleCells)if([cell isKindOfClass:UIColorPanelFavoriteSwatchView.class])((UIColorPanelFavoriteSwatchView *)cell).usesCircularPresentation=circular;
}
// BINMAP-ADAPT: id=native-favorites-uikit-04
- (void)setUsesNativePickerPresentation:(BOOL)native {
    if(_usesNativePickerPresentation==native)return;[self cancelPendingDrops];NSIndexPath *managerSelection=nil;
    if(!native){NSArray<NSIndexPath *> *selected=[self.collectionView.indexPathsForSelectedItems sortedArrayUsingSelector:@selector(compare:)];managerSelection=selected.firstObject;for(NSIndexPath *index in selected)[self.collectionView deselectItemAtIndexPath:index animated:NO];}
    _usesNativePickerPresentation=native;self.favoriteLayout.nativePickerPresentation=native;
    if(native)_usesNativeDefaultColors=YES; // Opening the manager keeps the same library.
    if(native&&!_nativeDefaultsInitialized&&!self.favoriteStore.colors.count)[self seedNativeFavorites];
    CGFloat size=native?(self.nativeLandscapeLayout?28:30):13;self.favoriteLayout.itemSize=CGSizeMake(size,size);self.favoriteLayout.itemSpacing=native?(self.nativeLandscapeLayout?16:18):1;self.favoriteLayout.sectionInset=native?UIEdgeInsetsZero:UIEdgeInsetsMake(8,10,8,10);
    self.collectionView.allowsMultipleSelection=native;self.collectionView.prefetchingEnabled=!native;self.collectionView.showsVerticalScrollIndicator=!native;self.collectionView.decelerationRate=native?UIScrollViewDecelerationRateFast:UIScrollViewDecelerationRateNormal;self.collectionView.accessibilityLabel=native?[UIColorPanelAppearance localizedString:@"Favorites"]:nil;self.nativeDeleteGesture.enabled=native;self.managerMenuGesture.enabled=!native;
    if(self.managerMenuInteraction){if(native)[self.collectionView removeInteraction:self.managerMenuInteraction];else [self.collectionView addInteraction:self.managerMenuInteraction];}
    // Native makeUIView (0x10001e150) installs only the Delete long press.
    // A collection-wide drag lifts the whole palette and competes with it.
    if(native){[self.collectionView removeInteraction:self.managerDragInteraction];[self.collectionView removeInteraction:self.managerDropInteraction];}
    else {[self.collectionView addInteraction:self.managerDragInteraction];[self.collectionView addInteraction:self.managerDropInteraction];}
    self.collectionView.contentOffset=CGPointZero;[self.collectionView reloadData];if(native)[self updateNativeSelection];else if(self.presentedColors.count){NSIndexPath *index=managerSelection&&managerSelection.item<(NSInteger)self.presentedColors.count?managerSelection:[NSIndexPath indexPathForItem:0 inSection:0];[self.collectionView selectItemAtIndexPath:index animated:NO scrollPosition:UICollectionViewScrollPositionNone];}[self.favoriteLayout invalidateLayout];[self invalidateIntrinsicContentSize];[self setNeedsLayout];
}
// BINMAP-ADAPT: id=native-favorites-uikit-05
- (void)setNativeLandscapeLayout:(BOOL)landscape {if(_nativeLandscapeLayout==landscape)return;_nativeLandscapeLayout=landscape;if(self.usesNativePickerPresentation){CGFloat size=landscape?28:30;self.favoriteLayout.itemSize=CGSizeMake(size,size);self.favoriteLayout.itemSpacing=landscape?16:18;self.collectionView.contentOffset=CGPointZero;[self.favoriteLayout invalidateLayout];[self setNeedsLayout];}}
// BINMAP-ADAPT: id=native-favorites-uikit-06
- (void)setCurrentColor:(UIColorValue *)color {_currentColor=color;if(self.usesNativePickerPresentation)[self updateNativeSelection];}
// BINMAP-ADAPT: id=native-favorites-uikit-07
- (void)updateNativeSelection {
    for(NSIndexPath *index in [self.collectionView.indexPathsForSelectedItems copy])[self.collectionView deselectItemAtIndexPath:index animated:NO];
    NSArray<UIColorValue *> *colors=self.presentedColors;for(NSUInteger index=0;index<colors.count;index++)if(UIColorPickerNativeFavoriteColorsEqual(colors[index],self.currentColor))[self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}
// BINMAP-ADAPT: id=native-favorites-uikit-08
- (void)setManagementHandler:(void (^)(void))handler {_managementHandler=[handler copy];[self.collectionView reloadData];if(self.usesNativePickerPresentation)[self updateNativeSelection];}
// BINMAP-ADAPT: id=native-favorites-uikit-09
- (BOOL)accessibilityManageFavorites:(UIAccessibilityCustomAction *)action {if(!self.managementHandler)return NO;self.managementHandler();return YES;}
// BINMAP-ADAPT: id=native-favorites-uikit-10
- (void)setFavoritesStore:(UIColorPickerFavoritesStore *)store {
    if(store==_favoritesStore)return;[NSNotificationCenter.defaultCenter removeObserver:self name:UIColorPickerFavoritesStoreDidChangeNotification object:nil];[self cancelPendingDrops];_favoritesStore=store;
    if(store)[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(sharedFavoritesDidChange:) name:UIColorPickerFavoritesStoreDidChangeNotification object:nil];[self loadSlots];
}
// BINMAP-ADAPT: id=native-favorites-uikit-11
- (void)sharedFavoritesDidChange:(NSNotification *)notification {
    if(!NSThread.isMainThread){__weak typeof(self) weakSelf=self;dispatch_async(dispatch_get_main_queue(),^{[weakSelf sharedFavoritesDidChange:notification];});return;}
    if(_writingFavoritesStore||!self.favoritesStore)return;UIColorPickerFavoritesStore *changed=notification.object;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(changed.isSystemPickerStore!=self.favoritesStore.isSystemPickerStore)return;
#endif
    if(![changed.key isEqualToString:self.favoritesStore.key])return;NSString *group=changed.appGroupIdentifier,*ownGroup=self.favoritesStore.appGroupIdentifier;if(group!=ownGroup&&![group isEqualToString:ownGroup])return;
    [self refreshFavorites];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-055E1C60578D  UIColorPickerSwatchesView.setCurrentColorSourceView: — attach public current-well drag and accessibility save/copy without another visible toolbar row.
- (void)setCurrentColorSourceView:(UIView *)view {
    if(view==_currentColorSourceView)return;UIView *old=_currentColorSourceView;for(id<UIInteraction> interaction in old.interactions)if([interaction isKindOfClass:UIDragInteraction.class]&&[(UIDragInteraction *)interaction delegate]==self)[old removeInteraction:interaction];
    NSMutableArray *oldActions=[old.accessibilityCustomActions mutableCopy];for(id action in [oldActions copy])if([action isKindOfClass:UIColorPickerSwatchAction.class])[oldActions removeObject:action];old.accessibilityCustomActions=oldActions;
    _currentColorSourceView=view;
    if(view){UIDragInteraction *drag=[[UIDragInteraction alloc]initWithDelegate:self];drag.enabled=YES;[view addInteraction:drag];[self updateCurrentColorActions];}
}
// BINMAP-ADAPT: UIColorPickerSwatchesView.updateCurrentColorActions manifest=reimpl/favorites_swatches_refresh_extras.json
- (void)updateCurrentColorActions {
    UIView *view=self.currentColorSourceView;
    if(!view)return;
    NSMutableArray *actions=[view.accessibilityCustomActions mutableCopy]?:[NSMutableArray new];
    for(id action in [actions copy])if([action isKindOfClass:UIColorPickerSwatchAction.class])[actions removeObject:action];
    if(self.favoritesEditable)[actions addObject:[[UIColorPickerSwatchAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Save Current Color"] target:self selector:@selector(accessibilitySaveCurrentColor:)]];
    UIColorPickerSwatchAction *copy=[[UIColorPickerSwatchAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Copy Color"] target:self selector:@selector(accessibilityCopy:)];
    copy.slot=NSNotFound;[actions addObject:copy];view.accessibilityCustomActions=actions;
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-AC3A29194F8C  UIColorPickerSwatchesView.slots — backward-compatible backing-index snapshot; empty marker is not a transparent saved color.
- (NSArray *)slots {return self.favoriteStore.colors;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-6498ED6DE7FC  UIColorPickerSwatchesView.colorAtIndex:
- (UIColorValue *)colorAtIndex:(NSUInteger)index {NSArray *values=self.favoriteStore.colors;return index<values.count&&[values[index]isKindOfClass:UIColorValue.class]?values[index]:nil;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-25D81985376A  UIColorPickerSwatchesView.setColor:forSlot: — indexed API compatibility keeps holes and extends beyond20 without reindexing existing values.
- (void)setColor:(UIColorValue *)color forSlot:(NSUInteger)index {
    if(index>=NSIntegerMax||![self canWriteFavorites])return;if(color&&(self.favoritesStore||self.persistenceKey.length)&&![color propertyListRepresentationWithError:nil]){UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"This color cannot be saved."]);return;}
    NSMutableArray *values=[self.favoriteStore.colors mutableCopy];while(values.count<=index)[values addObject:NSNull.null];values[index]=color?:NSNull.null;[self.unrestoredSlotRecords removeObjectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)index]];self.favoriteStore.colorEntries=values;[self persistSlots];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-28C90BF43BA6  UIColorPickerSwatchesView.saveCurrentColor — public mobile AX adapter to native append semantics, without a visible Save button or empty-decoration tap action.
- (BOOL)saveCurrentColor {
    if(![self canWriteFavorites])return NO;
    if((self.favoritesStore||self.persistenceKey.length)&&![self.currentColor propertyListRepresentationWithError:nil]){
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"This color cannot be saved."]);
        return NO;
    }
    [self.favoriteStore addColor:self.currentColor];
    return [self persistSlots];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-B78E03FE2711  UIColorPickerSwatchesView.setPersistenceKey:
- (void)setPersistenceKey:(NSString *)key {[self cancelPendingDrops];_persistenceKey=[key copy];[self loadSlots];}
// BINMAP-ADAPT: UIColorPickerSwatchesView.cancelPendingDrops manifest=reimpl/ui_ux_repairs_extras.json
- (void)cancelPendingDrops {++_dropGeneration;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100026140 ea=0x100026140 end=0x10002667e
- (void)seedNativeFavorites {
    _nativeDefaultsInitialized=YES;
    NSDictionary *slots=UIColorPickerDefaultFavoritesRecord()[@"slots"];
    NSMutableArray *colors=[NSMutableArray arrayWithCapacity:slots.count];
    for(NSUInteger index=0;index<slots.count;index++){
        UIColorValue *color=[[UIColorValue alloc]initWithPropertyList:slots[@(index).stringValue] error:nil];
        [colors addObject:color];
    }
    [self.favoriteStore updatingFromBacking:^{self.favoriteStore.colorEntries=colors;}];[self reloadSlots];[self persistSlots];
}
// BINMAP-ADAPT: id=native-favorites-uikit-supports-alpha manifest=reimpl/native_favorites_chrome_api_manifest.json
- (void)setSupportsAlpha:(BOOL)supportsAlpha {
    if(_supportsAlpha==supportsAlpha)return;_supportsAlpha=supportsAlpha;
    [self.collectionView selectItemAtIndexPath:nil animated:NO scrollPosition:UICollectionViewScrollPositionNone];[self reloadSlots];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-EC722C8462C4  UIColorPickerSwatchesView.loadSlots — version1 sparse dictionary and legacy array transport; preserve undecodable records for later compatible systems.
- (void)loadSlots {
    id saved=self.favoritesStore?[self.favoritesStore readRecord]:(self.persistenceKey.length?[NSUserDefaults.standardUserDefaults objectForKey:self.persistenceKey]:nil);
    [self loadSlotsFromRecord:[self repairDefaultsRecord:saved] initializeIfMissing:YES];
}
// BINMAP-ADAPT: UIColorPickerSwatchesView.refreshFavorites manifest=reimpl/favorites_swatches_refresh_extras.json
- (void)refreshFavorites {
    if(!self.favoritesStore&&!self.persistenceKey.length)return;
    id saved=self.favoritesStore?[self.favoritesStore readRecord]:[NSUserDefaults.standardUserDefaults objectForKey:self.persistenceKey];
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(self.favoritesStore.isSystemPickerStore && saved==NSNull.null)return;
#endif
    if(saved==_loadedFavoritesRecord)return;
    saved=[self repairDefaultsRecord:saved];
    if([saved isEqual:_loadedFavoritesRecord])return;
    [self loadSlotsFromRecord:saved initializeIfMissing:NO];
}
// BINMAP-ADAPT: UIColorPickerSwatchesView.loadSlotsFromRecord:initializeIfMissing: manifest=reimpl/favorites_swatches_refresh_extras.json
- (void)loadSlotsFromRecord:(id)saved initializeIfMissing:(BOOL)initialize {
    BOOL editable=UIColorPickerFavoritesRecordIsEditable(saved);
    BOOL editabilityChanged=editable!=self.favoritesEditable;
    self.favoriteStore.backingReadOnly=!editable;
    if(editabilityChanged)[self updateCurrentColorActions];
    _loadedFavoritesRecord=saved;
    [self.unrestoredSlotRecords removeAllObjects];
    if(initialize&&self.usesNativePickerPresentation&&!saved){
#if UICOLORPANEL_ENABLE_PRIVATE_API
        _lastSystemSlots=self.favoritesStore.isSystemPickerStore ? @[] : nil;
#endif
        [self seedNativeFavorites];return;
    }
    NSMutableArray *values=[NSMutableArray new];
    if(editable&&[saved isKindOfClass:NSDictionary.class]){
        NSDictionary *records=saved[@"slots"];for(id key in records){NSUInteger index=UIColorPickerFavoriteSlotIndex(key);if(index==NSNotFound)continue;while(values.count<=index)[values addObject:NSNull.null];UIColorValue *color=[[UIColorValue alloc]initWithPropertyList:records[key] error:nil];if(color)values[index]=color;else self.unrestoredSlotRecords[key]=records[key];}
    }else if([saved isKindOfClass:NSArray.class]){for(NSUInteger index=0;index<[saved count];index++){UIColorValue *color=[[UIColorValue alloc]initWithPropertyList:saved[index] error:nil];[values addObject:color?:NSNull.null];if(!color&&saved[index]!=NSNull.null)self.unrestoredSlotRecords[[NSString stringWithFormat:@"%lu",(unsigned long)index]]=saved[index];}}
    BOOL entriesChanged=![self.favoriteStore.colors isEqualToArray:values];
    if(initialize&&entriesChanged)
        for(NSIndexPath *index in self.collectionView.indexPathsForSelectedItems)
            [self.collectionView deselectItemAtIndexPath:index animated:NO];
    BOOL wasRefreshing=_refreshingFavoritesRecord;
    _refreshingFavoritesRecord=!initialize;
    [self.favoriteStore updatingFromBacking:^{self.favoriteStore.colorEntries=values;}];
    if(editabilityChanged&&!entriesChanged){
        // No model notification is sent when both records present the same entries.
        [self reloadSlots];
        if([self.delegate respondsToSelector:@selector(colorPickerSwatchesDidChangeSlots:)])[self.delegate colorPickerSwatchesDidChangeSlots:self];
    }
    _refreshingFavoritesRecord=wasRefreshing;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    _lastSystemSlots=self.favoritesStore.isSystemPickerStore ? self.favoriteStore.colors : nil;
#endif
    // An absent record on refresh is an external removal. Only a newly
    // configured backing can be eligible for default seeding.
    _nativeDefaultsInitialized=!initialize||saved!=nil;
}
// BINMAP-ADAPT: UIColorPickerSwatchesView.repairDefaultsRecord: manifest=reimpl/favorites_swatches_refresh_extras.json
- (id)repairDefaultsRecord:(id)saved {
    if (!saved) return nil;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if (self.favoritesStore.isSystemPickerStore) return saved;
#endif
    NSDictionary *replacement = nil;
    if ([saved isKindOfClass:NSArray.class]) {
        NSArray *legacy = saved;
        NSUInteger badIndex = [legacy indexOfObjectPassingTest:^BOOL(id value, NSUInteger index, BOOL *stop) {
            return value != NSNull.null && UIColorPickerFavoriteSlotIsCorrupt(value);
        }];
        if (badIndex == NSNotFound) return saved;
        NSMutableDictionary *slots = [NSMutableDictionary dictionary];
        [legacy enumerateObjectsUsingBlock:^(id value, NSUInteger index, BOOL *stop) {
            if (value != NSNull.null && !UIColorPickerFavoriteSlotIsCorrupt(value)) slots[@(index).stringValue] = value;
        }];
        replacement = @{@"version": @1, @"slots": slots};
    } else {
        NSDictionary *library = [saved isKindOfClass:NSDictionary.class] ? saved : nil;
        NSNumber *version = library[@"version"];
        BOOL versionNumber = [version isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)version) != CFBooleanGetTypeID();
        if (versionNumber && version.doubleValue > 1 && isfinite(version.doubleValue) && floor(version.doubleValue) == version.doubleValue) return saved;
        NSDictionary *slots = library[@"slots"];
        if (versionNumber && [version isEqual:@1] && [slots isKindOfClass:NSDictionary.class]) {
            NSMutableDictionary *cleanSlots = nil;
            for (NSString *key in slots) {
                if (UIColorPickerFavoriteSlotIndex(key) != NSNotFound && !UIColorPickerFavoriteSlotIsCorrupt(slots[key])) continue;
                if (!cleanSlots) cleanSlots = [slots mutableCopy];
                [cleanSlots removeObjectForKey:key];
            }
            if (!cleanSlots) return saved;
            NSMutableDictionary *cleanLibrary = [library mutableCopy];
            cleanLibrary[@"slots"] = cleanSlots;
            replacement = cleanLibrary;
        } else {
            replacement = _usesNativeDefaultColors ? UIColorPickerDefaultFavoritesRecord() : @{@"version": @1, @"slots": @{}};
        }
    }
    [self cancelPendingDrops];
    [self writeDefaultsRecord:replacement];
    return replacement;
}
// BINMAP-ADAPT: UIColorPickerSwatchesView.writeDefaultsRecord: manifest=reimpl/favorites_swatches_refresh_extras.json
- (void)writeDefaultsRecord:(NSDictionary *)record {
    if (self.favoritesStore) {
        _writingFavoritesStore = YES;
        [self.favoritesStore writeRecord:record];
        _writingFavoritesStore = NO;
    } else {
        [NSUserDefaults.standardUserDefaults setObject:record forKey:self.persistenceKey];
    }
}
// BINMAP-ADAPT: UIColorPickerSwatchesView.favoritesEditable manifest=reimpl/favorites_swatches_refresh_extras.json
- (BOOL)favoritesEditable {return !self.favoriteStore.backingReadOnly;}
// BINMAP-ADAPT: UIColorPickerSwatchesView.canWriteFavorites manifest=reimpl/favorites_swatches_refresh_extras.json
- (BOOL)canWriteFavorites {
    if(!self.favoritesEditable)return NO;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    // The file writer compares its original native snapshot; rereading here would replace it.
    if(self.favoritesStore.isSystemPickerStore)return YES;
#endif
    id current=self.favoritesStore?[self.favoritesStore readRecord]:(self.persistenceKey.length?[NSUserDefaults.standardUserDefaults objectForKey:self.persistenceKey]:nil);
    if(current==_loadedFavoritesRecord)return YES;
    id repaired=[self repairDefaultsRecord:current];
    if(repaired!=current){
        [self loadSlotsFromRecord:repaired initializeIfMissing:NO];
        return NO; // A pending edit still refers to the pre-repair indices.
    }
    if(UIColorPickerFavoritesRecordIsEditable(current))return YES;
    [self loadSlotsFromRecord:current initializeIfMissing:NO];
    return NO;
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-3ABEC37F70B1  UIColorPickerSwatchesView.persistSlots — preserve every sparse backing index and unsupported serialized record, with no20-item truncation.
- (BOOL)persistSlots {
    if(!self.favoritesStore && !self.persistenceKey.length) return YES;
    NSMutableDictionary *records = [self.unrestoredSlotRecords mutableCopy];
    NSArray *values = self.favoriteStore.colors;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    BOOL systemStore = self.favoritesStore.isSystemPickerStore;
    BOOL representable = YES;
#endif
    for(NSUInteger index = 0; index < values.count; index++) {
        UIColorValue *color = [self colorAtIndex:index];
        if(!color) continue;
        NSDictionary *value = [color propertyListRepresentationWithError:nil];
        NSUInteger slot = index;
#if UICOLORPANEL_ENABLE_PRIVATE_API
        if(systemStore) {
            if(!value) { representable = NO; break; }
            // The native list is dense. Keep sparse indices for this view's indexed editing API.
            slot = records.count;
        }
#endif
        if(value) records[@(slot).stringValue] = value;
    }
    NSDictionary *record = @{@"version": @1, @"slots": records};
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(systemStore) {
        if(representable && [record isEqual:_loadedFavoritesRecord]) {
            _lastSystemSlots = values;
            return YES;
        }
        _writingFavoritesStore = YES;
        BOOL saved = representable && [self.favoritesStore tryWriteRecord:record];
        _writingFavoritesStore = NO;
        if(!saved) {
            id latest = [self.favoritesStore readRecord];
            if(latest == NSNull.null || latest == _loadedFavoritesRecord || [latest isEqual:_loadedFavoritesRecord]) {
                // Preserve backing indices, including holes not represented in the native file.
                [self.favoriteStore updatingFromBacking:^{ self.favoriteStore.colorEntries = self->_lastSystemSlots; }];
            } else {
                [self loadSlotsFromRecord:latest initializeIfMissing:NO];
            }
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"This color cannot be saved."]);
            return NO;
        }
        _loadedFavoritesRecord = record;
        _lastSystemSlots = values;
        return YES;
    }
#endif
    if(![self canWriteFavorites]) return NO;
    if([record isEqual:_loadedFavoritesRecord]) return YES;
    _loadedFavoritesRecord = record;
    [self writeDefaultsRecord:record];
    return YES;
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-103791BC03D4  UIColorPickerSwatchesView.reloadSlots
- (void)reloadSlots {[self _favoritesDidChange:nil];}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList savedColors] ea=0x184047614 end=0x184047624
- (NSArray<UIColorValue *> *)savedColors {return _savedColors;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList setSavedColors:] ea=0x184047624 end=0x184047678
- (void)setSavedColors:(NSArray<UIColorValue *> *)colors {if(![_savedColors isEqualToArray:colors])_savedColors=[colors copy];}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList presentedColors] ea=0x1840471e4 end=0x1840471e8
- (NSArray<UIColorValue *> *)presentedColors {return self.savedColors;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList storeIndexForColorIndex:] ea=0x184047874 end=0x1840478f4
- (NSInteger)storeIndexForColorIndex:(NSInteger)index {if(self.savedColorsStoreIndexes.count==(NSUInteger)index)return self.savedColorsStoreIndexes.lastObject.integerValue+1;return self.savedColorsStoreIndexes[index].integerValue;}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList _favoritesDidChange:] ea=0x184047728 end=0x184047874
- (void)_favoritesDidChange:(NSNotification *)notification {
    if(notification)_nativeDefaultsInitialized=YES;
    // BINMAP-ADAPT: a changed list invalidates pending UIKit provider positions;
    // the recovered sparse-store presentation and selection mapping remain below.
    [self cancelPendingDrops];
    NSArray<NSNumber *> *indexes=nil;NSArray *colors=UIColorPanelPresentedFavoriteColors(self.favoriteStore.colors,&indexes);
    if(!self.supportsAlpha){NSMutableArray *opaqueColors=[NSMutableArray new],*opaqueIndexes=[NSMutableArray new];for(NSUInteger index=0;index<colors.count;index++)if(CGColorGetAlpha([colors[index] CGColor])==1){[opaqueColors addObject:colors[index]];[opaqueIndexes addObject:indexes[index]];}colors=opaqueColors;indexes=opaqueIndexes;}
    NSUInteger oldCount=self.savedColors.count;self.savedColorsStoreIndexes=indexes;self.savedColors=colors;NSArray *selection=[self.collectionView.indexPathsForSelectedItems copy];
    // A manager row may now refer to another slot. Clear its selection before
    // reloading so a pending Delete or Copy cannot act on the new occupant.
    if(_refreshingFavoritesRecord&&!self.usesNativePickerPresentation)
        for(NSIndexPath *index in selection)[self.collectionView deselectItemAtIndexPath:index animated:NO];
    [self.collectionView reloadData];
    if(self.usesNativePickerPresentation)[self updateNativeSelection];
    else if(!_refreshingFavoritesRecord){
        if((selection.count||!self.savedColors.count)&&(oldCount||!self.savedColors.count)){if(self.savedColors.count){for(NSIndexPath *index in selection)if(index.item<(NSInteger)self.savedColors.count)[self.collectionView selectItemAtIndexPath:index animated:NO scrollPosition:UICollectionViewScrollPositionNone];}else[self.collectionView selectItemAtIndexPath:nil animated:NO scrollPosition:UICollectionViewScrollPositionNone];}
        else [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    if(notification&&[self.delegate respondsToSelector:@selector(colorPickerSwatchesDidChangeSlots:)])[self.delegate colorPickerSwatchesDidChangeSlots:self];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList collectionView:numberOfItemsInSection:] ea=0x1840471e8 end=0x184047210
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {return self.presentedColors.count+(self.usesNativePickerPresentation&&self.favoritesEditable?1:0);}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-85F6195E651B  UIColorPickerSwatchesView.collectionView:cellForItemAtIndexPath: — UIKit reusable views and named AX routes, not stored empty colors.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(self.usesNativePickerPresentation){
        if(indexPath.item==(NSInteger)self.presentedColors.count){UIColorPickerNativeAddCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"nativeAdd" forIndexPath:indexPath];cell.accessibilityIdentifier=@"ui.saved.add";cell.accessibilityCustomActions=self.managementHandler?@[[[UIAccessibilityCustomAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Manage Saved Colors"] target:self selector:@selector(accessibilityManageFavorites:)]]:nil;return cell;}
        NSUInteger slot=[self storeIndexForColorIndex:indexPath.item];UIColorPickerNativeFavoriteCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"nativeFavorite" forIndexPath:indexPath];cell.color=self.presentedColors[indexPath.item];cell.accessibilityIdentifier=[NSString stringWithFormat:@"ui.saved.slot.%lu",(unsigned long)slot];
        __weak typeof(self) weakSelf=self;
        // BINMAP-BLOCK: invoke_ea=0x100024100 parent_ea=0x10001e7f0 reconstructed_as=block_literal; backing slot replaces Swift diffable occurrence identity.
        cell.deletionHandler=^{[weakSelf deleteNativeFavoriteAtSlot:slot];};
        UIColorPickerSwatchAction *delete=[[UIColorPickerSwatchAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Delete Color"] target:self selector:@selector(accessibilityClear:)];delete.slot=slot;NSMutableArray *actions=[NSMutableArray arrayWithObject:delete];if(self.managementHandler)[actions addObject:[[UIAccessibilityCustomAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Manage Saved Colors"] target:self selector:@selector(accessibilityManageFavorites:)]];cell.accessibilityCustomActions=actions;return cell;
    }
    UIColorPanelFavoriteSwatchView *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"favoriteSwatch" forIndexPath:indexPath];NSUInteger storeIndex=[self storeIndexForColorIndex:indexPath.item];cell.usesCircularPresentation=self.usesCircularManagerPresentation;cell.color=self.presentedColors[indexPath.item];cell.isAccessibilityElement=YES;cell.accessibilityIdentifier=[NSString stringWithFormat:@"ui.saved.slot.%lu",(unsigned long)storeIndex];cell.accessibilityLabel=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Saved Color %lu"],(unsigned long)indexPath.item+1];cell.accessibilityHint=[UIColorPanelAppearance localizedString:@"Choose this color. Use actions to replace, copy or delete it."];cell.accessibilityTraits=UIAccessibilityTraitButton|(cell.selected?UIAccessibilityTraitSelected:0);cell.accessibilityValue=UIColorPickerAXColorStringForColor(cell.color.UIColor,1);
    NSMutableArray *actions=[NSMutableArray new];for(NSDictionary *spec in @[@{@"name":@"Replace with Current Color",@"selector":NSStringFromSelector(@selector(accessibilityReplace:))},@{@"name":@"Delete Color",@"selector":NSStringFromSelector(@selector(accessibilityClear:))},@{@"name":[UIColorPanelAppearance localizedString:@"Copy Color"],@"selector":NSStringFromSelector(@selector(accessibilityCopy:))}]){UIColorPickerSwatchAction *action=[[UIColorPickerSwatchAction alloc]initWithName:[UIColorPanelAppearance localizedString:spec[@"name"]] target:self selector:NSSelectorFromString(spec[@"selector"])];action.slot=storeIndex;[actions addObject:action];}cell.accessibilityCustomActions=actions;return cell;
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-62C6300B9954  UIColorPickerSwatchesView.collectionView:didSelectItemAtIndexPath:
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(!self.usesNativePickerPresentation){[self _activateSelectedColor];return;}
    if(indexPath.item==(NSInteger)self.presentedColors.count){[collectionView deselectItemAtIndexPath:indexPath animated:NO];[self saveCurrentColor];[self updateNativeSelection];return;}
    UIColorValue *color=self.presentedColors[indexPath.item];self.currentColor=color;[self.delegate colorPickerSwatches:self didSelectColorValue:color];
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=-[_TtCV27com_apple_UIKit_ColorPicker23FavoriteColorPickerView11Coordinator collectionView:shouldDeselectItemAtIndexPath:] ea=0x10001da20 end=0x10001da77
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {return !self.usesNativePickerPresentation;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001EA20 ea=0x10001ea20 end=0x10001eed0
- (void)deleteNativeFavoriteAtSlot:(NSUInteger)slot {if([self colorAtIndex:slot])[self setColor:nil forSlot:slot];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001DA80 ea=0x10001da80 end=0x10001ddbc
- (void)showNativeDeleteCallout:(UILongPressGestureRecognizer *)gesture {
    if(gesture.state!=UIGestureRecognizerStateBegan)return;NSIndexPath *index=[self.collectionView indexPathForItemAtPoint:[gesture locationInView:self.collectionView]];if(!index||index.item>=(NSInteger)self.presentedColors.count)return;
    UICollectionViewCell *cell=[self.collectionView cellForItemAtIndexPath:index];if(!cell)return;[cell becomeFirstResponder];
    if(@available(iOS 13.0,*))[UIMenuController.sharedMenuController showMenuFromView:cell rect:cell.bounds];
    else {[UIMenuController.sharedMenuController setTargetRect:cell.bounds inView:cell];[UIMenuController.sharedMenuController setMenuVisible:YES animated:YES];}
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList _activateSelectedColor] ea=0x184047f10 end=0x184047fac
- (void)_activateSelectedColor {NSIndexPath *selection=self.collectionView.indexPathsForSelectedItems.firstObject;if(selection&&self.delegate){UIColorValue *color=self.presentedColors[selection.item];self.currentColor=color;[self.delegate colorPickerSwatches:self didSelectColorValue:color];}}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList deleteCurrentColorAndSelectPrevious] ea=0x184047910 end=0x184047a6c
- (void)deleteCurrentColorAndSelectPrevious {
    if(![self canWriteFavorites])return;
    NSIndexPath *selection=self.collectionView.indexPathsForSelectedItems.firstObject;if(!selection)return;NSInteger index=selection.item;NSUInteger storeIndex=[self storeIndexForColorIndex:index];[self.unrestoredSlotRecords removeObjectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)storeIndex]];[self.favoriteStore replaceColorAtIndex:storeIndex withColor:NSNull.null];NSUInteger previous=index<=0?0:(NSUInteger)index-1;
    if(![self persistSlots])return;
    if(previous<self.presentedColors.count)[self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:previous inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];else if(!self.presentedColors.count)[self.collectionView selectItemAtIndexPath:nil animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanelFavoritesList deleteCurrentColorAndSelectNext] ea=0x184047a6c end=0x184047bd8
- (void)deleteCurrentColorAndSelectNext {
    if(![self canWriteFavorites])return;
    NSIndexPath *selection=self.collectionView.indexPathsForSelectedItems.firstObject;if(!selection)return;NSInteger index=selection.item;NSUInteger storeIndex=[self storeIndexForColorIndex:index];[self.unrestoredSlotRecords removeObjectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)storeIndex]];[self.favoriteStore replaceColorAtIndex:storeIndex withColor:NSNull.null];NSInteger next=index-(index>=(NSInteger)self.presentedColors.count);
    if(![self persistSlots])return;
    if(next>=0&&next<(NSInteger)self.presentedColors.count)[self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:next inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];else if(!self.presentedColors.count)[self.collectionView selectItemAtIndexPath:nil animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-CF3794A22529  UIColorPickerSwatchesView.clearSelected: — existing compatibility selector routes through native delete-to-marker semantics, with no visible Clear button.
- (void)clearSelected:(id)sender {[self deleteCurrentColorAndSelectPrevious];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-5E5D59D2A818  UIColorPickerSwatchesView.accessibilityClear:
- (BOOL)accessibilityClear:(UIColorPickerSwatchAction *)action {if(![self canWriteFavorites]||![self colorAtIndex:action.slot])return NO;if(self.usesNativePickerPresentation){[self deleteNativeFavoriteAtSlot:action.slot];return YES;}NSUInteger index=[self.savedColorsStoreIndexes indexOfObject:@(action.slot)];if(index==NSNotFound)return NO;[self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];[self deleteCurrentColorAndSelectPrevious];return YES;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-2449034B0F44  UIColorPickerSwatchesView.accessibilityReplace:
- (BOOL)accessibilityReplace:(UIColorPickerSwatchAction *)action {[self setColor:self.currentColor forSlot:action.slot];return [[self colorAtIndex:action.slot] isEqualForColorPanel:self.currentColor];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-C787B07232BE  UIColorPickerSwatchesView.accessibilitySaveCurrentColor:
- (BOOL)accessibilitySaveCurrentColor:(UIAccessibilityCustomAction *)action {return [self saveCurrentColor];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-89809BDF535C  UIColorPickerSwatchesView.accessibilityCopy:
- (BOOL)accessibilityCopy:(UIColorPickerSwatchAction *)action {UIColorValue *color=action.target==self&&[action.name isEqualToString:[UIColorPanelAppearance localizedString:@"Copy Color"]]&&action.slot<self.slots.count?[self colorAtIndex:action.slot]:self.currentColor;if(!color)return NO;NSData *native=[UIColorArchive archivedDataWithColorValue:color error:nil];NSDictionary *record=[color propertyListRepresentationWithError:nil];NSData *exact=record?[NSPropertyListSerialization dataWithPropertyList:record format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil]:nil;NSMutableDictionary *item=[NSMutableDictionary new];if(native)item[@"com.apple.cocoa.pasteboard.color"]=native;if(exact)item[@"org.uicolorpanelkit.color-value"]=exact;if(!item.count)return NO;UIPasteboard.generalPasteboard.items=@[item];return YES;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-B620DCFBA90E  UIColorPickerSwatchesView.showContextMenu: — standard iOS12 edit menu on existing favorites; no new always-visible controls.
- (void)showContextMenu:(UILongPressGestureRecognizer *)gesture {if(self.usesNativePickerPresentation||gesture.state!=UIGestureRecognizerStateBegan)return;CGPoint point=[gesture locationInView:self.collectionView];NSIndexPath *index=[self.collectionView indexPathForItemAtPoint:point];if(index)[self.collectionView selectItemAtIndexPath:index animated:NO scrollPosition:UICollectionViewScrollPositionNone];[self becomeFirstResponder];[UIMenuController.sharedMenuController setTargetRect:index?[self.favoriteLayout layoutAttributesForItemAtIndexPath:index].frame:CGRectMake(point.x,point.y,1,1) inView:self.collectionView];[UIMenuController.sharedMenuController setMenuVisible:YES animated:YES];}
// BINMAP-ADAPT: UIColorPickerSwatchesView.contextMenuInteraction:configurationForMenuAtLocation:
- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0)) {
    if(self.usesNativePickerPresentation)return nil;
    NSIndexPath *index=[self.collectionView indexPathForItemAtPoint:location];
    if(index)[self.collectionView selectItemAtIndexPath:index animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    __weak typeof(self) weakSelf=self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> *suggestedActions){
        UIColorPickerSwatchesView *view=weakSelf;
        if(!view)return nil;
        UIAction *copy=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Copy"] image:nil identifier:nil handler:^(UIAction *action){
            UIColorPickerSwatchesView *target=weakSelf;
            if([target canPerformAction:@selector(copy:) withSender:action])[target copy:action];
        }];
        copy.attributes=[view canPerformAction:@selector(copy:) withSender:copy]?0:UIMenuElementAttributesDisabled;
        UIAction *paste=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Paste"] image:nil identifier:nil handler:^(UIAction *action){
            UIColorPickerSwatchesView *target=weakSelf;
            if([target canPerformAction:@selector(paste:) withSender:action])[target paste:action];
        }];
        paste.attributes=[view canPerformAction:@selector(paste:) withSender:paste]?0:UIMenuElementAttributesDisabled;
        UIAction *delete=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Delete"] image:nil identifier:nil handler:^(UIAction *action){
            UIColorPickerSwatchesView *target=weakSelf;
            if([target canPerformAction:@selector(delete:) withSender:action])[target delete:action];
        }];
        delete.attributes=UIMenuElementAttributesDestructive|([view canPerformAction:@selector(delete:) withSender:delete]?0:UIMenuElementAttributesDisabled);
        return [UIMenu menuWithTitle:@"" children:@[copy,paste,delete]];
    }];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-58C3AC385096  UIColorPickerSwatchesView.canBecomeFirstResponder
- (BOOL)canBecomeFirstResponder {return YES;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-F9A44933F5A4  UIColorPickerSwatchesView.canPerformAction:withSender:
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {if(self.usesNativePickerPresentation||!self.favoritesEditable)return NO;if(action==@selector(delete:)||action==@selector(copy:))return self.collectionView.indexPathsForSelectedItems.count>0;if(action==@selector(paste:))return [UIPasteboard.generalPasteboard containsPasteboardTypes:@[@"org.uicolorpanelkit.color-value",@"com.apple.cocoa.pasteboard.color"]];return NO;}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-9F09684580C6  UIColorPickerSwatchesView.delete:
- (void)delete:(id)sender {[self deleteCurrentColorAndSelectPrevious];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-029199AF6EF7  UIColorPickerSwatchesView.copy:
- (void)copy:(id)sender {NSIndexPath *selection=self.collectionView.indexPathsForSelectedItems.firstObject;if(!selection)return;UIColorPickerSwatchAction *action=[[UIColorPickerSwatchAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Copy Color"] target:self selector:@selector(accessibilityCopy:)];action.slot=[self storeIndexForColorIndex:selection.item];[self accessibilityCopy:action];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-4222EF823926  UIColorPickerSwatchesView.paste:
- (void)paste:(id)sender {NSData *data=[UIPasteboard.generalPasteboard dataForPasteboardType:@"org.uicolorpanelkit.color-value"];UIColorValue *color=nil;if(data){id record=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:nil];color=[[UIColorValue alloc]initWithPropertyList:record error:nil];}if(!color){data=[UIPasteboard.generalPasteboard dataForPasteboardType:@"com.apple.cocoa.pasteboard.color"];if(data)color=[UIColorArchive colorValueFromNSColorArchiveData:data error:nil];}if(color){NSUInteger index=self.collectionView.indexPathsForSelectedItems.firstObject?self.collectionView.indexPathsForSelectedItems.firstObject.item:self.presentedColors.count;[self storeDroppedColor:color atIndex:index source:nil];}}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-33C0683F19F6  UIColorPickerSwatchesView.dragInteraction:itemsForBeginningSession:
- (NSArray<UIDragItem *> *)dragInteraction:(UIDragInteraction *)interaction itemsForBeginningSession:(id<UIDragSession>)session {
    BOOL fromCurrent=interaction.view==self.currentColorSourceView;if(self.usesNativePickerPresentation&&!fromCurrent)return @[];NSIndexPath *index=fromCurrent?nil:[self.collectionView indexPathForItemAtPoint:[session locationInView:self.collectionView]];if(!fromCurrent&&(!index||index.item>=(NSInteger)self.presentedColors.count))return @[];NSUInteger storeIndex=index?[self storeIndexForColorIndex:index.item]:NSNotFound;UIColorValue *color=fromCurrent?self.currentColor:[self colorAtIndex:storeIndex];if(!color)return @[];
    NSItemProvider *provider=[[NSItemProvider alloc]initWithObject:color.UIColor];NSDictionary *value=[color propertyListRepresentationWithError:nil];NSData *exact=value?[NSPropertyListSerialization dataWithPropertyList:value format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil]:nil;
    if(exact)[provider registerDataRepresentationForTypeIdentifier:@"org.uicolorpanelkit.color-value" visibility:NSItemProviderRepresentationVisibilityAll loadHandler:^NSProgress *(void(^completion)(NSData *,NSError *)){completion(exact,nil);return nil;}];
    NSData *native=[UIColorArchive archivedDataWithColorValue:color error:nil];if(native)[provider registerDataRepresentationForTypeIdentifier:@"com.apple.cocoa.pasteboard.color" visibility:NSItemProviderRepresentationVisibilityAll loadHandler:^NSProgress *(void(^completion)(NSData *,NSError *)){completion(native,nil);return nil;}];
    UIDragItem *item=[[UIDragItem alloc]initWithItemProvider:provider];item.localObject=fromCurrent?@{@"color":color}:@{@"owner":self,@"storeIndex":@(storeIndex),@"color":color};return @[item];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-3BF61A12F92A  UIColorPickerSwatchesView.dropInteraction:canHandleSession:
- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session {NSItemProvider *provider=session.items.firstObject.itemProvider;return self.favoritesEditable&&session.items.count==1&&([provider hasItemConformingToTypeIdentifier:@"org.uicolorpanelkit.color-value"]||[provider hasItemConformingToTypeIdentifier:@"com.apple.cocoa.pasteboard.color"]||[session canLoadObjectsOfClass:UIColor.class]);}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-80D13A4E1F97  UIColorPickerSwatchesView.dropInteraction:sessionDidUpdate:
- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session {id local=session.items.firstObject.localObject;BOOL moving=[local isKindOfClass:NSDictionary.class]&&local[@"owner"]==self;return [[UIDropProposal alloc]initWithDropOperation:self.favoritesEditable?(moving?UIDropOperationMove:UIDropOperationCopy):UIDropOperationCancel];}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-2DF785C7D0F6  UIColorPickerSwatchesView.storeDroppedColor:atIndex:source: — UIKit insert/move transport preserves sparse backing indices and opaque legacy records.
- (void)storeDroppedColor:(UIColorValue *)color atIndex:(NSUInteger)index source:(NSDictionary *)source {
    if(![self canWriteFavorites]||!color||index>self.presentedColors.count)return;if((self.favoritesStore||self.persistenceKey.length)&&![color propertyListRepresentationWithError:nil]){UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"This color cannot be saved."]);return;}
    NSUInteger destination=[self storeIndexForColorIndex:index];BOOL moving=source[@"owner"]==self;NSUInteger original=[source[@"storeIndex"]unsignedIntegerValue];if(moving&&[self colorAtIndex:original]!=source[@"color"])return;
    // Native append mapping returns1 for an empty visible list. An entirely new app store has no grid backing seed; retain index0 as an empty marker before insertion.
    if(destination>self.favoriteStore.colors.count){NSMutableArray *values=[self.favoriteStore.colors mutableCopy];while(values.count<destination)[values addObject:NSNull.null];[self.favoriteStore updatingFromBacking:^{self.favoriteStore.colorEntries=values;}];}
    if(moving&&original<destination)destination--;if(moving&&original==destination)return;
    NSMutableDictionary *records=[NSMutableDictionary new];for(NSString *key in self.unrestoredSlotRecords){NSUInteger old=key.integerValue;if(moving&&old>original)old--;if(old>=destination)old++;records[[NSString stringWithFormat:@"%lu",(unsigned long)old]]=self.unrestoredSlotRecords[key];}self.unrestoredSlotRecords=records;
    if(moving)[self.favoriteStore moveColorAtIndex:original toIndex:destination replacement:NO];else[self.favoriteStore insertColor:color atIndex:destination];if(![self persistSlots])return;NSUInteger selected=[self.savedColorsStoreIndexes indexOfObject:@(destination)];if(selected!=NSNotFound)[self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:selected inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-88325132C991  UIColorPickerSwatchesView.dropInteraction:performDrop:
- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session {
    if(![self canWriteFavorites])return;
    CGPoint point=[session locationInView:self.collectionView];point.x=MAX(0,point.x);point.y=MAX(0,point.y);NSUInteger index=[self.favoriteLayout layoutAttributesForDropTargetAtPoint:point].indexPath.item;UIDragItem *item=session.items.firstObject;id local=item.localObject;
    if([local isKindOfClass:NSDictionary.class]&&[local[@"color"]isKindOfClass:UIColorValue.class]){[self storeDroppedColor:local[@"color"] atIndex:index source:local];return;}
    NSItemProvider *provider=item.itemProvider;NSString *type=[provider hasItemConformingToTypeIdentifier:@"org.uicolorpanelkit.color-value"]?@"org.uicolorpanelkit.color-value":([provider hasItemConformingToTypeIdentifier:@"com.apple.cocoa.pasteboard.color"]?@"com.apple.cocoa.pasteboard.color":nil);
    // Conservative UIKit transport policy: if the list changes while an
    // external provider loads, cancel rather than reinterpret its old index.
    NSUInteger generation=_dropGeneration;UIFavoriteColorsStore *store=self.favoriteStore;NSString *key=[self.persistenceKey copy];__weak typeof(self) weakSelf=self;__block BOOL handled=NO;
    if(type){[provider loadDataRepresentationForTypeIdentifier:type completionHandler:^(NSData *data,NSError *error){
        UIColorValue *color=nil;if([type isEqualToString:@"org.uicolorpanelkit.color-value"]){id record=data?[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:nil]:nil;if(record)color=[[UIColorValue alloc]initWithPropertyList:record error:nil];}else if(data)color=[UIColorArchive colorValueFromNSColorArchiveData:data error:nil];
        dispatch_async(dispatch_get_main_queue(),^{
            if(handled)return;handled=YES;UIColorPickerSwatchesView *view=weakSelf;
            if(!view||view->_dropGeneration!=generation||view.favoriteStore!=store||!(view.persistenceKey==key||[view.persistenceKey isEqualToString:key]))return;
            if(color)[view storeDroppedColor:color atIndex:index source:nil];else UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"The dropped color is not supported."]);
        });
    }];}
    else if([provider canLoadObjectOfClass:UIColor.class]){[provider loadObjectOfClass:UIColor.class completionHandler:^(id<NSItemProviderReading> object,NSError *error){
        UIColor *native=[object isKindOfClass:UIColor.class]?(UIColor *)object:nil;UIColorValue *color=native?[[UIColorValue alloc]initWithCGColor:native.CGColor]:nil;
        dispatch_async(dispatch_get_main_queue(),^{
            if(handled)return;handled=YES;UIColorPickerSwatchesView *view=weakSelf;
            if(!view||view->_dropGeneration!=generation||view.favoriteStore!=store||!(view.persistenceKey==key||[view.persistenceKey isEqualToString:key]))return;
            if(color)[view storeDroppedColor:color atIndex:index source:nil];else UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"The dropped color could not be loaded."]);
        });
    }];}
}
@end
