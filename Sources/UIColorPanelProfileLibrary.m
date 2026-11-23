#import "UIColorPanelProfileLibrary.h"
#import <dlfcn.h>
#import <stdbool.h>

@interface UIColorPanelProfileLibrary () {
    dispatch_queue_t _discoveryQueue;
    NSUInteger _discoveryGeneration;
    NSArray<UIColorPanelColorProfile *> *_systemProfiles;
    UIColorPanelProfileDiscoveryStatus _discoveryStatus;
    NSError *_discoveryError;
}
- (NSDictionary<NSString *, id> *)performSystemDiscoveryUsingSPI:(BOOL)useSPI;
- (void)consumeSystemProfileDictionary:(CFDictionaryRef)dictionary context:(NSMutableDictionary *)context;
@end

#if UICOLORPANEL_ENABLE_PRIVATE_API
typedef void (*UIColorPanelIterateProfilesImport)(bool (*)(CFDictionaryRef, void *), uint32_t *, void *, CFErrorRef *);
// BINMAP-ADAPT: UIColorPanelProfileEnumerationCallback manifest=reimpl/slider_profile_extras.json — sole C ABI bridge for the validated ColorSync iterator callback.
static bool UIColorPanelProfileEnumerationCallback(CFDictionaryRef dictionary, void *userInfo) {
    @autoreleasepool {
        NSMutableDictionary *context = (__bridge NSMutableDictionary *)userInfo;
        [context[@"library"] consumeSystemProfileDictionary:dictionary context:context];
    }
    return true;
}
#endif

