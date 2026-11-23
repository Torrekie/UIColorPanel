#import "RuntimeProfileProbe.h"
#import "../Sources/UIColorPanelAppearance.h"
#if UICOLORPANEL_ENABLE_PRIVATE_API
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CommonCrypto/CommonDigest.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>
#import <stdlib.h>

// Test-only ABI declarations follow ColorSyncProfile.h. In particular, the
// iterator callback is a C function, not a Block, and its return type is bool.
typedef CFTypeRef (*UIRuntimeProfileCreate)(CFDataRef, CFErrorRef *);
typedef CFTypeRef (*UIRuntimeProfileCreateWithURL)(CFURLRef, CFErrorRef *);
typedef CFDataRef (*UIRuntimeProfileCopyData)(CFTypeRef, CFErrorRef *);
typedef CFStringRef (*UIRuntimeProfileCopyDescription)(CFTypeRef);
typedef void (*UIRuntimeProfileIterator)(bool (*)(CFDictionaryRef, void *), uint32_t *, void *, CFErrorRef *);
typedef CGColorSpaceRef (*UIRuntimeSpaceTransform)(CGColorSpaceRef);

typedef struct {
    __unsafe_unretained NSMutableArray *dictionaries;
    NSUInteger callbackCount;
    NSUInteger invalidDictionaryCount;
    BOOL stoppedAtLimit;
} UIRuntimeProfileIterationContext;

static bool UIRuntimeProfileCollect(CFDictionaryRef dictionary, void *opaque) {
    UIRuntimeProfileIterationContext *context=opaque;
    context->callbackCount++;
    if(dictionary&&CFGetTypeID(dictionary)==CFDictionaryGetTypeID())[context->dictionaries addObject:[(__bridge NSDictionary *)dictionary copy]];
    else context->invalidDictionaryCount++;
    context->stoppedAtLimit=context->callbackCount>=256;
    return !context->stoppedAtLimit;
}

static NSDictionary *UIRuntimeProfileError(NSError *error) {
    return error?@{@"domain":error.domain?:@"",@"code":@(error.code),@"description":error.localizedDescription?:@""}:@{};
}

static NSDictionary *UIRuntimeProfileSymbol(void *handle,const char *name) {
    void *address=handle?dlsym(handle,name):NULL;
    NSMutableDictionary *record=[@{@"available":@(address!=NULL)}mutableCopy];
    if(address){Dl_info info={0};if(dladdr(address,&info)){record[@"image"]=info.dli_fname?@(info.dli_fname):@"";record[@"resolvedName"]=info.dli_sname?@(info.dli_sname):@"";}}
    return record;
}

static NSString *UIRuntimeProfileDigest(CFDataRef data) {
    if(!data||CFDataGetLength(data)>UINT32_MAX)return @"";
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(CFDataGetBytePtr(data),(CC_LONG)CFDataGetLength(data),digest);
    NSMutableString *hex=[NSMutableString new];for(NSUInteger index=0;index<sizeof(digest);index++)[hex appendFormat:@"%02x",digest[index]];return hex;
}

static NSDictionary *UIRuntimeProfileSpace(CGColorSpaceRef space,CGColorRef source) {
    NSMutableDictionary *record=[@{@"created":@(space!=NULL)}mutableCopy];
    if(!space)return record;
    CFStringRef name=CGColorSpaceCopyName(space);CFDataRef data=CGColorSpaceCopyICCData(space);
    record[@"name"]=name?(__bridge NSString *)name:@"";record[@"model"]=@(CGColorSpaceGetModel(space));record[@"componentCount"]=@(CGColorSpaceGetNumberOfComponents(space));record[@"extendedRange"]=@(CGColorSpaceUsesExtendedRange(space));record[@"iccByteCount"]=@(data?CFDataGetLength(data):0);if(data)record[@"iccSHA256"]=UIRuntimeProfileDigest(data);
    if(source){
        CGColorRef converted=CGColorCreateCopyByMatchingToColorSpace(space,kCGRenderingIntentDefault,source,NULL);
        record[@"conversionSucceeded"]=@(converted!=NULL);
        if(converted){NSMutableArray *components=[NSMutableArray new];BOOL finite=YES;const CGFloat *values=CGColorGetComponents(converted);for(size_t index=0;index<CGColorGetNumberOfComponents(converted);index++){BOOL valid=isfinite(values[index]);finite&=valid;[components addObject:valid?@(values[index]):(id)@"nonfinite"];}record[@"components"]=components;record[@"finiteComponents"]=@(finite);record[@"alphaPreserved"]=@(fabs(CGColorGetAlpha(converted)-CGColorGetAlpha(source))<1e-6);record[@"outputSpaceMatchesRequested"]=@(CFEqual(CGColorGetColorSpace(converted),space));CGColorRelease(converted);}
        else record[@"conversionStatus"]=@"returnedNull";
    }
    if(name)CFRelease(name);if(data)CFRelease(data);return record;
}

