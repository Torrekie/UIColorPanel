#import <Foundation/Foundation.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSErrorDomain const UIColorArchiveErrorDomain;
typedef NS_ERROR_ENUM(UIColorArchiveErrorDomain, UIColorArchiveError) {
    UIColorArchiveErrorInvalidData = 1,
    UIColorArchiveErrorUnsupportedColor,
    UIColorArchiveErrorUnsupportedLegacyData
};

/// A scoped NSColor archive-format bridge. It never defines or replaces the NSColor runtime class.
@interface UIColorArchive : NSObject
+ (nullable UIColorValue *)colorValueFromNSColorArchiveData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSData *)archivedDataWithColorValue:(UIColorValue *)color error:(NSError * _Nullable * _Nullable)error;
#if TARGET_OS_IOS
+ (nullable UIColor *)colorFromNSColorArchiveData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSData *)archivedDataWithColor:(UIColor *)color error:(NSError * _Nullable * _Nullable)error;
#endif
@end
NS_ASSUME_NONNULL_END
