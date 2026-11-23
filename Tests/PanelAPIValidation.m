#import "PanelAPIValidation.h"
#import "UIColorPanel.h"
#import "UIColorPanelWell.h"
#import "UIColorPanelViewController.h"
#import "UIColorPickerCatalogController.h"
#import "UIColorPickerSwatchesView.h"
#import "UIColorPickerFavoritesStore.h"
#import "UIColorPanelAppearance.h"
#import "UIEyedropperViewController.h"
#import <math.h>

@interface UIColorPanelViewController (SourceAPIValidation)
- (void)applySourceColor:(UIColorValue *)color notify:(BOOL)notify;
- (void)precisionChanged:(UISegmentedControl *)sender;
- (void)spaceChanged:(UISegmentedControl *)sender;
- (void)colorPickerCatalog:(UIColorPickerCatalogController *)catalog didSelectColorValue:(UIColorValue *)color;
- (void)colorPickerSwatches:(UIColorPickerSwatchesView *)view didSelectColorValue:(UIColorValue *)color;
- (void)presentSamplingController:(UIEyedropperViewController *)controller;
- (void)sample:(id)sender;
@end

@interface UIColorPanelAPIRecorder : NSObject <UIColorPanelViewControllerDelegate>
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *events;
@property(nonatomic) BOOL reenter;
@property(nonatomic, strong) UIColorValue *afterReentry;
@property(nonatomic, weak) UIColorPanelViewController *sourceReentryController;
@property(nonatomic, strong) UIColorValue *sourceReentryColor;
@property(nonatomic, strong) UIColorValue *sourceReentryControllerResult;
- (void)panelAction:(UIColorPanel *)panel;
- (void)wellAction:(UIColorPanelWell *)well;
@end
@implementation UIColorPanelAPIRecorder
- (void)panelAction:(UIColorPanel *)panel {
    [self.events addObject:@{@"event":@"panelAction"}];
    if (self.reenter) {
        self.reenter = NO;
        panel.color = UIColor.brownColor;
        self.afterReentry = panel.colorValue;
    }
    if(self.sourceReentryColor){UIColorValue *source=self.sourceReentryColor;self.sourceReentryColor=nil;[self.sourceReentryController applySourceColor:source notify:YES];self.sourceReentryControllerResult=self.sourceReentryController.selectedColor;}
}
- (void)wellAction:(UIColorPanelWell *)well {
    [self.events addObject:@{@"event":@"wellAction", @"well":@(well.tag)}];
}
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {[self.events addObject:@{@"event":@"embeddedSelection"}];}
@end

static UIColor *APIColor(CFStringRef spaceName, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    CGColorSpaceRef space = CGColorSpaceCreateWithName(spaceName);
    CGFloat components[] = {red, green, blue, alpha};
    CGColorRef color = CGColorCreate(space, components);
    UIColor *result = [UIColor colorWithCGColor:color];
    CGColorRelease(color);
    CGColorSpaceRelease(space);
    return result;
}

static NSDictionary *APIColorState(UIColorValue *value) {
    CGColorRef color = value.CGColor;
    CGColorSpaceRef space = CGColorGetColorSpace(color);
    CFStringRef name = CGColorSpaceCopyName(space);
    NSMutableArray *components = [NSMutableArray new];
    const CGFloat *values = CGColorGetComponents(color);
    for (size_t index = 0; index < CGColorGetNumberOfComponents(color); index++) [components addObject:@(values[index])];
    NSDictionary *result = @{@"space":name ? (__bridge NSString *)name : @"unnamed",
                             @"model":@(CGColorSpaceGetModel(space)), @"components":components};
    if (name) CFRelease(name);
    return result;
}

static NSDictionary *APIState(UIColorPanel *panel, UIColorPanelWell *a, UIColorPanelWell *b) {
    return @{@"color":APIColorState(panel.colorValue), @"alpha":@(panel.alpha),
             @"visible":@(panel.visible), @"continuous":@(panel.continuous), @"showsAlpha":@(panel.showsAlpha),
             @"mode":@(panel.mode), @"wellAActive":@(a.active), @"wellBActive":@(b.active),
             @"wellAColor":APIColorState(a.colorValue), @"wellBColor":APIColorState(b.colorValue)};
}

static BOOL APIExpectedState(NSDictionary *actual, NSDictionary *expected, NSMutableArray *failures) {
    NSUInteger previousFailures = failures.count;
    for (NSString *key in expected) {
        id wanted = expected[key], value = actual[key];
        BOOL same = NO;
        if ([wanted isKindOfClass:NSDictionary.class] && [value isKindOfClass:NSDictionary.class]) {
            same = APIExpectedState(value, wanted, failures);
        } else if ([wanted isKindOfClass:NSArray.class] && [value isKindOfClass:NSArray.class]) {
            same = [wanted count] == [value count];
            if (same) for (NSUInteger i = 0; i < [wanted count]; i++) {
                if (!isfinite([value[i] doubleValue]) || fabs([wanted[i] doubleValue] - [value[i] doubleValue]) > 1e-12) { same = NO; break; }
            }
        } else if ([wanted isKindOfClass:NSNumber.class] && [value isKindOfClass:NSNumber.class]) {
            same = fabs([wanted doubleValue] - [value doubleValue]) <= 1e-12;
        } else same = [wanted isEqual:value];
        if (!same) [failures addObject:[NSString stringWithFormat:@"State %@ expected %@, actual %@", key, wanted, value ?: @"missing"]];
    }
    return failures.count == previousFailures;
}

