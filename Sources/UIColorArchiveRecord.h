#import <Foundation/Foundation.h>
#import "UIColorArchive.h"

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT const char UIColorArchiveMetadataAssociationKey;
/// Private secure-decoding records used only through per-archiver class mappings.
@interface UIColorSpaceArchiveRecord : NSObject <NSSecureCoding>
@property(nonatomic, readonly) CGColorSpaceRef CGColorSpace;
- (instancetype)initWithCGColorSpace:(CGColorSpaceRef)space;
@end
@interface UIColorArchiveRecord : NSObject <NSSecureCoding>
@property(nonatomic, strong, readonly) UIColorValue *colorValue;
- (instancetype)initWithColorValue:(UIColorValue *)value;
@end
@interface UIColorArchive (ColorListCoding)
+ (nullable NSDictionary<NSString *, NSArray *> *)colorListContentsFromData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSData *)archivedColorListWithKeys:(NSArray<NSString *> *)keys values:(NSArray<UIColorValue *> *)values error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
