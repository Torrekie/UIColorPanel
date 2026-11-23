#import "UIFavoriteColorsStore+Internal.h"
#import "UIColorValue+AppKitEquality.h"
NSNotificationName const UIFavoriteColorsDidChangeNotification=@"UIFavoriteColorsDidChangeNotification";
// BINMAP: original=AppKit ida_name=sub_184047044 ea=0x184047044 end=0x1840470f0
NSArray * UIColorPanelPresentedFavoriteColors(NSArray *colors,NSArray<NSNumber *> **storeIndexes) {
    NSMutableArray *indexes=[NSMutableArray array],*presented=[NSMutableArray array];
    // BINMAP-BLOCK: invoke_ea=0x18404811c parent_ea=0x184047044 reconstructed_as=block_literal
    [colors enumerateObjectsUsingBlock:^(id color,NSUInteger index,BOOL *stop){if(color!=NSNull.null){[presented addObject:color];[indexes addObject:@(index)];}}];*storeIndexes=indexes;return presented;
}
@interface UIFavoriteColorsStore () {BOOL _updatingFromBacking;}
- (void)deferredWriteColors;
- (void)writeColorsToBacking;
@end
@implementation UIFavoriteColorsStore
@synthesize colorEntries=_colorEntries;
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore init] ea=0x18410151c end=0x184101578
- (instancetype)init {if((self=[super init]))_colorEntries=@[];return self;}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore colorEntries] ea=0x184101938 end=0x184101978
- (NSArray *)colorEntries {@synchronized(self){return _colorEntries;}}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore colors] ea=0x18410198c end=0x1841019c0
- (NSArray *)colors {return self.colorEntries;}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore setColorEntries:] ea=0x18410187c end=0x184101924
- (void)setColorEntries:(NSArray *)entries {
    @synchronized(self){
        // An unsupported snapshot imports as empty, even for callers using updatingFromBacking:.
        if(self.backingReadOnly && entries.count) return;
        if(!_updatingFromBacking && self.backingAllowsEditing && !self.backingAllowsEditing()) return;
        // Native entry wrappers delegate equality to NSColor. The transport retains the same finite numeric equality without replacing canonical UIColorValue equality.
        BOOL equal=_colorEntries.count==entries.count;
        if(_updatingFromBacking){
            // The persisted transport can differ below the recovered float equality.
            equal=[_colorEntries isEqualToArray:entries];
        }else if(equal)for(NSUInteger i=0;i<entries.count;i++){id old=_colorEntries[i],new=entries[i];if(old!=new&&(![old isKindOfClass:UIColorValue.class]||![old isEqualForColorPanel:new])){equal=NO;break;}}
        if(!equal){_colorEntries=[entries copy];if(!_updatingFromBacking){if(self.class.defersBackingUpdates)[self deferredWriteColors];else[self writeColorsToBacking];}[NSNotificationCenter.defaultCenter postNotificationName:UIFavoriteColorsDidChangeNotification object:self];}
    }
}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore addColor:] ea=0x184101c0c end=0x184101c60
- (void)addColor:(id)color {@synchronized(self){[self insertColor:color atIndex:_colorEntries.count];}}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore insertColor:atIndex:] ea=0x184101b70 end=0x184101bf8
- (void)insertColor:(id)color atIndex:(NSInteger)index {@synchronized(self){if(self.backingReadOnly)return;NSMutableArray *values=[_colorEntries mutableCopy];[values insertObject:color atIndex:index];self.colorEntries=values;}}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore removeColorAtIndex:] ea=0x184101c74 end=0x184101ce0
- (void)removeColorAtIndex:(NSInteger)index {@synchronized(self){if(self.backingReadOnly)return;NSMutableArray *values=[_colorEntries mutableCopy];[values removeObjectAtIndex:index];self.colorEntries=values;}}
// BINMAP: original=AppKit ida_name=sub_184101CF4 ea=0x184101cf4 end=0x184101d7c
- (void)replaceColorAtIndex:(NSInteger)index withColor:(id)color {@synchronized(self){if(self.backingReadOnly)return;NSMutableArray *values=[_colorEntries mutableCopy];values[index]=color;self.colorEntries=values;}}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore copyColorAtIndex:toIndex:] ea=0x184101ad8 end=0x184101b58
- (void)copyColorAtIndex:(NSInteger)source toIndex:(NSInteger)destination {@synchronized(self){if(self.backingReadOnly)return;NSMutableArray *values=[_colorEntries mutableCopy];values[destination]=values[source];self.colorEntries=values;}}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore moveColorAtIndex:toIndex:replacement:] ea=0x1841019c8 end=0x184101ac0
- (void)moveColorAtIndex:(NSInteger)source toIndex:(NSInteger)destination replacement:(BOOL)replacement {@synchronized(self){if(self.backingReadOnly)return;NSMutableArray *values=[_colorEntries mutableCopy];if(replacement){values[destination]=values[source];values[source]=NSNull.null;}else{id value=values[source];[values removeObjectAtIndex:source];[values insertObject:value atIndex:destination];}self.colorEntries=values;}}
// BINMAP: original=AppKit ida_name=+[NSFavoriteColorsStore defersBackingUpdates] ea=0x184101e54 end=0x184101e5c
+ (BOOL)defersBackingUpdates {return YES;}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore deferredWriteColors] ea=0x184101d90 end=0x184101e54
- (void)deferredWriteColors {
    NSMutableArray *modes=[@[NSDefaultRunLoopMode,NSRunLoopCommonModes] mutableCopy];
#if TARGET_OS_IOS
    [modes addObject:UITrackingRunLoopMode];
#endif
    [self performSelector:@selector(writeColorsToBacking) withObject:nil afterDelay:.1 inModes:modes];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-FAVORITES-240BEBD2B0BB  -[UIFavoriteColorsStore writeColorsToBacking] — app-scoped immutable value transport replaces imported native backing subclass; native deferred scheduling remains intact.
- (void)writeColorsToBacking {if(self.backingWriter)self.backingWriter(self.colors);}
// BINMAP: original=AppKit ida_name=-[NSFavoriteColorsStore updatingFromBacking:] ea=0x184101e5c end=0x184101e98
- (void)updatingFromBacking:(void (^)(void))block {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(writeColorsToBacking) object:nil];
    _updatingFromBacking=YES;block();_updatingFromBacking=NO;
}
@end