static NSArray<NSString *> *APIEventNames(NSArray<NSDictionary *> *events) {
    NSMutableArray *names = [NSMutableArray new];
    for (NSDictionary *event in events) {
        NSString *name = event[@"event"];
        if ([name isEqual:@"wellAction"]) name = [name stringByAppendingFormat:@":%@",event[@"well"]];
        [names addObject:name];
    }
    return names;
}

static void APICase(NSMutableArray *cases, NSString *name, UIColorPanelAPIRecorder *recorder,
                    UIColorPanel *panel, UIColorPanelWell *a, UIColorPanelWell *b,
                    NSArray<NSString *> *expectedEvents, NSDictionary *expectedState, void (^operation)(void)) {
    [recorder.events removeAllObjects];
    NSMutableArray *failures = [NSMutableArray new];
    @try { operation(); }
    @catch (NSException *exception) { [failures addObject:[NSString stringWithFormat:@"Exception %@: %@",exception.name,exception.reason]]; }
    NSDictionary *actual = APIState(panel,a,b);
    NSArray *events = APIEventNames(recorder.events);
    if (![events isEqual:expectedEvents]) [failures addObject:[NSString stringWithFormat:@"Events expected %@, actual %@",expectedEvents,events]];
    APIExpectedState(actual,expectedState,failures);
    [cases addObject:@{@"case":name,@"status":failures.count ? @"FAIL" : @"PASS",
                      @"expectedEvents":expectedEvents,@"actualEvents":events,
                      @"expectedState":expectedState,@"actualState":actual,@"failures":failures}];
}

