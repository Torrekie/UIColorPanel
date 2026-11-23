#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const UIColorPanelColorProfileErrorDomain;
typedef NS_ERROR_ENUM(UIColorPanelColorProfileErrorDomain, UIColorPanelColorProfileError) {
    UIColorPanelColorProfileErrorInvalidICC = 1,
    UIColorPanelColorProfileErrorDiscoveryDisabled,
    UIColorPanelColorProfileErrorDiscoveryUnavailable,
    UIColorPanelColorProfileErrorDiscoveryFailed,
    UIColorPanelColorProfileErrorUnreadableProfile,
    UIColorPanelColorProfileErrorSelectionSuppressed,
    UIColorPanelColorProfileErrorIncompatibleModel
};

/// An immutable working-space descriptor. Display names never determine identity.
@interface UIColorPanelColorProfile : NSObject <NSCopying>
@property(nonatomic, readonly) CGColorSpaceRef CGColorSpace;
@property(nonatomic, copy, readonly) NSString *displayName;
/// ICC bytes and space semantics (including extended range) determine this identifier.
/// Restorable non-ICC spaces use their complete description. An otherwise opaque space
/// receives a process-local unique identity rather than risking a hash/name collision.
/// Persist the ICC/CG space representation, not this identifier, across OS releases.
@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, copy, readonly, nullable) NSData *ICCData;
@property(nonatomic, readonly) CGColorSpaceModel model;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithColorSpace:(CGColorSpaceRef)colorSpace displayName:(nullable NSString *)displayName NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithICCData:(NSData *)ICCData displayName:(nullable NSString *)displayName error:(NSError * _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
