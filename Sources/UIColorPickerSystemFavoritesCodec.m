#import "UIColorPickerSystemFavoritesCodec.h"

#if defined(UICOLORPANEL_ENABLE_PRIVATE_API) && UICOLORPANEL_ENABLE_PRIVATE_API
#import "UIColorValue.h"
#import "UIColorPickerFavoritesStore+Internal.h"
#import <math.h>
#import <string.h>

// BINMAP-ADAPT: UIColorPickerDecodeSystemColor manifest=reimpl/favorites_sharing_api_manifest.json
static UIColorValue *UIColorPickerDecodeSystemColor(id entry, BOOL legacy, BOOL *damaged) {
    if (legacy) {
        if (![entry isKindOfClass:NSData.class]) {
            *damaged = ![entry isKindOfClass:NSDictionary.class] && ![entry isKindOfClass:NSArray.class];
            return nil;
        }
        NSError *error = nil;
        UIColor *archived = [NSKeyedUnarchiver unarchivedObjectOfClass:UIColor.class fromData:entry error:&error];
        if (!archived) {
            // Secure decoding can fail for a valid archive containing a class this OS does not know.
            // Only malformed archive bytes identify damage independent of class availability.
            NSData *data = entry;
            if (data.length >= 8 && memcmp(data.bytes, "bplist", 6) == 0 && memcmp(data.bytes, "bplist00", 8) != 0) return nil;
            id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&error];
            *damaged = ![entry length] || (plist && ![plist isKindOfClass:NSDictionary.class]) ||
                       (!plist && [error.domain isEqual:NSCocoaErrorDomain] && error.code == NSPropertyListReadCorruptError);
            return nil;
        }
        return [[UIColorValue alloc] initWithCGColor:archived.CGColor];
    }

    // Preserve future encodings and fields verbatim when removing a damaged neighbor.
    if (![entry isKindOfClass:NSDictionary.class]) {
        *damaged = ![entry isKindOfClass:NSArray.class];
        return nil;
    }
    NSArray *fields = @[@"r", @"g", @"b", @"a", @"colorSpace"];
    for (NSString *key in entry) if (![fields containsObject:key]) return nil;
    id profile = entry[@"colorSpace"];
    if (![profile isKindOfClass:NSDictionary.class]) {
        *damaged = YES;
        return nil;
    }
    for (NSString *key in profile) if (![key isEqual:@"rawValue"]) return nil;
    NSString *name = profile[@"rawValue"];
    if (![name isKindOfClass:NSString.class]) {
        *damaged = YES;
        return nil;
    }
    BOOL p3 = [name isEqual:(__bridge NSString *)kCGColorSpaceDisplayP3];
    if (!p3 && ![name isEqual:(__bridge NSString *)kCGColorSpaceSRGB]) return nil;

    CGFloat components[4];
    for (NSUInteger i = 0; i < 4; i++) {
        NSNumber *number = entry[fields[i]];
        if (![number isKindOfClass:NSNumber.class] ||
            CFGetTypeID((__bridge CFTypeRef)number) == CFBooleanGetTypeID() ||
            !isfinite(number.doubleValue) || (i == 3 && (number.doubleValue < 0 || number.doubleValue > 1))) {
            *damaged = YES;
            return nil;
        }
        components[i] = number.doubleValue;
    }
    BOOL extended = components[0] < 0 || components[0] > 1 || components[1] < 0 ||
                    components[1] > 1 || components[2] < 0 || components[2] > 1;
    CFStringRef spaceName = (__bridge CFStringRef)name;
    if (extended) spaceName = p3 ? CFSTR("kCGColorSpaceExtendedDisplayP3") : kCGColorSpaceExtendedSRGB;
    CGColorSpaceRef space = CGColorSpaceCreateWithName(spaceName);
    if (!space) return nil;
    CGColorRef color = CGColorCreate(space, components);
    CGColorSpaceRelease(space);
    if (!color) return nil;
    UIColorValue *value = [[UIColorValue alloc] initWithCGColor:color];
    CGColorRelease(color);
    return value;
}

