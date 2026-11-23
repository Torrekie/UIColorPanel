#import "UIColorValue.h"
#import "UIColorValue+FavoriteRecord.h"
#import <math.h>
#import <dlfcn.h>
#import <string.h>
#if TARGET_OS_IOS
#import "UIColorArchiveRecord.h"
#import <objc/runtime.h>
#endif

NSErrorDomain const UIColorValueErrorDomain = @"UIColorValueErrorDomain";

// BINMAP-ADAPT: UIColorPickerFavoriteSlotIsCorrupt manifest=reimpl/color_model_extras.json
BOOL UIColorPickerFavoriteSlotIsCorrupt(id value) {
    if (![value isKindOfClass:NSDictionary.class]) return YES;
    NSNumber *version = value[@"version"];
    if (![version isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)version) == CFBooleanGetTypeID() ||
        !isfinite(version.doubleValue) || version.doubleValue < 1 || floor(version.doubleValue) != version.doubleValue) return YES;
    if (![version isEqual:@1]) return NO;

    NSNumber *model = value[@"model"];
    if (![model isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)model) == CFBooleanGetTypeID() ||
        !isfinite(model.doubleValue) || floor(model.doubleValue) != model.doubleValue) return YES;
    NSUInteger channels;
    switch (model.integerValue) {
        case kCGColorSpaceModelMonochrome: channels = 1; break;
        case kCGColorSpaceModelRGB:
        case kCGColorSpaceModelLab: channels = 3; break;
        case kCGColorSpaceModelCMYK: channels = 4; break;
        default: return NO;  // Preserve a color model this reader cannot interpret.
    }
    NSNumber *count = value[@"componentCount"];
    NSArray *components = value[@"components"];
    if (![count isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)count) == CFBooleanGetTypeID() ||
        count.doubleValue != channels || ![components isKindOfClass:NSArray.class] || components.count != channels + 1) return YES;
    for (NSNumber *number in components) {
        if (![number isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)number) == CFBooleanGetTypeID() ||
            !isfinite(number.doubleValue)) return YES;
    }
    double alpha = [components.lastObject doubleValue];
    if (alpha < 0 || alpha > 1) return YES;

    NSString *name = value[@"spaceName"];
    NSData *profile = value[@"iccData"];
    NSNumber *extended = value[@"extendedRange"];
    if (name && ![name isKindOfClass:NSString.class]) return YES;
    if (!name.length && !profile) return YES;
    if (profile) {
        // ICC.1 §7.2: size and signature are independent of supported profile versions or transforms.
        if (![profile isKindOfClass:NSData.class] || profile.length < 132) return YES;
        const uint8_t *bytes = profile.bytes;
        uint32_t size;
        memcpy(&size, bytes, sizeof(size));
        size = CFSwapInt32BigToHost(size);
        if (size < 132 || size > profile.length || memcmp(bytes + 36, "acsp", 4) != 0) return YES;
    }
    return extended && (![extended isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)extended) != CFBooleanGetTypeID());
}

