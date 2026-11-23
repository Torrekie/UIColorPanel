#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Scoped reader for observed little-endian v1 .clr lists; not a general typedstream unarchiver.
@interface UIColorLegacyColorListReader : NSObject
- (instancetype)initWithData:(NSData *)data;
- (nullable NSDictionary<NSString *, NSArray *> *)colorListContentsWithError:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
