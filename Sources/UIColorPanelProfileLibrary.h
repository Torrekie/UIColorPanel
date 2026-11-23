#import "UIColorPanelColorProfile.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UIColorPanelProfileDiscoveryStatus) {
    UIColorPanelProfileDiscoveryStatusDisabled = 0,
    UIColorPanelProfileDiscoveryStatusUnavailable,
    UIColorPanelProfileDiscoveryStatusFailed,
    UIColorPanelProfileDiscoveryStatusEmpty,
    UIColorPanelProfileDiscoveryStatusAvailable,
    UIColorPanelProfileDiscoveryStatusDiscovering,
    UIColorPanelProfileDiscoveryStatusPartial,
    UIColorPanelProfileDiscoveryStatusCancelled
};

/// Standard and caller-supplied profiles remain available without system discovery.
@interface UIColorPanelProfileLibrary : NSObject
@property(atomic, copy, readonly) NSArray<UIColorPanelColorProfile *> *systemProfiles;
@property(atomic, readonly) UIColorPanelProfileDiscoveryStatus discoveryStatus;
@property(atomic, strong, readonly, nullable) NSError *discoveryError;
+ (NSArray<UIColorPanelColorProfile *> *)standardProfiles;
/// Preserves group and item order; equal profiles are retained only once.
+ (NSArray<UIColorPanelColorProfile *> *)profilesByCombiningProfiles:(NSArray<NSArray<UIColorPanelColorProfile *> *> *)profileGroups;
/// Completion is delivered on the main queue. Cancellation/supersession drops old completions.
/// Requests/cancellation may originate on any queue; state/KVO publication is on main.
/// Background cancellation invalidates work immediately and queues its visible status.
/// A completion whose delivery has already begun cannot be retracted.
/// A successful call is a snapshot; ColorSync may populate its installed-profile cache later.
/// The optional system provider requires both its compile-time gate and useSPI=YES.
- (void)refreshSystemProfilesUsingSPI:(BOOL)useSPI completion:(nullable void (^)(UIColorPanelProfileLibrary *library))completion;
- (void)cancelPendingDiscovery;
/// Export availability only, not proof of execution or a complete installed-profile catalog.
+ (NSDictionary<NSString *, id> *)runtimeCapabilities;
+ (nullable CGColorSpaceRef)createExtendedColorSpace:(CGColorSpaceRef)space CF_RETURNS_RETAINED;
+ (nullable CGColorSpaceRef)createLinearizedColorSpace:(CGColorSpaceRef)space CF_RETURNS_RETAINED;
@end

NS_ASSUME_NONNULL_END