// BINMAP-ADAPT: UIColorPickerDecodeSystemFavorites manifest=reimpl/favorites_sharing_api_manifest.json
NSDictionary *UIColorPickerDecodeSystemFavorites(id nativeValue, id *replacement) {
    *replacement = nil;
    BOOL legacy = [nativeValue isKindOfClass:NSArray.class];
    NSArray *entries = nativeValue;
    if (!legacy) {
        if ([nativeValue isKindOfClass:NSDictionary.class]) return nil;
        if ([nativeValue isKindOfClass:NSData.class]) {
            NSData *data = nativeValue;
            entries = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
            if (!entries && data.length) {
                // The native writer emits UTF-8 JSON. Keep opaque binary and alternate structured encodings intact.
                NSString *text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                  stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                NSMutableCharacterSet *binaryControls = [NSCharacterSet.controlCharacterSet mutableCopy];
                [binaryControls removeCharactersInString:@"\t\n\r"];
                if (!text || [text hasPrefix:@"bplist"] || [text hasPrefix:@"<"] || [text hasPrefix:@"{"] ||
                    [text rangeOfCharacterFromSet:binaryControls].location != NSNotFound) return nil;
            }
            if ([entries isKindOfClass:NSDictionary.class]) return nil;
        }
        if (![entries isKindOfClass:NSArray.class]) {
            NSDictionary *seed = UIColorPickerDefaultFavoritesRecord();
            *replacement = UIColorPickerEncodeSystemFavorites(seed);
            return seed;
        }
    }

    NSMutableDictionary *slots = [NSMutableDictionary dictionary];
    NSMutableIndexSet *damagedIndexes = [NSMutableIndexSet indexSet];
    BOOL supported = YES;
    NSUInteger index = 0;
    for (id entry in entries) {
        BOOL damaged = NO;
        UIColorValue *color = UIColorPickerDecodeSystemColor(entry, legacy, &damaged);
        NSDictionary *saved = [color propertyListRepresentationWithError:nil];
        if (damaged) [damagedIndexes addIndex:index];
        else if (saved) slots[@(slots.count).stringValue] = saved;
        else supported = NO;
        index++;
    }
    if (damagedIndexes.count) {
        NSMutableArray *intact = [entries mutableCopy];
        [intact removeObjectsAtIndexes:damagedIndexes];
        *replacement = legacy ? intact : [NSJSONSerialization dataWithJSONObject:intact options:0 error:nil];
    }
    if (!supported) return nil;
    NSDictionary *record = @{@"version": @1, @"slots": slots};
    // Editing a legacy archive migrates the whole list to the two-profile JSON format.
    if (legacy && !UIColorPickerEncodeSystemFavorites(record)) return nil;
    return record;
}

// BINMAP-ADAPT: UIColorPickerEncodeSystemFavorites manifest=reimpl/favorites_sharing_api_manifest.json
NSData *UIColorPickerEncodeSystemFavorites(NSDictionary *record) {
    if (![record isKindOfClass:NSDictionary.class]) return nil;
    NSNumber *version = record[@"version"];
    if (![version isEqual:@1] || CFGetTypeID((__bridge CFTypeRef)version) == CFBooleanGetTypeID()) return nil;
    NSDictionary *slots = record[@"slots"];
    if (![slots isKindOfClass:NSDictionary.class]) return nil;
    NSMutableArray<NSNumber *> *indices = [NSMutableArray arrayWithCapacity:slots.count];
    for (id key in slots) {
        if (![key isKindOfClass:NSString.class]) return nil;
        NSInteger index = [key integerValue];
        if (index < 0 || index == NSIntegerMax || ![@(index).stringValue isEqual:key]) return nil;
        [indices addObject:@(index)];
    }
    [indices sortUsingSelector:@selector(compare:)];

    NSMutableArray *entries = [NSMutableArray arrayWithCapacity:indices.count];
    for (NSNumber *index in indices) {
        NSDictionary *slot = slots[index.stringValue];
        UIColorValue *color = [[UIColorValue alloc] initWithPropertyList:slot error:nil];
        if (!color) return nil;
        // UIColorValue emits spaceName only after checking the restored space against
        // the system's named space. This also checks an embedded ICC with a name hint.
        NSDictionary *restored = [color propertyListRepresentationWithError:nil];
        NSString *name = restored[@"spaceName"];
        NSString *rawValue;
        if ([name isEqual:(__bridge NSString *)kCGColorSpaceSRGB] ||
            [name isEqual:(__bridge NSString *)kCGColorSpaceExtendedSRGB]) {
            rawValue = (__bridge NSString *)kCGColorSpaceSRGB;
        } else if ([name isEqual:(__bridge NSString *)kCGColorSpaceDisplayP3] ||
                   [name isEqual:@"kCGColorSpaceExtendedDisplayP3"]) {
            rawValue = (__bridge NSString *)kCGColorSpaceDisplayP3;
        } else {
            return nil;
        }
        NSArray *components = restored[@"components"];
        if (![components isEqualToArray:slot[@"components"]]) return nil;
        for (NSNumber *number in slot[@"components"]) {
            if (CFGetTypeID((__bridge CFTypeRef)number) == CFBooleanGetTypeID()) return nil;
        }
        [entries addObject:@{@"r": components[0], @"g": components[1], @"b": components[2],
                             @"a": components[3], @"colorSpace": @{@"rawValue": rawValue}}];
    }
    return [NSJSONSerialization dataWithJSONObject:entries options:0 error:nil];
}
#endif
