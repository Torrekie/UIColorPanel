#import <UIKit/UIKit.h>
#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN
@class UIColorPickerSwatchesView,UIColorPanelFavoriteSwatchLayout,UIFavoriteColorsStore,UIColorPickerFavoritesStore;
@protocol UIColorPickerSwatchesViewDelegate <NSObject>
- (void)colorPickerSwatches:(UIColorPickerSwatchesView *)view didSelectColorValue:(UIColorValue *)color;
@optional
- (void)colorPickerSwatchesDidChangeSlots:(UIColorPickerSwatchesView *)view;
@end
/// Favorites backed by a sparse indexed store, with manager and native picker presentations.
/// Empty decorations are not stored transparent colors. Version1 dictionary indices remain intact.
@interface UIColorPickerSwatchesView : UIView
@property(nonatomic,weak,nullable) id<UIColorPickerSwatchesViewDelegate> delegate;
/// Native selection updates visuals only; assignment never saves or emits selection events.
@property(nonatomic,strong) UIColorValue *currentColor;
@property(nonatomic,copy,nullable) NSString *persistenceKey;
/// Optional record backing. When nonnil, takes precedence over persistenceKey.
@property(nonatomic,strong,nullable) UIColorPickerFavoritesStore *favoritesStore;
/// Default NO retains the wrapped manager. YES shows circular favorites followed by Add.
/// Overflow pages horizontally; the supplied bounds determine the number of rows.
@property(nonatomic) BOOL usesNativePickerPresentation;
/// Default YES. NO presents only favorites whose alpha is exactly1.
/// Hidden colors retain their original backing indices and are never removed by filtering.
@property(nonatomic) BOOL supportsAlpha;
/// Default NO retains legacy manager decorations. YES uses30pt dots inside its existing cells.
/// This appearance option does not change native picker cells or manager interactions.
@property(nonatomic) BOOL usesCircularManagerPresentation;
/// Original compact landscape metrics:28pt circles/16pt spacing instead of30/18.
@property(nonatomic) BOOL nativeLandscapeLayout;
/// Presents the host's complete favorites manager from native accessibility actions.
@property(nonatomic,copy,nullable) void (^managementHandler)(void);
/// Native logical units. Keep1 inside a uniformly transformed native canvas.
@property(nonatomic) CGFloat logicalScale;
/// Installs public drag and Save Current Color accessibility routes on the existing current well.
@property(nonatomic,weak,nullable) UIView *currentColorSourceView;
@property(nonatomic,strong,readonly) UICollectionView *collectionView;
@property(nonatomic,strong,readonly) UIColorPanelFavoriteSwatchLayout *favoriteLayout;
@property(nonatomic,strong,readonly) UIFavoriteColorsStore *favoriteStore;
/// Backing-index snapshot of UIColorValue/NSNull entries; no fixed twenty-item capacity.
@property(nonatomic,copy,readonly) NSArray *slots;
@property(nonatomic,copy,readonly) NSArray<UIColorValue *> *presentedColors;
- (nullable UIColorValue *)colorAtIndex:(NSUInteger)index;
/// Explicit compatibility adapter: nil creates an empty marker without reindexing later entries.
- (void)setColor:(nullable UIColorValue *)color forSlot:(NSUInteger)index;
/// A future-version library disables editing until a supported record is loaded.
@property(nonatomic, readonly) BOOL favoritesEditable;
/// Returns NO when the backing is read-only or cannot save this color.
- (BOOL)saveCurrentColor;
/// Reread the backing, removing corrupt color entries or rebuilding a malformed library.
/// Unbacked views and unchanged records retain their state.
- (void)refreshFavorites;
/// Invalidates asynchronous external drops when their store, list or host session changes.
/// Provider completions may still arrive; they cannot write into a later session.
/// Any list revision cancels pending positions. With concurrent external drops,
/// the first successful insertion changes the list and invalidates the others.
- (void)cancelPendingDrops;
- (NSInteger)storeIndexForColorIndex:(NSInteger)index;
- (void)deleteCurrentColorAndSelectPrevious;
- (void)deleteCurrentColorAndSelectNext;
@end
NS_ASSUME_NONNULL_END
