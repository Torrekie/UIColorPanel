#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Posted synchronously on the writing thread; object is the writing store.
/// Consumers compare key and appGroupIdentifier to recognize other instances
/// using the same backing. This notification does not cross process boundaries.
FOUNDATION_EXPORT NSNotificationName const UIColorPickerFavoritesStoreDidChangeNotification;
FOUNDATION_EXPORT NSErrorDomain const UIColorPickerFavoritesStoreErrorDomain;
typedef NS_ERROR_ENUM(UIColorPickerFavoritesStoreErrorDomain, UIColorPickerFavoritesStoreError) {
    UIColorPickerFavoritesStoreErrorAppGroupUnavailable = 1,
    UIColorPickerFavoritesStoreErrorDefaultsUnavailable,
};

/// Explicit application-local or App Group backing for this component's favorites records.
/// Writes replace a complete snapshot; concurrent writers are last-writer-wins.
/// App Group changes from another process are read on reopening or explicit refresh;
/// no real-time cross-process update or merge is provided.
@interface UIColorPickerFavoritesStore : NSObject
/// Application-local standard defaults. The key must be nonempty.
- (instancetype)initWithKey:(NSString *)key NS_DESIGNATED_INITIALIZER;
/// Requires the caller's App Group entitlement. Both arguments must be nonempty.
/// Failure returns an error and never falls back to application-local storage.
- (nullable instancetype)initWithAppGroupIdentifier:(NSString *)appGroupIdentifier key:(NSString *)key error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@property(nonatomic, copy, readonly) NSString *key;
/// nil for application-local storage.
@property(nonatomic, copy, readonly, nullable) NSString *appGroupIdentifier;
/// Existing version-one sparse property-list dictionary or legacy array; nil if absent.
/// Records, including unsupported serialized colors, are returned unchanged.
- (nullable id)readRecord;
/// Stores a complete property-list record unchanged and posts the change notification.
- (void)writeRecord:(id)record;
@end

NS_ASSUME_NONNULL_END