@implementation UIColorValue {
    CGColorRef _color;
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-01 manifest=reimpl/color_model_extras.json
- (instancetype)initWithCGColor:(CGColorRef)color {
    if (!color) return nil;
    self = [super init];
    if (self) _color = CGColorRetain(color);
    return self;
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-02 manifest=reimpl/color_model_extras.json
- (void)dealloc {
    CGColorRelease(_color);
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-03 manifest=reimpl/color_model_extras.json
- (CGColorRef)CGColor {
    return _color;
}

#if TARGET_OS_IOS
// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-04 manifest=reimpl/color_model_extras.json
- (UIColor *)UIColor {
    UIColor *color=[UIColor colorWithCGColor:_color];
    // BINMAP-ADAPT: retain the existing archive bridge's named-color identity
    // when transporting an unedited canonical value through UIKit.
    NSDictionary *metadata=objc_getAssociatedObject(self,&UIColorArchiveMetadataAssociationKey);
    if(metadata&&color)objc_setAssociatedObject(color,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return color;
}
#endif

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-05 manifest=reimpl/color_model_extras.json
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

// BINMAP-ADAPT: UIColorValue.isEqual: — canonical color-space/components equality for the UIKit object bridge.
- (BOOL)isEqual:(id)object {
    return object==self || ([object isKindOfClass:UIColorValue.class] && CGColorEqualToColor(_color,[object CGColor]));
}

// BINMAP-ADAPT: UIColorValue.hash — Core Graphics equality and hash remain paired.
- (NSUInteger)hash { return CFHash(_color); }

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-06 manifest=reimpl/color_model_extras.json
- (UIColorValue *)copyWithAlpha:(CGFloat)alpha {
    if (!isfinite(alpha) || alpha < 0 || alpha > 1) return nil;
    CGColorRef color = CGColorCreateCopyWithAlpha(_color, alpha);
    UIColorValue *result = color ? [[UIColorValue alloc] initWithCGColor:color] : nil;
    if (color) CGColorRelease(color);
    return result;
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-07 manifest=reimpl/color_model_extras.json
- (UIColorValue *)colorByConvertingToSpace:(CGColorSpaceRef)space error:(NSError **)error {
    CGColorSpaceRef source = CGColorGetColorSpace(_color);
    if (!space || !source || CGColorSpaceGetModel(source) == kCGColorSpaceModelPattern ||
        CGColorSpaceGetModel(space) == kCGColorSpaceModelPattern || CGColorSpaceGetModel(space) == kCGColorSpaceModelIndexed) {
        if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:UIColorValueErrorUnsupportedSpace
                                          userInfo:@{NSLocalizedDescriptionKey: @"This color space cannot be converted."}];
        return nil;
    }
    if (CFEqual(source, space)) return self;
    CGColorRef converted = CGColorCreateCopyByMatchingToColorSpace(space, kCGRenderingIntentDefault, _color, NULL);
    if (!converted) {
        if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:UIColorValueErrorConversionFailed
                                          userInfo:@{NSLocalizedDescriptionKey: @"Core Graphics could not convert this color."}];
        return nil;
    }
    UIColorValue *result = [[UIColorValue alloc] initWithCGColor:converted];
    CGColorRelease(converted);
    return result;
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-08 manifest=reimpl/color_model_extras.json
- (BOOL)getRGBComponents:(CGFloat [4])components inColorSpace:(CGColorSpaceRef)space error:(NSError **)error {
    if (!components || !space || CGColorSpaceGetModel(space) != kCGColorSpaceModelRGB) {
        if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:UIColorValueErrorUnsupportedSpace
                                          userInfo:@{NSLocalizedDescriptionKey: @"Choose an RGB color space for RGB components."}];
        return NO;
    }
    UIColorValue *converted = [self colorByConvertingToSpace:space error:error];
    if (!converted || CGColorGetNumberOfComponents(converted.CGColor) != 4) return NO;
    const CGFloat *values = CGColorGetComponents(converted.CGColor);
    for (NSUInteger i = 0; i < 4; i++) components[i] = values[i];
    return YES;
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-09 manifest=reimpl/color_model_extras.json
- (NSDictionary *)propertyListRepresentationWithError:(NSError **)error {
    CGColorSpaceRef space = CGColorGetColorSpace(_color);
    CGColorSpaceModel model = space ? CGColorSpaceGetModel(space) : kCGColorSpaceModelUnknown;
    if (model != kCGColorSpaceModelRGB && model != kCGColorSpaceModelMonochrome && model != kCGColorSpaceModelCMYK && model != kCGColorSpaceModelLab) {
        if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:UIColorValueErrorUnsupportedSpace
                                          userInfo:@{NSLocalizedDescriptionKey: @"This color space cannot be saved as components."}];
        return nil;
    }
    CFStringRef spaceName = CGColorSpaceCopyName(space);
    CFDataRef profile = CGColorSpaceCopyICCData(space);
    NSMutableDictionary *representation = [@{@"version": @1, @"model": @(model), @"componentCount": @(CGColorSpaceGetNumberOfComponents(space)), @"extendedRange": @(CGColorSpaceUsesExtendedRange(space))} mutableCopy];
    if (spaceName) {
        CGColorSpaceRef namedSpace = CGColorSpaceCreateWithName(spaceName);
        if (namedSpace && CFEqual(namedSpace, space)) representation[@"spaceName"] = (__bridge NSString *)spaceName;
        if (namedSpace) CGColorSpaceRelease(namedSpace);
        CFRelease(spaceName);
    }
    if (profile) { representation[@"iccData"] = (__bridge NSData *)profile; CFRelease(profile); }
    if (!representation[@"spaceName"] && !representation[@"iccData"]) {
        if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:UIColorValueErrorUnsupportedSpace
                                          userInfo:@{NSLocalizedDescriptionKey: @"This color space has no restorable name or ICC profile."}];
        return nil;
    }
    const CGFloat *values = CGColorGetComponents(_color);
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:CGColorGetNumberOfComponents(_color)];
    for (NSUInteger i = 0; i < CGColorGetNumberOfComponents(_color); i++) {
        if (!isfinite(values[i])) {
            if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:UIColorValueErrorInvalidArchive
                                              userInfo:@{NSLocalizedDescriptionKey: @"Non-finite color components cannot be saved."}];
            return nil;
        }
        [components addObject:@(values[i])];
    }
    representation[@"components"] = components;
    return representation;
}

