#import "UIColorPanelColorProfile.h"
#import <CommonCrypto/CommonDigest.h>
#import <string.h>

NSErrorDomain const UIColorPanelColorProfileErrorDomain = @"UIColorPanelKit.ColorProfile";

@interface UIColorPanelColorProfile ()
@property(nonatomic, readwrite) CGColorSpaceRef CGColorSpace;
@property(nonatomic, copy, readwrite) NSString *displayName;
@property(nonatomic, copy, readwrite) NSString *identifier;
@property(nonatomic, copy, readwrite) NSData *ICCData;
@property(nonatomic, readwrite) CGColorSpaceModel model;
+ (NSString *)displayNameForICCData:(nullable NSData *)data fallback:(NSString *)fallback;
+ (NSString *)identityForColorSpace:(CGColorSpaceRef)space ICCData:(nullable NSData *)data;
@end

@implementation UIColorPanelColorProfile
// BINMAP-ADAPT: UIColorPanelColorProfile.initWithColorSpace:displayName: manifest=reimpl/slider_profile_extras.json — immutable retained CG working-space descriptor.
- (instancetype)initWithColorSpace:(CGColorSpaceRef)colorSpace displayName:(NSString *)displayName {
    NSParameterAssert(colorSpace);
    if (!colorSpace) return nil;
    if ((self = [super init])) {
        _CGColorSpace = CGColorSpaceRetain(colorSpace);
        _model = CGColorSpaceGetModel(colorSpace);
        _ICCData = CFBridgingRelease(CGColorSpaceCopyICCData(colorSpace));
        NSString *nativeName = CFBridgingRelease(CGColorSpaceCopyName(colorSpace));
        NSDictionary *knownNames = @{@"kCGColorSpaceSRGB": @"sRGB", @"kCGColorSpaceDisplayP3": @"Display P3",
            @"kCGColorSpaceAdobeRGB1998": @"Adobe RGB (1998)", @"kCGColorSpaceGenericRGB": @"Generic RGB Profile",
            @"kCGColorSpaceGenericGray": @"Generic Gray Profile", @"kCGColorSpaceGenericCMYK": @"Generic CMYK Profile",
            @"kCGColorSpaceGenericGrayGamma2_2": @"Generic Gray Gamma 2.2 Profile", @"kCGColorSpaceITUR_709": @"Rec. ITU-R BT.709-5",
            @"kCGColorSpaceITUR_2020": @"Rec. ITU-R BT.2020-1", @"kCGColorSpaceROMMRGB": @"ROMM RGB: ISO 22028-2:2013",
            @"kCGColorSpaceDCIP3": @"DCI-P3", @"kCGColorSpaceDeviceRGB": @"Device RGB", @"kCGColorSpaceDeviceGray": @"Device Gray",
            @"kCGColorSpaceDeviceCMYK": @"Device CMYK", @"kCGColorSpaceACESCGLinear": @"ACES CG Linear"};
        NSString *fallback = knownNames[nativeName] ?: nativeName;
        if (!fallback.length) fallback = _model == kCGColorSpaceModelRGB ? @"RGB" : _model == kCGColorSpaceModelMonochrome ? @"Gray" : _model == kCGColorSpaceModelCMYK ? @"CMYK" : @"Color Profile";
        _displayName = displayName.length ? [displayName copy] : [[self.class displayNameForICCData:_ICCData fallback:fallback] copy];
        _identifier = [self.class identityForColorSpace:colorSpace ICCData:_ICCData];
    }
    return self;
}

// BINMAP-ADAPT: UIColorPanelColorProfile.initWithICCData:displayName:error: manifest=reimpl/slider_profile_extras.json — validate actual ICC before preserving its original bytes.
- (instancetype)initWithICCData:(NSData *)ICCData displayName:(NSString *)displayName error:(NSError **)error {
    if (error) *error = nil;
    NSData *input = [ICCData isKindOfClass:NSData.class] ? [ICCData copy] : nil;
    const uint8_t *bytes = input.bytes;
    NSUInteger length = input.length;
    uint32_t declaredLength = length >= 132 ? ((uint32_t)bytes[0] << 24 | (uint32_t)bytes[1] << 16 | (uint32_t)bytes[2] << 8 | bytes[3]) : 0;
    BOOL validHeader = declaredLength >= 132 && declaredLength <= length && bytes[36] == 'a' && bytes[37] == 'c' && bytes[38] == 's' && bytes[39] == 'p';
    CGColorSpaceRef space = validHeader ? CGColorSpaceCreateWithICCData((__bridge CFDataRef)input) : NULL;
    if (!space) {
        if (error) *error = [NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorInvalidICC userInfo:@{NSLocalizedDescriptionKey: @"The ICC color profile is invalid or unsupported."}];
        return nil;
    }
    self = [self initWithColorSpace:space displayName:displayName];
    if (self) {
        _ICCData = input;
        _identifier = [self.class identityForColorSpace:space ICCData:_ICCData];
        if (!displayName.length) _displayName = [self.class displayNameForICCData:_ICCData fallback:_displayName];
    }
    CGColorSpaceRelease(space);
    return self;
}