// R12 transport checks use original CGColor/ICC values; display UIColor and
// rounded text are never used as the expected canonical color.
static BOOL APIExactColor(UIColorValue *actual,UIColorValue *expected) {
    if(!actual||!expected)return NO;CGColorRef a=actual.CGColor,b=expected.CGColor;
    if(!CFEqual(CGColorGetColorSpace(a),CGColorGetColorSpace(b))||CGColorGetNumberOfComponents(a)!=CGColorGetNumberOfComponents(b))return NO;
    for(NSUInteger n=0;n<CGColorGetNumberOfComponents(a);n++)if(CGColorGetComponents(a)[n]!=CGColorGetComponents(b)[n])return NO;
    return YES;
}
static BOOL APIWaitUntil(BOOL (^condition)(void),NSTimeInterval timeout) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:timeout];while(!condition()&&deadline.timeIntervalSinceNow>0)[NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];return condition();
}
static void APISourceExpect(BOOL condition,NSString *failure,NSMutableArray *failures) {if(!condition)[failures addObject:failure];}
static UIColorValue *APIValueWithComponents(CGColorSpaceRef space,const CGFloat *components) {
    if(!space)return nil;CGColorRef cg=CGColorCreate(space,components);UIColorValue *value=cg?[[UIColorValue alloc]initWithCGColor:cg]:nil;if(cg)CGColorRelease(cg);return value;
}
static void APIPrepareSourceChoice(UIColorPanelViewController *controller,UIColorPanel *shared,UIColorValue *source) {
    UIColorValue *baseline=[[UIColorValue alloc]initWithCGColor:APIColor(kCGColorSpaceSRGB,.25,.4,.6,.65).CGColor];
    if(shared)shared.colorValue=baseline;else controller.selectedColor=baseline;
    controller.mode=UIColorPanelModeRGB;UISegmentedControl *precision=[controller valueForKey:@"precision"];precision.selectedSegmentIndex=1;[controller precisionChanged:precision];
    UISegmentedControl *spaces=[controller valueForKey:@"spaces"];CGColorSpaceRef srgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);spaces.selectedSegmentIndex=CFEqual(CGColorGetColorSpace(source.CGColor),srgb)?1:0;CGColorSpaceRelease(srgb);[controller spaceChanged:spaces];
}
static BOOL APIInvokeSource(UIColorPanelViewController *controller,UIColorPanel *shared,UIColorValue *source,NSString *route) {
    if([route isEqualToString:@"external"]){if(shared)shared.colorValue=source;else controller.selectedColor=source;return YES;}
    if([route isEqualToString:@"favorites"]){[controller colorPickerSwatches:[controller valueForKey:@"swatchesView"] didSelectColorValue:source];return YES;}
    if([route isEqualToString:@"catalog"]){[controller colorPickerCatalog:[controller valueForKey:@"catalogController"] didSelectColorValue:source];return YES;}
    if(![route isEqualToString:@"sampler"])return NO;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(2,2),NO,1);[UIColor.redColor setFill];UIRectFill(CGRectMake(0,0,2,2));UIImage *image=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();
    BOOL oldSPI=controller.use_spi,oldAllows=controller.allowsApplicationSampling;UIImage *oldImage=controller.samplingImage;
    controller.use_spi=NO;controller.allowsApplicationSampling=YES;controller.samplingImage=image;
    @try {
        if(!APIWaitUntil(^BOOL{return UIApplication.sharedApplication.applicationState==UIApplicationStateActive;},2))return NO;
        if(shared)APIWaitUntil(^BOOL{return shared.visible&&!shared.transitioning;},2);
        [controller sample:[controller valueForKey:@"sampleButton"]];
        BOOL presented=APIWaitUntil(^BOOL{return [controller.presentedViewController isKindOfClass:UIEyedropperViewController.class]&&!controller.presentedViewController.isBeingPresented;},2);
        UIEyedropperViewController *sampler=presented?(id)controller.presentedViewController:nil;
        if(!sampler.completionHandler){if(controller.presentedViewController)[controller dismissViewControllerAnimated:NO completion:nil];APIWaitUntil(^BOOL{return controller.presentedViewController==nil;},1);return NO;}
        // Exercise the actual source-session entry and the completion it installs.
        // Its supplied known color tests transport, not image/screen sampling.
        void (^completion)(UIColorValue *)=[sampler.completionHandler copy];completion(source);
        return APIWaitUntil(^BOOL{return controller.presentedViewController==nil&&APIExactColor(controller.selectedColor,source);},2);
    }@finally{controller.use_spi=oldSPI;controller.allowsApplicationSampling=oldAllows;controller.samplingImage=oldImage;}
}
static void APIR12SourceCase(NSMutableArray *cases,NSString *name,UIColorPanelViewController *controller,UIColorPanel *shared,UIColorValue *source,NSString *route,UIColorPanelAPIRecorder *recorder) {
    NSMutableArray *failures=[NSMutableArray new];NSMutableDictionary *details=[NSMutableDictionary new];
    @try {
        APIPrepareSourceChoice(controller,shared,source);[recorder.events removeAllObjects];
        BOOL invoked=APIInvokeSource(controller,shared,source,route);NSArray *sourceEvents=APIEventNames(recorder.events);NSArray *expected=shared?@[@"panelAction",@"notification"]:([route isEqualToString:@"external"]?@[]:@[@"embeddedSelection"]);
        details[@"sourceEvents"]=sourceEvents;details[@"expectedSourceEvents"]=expected;details[@"sourceColor"]=APIColorState(source);details[@"adoptedColor"]=APIColorState(controller.selectedColor);details[@"sourceSpaceIndex"]=[controller valueForKey:@"spaceIndex"];
        APISourceExpect(invoked,@"The real provider/source route did not complete.",failures);APISourceExpect([sourceEvents isEqual:expected],@"Source arrival dispatched a missing, duplicate or unexpected callback.",failures);
        APISourceExpect(APIExactColor(controller.selectedColor,source),@"Source adoption changed original profile/components/alpha.",failures);APISourceExpect([[controller valueForKey:@"spaceIndex"]integerValue]==2,@"Source arrival did not reset the explicit working profile to Original.",failures);
        if(shared)APISourceExpect(APIExactColor(shared.colorValue,source),@"Shared canonical color diverged from the source/controller.",failures);
        [recorder.events removeAllObjects];UITextField *red=[[controller valueForKey:@"componentFields"]firstObject];red.text=[UIColorPanelAppearance formatNumber:.125 significantDigits:9];[red sendActionsForControlEvents:UIControlEventEditingChanged];[red sendActionsForControlEvents:UIControlEventEditingDidEnd];
        const CGFloat *original=CGColorGetComponents(source.CGColor);CGFloat components[]={.125,original[1],original[2],original[3]};UIColorValue *componentExpected=APIValueWithComponents(CGColorGetColorSpace(source.CGColor),components);
        details[@"firstComponentEdit"]=APIColorState(controller.selectedColor);details[@"componentEvents"]=APIEventNames(recorder.events);
        APISourceExpect(APIExactColor(controller.selectedColor,componentExpected),@"The first component edit changed space or untouched source components/alpha.",failures);APISourceExpect([APIEventNames(recorder.events)isEqual:shared?@[@"panelAction",@"notification"]:@[@"embeddedSelection"]],@"The first component edit did not dispatch exactly one selection.",failures);
        if(shared)APISourceExpect(APIExactColor(shared.colorValue,componentExpected),@"Shared component edit and controller differ.",failures);
        // Re-enter through the SAME provider with an opposite explicit profile,
        // then make hex the first edit of a fresh source arrival.
        APIPrepareSourceChoice(controller,shared,source);[recorder.events removeAllObjects];BOOL reinvoked=APIInvokeSource(controller,shared,source,route);
        [recorder.events removeAllObjects];UITextField *hex=[controller valueForKey:@"hexField"];hex.text=@"204060";[hex sendActionsForControlEvents:UIControlEventEditingChanged];[hex sendActionsForControlEvents:UIControlEventEditingDidEnd];CGFloat hexComponents[]={32/255.0,64/255.0,96/255.0,original[3]};UIColorValue *hexExpected=APIValueWithComponents(CGColorGetColorSpace(source.CGColor),hexComponents);
        details[@"firstHexEdit"]=APIColorState(controller.selectedColor);details[@"hexEvents"]=APIEventNames(recorder.events);
        APISourceExpect(reinvoked&&APIExactColor(controller.selectedColor,hexExpected),@"The first hex edit used an old profile or changed source alpha.",failures);APISourceExpect([APIEventNames(recorder.events)isEqual:shared?@[@"panelAction",@"notification"]:@[@"embeddedSelection"]],@"The first hex edit did not dispatch exactly one selection.",failures);
        if(shared)APISourceExpect(APIExactColor(shared.colorValue,hexExpected),@"Shared hex edit and controller differ.",failures);
    }@catch(NSException *exception){[failures addObject:[NSString stringWithFormat:@"Exception %@: %@",exception.name,exception.reason]];}
    [cases addObject:@{@"case":name,@"status":failures.count?@"FAIL":@"PASS",@"details":details,@"failures":failures}];
}