static NSDictionary *UIRuntimeProfileMethod(Class cls,SEL selector,BOOL classMethod) {
    Method method=cls?(classMethod?class_getClassMethod(cls,selector):class_getInstanceMethod(cls,selector)):NULL;
    NSMutableDictionary *record=[@{@"classExists":@(cls!=Nil),@"methodExists":@(method!=NULL),@"definedOnQueriedClass":@NO,@"kind":classMethod?@"class":@"instance"}mutableCopy];
    if(cls){record[@"queriedClass"]=NSStringFromClass(cls);Class parent=class_getSuperclass(cls);record[@"superclass"]=parent?NSStringFromClass(parent):@"";}
    if(method){const char *encoding=method_getTypeEncoding(method);record[@"typeEncoding"]=encoding?@(encoding):@"";record[@"argumentCount"]=@(method_getNumberOfArguments(method));IMP implementation=method_getImplementation(method);record[@"implementation"]=[NSString stringWithFormat:@"%p",(void *)implementation];Dl_info info={0};if(dladdr((void *)implementation,&info)){if(info.dli_fname)record[@"image"]=@(info.dli_fname);if(info.dli_sname)record[@"implementationSymbol"]=@(info.dli_sname);}
        for(Class candidate=cls;candidate;candidate=class_getSuperclass(candidate)){unsigned int count=0;Method *ownMethods=class_copyMethodList(classMethod?object_getClass(candidate):candidate,&count);BOOL found=NO;for(unsigned int index=0;index<count;index++)if(method_getName(ownMethods[index])==selector){found=YES;break;}free(ownMethods);if(found){record[@"definingClass"]=NSStringFromClass(candidate);record[@"definedOnQueriedClass"]=@(candidate==cls);break;}}
    }
    return record;
}