// BINMAP-ADAPT: UIColorPanelColorProfile.dealloc manifest=reimpl/slider_profile_extras.json — balanced CG retain ownership.
- (void)dealloc { if (_CGColorSpace) CGColorSpaceRelease(_CGColorSpace); }

// BINMAP-ADAPT: UIColorPanelColorProfile.copyWithZone: manifest=reimpl/slider_profile_extras.json — immutable descriptors share identity.
- (id)copyWithZone:(NSZone *)zone { return self; }

// BINMAP-ADAPT: UIColorPanelColorProfile.isEqual: manifest=reimpl/slider_profile_extras.json — display names are not profile identities.
- (BOOL)isEqual:(id)object { return object == self || ([object isKindOfClass:UIColorPanelColorProfile.class] && [_identifier isEqual:((UIColorPanelColorProfile *)object).identifier]); }

// BINMAP-ADAPT: UIColorPanelColorProfile.hash manifest=reimpl/slider_profile_extras.json — paired with the complete profile identifier.
- (NSUInteger)hash { return _identifier.hash; }

// BINMAP-ADAPT: UIColorPanelColorProfile.identityForColorSpace:ICCData: manifest=reimpl/slider_profile_extras.json — exact ICC bytes plus model/component/extended semantics; no localized names in identity.
+ (NSString *)identityForColorSpace:(CGColorSpaceRef)space ICCData:(NSData *)data {
    NSString *semantics = [NSString stringWithFormat:@"UIColorPanelProfile-v1:%ld:%lu:%d:", (long)CGColorSpaceGetModel(space), (unsigned long)CGColorSpaceGetNumberOfComponents(space), CGColorSpaceUsesExtendedRange(space)];
    NSMutableData *identity = [[semantics dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    if (data.length) { [identity appendData:[@"ICC:" dataUsingEncoding:NSUTF8StringEncoding]]; [identity appendData:data]; }
    else {
        [identity appendData:[@"NonICC:" dataUsingEncoding:NSUTF8StringEncoding]];
        id propertyList = CFBridgingRelease(CGColorSpaceCopyPropertyList(space));
        BOOL encoded = NO;
        if (propertyList && [NSPropertyListSerialization propertyList:propertyList isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
            // Canonical traversal avoids depending on NSDictionary iteration order or
            // a binary-plist writer's object-table ordering across processes.
            NSMutableData *description = [NSMutableData data];
            NSMutableArray *pending = [NSMutableArray arrayWithObject:propertyList];
            encoded = YES;
            while (pending.count) {
                id value = pending.lastObject; [pending removeLastObject];
                if ([value isKindOfClass:NSDictionary.class]) {
                    NSArray *keys = [[value allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *left, NSString *right) { return [left compare:right options:NSLiteralSearch]; }];
                    [description appendData:[[NSString stringWithFormat:@"D%lu:", (unsigned long)keys.count] dataUsingEncoding:NSUTF8StringEncoding]];
                    for (NSString *key in keys.reverseObjectEnumerator) { [pending addObject:value[key]]; [pending addObject:key]; }
                } else if ([value isKindOfClass:NSArray.class]) {
                    [description appendData:[[NSString stringWithFormat:@"A%lu:", (unsigned long)[value count]] dataUsingEncoding:NSUTF8StringEncoding]];
                    for (id child in [value reverseObjectEnumerator]) [pending addObject:child];
                } else if ([value isKindOfClass:NSString.class] || [value isKindOfClass:NSData.class]) {
                    BOOL isString = [value isKindOfClass:NSString.class];
                    NSData *bytes = isString ? [value dataUsingEncoding:NSUTF8StringEncoding] : value;
                    if (!bytes) { encoded = NO; break; }
                    [description appendData:[[NSString stringWithFormat:@"%@%lu:", isString ? @"S" : @"B", (unsigned long)bytes.length] dataUsingEncoding:NSUTF8StringEncoding]];
                    [description appendData:bytes];
                } else if ([value isKindOfClass:NSNumber.class]) {
                    if (CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) [description appendData:[([value boolValue] ? @"T" : @"F") dataUsingEncoding:NSUTF8StringEncoding]];
                    else if (CFNumberIsFloatType((__bridge CFNumberRef)value)) {
                        [description appendData:[@"Nf:" dataUsingEncoding:NSUTF8StringEncoding]];
                        CFSwappedFloat64 number = CFConvertDoubleHostToSwapped([value doubleValue]);
                        [description appendBytes:&number length:sizeof(number)];
                    } else {
                        NSString *number = [value stringValue];
                        [description appendData:[[NSString stringWithFormat:@"Ni%lu:%@", (unsigned long)number.length, number] dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                } else if ([value isKindOfClass:NSDate.class]) {
                    [description appendData:[@"Z:" dataUsingEncoding:NSUTF8StringEncoding]];
                    CFSwappedFloat64 date = CFConvertDoubleHostToSwapped([value timeIntervalSinceReferenceDate]);
                    [description appendBytes:&date length:sizeof(date)];
                } else { encoded = NO; break; }
            }
            if (encoded) [identity appendData:description];
        }
        if (!encoded) {
            NSString *name = CFBridgingRelease(CGColorSpaceCopyName(space));
            CGColorSpaceRef restored = name.length ? CGColorSpaceCreateWithName((__bridge CFStringRef)name) : NULL;
            BOOL exactNamedSpace = restored && CFEqual(space, restored);
            if (restored) CGColorSpaceRelease(restored);
            NSString *fallback = exactNamedSpace ? [@"named:" stringByAppendingString:name] : [@"opaque:" stringByAppendingString:NSUUID.UUID.UUIDString];
            [identity appendData:[fallback dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX context; CC_SHA256_Init(&context);
    const uint8_t *cursor = identity.bytes; NSUInteger remaining = identity.length;
    while (remaining) { CC_LONG count = (CC_LONG)MIN(remaining, (NSUInteger)UINT32_MAX); CC_SHA256_Update(&context, cursor, count); cursor += count; remaining -= count; }
    CC_SHA256_Final(digest, &context);
    NSMutableString *identifier = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) [identifier appendFormat:@"%02x", digest[index]];
    return identifier;
}

// BINMAP-ADAPT: UIColorPanelColorProfile.displayNameForICCData:fallback: manifest=reimpl/slider_profile_extras.json — bounded ICC desc/mluc metadata decoding, preserving the profile's own translations.
+ (NSString *)displayNameForICCData:(NSData *)data fallback:(NSString *)fallback {
    if (data.length < 132) return fallback;
    const uint8_t *bytes = data.bytes;
    uint32_t length = (uint32_t)bytes[0] << 24 | (uint32_t)bytes[1] << 16 | (uint32_t)bytes[2] << 8 | bytes[3];
    if (length < 132 || length > data.length || memcmp(bytes + 36, "acsp", 4)) return fallback;
    uint32_t count = (uint32_t)bytes[128] << 24 | (uint32_t)bytes[129] << 16 | (uint32_t)bytes[130] << 8 | bytes[131];
    if (count > (length - 132) / 12) return fallback;
    NSString *bestLocalized = nil, *asciiDescription = nil; NSInteger bestRank = NSIntegerMin;
    NSArray<NSString *> *languages = NSLocale.preferredLanguages;
    for (uint32_t index = 0; index < count; index++) {
        const uint8_t *entry = bytes + 132 + (NSUInteger)index * 12;
        if (memcmp(entry, "desc", 4) && memcmp(entry, "dscm", 4)) continue;
        uint32_t offset = (uint32_t)entry[4] << 24 | (uint32_t)entry[5] << 16 | (uint32_t)entry[6] << 8 | entry[7];
        uint32_t size = (uint32_t)entry[8] << 24 | (uint32_t)entry[9] << 16 | (uint32_t)entry[10] << 8 | entry[11];
        if (offset < 132 + (NSUInteger)count * 12 || offset > length || size > length - offset || size < 12) continue;
        const uint8_t *tag = bytes + offset;
        if (!memcmp(tag, "mluc", 4) && size >= 16) {
            uint32_t records = (uint32_t)tag[8] << 24 | (uint32_t)tag[9] << 16 | (uint32_t)tag[10] << 8 | tag[11];
            uint32_t stride = (uint32_t)tag[12] << 24 | (uint32_t)tag[13] << 16 | (uint32_t)tag[14] << 8 | tag[15];
            if (stride < 12 || records > (size - 16) / stride) continue;
            for (uint32_t recordIndex = 0; recordIndex < records; recordIndex++) {
                const uint8_t *record = tag + 16 + (NSUInteger)recordIndex * stride;
                uint32_t stringLength = (uint32_t)record[4] << 24 | (uint32_t)record[5] << 16 | (uint32_t)record[6] << 8 | record[7];
                uint32_t stringOffset = (uint32_t)record[8] << 24 | (uint32_t)record[9] << 16 | (uint32_t)record[10] << 8 | record[11];
                if (stringOffset < 16 + (NSUInteger)records * stride || stringOffset > size || stringLength > size - stringOffset || (stringLength & 1)) continue;
                NSString *value = [[NSString alloc] initWithBytes:tag + stringOffset length:stringLength encoding:NSUTF16BigEndianStringEncoding];
                value = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                if (!value.length) continue;
                NSString *language = [[NSString alloc] initWithBytes:record length:2 encoding:NSASCIIStringEncoding];
                NSString *country = [[NSString alloc] initWithBytes:record + 2 length:2 encoding:NSASCIIStringEncoding];
                NSInteger rank = [language isEqualToString:@"en"] ? 1 : 0;
                for (NSUInteger preferenceIndex = 0; preferenceIndex < languages.count; preferenceIndex++) {
                    NSDictionary *components = [NSLocale componentsFromLocaleIdentifier:languages[preferenceIndex]];
                    if ([components[NSLocaleLanguageCode] isEqualToString:language]) {
                        NSInteger matchRank = 100000 - (NSInteger)MIN(preferenceIndex, (NSUInteger)999) * 100;
                        NSString *preferredCountry = components[NSLocaleCountryCode];
                        NSString *preferredScript = components[NSLocaleScriptCode];
                        NSString *recordScript = nil;
                        // ICC mluc stores two-letter language/country rather than a
                        // BCP-47 script. Infer only regions with an unambiguous
                        // conventional Chinese script; never change the ICC text.
                        if ([language isEqualToString:@"zh"]) {
                            if ([@[@"CN", @"SG"] containsObject:country]) recordScript = @"Hans";
                            else if ([@[@"TW", @"HK", @"MO"] containsObject:country]) recordScript = @"Hant";
                            if (!preferredScript.length) {
                                if ([@[@"CN", @"SG"] containsObject:preferredCountry ?: @""]) preferredScript = @"Hans";
                                else if ([@[@"TW", @"HK", @"MO"] containsObject:preferredCountry ?: @""]) preferredScript = @"Hant";
                            }
                        }
                        if (preferredScript.length && recordScript.length) matchRank += [preferredScript isEqualToString:recordScript] ? 40 : -40;
                        if ([preferredCountry isEqualToString:country]) matchRank += 10;
                        rank = MAX(rank, matchRank); break;
                    }
                }
                if (!bestLocalized || rank > bestRank) { bestLocalized = value; bestRank = rank; }
            }
        } else if (!memcmp(tag, "desc", 4)) {
            uint32_t stringLength = (uint32_t)tag[8] << 24 | (uint32_t)tag[9] << 16 | (uint32_t)tag[10] << 8 | tag[11];
            if (stringLength > size - 12) continue;
            NSUInteger visibleLength = 0; while (visibleLength < stringLength && tag[12 + visibleLength]) visibleLength++;
            NSString *value = [[NSString alloc] initWithBytes:tag + 12 length:visibleLength encoding:NSASCIIStringEncoding];
            if (!value) value = [[NSString alloc] initWithBytes:tag + 12 length:visibleLength encoding:NSMacOSRomanStringEncoding];
            value = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (value.length && !asciiDescription) asciiDescription = value;
            // ICC v2 may additionally contain a UTF-16 description after its ASCII field.
            NSUInteger unicodeHeader = 12 + (NSUInteger)stringLength;
            if (unicodeHeader <= size && size - unicodeHeader >= 8) {
                const uint8_t *unicode = tag + unicodeHeader;
                uint32_t characters = (uint32_t)unicode[4] << 24 | (uint32_t)unicode[5] << 16 | (uint32_t)unicode[6] << 8 | unicode[7];
                if (characters <= (size - unicodeHeader - 8) / 2 && characters) {
                    NSString *unicodeValue = [[NSString alloc] initWithBytes:unicode + 8 length:(NSUInteger)characters * 2 encoding:NSUTF16BigEndianStringEncoding];
                    unicodeValue = [unicodeValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\0 \n\r\t"]];
                    if (unicodeValue.length && !bestLocalized) { bestLocalized = unicodeValue; bestRank = -1; }
                }
            }
        }
    }
    return bestLocalized ?: asciiDescription ?: fallback;
}
@end