// BINMAP-ADAPT: id=BINMAP-ADAPT-COLOR-10 manifest=reimpl/color_model_extras.json
- (instancetype)initWithPropertyList:(id)propertyList error:(NSError **)error {
    CGColorSpaceRef space = NULL;
    CGColorRef restored = NULL;
    UIColorValueError failure = UIColorValueErrorInvalidArchive;
    if ([propertyList isKindOfClass:NSDictionary.class]) {
        NSDictionary *archive = propertyList;
        NSArray *components = archive[@"components"];
        NSNumber *model = archive[@"model"];
        NSNumber *count = archive[@"componentCount"];
        id name = archive[@"spaceName"], profile = archive[@"iccData"], extended = archive[@"extendedRange"];
        if (!UIColorPickerFavoriteSlotIsCorrupt(archive) && [archive[@"version"] isEqual:@1] &&
            model.doubleValue >= kCGColorSpaceModelMonochrome && model.doubleValue <= kCGColorSpaceModelLab) {
            CGFloat values[5];
            for (NSUInteger i = 0; i < components.count; i++) values[i] = [components[i] doubleValue];
            CGColorSpaceRef named = name ? CGColorSpaceCreateWithName((__bridge CFStringRef)name) : NULL;
            // Legacy records predate extendedRange. Preserve the named extended semantics,
            // including names unavailable on the restoring OS, without guessing from components.
            BOOL wantsExtended = extended ? [extended boolValue] :
                (named && CGColorSpaceUsesExtendedRange(named)) || [@[@"kCGColorSpaceExtendedSRGB", @"kCGColorSpaceExtendedLinearSRGB",
                    @"kCGColorSpaceExtendedGray", @"kCGColorSpaceExtendedLinearGray", @"kCGColorSpaceExtendedDisplayP3",
                    @"kCGColorSpaceExtendedLinearDisplayP3", @"kCGColorSpaceExtendedITUR_2020", @"kCGColorSpaceExtendedLinearITUR_2020"] containsObject:name ?: @""];
            CFDataRef namedProfile = named ? CGColorSpaceCopyICCData(named) : NULL;
            // The name is a hint: OS releases can ship different ICC bytes for the same name.
            BOOL sameProfile = profile && namedProfile && CFEqual((__bridge CFDataRef)profile, namedProfile);
            if (profile) {
                if (sameProfile && CGColorSpaceUsesExtendedRange(named) == wantsExtended) space = CGColorSpaceRetain(named);
                else space = CGColorSpaceCreateWithICCData((__bridge CFDataRef)profile);
            } else if (named) space = CGColorSpaceRetain(named);
            if (namedProfile) CFRelease(namedProfile);
            if (named) CGColorSpaceRelease(named);
            if (space && wantsExtended && !CGColorSpaceUsesExtendedRange(space)) {
                CGColorSpaceRef extendedSpace = NULL;
                CGColorSpaceRef (*createExtended)(CGColorSpaceRef) = dlsym(RTLD_DEFAULT, "CGColorSpaceCreateExtended");
                if (createExtended) extendedSpace = createExtended(space);
                CGColorSpaceRelease(space);
                space = extendedSpace;
                if (!space || !CGColorSpaceUsesExtendedRange(space)) failure = UIColorValueErrorUnsupportedSpace;
            }
            BOOL valid = space && CGColorSpaceUsesExtendedRange(space) == wantsExtended &&
                CGColorSpaceGetModel(space) == model.integerValue && CGColorSpaceGetNumberOfComponents(space) == count.unsignedIntegerValue;
            if (valid) restored = CGColorCreate(space, values);
        }
    }
    if (space) CGColorSpaceRelease(space);
    if (!restored) {
        if (error) *error = [NSError errorWithDomain:UIColorValueErrorDomain code:failure
            userInfo:@{NSLocalizedDescriptionKey: failure == UIColorValueErrorUnsupportedSpace ?
                @"This system cannot restore the saved extended ICC color space." : @"The saved color or its color space is invalid."}];
        return nil;
    }
    self = [self initWithCGColor:restored];
    CGColorRelease(restored);
    return self;
}
@end
