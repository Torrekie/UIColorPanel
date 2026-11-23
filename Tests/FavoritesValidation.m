#import "FavoritesValidation.h"
#import "../Sources/UIColorPickerSwatchesView.h"
#import "../Sources/UIColorPanelFavoriteSwatchLayout.h"
#import "../Sources/UIColorPanelFavoriteSwatchView.h"
#import "../Sources/UIFavoriteColorsStore.h"
#import <QuartzCore/QuartzCore.h>
#import "../Sources/UIColorPanelAppearance.h"
#import "../Sources/UIColorPanelSavedColorsController.h"
#import "../Sources/UIColorPanelViewController.h"
#import "../Sources/UIColorPickerFavoritesStore.h"
#import "../Sources/RecoveredElements/UIColorPickerSpectrum.h"
#import <dispatch/dispatch.h>
#if UICOLORPANEL_ENABLE_PRIVATE_API
#import "../Sources/UIColorPickerFavoritesStore+Internal.h"
#import <fcntl.h>
#endif

@interface UIColorPickerSpectrum (FavoritesFeatureValidation)
- (void)updateSelectionAtLocation:(CGPoint)point;
@end
@interface UIFavoritesFeatureRecorder : NSObject <UIColorPanelViewControllerDelegate>
@property(nonatomic) NSUInteger changes;
@end
@implementation UIFavoritesFeatureRecorder
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {self.changes++;}
@end

@interface UIColorPickerSwatchesView (FavoritesAsyncValidation)
- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session;
- (BOOL)accessibilitySaveCurrentColor:(UIAccessibilityCustomAction *)action;
- (BOOL)persistSlots;
- (void)showNativeDeleteCallout:(UILongPressGestureRecognizer *)gesture;
@end
@interface UIColorPanelSavedColorsController (FavoritesAsyncValidation)
- (void)close:(id)sender;
- (void)save:(id)sender;
@end

// Only the two drop-session messages used by the production adapter are mocked.
@interface UIFavoritesDeferredDropSession : NSObject
@property(nonatomic,copy) NSArray<UIDragItem *> *items;
@property(nonatomic) CGPoint location;
- (CGPoint)locationInView:(UIView *)view;
@end
@implementation UIFavoritesDeferredDropSession
- (CGPoint)locationInView:(UIView *)view {return self.location;}
@end
@interface UIFavoritesDeferredItemProvider : NSItemProvider
@property(nonatomic,copy) void (^dataCompletion)(NSData *,NSError *);
@end
@implementation UIFavoritesDeferredItemProvider
- (BOOL)hasItemConformingToTypeIdentifier:(NSString *)identifier {return [identifier isEqualToString:@"org.uicolorpanelkit.color-value"];}
- (NSProgress *)loadDataRepresentationForTypeIdentifier:(NSString *)identifier completionHandler:(void (^)(NSData *,NSError *))completionHandler {self.dataCompletion=completionHandler;return [NSProgress progressWithTotalUnitCount:1];}
@end

// Only recognition state and location are supplied by the harness. The real
// footer handler, attached cell, responder chain and UIKit menu remain intact.
@interface UIFavoritesNativeLongPress : UILongPressGestureRecognizer
@property(nonatomic) CGPoint testLocation;
@end
@implementation UIFavoritesNativeLongPress
- (UIGestureRecognizerState)state {return UIGestureRecognizerStateBegan;}
- (CGPoint)locationInView:(UIView *)view {return self.testLocation;}
@end

static BOOL UIFavoritesDrainMainQueue(void) {
    // A fixed25ms pump can expire while UIKit services its first layout event,
    // before any queued drop completion is consumed. FIFO sentinel completion
    // establishes that the preceding callbacks actually ran, including cancels.
    __block BOOL drained=NO;dispatch_async(dispatch_get_main_queue(),^{drained=YES;});NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:1];
    while(!drained&&deadline.timeIntervalSinceNow>0)[NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:MIN(.005,deadline.timeIntervalSinceNow)]];
    return drained;
}