@implementation UIColorPanelRuntimeProfileProbe
+ (BOOL)runWithOutputURL:(NSURL *)outputURL {
    @autoreleasepool {
        NSMutableDictionary *result=[NSMutableDictionary new];
        result[@"schemaVersion"]=@1;result[@"probeCompleted"]=@NO;result[@"compiledPrivateAPI"]=@(UICOLORPANEL_ENABLE_PRIVATE_API);result[@"runtimeUseSPI"]=@([NSUserDefaults.standardUserDefaults boolForKey:@"UIUseSPI"]);
        result[@"scope"]=@"Research-only application-process probe. ColorSync discovery is deliberately tested independently of the production public/SPI gate. Missing optional symbols, empty enumeration, permission failures and conversion failures are separate capability results. No screen capture, UI presentation, installed-profile mutation or user preference mutation.";
        NSProcessInfo *process=NSProcessInfo.processInfo;const struct mach_header *header=_dyld_get_image_header(0);
        NSMutableDictionary *identity=[@{@"osVersion":process.operatingSystemVersionString,@"processIdentifier":@(process.processIdentifier),@"mainThread":@(NSThread.isMainThread),@"executableImage":_dyld_get_image_name(0)?@(_dyld_get_image_name(0)):@""}mutableCopy];
        if(header){identity[@"cpuType"]=@(header->cputype);identity[@"cpuSubtype"]=@(header->cpusubtype);}
#if defined(__arm64__)
        identity[@"compiledArchitecture"]=@"arm64";
#elif defined(__x86_64__)
        identity[@"compiledArchitecture"]=@"x86_64";
#else
        identity[@"compiledArchitecture"]=@"other";
#endif
        NSMutableDictionary *simulator=[NSMutableDictionary new];for(NSString *key in @[@"SIMULATOR_UDID",@"SIMULATOR_RUNTIME_VERSION",@"SIMULATOR_ROOT",@"SIMULATOR_MODEL_IDENTIFIER"]){NSString *value=process.environment[key];if(value)simulator[key]=value;}identity[@"simulatorIdentity"]=simulator;result[@"identity"]=identity;
        CGColorSpaceRef sourceSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGFloat sourceValues[]={.25,.4,.6,.65};CGColorRef source=sourceSpace?CGColorCreate(sourceSpace,sourceValues):NULL;
        NSMutableArray *standardSpaces=[NSMutableArray new];BOOL baseline=source!=NULL;
        for(NSString *name in @[@"kCGColorSpaceSRGB",@"kCGColorSpaceDisplayP3",@"kCGColorSpaceGenericRGB",@"kCGColorSpaceAdobeRGB1998",@"kCGColorSpaceACESCGLinear",@"kCGColorSpaceROMMRGB",@"kCGColorSpaceITUR_709",@"kCGColorSpaceITUR_2020",@"kCGColorSpaceDCIP3",@"kCGColorSpaceGenericGray",@"kCGColorSpaceGenericGrayGamma2_2",@"kCGColorSpaceGenericCMYK",@"kCGColorSpaceExtendedDisplayP3",@"kCGColorSpaceExtendedLinearDisplayP3"]){
            CGColorSpaceRef space=CGColorSpaceCreateWithName((__bridge CFStringRef)name);NSMutableDictionary *record=[UIRuntimeProfileSpace(space,source)mutableCopy];record[@"requestedName"]=name;[standardSpaces addObject:record];if([name isEqualToString:@"kCGColorSpaceSRGB"]||[name isEqualToString:@"kCGColorSpaceDisplayP3"])baseline&=[record[@"conversionSucceeded"]boolValue]&&[record[@"finiteComponents"]boolValue]&&[record[@"alphaPreserved"]boolValue];if(space)CGColorSpaceRelease(space);
        }
        result[@"standardSpaces"]=standardSpaces;
        NSMutableDictionary *transforms=[NSMutableDictionary new];
        for(NSString *name in @[@"CGColorSpaceCreateLinearized",@"CGColorSpaceCreateExtended",@"CGColorSpaceCreateExtendedLinearized"]){
            NSMutableDictionary *record=[UIRuntimeProfileSymbol(RTLD_DEFAULT,name.UTF8String)mutableCopy];UIRuntimeSpaceTransform transform=(UIRuntimeSpaceTransform)dlsym(RTLD_DEFAULT,name.UTF8String);
            record[@"called"]=@(transform!=NULL&&sourceSpace!=NULL);
            if(transform&&sourceSpace){CGColorSpaceRef transformed=transform(sourceSpace);record[@"sRGBResult"]=UIRuntimeProfileSpace(transformed,source);if(transformed)CGColorSpaceRelease(transformed);CGColorSpaceRef cmyk=CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);if(cmyk){CGColorSpaceRef unsupported=transform(cmyk);record[@"cmykResult"]=UIRuntimeProfileSpace(unsupported,source);if(unsupported)CGColorSpaceRelease(unsupported);CGColorSpaceRelease(cmyk);}}
            transforms[name]=record;
        }result[@"weakCGTransforms"]=transforms;
        NSMutableArray *libraryAttempts=[NSMutableArray new];void *colorSync=NULL;
        for(NSString *path in @[@"/System/Library/PrivateFrameworks/ColorSync.framework/ColorSync",@"/System/Library/Frameworks/ColorSync.framework/ColorSync"]){dlerror();void *candidate=dlopen(path.fileSystemRepresentation,RTLD_LAZY|RTLD_LOCAL);const char *failure=dlerror();[libraryAttempts addObject:@{@"path":path,@"loaded":@(candidate!=NULL),@"error":failure?@(failure):@""}];if(candidate){colorSync=candidate;break;}}
        NSMutableDictionary *discovery=[@{@"libraryAttempts":libraryAttempts,@"libraryLoaded":@(colorSync!=NULL)}mutableCopy];NSMutableDictionary *symbols=[NSMutableDictionary new];
        NSArray *symbolNames=@[@"ColorSyncIterateInstalledProfiles",@"ColorSyncProfileCreate",@"ColorSyncProfileCreateWithURL",@"ColorSyncProfileCopyData",@"ColorSyncProfileCopyDescriptionString",@"ColorSyncProfileGetTypeID",@"kColorSyncProfileURL",@"kColorSyncProfileClass",@"kColorSyncProfileColorSpace",@"kColorSyncProfileHeader",@"kColorSyncProfileDescription",@"ColorSyncIterateInstalledProfilesWithOptions",@"kColorSyncWaitForCacheReply",@"kColorSyncProfileCacheSeed",@"kColorSyncProfileRepositoryChangeNotification"];
        for(NSString *name in symbolNames){NSMutableDictionary *record=[UIRuntimeProfileSymbol(colorSync,name.UTF8String)mutableCopy];if(colorSync&&[name hasPrefix:@"k"]){CFStringRef *address=(CFStringRef *)dlsym(colorSync,name.UTF8String);record[@"valuePresent"]=@(address&&*address);if(address&&*address){BOOL string=CFGetTypeID(*address)==CFStringGetTypeID();record[@"valueIsString"]=@(string);if(string)record[@"value"]=(__bridge NSString *)*address;}}symbols[name]=record;}discovery[@"symbols"]=symbols;
        UIRuntimeProfileIterator iterate=colorSync?(UIRuntimeProfileIterator)dlsym(colorSync,"ColorSyncIterateInstalledProfiles"):NULL;UIRuntimeProfileCreate create=colorSync?(UIRuntimeProfileCreate)dlsym(colorSync,"ColorSyncProfileCreate"):NULL;UIRuntimeProfileCreateWithURL createURL=colorSync?(UIRuntimeProfileCreateWithURL)dlsym(colorSync,"ColorSyncProfileCreateWithURL"):NULL;UIRuntimeProfileCopyData copyData=colorSync?(UIRuntimeProfileCopyData)dlsym(colorSync,"ColorSyncProfileCopyData"):NULL;UIRuntimeProfileCopyDescription copyDescription=colorSync?(UIRuntimeProfileCopyDescription)dlsym(colorSync,"ColorSyncProfileCopyDescriptionString"):NULL;
        CFStringRef *urlKeyAddress=colorSync?(CFStringRef *)dlsym(colorSync,"kColorSyncProfileURL"):NULL;CFStringRef urlKey=urlKeyAddress&&*urlKeyAddress&&CFGetTypeID(*urlKeyAddress)==CFStringGetTypeID()?*urlKeyAddress:NULL;
        NSMutableArray *profileDictionaries=[NSMutableArray new];UIRuntimeProfileIterationContext iteration={profileDictionaries,0,0,NO};uint32_t seed=0;CFErrorRef iterationError=NULL;
        discovery[@"iterationCalled"]=@(iterate!=NULL);discovery[@"iterationCallCount"]=@(iterate?1:0);
        if(iterate){NSTimeInterval started=NSDate.timeIntervalSinceReferenceDate;iterate(UIRuntimeProfileCollect,&seed,&iteration,&iterationError);discovery[@"iterationSeconds"]=@(NSDate.timeIntervalSinceReferenceDate-started);discovery[@"iterationStatus"]=iterationError?@"returnedError":profileDictionaries.count?@"returnedProfiles":@"emptyWithoutError";}else discovery[@"iterationStatus"]=colorSync?@"symbolMissing":@"libraryUnavailable";
        discovery[@"iterationError"]=UIRuntimeProfileError((__bridge NSError *)iterationError);discovery[@"seedAfterCall"]=@(seed);discovery[@"callbackCount"]=@(iteration.callbackCount);discovery[@"invalidDictionaryCount"]=@(iteration.invalidDictionaryCount);discovery[@"stoppedAtSafetyLimit"]=@(iteration.stoppedAtLimit);
        NSMutableArray *profiles=[NSMutableArray new];NSUInteger readable=0,createdSpaces=0,successfulConversions=0;
        for(NSDictionary *dictionary in profileDictionaries){
            NSMutableDictionary *record=[NSMutableDictionary new];NSMutableArray *keys=[NSMutableArray new];for(id key in dictionary)if([key isKindOfClass:NSString.class])[keys addObject:key];record[@"dictionaryKeys"]=[keys sortedArrayUsingSelector:@selector(compare:)];id url=urlKey?dictionary[(__bridge NSString *)urlKey]:nil;record[@"profileURLKeyAvailable"]=@(urlKey!=NULL);record[@"profileURLIsURL"]=@([url isKindOfClass:NSURL.class]);
            if([url isKindOfClass:NSURL.class]){
                record[@"profileURL"]=[url absoluteString];NSError *readError=nil;NSData *directData=[NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&readError];record[@"directReadSucceeded"]=@(directData!=nil);record[@"directReadByteCount"]=@(directData.length);record[@"directReadError"]=UIRuntimeProfileError(readError);if(directData)readable++;
                CFErrorRef profileError=NULL;CFTypeRef profile=createURL?createURL((__bridge CFURLRef)url,&profileError):NULL;record[@"createWithURLCalled"]=@(createURL!=NULL);record[@"profileCreatedFromURL"]=@(profile!=NULL);record[@"createWithURLError"]=UIRuntimeProfileError((__bridge NSError *)profileError);if(profileError)CFRelease(profileError);
                CFDataRef data=NULL;if(profile&&copyData){CFErrorRef dataError=NULL;data=copyData(profile,&dataError);record[@"copyDataSucceeded"]=@(data!=NULL);record[@"copyDataError"]=UIRuntimeProfileError((__bridge NSError *)dataError);if(dataError)CFRelease(dataError);}
                if(profile&&copyDescription){CFStringRef description=copyDescription(profile);record[@"description"]=description?(__bridge NSString *)description:@"";if(description)CFRelease(description);}
                CFDataRef bytes=data?:((__bridge CFDataRef)directData);record[@"bytesUsedForCG"]=data?@"ColorSyncProfileCopyData":directData?@"directURLRead":@"none";
                if(bytes&&CFDataGetLength(bytes)>0&&CFDataGetLength(bytes)<=16*1024*1024){record[@"iccByteCount"]=@(CFDataGetLength(bytes));record[@"iccSHA256"]=UIRuntimeProfileDigest(bytes);CGColorSpaceRef space=CGColorSpaceCreateWithICCData(bytes);NSDictionary *spaceRecord=UIRuntimeProfileSpace(space,source);record[@"coreGraphics"]=spaceRecord;if(space)createdSpaces++;if([spaceRecord[@"conversionSucceeded"]boolValue])successfulConversions++;if(space)CGColorSpaceRelease(space);if(create){CFErrorRef createError=NULL;CFTypeRef fromData=create(bytes,&createError);record[@"profileCreatedFromData"]=@(fromData!=NULL);record[@"createFromDataError"]=UIRuntimeProfileError((__bridge NSError *)createError);if(createError)CFRelease(createError);if(fromData)CFRelease(fromData);}}
                else record[@"coreGraphicsReadStatus"]=bytes?@"emptyOrOverSafetyLimit":@"noReadableData";
                if(data)CFRelease(data);if(profile)CFRelease(profile);
            }else record[@"readStatus"]=url?@"unexpectedURLValueType":@"noURL";
            [profiles addObject:record];
        }
        discovery[@"profiles"]=profiles;discovery[@"directlyReadableCount"]=@(readable);discovery[@"cgCreatedCount"]=@(createdSpaces);discovery[@"conversionSucceededCount"]=@(successfulConversions);result[@"colorSync"]=discovery;
        if(iterationError)CFRelease(iterationError);
        NSMutableDictionary *captureSymbols=[NSMutableDictionary new];for(NSString *name in @[@"_UIRenderDisplay",@"_UIRenderingBufferCreate",@"kUIRenderingSourceScreen",@"kUIRenderingDestinationGamut",@"kUIRenderingDestinationOpaque",@"kUIRenderingDestinationScale",@"kUIRenderingSourceOrientation",@"kUIRenderingEnforceSecureMode",@"kUIRenderingSourceRect",@"CARenderServerBufferGetTypeID",@"CARenderServerGetBufferWidth",@"CARenderServerGetBufferHeight",@"CARenderServerGetBufferRowBytes",@"CARenderServerGetBufferDataSize",@"CARenderServerGetBufferData",@"IOSurfaceGetTypeID",@"IOSurfaceGetWidth",@"IOSurfaceGetHeight",@"IOSurfaceGetBytesPerRow",@"IOSurfaceGetBaseAddress",@"IOSurfaceGetPixelFormat",@"IOSurfaceLock",@"IOSurfaceUnlock"])captureSymbols[name]=UIRuntimeProfileSymbol(RTLD_DEFAULT,name.UTF8String);result[@"captureSymbolsNotInvoked"]=captureSymbols;
        dlerror();void *coreImage=dlopen("/System/Library/Frameworks/CoreImage.framework/CoreImage",RTLD_LAZY|RTLD_LOCAL);const char *coreImageError=dlerror();Class imageClass=NSClassFromString(@"CIImage");SEL continuous=NSSelectorFromString(@"setContinuousCorners:");NSMutableDictionary *corner=[UIRuntimeProfileMethod(CALayer.class,continuous,NO)mutableCopy];Method method=class_getInstanceMethod(CALayer.class,continuous);BOOL setterABI=NO;if(method){char argument[16]={0},returned[16]={0};method_getArgumentType(method,2,argument,sizeof(argument));method_getReturnType(method,returned,sizeof(returned));setterABI=method_getNumberOfArguments(method)==3&&returned[0]=='v'&&(argument[0]=='B'||argument[0]=='c');corner[@"booleanSetterABI"]=@(setterABI);}
        corner[@"invokedOnDetachedLayer"]=@NO;if(setterABI){@try{CALayer *layer=[CALayer layer];((void(*)(id,SEL,BOOL))objc_msgSend)(layer,continuous,YES);((void(*)(id,SEL,BOOL))objc_msgSend)(layer,continuous,NO);corner[@"invokedOnDetachedLayer"]=@YES;}@catch(NSException *exception){corner[@"exceptionName"]=exception.name;corner[@"exceptionReason"]=exception.reason?:@"";}}
        result[@"objcMethods"]=@{@"CALayer.setContinuousCorners:":corner,@"CIImage.initWithIOSurface:options:":UIRuntimeProfileMethod(imageClass,NSSelectorFromString(@"initWithIOSurface:options:"),NO),@"CIImage.imageWithIOSurface:":UIRuntimeProfileMethod(imageClass,NSSelectorFromString(@"imageWithIOSurface:"),YES),@"coreImageLibraryLoaded":@(coreImage!=NULL),@"coreImageLoadError":coreImageError?@(coreImageError):@"",@"scope":@"CIImage method identity is inspected without constructing a fake surface. CALayer setter runs only on a new detached layer after validating its scalar setter ABI."};
        NSArray<NSString *> *legacyAXSelectors=@[@"accessibilityActionDescription:",@"accessibilityActionNames",@"accessibilityAttributeNames",@"accessibilityAttributeValue:",@"accessibilityChildrenAttribute",@"accessibilityDescriptionAttribute",@"accessibilityFocusedUIElement",@"accessibilityHitTest:",@"accessibilityIsAttributeSettable:",@"accessibilityIsDescriptionAttributeSettable",@"accessibilityIsIgnored",@"accessibilityIsParentAttributeSettable",@"accessibilityIsPositionAttributeSettable",@"accessibilityIsRoleAttributeSettable",@"accessibilityIsRoleDescriptionAttributeSettable",@"accessibilityIsSizeAttributeSettable",@"accessibilityIsTopLevelUIElementAttributeSettable",@"accessibilityIsValueAttributeSettable",@"accessibilityIsWindowAttributeSettable",@"accessibilityParentAttribute",@"accessibilityPerformAction:",@"accessibilityPositionAttribute",@"accessibilityRoleAttribute",@"accessibilityRoleDescriptionAttribute",@"accessibilitySetValue:forAttribute:",@"accessibilitySizeAttribute",@"accessibilityTopLevelUIElementAttribute",@"accessibilityValueAttribute",@"accessibilityWindowAttribute"];
        NSMutableArray *axClasses=[NSMutableArray new];for(NSString *className in @[@"UIAccessibilityElement",@"UIControl",@"UIColoredPencil",@"UIColorPickerPencilView"]){Class cls=NSClassFromString(className);NSMutableDictionary *methods=[NSMutableDictionary new];for(NSString *name in legacyAXSelectors)methods[name]=UIRuntimeProfileMethod(cls,NSSelectorFromString(name),NO);[axClasses addObject:@{@"class":className,@"classLoaded":@(cls!=Nil),@"legacySelectorMetadata":methods}];}
        NSMutableArray *loadedAXImages=[NSMutableArray new];for(uint32_t index=0;index<_dyld_image_count();index++){const char *path=_dyld_get_image_name(index);if(!path)continue;NSString *name=@(path),*lower=name.lowercaseString;if([lower containsString:@"accessibility"]||[lower containsString:@"/axruntime.framework/"]||[lower containsString:@"/uikit.axbundle/"])[loadedAXImages addObject:name];}
        result[@"pencilAccessibilityABI"]=@{@"classes":axClasses,@"alreadyLoadedAccessibilityImages":loadedAXImages,@"legacySelectorInvocations":@0,@"scope":@"Metadata-only snapshot of already-loaded UIKit base classes and the ported pencil classes. Each method records its actual type encoding, defining class and IMP image/symbol when available. No accessibility framework is loaded for this inspection, no legacy selector or unknown ABI is called, and absence before lazy AX loading is recorded as absence in this process snapshot."};
        if(source)CGColorRelease(source);if(sourceSpace)CGColorSpaceRelease(sourceSpace);
        result[@"passed"]=@(baseline);result[@"requiredBaselinePassed"]=@(baseline);result[@"probeCompleted"]=@YES;result[@"completedAt"]=[[NSISO8601DateFormatter new]stringFromDate:NSDate.date];
        // Keep frameworks loaded for the lifetime of this short research run;
        // copied metadata/classes and runtime method addresses are not used after
        // an eager dlclose of their defining image.
        NSError *serializationError=nil;NSData *json=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:&serializationError];NSError *writeError=nil;BOOL wrote=json&&[json writeToURL:outputURL options:NSDataWritingAtomic error:&writeError];
        if(!wrote)NSLog(@"Runtime profile probe output failed: %@",serializationError?:writeError);
        return wrote&&baseline;
    }
}
@end
#else
@implementation UIColorPanelRuntimeProfileProbe
+ (BOOL)runWithOutputURL:(NSURL *)outputURL {
    NSDictionary *result=@{@"schemaVersion":@1,@"probeCompleted":@NO,@"skipped":@YES,@"runtimeChecksPerformed":@NO,@"compiledPrivateAPI":@NO,@"status":@"excludedByCompilePolicy",@"scope":@"Optional private runtime research is excluded from this public executable. No runtime capability check was performed. Public profile behavior is covered by ProfileEditingValidation."};
    NSError *error=nil;NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:&error];BOOL wrote=data&&[data writeToURL:outputURL options:NSDataWritingAtomic error:&error];if(!wrote)NSLog(@"Runtime research skip output failed: %@",error);return wrote;
}
@end
#endif