@implementation UIColorPanelProfileLibrary
// BINMAP-ADAPT: UIColorPanelProfileLibrary.init manifest=reimpl/slider_profile_extras.json — each library owns a serial discovery lane and a cancellation generation.
- (instancetype)init {
    if ((self = [super init])) {
        _systemProfiles = @[];
        _discoveryStatus = UIColorPanelProfileDiscoveryStatusDisabled;
        _discoveryQueue = dispatch_queue_create("org.uicolorpanelkit.profiles.discovery", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.dealloc manifest=reimpl/slider_profile_extras.json — invalidate any work that has not acquired the library.
- (void)dealloc { _discoveryGeneration++; }

// BINMAP-ADAPT: UIColorPanelProfileLibrary.systemProfiles manifest=reimpl/slider_profile_extras.json — synchronized snapshot read paired with atomic batch publication.
- (NSArray<UIColorPanelColorProfile *> *)systemProfiles { @synchronized (self) { return _systemProfiles; } }

// BINMAP-ADAPT: UIColorPanelProfileLibrary.discoveryStatus manifest=reimpl/slider_profile_extras.json — synchronized status read; observers see the complete published state.
- (UIColorPanelProfileDiscoveryStatus)discoveryStatus { @synchronized (self) { return _discoveryStatus; } }

// BINMAP-ADAPT: UIColorPanelProfileLibrary.discoveryError manifest=reimpl/slider_profile_extras.json — synchronized strong snapshot read.
- (NSError *)discoveryError { @synchronized (self) { return _discoveryError; } }

// BINMAP-ADAPT: UIColorPanelProfileLibrary.standardProfiles manifest=reimpl/slider_profile_extras.json — attempt actual named CG spaces, excluding constants absent from the runtime.
+ (NSArray<UIColorPanelColorProfile *> *)standardProfiles {
    static NSArray<UIColorPanelColorProfile *> *standardProfiles;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray<UIColorPanelColorProfile *> *profiles = [NSMutableArray array];
        NSArray<NSString *> *symbols = @[@"kCGColorSpaceSRGB", @"kCGColorSpaceDisplayP3", @"kCGColorSpaceAdobeRGB1998",
        @"kCGColorSpaceGenericRGB", @"kCGColorSpaceITUR_709", @"kCGColorSpaceITUR_2020", @"kCGColorSpaceROMMRGB",
        @"kCGColorSpaceDCIP3", @"kCGColorSpaceACESCGLinear", @"kCGColorSpaceGenericGray", @"kCGColorSpaceGenericGrayGamma2_2",
        @"kCGColorSpaceGenericCMYK"];
        for (NSString *symbol in symbols) {
            const CFStringRef *address = dlsym(RTLD_DEFAULT, symbol.UTF8String);
            CFStringRef name = address ? *address : NULL;
            if (!name || CFGetTypeID(name) != CFStringGetTypeID()) continue;
            CGColorSpaceRef space = CGColorSpaceCreateWithName(name);
            if (space) {
                [profiles addObject:[[UIColorPanelColorProfile alloc] initWithColorSpace:space displayName:nil]];
                CGColorSpaceRelease(space);
            }
        }
        CGColorSpaceRef deviceGray = CGColorSpaceCreateDeviceGray();
        CGColorSpaceRef deviceRGB = CGColorSpaceCreateDeviceRGB();
        CGColorSpaceRef deviceCMYK = CGColorSpaceCreateDeviceCMYK();
        if (deviceGray) { [profiles addObject:[[UIColorPanelColorProfile alloc] initWithColorSpace:deviceGray displayName:@"Device Gray"]]; CGColorSpaceRelease(deviceGray); }
        if (deviceRGB) { [profiles addObject:[[UIColorPanelColorProfile alloc] initWithColorSpace:deviceRGB displayName:@"Device RGB"]]; CGColorSpaceRelease(deviceRGB); }
        if (deviceCMYK) { [profiles addObject:[[UIColorPanelColorProfile alloc] initWithColorSpace:deviceCMYK displayName:@"Device CMYK"]]; CGColorSpaceRelease(deviceCMYK); }
        standardProfiles = [UIColorPanelProfileLibrary profilesByCombiningProfiles:@[profiles]];
    });
    return standardProfiles;
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.profilesByCombiningProfiles: manifest=reimpl/slider_profile_extras.json — ordered identity merge; display-name collisions do not discard profiles.
+ (NSArray<UIColorPanelColorProfile *> *)profilesByCombiningProfiles:(NSArray<NSArray<UIColorPanelColorProfile *> *> *)profileGroups {
    NSMutableArray<UIColorPanelColorProfile *> *profiles = [NSMutableArray array];
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    for (id group in profileGroups) {
        if (![group isKindOfClass:NSArray.class]) continue;
        for (id object in group) {
            if (![object isKindOfClass:UIColorPanelColorProfile.class]) continue;
            UIColorPanelColorProfile *profile = object;
            if (![identifiers containsObject:profile.identifier]) { [identifiers addObject:profile.identifier]; [profiles addObject:profile]; }
        }
    }
    return [profiles copy];
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.runtimeCapabilities manifest=reimpl/slider_profile_extras.json — independent weak export checks, with all optional ColorSync names and paths compiled out of the public variant.
+ (NSDictionary<NSString *, id> *)runtimeCapabilities {
    NSMutableDictionary *capabilities = [@{@"CGColorSpaceCreateExtended": @(dlsym(RTLD_DEFAULT, "CGColorSpaceCreateExtended") != NULL),
        @"CGColorSpaceCreateLinearized": @(dlsym(RTLD_DEFAULT, "CGColorSpaceCreateLinearized") != NULL),
        @"privateProviderCompiled": @NO} mutableCopy];
    for (NSString *symbol in @[@"kCGColorSpaceExtendedDisplayP3", @"kCGColorSpaceExtendedLinearDisplayP3"]) {
        const CFStringRef *address = dlsym(RTLD_DEFAULT, symbol.UTF8String);
        CFStringRef value = address ? *address : NULL;
        capabilities[symbol] = @(value && CFGetTypeID(value) == CFStringGetTypeID());
    }
#if UICOLORPANEL_ENABLE_PRIVATE_API
    capabilities[@"privateProviderCompiled"] = @YES;
    void *handle = dlopen("/System/Library/PrivateFrameworks/ColorSync.framework/ColorSync", RTLD_LAZY | RTLD_LOCAL);
    if (!handle) handle = dlopen("/System/Library/Frameworks/ColorSync.framework/ColorSync", RTLD_LAZY | RTLD_LOCAL);
    capabilities[@"providerLoaded"] = @(handle != NULL);
    if (handle) {
        for (NSString *symbol in @[@"ColorSyncIterateInstalledProfiles", @"ColorSyncIterateInstalledProfilesWithOptions", @"ColorSyncProfileCreate", @"ColorSyncProfileCreateWithURL", @"ColorSyncProfileCopyData", @"ColorSyncProfileCopyDescriptionString"]) capabilities[symbol] = @(dlsym(handle, symbol.UTF8String) != NULL);
        for (NSString *symbol in @[@"kColorSyncProfileURL", @"kColorSyncProfileDescription", @"kColorSyncProfileCacheSeed", @"kColorSyncProfileRepositoryChangeNotification", @"kColorSyncWaitForCacheReply"]) {
            const CFStringRef *address = dlsym(handle, symbol.UTF8String);
            CFStringRef value = address ? *address : NULL;
            capabilities[symbol] = @(value && CFGetTypeID(value) == CFStringGetTypeID());
        }
        dlclose(handle);
    }
#endif
    return [capabilities copy];
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.createExtendedColorSpace: manifest=reimpl/slider_profile_extras.json — exact optional CG import, without an iOS availability-version cutoff or substitute.
+ (CGColorSpaceRef)createExtendedColorSpace:(CGColorSpaceRef)space {
    CGColorSpaceRef (*create)(CGColorSpaceRef) = dlsym(RTLD_DEFAULT, "CGColorSpaceCreateExtended");
    return space && create ? create(space) : NULL;
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.createLinearizedColorSpace: manifest=reimpl/slider_profile_extras.json — independently resolve the linearized operation; it never stands in for extended range.
+ (CGColorSpaceRef)createLinearizedColorSpace:(CGColorSpaceRef)space {
    CGColorSpaceRef (*create)(CGColorSpaceRef) = dlsym(RTLD_DEFAULT, "CGColorSpaceCreateLinearized");
    return space && create ? create(space) : NULL;
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.refreshSystemProfilesUsingSPI:completion: manifest=reimpl/slider_profile_extras.json — worker discovery, main-queue commit, and generation-checked completion.
- (void)refreshSystemProfilesUsingSPI:(BOOL)useSPI completion:(void (^)(UIColorPanelProfileLibrary *))completion {
    NSUInteger generation;
    @synchronized (self) { generation = ++_discoveryGeneration; }
    // Main-queue publication keeps KVO transactions ordered without holding the
    // state lock while application observers or completions execute. Background
    // requests still supersede old generations immediately, before queueing here.
    void (^beginDiscovery)(void) = ^{
        @synchronized (self) { if (generation != self->_discoveryGeneration) return; }
        NSMutableArray<NSString *> *notifiedKeys = [NSMutableArray array];
        for (NSString *key in @[@"discoveryStatus", @"discoveryError"]) {
            [self willChangeValueForKey:key];
            [notifiedKeys addObject:key];
            // Prior-value observers may synchronously cancel or supersede this request.
            @synchronized (self) { if (generation != self->_discoveryGeneration) break; }
        }
        @synchronized (self) {
            if (generation == self->_discoveryGeneration) {
                self->_discoveryStatus = UIColorPanelProfileDiscoveryStatusDiscovering;
                self->_discoveryError = nil;
            }
        }
        BOOL current = YES;
        for (NSString *key in notifiedKeys.reverseObjectEnumerator) {
            [self didChangeValueForKey:key];
            @synchronized (self) { if (generation != self->_discoveryGeneration) current = NO; }
        }
        if (!current) return;
        @synchronized (self) { if (generation != self->_discoveryGeneration) return; }
        __weak UIColorPanelProfileLibrary *weakSelf = self;
        dispatch_async(self->_discoveryQueue, ^{
            UIColorPanelProfileLibrary *library = weakSelf;
            if (!library) return;
            @synchronized (library) { if (generation != library->_discoveryGeneration) return; }
            NSDictionary *result = [library performSystemDiscoveryUsingSPI:useSPI];
            dispatch_async(dispatch_get_main_queue(), ^{
                @synchronized (library) { if (generation != library->_discoveryGeneration) return; }
                NSMutableArray<NSString *> *resultKeys = [NSMutableArray array];
                for (NSString *key in @[@"systemProfiles", @"discoveryStatus", @"discoveryError"]) {
                    [library willChangeValueForKey:key];
                    [resultKeys addObject:key];
                    @synchronized (library) { if (generation != library->_discoveryGeneration) break; }
                }
                @synchronized (library) {
                    if (generation == library->_discoveryGeneration) {
                        // Publish the complete state before any post-change observer runs.
                        library->_systemProfiles = [result[@"profiles"] copy] ?: @[];
                        library->_discoveryStatus = [result[@"status"] integerValue];
                        library->_discoveryError = result[@"error"];
                    }
                }
                BOOL deliver = YES;
                for (NSString *key in resultKeys.reverseObjectEnumerator) {
                    [library didChangeValueForKey:key];
                    @synchronized (library) { if (generation != library->_discoveryGeneration) deliver = NO; }
                }
                if (!deliver) return;
                // Delivery begins at this final generation check. A cancellation
                // ordered after it may stop future work but cannot retract a
                // completion whose delivery has already begun. No client code
                // runs while the state mutex is held.
                @synchronized (library) { if (generation != library->_discoveryGeneration) return; }
                if (completion) completion(library);
            });
        });
    };
    if (NSThread.isMainThread) beginDiscovery();
    else dispatch_async(dispatch_get_main_queue(), beginDiscovery);
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.cancelPendingDiscovery manifest=reimpl/slider_profile_extras.json — old results and completions cannot overwrite a newer request; retained snapshot remains identifiable.
- (void)cancelPendingDiscovery {
    NSUInteger generation;
    @synchronized (self) { generation = ++_discoveryGeneration; }
    void (^publishCancellation)(void) = ^{
        @synchronized (self) { if (generation != self->_discoveryGeneration) return; }
        NSMutableArray<NSString *> *notifiedKeys = [NSMutableArray array];
        for (NSString *key in @[@"discoveryStatus", @"discoveryError"]) {
            [self willChangeValueForKey:key];
            [notifiedKeys addObject:key];
            @synchronized (self) { if (generation != self->_discoveryGeneration) break; }
        }
        @synchronized (self) {
            if (generation == self->_discoveryGeneration) {
                self->_discoveryStatus = UIColorPanelProfileDiscoveryStatusCancelled;
                self->_discoveryError = nil;
            }
        }
        for (NSString *key in notifiedKeys.reverseObjectEnumerator) {
            [self didChangeValueForKey:key];
            // Balance every opened KVO transaction even if a newer generation
            // superseded this one during an earlier post-change notification.
            @synchronized (self) { if (generation != self->_discoveryGeneration) continue; }
        }
    };
    if (NSThread.isMainThread) publishCancellation();
    else dispatch_async(dispatch_get_main_queue(), publishCancellation);
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.consumeSystemProfileDictionary:context: manifest=reimpl/slider_profile_extras.json — type-checked callback data, real file/ICC validation and explicit partial-failure recording.
- (void)consumeSystemProfileDictionary:(CFDictionaryRef)dictionary context:(NSMutableDictionary *)context {
    NSMutableArray<NSError *> *errors = context[@"errors"];
    if (!dictionary || CFGetTypeID(dictionary) != CFDictionaryGetTypeID()) {
        [errors addObject:[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorUnreadableProfile userInfo:@{NSLocalizedDescriptionKey: @"The system returned invalid color-profile metadata."}]];
        return;
    }
    CFTypeRef urlValue = CFDictionaryGetValue(dictionary, (__bridge const void *)context[@"urlKey"]);
    if (!urlValue || CFGetTypeID(urlValue) != CFURLGetTypeID() || ![(__bridge NSURL *)urlValue isFileURL]) {
        [errors addObject:[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorUnreadableProfile userInfo:@{NSLocalizedDescriptionKey: @"The system color profile has no readable file URL."}]];
        return;
    }
    NSURL *url = (__bridge NSURL *)urlValue;
    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&readError];
    NSError *profileError = nil;
    UIColorPanelColorProfile *profile = data ? [[UIColorPanelColorProfile alloc] initWithICCData:data displayName:nil error:&profileError] : nil;
    if (!profile) {
        NSMutableDictionary *details = [@{NSLocalizedDescriptionKey: @"An installed color profile could not be read or validated.", NSURLErrorKey: url} mutableCopy];
        if (readError ?: profileError) details[NSUnderlyingErrorKey] = readError ?: profileError;
        [errors addObject:[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorUnreadableProfile userInfo:details]];
        return;
    }
    [context[@"profiles"] addObject:profile];
}

// BINMAP-ADAPT: UIColorPanelProfileLibrary.performSystemDiscoveryUsingSPI: manifest=reimpl/slider_profile_extras.json — exact iterator ABI with only iterator+URL-key as required dependencies; unavailable cache/notification extensions do not disable discovery.
- (NSDictionary<NSString *, id> *)performSystemDiscoveryUsingSPI:(BOOL)useSPI {
    // Runtime policy is checked before even loading the optional provider.
    NSDictionary *capabilities = useSPI ? self.class.runtimeCapabilities : @{};
    NSMutableDictionary *result = [@{@"status": @(UIColorPanelProfileDiscoveryStatusDisabled), @"profiles": @[], @"capabilities": capabilities} mutableCopy];
    if (!useSPI) return result;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    // Reject an incomplete capability snapshot before entering the provider.
    // Resolve and validate again below: a snapshot never replaces live checks.
    BOOL providerCapable = [capabilities[@"providerLoaded"] boolValue] &&
        [capabilities[@"ColorSyncIterateInstalledProfiles"] boolValue] &&
        [capabilities[@"kColorSyncProfileURL"] boolValue];
    void *handle = providerCapable ? dlopen("/System/Library/PrivateFrameworks/ColorSync.framework/ColorSync", RTLD_LAZY | RTLD_LOCAL) : NULL;
    if (!handle && providerCapable) handle = dlopen("/System/Library/Frameworks/ColorSync.framework/ColorSync", RTLD_LAZY | RTLD_LOCAL);
    UIColorPanelIterateProfilesImport iterate = handle ? dlsym(handle, "ColorSyncIterateInstalledProfiles") : NULL;
    const CFStringRef *urlAddress = handle ? dlsym(handle, "kColorSyncProfileURL") : NULL;
    CFStringRef urlKey = urlAddress ? *urlAddress : NULL;
    if (!handle || !iterate || !urlKey || CFGetTypeID(urlKey) != CFStringGetTypeID()) {
        result[@"status"] = @(UIColorPanelProfileDiscoveryStatusUnavailable);
        result[@"error"] = [NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorDiscoveryUnavailable userInfo:@{NSLocalizedDescriptionKey: @"System color-profile discovery is unavailable in this runtime."}];
        if (handle) dlclose(handle);
        return result;
    }
    NSMutableDictionary *context = [@{@"library": self, @"profiles": [NSMutableArray array], @"errors": [NSMutableArray array], @"urlKey": (__bridge NSString *)urlKey} mutableCopy];
    CFErrorRef providerError = NULL;
    uint32_t seed = 0;
    iterate(UIColorPanelProfileEnumerationCallback, &seed, (__bridge void *)context, &providerError);
    NSError *error = CFBridgingRelease(providerError);
    NSArray *profiles = [self.class profilesByCombiningProfiles:@[context[@"profiles"]]];
    NSArray<NSError *> *errors = context[@"errors"];
    result[@"profiles"] = profiles;
    if (error || errors.count) {
        NSMutableDictionary *details = [@{NSLocalizedDescriptionKey: @"System color-profile discovery did not complete without errors.", @"skippedProfileCount": @(errors.count)} mutableCopy];
        if (error ?: errors.firstObject) details[NSUnderlyingErrorKey] = error ?: errors.firstObject;
        if (errors.count) details[@"profileErrors"] = errors;
        result[@"error"] = [NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorDiscoveryFailed userInfo:details];
        result[@"status"] = @(profiles.count ? UIColorPanelProfileDiscoveryStatusPartial : UIColorPanelProfileDiscoveryStatusFailed);
    } else result[@"status"] = @(profiles.count ? UIColorPanelProfileDiscoveryStatusAvailable : UIColorPanelProfileDiscoveryStatusEmpty);
    dlclose(handle);
#else
    result[@"status"] = @(UIColorPanelProfileDiscoveryStatusDisabled);
    result[@"error"] = [NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorDiscoveryDisabled userInfo:@{NSLocalizedDescriptionKey: @"This build does not enable the optional system color-profile provider."}];
#endif
    return result;
}
@end