static void APIR12SourceCases(NSMutableArray *cases,UIColorPanel *panel,UIColorPanelAPIRecorder *recorder) {
    CGColorSpaceRef srgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB),p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    const CGFloat white[]={.95047,1,1.08883},black[]={0,0,0},gamma[]={2.2,2.2,2.2},matrix[]={.4124564,.2126729,.0193339,.3575761,.7151522,.119192,.1804375,.072175,.9503041};
    CGColorSpaceRef calibrated=CGColorSpaceCreateCalibratedRGB(white,black,gamma,matrix);NSData *icc=calibrated?CFBridgingRelease(CGColorSpaceCopyICCData(calibrated)):nil;CGColorSpaceRef custom=icc?CGColorSpaceCreateWithICCData((__bridge CFDataRef)icc):NULL;
    UIColorValue *s=APIValueWithComponents(srgb,(CGFloat[]){.2,.5,.7,.42}),*p=APIValueWithComponents(p3,(CGFloat[]){.9,.16,.12,.37}),*c=APIValueWithComponents(custom,(CGFloat[]){.7,.3,.2,.77});
    if(srgb)CGColorSpaceRelease(srgb);if(p3)CGColorSpaceRelease(p3);if(calibrated)CGColorSpaceRelease(calibrated);if(custom)CGColorSpaceRelease(custom);
    if(!s||!p||!c){[cases addObject:@{@"case":@"R12_source_fixture_profiles",@"status":@"FAIL",@"iccBytes":@(icc.length),@"failures":@[@"Could not create actual sRGB/P3/calibrated-ICC runtime fixtures."]}];return;}
    [cases addObject:@{@"case":@"R12_source_fixture_profiles",@"status":@"PASS",@"iccBytes":@(icc.length),@"customICCColor":APIColorState(c),@"failures":@[]}];
    UIWindow *host=nil;for(UIWindow *window in UIApplication.sharedApplication.windows)if(window.isKeyWindow&&!window.hidden&&window!=panel.window){host=window;break;}
    UIViewController *hostController=host.rootViewController;if([hostController isKindOfClass:UINavigationController.class])hostController=((UINavigationController *)hostController).visibleViewController;
    UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeRGB;configuration.savedColorsKey=nil;
    UIColorPanelViewController *embedded=[[UIColorPanelViewController alloc]initWithColor:s configuration:configuration];embedded.delegate=recorder;[embedded loadViewIfNeeded];embedded.view.frame=hostController.view.bounds;
    if(hostController){[hostController addChildViewController:embedded];[hostController.view addSubview:embedded.view];[embedded didMoveToParentViewController:hostController];}
    UIColorPanelViewController *shared=[panel valueForKey:@"pickerController"];BOOL oldContinuous=panel.continuous;panel.continuous=YES;panel.showsAlpha=YES;
    @try {
        NSArray *specs=@[@{@"name":@"sRGB",@"color":s},@{@"name":@"P3",@"color":p},@{@"name":@"customICC",@"color":c}];
        for(NSDictionary *spec in specs)APIR12SourceCase(cases,[NSString stringWithFormat:@"R12_embedded_external_%@",spec[@"name"]],embedded,nil,spec[@"color"],@"external",recorder);
        for(NSDictionary *spec in specs)APIR12SourceCase(cases,[NSString stringWithFormat:@"R12_shared_external_%@",spec[@"name"]],shared,panel,spec[@"color"],@"external",recorder);
        for(NSDictionary *spec in @[@{@"route":@"favorites",@"color":p},@{@"route":@"catalog",@"color":c},@{@"route":@"sampler",@"color":[p copyWithAlpha:1]}]){
            NSString *route=spec[@"route"];APIR12SourceCase(cases,[@"R12_embedded_provider_" stringByAppendingString:route],embedded,nil,spec[@"color"],route,recorder);
            if([route isEqualToString:@"sampler"]){[panel orderFront:hostController];APIWaitUntil(^BOOL{return panel.visible&&shared.view.window!=nil;},1);}
            APIR12SourceCase(cases,[@"R12_shared_provider_" stringByAppendingString:route],shared,panel,spec[@"color"],route,recorder);
        }
        NSMutableArray *failures=[NSMutableArray new];APIPrepareSourceChoice(shared,panel,p);[recorder.events removeAllObjects];recorder.sourceReentryController=shared;recorder.sourceReentryColor=c;recorder.sourceReentryControllerResult=nil;[shared applySourceColor:p notify:YES];
        APISourceExpect(APIExactColor(panel.colorValue,p)&&APIExactColor(shared.selectedColor,p)&&APIExactColor(recorder.sourceReentryControllerResult,p),@"A source arriving inside panelAction bypassed shared suppression or left the controller divergent.",failures);
        APISourceExpect([APIEventNames(recorder.events)isEqual:@[@"panelAction",@"notification"]],@"A suppressed reentrant source sent an extra action/notification.",failures);
        // Editing after the suppressed source also detects a hidden stale
        // _originalSpace even when both visible canonical colors were restored.
        [recorder.events removeAllObjects];UITextField *red=[[shared valueForKey:@"componentFields"]firstObject];red.text=[UIColorPanelAppearance formatNumber:.125 significantDigits:9];[red sendActionsForControlEvents:UIControlEventEditingChanged];[red sendActionsForControlEvents:UIControlEventEditingDidEnd];UIColorValue *expected=APIValueWithComponents(CGColorGetColorSpace(p.CGColor),(CGFloat[]){.125,.16,.12,.37});
        APISourceExpect(APIExactColor(panel.colorValue,expected)&&APIExactColor(shared.selectedColor,expected),@"Suppressed reentry changed Original or the next component edit.",failures);
        [cases addObject:@{@"case":@"R12_shared_source_callback_suppression",@"status":failures.count?@"FAIL":@"PASS",@"actualColor":APIColorState(shared.selectedColor),@"failures":failures}];
    }@finally {
        recorder.sourceReentryController=nil;recorder.sourceReentryColor=nil;recorder.sourceReentryControllerResult=nil;
        if(embedded.presentedViewController)[embedded dismissViewControllerAnimated:NO completion:nil];if(shared.presentedViewController)[shared dismissViewControllerAnimated:NO completion:nil];
        [embedded willMoveToParentViewController:nil];[embedded.view removeFromSuperview];[embedded removeFromParentViewController];[panel close];panel.continuous=oldContinuous;
    }
}

