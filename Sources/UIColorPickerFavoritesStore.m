#import "UIColorPickerFavoritesStore+Internal.h"
#import "UIColorValue.h"
#if UICOLORPANEL_ENABLE_PRIVATE_API
#import "UIColorPickerSystemFavoritesCodec.h"
#import <TargetConditionals.h>
#import <copyfile.h>
#import <errno.h>
#import <fcntl.h>
#import <stdio.h>
#import <string.h>
#import <sys/file.h>
#import <sys/stat.h>
#import <unistd.h>
#endif

NSNotificationName const UIColorPickerFavoritesStoreDidChangeNotification = @"UIColorPickerFavoritesStoreDidChangeNotification";
NSErrorDomain const UIColorPickerFavoritesStoreErrorDomain = @"UIColorPickerFavoritesStoreErrorDomain";

// BINMAP-ADAPT: UIColorPickerDefaultFavoritesRecord manifest=reimpl/favorites_sharing_api_manifest.json
NSDictionary *UIColorPickerDefaultFavoritesRecord(void) {
    static const unsigned char srgb[5][3] = {{0,0,0},{0,97,253},{51,199,89},{255,204,1},{255,58,47}};
    static const unsigned char p3[5][3] = {{0,0,0},{40,95,244},{100,196,102},{247,206,70},{235,77,61}};
    BOOL wide = UIScreen.mainScreen.traitCollection.displayGamut == UIDisplayGamutP3;
    const unsigned char (*components)[3] = wide ? p3 : srgb;
    CGColorSpaceRef space = CGColorSpaceCreateWithName(wide ? kCGColorSpaceDisplayP3 : kCGColorSpaceSRGB);
    NSMutableDictionary *slots = [NSMutableDictionary dictionaryWithCapacity:5];
    for (NSUInteger i = 0; i < 5; i++) {
        CGFloat rgba[] = {components[i][0]/255.0, components[i][1]/255.0, components[i][2]/255.0, 1};
        CGColorRef color = CGColorCreate(space, rgba);
        slots[@(i).stringValue] = [[[UIColorValue alloc] initWithCGColor:color] propertyListRepresentationWithError:nil];
        CGColorRelease(color);
    }
    CGColorSpaceRelease(space);
    return @{@"version": @1, @"slots": slots};
}

#if UICOLORPANEL_ENABLE_PRIVATE_API
static NSString *const UIColorPickerDefaultsDomain = @"com.apple.UIKit.ColorPicker";
static const char UIColorPickerDefaultsFilename[] = "com.apple.UIKit.ColorPicker.plist";

// BINMAP-ADAPT: UIColorPickerReadPreferences manifest=reimpl/favorites_sharing_api_manifest.json
static NSDictionary *UIColorPickerReadPreferences(int directory, NSFileHandle **openedFile, struct stat *snapshot, BOOL *damaged) API_AVAILABLE(ios(14.0)) {
    int fd = openat(directory, UIColorPickerDefaultsFilename, O_RDWR | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK);
    if (fd < 0) return errno == ENOENT ? @{} : nil;
    NSFileHandle *file = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
    struct stat attributes;
    if (fstat(fd, &attributes) != 0 || !S_ISREG(attributes.st_mode)) return nil;
    NSError *error = nil;
    NSData *data = [file readDataToEndOfFileAndReturnError:&error];
    if (error || (!data && attributes.st_size != 0)) return nil;
    id plist = data.length ? [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&error] : nil;
    if (![plist isKindOfClass:NSDictionary.class]) {
        // The preferences domain must be a dictionary. Keep unknown plist versions and I/O failures intact.
        if (!damaged) return nil;
        if (data.length >= 8 && memcmp(data.bytes, "bplist", 6) == 0 && memcmp(data.bytes, "bplist00", 8) != 0) return nil;
        if (!plist && data.length && !([error.domain isEqual:NSCocoaErrorDomain] && error.code == NSPropertyListReadCorruptError)) return nil;
        *damaged = YES;
        plist = @{};
    }
    if (openedFile) *openedFile = file;
    if (snapshot) *snapshot = attributes;
    return plist;
}

