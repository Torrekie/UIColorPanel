#import "UIColorList.h"
#if TARGET_OS_IOS
#import "UIColorPanelAppearance.h"
#endif
#import "UIColorArchiveRecord.h"
#import <objc/runtime.h>

NSNotificationName const UIColorListDidChangeNotification=@"UIColorListDidChangeNotification";
NSExceptionName const UIColorListNotEditableException=@"UIColorListNotEditableException";
static NSMutableArray<UIColorList *> *UIAvailableColorLists;

// BINMAP: original=AppKit ida_name=sub_183974AA8 ea=0x183974aa8 end=0x183974ac4
static Boolean UIColorListKeyEqual(const void *a,const void *b){return [(__bridge NSString *)a isEqualToString:(__bridge NSString *)b];}
// BINMAP: original=AppKit ida_name=sub_183974A08 ea=0x183974a08 end=0x183974aa8
static CFHashCode UIColorListKeyHash(const void *key){NSString *string=(__bridge NSString *)key;NSUInteger length=MIN(string.length,(NSUInteger)32);unichar units[32];[string getCharacters:units range:NSMakeRange(0,length)];uint64_t result=0;for(NSUInteger i=0;i<length;i++)result=((uint64_t)units[i]<<(units[i]&7))+83*result;return (CFHashCode)result;}

