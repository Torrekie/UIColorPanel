#import <Foundation/Foundation.h>
#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSNotificationName const UIFavoriteColorsDidChangeNotification;
/// Exact native filter topology with NSNull identity transport for the private native empty marker.
FOUNDATION_EXPORT NSArray<UIColorValue *> *UIColorPanelPresentedFavoriteColors(NSArray *colors,NSArray<NSNumber *> * _Nullable * _Nonnull storeIndexes);
/// App-local transport for the native ordered favorite store. NSNull is an empty marker, never an alpha-zero color.
@interface UIFavoriteColorsStore : NSObject
@property(nonatomic,copy) NSArray *colorEntries;
@property(nonatomic,copy,readonly) NSArray *colors;
@property(nonatomic,copy,nullable) void (^backingWriter)(NSArray *colors);
+ (BOOL)defersBackingUpdates;
- (void)addColor:(id)color;
- (void)insertColor:(id)color atIndex:(NSInteger)index;
- (void)replaceColorAtIndex:(NSInteger)index withColor:(id)color;
- (void)removeColorAtIndex:(NSInteger)index;
- (void)copyColorAtIndex:(NSInteger)source toIndex:(NSInteger)destination;
- (void)moveColorAtIndex:(NSInteger)source toIndex:(NSInteger)destination replacement:(BOOL)replacement;
- (void)updatingFromBacking:(void (^)(void))block;
@end
NS_ASSUME_NONNULL_END