// BINMAP-ADAPT: UIColorPickerReplacePreferences manifest=reimpl/favorites_sharing_api_manifest.json
static BOOL UIColorPickerReplacePreferences(int directory, NSFileHandle *original, struct stat expected, NSData *data) API_AVAILABLE(ios(14.0)) {
    // A privileged creator must leave a first-use plist owned by the extension's user.
    if (!original && fstat(directory, &expected) != 0) return NO;
    NSString *temporary = [@".ColorPicker-" stringByAppendingString:NSUUID.UUID.UUIDString];
    const char *tempName = temporary.fileSystemRepresentation;
    int fd = openat(directory, tempName, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    if (fd < 0) return NO;
    NSFileHandle *file = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
    BOOL success = [file writeData:data error:nil];
    if (success && original)
        success = fcopyfile(original.fileDescriptor, fd, NULL, COPYFILE_XATTR | COPYFILE_ACL) == 0;
#if !TARGET_OS_SIMULATOR
    if (success && original) {
        int protection = fcntl(original.fileDescriptor, F_GETPROTECTIONCLASS);
        success = protection >= 0 && (fcntl(fd, F_GETPROTECTIONCLASS) == protection ||
                                       fcntl(fd, F_SETPROTECTIONCLASS, protection) == 0);
    }
#endif
    struct stat replacement;
    if (success) success = fstat(fd, &replacement) == 0;
    if (success && (replacement.st_uid != expected.st_uid || replacement.st_gid != expected.st_gid))
        success = fchown(fd, expected.st_uid, expected.st_gid) == 0;
    if (success && original) success = fchmod(fd, expected.st_mode & 07777) == 0;
    if (![file closeAndReturnError:nil]) success = NO;
    if (success && original) {
        struct stat current;
        success = fstatat(directory, UIColorPickerDefaultsFilename, &current, AT_SYMLINK_NOFOLLOW) == 0 &&
                  current.st_dev == expected.st_dev && current.st_ino == expected.st_ino &&
                  current.st_size == expected.st_size && current.st_ctimespec.tv_sec == expected.st_ctimespec.tv_sec &&
                  current.st_ctimespec.tv_nsec == expected.st_ctimespec.tv_nsec;
    }
    if (success)
        success = renameatx_np(directory, tempName, directory, UIColorPickerDefaultsFilename,
                               original ? 0 : RENAME_EXCL) == 0;
    if (!success) unlinkat(directory, tempName, 0);
    return success;
}
#endif

@implementation UIColorPickerFavoritesStore {
    NSUserDefaults *_defaults;
    NSString *_key;
    NSString *_appGroupIdentifier;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    NSFileHandle *_systemPreferencesDirectory;
    id _lastSystemFavorites;
    BOOL _hasSystemSnapshot;
#endif
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.initWithKey: manifest=reimpl/favorites_sharing_api_manifest.json
- (instancetype)initWithKey:(NSString *)key {
    NSParameterAssert(key.length);
    if ((self = [super init])) {
        _key = [key copy];
        _defaults = NSUserDefaults.standardUserDefaults;
    }
    return self;
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.initWithAppGroupIdentifier:key:error: manifest=reimpl/favorites_sharing_api_manifest.json
- (instancetype)initWithAppGroupIdentifier:(NSString *)appGroupIdentifier key:(NSString *)key error:(NSError **)error {
    NSParameterAssert(appGroupIdentifier.length);
    NSParameterAssert(key.length);
    if ((self = [super init])) {
        NSURL *container = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier];
        if (!container) {
            if (error) *error = [NSError errorWithDomain:UIColorPickerFavoritesStoreErrorDomain code:UIColorPickerFavoritesStoreErrorAppGroupUnavailable userInfo:@{NSLocalizedDescriptionKey: @"The application cannot access the requested App Group."}];
            return nil;
        }
        _defaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupIdentifier];
        if (!_defaults) {
            if (error) *error = [NSError errorWithDomain:UIColorPickerFavoritesStoreErrorDomain code:UIColorPickerFavoritesStoreErrorDefaultsUnavailable userInfo:@{NSLocalizedDescriptionKey: @"The requested App Group defaults are unavailable."}];
            return nil;
        }
        _key = [key copy];
        _appGroupIdentifier = [appGroupIdentifier copy];
    }
    return self;
}

#if UICOLORPANEL_ENABLE_PRIVATE_API
// BINMAP-ADAPT: UIColorPickerFavoritesStore.systemPickerStoreIfAccessible manifest=reimpl/favorites_sharing_api_manifest.json
+ (instancetype)systemPickerStoreIfAccessible {
    if (@available(iOS 14.0, *)) {
#if TARGET_OS_SIMULATOR
        NSString *root = NSProcessInfo.processInfo.environment[@"SIMULATOR_SHARED_RESOURCES_DIRECTORY"];
        if (!root.length) return nil;
#else
        NSString *root = @"/private/var/mobile";
#endif
        NSString *registry = [root stringByAppendingPathComponent:@"Containers/Data/PluginKitPlugin"];
        NSFileManager *manager = NSFileManager.defaultManager;
        NSFileHandle *prefs = nil;
        int directoryFlags = O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW;
        for (NSString *name in [manager contentsOfDirectoryAtPath:registry error:nil]) {
            if (![[NSUUID alloc] initWithUUIDString:name]) continue;
            NSString *container = [registry stringByAppendingPathComponent:name];
            int candidate = open(container.fileSystemRepresentation, directoryFlags);
            if (candidate < 0) continue;
            int metadata = openat(candidate, ".com.apple.mobile_container_manager.metadata.plist", O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK);
            NSDictionary *registration = nil;
            if (metadata >= 0) {
                struct stat attributes;
                NSFileHandle *file = [[NSFileHandle alloc] initWithFileDescriptor:metadata closeOnDealloc:YES];
                NSData *data = fstat(metadata, &attributes) == 0 && S_ISREG(attributes.st_mode) ? [file readDataToEndOfFileAndReturnError:nil] : nil;
                if (data) registration = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:nil];
                [file closeAndReturnError:nil];
            }
            BOOL matches = [registration isKindOfClass:NSDictionary.class] && [registration[@"MCMMetadataIdentifier"] isEqual:UIColorPickerDefaultsDomain];
            int library = matches ? openat(candidate, "Library", directoryFlags) : -1;
            close(candidate);
            if (!matches) continue;
            if (library < 0) return nil;
            int directory = openat(library, "Preferences", directoryFlags);
            close(library);
            if (directory < 0) return nil;
            if (prefs || faccessat(directory, ".", W_OK | X_OK, 0) != 0) {
                close(directory);
                return nil;
            }
            // Keep the directory paired with the checked container across reads and writes.
            prefs = [[NSFileHandle alloc] initWithFileDescriptor:directory closeOnDealloc:YES];
        }
        if (!prefs) return nil;
        UIColorPickerFavoritesStore *store = [[self alloc] initWithKey:@"FavoriteColors"];
        store->_systemPreferencesDirectory = prefs;
        if ([store readRecord] == NSNull.null) return nil;
        return store;
    }
    return nil;
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.isSystemPickerStore manifest=reimpl/favorites_sharing_api_manifest.json
- (BOOL)isSystemPickerStore {
    return _systemPreferencesDirectory != nil;
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.tryWriteRecord: manifest=reimpl/favorites_sharing_api_manifest.json
- (BOOL)tryWriteRecord:(id)record {
    if (!_systemPreferencesDirectory) {
        [self writeRecord:record];
        return YES;
    }
    if (@available(iOS 14.0, *)) {
        NSData *encoded = UIColorPickerEncodeSystemFavorites(record);
        if (!encoded) return NO;
        @synchronized (self) {
            if (!_hasSystemSnapshot) return NO;
            int dir = openat(_systemPreferencesDirectory.fileDescriptor, ".", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
            if (dir < 0) return NO;
            BOOL saved = NO;
            // Serialize cooperating file writers. The system picker may have a separately cached copy.
            if (flock(dir, LOCK_EX | LOCK_NB) == 0) {
                NSFileHandle *original = nil;
                struct stat snapshot = {0};
                NSMutableDictionary *prefs = [UIColorPickerReadPreferences(dir, &original, &snapshot, NULL) mutableCopy];
                id current = prefs[_key];
                if (prefs && (current == _lastSystemFavorites || [current isEqual:_lastSystemFavorites])) {
                    prefs[_key] = encoded;
                    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:prefs format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
                    saved = plist && UIColorPickerReplacePreferences(dir, original, snapshot, plist);
                    if (saved) _lastSystemFavorites = encoded;
                }
            }
            close(dir);
            if (!saved) return NO;
        }
        [NSNotificationCenter.defaultCenter postNotificationName:UIColorPickerFavoritesStoreDidChangeNotification object:self];
        return YES;
    }
    return NO;
}
#endif

// BINMAP-ADAPT: UIColorPickerFavoritesStore.key manifest=reimpl/favorites_sharing_api_manifest.json
- (NSString *)key {
    return _key;
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.appGroupIdentifier manifest=reimpl/favorites_sharing_api_manifest.json
- (NSString *)appGroupIdentifier {
    return _appGroupIdentifier;
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.readRecord manifest=reimpl/favorites_sharing_api_manifest.json
- (id)readRecord {
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if (_systemPreferencesDirectory) {
        if (@available(iOS 14.0, *)) {
            id result;
            BOOL repaired = NO;
            @synchronized (self) {
                int directory = _systemPreferencesDirectory.fileDescriptor;
                NSFileHandle *original = nil;
                struct stat snapshot = {0};
                BOOL damagedFile = NO;
                NSDictionary *prefs = UIColorPickerReadPreferences(directory, &original, &snapshot, &damagedFile);
                id native = prefs[_key];
                id replacement = nil;
                NSDictionary *record = nil;
                if (damagedFile) {
                    record = UIColorPickerDefaultFavoritesRecord();
                    replacement = UIColorPickerEncodeSystemFavorites(record);
                } else if (native) {
                    record = UIColorPickerDecodeSystemFavorites(native, &replacement);
                }
                if (replacement) {
                    // Use a separate lock description, then compare the original inode and timestamps before renaming.
                    int lock = openat(directory, ".", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
                    if (lock >= 0) {
                        if (flock(lock, LOCK_EX | LOCK_NB) == 0) {
                            NSMutableDictionary *updated = [prefs mutableCopy];
                            updated[_key] = replacement;
                            NSData *bytes = [NSPropertyListSerialization dataWithPropertyList:updated format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
                            repaired = bytes && UIColorPickerReplacePreferences(lock, original, snapshot, bytes);
                        }
                        close(lock);
                    }
                    native = replacement;
                }
                _hasSystemSnapshot = prefs && (!native || record) && (!(damagedFile || replacement) || repaired);
                _lastSystemFavorites = _hasSystemSnapshot ? native : nil;
                result = _hasSystemSnapshot ? record : NSNull.null;
            }
            if (repaired) [NSNotificationCenter.defaultCenter postNotificationName:UIColorPickerFavoritesStoreDidChangeNotification object:self];
            return result;
        }
        return NSNull.null;
    }
#endif
    return [_defaults objectForKey:_key];
}

// BINMAP-ADAPT: UIColorPickerFavoritesStore.writeRecord: manifest=reimpl/favorites_sharing_api_manifest.json
- (void)writeRecord:(id)record {
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if (_systemPreferencesDirectory) {
        [self tryWriteRecord:record];
        return;
    }
#endif
    [_defaults setObject:record forKey:_key];
    [NSNotificationCenter.defaultCenter postNotificationName:UIColorPickerFavoritesStoreDidChangeNotification object:self];
}

@end