@interface UIColorList () {
    NSMutableArray<NSString *> *_keyArray;
    NSMutableArray<UIColorValue *> *_colorArray;
    NSString *_fileName;
    CFMutableDictionaryRef _keyToIndexTable;
    BOOL _colorsLoaded,_notificationsDisabled,_dirty,_readOnlyBuiltin;
    NSTimeInterval _accessCheckTime;
    BOOL _cachedEditable;
}
- (BOOL)_loadColors;
- (NSUInteger)_indexOfKey:(NSString *)key;
- (void)_invalidateKeyToIndexTable;
- (void)_changed:(id)sender;
- (void)removeFilePreservingList:(UIColorList *)list;
@end
@implementation UIColorList
// BINMAP-ADAPT: UIColorList.availableColorLists manifest=reimpl/color_list_extras.json
+ (NSArray<UIColorList *> *)availableColorLists {
    @synchronized(self){
        if(!UIAvailableColorLists){
            UIAvailableColorLists=[NSMutableArray array];
            NSString *resource=
#if TARGET_OS_IOS
                [[UIColorPanelAppearance resourceBundle]pathForResource:@"UIBuiltInPalettes" ofType:@"json"]?:
#endif
                [[NSBundle bundleForClass:self]pathForResource:@"UIBuiltInPalettes" ofType:@"json"]?:[NSBundle.mainBundle pathForResource:@"UIBuiltInPalettes" ofType:@"json"];
            NSDictionary *builtins=resource?[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:resource] options:0 error:NULL]:nil;
            for(NSDictionary *palette in builtins[@"palettes"]){
                UIColorList *list=[[self alloc]initWithName:palette[@"name"]];list->_notificationsDisabled=YES;
                for(NSDictionary *entry in palette[@"colors"]){NSArray *components=entry[@"cgComponents"]?:entry[@"components"];if(components.count!=4)continue;CGFloat values[4];for(NSUInteger i=0;i<4;i++)values[i]=[components[i]doubleValue];CGColorSpaceRef space=CGColorSpaceCreateWithName(entry[@"cgSpaceName"]?(__bridge CFStringRef)entry[@"cgSpaceName"]:([palette[@"name"]isEqual:@"Web Safe Colors"]?kCGColorSpaceGenericRGB:kCGColorSpaceSRGB));CGColorRef cg=CGColorCreate(space,values);if(cg){[list setColorValue:[[UIColorValue alloc]initWithCGColor:cg] forKey:entry[@"name"]];CGColorRelease(cg);}CGColorSpaceRelease(space);}
                list->_notificationsDisabled=NO;list->_readOnlyBuiltin=YES;[UIAvailableColorLists addObject:list];
            }
            NSString *library=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
            NSString *directory=[library stringByAppendingPathComponent:@"Colors"];
            for(NSString *file in [[NSFileManager defaultManager]contentsOfDirectoryAtPath:directory error:NULL])if([file.pathExtension isEqual:@"clr"]||[file.pathExtension isEqual:@"color"]){UIColorList *list=[[self alloc]initWithName:file.stringByDeletingPathExtension fromFile:[directory stringByAppendingPathComponent:file]];if(list)[UIAvailableColorLists addObject:list];}
        }
        return UIAvailableColorLists;
    }
}
// BINMAP-ADAPT: UIColorList.colorListNamed: manifest=reimpl/color_list_extras.json
+ (UIColorList *)colorListNamed:(NSString *)name {for(UIColorList *list in self.availableColorLists)if([list.name isEqualToString:name])return list;return nil;}
// BINMAP: original=AppKit ida_name=-[NSColorList initWithName:] ea=0x183b1b910 end=0x183b1b918
- (instancetype)initWithName:(NSString *)name {return [self initWithName:name fromFile:nil];}
// BINMAP-ADAPT: UIColorList.initWithName:fromFile: manifest=reimpl/color_list_extras.json
- (instancetype)initWithName:(NSString *)name fromFile:(NSString *)path {
    if(path&&![[NSFileManager defaultManager]isReadableFileAtPath:path])return nil;
    if((self=[super init])){_name=[name copy];_fileName=[path copy];_keyArray=[NSMutableArray array];_colorArray=[NSMutableArray array];_colorsLoaded=path==nil;if(path&&![self _loadColors])return nil;}return self;
}
// BINMAP-ADAPT: UIColorList.dealloc manifest=reimpl/color_list_extras.json
- (void)dealloc {if(_keyToIndexTable)CFRelease(_keyToIndexTable);}
// BINMAP-ADAPT: UIColorList.localizedName manifest=reimpl/ui_corrections_extras.json
- (NSString *)localizedName {
#if TARGET_OS_IOS
    return _readOnlyBuiltin?[UIColorPanelAppearance localizedString:_name]:_name;
#else
    return _name;
#endif
}
// BINMAP-ADAPT: UIColorList.localizedColorNameWithKey: manifest=reimpl/ui_corrections_extras.json
- (NSString *)localizedColorNameWithKey:(NSString *)key {
#if TARGET_OS_IOS
    return _readOnlyBuiltin?[UIColorPanelAppearance localizedString:key]:key;
#else
    return key;
#endif
}
// BINMAP: original=AppKit ida_name=-[NSColorList allKeys] ea=0x183b1d22c end=0x183b1d254
- (NSArray<NSString *> *)allKeys {[self _loadColors];return _keyArray;}
// BINMAP-ADAPT: UIColorList.isEditable manifest=reimpl/color_list_extras.json
- (BOOL)isEditable {
    if(_readOnlyBuiltin)return NO;
    NSTimeInterval now=NSDate.timeIntervalSinceReferenceDate;
    if(_accessCheckTime<now-1){_cachedEditable=!_fileName||![[NSFileManager defaultManager]fileExistsAtPath:_fileName]||[[NSFileManager defaultManager]isWritableFileAtPath:_fileName];_accessCheckTime=now;}
    return _cachedEditable;
}
// BINMAP: original=AppKit ida_name=-[NSColorList setColor:forKey:] ea=0x183b1ce14 end=0x183b1ce88
- (void)setColorValue:(UIColorValue *)color forKey:(NSString *)key {[self _loadColors];NSUInteger index=[self _indexOfKey:key];[self insertColorValue:color key:key atIndex:index?index-1:_keyArray.count];}
// BINMAP: original=AppKit ida_name=-[NSColorList insertColor:key:atIndex:] ea=0x183b1ce88 end=0x183b1cfbc
- (void)insertColorValue:(UIColorValue *)color key:(NSString *)key atIndex:(NSUInteger)index {
    if(!self.isEditable)[NSException raise:UIColorListNotEditableException format:@"Attempt to change noneditable color list %@",self.name];
    [self _loadColors];NSUInteger existing=[self _indexOfKey:key];
    if(existing){NSUInteger old=existing-1;if(old==index){[_colorArray replaceObjectAtIndex:index withObject:color];_dirty=YES;[self _changed:key];return;}[self _invalidateKeyToIndexTable];[_keyArray removeObjectAtIndex:old];[_colorArray removeObjectAtIndex:old];if(old<index)index--;}
    else [self _invalidateKeyToIndexTable];
    [_keyArray insertObject:key atIndex:index];[_colorArray insertObject:color atIndex:index];_dirty=YES;[self _changed:key];
}
// BINMAP: original=AppKit ida_name=-[NSColorList removeColorWithKey:] ea=0x183b1cfbc end=0x183b1d0a4
- (void)removeColorWithKey:(NSString *)key {
    if(!self.isEditable)[NSException raise:UIColorListNotEditableException format:@"Attempt to change noneditable color list %@",self.name];
    [self _loadColors];NSUInteger index=[self _indexOfKey:key];if(index){[self _invalidateKeyToIndexTable];[_keyArray removeObjectAtIndex:index-1];[_colorArray removeObjectAtIndex:index-1];_dirty=YES;[self _changed:key];}
}
// BINMAP: original=AppKit ida_name=-[NSColorList colorWithKey:] ea=0x18396487c end=0x1839648dc
- (UIColorValue *)colorValueWithKey:(NSString *)key {[self _loadColors];NSUInteger index=[self _indexOfKey:key];return index?[_colorArray objectAtIndex:index-1]:nil;}
// BINMAP: original=AppKit ida_name=-[NSColorList _indexOfKey:] ea=0x18396549c end=0x183965600
- (NSUInteger)_indexOfKey:(NSString *)key {
    if(!_keyToIndexTable){CFDictionaryKeyCallBacks callbacks={0,NULL,NULL,NULL,UIColorListKeyEqual,UIColorListKeyHash};_keyToIndexTable=CFDictionaryCreateMutable(kCFAllocatorDefault,0,&callbacks,NULL);NSUInteger i=0;for(NSString *entry in _keyArray)CFDictionarySetValue(_keyToIndexTable,(__bridge const void *)entry,(const void *)(uintptr_t)++i);}
    return (NSUInteger)(uintptr_t)CFDictionaryGetValue(_keyToIndexTable,(__bridge const void *)key);
}
// BINMAP: original=AppKit ida_name=-[NSColorList _invalidateKeyToIndexTable] ea=0x183b1b8e0 end=0x183b1b910
- (void)_invalidateKeyToIndexTable {if(_keyToIndexTable)CFRelease(_keyToIndexTable);_keyToIndexTable=NULL;}
// BINMAP: original=AppKit ida_name=-[NSColorList _changed:] ea=0x183b1d3d0 end=0x183b1d430
- (void)_changed:(id)sender {if(!_notificationsDisabled)[NSNotificationCenter.defaultCenter postNotificationName:UIColorListDidChangeNotification object:self];}
// BINMAP-ADAPT: UIColorList._loadColors manifest=reimpl/color_list_extras.json
- (BOOL)_loadColors {
    @synchronized(self){if(_colorsLoaded)return YES;_colorsLoaded=YES;NSData *data=[NSData dataWithContentsOfFile:_fileName];NSDictionary *contents=data?[UIColorArchive colorListContentsFromData:data error:NULL]:nil;if(!contents)return NO;[_keyArray addObjectsFromArray:contents[@"keys"]];[_colorArray addObjectsFromArray:contents[@"values"]];[self _invalidateKeyToIndexTable];return YES;}
}
// BINMAP-ADAPT: UIColorList.writeToURL:error: manifest=reimpl/color_list_extras.json
- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error {
    BOOL registerList=url==nil;
    if(url&&!url.isFileURL){if(error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnsupportedSchemeError userInfo:@{NSURLErrorKey:url}];return NO;}
    if(!url){
        if(!_name.length||[_name containsString:@"/"]||[_name isEqual:@"."]||[_name isEqual:@".."]){if(error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInvalidFileNameError userInfo:nil];return NO;}
        NSString *library=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;NSURL *directory=[NSURL fileURLWithPath:[library stringByAppendingPathComponent:@"Colors"] isDirectory:YES];
        if(![[NSFileManager defaultManager]createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:error])return NO;
        url=[directory URLByAppendingPathComponent:[_name stringByAppendingPathExtension:@"clr"]];
    }
    [self _loadColors];NSData *data=[UIColorArchive archivedColorListWithKeys:_keyArray values:_colorArray error:error];if(!data||![data writeToURL:url options:NSDataWritingAtomic error:error])return NO;
    if(registerList){@synchronized(UIColorList.class){[UIColorList availableColorLists];for(NSInteger i=(NSInteger)UIAvailableColorLists.count-1;i>=0;i--){UIColorList *other=UIAvailableColorLists[(NSUInteger)i];if(other==self)break;if([other.name isEqual:self.name]){[UIAvailableColorLists removeObjectAtIndex:(NSUInteger)i];break;}}if(![UIAvailableColorLists containsObject:self])[UIAvailableColorLists addObject:self];}_fileName=url.path;}
    return YES;
}
// BINMAP-ADAPT: UIColorList.writeColorsWithKeys:values:error: manifest=reimpl/color_list_extras.json
- (BOOL)writeColorsWithKeys:(NSArray<NSString *> *)keys values:(NSArray<UIColorValue *> *)values error:(NSError **)error {
    if(!self.isEditable)[NSException raise:UIColorListNotEditableException format:@"Attempt to change noneditable color list %@",self.name];
    [self _loadColors];
    NSMutableArray<NSString *> *newKeys=[keys mutableCopy];NSMutableArray<UIColorValue *> *newColors=[values mutableCopy];
    NSMutableArray<NSString *> *oldKeys=_keyArray;NSMutableArray<UIColorValue *> *oldColors=_colorArray;BOOL oldDirty=_dirty;
    // The scoped archive has no host callbacks or run-loop work. Publish a
    // notification only after the existing atomic save has succeeded.
    _keyArray=newKeys;_colorArray=newColors;_dirty=YES;
    if(![self writeToURL:nil error:error]){_keyArray=oldKeys;_colorArray=oldColors;_dirty=oldDirty;return NO;}
    _keyArray=oldKeys;_colorArray=oldColors;[self _invalidateKeyToIndexTable];[_keyArray setArray:newKeys];[_colorArray setArray:newColors];[self _changed:nil];return YES;
}
// BINMAP-ADAPT: UIColorList.removeFile manifest=reimpl/color_list_extras.json
- (void)removeFile { [self removeFilePreservingList:nil]; }
// BINMAP-ADAPT: UIColorList.removeFilePreservingList: manifest=reimpl/color_list_extras.json
- (void)removeFilePreservingList:(UIColorList *)list {
    if(!_name.length||[_name containsString:@"/"])return;
    NSString *library=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;NSString *directory=[library stringByAppendingPathComponent:@"Colors"];
    NSURL *preservedURL=list&&list->_fileName?[NSURL fileURLWithPath:list->_fileName]:nil;id preservedIdentifier=nil;[preservedURL getResourceValue:&preservedIdentifier forKey:NSURLFileResourceIdentifierKey error:NULL];
    for(NSString *ext in @[@"clr",@"color"]){
        NSURL *url=[NSURL fileURLWithPath:[directory stringByAppendingPathComponent:[_name stringByAppendingPathExtension:ext]]];
        // A case-only rename can already have replaced this path during the atomic save.
        if(preservedURL){id identifier=nil;[url getResourceValue:&identifier forKey:NSURLFileResourceIdentifierKey error:NULL];if([url isEqual:preservedURL]||(preservedIdentifier&&[identifier isEqual:preservedIdentifier]))break;}
        if([[NSFileManager defaultManager]removeItemAtURL:url error:NULL])break;
    }
    @synchronized(UIColorList.class){[UIAvailableColorLists removeObject:self];}
}
#if TARGET_OS_IOS
// BINMAP-ADAPT: UIColorList.setColor:forKey: manifest=reimpl/color_list_extras.json
- (void)setColor:(UIColor *)color forKey:(NSString *)key {UIColorValue *value=[[UIColorValue alloc]initWithCGColor:color.CGColor];NSDictionary *metadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey);if(metadata)objc_setAssociatedObject(value,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);[self setColorValue:value forKey:key];}
// BINMAP-ADAPT: UIColorList.insertColor:key:atIndex: manifest=reimpl/color_list_extras.json
- (void)insertColor:(UIColor *)color key:(NSString *)key atIndex:(NSUInteger)index {UIColorValue *value=[[UIColorValue alloc]initWithCGColor:color.CGColor];NSDictionary *metadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey);if(metadata)objc_setAssociatedObject(value,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);[self insertColorValue:value key:key atIndex:index];}
// BINMAP-ADAPT: UIColorList.colorWithKey: manifest=reimpl/color_list_extras.json
- (UIColor *)colorWithKey:(NSString *)key {UIColorValue *value=[self colorValueWithKey:key];UIColor *color=value.UIColor;NSDictionary *metadata=value?objc_getAssociatedObject(value,&UIColorArchiveMetadataAssociationKey):nil;if(metadata&&color)objc_setAssociatedObject(color,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);return color;}
#endif
@end