@implementation UIColorPanelAPIValidation
+ (NSArray<NSDictionary *> *)configurationSnapshotCases {
    NSMutableArray *cases = [NSMutableArray new];
    NSMutableArray *failures = [NSMutableArray new];
    void (^finishCase)(NSString *) = ^(NSString *name) {
        [cases addObject:@{@"case":name, @"status":failures.count ? @"FAIL" : @"PASS", @"failures":[failures copy]}];
        [failures removeAllObjects];
    };
    NSString *key = [@"PanelAPI.snapshot." stringByAppendingString:NSUUID.UUID.UUIDString];
    UIColorPickerFavoritesStore *store = [[UIColorPickerFavoritesStore alloc] initWithKey:key];
    [store writeRecord:@{@"version":@1, @"slots":@{}}];
    @try {
        UIColorValue *color = [[UIColorValue alloc] initWithCGColor:APIColor(kCGColorSpaceSRGB,.2,.4,.6,.5).CGColor];
        UIColorPalette *palette = [[UIColorPalette alloc] initWithName:@"Fixture" colors:@[color] names:@[@"Blue"]];
        UIColorPanelColorProfile *profile = [[UIColorPanelColorProfile alloc] initWithColorSpace:CGColorGetColorSpace(color.CGColor) displayName:@"Fixture RGB"];
        UIImage *image = [UIImage new];
        UIColorPanelConfiguration *settings = [UIColorPanelConfiguration new];
        settings.initialMode = UIColorPanelModeRGB;
        settings.favoritesStore = store;
        settings.savedColorsKey = key;
        settings.palettes = @[palette];
        settings.colorProfiles = @[profile];
        settings.samplingImage = image;
        settings.allowsApplicationSampling = YES;
        UIColorPanelViewController *first, *second;
        @autoreleasepool {
            UIView *source = [UIView new];
            settings.samplingSourceView = source;
            first = [[UIColorPanelViewController alloc] initWithColor:color configuration:settings];
            second = [[UIColorPanelViewController alloc] initWithColor:color configuration:settings];
            APISourceExpect(first.samplingSourceView == source && second.samplingSourceView == source,
                            @"The configured sampling view was lost during initialization.", failures);
        }
        APISourceExpect(!settings.samplingSourceView && !first.samplingSourceView && !second.samplingSourceView,
                        @"A configuration kept the caller's sampling view alive.", failures);
        finishCase(@"configuration_weak_sampling_view");

        [first loadViewIfNeeded];
        [second loadViewIfNeeded];
        UIColorPickerSwatchesView *firstSwatches = [first valueForKey:@"swatchesView"];
        UIColorPickerSwatchesView *secondSwatches = [second valueForKey:@"swatchesView"];
        APISourceExpect(firstSwatches.favoritesStore == store && secondSwatches.favoritesStore == store,
                        @"Explicit favorites store identity changed.", failures);
        APISourceExpect([firstSwatches saveCurrentColor], @"The first panel could not save its translucent color.", failures);
        [second refreshFavorites];
        APISourceExpect(APIExactColor(secondSwatches.presentedColors.firstObject, color),
                        @"The second panel did not read the saved color from the shared store.", failures);
        finishCase(@"configuration_explicit_shared_favorites");

        UIColorPanelAPIRecorder *recorder = [UIColorPanelAPIRecorder new];
        recorder.events = [NSMutableArray new];
        first.delegate = recorder;
        second.delegate = recorder;
        first.supportsAlpha = NO;
        UIView *firstOpacity = [first valueForKey:@"opacityRow"];
        UIView *secondOpacity = [second valueForKey:@"opacityRow"];
        APISourceExpect(!first.supportsAlpha && firstOpacity.hidden && firstSwatches.presentedColors.count == 0,
                        @"The first panel kept an alpha control or a translucent favorite visible.", failures);
        APISourceExpect(settings.supportsAlpha && second.supportsAlpha && secondOpacity && !secondOpacity.hidden &&
                        APIExactColor(secondSwatches.presentedColors.firstObject, color),
                        @"Changing the first panel affected its template or the second panel.", failures);
        APISourceExpect(APIExactColor(first.selectedColor, color) && APIExactColor(second.selectedColor, color) &&
                        recorder.events.count == 0, @"Changing alpha support edited or dispatched a selection.", failures);
        finishCase(@"configuration_independent_alpha_controls");

        UIColorPanelViewController *pending = [[UIColorPanelViewController alloc] initWithColor:color configuration:settings];
        settings.showsAlpha = NO;
        settings.supportsAlpha = NO;
        settings.use_spi = YES;
        settings.allowsApplicationSampling = NO;
        settings.initialMode = UIColorPanelModePencils;
        settings.favoritesStore = nil;
        settings.savedColorsKey = nil;
        settings.palettes = @[];
        settings.colorProfiles = @[];
        settings.samplingImage = nil;
        UIColorPanelViewController *later = [[UIColorPanelViewController alloc] initWithColor:color configuration:settings];
        [pending loadViewIfNeeded];
        UIColorPanelConfiguration *initial = [pending valueForKey:@"configuration"];
        APISourceExpect(pending.showsAlpha && pending.supportsAlpha && !pending.use_spi && pending.allowsApplicationSampling &&
                        pending.mode == UIColorPanelModeRGB && initial.favoritesStore == store && [initial.savedColorsKey isEqual:key] &&
                        initial.palettes.firstObject == palette && pending.colorProfiles.firstObject == profile && pending.samplingImage == image,
                        @"The unloaded panel did not retain its initial field values and source identities.", failures);
        UIColorPanelConfiguration *updated = [later valueForKey:@"configuration"];
        UIColorPanelMode expectedMode = UICOLORPANEL_ENABLE_PENCILS ? UIColorPanelModePencils : UIColorPanelModeGrid;
        APISourceExpect(!later.showsAlpha && !later.supportsAlpha && later.use_spi && !later.allowsApplicationSampling &&
                        later.mode == expectedMode && !updated.favoritesStore && !updated.savedColorsKey &&
                        !updated.palettes.count && !later.colorProfiles.count && !later.samplingImage,
                        @"A later panel did not use the updated template or the configured build's initial mode.", failures);
        finishCase(@"configuration_snapshot_before_view_load");
    } @finally {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
    }
    return cases;
}

