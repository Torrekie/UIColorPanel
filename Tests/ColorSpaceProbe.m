#import "ColorSpaceProbe.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CommonCrypto/CommonDigest.h>
@implementation UIColorColorSpaceProbe
+ (NSDictionary *)environmentState {
    NSMutableArray *results = [NSMutableArray new];
    for (NSString *name in @[(__bridge NSString *)kCGColorSpaceGenericRGB,(__bridge NSString *)kCGColorSpaceSRGB,(__bridge NSString *)kCGColorSpaceDisplayP3]) {
        CGColorSpaceRef space = CGColorSpaceCreateWithName((__bridge CFStringRef)name);
        NSMutableDictionary *record = [@{@"requestedName":name,@"available":@(space != NULL)} mutableCopy];
        if (space) {
            CFStringRef actualName = CGColorSpaceCopyName(space);
            record[@"returnedName"] = actualName ? (__bridge NSString *)actualName : @"unnamed";
            record[@"model"] = @(CGColorSpaceGetModel(space));
            CFDataRef profile = CGColorSpaceCopyICCData(space);
            record[@"iccByteCount"] = @(profile ? CFDataGetLength(profile) : 0);
            if (profile) {
                unsigned char digest[CC_SHA256_DIGEST_LENGTH];
                CC_SHA256(CFDataGetBytePtr(profile),(CC_LONG)CFDataGetLength(profile),digest);
                NSMutableString *hex = [NSMutableString new];
                for (NSUInteger index = 0; index < sizeof(digest); index++) [hex appendFormat:@"%02x",digest[index]];
                record[@"iccSHA256"] = hex;
                CFRelease(profile);
            }
            if (actualName) CFRelease(actualName);
            CGColorSpaceRelease(space);
        }
        [results addObject:record];
    }
    return @{@"spaces":results};
}
@end
