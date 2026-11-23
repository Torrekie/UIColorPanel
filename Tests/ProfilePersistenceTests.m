#import "ProfilePersistenceTests.h"
#import "../Sources/UIColorValue.h"
#import <math.h>

@implementation UIColorProfilePersistenceTests
+ (BOOL)runWithOutputURL:(NSURL *)outputURL {
    NSMutableArray *cases=[NSMutableArray new];
    __block NSUInteger failures=0;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL pass,NSDictionary *details) {
        NSMutableDictionary *entry=[@{@"name":name,@"pass":@(pass)} mutableCopy];
        [entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];if(!pass)failures++;
    };
    CGColorSpaceRef srgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGColorSpaceRef p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    CGColorSpaceRef extendedRGB=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
    if(!srgb||!p3||!extendedRGB){if(srgb)CGColorSpaceRelease(srgb);if(p3)CGColorSpaceRelease(p3);if(extendedRGB)CGColorSpaceRelease(extendedRGB);return NO;}
    CGFloat values[]={.25,.7,.9,.37};
    CGColorRef color=CGColorCreate(p3,values);UIColorValue *value=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);
    NSError *error=nil;
    NSDictionary *saved=[value propertyListRepresentationWithError:&error];
    CFDataRef p3ICC=CGColorSpaceCopyICCData(p3);
    NSData *profile=CFBridgingRelease(p3ICC);
    NSMutableDictionary *differentHint=[saved mutableCopy];differentHint[@"spaceName"]=(__bridge NSString *)kCGColorSpaceSRGB;
    UIColorValue *restored=[[UIColorValue alloc]initWithPropertyList:differentHint error:&error];
    NSData *restoredICC=restored?CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(restored.CGColor))):nil;
    BOOL componentsExact=restored&&CGColorGetNumberOfComponents(restored.CGColor)==4;
    if(componentsExact)for(NSUInteger i=0;i<4;i++)componentsExact&=CGColorGetComponents(restored.CGColor)[i]==values[i];
    record(@"storedICCOverridesDifferentNamedProfile",restored&&!error&&[restoredICC isEqual:profile]&&componentsExact,
           @{@"savedICCBytes":@(profile.length),@"restoredICCBytes":@(restoredICC.length),@"componentsExact":@(componentsExact)});

    error=nil;restored=[[UIColorValue alloc]initWithPropertyList:saved error:&error];
    record(@"matchingNamedProfilePreservesRepresentation",restored&&!error&&CFEqual(CGColorGetColorSpace(restored.CGColor),p3)&&CGColorEqualToColor(value.CGColor,restored.CGColor)&&[saved[@"extendedRange"]isEqual:@NO],nil);
    CGFloat extendedComponents[]={-0.125,1.375,.3141592653589793,0};
    color=CGColorCreate(extendedRGB,extendedComponents);UIColorValue *extendedValue=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);
    NSDictionary *extendedSaved=[extendedValue propertyListRepresentationWithError:&error];
    restored=[[UIColorValue alloc]initWithPropertyList:extendedSaved error:&error];
    componentsExact=restored&&CGColorSpaceUsesExtendedRange(CGColorGetColorSpace(restored.CGColor));
    if(componentsExact)for(NSUInteger i=0;i<4;i++)componentsExact&=CGColorGetComponents(restored.CGColor)[i]==extendedComponents[i];
    record(@"matchingExtendedNamePreservesRangeComponentsAndZeroAlpha",componentsExact&&[extendedSaved[@"extendedRange"]isEqual:@YES],nil);

    NSMutableDictionary *legacy=[extendedSaved mutableCopy];[legacy removeObjectForKey:@"extendedRange"];
    error=nil;restored=[[UIColorValue alloc]initWithPropertyList:legacy error:&error];
    record(@"legacyExtendedNameInfersExtendedRange",restored&&!error&&CGColorEqualToColor(restored.CGColor,extendedValue.CGColor),nil);
    [legacy removeObjectForKey:@"iccData"];error=nil;restored=[[UIColorValue alloc]initWithPropertyList:legacy error:&error];
    record(@"legacyNameOnlyExtendedRecord",restored&&!error&&CGColorEqualToColor(restored.CGColor,extendedValue.CGColor),nil);
    legacy=[saved mutableCopy];[legacy removeObjectForKey:@"iccData"];[legacy removeObjectForKey:@"extendedRange"];
    error=nil;restored=[[UIColorValue alloc]initWithPropertyList:legacy error:&error];
    record(@"legacyNameOnlyBoundedRecord",restored&&!error&&CGColorEqualToColor(restored.CGColor,value.CGColor),nil);

    NSMutableDictionary *customExtended=[differentHint mutableCopy];customExtended[@"extendedRange"]=@YES;
    customExtended[@"components"]=@[@(-.125),@1.375,@.3141592653589793,@.37];
    error=nil;restored=[[UIColorValue alloc]initWithPropertyList:customExtended error:&error];
    BOOL canExtend=NO;
    if(@available(iOS 14.0,macOS 11.0,*))canExtend=YES;
    restoredICC=restored?CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(restored.CGColor))):nil;
    componentsExact=restored&&CGColorSpaceUsesExtendedRange(CGColorGetColorSpace(restored.CGColor))&&CGColorGetNumberOfComponents(restored.CGColor)==4;
    if(componentsExact)for(NSUInteger i=0;i<4;i++)componentsExact&=CGColorGetComponents(restored.CGColor)[i]==[customExtended[@"components"][i]doubleValue];
    BOOL outcome=canExtend?(restored&&!error&&componentsExact&&[restoredICC isEqual:profile]):(!restored&&[error.domain isEqual:UIColorValueErrorDomain]&&error.code==UIColorValueErrorUnsupportedSpace);
    record(@"foreignExtendedICCRecreatedOrExplicitlyUnsupported",outcome,@{@"canCreateExtendedICC":@(canExtend),@"restored":@(restored!=nil),@"errorCode":@(error.code),@"exactICC":@([restoredICC isEqual:profile]),@"componentsExact":@(componentsExact)});

    NSMutableDictionary *foreignLegacy=[customExtended mutableCopy];[foreignLegacy removeObjectForKey:@"extendedRange"];
    foreignLegacy[@"spaceName"]=@"kCGColorSpaceExtendedDisplayP3";
    error=nil;restored=[[UIColorValue alloc]initWithPropertyList:foreignLegacy error:&error];
    outcome=canExtend?(restored&&!error&&CGColorSpaceUsesExtendedRange(CGColorGetColorSpace(restored.CGColor))):(!restored&&error.code==UIColorValueErrorUnsupportedSpace);
    record(@"legacyUnavailableExtendedNameDoesNotBecomeBoundedICC",outcome,@{@"canCreateExtendedICC":@(canExtend),@"errorCode":@(error.code)});

    NSArray *invalidFields=@[@{@"extendedRange":@"YES"},@{@"extendedRange":@1},@{@"extendedRange":@[]},@{@"iccData":@"not data"},@{@"iccData":[NSData data]},@{@"spaceName":@1},@{@"components":@[@.1,@.2,@.3,@2]},@{@"model":@"RGB"},@{@"componentCount":@3.5}];
    NSUInteger invalidAccepted=0,wrongErrors=0;
    for(NSDictionary *replacement in invalidFields){NSMutableDictionary *invalid=[saved mutableCopy];[invalid addEntriesFromDictionary:replacement];error=nil;UIColorValue *result=[[UIColorValue alloc]initWithPropertyList:invalid error:&error];if(result)invalidAccepted++;if(error.code!=UIColorValueErrorInvalidArchive)wrongErrors++;}
    record(@"malformedFieldsAndInvalidICCRejectedWithoutNamedFallback",invalidAccepted==0&&wrongErrors==0,@{@"caseCount":@(invalidFields.count),@"acceptedCount":@(invalidAccepted),@"wrongErrorCount":@(wrongErrors)});
    CGColorSpaceRelease(srgb);CGColorSpaceRelease(p3);CGColorSpaceRelease(extendedRGB);
    NSDictionary *output=@{@"cases":cases,@"caseCount":@(cases.count),@"failureCount":@(failures),@"platform":[NSProcessInfo.processInfo operatingSystemVersionString],@"scope":@"ICC-authoritative canonical persistence, extended-range metadata, legacy name compatibility and explicit unsupported-platform rejection. Named profile mismatch is generated from actual current Core Graphics ICC data; no shipped production profile fixture."};
    NSData *data=[NSJSONSerialization dataWithJSONObject:output options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];
    return data&&[data writeToURL:outputURL atomically:YES]&&failures==0;
}
@end
#if !TARGET_OS_IOS
int main(int argc,const char *argv[]) {
    @autoreleasepool {NSURL *url=[NSURL fileURLWithPath:argc>1?[NSString stringWithUTF8String:argv[1]]:@".build/profile-persistence-host.json"];BOOL pass=[UIColorProfilePersistenceTests runWithOutputURL:url];NSLog(@"Profile persistence tests %@ (%@)",pass?@"PASS":@"FAIL",url.path);return pass?0:1;}
}
#endif