+ (BOOL)runWithOutputURL:(NSURL *)outputURL {
    NSAssert(NSThread.isMainThread, @"Run panel validation on the main thread after UIApplication launch.");
    BOOL existed = UIColorPanel.sharedColorPanelExists;
    BOOL maskBefore = [NSUserDefaults.standardUserDefaults boolForKey:@"UIProbeMaskBeforeAllocation"];
    if (maskBefore && !existed) [UIColorPanel setPickerMask:UIColorPanelRGBModeMask];
    UIColorPanel *panel = UIColorPanel.sharedColorPanel;
    UIColorPanelAPIRecorder *recorder = [UIColorPanelAPIRecorder new];
    recorder.events = [NSMutableArray new];
    UIColorPanelWell *a = [[UIColorPanelWell alloc] initWithFrame:CGRectMake(0,0,44,32)];
    UIColorPanelWell *b = [[UIColorPanelWell alloc] initWithFrame:CGRectMake(0,0,44,32)];
    a.tag = 1; b.tag = 2;
    a.target = recorder; b.target = recorder;
    a.action = @selector(wellAction:); b.action = @selector(wellAction:);
    a.color = APIColor(kCGColorSpaceSRGB,1,0,0,1); b.color = APIColor(kCGColorSpaceSRGB,0,0,1,1);
    panel.target = recorder; panel.action = @selector(panelAction:);
    id observer = [NSNotificationCenter.defaultCenter addObserverForName:UIColorPanelColorDidChangeNotification object:panel queue:nil usingBlock:^(NSNotification *note) {
        [recorder.events addObject:@{@"event":@"notification",@"objectIsPanel":@(note.object == panel)}];
    }];
    NSMutableArray *cases = [NSMutableArray new];
    APICase(cases,@"shared_identity",recorder,panel,a,b,@[],@{},^{
        NSAssert(UIColorPanel.sharedColorPanelExists, @"Shared getter must make exists true.");
        NSAssert(UIColorPanel.sharedColorPanel == panel, @"Shared panel identity must remain stable.");
    });
    if (maskBefore) {
        APICase(cases,@"mask_before_allocation_initial_rgb",recorder,panel,a,b,@[],@{@"mode":@(UIColorPanelModeRGB)},^{});
        for (NSInteger mode = 0; mode < 8; mode++) {
            APICase(cases,[NSString stringWithFormat:@"mask_before_set_mode_%ld",(long)mode],recorder,panel,a,b,@[],@{@"mode":@(UIColorPanelModeRGB)},^{ panel.mode = mode; });
        }
        APICase(cases,@"mask_before_class_set_wheel_stays_rgb",recorder,panel,a,b,@[],@{@"mode":@(UIColorPanelModeRGB)},^{ [UIColorPanel setPickerMode:UIColorPanelModeWheel]; });
    } else {
        [cases addObjectsFromArray:[self configurationSnapshotCases]];
        panel.showsAlpha = YES; panel.continuous = YES;
        panel.color = APIColor(kCGColorSpaceSRGB,0,0,0,1);
        NSDictionary *p3 = @{@"space":(__bridge NSString *)kCGColorSpaceDisplayP3,@"components":@[@.1,@.6,@.9,@.37]};
        APICase(cases,@"continuous_yes_changed",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"color":p3,@"alpha":@.37},^{ panel.color = APIColor(kCGColorSpaceDisplayP3,.1,.6,.9,.37); });
        APICase(cases,@"continuous_yes_same",recorder,panel,a,b,@[],@{@"color":p3,@"alpha":@.37},^{ panel.color = panel.color; });
        APICase(cases,@"continuous_yes_alpha_only",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"color":@{@"components":@[@.1,@.6,@.9,@.23]},@"alpha":@.23},^{ panel.color = [panel.color colorWithAlphaComponent:.23]; });
        APICase(cases,@"continuous_no_changed_no_primary_pointer",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"continuous":@NO,@"color":@{@"components":@[@0,@1,@0,@1]}},^{ panel.continuous = NO; panel.color = APIColor(kCGColorSpaceSRGB,0,1,0,1); });
        APICase(cases,@"continuous_no_same_no_primary_pointer",recorder,panel,a,b,@[@"panelAction",@"notification"],@{},^{ panel.color = panel.color; });
        panel.color = APIColor(kCGColorSpaceDisplayP3,.2,.3,.4,.37);
        APICase(cases,@"hide_alpha_without_assignment",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"showsAlpha":@NO,@"alpha":@1,@"color":@{@"space":(__bridge NSString *)kCGColorSpaceDisplayP3,@"components":@[@.2,@.3,@.4,@1]}},^{ panel.showsAlpha = NO; });
        APICase(cases,@"hide_alpha_then_assign",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"alpha":@1,@"color":@{@"components":@[@.2,@.3,@.4,@1]}},^{ panel.color = APIColor(kCGColorSpaceDisplayP3,.2,.3,.4,.37); });
        APICase(cases,@"show_alpha",recorder,panel,a,b,@[],@{@"showsAlpha":@YES,@"alpha":@1},^{ panel.showsAlpha = YES; });
        APICase(cases,@"wellA_activate_exclusive",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"wellAActive":@YES,@"wellBActive":@NO,@"visible":@YES,@"color":@{@"components":@[@1,@0,@0,@1]}},^{ [a activate:YES]; });
        APICase(cases,@"panel_changed_with_wellA",recorder,panel,a,b,@[@"panelAction",@"wellAction:1",@"notification"],@{@"wellAColor":@{@"components":@[@1,@.5,@0,@1]}},^{ panel.continuous = YES; panel.color = APIColor(kCGColorSpaceSRGB,1,.5,0,1); });
        APICase(cases,@"disabled_active_well_panel_changed",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"wellAActive":@YES,@"wellAColor":@{@"components":@[@1,@.5,@0,@1]},@"color":@{@"components":@[@0,@1,@1,@1]}},^{ a.enabled = NO; panel.color = APIColor(kCGColorSpaceSRGB,0,1,1,1); });
        APICase(cases,@"noncontinuous_well_panel_changed",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"wellAColor":@{@"components":@[@1,@0,@1,@1]}},^{ a.enabled = YES; a.continuous = NO; panel.color = APIColor(kCGColorSpaceSRGB,1,0,1,1); });
        a.continuous = YES;
        APICase(cases,@"active_well_programmatic_color",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"color":@{@"components":@[@.5,@0,@.5,@1]}},^{ a.color = APIColor(kCGColorSpaceSRGB,.5,0,.5,1); });
        APICase(cases,@"wellB_activate_nonexclusive",recorder,panel,a,b,@[],@{@"wellAActive":@YES,@"wellBActive":@YES,@"wellBColor":@{@"components":@[@.5,@0,@.5,@1]}},^{ [b activate:NO]; });
        APICase(cases,@"panel_changed_with_two_wells",recorder,panel,a,b,@[@"panelAction",@"wellAction:1",@"wellAction:2",@"notification"],@{@"wellAColor":@{@"components":@[@1,@1,@0,@1]},@"wellBColor":@{@"components":@[@1,@1,@0,@1]}},^{ panel.color = APIColor(kCGColorSpaceSRGB,1,1,0,1); });
        APICase(cases,@"wellA_deactivate",recorder,panel,a,b,@[],@{@"wellAActive":@NO,@"wellBActive":@YES},^{ [a deactivate]; });
        APICase(cases,@"wellA_activate_exclusive_again",recorder,panel,a,b,@[],@{@"wellAActive":@YES,@"wellBActive":@NO},^{ [a activate:YES]; });
        APICase(cases,@"orderFront",recorder,panel,a,b,@[],@{@"visible":@YES},^{ [panel orderFront:nil]; });
        APICase(cases,@"orderOut",recorder,panel,a,b,@[],@{@"visible":@NO,@"wellAActive":@YES},^{ [panel orderOut:nil]; });
        APICase(cases,@"orderFront_again",recorder,panel,a,b,@[],@{@"visible":@YES,@"wellAActive":@YES},^{ [panel orderFront:nil]; });
        APICase(cases,@"close",recorder,panel,a,b,@[],@{@"visible":@NO,@"wellAActive":@NO,@"wellBActive":@NO},^{ [panel close]; });
        APICase(cases,@"target_nil_changed",recorder,panel,a,b,@[@"notification"],@{},^{ panel.target = nil; panel.color = APIColor(kCGColorSpaceSRGB,0,1,1,1); });
        APICase(cases,@"action_nil_changed",recorder,panel,a,b,@[@"notification"],@{},^{ panel.target = recorder; panel.action = NULL; panel.color = APIColor(kCGColorSpaceSRGB,1,0,1,1); });
        APICase(cases,@"restore_action_without_color_change",recorder,panel,a,b,@[],@{},^{ panel.action = @selector(panelAction:); });
        APICase(cases,@"reentrant_setColor_ignored",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"color":@{@"components":@[@1,@.5,@0,@1]}},^{ recorder.reenter = YES; panel.color = APIColor(kCGColorSpaceSRGB,1,.5,0,1); NSAssert([recorder.afterReentry isEqual:panel.colorValue],@"Nested callback assignment must leave original color intact."); });
        UIView *accessory = [[UIView alloc] initWithFrame:CGRectMake(0,0,100,44)];
        APICase(cases,@"accessory_identity",recorder,panel,a,b,@[],@{},^{ panel.accessoryView = accessory; NSAssert(panel.accessoryView == accessory && accessory.superview, @"Accessory must keep object identity and be installed."); });
        APICase(cases,@"accessory_remove",recorder,panel,a,b,@[],@{},^{ panel.accessoryView = nil; NSAssert(panel.accessoryView == nil && accessory.superview == nil,@"Removing accessory must detach it."); });
        APICase(cases,@"extended_rgb_exact",recorder,panel,a,b,@[@"panelAction",@"notification"],@{@"color":@{@"space":(__bridge NSString *)kCGColorSpaceExtendedSRGB,@"components":@[@1.3,@(-.1),@.4,@.123456789]},@"alpha":@.123456789},^{ panel.color = APIColor(kCGColorSpaceExtendedSRGB,1.3,-.1,.4,.123456789); });
        APIR12SourceCases(cases,panel,recorder);
        [UIColorPanel setPickerMask:UIColorPanelRGBModeMask];
        APICase(cases,@"mask_after_allocation_class_set_wheel",recorder,panel,a,b,@[],@{@"mode":@(UIColorPanelModeWheel)},^{ [UIColorPanel setPickerMode:UIColorPanelModeWheel]; });
        APICase(cases,@"mask_after_allocation_rgb",recorder,panel,a,b,@[],@{@"mode":@(UIColorPanelModeRGB)},^{ panel.mode = UIColorPanelModeRGB; });
        APICase(cases,@"mask_after_allocation_gray",recorder,panel,a,b,@[],@{@"mode":@(UIColorPanelModeGray)},^{ panel.mode = UIColorPanelModeGray; });
    }
    [NSNotificationCenter.defaultCenter removeObserver:observer];
    panel.target = nil; panel.action = NULL;
    [panel close];
    [UIColorPanel setPickerMask:UIColorPanelAllModesMask];
    NSUInteger failed = 0;
    for (NSDictionary *item in cases) if ([item[@"status"] isEqual:@"FAIL"]) failed++;
    NSDictionary *result = @{@"suite":@"UIColorPanel public API native comparison",@"nativeReference":@"reference/provider/equivalence/panel-api-runtime.json",@"sourceProfileNativeReference":@"reference/ui-ux-repairs/original-profile.json",
                             @"sharedExistedBefore":@(existed),@"maskBeforeAllocation":@(maskBefore),@"cases":cases,
                             @"caseCount":@(cases.count),@"failed":@(failed),@"passed":@(failed == 0),
                             @"sourceProfileScope":@"Exact CGColor source adoption and first component/hex edits across external sRGB/P3/runtime-generated ICC and real provider delegate/completion transport in embedded/shared controllers. Sampler uses a real presented controller and its installed completion with a known supplied color; image/screen capture and physical selection are verified elsewhere. Temporary embedded child is removed and its presentations dismissed.",
                             @"unverified":@[@"End-to-end first-responder changeColor: delivery; no responder hit established in native fixture.",@"Real pointer/touch drag end: programmatic calls here run with no active pointer.",@"First lazy ColorList selection and callback order are exercised separately by PanelLazySelectionValidation.",@"R12 provider checks call production delegate/completion transport programmatically; they are not physical favorites/catalog/sampler gestures or VoiceOver speech."]};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:&error];
    if (!data || ![data writeToURL:outputURL options:NSDataWritingAtomic error:&error]) {
        NSLog(@"Panel API validation output failed: %@",error);
        return NO;
    }
    return failed == 0;
}
@end