@implementation UIColorFavoritesValidation
#if UICOLORPANEL_ENABLE_PRIVATE_API
+ (NSDictionary<NSString *,NSNumber *> *)systemFileRepairCases {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSURL *directory = [manager.temporaryDirectory URLByAppendingPathComponent:NSUUID.UUID.UUIDString];
    if (![manager createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:nil])
        return @{@"systemFavoritesFixtureDirectory": @NO};
    NSMutableDictionary *cases = [NSMutableDictionary dictionary];
    @try {
        int fd = open(directory.fileSystemRepresentation, O_RDONLY | O_DIRECTORY);
        if (fd < 0) return @{@"systemFavoritesFixtureDescriptor": @NO};
        NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
        UIColorPickerFavoritesStore *store = [[UIColorPickerFavoritesStore alloc] initWithKey:@"FavoriteColors"];
        // Isolate the file adapter from registry discovery and the device's actual picker.
        [store setValue:handle forKey:@"systemPreferencesDirectory"];
        NSURL *file = [directory URLByAppendingPathComponent:@"com.apple.UIKit.ColorPicker.plist"];
        NSDictionary *seed = UIColorPickerDefaultFavoritesRecord();
        [NSData.data writeToURL:file atomically:YES];
        id restored = [store readRecord];
        cases[@"systemDamagedFileRebuilt"] = @([restored isEqual:seed] && [[store readRecord] isEqual:seed]);

        BOOL (^writeValue)(id) = ^BOOL(id native) {
            return [@{@"FavoriteColors":native, @"sibling":@42} writeToURL:file atomically:YES];
        };
        NSData *(^json)(id) = ^NSData *(id value) {
            return [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        };
        NSDictionary *(^readPrefs)(void) = ^{ return [NSDictionary dictionaryWithContentsOfURL:file]; };
        NSDictionary *red = @{@"r":@1,@"g":@0,@"b":@0,@"a":@1,@"colorSpace":@{@"rawValue":(__bridge NSString *)kCGColorSpaceSRGB}};
        NSMutableDictionary *blue = [red mutableCopy]; blue[@"r"] = @0; blue[@"b"] = @1;
        NSMutableDictionary *bad = [red mutableCopy]; [bad removeObjectForKey:@"g"];
        BOOL written = writeValue(json(@[red,bad,@"broken",@42,blue]));
        id repaired = [store readRecord];
        NSDictionary *prefs = readPrefs();
        NSArray *actual = [NSJSONSerialization JSONObjectWithData:prefs[@"FavoriteColors"] options:0 error:nil];
        cases[@"systemDamagedColorRemovedInOrder"] = @(written && [repaired isKindOfClass:NSDictionary.class] &&
                [repaired[@"slots"] count] == 2 && [actual isEqual:@[red,blue]] && [prefs[@"sibling"] isEqual:@42]);

        NSMutableDictionary *future = [blue mutableCopy]; future[@"future"] = @"preserved";
        written = writeValue(json(@[red,bad,future]));
        id unsupported = [store readRecord];
        actual = [NSJSONSerialization JSONObjectWithData:readPrefs()[@"FavoriteColors"] options:0 error:nil];
        cases[@"systemRepairKeepsUnsupportedNeighbor"] = @(written && unsupported == NSNull.null && [actual isEqual:@[red,future]]);

        written = writeValue([@"[{" dataUsingEncoding:NSUTF8StringEncoding]);
        restored = [store readRecord];
        cases[@"systemDamagedPayloadRebuiltWithSibling"] = @(written && [restored isEqual:seed] && [readPrefs()[@"sibling"] isEqual:@42]);
        for (id invalid in @[@42, [@"broken JSON" dataUsingEncoding:NSUTF8StringEncoding]]) {
            written = writeValue(invalid);
            restored = [store readRecord];
            NSString *name = [invalid isKindOfClass:NSNumber.class] ? @"systemScalarPayloadRebuilt" : @"systemDamagedTextRebuilt";
            cases[name] = @(written && [restored isEqual:seed] && [readPrefs()[@"sibling"] isEqual:@42]);
        }
        UIColor *sourceColor = [[UIColorValue alloc] initWithPropertyList:seed[@"slots"][@"1"] error:nil].UIColor;
        NSData *legacy = [NSKeyedArchiver archivedDataWithRootObject:sourceColor requiringSecureCoding:YES error:nil];
        written = writeValue(@[legacy,@"broken",[@"broken" dataUsingEncoding:NSUTF8StringEncoding],legacy]);
        repaired = [store readRecord];
        cases[@"systemLegacyWrongTypeRemoved"] = @(written && [repaired isKindOfClass:NSDictionary.class] &&
                [repaired[@"slots"] count] == 2 && [readPrefs()[@"FavoriteColors"] isEqual:@[legacy,legacy]]);

        NSData *newFormat = [@"bplist23future" dataUsingEncoding:NSUTF8StringEncoding];
        written = [newFormat writeToURL:file atomically:YES];
        cases[@"systemUnknownPlistVersionPreserved"] = @(written && [store readRecord] == NSNull.null &&
                [[NSData dataWithContentsOfURL:file] isEqual:newFormat]);
    } @finally {
        [manager removeItemAtURL:directory error:nil];
    }
    return cases;
}
#endif
+ (BOOL)runNativeFooterWithOutputURL:(NSURL *)url {
    BOOL keepFixture=[NSUserDefaults.standardUserDefaults boolForKey:@"UIKeepNativeFooterFixture"];
    NSMutableArray *cases=[NSMutableArray new];__block NSUInteger failures=0;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL pass,NSDictionary *details){NSMutableDictionary *entry=[@{@"name":name,@"pass":@(pass)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];if(!pass)failures++;};
#if UICOLORPANEL_ENABLE_PRIVATE_API
    NSDictionary *fileCases = [self systemFileRepairCases];
    for (NSString *name in fileCases) record(name, [fileCases[name] boolValue], nil);
#endif
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIView *host=[[UIView alloc]initWithFrame:window.bounds];[window addSubview:host];
    UIColorPickerSwatchesView *view=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectMake(20,200,280,88)];[host addSubview:view];
    UIView *well=[[UIView alloc]initWithFrame:CGRectMake(20,320,44,44)];[host addSubview:well];view.currentColorSourceView=well;
    UIColorValue *duplicate=[[UIColorValue alloc]initWithCGColor:[UIColor colorWithRed:.2 green:.6 blue:.8 alpha:.48].CGColor];UIColorValue *other=[[UIColorValue alloc]initWithCGColor:UIColor.redColor.CGColor];
    [view setColor:duplicate forSlot:0];[view setColor:other forSlot:1];[view setColor:duplicate forSlot:2];view.currentColor=duplicate;
    NSArray *managerInteractions=[view.collectionView.interactions copy];UIDragInteraction *managerDrag=nil;UIDropInteraction *managerDrop=nil;
    for(id interaction in managerInteractions){if([interaction isKindOfClass:UIDragInteraction.class])managerDrag=interaction;if([interaction isKindOfClass:UIDropInteraction.class])managerDrop=interaction;}
    id managerMenu=[view valueForKey:@"managerMenuInteraction"];NSMutableArray *observedInteractions=[NSMutableArray new];
    NSDictionary *(^interactionDetails)(NSArray *)=^NSDictionary *(NSArray *interactions){NSMutableArray *entries=[NSMutableArray new];NSUInteger drag=0,drop=0,context=0,dragIdentity=0,dropIdentity=0,menuIdentity=0;
        for(id interaction in interactions){NSUInteger identity=[observedInteractions indexOfObjectIdenticalTo:interaction];if(identity==NSNotFound){identity=observedInteractions.count;[observedInteractions addObject:interaction];}BOOL owned=NO;
            if([interaction isKindOfClass:UIDragInteraction.class]){owned=(id)[(UIDragInteraction *)interaction delegate]==view;if(owned)drag++;}
            else if([interaction isKindOfClass:UIDropInteraction.class]){owned=(id)[(UIDropInteraction *)interaction delegate]==view;if(owned)drop++;}
            else if(@available(iOS 13.0,*)){if([interaction isKindOfClass:UIContextMenuInteraction.class]){owned=(id)[(UIContextMenuInteraction *)interaction delegate]==view;if(owned)context++;}}
            dragIdentity+=interaction==managerDrag;dropIdentity+=interaction==managerDrop;menuIdentity+=interaction==managerMenu;
            [entries addObject:@{@"class":NSStringFromClass([interaction class]),@"identity":@(identity),@"owned":@(owned)}];}
        return @{@"interactions":entries,@"ownedDragCount":@(drag),@"ownedDropCount":@(drop),@"ownedContextMenuCount":@(context),@"originalDragIdentityCount":@(dragIdentity),@"originalDropIdentityCount":@(dropIdentity),@"originalMenuIdentityCount":@(menuIdentity)};};
    NSDictionary *initialInteractionDetails=interactionDetails(managerInteractions);
    // UIKit15.5 recreates its private click-presentation companion when the
    // public context menu is reattached. Only component-owned instances and
    // counts are stable contracts; retain complete snapshots as diagnostics.
    BOOL (^ownedInteractionsRestored)(NSDictionary *)=^BOOL(NSDictionary *details){NSUInteger menus=managerMenu?1:0;return [details[@"ownedDragCount"]unsignedIntegerValue]==1&&[details[@"ownedDropCount"]unsignedIntegerValue]==1&&[details[@"ownedContextMenuCount"]unsignedIntegerValue]==menus&&[details[@"originalDragIdentityCount"]unsignedIntegerValue]==1&&[details[@"originalDropIdentityCount"]unsignedIntegerValue]==1&&[details[@"originalMenuIdentityCount"]unsignedIntegerValue]==menus;};
    BOOL (^hasTransport)(UIView *)=^BOOL(UIView *source){for(id interaction in source.interactions)if([interaction isKindOfClass:UIDragInteraction.class]||[interaction isKindOfClass:UIDropInteraction.class])return YES;return NO;};
    UIMenuController *menu=UIMenuController.sharedMenuController;
    NSString *featureKey=[@"UIColorPanelKit.NativeFeatures." stringByAppendingString:NSUUID.UUID.UUIDString];
    NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    BOOL (^waitForMenu)(BOOL)=^BOOL(BOOL visible){NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:.75];while(menu.menuVisible!=visible&&deadline.timeIntervalSinceNow>0)[NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:MIN(.01,deadline.timeIntervalSinceNow)]];return menu.menuVisible==visible;};
    @try {
        BOOL symbols=YES;NSArray *keys=@[@"wheel",@"sliders",@"palette",@"image",UICOLORPANEL_ENABLE_PENCILS ? @"pencils" : @"grid"];
        for(NSString *key in keys){UIImage *image=[UIColorPanelAppearance imageForSymbol:key size:25];symbols=symbols&&image&&image.renderingMode==UIImageRenderingModeAlwaysTemplate;if(@available(iOS 13.0,*)){BOOL expected=![key isEqual:@"wheel"];if(@available(iOS 14.0,*))expected=YES;symbols=symbols&&(image.isSymbolImage==expected);}else symbols=symbols&&CGSizeEqualToSize(image.size,CGSizeMake(25,25));}
        record(@"modeImagesUseAvailableSystemSymbolsOrOldSystemArtwork",symbols,nil);
        UIColorPickerSwatchesView *fresh=[UIColorPickerSwatchesView new];fresh.persistenceKey=featureKey;fresh.usesNativePickerPresentation=YES;
        BOOL wide=UIScreen.mainScreen.traitCollection.displayGamut==UIDisplayGamutP3;
        const unsigned char srgb[5][3]={{0,0,0},{0,97,253},{51,199,89},{255,204,1},{255,58,47}},p3[5][3]={{0,0,0},{40,95,244},{100,196,102},{247,206,70},{235,77,61}};
        const unsigned char (*seed)[3]=wide?p3:srgb;CGColorSpaceRef seedSpace=CGColorSpaceCreateWithName(wide?kCGColorSpaceDisplayP3:kCGColorSpaceSRGB);BOOL seeds=fresh.presentedColors.count==5;
        for(NSUInteger index=0;index<fresh.presentedColors.count;index++){CGColorRef cg=fresh.presentedColors[index].CGColor;const CGFloat *rgba=CGColorGetComponents(cg);seeds=seeds&&index<5&&CFEqual(CGColorGetColorSpace(cg),seedSpace)&&CGColorGetAlpha(cg)==1;for(NSUInteger channel=0;channel<3&&index<5;channel++)seeds=seeds&&rgba[channel]==seed[index][channel]/255.0;}
        CGColorSpaceRelease(seedSpace);record(@"absentNativeLibraryGetsExactFiveDeviceGamutSeeds",seeds&&[defaults dictionaryForKey:featureKey][@"slots"]!=nil,nil);
        NSDictionary *nativeSeed=[defaults dictionaryForKey:featureKey];
        NSDictionary *empty=@{@"version":@1,@"slots":@{}};[defaults setObject:empty forKey:featureKey];fresh.persistenceKey=featureKey;fresh.usesNativePickerPresentation=NO;fresh.usesNativePickerPresentation=YES;
        record(@"explicitEmptyLibraryStaysEmptyAcrossPresentationChanges",fresh.presentedColors.count==0&&[[defaults objectForKey:featureKey]isEqual:empty],nil);
        NSDictionary *unknown=@{@"version":@99,@"fixture":@"unsupported"};
        [defaults setObject:unknown forKey:featureKey];
        fresh.persistenceKey=featureKey;
        fresh.currentColor=other;
        UIView *source=[UIView new];
        fresh.currentColorSourceView=source;
        NSString *saveTitle=[UIColorPanelAppearance localizedString:@"Save Current Color"];
        BOOL (^offersSave)(void)=^BOOL{
            for(UIAccessibilityCustomAction *action in source.accessibilityCustomActions)
                if([action.name isEqual:saveTitle])return YES;
            return NO;
        };
        UIColorPanelSavedColorsController *readOnlyManager=[[UIColorPanelSavedColorsController alloc]initWithSwatchesView:fresh];
        [readOnlyManager loadViewIfNeeded];
        __block NSUInteger modelChanges=0;
        id observer=[NSNotificationCenter.defaultCenter addObserverForName:UIFavoriteColorsDidChangeNotification object:fresh.favoriteStore queue:nil usingBlock:^(NSNotification *note){modelChanges++;}];
        BOOL readOnly=!fresh.favoritesEditable&&!readOnlyManager.navigationItem.leftBarButtonItem.enabled&&!offersSave();
        [readOnlyManager save:nil];
        [fresh setColor:other forSlot:0];
        [fresh.favoriteStore addColor:other];
        [fresh.favoriteStore updatingFromBacking:^{fresh.favoriteStore.colorEntries=@[other];}];
        BOOL rejected=![fresh saveCurrentColor]&&![fresh accessibilitySaveCurrentColor:nil];
        [NSNotificationCenter.defaultCenter removeObserver:observer];
        record(@"unsupportedRecordRejectsManagerModelIndexedAndAccessibilityEdits",readOnly&&rejected&&modelChanges==0&&
               fresh.currentColor==other&&!fresh.slots.count&&!fresh.collectionView.indexPathsForSelectedItems.count&&
               [[defaults objectForKey:featureKey]isEqual:unknown],nil);
        fresh.usesNativePickerPresentation=YES;
        BOOL noAdd=[fresh.collectionView numberOfItemsInSection:0]==0;
        [defaults setObject:empty forKey:featureKey];
        [fresh refreshFavorites];
        BOOL addRestored=[fresh.collectionView numberOfItemsInSection:0]==1&&offersSave();
        [fresh.collectionView.delegate collectionView:fresh.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        record(@"validEmptyAfterFutureRecordRestoresNativeAdd",noAdd&&addRestored&&fresh.favoritesEditable&&
               [[[defaults dictionaryForKey:featureKey] objectForKey:@"slots"] count]==1&&[fresh.presentedColors.firstObject isEqual:other],nil);
        [defaults setObject:@"corrupt library" forKey:featureKey];
        UIColorPanelConfiguration *damagedConfiguration=[UIColorPanelConfiguration new];
        damagedConfiguration.savedColorsKey=featureKey;
        UIColorPanelViewController *damagedPanel=[[UIColorPanelViewController alloc]initWithColor:other configuration:damagedConfiguration];
        [damagedPanel loadViewIfNeeded];
        UIColorPickerSwatchesView *damagedView=[damagedPanel valueForKey:@"swatchesView"];
        record(@"nativePanelRebuildsCorruptLibraryOnFirstLoad",damagedView.favoritesEditable&&
               damagedView.presentedColors.count==5&&[[defaults objectForKey:featureKey]isEqual:nativeSeed],nil);
        fresh.usesNativePickerPresentation=NO;
        [defaults setObject:@{@"version":@1,@"slots":@[]} forKey:featureKey];
        [fresh refreshFavorites];
        record(@"nativeLibraryRebuildsFiveSeedsWhileManagerIsOpen",fresh.presentedColors.count==5&&
               [[defaults objectForKey:featureKey]isEqual:nativeSeed],nil);
        fresh.usesNativePickerPresentation=YES;
        NSDictionary *otherSlot=[other propertyListRepresentationWithError:nil];
        NSDictionary *brokenColor=@{@"version":@1,@"components":@"damaged"};
        NSDictionary *goodSlots=@{@"0":otherSlot,@"7":unknown,@"9":otherSlot};
        NSMutableDictionary *oneBad=[goodSlots mutableCopy];
        oneBad[@"4"]=brokenColor;
        NSDictionary *damagedSparse=@{@"version":@1,@"slots":oneBad,@"otherField":@"intact"};
        NSDictionary *cleanSparse=@{@"version":@1,@"slots":goodSlots,@"otherField":@"intact"};
        [defaults setObject:damagedSparse forKey:featureKey];
        [fresh refreshFavorites];
        record(@"corruptSparseSlotRemovedWithoutChangingOtherPayloadsOrIndices",
               [[defaults objectForKey:featureKey]isEqual:cleanSparse]&&fresh.presentedColors.count==2&&
               ![fresh colorAtIndex:4]&&[[fresh colorAtIndex:9]isEqual:other],nil);
        [defaults setObject:@[otherSlot,brokenColor,unknown,otherSlot] forKey:featureKey];
        [fresh refreshFavorites];
        NSDictionary *migrated=@{@"version":@1,@"slots":@{@"0":otherSlot,@"2":unknown,@"3":otherSlot}};
        record(@"corruptLegacySlotMigratesSurvivorsAtSameIndices",[[defaults objectForKey:featureKey]isEqual:migrated]&&
               fresh.presentedColors.count==2&&[[fresh colorAtIndex:3]isEqual:other],nil);
        NSArray *oldSlots=@[[other propertyListRepresentationWithError:nil],unknown];
        [defaults setObject:oldSlots forKey:featureKey];
        [fresh refreshFavorites];
        BOOL appended=[fresh saveCurrentColor];
        NSDictionary *converted=[defaults dictionaryForKey:featureKey][@"slots"];
        record(@"legacyArrayWithFutureSlotCanAppendWithoutLosingOriginalIndices",appended&&
               [converted[@"0"]isEqual:oldSlots[0]]&&[converted[@"1"]isEqual:unknown]&&[converted[@"2"]isEqual:oldSlots[0]],nil);
        NSString *group=[defaults stringForKey:@"UIFavoritesValidationAppGroup"];
        if(group.length){
            NSError *error=nil;
            UIColorPickerFavoritesStore *store=[[UIColorPickerFavoritesStore alloc]initWithAppGroupIdentifier:group key:featureKey error:&error];
            if(store){
                @try {
                    [store writeRecord:unknown];
                    UIColorPickerSwatchesView *groupView=[UIColorPickerSwatchesView new];
                    groupView.favoritesStore=store;
                    groupView.currentColor=other;
                    BOOL preserved=![groupView saveCurrentColor]&&[[store readRecord]isEqual:unknown];
                    [store writeRecord:empty];
                    BOOL saved=[groupView saveCurrentColor];
                    record(@"appGroupSuiteProtectsFutureRecordAndAllowsExplicitReplacement",preserved&&saved&&[store readRecord][@"slots"][@"0"]!=nil,nil);
                    [store writeRecord:damagedSparse];
                    record(@"appGroupRepairsOnlyDamagedSlot",[[store readRecord]isEqual:cleanSparse]&&
                           groupView.presentedColors.count==2,nil);
                    NSDictionary *localBefore=[defaults dictionaryForKey:featureKey];
                    [store writeRecord:@"corrupt group library"];
                    record(@"legacyManagerRebuildsOnlyGroupRecord",[[store readRecord]isEqual:empty]&&
                           groupView.favoritesEditable&&!groupView.slots.count&&[[defaults dictionaryForKey:featureKey]isEqual:localBefore],nil);
                    groupView.favoritesStore=nil;
                } @finally {[[[NSUserDefaults alloc]initWithSuiteName:group]removeObjectForKey:featureKey];}
            }else record(@"appGroupSuiteAvailableToConfiguredHost",NO,@{@"error":error.localizedDescription?:@""});
        }
        UIColorPickerSwatchesView *memory=[UIColorPickerSwatchesView new];[memory.favoriteStore addColor:other];[memory.favoriteStore removeColorAtIndex:0];memory.usesNativePickerPresentation=YES;
        record(@"explicitlyClearedMemoryLibraryIsNeverReseeded",memory.slots.count==0&&memory.presentedColors.count==0,nil);
        [defaults setObject:empty forKey:featureKey];fresh.persistenceKey=featureKey;
        UIColorValue *transparent=[duplicate copyWithAlpha:0],*opaque=[duplicate copyWithAlpha:1];[fresh setColor:transparent forSlot:0];[fresh setColor:other forSlot:1];[fresh setColor:duplicate forSlot:2];[fresh setColor:opaque forSlot:3];fresh.currentColor=opaque;fresh.supportsAlpha=NO;
        BOOL filtered=fresh.presentedColors.count==2&&[fresh storeIndexForColorIndex:0]==1&&[fresh storeIndexForColorIndex:1]==3&&[fresh colorAtIndex:0]==transparent&&[fresh colorAtIndex:2]==duplicate;
        [fresh setColor:nil forSlot:[fresh storeIndexForColorIndex:0]];BOOL added=[fresh saveCurrentColor];fresh.supportsAlpha=YES;
        UIColorPickerSwatchesView *reopened=[UIColorPickerSwatchesView new];reopened.persistenceKey=featureKey;reopened.usesNativePickerPresentation=YES;
        record(@"opaqueOnlyEditsPreserveHiddenTransparentRecordsAndBackingIndices",filtered&&added&&fresh.presentedColors.count==4&&reopened.presentedColors.count==4&&[[reopened colorAtIndex:0]isEqual:transparent]&&[[reopened colorAtIndex:2]isEqual:duplicate]&&![reopened colorAtIndex:1]&&CGColorGetAlpha([reopened colorAtIndex:4].CGColor)==1,nil);
        UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeCustomPalette;configuration.supportsAlpha=NO;configuration.savedColorsKey=featureKey;
        UIColorPanelViewController *panel=[[UIColorPanelViewController alloc]initWithColor:duplicate configuration:configuration];UIFavoritesFeatureRecorder *recorder=[UIFavoritesFeatureRecorder new];panel.delegate=recorder;
        panel.supportsAlpha=YES;panel.supportsAlpha=NO;BOOL unloaded=!panel.isViewLoaded&&panel.selectedColor==duplicate&&panel.showsAlpha;
        [panel loadViewIfNeeded];UIView *opacity=[panel valueForKey:@"opacityRow"];UIColorPickerSwatchesView *panelFavorites=[panel valueForKey:@"swatchesView"];BOOL opacityHidden=opacity.hidden&&!panelFavorites.supportsAlpha;
        panel.supportsAlpha=YES;BOOL restored=!opacity.hidden&&panelFavorites.supportsAlpha;panel.showsAlpha=NO;panel.supportsAlpha=NO;panel.supportsAlpha=YES;
        record(@"alphaCapabilityKeepsVisibilityPreferenceAndCanonicalColorIndependent",unloaded&&opacityHidden&&restored&&opacity.hidden&&!panel.showsAlpha&&panel.selectedColor==duplicate&&recorder.changes==0,nil);
        CGColorSpaceRef p3Space=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);CGFloat input[]={.2,.6,.8,.35};CGColorRef inputCG=CGColorCreate(p3Space,input);UIColorValue *inputColor=[[UIColorValue alloc]initWithCGColor:inputCG];CGColorRelease(inputCG);panel.selectedColor=inputColor;
        panel.view.frame=CGRectMake(0,0,375,700);[panel.view setNeedsLayout];[panel.view layoutIfNeeded];UIColorPickerSpectrum *spectrum=[panel valueForKey:@"spectrum"];[spectrum setValue:@YES forKey:@"active"];
        [spectrum updateSelectionAtLocation:CGPointMake(spectrum.bounds.size.width*.37,spectrum.bounds.size.height*.41)];[spectrum setValue:@NO forKey:@"active"];
        BOOL profile=spectrum&&recorder.changes==1&&CFEqual(CGColorGetColorSpace(panel.selectedColor.CGColor),p3Space)&&CGColorGetAlpha(panel.selectedColor.CGColor)==.35&&CGColorEqualToColor(panel.selectedColor.CGColor,spectrum.sampledColor.CGColor);
        panel.selectedColor=inputColor;[spectrum layoutIfNeeded];record(@"spectrumBindingRetainsP3AlphaAndSilentExternalUpdate",profile&&CGColorEqualToColor(spectrum.selectedColor.CGColor,inputColor.CGColor)&&recorder.changes==1,nil);CGColorSpaceRelease(p3Space);

        [panelFavorites setColor:inputColor forSlot:0];
        [panel refreshFavorites];
        NSDictionary *storedSlot=[defaults dictionaryForKey:featureKey][@"slots"][@"0"];
        record(@"refreshRetainsAppLocalFavorite",[[[UIColorValue alloc]initWithPropertyList:storedSlot error:nil] isEqual:inputColor]&&panelFavorites.presentedColors.firstObject==inputColor&&recorder.changes==1,nil);

        configuration=[UIColorPanelConfiguration new];
        configuration.favoritesStore=[[UIColorPickerFavoritesStore alloc]initWithKey:featureKey];
        UIColorPanelViewController *reader=[[UIColorPanelViewController alloc]initWithColor:inputColor configuration:configuration];
        reader.delegate=recorder;
        [reader refreshFavorites];
        BOOL lazy=!reader.isViewLoaded;
        [reader loadViewIfNeeded];
        UIColorPickerSwatchesView *library=[reader valueForKey:@"swatchesView"];
        NSDictionary *newRecord=@{@"version":@1,@"slots":@{@"3":[inputColor propertyListRepresentationWithError:nil]}};
        [defaults setObject:newRecord forKey:featureKey]; // A writer without the in-process notification.
        [reader refreshFavorites];
        BOOL imported=library.presentedColors.count==1&&[[library colorAtIndex:3] isEqual:inputColor];
        UIColorValue *sameObject=[library colorAtIndex:3];
        [reader refreshFavorites];
        BOOL unchanged=[library colorAtIndex:3]==sameObject;
        UIColorPickerFavoritesStore *peer=[[UIColorPickerFavoritesStore alloc]initWithKey:featureKey];
        [peer writeRecord:empty];
        record(@"loadedControllerRefreshesExactSparseColorsAndObservesPeerClear",lazy&&imported&&unchanged&&!library.presentedColors.count&&reader.selectedColor==inputColor&&recorder.changes==1,nil);

        [defaults removeObjectForKey:featureKey];
        [reader refreshFavorites];
        library.usesNativePickerPresentation=NO;
        library.usesNativePickerPresentation=YES;
        record(@"refreshOfRemovedRecordDoesNotWriteOrReseed",!library.presentedColors.count&&![defaults objectForKey:featureKey],nil);

        library.usesNativePickerPresentation=NO;
        [peer writeRecord:newRecord];
        [library.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                             animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [peer writeRecord:@{@"version":@1,@"slots":@{@"0":[other propertyListRepresentationWithError:nil]}}];
        record(@"managerRefreshDoesNotRetargetDeleteToAnotherSlot",
               library.presentedColors.count==1&&[[library colorAtIndex:0]isEqual:other]&&
               ![library canPerformAction:@selector(delete:) withSender:nil]&&recorder.changes==1,nil);

        view.usesNativePickerPresentation=YES;[view layoutIfNeeded];[view.collectionView layoutIfNeeded];
        UILongPressGestureRecognizer *nativeGesture=[view valueForKey:@"nativeDeleteGesture"];
        record(@"nativeFooterInstallsDeleteWithoutCollectionDragDrop",managerDrag&&managerDrop&&!hasTransport(view.collectionView)&&hasTransport(well)&&nativeGesture.enabled&&[view.collectionView.gestureRecognizers containsObject:nativeGesture],nil);
        view.usesNativePickerPresentation=NO;
        NSArray *firstManagerInteractions=[view.collectionView.interactions copy];NSDictionary *firstInteractionDetails=interactionDetails(firstManagerInteractions);BOOL firstSnapshotUnchanged=managerInteractions.count==firstManagerInteractions.count&&[[NSSet setWithArray:managerInteractions]isEqualToSet:[NSSet setWithArray:firstManagerInteractions]],firstGestureDisabled=!nativeGesture.enabled;
        view.usesNativePickerPresentation=YES;view.usesNativePickerPresentation=NO;
        NSArray *secondManagerInteractions=[view.collectionView.interactions copy];NSDictionary *secondInteractionDetails=interactionDetails(secondManagerInteractions);BOOL secondSnapshotUnchanged=managerInteractions.count==secondManagerInteractions.count&&[[NSSet setWithArray:managerInteractions]isEqualToSet:[NSSet setWithArray:secondManagerInteractions]],secondGestureDisabled=!nativeGesture.enabled;
        BOOL firstOwnedRestored=ownedInteractionsRestored(firstInteractionDetails),secondOwnedRestored=ownedInteractionsRestored(secondInteractionDetails);
        BOOL roundTrip=ownedInteractionsRestored(initialInteractionDetails)&&firstOwnedRestored&&secondOwnedRestored&&firstGestureDisabled&&secondGestureDisabled;
        view.usesNativePickerPresentation=YES;[view layoutIfNeeded];[view.collectionView layoutIfNeeded];
        record(@"managerRoundTripRestoresSameInteractionsWithoutDuplicates",roundTrip&&!hasTransport(view.collectionView)&&nativeGesture.enabled,@{@"initial":initialInteractionDetails,@"firstReturn":firstInteractionDetails,@"secondReturn":secondInteractionDetails,@"firstOwnedRestored":@(firstOwnedRestored),@"secondOwnedRestored":@(secondOwnedRestored),@"firstSnapshotUnchanged":@(firstSnapshotUnchanged),@"secondSnapshotUnchanged":@(secondSnapshotUnchanged),@"nativeDeleteDisabledInManager":@(firstGestureDisabled&&secondGestureDisabled)});
        NSIndexPath *firstIndex=[NSIndexPath indexPathForItem:0 inSection:0],*addIndex=[NSIndexPath indexPathForItem:3 inSection:0];
        UICollectionViewCell *cell=[view.collectionView cellForItemAtIndexPath:firstIndex],*add=[view.collectionView cellForItemAtIndexPath:addIndex];
        BOOL responder=window&&cell.window==window&&cell.canBecomeFirstResponder&&[cell becomeFirstResponder]&&cell.isFirstResponder&&[cell canPerformAction:@selector(delete:) withSender:menu];
        for(NSString *action in @[@"copy:",@"paste:",@"cut:",@"select:",@"selectAll:"])responder=responder&&![cell canPerformAction:NSSelectorFromString(action) withSender:menu];
        record(@"attachedNativeCellAcceptsOnlyDelete",responder,@{@"attached":@(window&&cell.window==window),@"firstResponder":@(cell.isFirstResponder)});[cell resignFirstResponder];
        UIFavoritesNativeLongPress *gesture=[UIFavoritesNativeLongPress new];gesture.testLocation=CGPointMake(CGRectGetMidX(cell.frame),CGRectGetMidY(cell.frame));
        [view showNativeDeleteCallout:gesture];BOOL presented=waitForMenu(YES)&&cell.isFirstResponder;
        record(@"productionLongPressHandlerPresentsNativeDeleteMenu",presented,@{@"menuVisible":@(menu.menuVisible),@"cellIsFirstResponder":@(cell.isFirstResponder),@"recognition":@"Synthetic Began/location only; physical long press and arbitration are not tested."});
        [menu setMenuVisible:NO animated:NO];BOOL hidden=waitForMenu(NO);[cell resignFirstResponder];gesture.testLocation=CGPointMake(CGRectGetMidX(add.frame),CGRectGetMidY(add.frame));[view showNativeDeleteCallout:gesture];
        record(@"addCellExcludedFromDeleteCallout",hidden&&window&&add.window==window&&!menu.menuVisible&&!add.isFirstResponder&&!cell.isFirstResponder&&view.presentedColors.count==3,nil);
        gesture.testLocation=CGPointMake(CGRectGetMidX(cell.frame),CGRectGetMidY(cell.frame));[view showNativeDeleteCallout:gesture];BOOL ready=waitForMenu(YES)&&cell.isFirstResponder;
        BOOL dispatched=ready&&[UIApplication.sharedApplication sendAction:@selector(delete:) to:nil from:menu forEvent:nil];
        record(@"deleteDispatchRemovesOneDuplicateWithoutChangingCurrentColor",dispatched&&view.presentedColors.count==2&&![view colorAtIndex:0]&&[view colorAtIndex:1]==other&&[view colorAtIndex:2]==duplicate&&view.currentColor==duplicate,@{@"actionDispatched":@(dispatched),@"remainingCount":@(view.presentedColors.count)});
    } @finally {[defaults removeObjectForKey:featureKey];[menu setMenuVisible:NO animated:NO];[host endEditing:YES];[view cancelPendingDrops];
        // Optional touch inspection keeps only this in-memory fixture alive
        // until the demo exits; the normal finite run removes it immediately.
        if(keepFixture)host.backgroundColor=UIColor.whiteColor;
        else {view.currentColorSourceView=nil;[host removeFromSuperview];}}
    NSDictionary *result=@{@"caseCount":@(cases.count),@"failureCount":@(failures),@"cases":cases,@"scope":@"Focused SF toolbar/favorites initialization, alpha capability and Spectrum profile integration, plus existing native-footer responder/menu wiring. Unique defaults fixtures are removed afterward. Spectrum active state and recognizer Began/location are programmatic; physical touch, long press, spoken VoiceOver and new native raster comparison are not claimed."};
    NSData *output=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];return[output writeToURL:url atomically:YES]&&failures==0;
}
+ (BOOL)runWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray new];__block NSUInteger failures=0;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL pass,NSDictionary *details){NSMutableDictionary *entry=[@{@"name":name,@"pass":@(pass)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];if(!pass)failures++;};
    UIColorPickerSwatchesView *view=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectMake(0,0,166,48)];[view layoutIfNeeded];
    NSArray *attributes=[view.favoriteLayout layoutAttributesForElementsInRect:view.collectionView.bounds];NSUInteger empty=0;for(UICollectionViewLayoutAttributes *attribute in attributes)if([attribute.representedElementKind isEqual:UIColorPanelEmptySwatchKind])empty++;
    record(@"compactEmptyDecorationsAreNotStoredColors",view.slots.count==0&&view.presentedColors.count==0&&empty==20&&[view.favoriteLayout numberOfItemsFittingInBoundsWidth:166]==10,nil);
    view.frame=CGRectMake(0,0,262,48);[view setNeedsLayout];[view layoutIfNeeded];CGSize size=view.favoriteLayout.collectionViewContentSize;
    record(@"responsiveWideViewportHasNoHorizontalOverflow",[view.favoriteLayout numberOfItemsFittingInBoundsWidth:view.collectionView.bounds.size.width]==17&&size.width==262&&!view.collectionView.showsHorizontalScrollIndicator,nil);
    CGColorSpaceRef p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);CGFloat components[]={.25,.7,.9,.37};CGColorRef cg=CGColorCreate(p3,components);UIColorValue *color=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);CGColorSpaceRelease(p3);UIColorValue *zero=[color copyWithAlpha:0];
    NSString *key=[@"UIColorPanelKit.FavoritesValidation." stringByAppendingString:NSUUID.UUID.UUIDString];NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    NSDictionary *opaqueFuture=@{@"version":@99,@"preservedFutureRecord":@YES};NSDictionary *legacy=@{@"version":@1,@"slots":@{@"2":[color propertyListRepresentationWithError:nil],@"40":[zero propertyListRepresentationWithError:nil],@"64":opaqueFuture}};
    @try {
        [defaults setObject:legacy forKey:key];view.persistenceKey=key;
        record(@"versionOneIndicesAndTrueAlphaZeroRemainDistinct",view.slots.count==65&&view.presentedColors.count==2&&[view colorAtIndex:2]&&[view colorAtIndex:40]&&CGColorGetAlpha([view colorAtIndex:40].CGColor)==0&&[view storeIndexForColorIndex:0]==2&&[view storeIndexForColorIndex:1]==40&&[view storeIndexForColorIndex:2]==41,nil);
        [view setColor:color forSlot:70];NSDictionary *persisted=[defaults dictionaryForKey:key][@"slots"];
        record(@"noTwentyCapAndUnknownRecordsSurviveMutation",view.slots.count==71&&[view colorAtIndex:70]&&[persisted[@"64"]isEqual:opaqueFuture]&&persisted[@"2"]&&persisted[@"40"]&&persisted[@"70"],@{@"backingCount":@(view.slots.count),@"presentedCount":@(view.presentedColors.count)});
        [view.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];[view deleteCurrentColorAndSelectPrevious];persisted=[defaults dictionaryForKey:key][@"slots"];
        record(@"nativeDeleteMarksStoreAndSelectsPrevious",![view colorAtIndex:40]&&[view colorAtIndex:2]&&[view colorAtIndex:70]&&view.presentedColors.count==2&&view.collectionView.indexPathsForSelectedItems.firstObject.item==0&&!persisted[@"40"]&&[persisted[@"64"]isEqual:opaqueFuture],nil);
        view.currentColor=color;BOOL saved=[view saveCurrentColor];UIColorPickerSwatchesView *reopened=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectMake(0,0,166,48)];reopened.persistenceKey=key;
        record(@"appendAndRelaunchPreserveSparseBacking",saved&&[reopened colorAtIndex:2]&&![reopened colorAtIndex:40]&&[reopened colorAtIndex:70]&&[reopened colorAtIndex:71]&&CGColorEqualToColor([reopened colorAtIndex:71].CGColor,color.CGColor),nil);reopened.persistenceKey=nil;
        for(NSUInteger i=0;i<64;i++)[view.favoriteStore addColor:color];[view.collectionView reloadData];size=view.favoriteLayout.collectionViewContentSize;
        record(@"occupiedOverflowIsVerticalOnly",view.presentedColors.count>20&&size.width==view.collectionView.bounds.size.width&&size.height>view.collectionView.bounds.size.height,@{@"count":@(view.presentedColors.count),@"contentSize":@[@(size.width),@(size.height)]});
    } @finally {view.persistenceKey=nil;[defaults removeObjectForKey:key];}

    NSString *asyncKey=[@"UIColorPanelKit.FavoritesAsyncValidation." stringByAppendingString:NSUUID.UUID.UUIDString],*otherKey=[asyncKey stringByAppendingString:@".other"];
    UIColorPickerSwatchesView *asyncView=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectMake(0,0,320,220)];[asyncView layoutIfNeeded];
    NSDictionary *sourceRecord=[color propertyListRepresentationWithError:nil],*zeroRecord=[zero propertyListRepresentationWithError:nil];NSDictionary *seed=@{@"version":@1,@"slots":@{@"0":sourceRecord,@"1":zeroRecord}};
    NSData *droppedData=[NSPropertyListSerialization dataWithPropertyList:sourceRecord format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    UIFavoritesDeferredItemProvider *(^beginDrop)(void)=^UIFavoritesDeferredItemProvider *{
        UIFavoritesDeferredItemProvider *provider=[UIFavoritesDeferredItemProvider new];UIFavoritesDeferredDropSession *session=[UIFavoritesDeferredDropSession new];session.items=@[[[UIDragItem alloc]initWithItemProvider:provider]];session.location=CGPointMake(16,16);
        [asyncView dropInteraction:nil performDrop:(id<UIDropSession>)session];return provider;
    };
    __block NSUInteger changes=0;id changeObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIFavoriteColorsDidChangeNotification object:asyncView.favoriteStore queue:nil usingBlock:^(NSNotification *notification){changes++;}];
    @try {
        [defaults setObject:seed forKey:asyncKey];asyncView.persistenceKey=asyncKey;
        NSDictionary *future=@{@"version":@99,@"futurePayload":@[@"original"]};
        NSDictionary *writableEmpty=@{@"version":@1,@"slots":@{}};
        UIColorPickerFavoritesStore *backing=[[UIColorPickerFavoritesStore alloc]initWithKey:asyncKey];
        asyncView.favoritesStore=backing;
        [backing writeRecord:writableEmpty];
        UIFavoritesDeferredItemProvider *delayed=beginDrop();
        [backing writeRecord:future];
        [backing writeRecord:writableEmpty];
        if(delayed.dataCompletion)delayed.dataCompletion(droppedData,nil);
        BOOL cancelled=UIFavoritesDrainMainQueue()&&delayed.dataCompletion&&[[backing readRecord]isEqual:writableEmpty]&&!asyncView.slots.count;
        record(@"emptyFutureEmptyTransitionInvalidatesPreviousDrop",cancelled,nil);
        [defaults setObject:future forKey:asyncKey]; // External update with no notification to this view.
        __block NSUInteger backingWrites=0;
        id writes=[NSNotificationCenter.defaultCenter addObserverForName:UIColorPickerFavoritesStoreDidChangeNotification object:backing queue:nil usingBlock:^(NSNotification *note){backingWrites++;}];
        changes=0;
        asyncView.currentColor=color;
        BOOL staleSave=[asyncView saveCurrentColor];
        [asyncView.favoriteStore addColor:color];
        [NSNotificationCenter.defaultCenter removeObserver:writes];
        record(@"staleEditableViewCannotOverwriteNewerUnsupportedBacking",!staleSave&&!backingWrites&&!changes&&
               !asyncView.slots.count&&[[backing readRecord]isEqual:future],nil);
        [backing writeRecord:writableEmpty];
        [defaults setObject:@{@"version":@1,@"slots":@{@"1":@"bad color",@"5":sourceRecord}} forKey:asyncKey];
        BOOL staleEdit=[asyncView saveCurrentColor];
        record(@"staleEditImportsRepairedSlotsBeforeAnyNewSave",!staleEdit&&
               [[backing readRecord]isEqual:@{@"version":@1,@"slots":@{@"5":sourceRecord}}]&&
               asyncView.presentedColors.count==1&&[[asyncView colorAtIndex:5]isEqual:color],nil);
        [defaults setObject:@"corrupt library" forKey:asyncKey];
        [asyncView refreshFavorites];
        record(@"standaloneManagerRebuildsEmptyWritableLibrary",asyncView.favoritesEditable&&!asyncView.slots.count&&
               [[backing readRecord]isEqual:writableEmpty]&&[asyncView saveCurrentColor],nil);
        asyncView.favoritesStore=nil;
        [defaults setObject:seed forKey:asyncKey];asyncView.persistenceKey=asyncKey;
        NSUInteger initialCount=asyncView.presentedColors.count;UIFavoritesDeferredItemProvider *provider=beginDrop();BOOL began=provider.dataCompletion!=nil;changes=0;
        if(provider.dataCompletion){provider.dataCompletion(droppedData,nil);provider.dataCompletion(droppedData,nil);}BOOL drained=UIFavoritesDrainMainQueue();
        BOOL exactDrop=asyncView.presentedColors.count==initialCount+1&&[asyncView.presentedColors.firstObject isEqual:color];
        UIColorValue *decodedInput=[[UIColorValue alloc]initWithPropertyList:[NSPropertyListSerialization propertyListWithData:droppedData options:NSPropertyListImmutable format:nil error:nil] error:nil];
        record(@"externalDropAcceptsUnchangedStoreAndConsumesCompletionOnce",drained&&began&&exactDrop&&changes==1,@{@"providerBegan":@(began),@"mainQueueDrained":@(drained),@"inputDataIsExact":@([decodedInput isEqual:color]),@"notifications":@(changes),@"count":@(asyncView.presentedColors.count)});

        UIFavoritesDeferredItemProvider *firstConcurrent=beginDrop(),*secondConcurrent=beginDrop();initialCount=asyncView.presentedColors.count;changes=0;
        if(firstConcurrent.dataCompletion)firstConcurrent.dataCompletion(droppedData,nil);if(secondConcurrent.dataCompletion)secondConcurrent.dataCompletion(droppedData,nil);drained=UIFavoritesDrainMainQueue();
        record(@"concurrentExternalDropsCancelRemainingPositionsAfterFirstInsertion",drained&&firstConcurrent.dataCompletion&&secondConcurrent.dataCompletion&&asyncView.presentedColors.count==initialCount+1&&changes==1,@{@"mainQueueDrained":@(drained)});

        provider=beginDrop();[asyncView cancelPendingDrops];NSArray *before=[asyncView.slots copy];NSDictionary *beforeData=[defaults dictionaryForKey:asyncKey];changes=0;
        if(provider.dataCompletion){provider.dataCompletion(droppedData,nil);provider.dataCompletion(droppedData,nil);}drained=UIFavoritesDrainMainQueue();
        record(@"cancelledExternalDropHasNoLateWriteOrNotification",drained&&provider.dataCompletion&&[asyncView.slots isEqual:before]&&[[defaults dictionaryForKey:asyncKey]isEqual:beforeData]&&changes==0,@{@"mainQueueDrained":@(drained)});

        provider=beginDrop();[defaults setObject:seed forKey:otherKey];asyncView.persistenceKey=otherKey;before=[asyncView.slots copy];NSDictionary *originalData=[defaults dictionaryForKey:asyncKey];beforeData=[defaults dictionaryForKey:otherKey];changes=0;
        if(provider.dataCompletion)provider.dataCompletion(droppedData,nil);drained=UIFavoritesDrainMainQueue();
        record(@"externalDropCannotWriteAcrossPersistenceKeyChange",drained&&provider.dataCompletion&&[asyncView.slots isEqual:before]&&[[defaults dictionaryForKey:asyncKey]isEqual:originalData]&&[[defaults dictionaryForKey:otherKey]isEqual:beforeData]&&changes==0,@{@"mainQueueDrained":@(drained)});

        for(NSUInteger mutation=0;mutation<3;mutation++){
            [defaults setObject:seed forKey:asyncKey];asyncView.persistenceKey=asyncKey;provider=beginDrop();
            if(mutation==0)[asyncView.favoriteStore addColor:color];
            else if(mutation==1){[asyncView.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];[asyncView deleteCurrentColorAndSelectPrevious];}
            else [asyncView.favoriteStore moveColorAtIndex:0 toIndex:1 replacement:NO];
            [asyncView persistSlots];
            before=[asyncView.slots copy];beforeData=[defaults dictionaryForKey:asyncKey];changes=0;
            if(provider.dataCompletion)provider.dataCompletion(droppedData,nil);drained=UIFavoritesDrainMainQueue();
            record(@[@"externalDropCancelledAfterInsertionRevision",@"externalDropCancelledAfterDeletionRevision",@"externalDropCancelledAfterMoveRevision"][mutation],drained&&provider.dataCompletion&&[asyncView.slots isEqual:before]&&[[defaults dictionaryForKey:asyncKey]isEqual:beforeData]&&changes==0,@{@"mainQueueDrained":@(drained)});
        }

        UIColorPanelSavedColorsController *manager=[[UIColorPanelSavedColorsController alloc]initWithSwatchesView:asyncView];UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:manager];[manager loadViewIfNeeded];
        for(NSUInteger exit=0;exit<2;exit++){
            provider=beginDrop();if(exit==0)[manager close:nil];else[manager viewDidDisappear:NO];before=[asyncView.slots copy];beforeData=[defaults dictionaryForKey:asyncKey];changes=0;
            if(provider.dataCompletion)provider.dataCompletion(droppedData,nil);drained=UIFavoritesDrainMainQueue();
            record(exit==0?@"managerDoneInvalidatesExternalDrop":@"managerExternalDisappearanceInvalidatesExternalDrop",drained&&navigation.viewControllers.firstObject==manager&&provider.dataCompletion&&[asyncView.slots isEqual:before]&&[[defaults dictionaryForKey:asyncKey]isEqual:beforeData]&&changes==0,@{@"mainQueueDrained":@(drained),@"scope":@"Actual manager exit/lifecycle method; no native modal dismissal gesture claimed."});
        }

        UIGraphicsImageRenderer *patternRenderer=[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(2,2)];UIImage *patternImage=[patternRenderer imageWithActions:^(UIGraphicsImageRendererContext *context){[UIColor.redColor setFill];UIRectFill(CGRectMake(0,0,2,2));}];
        UIColorValue *pattern=[[UIColorValue alloc]initWithCGColor:[UIColor colorWithPatternImage:patternImage].CGColor];asyncView.currentColor=pattern;before=[asyncView.slots copy];beforeData=[defaults dictionaryForKey:asyncKey];changes=0;NSError *patternError=nil;
        BOOL rejected=pattern&&![pattern propertyListRepresentationWithError:&patternError]&&![asyncView saveCurrentColor]&&![asyncView accessibilitySaveCurrentColor:nil];
        NSInteger patternModel=pattern?CGColorSpaceGetModel(CGColorGetColorSpace(pattern.CGColor)):kCGColorSpaceModelUnknown;
        record(@"patternSaveWithPersistenceFailsWithoutMutatingColorOrExistingRecords",rejected&&patternError!=nil&&asyncView.currentColor==pattern&&[asyncView.slots isEqual:before]&&[[defaults dictionaryForKey:asyncKey]isEqual:beforeData]&&changes==0,@{@"model":@(patternModel),@"error":patternError.localizedDescription?:@"",@"scope":@"Serialization and AX failure route; visible Add error alert is checked separately."});
        UIColorPickerSwatchesView *memoryView=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectZero];memoryView.currentColor=pattern;
        record(@"nonpersistentPatternSaveRetainsExistingInMemoryCapability",pattern&&[memoryView saveCurrentColor]&&memoryView.presentedColors.count==1&&CGColorEqualToColor(memoryView.presentedColors.firstObject.CGColor,pattern.CGColor),nil);
    } @finally {
        [asyncView cancelPendingDrops];[NSNotificationCenter.defaultCenter removeObserver:changeObserver];asyncView.persistenceKey=nil;[defaults removeObjectForKey:asyncKey];[defaults removeObjectForKey:otherKey];
    }
    view.logicalScale=2;view.frame=CGRectMake(0,0,332,96);[view setNeedsLayout];[view layoutIfNeeded];
    record(@"singleUniformScaleRetainsNativeLogicalGeometry",view.collectionView.bounds.size.width==166&&view.collectionView.bounds.size.height==48&&[view.favoriteLayout numberOfItemsFittingInBoundsWidth:view.collectionView.bounds.size.width]==10&&view.intrinsicContentSize.height==96,nil);
    UIView *well=[[UIView alloc]initWithFrame:CGRectMake(0,0,33,31)];view.currentColorSourceView=well;BOOL drag=NO;for(id interaction in well.interactions)drag|=[interaction isKindOfClass:UIDragInteraction.class];BOOL saveAction=NO;for(UIAccessibilityCustomAction *action in well.accessibilityCustomActions)saveAction|=[action.name isEqual:@"Save Current Color"];
    record(@"existingCurrentWellHasDragAndSaveAccessibilityWithoutVisibleButtons",drag&&saveAction&&view.subviews.count==1,nil);
    UIBezierPath *outline=[UIColorPanelAppearance smoothPathForRect:CGRectMake(0,0,13,13) radius:2];BOOL geometry=CGRectEqualToRect(outline.bounds,CGRectMake(0,0,13,13));
    for(NSValue *point in @[[NSValue valueWithCGPoint:CGPointMake(.5,.5)],[NSValue valueWithCGPoint:CGPointMake(12.5,.5)],[NSValue valueWithCGPoint:CGPointMake(.5,12.5)],[NSValue valueWithCGPoint:CGPointMake(12.5,12.5)]])geometry=geometry&&![outline containsPoint:point.CGPointValue];
    for(NSValue *point in @[[NSValue valueWithCGPoint:CGPointMake(.75,.75)],[NSValue valueWithCGPoint:CGPointMake(12.25,.75)],[NSValue valueWithCGPoint:CGPointMake(.75,12.25)],[NSValue valueWithCGPoint:CGPointMake(12.25,12.25)]])geometry=geometry&&[outline containsPoint:point.CGPointValue];
    UIBezierPath *clamped=[UIColorPanelAppearance smoothPathForRect:CGRectMake(0,0,13,13) radius:100];geometry=geometry&&CGRectEqualToRect(clamped.bounds,outline.bounds)&&[clamped containsPoint:CGPointMake(6.5,6.5)];
    record(@"smoothRadiusHasSymmetricDiagonalInsetAndClampedNonselfIntersectingBounds",geometry,@{@"radius":@2,@"expectedDiagonalInset":@(2*(1-M_SQRT1_2)),@"outsideFourCornerPointInset":@.5,@"insideFourCornerPointInset":@.75});
    NSMutableDictionary<NSNumber *,NSData *> *zeroAlphaPlanes=[NSMutableDictionary new];BOOL alphaIndependent=YES;
    NSMutableArray *drawing=[NSMutableArray new];for(id candidate in @[NSNull.null,zero,color]){
        UIColorPanelFavoriteSwatchView *swatch=[[UIColorPanelFavoriteSwatchView alloc]initWithFrame:CGRectMake(0,0,13,13)];swatch.color=candidate==NSNull.null?nil:candidate;
        NSMutableArray *rasters=[NSMutableArray new];BOOL pass=YES;
        for(NSUInteger scale=1;scale<=3;scale++){
            NSUInteger pixels=13*scale;UIGraphicsBeginImageContextWithOptions(CGSizeMake(13,13),NO,scale);[swatch drawRect:swatch.bounds];UIImage *image=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();NSMutableData *storage=[NSMutableData dataWithLength:pixels*pixels*4];uint8_t *bytes=storage.mutableBytes;CGColorSpaceRef rgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGContextRef context=CGBitmapContextCreate(bytes,pixels,pixels,8,pixels*4,rgb,kCGImageAlphaPremultipliedLast);CGColorSpaceRelease(rgb);CGContextDrawImage(context,CGRectMake(0,0,pixels,pixels),image.CGImage);CGContextRelease(context);
            NSArray *corners=@[@(bytes[3]),@(bytes[(pixels-1)*4+3]),@(bytes[((pixels-1)*pixels)*4+3]),@(bytes[(pixels*pixels-1)*4+3])];BOOL corner=YES;for(NSNumber *alpha in corners)corner&=alpha.unsignedIntegerValue==0;
            BOOL center=candidate==NSNull.null?bytes[((pixels/2)*pixels+pixels/2)*4+3]==0:bytes[((pixels/2)*pixels+pixels/2)*4+3]==255;BOOL diagonal=candidate!=zero||abs((int)bytes[((pixels/2)*pixels+3*scale)*4]-(int)bytes[((pixels/2)*pixels+9*scale)*4])>200;
            // The authored smooth radius2 outline retreats .5858pt on each
            // diagonal. The entire .5pt (2x) and .333pt (3x) corner pixels are
            // outside it; exact zero is retained rather than relaxing a cutoff.
            // A 1pt pixel can intersect the edge and is diagnostic for corners.
            pass=pass&&center&&diagonal&&(scale==1||corner);
            NSMutableData *alphaPlane=[NSMutableData dataWithLength:pixels*pixels];uint8_t *alphaBytes=alphaPlane.mutableBytes;for(NSUInteger pixel=0;pixel<pixels*pixels;pixel++)alphaBytes[pixel]=bytes[pixel*4+3];
            if(candidate==zero)zeroAlphaPlanes[@(scale)]=alphaPlane;else if(candidate!=NSNull.null)alphaIndependent=alphaIndependent&&[zeroAlphaPlanes[@(scale)] isEqual:alphaPlane];
            NSString *state=candidate==NSNull.null?@"empty":(candidate==zero?@"alphaZero":@"fractionalAlpha");NSString *name=[NSString stringWithFormat:@"favorite-%@-%lux.png",state,(unsigned long)scale];[UIImagePNGRepresentation(image)writeToURL:[[url URLByDeletingLastPathComponent]URLByAppendingPathComponent:name]atomically:YES];
            [rasters addObject:@{@"scale":@(scale),@"pixelDimensions":@[@(CGImageGetWidth(image.CGImage)),@(CGImageGetHeight(image.CGImage))],@"cornerAlpha":corners,@"centerAlpha":@(bytes[((pixels/2)*pixels+pixels/2)*4+3]),@"allFourCornersTransparent":@(corner),@"expectedCenterOccupancy":@(center),@"diagonalNotTransparentPlaceholder":@(diagonal),@"acceptanceGate":scale>=2?@"Radius2 geometric exterior: all four corner pixels exactly alpha0":@"Corner diagnostic only: 1pt pixels can intersect the smooth edge",@"image":name}];
        }
        if(!pass)failures++;[drawing addObject:@{@"name":candidate==NSNull.null?@"empty":(candidate==zero?@"alphaZero":@"fractionalAlpha"),@"pass":@(pass),@"rasters":rasters}];
    }
    record(@"occupiedOutlineCoverageIsIndependentOfStoredAlpha",alphaIndependent,@{@"scales":@[@1,@2,@3],@"comparison":@"Every alpha-plane byte of the actual alpha-zero and fractional-alpha UIKit rasters must match; both use the same opaque alpha background."});
    [cases addObject:@{@"name":@"actualUIKitSwatchDrawing",@"pass":@([drawing filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pass == NO"]].count==0),@"states":drawing}];
    NSData *output=[NSJSONSerialization dataWithJSONObject:@{@"caseCount":@(cases.count),@"failureCount":@(failures),@"cases":cases,@"scope":@"Programmatic UIKit favorites layout, exact indexed persistence compatibility, sparse-marker display mapping, deferred external-provider cancellation/duplicate completion, manager exit methods, Pattern save failure and actual drawRect raster checks. No touch/VoiceOver speech/clipboard/native drag or modal gesture pass claimed."} options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];return[output writeToURL:url atomically:YES]&&failures==0;
}
@end
