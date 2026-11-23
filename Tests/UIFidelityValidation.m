#import "UIFidelityValidation.h"
#import "UIColorPanelViewController.h"
#import "UIColorPickerSwatchesView.h"
#import "UIColorPanelFavoriteSwatchLayout.h"
#import "UIColorArchive.h"
#import "UIColorArchiveRecord.h"
#import "EyedropperValidation.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import "UIColorPickerPencils.h"
#import "UIColorPickerPencilView.h"
#endif
#import "UIColorSurface.h"
#import "UIColorPanel.h"
#import "UIColorPickerCatalogController.h"
#import "UIColorList.h"
#import "UIColorPickerImagePaletteController.h"
#import "UIColorPanelMenuButton.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelSavedColorsController.h"
#import "UIColorPanelChoiceController.h"
#import "UIEyedropperViewController.h"
#import "UIColorPanelWell.h"
#import "UIColorPickerWell.h"
#import "UIColorPanelLifecycle.h"
#import "RecoveredElements/UIColorPickerColorTextField.h"
#import "RecoveredElements/UIColorPickerColorSlider.h"
#import "RecoveredElements/UIColorPickerGridView.h"
#import "RecoveredElements/UIColorPickerSpectrum+Internal.h"
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>
#import <string.h>
#import <stdlib.h>
#import <objc/runtime.h>
@interface UIColorPickerSpectrum (LensRenderingValidation)
- (CALayer *)makeLens;
@end
@interface UIColorPickerGridView (CircleRefinementsValidation)
- (void)sampleAtPoint:(CGPoint)point;
@end
@interface UIColorPanelViewController (WindowValidation)
- (void)keyboardChanged:(NSNotification *)notification;
- (void)restoreSavedColors;
- (void)precisionChanged:(UISegmentedControl *)sender;
- (UIMenu *)sliderModelMenu API_AVAILABLE(ios(13.0));
- (UIMenu *)sliderOptionsMenu API_AVAILABLE(ios(13.0));
- (void)chooseSliderModel:(UIButton *)sender;
- (void)showError:(NSString *)message;
- (void)done:(id)sender;
- (BOOL)commitPendingEdits;
- (BOOL)commitField:(UITextField *)field;
- (void)updateControls;
- (BOOL)selectColorProfile:(UIColorPanelColorProfile *)profile error:(NSError **)error animated:(BOOL)animated;
- (void)endTransientInteractionsForClose:(BOOL)closing;
- (void)invalidateSamplingSession;
- (void)importImage:(UIButton *)sender;
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls;
@end

// Counts the production control's callbacks without manufacturing UITouch or
// replacing its drag, cancellation, accessibility or panel dispatch methods.
@interface UITouchRefinementsRecorder : NSObject <UIColorPanelViewControllerDelegate>
@property(nonatomic) NSUInteger panelActions,selections,begins,changes,ends,cancels;
@property(nonatomic,strong) NSMutableArray<NSString *> *events;
- (void)observeSlider:(UIGradientSlider *)slider;
@end
@implementation UITouchRefinementsRecorder
- (instancetype)init {if((self=[super init]))_events=[NSMutableArray new];return self;}
- (void)panelAction:(UIColorPanel *)panel {self.panelActions++;}
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {self.selections++;}
- (void)began:(UIControl *)control {self.begins++;[self.events addObject:@"begin"];}
- (void)changed:(UIControl *)control {self.changes++;[self.events addObject:@"change"];}
- (void)ended:(UIControl *)control {self.ends++;[self.events addObject:@"end"];}
- (void)cancelled:(UIControl *)control {self.cancels++;[self.events addObject:@"cancel"];}
- (void)observeSlider:(UIGradientSlider *)slider {
    [slider addTarget:self action:@selector(began:) forControlEvents:UIControlEventEditingDidBegin];[slider addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];[slider addTarget:self action:@selector(ended:) forControlEvents:UIControlEventEditingDidEnd];[slider addTarget:self action:@selector(cancelled:) forControlEvents:UIControlEventTouchCancel];
}
@end
@interface UIColorPickerCatalogController (NativeMenuValidation)
- (void)clearSearch:(id)sender;
- (UIMenu *)menuForColorLists API_AVAILABLE(ios(13.0));
- (UIMenu *)menuForColorListActions API_AVAILABLE(ios(13.0));
- (void)openList:(id)sender;
- (void)importListAtURL:(NSURL *)url;
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls;
- (void)renameList:(id)sender;
- (void)newList:(id)sender;
- (void)addColor:(id)sender;
- (void)confirmDeleteColor:(id)sender;
- (void)deleteColor:(id)sender;
- (void)selectListAtIndex:(NSUInteger)index;
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)installList:(UIColorList *)list replacing:(UIColorList *)old;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end
@interface UIColorPickerUserView (InteractionValidation)
- (BOOL)sampleAtPoint:(CGPoint)point;
@end
@interface UIColorPickerImagePaletteController (NativeMenuValidation)
- (UIMenu *)menuForImagePalettes API_AVAILABLE(ios(13.0));
- (UIMenu *)menuForImagePaletteActions API_AVAILABLE(ios(13.0));
- (void)importImage:(id)sender;
- (void)importImageAtURL:(NSURL *)url;
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls;
@end
// Only the final file-import side effect is replaced. Presentation, owner
// registration and late UIDocumentPickerDelegate handling use production code.
@interface UIReviewCatalogImportSpy : UIColorPickerCatalogController
@property(nonatomic) NSUInteger importCalls;
@end
@implementation UIReviewCatalogImportSpy
- (void)importListAtURL:(NSURL *)url {self.importCalls++;}
@end
@interface UIReviewImageImportSpy : UIColorPickerImagePaletteController
@property(nonatomic) NSUInteger importCalls;
@end
@implementation UIReviewImageImportSpy
- (void)importImageAtURL:(NSURL *)url {self.importCalls++;}
@end
// This runner uses the existing app window and the real shared panel. Short
// dispatch boundaries let UIKit finish its own animations and responder work;
// no nested run-loop waits, device preferences or replacement controls are used.
@interface UIReviewRepairsRunner : NSObject <UIColorPanelViewControllerDelegate>
@property(nonatomic,strong) NSURL *outputURL;
@property(nonatomic,strong) UIWindow *host;
@property(nonatomic,strong) UIViewController *anchor;
@property(nonatomic,strong) UIColorPanel *panel;
@property(nonatomic,strong) UIColorPanelViewController *controller;
@property(nonatomic,strong) NSMutableArray<NSDictionary *> *cases;
@property(nonatomic,strong) NSMutableArray<UIColorValue *> *actionColors;
@property(nonatomic,strong) id notificationObserver;
@property(nonatomic,strong) id closeObserver;
@property(nonatomic) NSUInteger notifications,closeNotifications,failures;
@property(nonatomic,strong) NSDictionary *original;
@property(nonatomic,strong) id originalTarget;
@property(nonatomic) SEL originalAction;
@property(nonatomic,strong) UIColorValue *initial,*beforeEdit;
@property(nonatomic,strong) UITextField *editingField;
@property(nonatomic,strong) UITraitCollection *originalTraits;
@property(nonatomic) NSUInteger beforeActions,beforeNotifications,invalidIndex;
@property(nonatomic) BOOL acceptedResponder,modalWasShown;
@property(nonatomic) BOOL reenterDone,targetCaptureBlocked,oldCaptureIgnored;
@property(nonatomic) BOOL reenterSampling,samplingReentryStarted,samplingReentryPreserved;
@property(nonatomic) NSUInteger samplingAGeneration,samplingBGeneration,samplingBCompletions,samplingBCancellations;
@property(nonatomic,strong) UIEyedropperViewController *samplingPickerA,*samplingPickerB;
@property(nonatomic,strong) UIColorValue *samplingBReturnedColor;
@property(nonatomic) NSUInteger beforeCloses,expectedCaptureGeneration;
@property(nonatomic,strong) UIColorValue *expectedSample;
@property(nonatomic,strong) NSDictionary *searchState;
@property(nonatomic,strong) UIView *searchResponder;
@property(nonatomic,strong) UIFont *searchFont;
@property(nonatomic,strong) NSMutableArray<NSDictionary *> *readinessReceipts,*pendingReadinessTimeouts;
@property(nonatomic,strong) UIColorPanelWell *fixtureWell;
@property(nonatomic,strong) UIColorPanelViewController *customController;
@property(nonatomic,strong) UINavigationController *customNavigation;
@property(nonatomic,strong) UIEyedropperViewController *customPicker;
@property(nonatomic) NSUInteger customSelections,customSamplingGeneration;
@property(nonatomic,strong) UIImage *fixtureImage,*filePaletteImage;
@property(nonatomic,strong) NSURL *fixtureFileURL;
@property(nonatomic,strong) UIViewController *fileProvider;
@property(nonatomic,strong) UIDocumentPickerViewController *filePicker;
@property(nonatomic,strong) UIAlertController *competingAlert;
@property(nonatomic) NSUInteger fileRoute,leaveRoute;
@property(nonatomic) BOOL pendingStarted,leavePreparationRejected;
- (void)start;
- (void)runStep:(NSUInteger)step;
- (void)scheduleStep:(NSUInteger)step after:(NSTimeInterval)delay;
- (void)waitForStep:(NSUInteger)step deadline:(NSTimeInterval)deadline started:(NSTimeInterval)started;
- (BOOL)isReadyForStep:(NSUInteger)step;
- (void)record:(NSString *)name passed:(BOOL)passed details:(NSDictionary *)details;
- (void)recordPanelAction:(UIColorPanel *)panel;
- (UIViewController *)presentedController;
- (void)checkLayoutFixtures;
- (void)checkSliderAccessibility;
- (void)restoreSearchFixture;
- (void)removeFileProviderFixture;
- (void)removeCustomFixture;
- (void)finish;
@end

@implementation UIReviewRepairsRunner
- (void)record:(NSString *)name passed:(BOOL)passed details:(NSDictionary *)details {
    passed=passed&&self.pendingReadinessTimeouts.count==0;
    NSMutableDictionary *entry=[@{@"name":name,@"passed":@(passed)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];if(self.pendingReadinessTimeouts.count){entry[@"readinessTimeouts"]=[self.pendingReadinessTimeouts copy];[self.pendingReadinessTimeouts removeAllObjects];}[self.cases addObject:entry];if(!passed)self.failures++;
}
- (void)recordPanelAction:(UIColorPanel *)panel {
    [self.actionColors addObject:panel.colorValue];if(self.reenterDone){self.reenterDone=NO;[self.controller done:nil];}
    if(self.reenterSampling){
        self.reenterSampling=NO;
        // Reenter the real sample button synchronously from A's target-action,
        // before A's dismissal completion resumes its remaining cleanup.
        [[self.controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];
        self.samplingPickerB=[self.controller valueForKey:@"activeSamplingController"];self.samplingBGeneration=[[self.controller valueForKey:@"samplingGeneration"]unsignedIntegerValue];
        self.samplingReentryStarted=self.samplingPickerB&&self.samplingPickerB!=self.samplingPickerA&&self.samplingBGeneration>self.samplingAGeneration&&[self.controller valueForKey:@"samplingIdentityValid"]!=nil&&self.samplingPickerB.completionHandler!=nil;
        void (^productionCompletion)(UIColorValue *)=[self.samplingPickerB.completionHandler copy];__weak typeof(self) weakSelf=self;
        if(productionCompletion)self.samplingPickerB.completionHandler=^(UIColorValue *color){weakSelf.samplingBCompletions++;if(!color)weakSelf.samplingBCancellations++;weakSelf.samplingBReturnedColor=color;productionCompletion(color);};
    }
}
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {if(panel==self.customController)self.customSelections++;}
- (UIViewController *)presentedController {return self.panel.window.rootViewController.presentedViewController?:self.controller.presentedViewController;}
- (void)scheduleStep:(NSUInteger)step after:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(delay*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
        // These deliberately observe an in-flight transition/request. Waiting
        // for readiness here would erase the behavior the fixture must test.
        if(step==0||step==29||step==30){[self runStep:step];return;}
        NSTimeInterval started=NSProcessInfo.processInfo.systemUptime;[self waitForStep:step deadline:started+2 started:started];
    });
}
- (BOOL)isReadyForStep:(NSUInteger)step {
    UIViewController *shown=[self presentedController];
    BOOL stableWindow=!self.panel.isTransitioning;
    BOOL stablePresentation=shown&&shown.isViewLoaded&&shown.view.window==self.panel.window&&!shown.isBeingPresented&&!shown.isBeingDismissed&&!shown.transitionCoordinator;
    BOOL noPresentation=!shown&&!self.panel.window.rootViewController.transitionCoordinator&&!self.controller.transitionCoordinator;
    BOOL releasedSession=![self.controller valueForKey:@"activeSamplingController"]&&![self.controller valueForKey:@"samplingIdentityValid"]&&![[self.controller valueForKey:@"ownsSamplingSurface"]boolValue];
    switch(step){
        // Observe completed appearance, or begin the next interaction only
        // after the previous owned presentation and window transition finish.
        case 1:case 4:case 7:case 10:case 13:case 16:case 18:case 23:case 25:case 40:
        case 51:case 54:case 60:case 71:case 73:case 80:case 82:case 90:
            return stableWindow&&self.panel.isVisible&&!self.panel.window.hidden&&noPresentation;
        case 3:case 6:case 9:case 12:case 21:case 22:case 24:
        case 50:case 53:case 62:case 63:
            return stableWindow&&noPresentation;
        case 55:case 59:return stableWindow&&noPresentation&&!self.anchor.presentedViewController;
        // Read the real presentation only after UIKit has attached it and
        // completed its transition; expected classes remain asserted below.
        case 5:case 8:case 11:case 19:case 26:case 31:case 52:case 61:case 72:case 91:case 92:
            return stableWindow&&stablePresentation;
        case 20:
            return stableWindow&&noPresentation;
        // Dismissal removes the VC before all completion work necessarily
        // runs. Wait for the session identity to be released as well, without
        // polling canonical values, notification counts or expected colors.
        case 27:case 28:case 32:case 35:case 81:case 84:case 93:case 94:
            return stableWindow&&noPresentation&&releasedSession;
        case 56:
            return self.customNavigation.presentingViewController&&self.customController.viewIfLoaded.window==self.host&&!self.customNavigation.transitionCoordinator&&!self.customController.presentedViewController;
        case 57:{
            UIViewController *picker=self.customNavigation.presentedViewController?:self.customController.presentedViewController;
            return picker&&picker.viewIfLoaded.window==self.host&&!picker.isBeingPresented&&!picker.isBeingDismissed&&!picker.transitionCoordinator;
        }
        case 58:
            return !self.customNavigation.presentingViewController&&!self.anchor.presentedViewController&&!self.customController.viewIfLoaded.window&&![self.customController valueForKey:@"activeSamplingController"]&&![self.customController valueForKey:@"samplingIdentityValid"]&&![[self.customController valueForKey:@"ownsSamplingSurface"]boolValue];
        case 83:return stableWindow&&stablePresentation&&releasedSession;
        default:return YES;
    }
}
- (void)waitForStep:(NSUInteger)step deadline:(NSTimeInterval)deadline started:(NSTimeInterval)started {
    @try {
        BOOL ready=[self isReadyForStep:step];NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        if(ready||now>=deadline){
            NSDictionary *receipt=@{@"step":@(step),@"waitedSeconds":@(MAX(0,now-started)),@"timedOut":@(!ready)};[self.readinessReceipts addObject:receipt];if(!ready)[self.pendingReadinessTimeouts addObject:receipt];
            // A timeout never skips or weakens the original business checks.
            // The next existing case also records the timed-out readiness.
            [self runStep:step];return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.05*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[self waitForStep:step deadline:deadline started:started];});
    }@catch(NSException *exception){[self record:@"review readiness exception" passed:NO details:@{@"step":@(step),@"exception":exception.name?:@"",@"reason":exception.reason?:@""}];[self finish];}
}
- (void)start {
    self.cases=[NSMutableArray new];self.actionColors=[NSMutableArray new];self.readinessReceipts=[NSMutableArray new];self.pendingReadinessTimeouts=[NSMutableArray new];
    self.host=UIApplication.sharedApplication.keyWindow;self.anchor=self.host.rootViewController;
    if([self.anchor isKindOfClass:UINavigationController.class])self.anchor=((UINavigationController *)self.anchor).visibleViewController;
    if(!self.host||self.host.hidden||self.anchor.presentedViewController){[self record:@"attached host precondition" passed:NO details:@{@"reason":@"An existing visible app key window without another modal is required."}];[self finish];return;}
    self.panel=UIColorPanel.sharedColorPanel;self.controller=[self.panel valueForKey:@"pickerController"];
    if(self.panel.isVisible||self.panel.isTransitioning){[self record:@"shared panel precondition" passed:NO details:@{@"reason":@"The shared panel must start closed; the fixture does not take over an existing interaction."}];self.panel=nil;self.controller=nil;[self finish];return;}
    NSMutableArray<UIView *> *wellViews=[UIApplication.sharedApplication.windows mutableCopy];while(wellViews.count){UIView *view=wellViews.lastObject;[wellViews removeLastObject];if([view isKindOfClass:UIColorPanelWell.class]&&((UIColorPanelWell *)view).isActive){[self record:@"active well precondition" passed:NO details:@{@"reason":@"An attached user color well is already active. The fixture leaves its session untouched instead of replacing it."}];self.panel=nil;self.controller=nil;[self finish];return;}[wellViews addObjectsFromArray:view.subviews];}
    UIColorPickerSwatchesView *swatches=[self.controller valueForKey:@"swatchesView"];
    self.originalTarget=self.panel.target;self.originalAction=self.panel.action;
    self.original=@{@"color":self.panel.colorValue,@"mode":@(self.panel.mode),@"ignoresAlpha":@(UIColor.ignoresAlpha),@"continuous":@(self.panel.isContinuous),@"useSPI":@(self.panel.use_spi),@"allowsSampling":@(self.panel.allowsApplicationSampling),@"image":self.panel.samplingImage?:NSNull.null,@"source":self.panel.samplingSourceView?:NSNull.null,@"accessory":self.panel.accessoryView?:NSNull.null,@"key":swatches.persistenceKey?:NSNull.null,@"favoritesStore":swatches.favoritesStore?:NSNull.null,@"paletteImage":[self.controller valueForKey:@"paletteImage"]?:NSNull.null};
    self.originalTraits=[(UINavigationController *)self.panel.window.rootViewController overrideTraitCollectionForChildViewController:self.controller];
    self.panel.target=nil;self.panel.action=NULL;self.panel.use_spi=NO;self.panel.allowsApplicationSampling=NO;self.panel.samplingImage=nil;self.panel.samplingSourceView=nil;self.panel.accessoryView=nil;self.panel.continuous=YES;self.panel.showsAlpha=YES;swatches.persistenceKey=nil;swatches.favoritesStore=nil;
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);CGFloat components[]={.9,.16,.12,.65};CGColorRef color=CGColorCreate(space,components);self.initial=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);CGColorSpaceRelease(space);
    self.panel.colorValue=self.initial;self.panel.mode=UIColorPanelModeRGB;self.panel.target=self;self.panel.action=@selector(recordPanelAction:);
    __weak typeof(self) weakSelf=self;self.notificationObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIColorPanelColorDidChangeNotification object:self.panel queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification){weakSelf.notifications++;}];
    self.closeObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIPanelWillCloseNotification object:self.panel queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification){weakSelf.closeNotifications++;}];
    [self.panel orderFront:self.anchor];[self scheduleStep:0 after:.04];
}
- (void)runStep:(NSUInteger)step {
    @try {
    UIColorPanel *panel=self.panel;UIColorPanelViewController *controller=self.controller;
    switch(step){
        case 0:{
            BOOL opening=panel.isVisible&&!panel.window.hidden&&panel.isTransitioning;
            [panel orderOut:nil];BOOL retiring=!panel.isVisible&&panel.isTransitioning&&self.host.isKeyWindow&&[panel.window hitTest:CGPointMake(20,20) withEvent:nil]==nil;
            [panel orderFront:self.anchor];[self record:@"R01 opening exit interrupted by reopening keeps the latest visibility target" passed:opening&&retiring&&panel.isVisible&&!panel.window.hidden details:@{@"openingTransition":@(opening),@"retiringTargetAndHitTest":@(retiring)}];[self scheduleStep:1 after:.35];break;
        }
        case 1:{
            BOOL settled=panel.isVisible&&!panel.window.hidden&&!panel.isTransitioning&&fabs(panel.window.layer.opacity-1)<1e-6&&[panel.colorValue isEqual:self.initial];
            [self record:@"R01 reopened shared window settles opaque without changing canonical alpha" passed:settled details:@{@"renderOpacity":@(panel.window.layer.opacity),@"canonicalAlpha":@(CGColorGetAlpha(panel.colorValue.CGColor)),@"transitioning":@(panel.isTransitioning)}];
            self.editingField=[controller valueForKey:@"opacityField"];self.acceptedResponder=[self.editingField becomeFirstResponder];[self scheduleStep:2 after:.2];break;
        }
        case 2:{
            BOOL key=self.acceptedResponder&&self.editingField.isFirstResponder&&self.editingField.window==panel.window&&panel.window.isKeyWindow;
            self.beforeEdit=panel.colorValue;[panel close];[panel close];BOOL immediate=!panel.isVisible&&self.host.isKeyWindow&&[panel.window hitTest:CGPointMake(20,20) withEvent:nil]==nil;
            [self record:@"R01 close immediately releases owned key and hit testing; repeated close is safe" passed:key&&immediate details:@{@"realAttachedFirstResponder":@(key),@"immediateHiddenTarget":@(immediate)}];[self scheduleStep:3 after:.35];break;
        }
        case 3:{
            BOOL hidden=panel.window.hidden&&!panel.isVisible&&!panel.isTransitioning&&self.host.isKeyWindow&&fabs(panel.window.layer.opacity-1)<1e-6&&[panel.colorValue isEqual:self.beforeEdit];
            [self record:@"R01 completed close hides the window and restores its rendering state" passed:hidden details:@{@"hidden":@(panel.window.hidden),@"renderOpacity":@(panel.window.layer.opacity)}];[panel orderFront:self.anchor];[self scheduleStep:4 after:.35];break;
        }
        case 4:[[controller valueForKey:@"savedColorsButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:5 after:.55];break;
        case 5:{
            UIViewController *shown=[self presentedController];self.modalWasShown=[shown isKindOfClass:UINavigationController.class]&&[((UINavigationController *)shown).topViewController isKindOfClass:UIColorPanelSavedColorsController.class];[panel close];[self scheduleStep:6 after:.4];break;
        }
        case 6:{
            UIColorPickerSwatchesView *swatches=[controller valueForKey:@"swatchesView"];BOOL restored=self.modalWasShown&&![self presentedController]&&swatches.superview==[controller valueForKey:@"savedColorsButton"]&&!swatches.userInteractionEnabled&&swatches.accessibilityElementsHidden;
            [self record:@"R03 closing saved colors dismisses only the owned page and restores the shared preview" passed:restored details:@{@"managerWasPresented":@(self.modalWasShown),@"previewRestored":@(restored)}];[panel orderFront:self.anchor];[self scheduleStep:7 after:.35];break;
        }
        case 7:[controller chooseSliderModel:[controller valueForKey:@"modelMenuButton"]];[self scheduleStep:8 after:.55];break;
        case 8:{UIViewController *shown=[self presentedController];self.modalWasShown=[shown isKindOfClass:UINavigationController.class]&&[((UINavigationController *)shown).topViewController isKindOfClass:UIColorPanelChoiceController.class];[panel close];[self scheduleStep:9 after:.4];break;}
        case 9:[self record:@"R03 closing a real choice page leaves no stale presentation" passed:self.modalWasShown&&![self presentedController]&&panel.window.hidden details:@{@"choiceWasPresented":@(self.modalWasShown)}];[panel orderFront:self.anchor];[self scheduleStep:10 after:.35];break;
        case 10:[controller showError:@"Review fixture error"];[self scheduleStep:11 after:.4];break;
        case 11:self.modalWasShown=[[self presentedController]isKindOfClass:UIAlertController.class];[panel close];[self scheduleStep:12 after:.4];break;
        case 12:[self record:@"R03 closing an owned alert permits a clean shared-panel reopen" passed:self.modalWasShown&&![self presentedController]&&panel.window.hidden&&self.host.isKeyWindow details:@{@"alertWasPresented":@(self.modalWasShown)}];[panel orderFront:self.anchor];[self scheduleStep:13 after:.35];break;
        case 13:{
            self.editingField=[[controller valueForKey:@"componentFields"]firstObject];self.acceptedResponder=[self.editingField becomeFirstResponder];self.editingField.text=@"1e";[self.editingField sendActionsForControlEvents:UIControlEventEditingChanged];
            UITextPosition *end=[self.editingField positionFromPosition:self.editingField.beginningOfDocument offset:1];self.editingField.selectedTextRange=[self.editingField textRangeFromPosition:self.editingField.beginningOfDocument toPosition:end];self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[self scheduleStep:14 after:.15];break;
        }
        case 14:{
            NSMutableArray *traits=[NSMutableArray arrayWithObjects:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge],[UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassCompact],nil];if(@available(iOS 13.0,*))[traits addObject:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
            [(UINavigationController *)panel.window.rootViewController setOverrideTraitCollection:[UITraitCollection traitCollectionWithTraitsFromCollections:traits] forChildViewController:controller];[controller.view setNeedsLayout];[controller.view layoutIfNeeded];[self scheduleStep:15 after:.15];break;
        }
        case 15:{
            UITextField *current=[[controller valueForKey:@"componentFields"]firstObject];UITextRange *selection=current.selectedTextRange;NSInteger start=selection?[current offsetFromPosition:current.beginningOfDocument toPosition:selection.start]:-1,end=selection?[current offsetFromPosition:current.beginningOfDocument toPosition:selection.end]:-1;
            BOOL intact=self.acceptedResponder&&current==self.editingField&&current.window==panel.window&&current.isFirstResponder&&[current.text isEqualToString:@"1e"]&&start==0&&end==1&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications&&![self presentedController]&&[current.traitCollection.preferredContentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];
            [self record:@"R05 attached first responder retains its instance draft selection and color across real scoped traits" passed:intact details:@{@"sameField":@(current==self.editingField),@"firstResponder":@(current.isFirstResponder),@"draft":current.text?:@"",@"selection":@[@(start),@(end)],@"actualCategory":current.traitCollection.preferredContentSizeCategory?:@""}];
            [controller endTransientInteractionsForClose:NO];[(UINavigationController *)panel.window.rootViewController setOverrideTraitCollection:self.originalTraits forChildViewController:controller];[self scheduleStep:16 after:.2];break;
        }
        case 16:{
            UITextField *field=[controller valueForKey:@"opacityField"];self.acceptedResponder=[field becomeFirstResponder];field.text=@"65%";[field sendActionsForControlEvents:UIControlEventEditingChanged];self.beforeActions=self.actionColors.count;
            UIGradientSlider *slider=[controller valueForKey:@"opacitySlider"];[slider sendActionsForControlEvents:UIControlEventEditingDidBegin];slider.value=.2;[slider sendActionsForControlEvents:UIControlEventValueChanged];[slider sendActionsForControlEvents:UIControlEventEditingDidEnd];[controller.view endEditing:YES];[self scheduleStep:17 after:.2];break;
        }
        case 17:{
            UITextField *field=[controller valueForKey:@"opacityField"];UIGradientSlider *slider=[controller valueForKey:@"opacitySlider"];NSNumberFormatter *format=[NSNumberFormatter new];format.numberStyle=NSNumberFormatterPercentStyle;format.usesSignificantDigits=YES;format.minimumSignificantDigits=1;format.maximumSignificantDigits=6;format.usesGroupingSeparator=NO;
            BOOL noStale=self.acceptedResponder&&fabs(CGColorGetAlpha(panel.colorValue.CGColor)-.2)<1e-6&&fabs(slider.value-.2)<1e-6&&[field.text isEqualToString:[format stringFromNumber:@.2]]&&self.actionColors.count>self.beforeActions;
            for(NSUInteger i=self.beforeActions;i<self.actionColors.count;i++)noStale=noStale&&fabs(CGColorGetAlpha(self.actionColors[i].CGColor)-.2)<1e-6;
            [self record:@"R06 slider takes over an attached opacity draft without committing stale 65 percent" passed:noStale details:@{@"canonicalAlpha":@(CGColorGetAlpha(panel.colorValue.CGColor)),@"field":field.text?:@"",@"actions":@(self.actionColors.count-self.beforeActions)}];self.invalidIndex=0;[self scheduleStep:18 after:0];break;
        }
        case 18:{
            panel.mode=UIColorPanelModeRGB;panel.colorValue=self.initial;[controller.view setNeedsLayout];[controller.view layoutIfNeeded];NSArray *fields=@[[[controller valueForKey:@"componentFields"]firstObject],[controller valueForKey:@"hexField"],[controller valueForKey:@"opacityField"]];self.editingField=fields[self.invalidIndex];self.acceptedResponder=[self.editingField becomeFirstResponder];self.editingField.text=@[@"12tail",@"ZZZZZZ",@"101%"][self.invalidIndex];[self.editingField sendActionsForControlEvents:UIControlEventEditingChanged];self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[controller done:nil];[self scheduleStep:19 after:.45];break;
        }
        case 19:{
            UIViewController *modal=[self presentedController];NSUInteger alertCount=0;for(UIViewController *cursor=modal;cursor;cursor=cursor.presentedViewController)if([cursor isKindOfClass:UIAlertController.class])alertCount++;
            BOOL blocked=self.acceptedResponder&&panel.isVisible&&!panel.window.hidden&&[modal isKindOfClass:UIAlertController.class]&&alertCount==1&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications;
            [self record:[NSString stringWithFormat:@"R07 invalid %@ Done keeps the panel and canonical value with one alert",@[@"RGB",@"Hex",@"Opacity"][self.invalidIndex]] passed:blocked details:@{@"alertCount":@(alertCount),@"panelVisible":@(panel.isVisible),@"draft":self.editingField.text?:@""}];
            if(modal)[modal dismissViewControllerAnimated:NO completion:^{[self scheduleStep:20 after:.05];}];else[self scheduleStep:20 after:.05];break;
        }
        case 20:{
            [self.editingField becomeFirstResponder];self.editingField.text=@[@"128",@"FF8800",@"25%"][self.invalidIndex];[self.editingField sendActionsForControlEvents:UIControlEventEditingChanged];self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[controller done:nil];[self scheduleStep:21 after:.4];break;
        }
        case 21:{
            const CGFloat *components=CGColorGetComponents(panel.colorValue.CGColor);BOOL expected=self.invalidIndex==0?fabs(components[0]-128/255.)<1e-6:self.invalidIndex==1?(fabs(components[0]-1)<1e-6&&fabs(components[1]-136/255.)<1e-6&&fabs(components[2])<1e-6):fabs(CGColorGetAlpha(panel.colorValue.CGColor)-.25)<1e-6;
            BOOL corrected=expected&&panel.window.hidden&&!panel.isVisible&&!panel.isTransitioning&&self.actionColors.count==self.beforeActions+1&&self.notifications==self.beforeNotifications+1&&![self presentedController];
            [self record:[NSString stringWithFormat:@"R07 corrected %@ submits once before finishing",@[@"RGB",@"Hex",@"Opacity"][self.invalidIndex]] passed:corrected details:@{@"expectedColor":@(expected),@"actions":@(self.actionColors.count-self.beforeActions),@"notifications":@(self.notifications-self.beforeNotifications)}];
            if(++self.invalidIndex<3){[panel orderFront:self.anchor];[self scheduleStep:18 after:.35];}else[self scheduleStep:22 after:0];break;
        }
        case 22:[self checkLayoutFixtures];[panel orderFront:self.anchor];[self scheduleStep:23 after:.35];break;
        case 23:{
            [self checkSliderAccessibility];panel.mode=UIColorPanelModeRGB;panel.colorValue=self.initial;[controller.view layoutIfNeeded];self.editingField=[controller valueForKey:@"opacityField"];self.acceptedResponder=[self.editingField becomeFirstResponder];self.editingField.text=@"35%";[self.editingField sendActionsForControlEvents:UIControlEventEditingChanged];self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;self.beforeCloses=self.closeNotifications;self.reenterDone=YES;[controller done:nil];[self scheduleStep:24 after:.4];break;
        }
        case 24:{
            BOOL once=self.acceptedResponder&&!self.reenterDone&&panel.window.hidden&&fabs(CGColorGetAlpha(panel.colorValue.CGColor)-.35)<1e-12&&self.actionColors.count==self.beforeActions+1&&self.notifications==self.beforeNotifications+1&&self.closeNotifications==self.beforeCloses+1;
            [self record:@"R07 target-action reentrant Done cannot finish or close the same commit twice" passed:once details:@{@"actions":@(self.actionColors.count-self.beforeActions),@"notifications":@(self.notifications-self.beforeNotifications),@"closes":@(self.closeNotifications-self.beforeCloses)}];
            panel.use_spi=NO;panel.allowsApplicationSampling=YES;UIGraphicsBeginImageContextWithOptions(CGSizeMake(8,8),YES,1);[UIColor.greenColor setFill];UIRectFill(CGRectMake(0,0,8,8));self.fixtureImage=UIGraphicsGetImageFromCurrentImageContext();panel.samplingImage=self.fixtureImage;UIGraphicsEndImageContext();panel.mode=UIColorPanelModeColorList;[panel orderFront:self.anchor];[self scheduleStep:40 after:.35];break;
        }
        case 25:[[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:26 after:.55];break;
        case 26:{
            UIViewController *shown=[self presentedController];self.modalWasShown=[shown isKindOfClass:UIEyedropperViewController.class]&&shown.modalPresentationStyle==UIModalPresentationFullScreen&&shown.view.window==panel.window;
            UIEyedropperViewController *picker=[shown isKindOfClass:UIEyedropperViewController.class]?(id)shown:nil;[picker moveToPoint:CGPointMake(CGRectGetMidX(picker.view.bounds),CGRectGetMidY(picker.view.bounds))];self.expectedSample=picker.selectedColor;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[picker commit];[self scheduleStep:27 after:.55];break;
        }
        case 27:{
            BOOL committed=self.modalWasShown&&self.expectedSample&&[panel.colorValue isEqual:self.expectedSample]&&self.actionColors.count==self.beforeActions+1&&self.notifications==self.beforeNotifications+1&&![self presentedController]&&![controller valueForKey:@"activeSamplingController"]&&fabs(panel.window.layer.opacity-1)<1e-6;
            [self record:@"R04 normal fullscreen sampling remains valid while covering its presenter and commits once" passed:committed details:@{@"fullscreenWasPresented":@(self.modalWasShown),@"actions":@(self.actionColors.count-self.beforeActions),@"notifications":@(self.notifications-self.beforeNotifications),@"renderOpacity":@(panel.window.layer.opacity),@"source":@"Explicit uniform application image; same production session/presentation/completion route as private capture."}];
            panel.allowsApplicationSampling=NO;panel.samplingImage=nil;
            if(![UIEyedropperViewController supportsSystemCapture]){[self record:@"R04 private capture target and delayed-generation reentry" passed:YES details:@{@"skipped":@YES,@"reason":@"This build/runtime does not expose optional system capture. Public image completion above remains mandatory."}];[panel close];[self scheduleStep:35 after:.35];break;}
            panel.use_spi=YES;[controller.view setNeedsLayout];[controller.view layoutIfNeeded];self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];panel.target=nil;[self scheduleStep:28 after:.18];break;
        }
        case 28:{
            UIButton *button=[controller valueForKey:@"sampleButton"];self.targetCaptureBlocked=![self presentedController]&&![controller valueForKey:@"activeSamplingController"]&&![[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&button.enabled&&fabs(panel.window.layer.opacity-1)<1e-6&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions;
            [controller endTransientInteractionsForClose:NO];panel.target=self;panel.action=@selector(recordPanelAction:);[[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:29 after:.04];break;
        }
        case 29:{
            // Close/reopen without the visibility animation only in this fixture:
            // request B must start before request A's original100ms callback.
            [UIView performWithoutAnimation:^{[panel close];[panel orderFront:self.anchor];}];[[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];self.expectedCaptureGeneration=[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue];[self scheduleStep:30 after:.075];break;
        }
        case 30:{
            UIButton *button=[controller valueForKey:@"sampleButton"];self.oldCaptureIgnored=![self presentedController]&&![controller valueForKey:@"activeSamplingController"]&&[[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue]==self.expectedCaptureGeneration&&[[controller valueForKey:@"samplingSurfaceGeneration"]unsignedIntegerValue]==self.expectedCaptureGeneration&&!button.enabled&&fabs(panel.window.layer.opacity)<1e-6;[self scheduleStep:31 after:.55];break;
        }
        case 31:{
            UIViewController *shown=[self presentedController];self.modalWasShown=[shown isKindOfClass:UIEyedropperViewController.class]&&[[(UIEyedropperViewController *)shown sourceKind]isEqualToString:@"Screen Snapshot"]&&shown.view.window==panel.window&&[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue]==self.expectedCaptureGeneration;
            if([shown isKindOfClass:UIEyedropperViewController.class])[(UIEyedropperViewController *)shown cancel];else[controller endTransientInteractionsForClose:NO];[self scheduleStep:32 after:.55];break;
        }
        case 32:{
            UIButton *button=[controller valueForKey:@"sampleButton"];BOOL restored=![self presentedController]&&![controller valueForKey:@"activeSamplingController"]&&![[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&button.enabled&&fabs(panel.window.layer.opacity-1)<1e-6&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications;
            [self record:@"R04 private capture target and delayed-generation reentry" passed:self.targetCaptureBlocked&&self.oldCaptureIgnored&&self.modalWasShown&&restored details:@{@"targetChangeCancelledBeforePresentation":@(self.targetCaptureBlocked),@"oldCallbackLeftNewRequestPendingAndHidden":@(self.oldCaptureIgnored),@"newScreenSnapshotPresented":@(self.modalWasShown),@"cancelRestoredSurfaceWithoutCommit":@(restored),@"expectedGeneration":@(self.expectedCaptureGeneration),@"skipped":@NO}];[panel close];[self scheduleStep:35 after:.35];break;
        }
        case 35:[self scheduleStep:50 after:0];break;
        case 40:{
            UIColorPickerCatalogController *catalog=[controller valueForKey:@"catalogController"];UISearchBar *bar=[catalog valueForKey:@"searchBar"];
            self.searchState=@{@"list":catalog.currentColorList?:NSNull.null,@"text":bar.text?:@"",@"row":[catalog valueForKey:@"selectedRowIndex"]?:@(-1),@"key":[catalog valueForKey:@"selectedKey"]?:NSNull.null};
            UIColorList *temporary=[[UIColorList alloc]initWithName:@"Review search responder fixture"];[temporary setColor:UIColor.redColor forKey:@"Review Red"];[temporary setColor:UIColor.greenColor forKey:@"Review Green"];[catalog setValue:temporary forKey:@"currentColorList"];bar.text=@"";panel.colorValue=self.initial;[catalog setValue:@(-1) forKey:@"selectedRowIndex"];[catalog reloadCatalog];[controller.view setNeedsLayout];[controller.view layoutIfNeeded];
            self.acceptedResponder=[bar becomeFirstResponder];NSMutableArray *pending=[NSMutableArray arrayWithObject:bar];while(pending.count){UIView *candidate=pending.lastObject;[pending removeLastObject];if(candidate.isFirstResponder&&[candidate isKindOfClass:UITextField.class]){self.searchResponder=candidate;break;}[pending addObjectsFromArray:candidate.subviews];}
            self.searchFont=[self.searchResponder isKindOfClass:UITextField.class]?((UITextField *)self.searchResponder).font:nil;self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[self scheduleStep:41 after:.15];break;
        }
        case 41:{
            UIColorPickerCatalogController *catalog=[controller valueForKey:@"catalogController"];UISearchBar *bar=[catalog valueForKey:@"searchBar"];bar.text=@"Review";[bar.delegate searchBar:bar textDidChange:bar.text];
            BOOL matched=[[catalog valueForKey:@"selectedRowIndex"]integerValue]>=0&&![panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions+1&&self.notifications==self.beforeNotifications+1;
            BOOL retained=self.acceptedResponder&&self.searchResponder.window==panel.window&&self.searchResponder.isFirstResponder&&[bar.text isEqualToString:@"Review"]&&self.searchFont&&[self.searchFont isEqual:((UITextField *)self.searchResponder).font]&&![self presentedController];
            [self record:@"R05 catalog matching keeps the actual native search responder text and font" passed:matched&&retained details:@{@"matchingNotifiedThroughProductionDelegate":@(matched),@"nativeFirstResponderRetained":@(retained),@"selectedRow":[catalog valueForKey:@"selectedRowIndex"]?:@(-1),@"actions":@(self.actionColors.count-self.beforeActions),@"scope":@"Temporary unsaved two-color current list and initial row -1 establish a real matching callback; original matcher and delegate chain are unchanged. Native UISearchBar focus is real; textDidChange is invoked programmatically."}];[self restoreSearchFixture];[self scheduleStep:25 after:.15];break;
        }
        case 50:{
            panel.use_spi=NO;panel.allowsApplicationSampling=NO;panel.samplingImage=nil;panel.mode=UIColorPanelModeRGB;
            self.fixtureWell=[[UIColorPanelWell alloc]initWithFrame:CGRectMake(0,0,44,44)];self.fixtureWell.orderColorPanelOnActivate=NO;self.fixtureWell.colorValue=panel.colorValue;[self.anchor.view addSubview:self.fixtureWell];[self.fixtureWell activate:NO];
            [panel orderFront:self.anchor];[self scheduleStep:51 after:.35];break;
        }
        case 51:[[controller valueForKey:@"savedColorsButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:52 after:.45];break;
        case 52:{
            UIViewController *shown=[self presentedController];self.modalWasShown=[shown isKindOfClass:UINavigationController.class]&&[((UINavigationController *)shown).topViewController isKindOfClass:UIColorPanelSavedColorsController.class]&&self.fixtureWell.isActive;
            self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;self.beforeCloses=self.closeNotifications;[panel orderOut:nil];[self scheduleStep:53 after:.35];break;
        }
        case 53:{
            UIColorPickerSwatchesView *swatches=[controller valueForKey:@"swatchesView"];
            self.targetCaptureBlocked=self.modalWasShown&&panel.window.hidden&&!panel.visible&&self.fixtureWell.isActive&&![self presentedController]&&swatches.superview==[controller valueForKey:@"savedColorsButton"]&&!swatches.userInteractionEnabled&&swatches.accessibilityElementsHidden&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications&&self.closeNotifications==self.beforeCloses&&panel.target==self&&panel.action==@selector(recordPanelAction:);
            [panel orderFront:self.anchor];[self scheduleStep:54 after:.35];break;
        }
        case 54:{
            UIColorPickerSwatchesView *swatches=[controller valueForKey:@"swatchesView"];BOOL reopened=panel.visible&&!panel.window.hidden&&!panel.transitioning&&self.fixtureWell.isActive&&![self presentedController]&&swatches.superview==[controller valueForKey:@"savedColorsButton"]&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications&&self.closeNotifications==self.beforeCloses;
            [self record:@"R03 owned saved colors orderOut reopens cleanly while preserving the active well" passed:self.targetCaptureBlocked&&reopened details:@{@"managerWasPresented":@(self.modalWasShown),@"hiddenAndPreviewRestored":@(self.targetCaptureBlocked),@"reopenedWithActiveWell":@(reopened),@"closeNotifications":@(self.closeNotifications-self.beforeCloses)}];
            [self.fixtureWell deactivate];[self.fixtureWell removeFromSuperview];self.fixtureWell=nil;[panel close];[self scheduleStep:55 after:.35];break;
        }
        case 55:{
            UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.savedColorsKey=nil;configuration.showsAlpha=YES;configuration.initialMode=UIColorPanelModeRGB;configuration.allowsApplicationSampling=YES;configuration.samplingImage=self.fixtureImage;
            self.customController=[[UIColorPanelViewController alloc]initWithColor:self.initial configuration:configuration];self.customController.delegate=self;self.customSelections=0;
            self.customNavigation=[[UINavigationController alloc]initWithRootViewController:self.customController];self.customNavigation.modalPresentationStyle=UIModalPresentationFormSheet;[self.anchor presentViewController:self.customNavigation animated:YES completion:nil];[self scheduleStep:56 after:.45];break;
        }
        case 56:{
            self.modalWasShown=self.customNavigation.presentingViewController!=nil&&self.customController.view.window==self.host;
            [[self.customController valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:57 after:.45];break;
        }
        case 57:{
            UIViewController *shown=self.customNavigation.presentedViewController?:self.customController.presentedViewController;
            self.customPicker=[shown isKindOfClass:UIEyedropperViewController.class]?(id)shown:nil;
            self.modalWasShown=self.modalWasShown&&self.customPicker&&self.customPicker.view.window==self.host&&[(id<UIColorPanelTransientOwner>)self.customController isTransientPresentationCurrent:self.customPicker]&&[self.customController valueForKey:@"activeSamplingController"]==self.customPicker;
            self.customSamplingGeneration=[[self.customController valueForKey:@"samplingGeneration"]unsignedIntegerValue];self.beforeEdit=self.customController.selectedColor;
            // Dismiss the actual outer Custom controller from its real host.
            // No lifecycle method is invoked directly by this fixture.
            [self.anchor dismissViewControllerAnimated:YES completion:nil];[self scheduleStep:58 after:.45];break;
        }
        case 58:{
            NSHashTable *owned=[self.customController valueForKey:@"transientPresentations"];
            BOOL released=self.modalWasShown&&!self.anchor.presentedViewController&&!self.customNavigation.presentingViewController&&!self.customController.viewIfLoaded.window&&![self.customController valueForKey:@"activeSamplingController"]&&![self.customController valueForKey:@"samplingIdentityValid"]&&![[self.customController valueForKey:@"ownsSamplingSurface"]boolValue]&&owned.count==0&&[[self.customController valueForKey:@"samplingGeneration"]unsignedIntegerValue]>self.customSamplingGeneration&&!self.customPicker.completionHandler&&[self.customController.selectedColor isEqual:self.beforeEdit]&&self.customSelections==0&&self.host.isKeyWindow;
            [self record:@"R03 real host dismissal of Custom releases its fullscreen owned sampling session" passed:released details:@{
                @"customAndPickerWerePresented":@(self.modalWasShown),@"sessionReleased":@(released),@"remainingOwnedPages":@(owned.count),@"selectionCallbacks":@(self.customSelections),
                @"anchorPresentedClass":NSStringFromClass(self.anchor.presentedViewController.class)?:@"nil",@"hostRootPresentedClass":NSStringFromClass(self.host.rootViewController.presentedViewController.class)?:@"nil",@"anchorStillPresentsCustom":@(self.anchor.presentedViewController==self.customNavigation),
                @"customNavigationHasPresenter":@(self.customNavigation.presentingViewController!=nil),@"customNavigationIsBeingDismissed":@(self.customNavigation.isBeingDismissed),@"customControllerIsBeingDismissed":@(self.customController.isBeingDismissed),@"customViewHasWindow":@(self.customController.viewIfLoaded.window!=nil),
                @"activeSamplingClass":NSStringFromClass([[self.customController valueForKey:@"activeSamplingController"]class])?:@"nil",@"samplingIdentityPresent":@([self.customController valueForKey:@"samplingIdentityValid"]!=nil),@"ownsSamplingSurface":[self.customController valueForKey:@"ownsSamplingSurface"]?:@NO,@"samplingGeneration":[self.customController valueForKey:@"samplingGeneration"]?:@0,@"samplingGenerationBeforeDismiss":@(self.customSamplingGeneration),
                @"pickerHasPresenter":@(self.customPicker.presentingViewController!=nil),@"pickerIsBeingDismissed":@(self.customPicker.isBeingDismissed),@"pickerViewHasWindow":@(self.customPicker.viewIfLoaded.window!=nil),@"pickerFinished":[self.customPicker valueForKey:@"finished"]?:@NO,@"pickerCompletionPresent":@(self.customPicker.completionHandler!=nil),
                @"scope":@"Actual host present/dismiss and UIKit lifecycle of the outer form sheet plus fullscreen public-image picker; no synthetic viewDidDisappear call."}];
            [self removeCustomFixture];self.fileRoute=0;[self scheduleStep:59 after:.1];break;
        }
        case 59:{
            self.fixtureFileURL=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"UIColorPanel-review-%@.png",NSUUID.UUID.UUIDString]]];
            if(![UIImagePNGRepresentation(self.fixtureImage) writeToURL:self.fixtureFileURL options:NSDataWritingAtomic error:nil])[self record:@"Files fixture owned image precondition" passed:NO details:@{@"reason":@"Could not create the tiny temporary image used for a controlled late delegate callback."}];
            [panel orderFront:self.anchor];[self scheduleStep:60 after:.35];break;
        }
        case 60:{
            self.filePaletteImage=[controller valueForKey:@"paletteImage"];
            if(self.fileRoute==0)[controller importImage:nil];
            else {
                if(self.fileRoute==1)self.fileProvider=[[UIReviewCatalogImportSpy alloc]initWithColorLists:@[] selectedColor:panel.colorValue];
                else self.fileProvider=[[UIReviewImageImportSpy alloc]initWithSpectrum:self.fixtureImage];
                [controller addChildViewController:self.fileProvider];UIView *host=[controller valueForKey:@"providerHost"];self.fileProvider.view.frame=host.bounds;[host addSubview:self.fileProvider.view];[self.fileProvider didMoveToParentViewController:controller];
                if(self.fileRoute==1)[(UIReviewCatalogImportSpy *)self.fileProvider openList:nil];else[(UIReviewImageImportSpy *)self.fileProvider importImage:nil];
            }
            [self scheduleStep:61 after:.45];break;
        }
        case 61:{
            UIViewController *shown=[self presentedController];self.filePicker=[shown isKindOfClass:UIDocumentPickerViewController.class]?(id)shown:nil;
            id expectedDelegate=self.fileRoute==0?controller:self.fileProvider;
            self.modalWasShown=self.filePicker&&self.filePicker.view.window==panel.window&&self.filePicker.delegate==expectedDelegate&&[(id<UIColorPanelTransientOwner>)controller isTransientPresentationCurrent:self.filePicker];
            self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;[panel close];[self scheduleStep:62 after:.35];break;
        }
        case 62:{
            // UIKit's real picker and production owner registration were used.
            // Only its delayed delegate delivery is controlled by the fixture.
            id<UIDocumentPickerDelegate> delegate=self.fileRoute==0?(id)controller:(id)self.fileProvider;
            if(self.filePicker&&self.fixtureFileURL)[delegate documentPicker:self.filePicker didPickDocumentsAtURLs:@[self.fixtureFileURL]];
            [self scheduleStep:63 after:.2];break;
        }
        case 63:{
            NSUInteger imports=self.fileRoute==0?0:[[self.fileProvider valueForKey:@"importCalls"]unsignedIntegerValue];
            BOOL ignored=self.modalWasShown&&self.fixtureFileURL&&[NSFileManager.defaultManager fileExistsAtPath:self.fixtureFileURL.path]&&panel.window.hidden&&!panel.visible&&![self presentedController]&&!self.filePicker.presentingViewController&&![(id<UIColorPanelTransientOwner>)controller isTransientPresentationCurrent:self.filePicker]&&imports==0&&[controller valueForKey:@"paletteImage"]==self.filePaletteImage&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications;
            NSString *route=@[@"root image import",@"catalog provider",@"image-palette provider"][self.fileRoute];
            [self record:[NSString stringWithFormat:@"R03 closed %@ rejects a late Files delegate",route] passed:ignored details:@{@"realPickerWasOwned":@(self.modalWasShown),@"lateImportCalls":@(imports),@"canonicalAndNotificationsUnchanged":@([panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications),@"scope":self.fileRoute==0?@"Real UIDocumentPicker presentation, registration and close, then controlled production delegate delivery with an owned temporary PNG; root palette image and canonical state must remain unchanged. No physical Files selection.":@"Real child-provider UIDocumentPicker presentation, registration and close, then controlled production delegate delivery. A test-only final importer counts calls instead of writing any palette. No physical Files selection."}];
            [self removeFileProviderFixture];self.filePaletteImage=nil;
            if(++self.fileRoute<3){[panel orderFront:self.anchor];[self scheduleStep:60 after:.35];}
            else {[NSFileManager.defaultManager removeItemAtURL:self.fixtureFileURL error:nil];self.fixtureFileURL=nil;self.leaveRoute=0;panel.use_spi=NO;panel.allowsApplicationSampling=YES;panel.samplingImage=self.fixtureImage;panel.mode=UIColorPanelModeRGB;[panel orderFront:self.anchor];[self scheduleStep:71 after:.35];}break;
        }
        case 71:{
            [controller endTransientInteractionsForClose:NO];panel.mode=UIColorPanelModeRGB;panel.colorValue=self.initial;[controller.view setNeedsLayout];[controller.view layoutIfNeeded];
            self.editingField=[[controller valueForKey:@"componentFields"]firstObject];self.acceptedResponder=[self.editingField becomeFirstResponder];self.editingField.text=@"12tail";[self.editingField sendActionsForControlEvents:UIControlEventEditingChanged];self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;self.leavePreparationRejected=NO;
            if(self.leaveRoute==0){UISegmentedControl *segments=[controller valueForKey:@"modeControl"];NSArray *modes=[controller valueForKey:@"modeSegmentModes"];NSUInteger wheel=[modes indexOfObject:@(UIColorPanelModeWheel)];if(wheel!=NSNotFound){segments.selectedSegmentIndex=wheel;[segments sendActionsForControlEvents:UIControlEventValueChanged];}}
            else if(self.leaveRoute==1)[controller chooseSliderModel:[controller valueForKey:@"modelMenuButton"]];
            else if(self.leaveRoute==2)self.leavePreparationRejected=![(id<UIColorPanelTransientOwner>)controller prepareForTransientPresentation];
            else [[controller valueForKey:self.leaveRoute==3?@"savedColorsButton":@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];
            [self scheduleStep:72 after:.4];break;
        }
        case 72:{
            UIViewController *shown=[self presentedController];NSUInteger alerts=0;for(UIViewController *cursor=shown;cursor;cursor=cursor.presentedViewController)if([cursor isKindOfClass:UIAlertController.class])alerts++;
            BOOL blocked=self.acceptedResponder&&panel.visible&&!panel.window.hidden&&panel.mode==UIColorPanelModeRGB&&[shown isKindOfClass:UIAlertController.class]&&alerts==1&&[controller valueForKey:@"inputErrorAlert"]==shown&&[self.editingField.text isEqualToString:@"12tail"]&&[[controller valueForKey:@"editedFields"]containsObject:self.editingField]&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications&&![controller valueForKey:@"activeSamplingController"]&&![[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&![controller valueForKey:@"savedColorsController"];
            if(self.leaveRoute==2)blocked=blocked&&self.leavePreparationRejected;
            if(self.leaveRoute==0){NSArray *modes=[controller valueForKey:@"modeSegmentModes"];UISegmentedControl *segments=[controller valueForKey:@"modeControl"];blocked=blocked&&segments.selectedSegmentIndex>=0&&segments.selectedSegmentIndex<(NSInteger)modes.count&&[modes[segments.selectedSegmentIndex]integerValue]==UIColorPanelModeRGB;}
            NSString *route=@[@"mode segment",@"choice presentation",@"menu preparation",@"saved colors",@"sampling"][self.leaveRoute];
            [self record:[NSString stringWithFormat:@"R07 invalid draft blocks %@ without changing canonical color",route] passed:blocked details:@{@"alertCount":@(alerts),@"draft":self.editingField.text?:@"",@"actions":@(self.actionColors.count-self.beforeActions),@"notifications":@(self.notifications-self.beforeNotifications),@"scope":@"Real attached dirty field and production leaving entry point; one owned input alert. Cleanup cancels the fixture draft. This does not invoke an UIAlertAction handler or claim native OK/focus recovery."}];
            [controller endTransientInteractionsForClose:NO];[self scheduleStep:73 after:.1];break;
        }
        case 73:{
            if(++self.leaveRoute<5){[self scheduleStep:71 after:0];break;}
            panel.allowsApplicationSampling=NO;panel.samplingImage=nil;
            if(![UIEyedropperViewController supportsSystemCapture]){
                for(NSString *name in @[@"R04 controlled application deactivation invalidates a pending private capture",@"R04 competing owned alert prevents a late private capture presentation"])[self record:name passed:YES details:@{@"skipped":@YES,@"reason":@"This build/runtime does not expose optional system capture."}];
                [panel close];[self scheduleStep:84 after:.35];break;
            }
            panel.use_spi=YES;[controller.view setNeedsLayout];[controller.view layoutIfNeeded];[self scheduleStep:80 after:0];break;
        }
        case 80:{
            self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;
            [[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];self.pendingStarted=[[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&!((UIButton *)[controller valueForKey:@"sampleButton"]).enabled&&fabs(panel.window.layer.opacity)<1e-6;self.expectedCaptureGeneration=[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue];
            [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillResignActiveNotification object:UIApplication.sharedApplication];[self scheduleStep:81 after:.2];break;
        }
        case 81:{
            UIButton *button=[controller valueForKey:@"sampleButton"];BOOL ignored=self.pendingStarted&&![self presentedController]&&![controller valueForKey:@"activeSamplingController"]&&![controller valueForKey:@"samplingIdentityValid"]&&![[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&button.enabled&&fabs(panel.window.layer.opacity-1)<1e-6&&[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue]>self.expectedCaptureGeneration&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications;
            [self record:@"R04 controlled application deactivation invalidates a pending private capture" passed:ignored details:@{@"captureWasPendingAndHidden":@(self.pendingStarted),@"restoredWithoutCommit":@(ignored),@"skipped":@NO,@"scope":@"Posts the real UIApplicationWillResignActiveNotification through NSNotificationCenter during the production100ms capture wait. This is a controlled notification, not an actual background or scene transition."}];[self scheduleStep:82 after:0];break;
        }
        case 82:{
            self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;
            [[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];self.pendingStarted=[[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&fabs(panel.window.layer.opacity)<1e-6;
            [controller showError:@"Review competing owned alert"];UIViewController *shown=[self presentedController];self.competingAlert=[shown isKindOfClass:UIAlertController.class]?(id)shown:nil;[self scheduleStep:83 after:.25];break;
        }
        case 83:{
            UIButton *button=[controller valueForKey:@"sampleButton"];BOOL ignored=self.pendingStarted&&self.competingAlert&&[self presentedController]==self.competingAlert&&[(id<UIColorPanelTransientOwner>)controller isTransientPresentationCurrent:self.competingAlert]&&![controller valueForKey:@"activeSamplingController"]&&![controller valueForKey:@"samplingIdentityValid"]&&![[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&button.enabled&&fabs(panel.window.layer.opacity-1)<1e-6&&[panel.colorValue isEqual:self.beforeEdit]&&self.actionColors.count==self.beforeActions&&self.notifications==self.beforeNotifications;
            [self record:@"R04 competing owned alert prevents a late private capture presentation" passed:ignored details:@{@"captureWasPendingAndHidden":@(self.pendingStarted),@"ownedAlertRemainedPresented":@([self presentedController]==self.competingAlert&&self.competingAlert!=nil),@"restoredWithoutCommit":@(ignored),@"skipped":@NO}];[controller endTransientInteractionsForClose:NO];self.competingAlert=nil;[panel close];[self scheduleStep:84 after:.35];break;
        }
        case 84:
            panel.use_spi=NO;panel.allowsApplicationSampling=YES;panel.samplingImage=self.fixtureImage;panel.mode=UIColorPanelModeRGB;panel.colorValue=self.initial;
            self.samplingReentryStarted=NO;self.samplingReentryPreserved=NO;self.samplingBCompletions=0;self.samplingBCancellations=0;self.samplingBReturnedColor=nil;
            [panel orderFront:self.anchor];[self scheduleStep:90 after:.35];break;
        case 90:
            self.beforeEdit=panel.colorValue;self.beforeActions=self.actionColors.count;self.beforeNotifications=self.notifications;
            [[controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:91 after:.55];break;
        case 91:{
            UIViewController *shown=[self presentedController];self.samplingPickerA=[shown isKindOfClass:UIEyedropperViewController.class]?(id)shown:nil;
            self.modalWasShown=self.samplingPickerA&&self.samplingPickerA.view.window==panel.window&&[controller valueForKey:@"activeSamplingController"]==self.samplingPickerA;
            self.samplingAGeneration=[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue];
            [self.samplingPickerA moveToPoint:CGPointMake(CGRectGetMidX(self.samplingPickerA.view.bounds),CGRectGetMidY(self.samplingPickerA.view.bounds))];self.expectedSample=self.samplingPickerA.selectedColor;
            self.reenterSampling=YES;[self.samplingPickerA commit];[self scheduleStep:92 after:.55];break;
        }
        case 92:{
            UIEyedropperViewController *picker=self.samplingPickerB;NSUInteger generation=[[controller valueForKey:@"samplingGeneration"]unsignedIntegerValue];
            BOOL (^identityValid)(void)=[controller valueForKey:@"samplingIdentityValid"];
            self.samplingReentryPreserved=self.modalWasShown&&self.samplingReentryStarted&&picker&&picker!=self.samplingPickerA&&[self presentedController]==picker&&picker.view.window==panel.window&&[controller valueForKey:@"activeSamplingController"]==picker&&generation==self.samplingBGeneration&&[(id<UIColorPanelTransientOwner>)controller isTransientPresentationCurrent:picker]&&identityValid&&identityValid()&&picker.completionHandler!=nil&&![[picker valueForKey:@"finished"]boolValue]&&self.samplingBCompletions==0&&[panel.colorValue isEqual:self.expectedSample]&&self.actionColors.count==self.beforeActions+1&&self.notifications==self.beforeNotifications+1;
            // B must still accept movement independently, with no color commit.
            [picker moveToPoint:CGPointMake(CGRectGetMidX(picker.view.bounds),CGRectGetMidY(picker.view.bounds))];self.samplingReentryPreserved=self.samplingReentryPreserved&&picker.selectedColor!=nil&&[panel.colorValue isEqual:self.expectedSample]&&self.samplingBCompletions==0;
            [picker cancel];[picker cancel];[picker commit];[self scheduleStep:93 after:.55];break;
        }
        case 93:{
            BOOL clean=![self presentedController]&&![controller valueForKey:@"activeSamplingController"]&&![controller valueForKey:@"samplingIdentityValid"]&&![[controller valueForKey:@"ownsSamplingSurface"]boolValue]&&!self.samplingPickerB.completionHandler&&((UIButton *)[controller valueForKey:@"sampleButton"]).enabled&&fabs(panel.window.layer.opacity-1)<1e-6;
            BOOL unchanged=[panel.colorValue isEqual:self.expectedSample]&&self.expectedSample&&![self.beforeEdit isEqual:self.expectedSample]&&self.actionColors.count==self.beforeActions+1&&self.notifications==self.beforeNotifications+1;
            BOOL passed=!self.reenterSampling&&self.samplingReentryPreserved&&self.samplingBCompletions==1&&self.samplingBCancellations==1&&!self.samplingBReturnedColor&&clean&&unchanged;
            [self record:@"R04 successful sampling target-action can synchronously open a new independent sampling session" passed:passed details:@{@"firstPickerWasPresented":@(self.modalWasShown),@"secondSessionStartedInsideTargetAction":@(self.samplingReentryStarted),@"secondSessionSurvivedOldCompletion":@(self.samplingReentryPreserved),@"firstGeneration":@(self.samplingAGeneration),@"secondGeneration":@(self.samplingBGeneration),@"secondCompletionCount":@(self.samplingBCompletions),@"secondCancelCompletionCount":@(self.samplingBCancellations),@"actions":@(self.actionColors.count-self.beforeActions),@"notifications":@(self.notifications-self.beforeNotifications),@"canonicalFirstColorPreserved":@(unchanged),@"sessionReleased":@(clean),@"scope":@"Two actual fullscreen public-image picker presentations. A commits through its production completion; its synchronous target-action invokes the sample button to create B. Only B's completion is wrapped to observe and forward unchanged. B movement/cancel is programmatic, not a physical gesture."}];
            self.reenterSampling=NO;self.samplingPickerA=nil;self.samplingPickerB=nil;[panel close];[self scheduleStep:94 after:.35];break;
        }
        case 94:[self finish];break;
        default:[self finish];break;
    }
    }@catch(NSException *exception){[self record:@"review fixture exception" passed:NO details:@{@"exception":exception.name?:@"",@"reason":exception.reason?:@"",@"step":@(step)}];[self finish];}
}
- (void)checkLayoutFixtures {
    NSMutableArray *checks=[NSMutableArray new];BOOL all=YES;
    for(NSString *language in @[@"nl",@"ru",@"ar"])for(NSNumber *width in @[@320,@375])for(NSNumber *height in @[@300,@460]){
        UIViewController *holder=[UIViewController new];UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeRGB;configuration.showsAlpha=YES;configuration.savedColorsKey=nil;UIColorPanelViewController *content=[[UIColorPanelViewController alloc]initWithColor:self.initial configuration:configuration];
        [self.anchor addChildViewController:holder];holder.view.frame=CGRectMake(0,0,width.doubleValue,height.doubleValue);[self.anchor.view addSubview:holder.view];[holder didMoveToParentViewController:self.anchor];[holder addChildViewController:content];[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge] forChildViewController:content];content.view.frame=holder.view.bounds;[holder.view addSubview:content.view];[content didMoveToParentViewController:holder];
        @try {
            NSString *path=[[UIColorPanelAppearance resourceBundle]pathForResource:language ofType:@"lproj"];NSBundle *bundle=path?[NSBundle bundleWithPath:path]:nil;NSString *labelText=[bundle localizedStringForKey:@"Opacity" value:@"Missing original text" table:@"UIColorPanelKit"];
            UILabel *label=((UIView *)[content valueForKey:@"opacityRow"]).subviews.firstObject;label.text=labelText;content.view.semanticContentAttribute=[language isEqualToString:@"ar"]?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;[content.view setNeedsLayout];[content.view layoutIfNeeded];
            CGSize needed=[label sizeThatFits:CGSizeMake(label.bounds.size.width,CGFLOAT_MAX)];BOOL fits=bundle!=nil&&label.window==self.host&&label.bounds.size.width>0&&label.bounds.size.height+.5>=ceil(needed.height)&&[label.traitCollection.preferredContentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];UIScrollView *overflow=[content valueForKey:@"overflowScroll"];BOOL reachable=YES;NSMutableArray *targets=[NSMutableArray new];
            for(UIView *control in @[[content valueForKey:@"modeControl"],((UITextField *)[content valueForKey:@"opacityField"]).superview,[content valueForKey:@"currentWell"],[content valueForKey:@"savedColorsButton"]]){
                [overflow scrollRectToVisible:[control convertRect:control.bounds toView:overflow] animated:NO];[overflow layoutIfNeeded];CGRect rect=[control convertRect:control.bounds toView:content.view];CGRect viewport=UIEdgeInsetsInsetRect(content.view.bounds,content.view.safeAreaInsets);CGPoint point=[control convertPoint:CGPointMake(CGRectGetMidX(control.bounds),CGRectGetMidY(control.bounds)) toView:self.host];UIView *hit=[self.host hitTest:point withEvent:nil];BOOL target=CGRectContainsRect(CGRectInset(viewport,-.5,-.5),rect)&&control.bounds.size.width>=44-.01&&control.bounds.size.height>=44-.01&&(hit==control||[hit isDescendantOfView:control]);reachable=reachable&&target;[targets addObject:@{@"class":NSStringFromClass(control.class),@"frame":NSStringFromCGRect(rect),@"hit":hit?NSStringFromClass(hit.class):@"nil",@"passed":@(target)}];
            }
            BOOL valid=fits&&reachable&&[content.selectedColor isEqual:self.initial];all=all&&valid;[checks addObject:@{@"language":language,@"text":labelText?:@"",@"size":@[@(width.doubleValue),@(height.doubleValue)],@"labelHeight":@(label.bounds.size.height),@"neededHeight":@(needed.height),@"fontSize":@(label.font.pointSize),@"overflowEnabled":@(overflow.scrollEnabled),@"targets":targets,@"passed":@(valid)}];
        }@finally{[holder setOverrideTraitCollection:nil forChildViewController:content];[content willMoveToParentViewController:nil];[content.view removeFromSuperview];[content removeFromParentViewController];[holder willMoveToParentViewController:nil];[holder.view removeFromSuperview];[holder removeFromParentViewController];}
    }
    [self record:@"R08 original long Opacity text fits AX layout and every shell target remains actually reachable in short hosts" passed:all details:@{@"fixtures":checks,@"scope":@"Real attached scoped AX XXXL; original nl/ru/ar text with explicit RTL; programmatic scroll and native view hit testing, not physical gestures or spoken VoiceOver."}];
}
- (void)checkSliderAccessibility {
    self.panel.mode=UIColorPanelModeWheel;NSNumberFormatter *percent=[NSNumberFormatter new];percent.numberStyle=NSNumberFormatterPercentStyle;percent.maximumFractionDigits=3;NSMutableArray *checks=[NSMutableArray new];BOOL all=YES;
    for(NSNumber *value in @[@0,@.5,@1]){
        self.panel.color=[UIColor colorWithWhite:value.doubleValue alpha:.65];UIGradientSlider *slider=[self.controller valueForKey:@"brightnessSlider"];NSString *expected=[percent stringFromNumber:value];BOOL valid=[slider.accessibilityValue isEqualToString:expected]&&[[slider valueForKey:@"accessibilityValueReversed"]boolValue];all=all&&valid;[checks addObject:@{@"brightness":value,@"expectedAX":expected?:@"",@"actualAX":slider.accessibilityValue?:@"",@"passed":@(valid)}];
    }
    NSMutableArray *directionChecks=[NSMutableArray new];BOOL directions=YES;self.panel.continuous=NO;
    for(NSNumber *direction in @[@(UISemanticContentAttributeForceLeftToRight),@(UISemanticContentAttributeForceRightToLeft)]){
        self.panel.color=[UIColor colorWithWhite:.5 alpha:.65];UIGradientSlider *slider=[self.controller valueForKey:@"brightnessSlider"];slider.semanticContentAttribute=direction.integerValue;CGFloat before=slider.value;NSUInteger actions=self.actionColors.count;
        [slider accessibilityIncrement];CGFloat incremented=slider.value;CGColorSpaceRef rgb=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);CGFloat values[4]={0};BOOL converted=[self.panel.colorValue getRGBComponents:values inColorSpace:rgb error:nil];CGFloat brighter=MAX(values[0],MAX(values[1],values[2]));BOOL oneIncrement=self.actionColors.count==actions+1;
        [slider accessibilityDecrement];CGFloat decremented=slider.value;converted=converted&&[self.panel.colorValue getRGBComponents:values inColorSpace:rgb error:nil];CGFloat darker=MAX(values[0],MAX(values[1],values[2]));CGColorSpaceRelease(rgb);
        BOOL valid=converted&&incremented<before&&decremented>incremented&&brighter>darker&&oneIncrement&&self.actionColors.count==actions+2&&fabs(CGColorGetAlpha(self.panel.colorValue.CGColor)-.65)<1e-12;directions=directions&&valid;[directionChecks addObject:@{@"rtl":@(direction.integerValue==UISemanticContentAttributeForceRightToLeft),@"rawBefore":@(before),@"rawAfterIncrement":@(incremented),@"rawAfterDecrement":@(decremented),@"brightnessAfterIncrement":@(brighter),@"brightnessAfterDecrement":@(darker),@"noncontinuousActions":@(self.actionColors.count-actions),@"passed":@(valid)}];
    }
    all=all&&directions;self.panel.continuous=YES;
    self.panel.mode=UIColorPanelModeHSB;self.panel.color=[UIColor colorWithHue:.25 saturation:1 brightness:1 alpha:.65];UIGradientSlider *hue=[[self.controller valueForKey:@"componentSliders"]firstObject];NSString *ninety=[UIColorPanelAppearance formatNumber:90 significantDigits:9];BOOL hueValue=[hue.accessibilityValue containsString:ninety]&&[hue.accessibilityValue containsString:@"°"];all=all&&hueValue;
    [self record:@"R09 slider AX reports semantic brightness and hue with matching increment direction" passed:all details:@{@"values":checks,@"directions":directionChecks,@"semanticDirection":@(directions),@"hueAX":hue.accessibilityValue?:@"",@"hueDegrees":@(hueValue),@"scope":@"Production UIKit accessibility methods and strings with LTR/RTL and noncontinuous target-action checks; no spoken VoiceOver or gesture claim."}];
}
- (void)finish {
    self.reenterSampling=NO;
    if(self.notificationObserver){[NSNotificationCenter.defaultCenter removeObserver:self.notificationObserver];self.notificationObserver=nil;}
    if(self.closeObserver){[NSNotificationCenter.defaultCenter removeObserver:self.closeObserver];self.closeObserver=nil;}
    [self restoreSearchFixture];
    [self removeFileProviderFixture];[self removeCustomFixture];
    [self.fixtureWell deactivate];[self.fixtureWell removeFromSuperview];self.fixtureWell=nil;
    if(self.fixtureFileURL){[NSFileManager.defaultManager removeItemAtURL:self.fixtureFileURL error:nil];self.fixtureFileURL=nil;}
    if(self.panel&&self.original){
        [self.controller endTransientInteractionsForClose:YES];[(UINavigationController *)self.panel.window.rootViewController setOverrideTraitCollection:self.originalTraits forChildViewController:self.controller];self.panel.target=nil;self.panel.action=NULL;[self.panel close];
        self.panel.use_spi=[self.original[@"useSPI"]boolValue];self.panel.allowsApplicationSampling=[self.original[@"allowsSampling"]boolValue];self.panel.samplingImage=self.original[@"image"]==NSNull.null?nil:self.original[@"image"];self.panel.samplingSourceView=self.original[@"source"]==NSNull.null?nil:self.original[@"source"];self.panel.accessoryView=self.original[@"accessory"]==NSNull.null?nil:self.original[@"accessory"];[self.controller setValue:self.original[@"paletteImage"]==NSNull.null?nil:self.original[@"paletteImage"] forKey:@"paletteImage"];UIColor.ignoresAlpha=[self.original[@"ignoresAlpha"]boolValue];self.panel.continuous=[self.original[@"continuous"]boolValue];self.panel.colorValue=self.original[@"color"];self.panel.mode=[self.original[@"mode"]integerValue];UIColorPickerSwatchesView *swatches=[self.controller valueForKey:@"swatchesView"];swatches.favoritesStore=self.original[@"favoritesStore"]==NSNull.null?nil:self.original[@"favoritesStore"];swatches.persistenceKey=self.original[@"key"]==NSNull.null?nil:self.original[@"key"];self.panel.target=self.originalTarget;self.panel.action=self.originalAction;
        BOOL restored=self.host.isKeyWindow&&!self.panel.isVisible&&[self.panel.colorValue isEqual:self.original[@"color"]]&&UIColor.ignoresAlpha==[self.original[@"ignoresAlpha"]boolValue];[self record:@"review fixture restores shared configuration and host ownership" passed:restored details:@{@"hostKey":@(self.host.isKeyWindow),@"panelTargetVisible":@(self.panel.isVisible)}];
    }
    NSDictionary *result=@{@"passed":@(self.failures==0),@"caseCount":@(self.cases.count),@"failureCount":@(self.failures),@"cases":self.cases?:@[],@"readiness":self.readinessReceipts?:@[],@"readinessPolicy":@"Original nominal delays followed by at most2s of50ms main-queue polling for owned UIKit transitions/session completion. Opening interruption step0 and100ms race steps29/30 never poll. Timeouts execute original assertions and fail the corresponding existing case.",@"scope":@"Finite asynchronous checks on the actual shared UIWindow and existing app host. Actual attached first responders, owned modal presentations, real host dismissal of Custom, scoped child traits, localized layout, programmatic slider/AX calls and native hit testing. Late Files delegate delivery and application-deactivation notification are explicitly controlled fixtures; provider import spies prevent palette writes. No device preference changes, physical taps, spoken VoiceOver, actual Files selection, actual background transition or complete screen-capture race coverage."};NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];[data writeToURL:self.outputURL options:NSDataWritingAtomic error:nil];
}
- (void)removeFileProviderFixture {
    self.filePicker.delegate=nil;if(self.filePicker.presentingViewController)[self.filePicker dismissViewControllerAnimated:NO completion:nil];self.filePicker=nil;
    if(self.fileProvider.parentViewController){[self.fileProvider willMoveToParentViewController:nil];[self.fileProvider.viewIfLoaded removeFromSuperview];[self.fileProvider removeFromParentViewController];}self.fileProvider=nil;
}
- (void)removeCustomFixture {
    [self.customController endTransientInteractionsForClose:YES];self.customController.delegate=nil;
    self.customPicker.completionHandler=nil;[self.customPicker cancel];if(self.customNavigation.presentingViewController)[self.customNavigation dismissViewControllerAnimated:NO completion:nil];self.customPicker=nil;self.customController=nil;self.customNavigation=nil;
}
- (void)restoreSearchFixture {
    if(!self.searchState)return;UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];UISearchBar *bar=[catalog valueForKey:@"searchBar"];[bar resignFirstResponder];[catalog setValue:self.searchState[@"list"]==NSNull.null?nil:self.searchState[@"list"] forKey:@"currentColorList"];bar.text=self.searchState[@"text"];[catalog setValue:self.searchState[@"row"] forKey:@"selectedRowIndex"];[catalog setValue:self.searchState[@"key"]==NSNull.null?nil:self.searchState[@"key"] forKey:@"selectedKey"];[catalog reloadCatalog];self.searchState=nil;self.searchResponder=nil;self.searchFont=nil;
}
@end

static BOOL UIInteractionExactColor(UIColorValue *a,UIColorValue *b) {
    CGColorRef x=a.CGColor,y=b.CGColor;
    return x&&y&&CGColorEqualToColor(x,y)&&CFEqual(CGColorGetColorSpace(x),CGColorGetColorSpace(y))&&CGColorGetNumberOfComponents(x)==CGColorGetNumberOfComponents(y)&&memcmp(CGColorGetComponents(x),CGColorGetComponents(y),CGColorGetNumberOfComponents(x)*sizeof(CGFloat))==0;
}
static UIImage *UIInteractionImage(NSData *data,size_t width,size_t height,size_t bits,size_t rowBytes,CGColorSpaceRef space,CGBitmapInfo info,UIImageOrientation orientation) {
    CGDataProviderRef provider=CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef image=provider?CGImageCreate(width,height,bits,bits*4,rowBytes,space,info,provider,NULL,NO,kCGRenderingIntentDefault):NULL;
    UIImage *result=image?[UIImage imageWithCGImage:image scale:1 orientation:orientation]:nil;
    if(image)CGImageRelease(image);if(provider)CGDataProviderRelease(provider);return result;
}
static BOOL UIInteractionComponents(UIColorValue *color,const CGFloat expected[4],double tolerance) {
    if(!color||CGColorGetNumberOfComponents(color.CGColor)!=4)return NO;
    const CGFloat *actual=CGColorGetComponents(color.CGColor);
    for(NSUInteger i=0;i<4;i++)if(fabs(actual[i]-expected[i])>tolerance)return NO;
    return YES;
}
// Only the persistence boundary fails; the real catalog transaction still runs.
@interface UIInputStateFailingColorList : UIColorList
@property(nonatomic) BOOL failWrites;
@property(nonatomic) NSUInteger failedWrites;
@end
@implementation UIInputStateFailingColorList
- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error {
    if(!self.failWrites)return[super writeToURL:url error:error];
    self.failedWrites++;if(error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:@{NSLocalizedDescriptionKey:@"Controlled palette save failure"}];return NO;
}
@end
#if UICOLORPANEL_ENABLE_PENCILS
@interface UIColorPickerPencilView (InputStateValidation)
- (void)keyDown:(UIKeyCommand *)command;
- (CALayer *)_layerForPencil:(UIColoredPencil *)pencil;
- (CGRect)_calculateFrameForPencil:(UIColoredPencil *)pencil;
@end
#endif
// An explicit finite fixture for the reported interaction failures. It uses a
// real nonshared panel and its real controls; each mode records its input scope.
@interface UIScopedChangeColorView : UIView
@property(nonatomic) NSUInteger changes;
@end
@implementation UIScopedChangeColorView
- (BOOL)canBecomeFirstResponder {return YES;}
- (void)changeColor:(id)sender {self.changes++;}
@end
@interface UIScopedChangeColorController : UIViewController
@property(nonatomic) NSUInteger changes;
@end
@implementation UIScopedChangeColorController
- (BOOL)canBecomeFirstResponder {return YES;}
- (void)changeColor:(id)sender {self.changes++;}
@end
@interface UIInteractionRepairsRunner : NSObject <UIColorPanelViewControllerDelegate>
@property(nonatomic,strong) NSURL *outputURL;
@property(nonatomic,strong) UIWindow *host;
@property(nonatomic,strong) UIColorPanel *panel;
@property(nonatomic,strong) UIColorPanelViewController *controller;
@property(nonatomic,strong) NSMutableArray<NSDictionary *> *cases;
@property(nonatomic,strong) NSMutableArray<UIColorList *> *fixtureLists;
@property(nonatomic,strong) id colorObserver,closeObserver;
@property(nonatomic,strong) UIColorValue *renameColor,*closingColor;
@property(nonatomic,strong) UIColorList *renameOriginal;
@property(nonatomic,strong) id savedCatalogSelection;
@property(nonatomic,copy) NSString *renameName,*renameKey;
@property(nonatomic) NSUInteger actions,notifications,closes,failures;
@property(nonatomic) BOOL oldIgnoresAlpha,reenterClose,showTransitionObserved,hideTransitionObserved;
@property(nonatomic) BOOL didSaveCatalogSelection;
@property(nonatomic) BOOL inputStateRepairs;
@property(nonatomic) BOOL scopedReviewRepairs;
@property(nonatomic,strong) UIResponder *savedHostResponder;
@property(nonatomic,strong) UIScopedChangeColorController *responderController;
@property(nonatomic,strong) UIScopedChangeColorView *responderView;
@property(nonatomic,strong) UIColorValue *pendingHostOverride,*hexBefore;
@property(nonatomic,strong) id<UIColorPanelViewControllerDelegate> overrideDelegate;
@property(nonatomic,strong) UITextField *hexDraft;
@property(nonatomic,strong) NSURL *importFixtureURL;
@property(nonatomic,strong) UIInputStateFailingColorList *failingList;
@property(nonatomic,strong) NSDictionary *catalogSnapshot;
@property(nonatomic,strong) id listObserver;
@property(nonatomic) NSUInteger listNotifications;
- (void)start;
- (void)runStep:(NSUInteger)step;
- (void)waitForStep:(NSUInteger)step deadline:(NSTimeInterval)deadline;
- (void)record:(NSString *)name passed:(BOOL)passed details:(NSDictionary *)details;
- (void)checkSampling;
- (void)checkEditing;
- (void)runInputStateStep:(NSUInteger)step;
- (void)runScopedReviewStep:(NSUInteger)step;
- (void)checkScopedMetadata;
- (void)checkScopedSwatches;
- (void)checkHSBState;
#if UICOLORPANEL_ENABLE_PENCILS
- (void)checkPencilInputState;
#endif
- (void)invokeAlertStyle:(UIAlertActionStyle)style text:(NSString *)text nextStep:(NSUInteger)step;
- (BOOL)catalogTransactionUnchanged;
- (void)finish;
@end
@implementation UIInteractionRepairsRunner
- (void)record:(NSString *)name passed:(BOOL)passed details:(NSDictionary *)details {
    NSMutableDictionary *entry=[@{@"name":name,@"passed":@(passed)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[self.cases addObject:entry];if(!passed)self.failures++;
}
- (void)panelAction:(UIColorPanel *)panel {self.actions++;if(self.reenterClose){self.reenterClose=NO;[panel close];}}
- (void)colorPanel:(UIColorPanelViewController *)controller didSelectColor:(UIColorValue *)color {
    [self.overrideDelegate colorPanel:controller didSelectColor:color];
    // Public target-action deliberately suppresses setColor:. The embedded
    // controller delegate may replace the source after that dispatch returns.
    UIColorValue *override=self.pendingHostOverride;self.pendingHostOverride=nil;
    if(override)self.panel.colorValue=override;
}
- (void)start {
    self.cases=[NSMutableArray new];self.fixtureLists=[NSMutableArray new];self.host=UIApplication.sharedApplication.keyWindow;
    BOOL attached=self.host&&!self.host.hidden&&self.host.rootViewController.view.window==self.host&&!self.host.rootViewController.presentedViewController;
    [self record:@"interaction fixture has an attached idle app host" passed:attached details:@{}];if(!attached){[self finish];return;}
    if(self.scopedReviewRepairs){
        NSMutableArray<UIView *> *views=[UIApplication.sharedApplication.windows mutableCopy];BOOL activeWell=NO;
        while(views.count){UIView *view=views.lastObject;[views removeLastObject];if([view isKindOfClass:UIColorPanelWell.class]&&((UIColorPanelWell *)view).active)activeWell=YES;[views addObjectsFromArray:view.subviews];
            if(view.window==self.host)for(UIResponder *responder=view;responder;responder=responder.nextResponder){if(responder.isFirstResponder)self.savedHostResponder=responder;if(responder==self.host)break;}}
        [self record:@"scoped fixture leaves existing active wells untouched" passed:!activeWell details:@{}];if(activeWell){[self finish];return;}
    }
    self.savedCatalogSelection=[NSUserDefaults.standardUserDefaults objectForKey:@"UIColorPickerCatalog.SelectedList.v1"];self.didSaveCatalogSelection=YES;
    self.oldIgnoresAlpha=UIColor.ignoresAlpha;UIColor.ignoresAlpha=NO;
    self.panel=[UIColorPanel new];self.controller=[self.panel valueForKey:@"pickerController"];self.panel.showsAlpha=YES;self.panel.mode=UIColorPanelModeRGB;self.panel.target=self;self.panel.action=@selector(panelAction:);
    __weak typeof(self) weakSelf=self;
    self.colorObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIColorPanelColorDidChangeNotification object:self.panel queue:nil usingBlock:^(NSNotification *note){weakSelf.notifications++;}];
    self.closeObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIPanelWillCloseNotification object:self.panel queue:nil usingBlock:^(NSNotification *note){weakSelf.closes++;}];
    [self.panel orderFront:self.host.rootViewController];self.showTransitionObserved=self.panel.isTransitioning;[self waitForStep:self.scopedReviewRepairs?200:self.inputStateRepairs?100:1 deadline:NSProcessInfo.processInfo.systemUptime+2];
}
- (void)waitForStep:(NSUInteger)step deadline:(NSTimeInterval)deadline {
    UIViewController *shown=self.panel.window.rootViewController.presentedViewController?:self.controller.presentedViewController;
    BOOL ready=!self.panel.isTransitioning;
    if(step==2||step==101||step==103||step==105||step==106||step==108||step==109||step==111||step==113||step==201||step==203||step==205||step==207)ready=ready&&[shown isKindOfClass:UIAlertController.class]&&shown.viewIfLoaded.window==self.panel.window&&!shown.isBeingPresented&&!shown.isBeingDismissed&&!shown.transitionCoordinator;
    else if(step==6)ready=ready&&[shown isKindOfClass:UIEyedropperViewController.class]&&shown.viewIfLoaded.window==self.panel.window&&!shown.isBeingPresented&&!shown.transitionCoordinator;
    else ready=ready&&!shown&&!self.panel.window.rootViewController.transitionCoordinator;
    if(step==211||step==213)ready=ready&&self.hexDraft.isFirstResponder&&self.panel.window.isKeyWindow;
    if(step==212||step==214)ready=ready&&self.host.isKeyWindow&&!self.hexDraft.isFirstResponder;
    if(ready){[self runStep:step];return;}
    if(NSProcessInfo.processInfo.systemUptime>=deadline){[self record:@"owned UIKit transition reached its two-second bound" passed:NO details:@{@"step":@(step)}];[self finish];return;}
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.05*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[self waitForStep:step deadline:deadline];});
}
- (void)runStep:(NSUInteger)step {
    if(self.scopedReviewRepairs){[self runScopedReviewStep:step];return;}
    if(self.inputStateRepairs){[self runInputStateStep:step];return;}
    @try {
        if(step==1){
            [self.panel.window layoutIfNeeded];[self.controller.view layoutIfNeeded];NSMutableArray *alphas=[NSMutableArray new];BOOL valid=self.panel.visible&&!self.panel.window.hidden&&(!UIView.areAnimationsEnabled||self.showTransitionObserved);
            for(NSNumber *alpha in @[@0,@.005,@1]){
                self.panel.color=[UIColor colorWithRed:.3 green:.5 blue:.7 alpha:alpha.doubleValue];UIControl *slider=[self.controller valueForKey:@"opacitySlider"];CGPoint point=[slider convertPoint:CGPointMake(CGRectGetMidX(slider.bounds),CGRectGetMidY(slider.bounds)) toView:self.panel.window];UIView *hit=[self.panel.window hitTest:point withEvent:nil];
                BOOL usable=(hit==slider||[hit isDescendantOfView:slider])&&fabs(self.panel.alpha-alpha.doubleValue)<1e-9&&fabs(self.panel.window.alpha-1)<1e-9&&fabs(self.panel.window.layer.opacity-1)<1e-6;
                valid=valid&&usable;[alphas addObject:@{@"colorAlpha":alpha,@"windowAlpha":@(self.panel.window.alpha),@"hitClass":hit?NSStringFromClass(hit.class):@"nil",@"passed":@(usable)}];
            }
            [self record:@"transparent color alpha leaves the actual window interactive after appearance" passed:valid details:@{@"values":alphas,@"observedAppearanceTransition":@(self.showTransitionObserved)}];
            [self checkSampling];[self checkEditing];
            self.panel.mode=UIColorPanelModeColorList;[self.controller.view layoutIfNeeded];UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];
            UIColorList *apple=nil;for(UIColorList *list in catalog.colorLists)if([list.name isEqualToString:@"Apple"]){apple=list;break;}
            self.renameColor=[[apple colorValueWithKey:@"Red"]copyWithAlpha:.5];
            if(!self.renameColor){[self record:@"Apple Red rename fixture is available" passed:NO details:@{}];[self finish];return;}
            NSString *name=[@"InteractionRename-" stringByAppendingString:NSUUID.UUID.UUIDString];self.renameName=[name stringByAppendingString:@"-renamed"];self.renameKey=@"Half Red";self.renameOriginal=[[UIColorList alloc]initWithName:name];[self.fixtureLists addObject:self.renameOriginal];[self.renameOriginal setColorValue:self.renameColor forKey:self.renameKey];NSError *error=nil;
            if(![self.renameOriginal writeToURL:nil error:&error]){[self record:@"rename fixture saves in the app-private palette directory" passed:NO details:@{@"error":error.localizedDescription?:@""}];[self finish];return;}
            [catalog installList:self.renameOriginal replacing:nil];UITableView *table=[catalog valueForKey:@"tableView"];[catalog tableView:table didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [self record:@"rename starts from the actual custom row-zero selection" passed:UIInteractionExactColor(self.panel.colorValue,self.renameColor)&&[[catalog valueForKey:@"selectedRowIndex"]integerValue]==0&&[[catalog valueForKey:@"selectedKey"]isEqual:self.renameKey] details:@{}];
            self.actions=0;self.notifications=0;[catalog renameList:nil];[self waitForStep:2 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==2){
            UIAlertController *alert=(id)(self.panel.window.rootViewController.presentedViewController?:self.controller.presentedViewController);UIAlertAction *rename=nil;for(UIAlertAction *action in alert.actions)if(action.style==UIAlertActionStyleDefault){rename=action;break;}
            alert.textFields.firstObject.text=self.renameName;
            // The real production alert is attached and registered with its
            // owner. Calling its stored action block is a programmatic fixture,
            // not evidence of a physical UIAlertAction tap.
            void (^handler)(UIAlertAction *)=[rename valueForKey:@"handler"];
            [self record:@"production rename alert and action handler are attached" passed:handler!=nil&&alert.view.window==self.panel.window details:@{}];
            if(handler)handler(rename);UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];if(catalog.currentColorList!=self.renameOriginal)[self.fixtureLists addObject:catalog.currentColorList];
            [alert dismissViewControllerAnimated:NO completion:nil];[self waitForStep:3 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==3){
            UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];UIColorList *renamed=catalog.currentColorList;NSString *path=[renamed valueForKey:@"fileName"];UIColorList *reloaded=path?[[UIColorList alloc]initWithName:renamed.name fromFile:path]:nil;UITableView *table=[catalog valueForKey:@"tableView"];
            BOOL valid=[renamed.name isEqual:self.renameName]&&UIInteractionExactColor(self.panel.colorValue,self.renameColor)&&UIInteractionExactColor(catalog.selectedColor,self.renameColor)&&UIInteractionExactColor([renamed colorValueWithKey:self.renameKey],self.renameColor)&&UIInteractionExactColor([reloaded colorValueWithKey:self.renameKey],self.renameColor)&&[[catalog valueForKey:@"selectedKey"]isEqual:self.renameKey]&&[[catalog valueForKey:@"selectedRowIndex"]integerValue]==0&&table.indexPathForSelectedRow.row==0&&table.indexPathForSelectedRow!=nil&&self.actions==0&&self.notifications==0;
            NSData *beforeICC=CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(self.renameColor.CGColor))),*afterICC=CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(self.panel.colorValue.CGColor)));
            valid=valid&&(beforeICC?[beforeICC isEqual:afterICC]:afterICC==nil);
            [self record:@"rename preserves exact RGBA ICC key row and color notifications while persisting the replacement" passed:valid details:@{@"actions":@(self.actions),@"notifications":@(self.notifications),@"selectedRow":[catalog valueForKey:@"selectedRowIndex"],@"persisted":@(reloaded!=nil),@"iccBytes":@(beforeICC.length)}];
            self.panel.mode=UIColorPanelModeRGB;self.panel.continuous=NO;self.actions=0;self.notifications=0;NSArray *sliders=[self.controller valueForKey:@"componentSliders"];UIGradientSlider *red=sliders.firstObject,*opacity=[self.controller valueForKey:@"opacitySlider"];[self.controller.view layoutIfNeeded];
            [red dragChangedAtPoint:CGPointMake(red.bounds.size.height*.5+(red.bounds.size.width-red.bounds.size.height)*.4,red.bounds.size.height*.5)];[opacity dragChangedAtPoint:CGPointMake(opacity.bounds.size.height*.5,opacity.bounds.size.height*.5)];self.closingColor=self.panel.colorValue;self.reenterClose=YES;[self.panel close];self.hideTransitionObserved=self.panel.isTransitioning;[self waitForStep:4 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==4){
            BOOL cleared=[[self.controller valueForKey:@"activeEditingControls"]count]==0&&![[self.panel valueForKey:@"interactionInProgress"]boolValue];
            [self record:@"close clears overlapping edits and reentrant close emits one final action and close notification" passed:cleared&&self.actions==1&&self.notifications==1&&self.closes==1&&!self.panel.visible&&self.panel.window.hidden&&UIInteractionExactColor(self.panel.colorValue,self.closingColor)&&self.host.isKeyWindow details:@{@"actions":@(self.actions),@"notifications":@(self.notifications),@"closeNotifications":@(self.closes),@"activeEdits":@([[self.controller valueForKey:@"activeEditingControls"]count]),@"observedExitTransition":@(self.hideTransitionObserved)}];
            [self.panel orderFront:self.host.rootViewController];[self waitForStep:5 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==5){
            [self.panel.window layoutIfNeeded];[self.controller.view layoutIfNeeded];UIControl *slider=[self.controller valueForKey:@"opacitySlider"];UIView *hit=[self.panel.window hitTest:[slider convertPoint:CGPointMake(CGRectGetMidX(slider.bounds),CGRectGetMidY(slider.bounds)) toView:self.panel.window] withEvent:nil];
            [self record:@"reopening restores window opacity and hit testing without changing transparent canonical color" passed:self.panel.visible&&!self.panel.window.hidden&&!self.panel.transitioning&&fabs(self.panel.window.alpha-1)<1e-9&&fabs(self.panel.window.layer.opacity-1)<1e-6&&UIInteractionExactColor(self.panel.colorValue,self.closingColor)&&(hit==slider||[hit isDescendantOfView:slider]) details:@{@"canonicalAlpha":@(self.panel.alpha),@"windowAlpha":@(self.panel.window.alpha)}];
            self.panel.use_spi=YES;self.panel.allowsApplicationSampling=NO;self.actions=0;self.notifications=0;
            if(![UIEyedropperViewController supportsSystemCapture]){[self record:@"private-enabled simulator exposes system capture" passed:NO details:@{}];[self finish];return;}
            [[self.controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];
            [self record:@"system capture temporarily hides only the actual window" passed:self.panel.window.alpha==0&&UIInteractionExactColor(self.panel.colorValue,self.closingColor)&&self.actions==0&&self.notifications==0 details:@{@"canonicalAlpha":@(self.panel.alpha),@"windowAlpha":@(self.panel.window.alpha)}];
            [self waitForStep:6 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==6){
            UIEyedropperViewController *picker=(id)(self.panel.window.rootViewController.presentedViewController?:self.controller.presentedViewController);
            [self record:@"private screen capture restores the window and presents its actual snapshot" passed:picker.samplingAvailable&&[picker.sourceKind isEqualToString:@"Screen Snapshot"]&&picker.systemCaptureDetails.count>0&&self.panel.window.alpha==1&&UIInteractionExactColor(self.panel.colorValue,self.closingColor) details:@{@"capture":picker.systemCaptureDetails?:@{},@"scope":@"Production sample-button action and actual private display capture; programmatic presentation/cancel, not delivered touch."}];
            [picker cancel];[self waitForStep:7 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==7){
            UIControl *slider=[self.controller valueForKey:@"opacitySlider"];UIView *hit=[self.panel.window hitTest:[slider convertPoint:CGPointMake(CGRectGetMidX(slider.bounds),CGRectGetMidY(slider.bounds)) toView:self.panel.window] withEvent:nil];
            [self record:@"cancelling screen capture preserves color and restores control hit testing" passed:UIInteractionExactColor(self.panel.colorValue,self.closingColor)&&self.actions==0&&self.notifications==0&&self.panel.window.alpha==1&&fabs(self.panel.window.layer.opacity-1)<1e-6&&(hit==slider||[hit isDescendantOfView:slider])&&((UIButton *)[self.controller valueForKey:@"sampleButton"]).enabled&&![[self.controller valueForKey:@"ownsSamplingSurface"]boolValue] details:@{}];[self finish];
        }
    }@catch(NSException *exception){[self record:@"interaction repair fixture exception" passed:NO details:@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""}];[self finish];}
}
- (void)checkSampling {
    self.panel.mode=UIColorPanelModeCustomPalette;[self.controller.view layoutIfNeeded];UIColorPickerUserView *production=[self.controller valueForKey:@"imageSampler"];CGPoint point=CGPointMake(CGRectGetWidth(production.bounds)*.37,CGRectGetHeight(production.bounds)*.41);BOOL sampled=[production sampleAtPoint:point];CGColorRef color=production.sampledColor.CGColor;
    [self record:@"actual bundled Spectrum samples an opaque pixel through its production action path" passed:sampled&&CGImageGetWidth(production.image.CGImage)==612&&CGImageGetHeight(production.image.CGImage)==152&&color&&CGColorGetAlpha(color)==1&&UIInteractionExactColor(self.panel.colorValue,production.sampledColor) details:@{@"sampled":@(sampled),@"alpha":@(color?CGColorGetAlpha(color):-1),@"bounds":NSStringFromCGRect(production.bounds)}];
    UIColorValue *before=production.sampledColor,*canonical=self.panel.colorValue;CGPoint beforePoint=production.samplePoint;NSString *beforeAX=production.accessibilityValue;NSUInteger actions=self.actions,notifications=self.notifications;CGRect bounds=production.bounds;
    BOOL refused=![production sampleAtPoint:CGPointMake(-1,0)]&&![production sampleAtPoint:CGPointMake(NAN,0)];production.bounds=CGRectZero;refused=refused&&![production sampleAtPoint:CGPointZero];production.bounds=bounds;
    [self record:@"failed production sample boundaries preserve selection marker AX and notifications" passed:refused&&UIInteractionExactColor(before,production.sampledColor)&&UIInteractionExactColor(canonical,self.panel.colorValue)&&CGPointEqualToPoint(beforePoint,production.samplePoint)&&[beforeAX isEqual:production.accessibilityValue]&&self.actions==actions&&self.notifications==notifications details:@{@"scope":@"Out-of-image, nonfinite and zero-size boundaries; no fabricated backend decode failure."}];
    UIColorPickerUserView *sampler=[[UIColorPickerUserView alloc]initWithFrame:CGRectMake(0,0,200,200)];sampler.contentMode=UIViewContentModeScaleToFill;UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];[sampler addTarget:recorder action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    CGColorSpaceRef srgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB),extended=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
    const uint8_t bytes[]={255,0,0,255, 0,255,0,255, 0,0,255,255, 255,255,0,255};NSData *data=[NSData dataWithBytes:bytes length:sizeof(bytes)];
    const CGFloat expected[4][4]={{1,0,0,1},{0,1,0,1},{0,0,1,1},{1,1,0,1}};
    const NSUInteger order[8][4]={{0,1,2,3},{3,2,1,0},{1,3,0,2},{2,0,3,1},{1,0,3,2},{2,3,0,1},{0,2,1,3},{3,1,2,0}};
    BOOL orientations=YES;NSMutableArray *orientationResults=[NSMutableArray new];
    for(NSUInteger orientation=0;orientation<8;orientation++){
        sampler.image=UIInteractionImage(data,2,2,8,8,srgb,kCGImageAlphaLast,(UIImageOrientation)orientation);BOOL valid=sampler.image!=nil;
        for(NSUInteger pixel=0;pixel<4;pixel++)valid=[sampler sampleAtPoint:CGPointMake(50+(pixel%2)*100,50+(pixel/2)*100)]&&UIInteractionComponents(sampler.sampledColor,expected[order[orientation][pixel]],1e-5)&&valid;
        orientations=orientations&&valid;[orientationResults addObject:@{@"orientation":@(orientation),@"passed":@(valid)}];
    }
    [self record:@"two-by-two known pixels retain all eight UIImage orientations" passed:orientations&&recorder.changes==32 details:@{@"orientations":orientationResults,@"valueEvents":@(recorder.changes)}];
    const CGFloat floating[]={-.125,.123456789,1.25,.25};float premultiplied[]={floating[0]*floating[3],floating[1]*floating[3],floating[2]*floating[3],floating[3]};
    sampler.image=UIInteractionImage([NSData dataWithBytes:premultiplied length:sizeof(premultiplied)],1,1,32,sizeof(premultiplied),extended,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast,UIImageOrientationUp);
    BOOL floats=[sampler sampleAtPoint:CGPointMake(100,100)]&&UIInteractionComponents(sampler.sampledColor,floating,1e-6)&&CFEqual(CGColorGetColorSpace(sampler.sampledColor.CGColor),extended);
    [self record:@"float sampling preserves fractions extended RGB and straight alpha" passed:floats details:@{@"expected":@[@(floating[0]),@(floating[1]),@(floating[2]),@(floating[3])]}];
    CGColorSpaceRef p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);NSData *icc=p3?CFBridgingRelease(CGColorSpaceCopyICCData(p3)):nil;CGColorSpaceRef custom=icc?CGColorSpaceCreateWithICCData((__bridge CFDataRef)icc):NULL;
    const CGFloat components[]={.123456,.4,.85,.7};float stored[]={components[0]*components[3],components[1]*components[3],components[2]*components[3],components[3]};BOOL iccValid=NO;
    if(custom){CGColorRef source=CGColorCreate(custom,components);UIColorValue *expectedColor=[[[UIColorValue alloc]initWithCGColor:source]colorByConvertingToSpace:extended error:nil];CGColorRelease(source);sampler.image=UIInteractionImage([NSData dataWithBytes:stored length:sizeof(stored)],1,1,32,sizeof(stored),custom,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast,UIImageOrientationUp);iccValid=[sampler sampleAtPoint:CGPointMake(100,100)]&&expectedColor&&UIInteractionComponents(sampler.sampledColor,CGColorGetComponents(expectedColor.CGColor),2e-4);}
    [self record:@"ICC-backed Display P3 pixels convert to extended sRGB without losing alpha" passed:iccValid details:@{@"iccBytes":@(icc.length)}];
    float transparent[]={0,0,0,0};sampler.image=UIInteractionImage([NSData dataWithBytes:transparent length:sizeof(transparent)],1,1,32,sizeof(transparent),extended,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast,UIImageOrientationUp);NSUInteger events=recorder.changes;
    [self record:@"legitimate transparent black remains a successful sample" passed:[sampler sampleAtPoint:CGPointMake(100,100)]&&UIInteractionComponents(sampler.sampledColor,(CGFloat[]){0,0,0,0},0)&&recorder.changes==events+1 details:@{}];
    // Nil deliberately proves that the cancelled bridges return before reading a touch.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    events=recorder.changes;[sampler cancelTrackingWithEvent:nil];BOOL imageRejected=![sampler continueTrackingWithTouch:nil withEvent:nil];UIColorPickerWheelView *wheel=[[UIColorPickerWheelView alloc]initWithFrame:CGRectMake(0,0,200,200)];[wheel addTarget:recorder action:@selector(changed:) forControlEvents:UIControlEventValueChanged];[wheel cancelTrackingWithEvent:nil];
    [self record:@"cancelled image and wheel bridges reject residual moves before reading a touch" passed:imageRejected&&![wheel continueTrackingWithTouch:nil withEvent:nil]&&recorder.changes==events details:@{@"scope":@"Direct cancel/continue calls with nil touch prove the closed bridge gate; no manufactured UITouch."}];
#pragma clang diagnostic pop
    if(custom)CGColorSpaceRelease(custom);if(p3)CGColorSpaceRelease(p3);CGColorSpaceRelease(extended);CGColorSpaceRelease(srgb);
}
- (void)checkEditing {
    self.panel.mode=UIColorPanelModeRGB;self.panel.color=[UIColor colorWithRed:.3 green:.5 blue:.7 alpha:.5];self.panel.continuous=NO;[self.controller.view layoutIfNeeded];
    UIGradientSlider *red=[[self.controller valueForKey:@"componentSliders"]firstObject],*opacity=[self.controller valueForKey:@"opacitySlider"];
    CGPoint (^point)(UIGradientSlider *,double)=^CGPoint(UIGradientSlider *slider,double fraction){CGFloat h=slider.bounds.size.height;return CGPointMake(h*.5+(slider.bounds.size.width-h)*fraction,h*.5);};
    self.actions=0;self.notifications=0;[red dragChangedAtPoint:point(red,.2)];[opacity dragChangedAtPoint:point(opacity,.3)];[red sendActionsForControlEvents:UIControlEventEditingDidBegin];[red dragEnded];[red sendActionsForControlEvents:UIControlEventEditingDidEnd];BOOL held=self.actions==0&&self.notifications==0&&[[self.controller valueForKey:@"activeEditingControls"]count]==1;
    // This nil touch checks the same closed bridge contract for the recovered slider.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [opacity dragChangedAtPoint:point(opacity,.4)];held=held&&self.actions==0;[opacity cancelTrackingWithEvent:nil];[opacity sendActionsForControlEvents:UIControlEventEditingDidEnd];held=held&&![opacity continueTrackingWithTouch:nil withEvent:nil];
#pragma clang diagnostic pop
    [self record:@"overlapping slider edits commit once after the last cancellation and ignore duplicate boundaries" passed:held&&self.actions==1&&self.notifications==1&&!red.active&&!opacity.active&&[[self.controller valueForKey:@"activeEditingControls"]count]==0&&![[self.panel valueForKey:@"interactionInProgress"]boolValue] details:@{@"actions":@(self.actions),@"notifications":@(self.notifications)}];
    self.actions=0;self.notifications=0;[red dragChangedAtPoint:point(red,.25)];[opacity dragChangedAtPoint:point(opacity,.6)];self.panel.mode=UIColorPanelModeWheel;BOOL retained=opacity.active&&!red.active&&self.actions==0&&[[self.controller valueForKey:@"activeEditingControls"]count]==1;[opacity cancelTrackingWithEvent:nil];
    [self record:@"provider rebuild cancels its old controls while an opacity edit remains active" passed:retained&&self.actions==1&&self.notifications==1&&[[self.controller valueForKey:@"activeEditingControls"]count]==0 details:@{}];
    self.panel.mode=UIColorPanelModeRGB;[self.controller.view layoutIfNeeded];red=[[self.controller valueForKey:@"componentSliders"]firstObject];self.actions=0;self.notifications=0;[red dragChangedAtPoint:point(red,.35)];UIColorValue *before=self.panel.colorValue;self.panel.mode=UIColorPanelModeCMYK;
    [self record:@"noncontinuous RGB cancellation cannot undo a requested CMYK mode switch" passed:self.panel.mode==UIColorPanelModeCMYK&&self.controller.mode==UIColorPanelModeCMYK&&self.actions==1&&self.notifications==1&&!red.active&&UIInteractionExactColor(before,self.panel.colorValue)&&[[self.controller valueForKey:@"activeEditingControls"]count]==0 details:@{@"mode":@(self.panel.mode),@"actions":@(self.actions)}];
}
- (void)checkHSBState {
    self.panel.mode=UIColorPanelModeHSB;
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    UIColorValue *(^color)(CGFloat,CGFloat,CGFloat,CGFloat)=^UIColorValue *(CGFloat r,CGFloat g,CGFloat b,CGFloat a){CGFloat values[]={r,g,b,a};CGColorRef cg=CGColorCreate(space,values);UIColorValue *result=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);return result;};
    UIColorValue *blue=color(0,0,1,.65);self.panel.colorValue=blue;[self.controller.view layoutIfNeeded];UIColorPanelColorProfile *profile=self.controller.activeColorProfile;
    NSArray<UIGradientSlider *> *sliders=[self.controller valueForKey:@"componentSliders"];NSArray<UITextField *> *fields=[self.controller valueForKey:@"componentFields"];
    void (^slide)(NSUInteger,double)=^(NSUInteger index,double value){UIGradientSlider *slider=sliders[index];slider.value=value;[slider sendActionsForControlEvents:UIControlEventValueChanged];};
    void (^type)(NSUInteger,double)=^(NSUInteger index,double value){UITextField *field=fields[index];field.text=[UIColorPanelAppearance formatNumber:value significantDigits:9];[field sendActionsForControlEvents:UIControlEventEditingChanged];[field sendActionsForControlEvents:UIControlEventEditingDidEnd];};
    BOOL (^matches)(const CGFloat *)=^BOOL(const CGFloat *expected){return UIInteractionComponents(self.panel.colorValue,expected,1e-10)&&CFEqual(CGColorGetColorSpace(self.panel.colorValue.CGColor),space)&&[profile.identifier isEqual:self.controller.activeColorProfile.identifier];};
    slide(2,0);BOOL black=matches((CGFloat[]){0,0,0,.65})&&fabs(sliders[1].value-1)<1e-10;slide(2,1);
    [self record:@"HSB slider brightness zero then restore retains blue saturation alpha and profile" passed:black&&matches((CGFloat[]){0,0,1,.65}) details:@{@"scope":@"Production slider ValueChanged action; no synthetic pointer gesture."}];
    self.panel.colorValue=blue;slide(1,0);type(0,180);BOOL hueHeld=fabs(sliders[0].value-.5)<1e-10;slide(1,1);
    [self record:@"HSB text hue while saturation is zero survives restoring saturation" passed:hueHeld&&matches((CGFloat[]){0,1,1,.65}) details:@{}];
    self.panel.colorValue=blue;slide(2,0);type(0,120);type(1,40);[sliders[1]accessibilityIncrement];BOOL stateHeld=fabs(sliders[0].value-1.0/3)<1e-10&&fabs(sliders[1].value-.5)<1e-10;slide(2,1);
    [self record:@"HSB black retains text hue and AX saturation until brightness returns" passed:stateHeld&&matches((CGFloat[]){.5,1,.5,.65}) details:@{@"scope":@"Actual accessibilityIncrement method plus production text commit; no spoken VoiceOver claim."}];
    self.panel.colorValue=blue;UIColorValue *override=color(1,0,0,.42);self.pendingHostOverride=override;self.overrideDelegate=self.controller.delegate;
    @try{self.controller.delegate=self;slide(2,.5);}@finally{self.controller.delegate=self.overrideDelegate;self.overrideDelegate=nil;}
    BOOL exactOverride=UIInteractionExactColor(self.panel.colorValue,override),sameProfile=[profile.identifier isEqual:self.controller.activeColorProfile.identifier];
    [self record:@"synchronous host override supersedes the pending HSB edit state" passed:self.pendingHostOverride==nil&&exactOverride&&sameProfile&&fabs(sliders[0].value)<1e-10&&fabs(sliders[1].value-1)<1e-10&&fabs(sliders[2].value-1)<1e-10 details:@{@"overrideConsumed":@(self.pendingHostOverride==nil),@"exactColor":@(exactOverride),@"sameProfile":@(sameProfile),@"hsb":@[@(sliders[0].value),@(sliders[1].value),@(sliders[2].value)],@"scope":@"Synchronous embedded-controller delegate source replacement after forwarding to the real panel; the public panel target-action setColor suppression contract is preserved."}];
    CGColorSpaceRelease(space);
}
#if UICOLORPANEL_ENABLE_PENCILS
- (void)checkPencilInputState {
    self.panel.mode=UIColorPanelModePencils;[self.controller.view layoutIfNeeded];UIColorPickerPencilView *pencil=((UIColorPickerPencils *)[self.controller valueForKey:@"pencilsPicker"]).pencilView;NSArray<UIColoredPencil *> *items=[pencil _pencils];
    if(items.count<15){[self record:@"pencil fixture contains two real colored pencils" passed:NO details:@{}];return;}
    UIColoredPencil *selected=items[13],*preview=items[14];[pencil _selectPencil:selected updateSelection:YES animate:NO];
    [self record:@"pencil touch-end preview cleanup requires delivered touch acceptance" passed:YES details:@{@"skipped":@YES,@"reason":@"The bridge also enters UIControl super touch handling. A fabricated UITouch cannot establish valid UIKit internal event state; native touch acceptance and the bounded source review cover this path."}];
    BOOL reduced=UIAccessibilityIsReduceMotionEnabled(),settled=YES;
    if(reduced){[pencil becomeFirstResponder];[pencil _selectPencil:preview updateSelection:YES animate:YES];[pencil _hoverPencil:selected];[pencil _hoverPencil:nil];for(UIColoredPencil *item in items){CALayer *layer=[pencil _layerForPencil:item];settled=settled&&layer.animationKeys.count==0&&CGRectEqualToRect(layer.frame,[pencil _calculateFrameForPencil:item]);}}
    [self record:@"Reduce Motion pencil changes reach their final frames without layer animations" passed:settled details:@{@"skipped":@(!reduced),@"reason":reduced?@"Current system preference is enabled; no preference was changed.":@"Current system preference is disabled; the enabled branch requires source review or a separately authorized enabled runtime."}];
    UIKeyCommand *forward=nil,*backward=nil;for(UIKeyCommand *command in pencil.keyCommands)if([command.input isEqual:@"\t"]){if(command.modifierFlags&UIKeyModifierShift)backward=command;else forward=command;}
    UITextField *opacity=[self.controller valueForKey:@"opacityField"];UIControl *toolbar=[self.controller valueForKey:@"modeControl"];
    NSMutableArray *steps=[NSMutableArray new];void (^snapshot)(NSString *,BOOL)=^(NSString *name,BOOL passed){
        UIColorPickerPencilView *current=((UIColorPickerPencils *)[self.controller valueForKey:@"pencilsPicker"]).pencilView;NSMutableArray *responders=[NSMutableArray new],*pending=[NSMutableArray arrayWithObject:self.panel.window];
        while(pending.count){UIView *view=pending.lastObject;[pending removeLastObject];if(view.isFirstResponder)[responders addObject:@{@"class":NSStringFromClass(view.class),@"identifier":view.accessibilityIdentifier?:@""}];[pending addObjectsFromArray:view.subviews];}
        [steps addObject:@{@"step":name,@"passed":@(passed),@"mode":@(self.panel.mode),@"panelKey":@(self.panel.window.isKeyWindow),@"pencilAttached":@(current.window==self.panel.window),@"pencilFirst":@(current.isFirstResponder),@"toolbarFirst":@(toolbar.isFirstResponder),@"opacityFirst":@(opacity.isFirstResponder),@"opacityEnabled":@(opacity.enabled),@"responders":responders}];
    };
    BOOL focus=forward&&backward;BOOL became=[pencil becomeFirstResponder];focus=focus&&became;snapshot(@"pencil becomes first responder",became);
    [pencil keyDown:forward];BOOL moved=opacity.isFirstResponder&&!pencil.isFirstResponder;focus=focus&&moved;snapshot(@"pencil Tab to opacity",moved);
    became=[pencil becomeFirstResponder];focus=focus&&became;snapshot(@"pencil becomes first responder again",became);
    [pencil keyDown:backward];moved=toolbar.isFirstResponder&&!pencil.isFirstResponder;focus=focus&&moved;snapshot(@"pencil Shift-Tab to toolbar",moved);
    NSInteger beforeMode=self.panel.mode;for(NSString *input in @[UIKeyInputLeftArrow,UIKeyInputRightArrow])for(UIKeyCommand *command in toolbar.keyCommands)if([command.input isEqual:input]){BOOL sent=[UIApplication.sharedApplication sendAction:command.action to:toolbar from:command forEvent:nil];BOOL held=sent&&toolbar.isFirstResponder;focus=focus&&held;snapshot([input isEqual:UIKeyInputLeftArrow]?@"toolbar left retains focus":@"toolbar right retains focus",held);break;}
    focus=focus&&self.panel.mode==beforeMode;pencil=((UIColorPickerPencils *)[self.controller valueForKey:@"pencilsPicker"]).pencilView;
    for(UIKeyCommand *command in toolbar.keyCommands)if([command.input isEqual:@"\t"]&&command.modifierFlags==0){[UIApplication.sharedApplication sendAction:command.action to:toolbar from:command forEvent:nil];break;}
    moved=pencil.isFirstResponder;focus=focus&&moved;snapshot(@"toolbar Tab to pencil",moved);
    // The global AppKit-style alpha setter updates the shared panel only; this fixture owns an embedded controller.
    self.controller.showsAlpha=NO;[self.controller.view layoutIfNeeded];became=[pencil becomeFirstResponder];[pencil keyDown:forward];moved=became&&toolbar.isFirstResponder&&!pencil.isFirstResponder;focus=focus&&moved;snapshot(@"pencil Tab without alpha to toolbar",moved);self.controller.showsAlpha=YES;[self.controller.view endEditing:YES];
    [self record:@"pencil Tab directions move actual first responder and toolbar arrows retain focus" passed:focus details:@{@"steps":steps,@"hasForward":@(forward!=nil),@"hasBackward":@(backward!=nil),@"returnedToOriginalMode":@(self.panel.mode==beforeMode),@"scope":@"Production key commands dispatched programmatically; verifies real UIKit first-responder targets, not AX focus or hardware key delivery."}];
}
#endif
- (void)invokeAlertStyle:(UIAlertActionStyle)style text:(NSString *)text nextStep:(NSUInteger)step {
    UIAlertController *alert=(id)(self.panel.window.rootViewController.presentedViewController?:self.controller.presentedViewController);UIAlertAction *chosen=nil;for(UIAlertAction *action in alert.actions)if(action.style==style){chosen=action;break;}
    void (^handler)(UIAlertAction *)=chosen?[chosen valueForKey:@"handler"]:nil;
    if(!chosen||alert.viewIfLoaded.window!=self.panel.window){[self record:@"current production alert has its requested attached action" passed:NO details:@{@"nextStep":@(step)}];[self finish];return;}
    if(text)alert.textFields.firstObject.text=text;
    // UIKit dismisses an action alert before its handler may present an error.
    // The production owner registration remains intact through this completion.
    [alert dismissViewControllerAnimated:NO completion:^{
        if(handler)handler(chosen);
        if(self.scopedReviewRepairs){UIColorList *current=((UIColorPickerCatalogController *)[self.controller valueForKey:@"catalogController"]).currentColorList;if([current.name isEqual:self.renameName]&&![self.fixtureLists containsObject:current])[self.fixtureLists addObject:current];}
        [self waitForStep:step deadline:NSProcessInfo.processInfo.systemUptime+2];
    }];
}
- (BOOL)catalogTransactionUnchanged {
    UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];UITableView *table=[catalog valueForKey:@"tableView"];NSArray *keys=self.catalogSnapshot[@"keys"],*values=self.catalogSnapshot[@"values"];
    BOOL same=catalog.currentColorList==self.failingList&&self.failingList.allKeys==self.catalogSnapshot[@"keysIdentity"]&&[self.failingList.allKeys isEqual:keys]&&[UIColorList colorListNamed:self.failingList.name]==self.failingList&&[[self.failingList valueForKey:@"fileName"]isEqual:self.catalogSnapshot[@"fileName"]]&&[[self.failingList valueForKey:@"dirty"]isEqual:self.catalogSnapshot[@"dirty"]]&&[[catalog valueForKey:@"selectedKey"]isEqual:self.catalogSnapshot[@"selectedKey"]]&&[[catalog valueForKey:@"selectedRowIndex"]isEqual:self.catalogSnapshot[@"selectedRowIndex"]]&&[table.indexPathForSelectedRow isEqual:self.catalogSnapshot[@"selectedPath"]]&&UIInteractionExactColor(self.panel.colorValue,self.catalogSnapshot[@"color"])&&self.listNotifications==0&&self.actions==0&&self.notifications==0;
    for(NSUInteger index=0;index<keys.count;index++)same=same&&UIInteractionExactColor([self.failingList colorValueWithKey:keys[index]],values[index]);return same;
}
- (void)runInputStateStep:(NSUInteger)step {
    @try {
        UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];UISearchBar *search=[catalog valueForKey:@"searchBar"];
        if(step==100){
            [self.panel.window layoutIfNeeded];[self.controller.view layoutIfNeeded];[self checkHSBState];
#if UICOLORPANEL_ENABLE_PENCILS
            [self checkPencilInputState];
#endif
            self.panel.mode=UIColorPanelModeRGB;self.panel.color=[UIColor colorWithRed:.2 green:.4 blue:.6 alpha:.65];[self.controller.view layoutIfNeeded];self.hexBefore=self.panel.colorValue;self.hexDraft=[self.controller valueForKey:@"hexField"];
            [self.hexDraft becomeFirstResponder];self.hexDraft.text=@"0xFFFF";[self.hexDraft sendActionsForControlEvents:UIControlEventEditingChanged];[self.controller commitField:self.hexDraft];[self waitForStep:101 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==101){
            [self record:@"Hex rejects a six-character 0x prefix without changing canonical color or draft" passed:UIInteractionExactColor(self.panel.colorValue,self.hexBefore)&&[self.hexDraft.text isEqual:@"0xFFFF"]&&[[self.controller valueForKey:@"editedFields"]containsObject:self.hexDraft]&&[self.controller valueForKey:@"invalidField"]==self.hexDraft details:@{}];[self invokeAlertStyle:UIAlertActionStyleDefault text:nil nextStep:102];
        }else if(step==102){
            BOOL retained=[self.hexDraft.text isEqual:@"0xFFFF"]&&[[self.controller valueForKey:@"editedFields"]containsObject:self.hexDraft];self.hexDraft.text=@"09d38e";[self.hexDraft sendActionsForControlEvents:UIControlEventEditingChanged];BOOL committed=[self.controller commitField:self.hexDraft];[self.hexDraft resignFirstResponder];
            [self record:@"six ASCII Hex digits commit exactly after correcting the retained invalid draft" passed:retained&&committed&&UIInteractionComponents(self.panel.colorValue,(CGFloat[]){9/255.0,211/255.0,142/255.0,.65},1e-10)&&![[self.controller valueForKey:@"editedFields"]containsObject:self.hexDraft] details:@{}];
            self.panel.mode=UIColorPanelModeColorList;[self.controller.view layoutIfNeeded];catalog=[self.controller valueForKey:@"catalogController"];search=[catalog valueForKey:@"searchBar"];search.text=@"No matching fixture color";[catalog searchBar:search textDidChange:search.text];UIColorList *old=catalog.currentColorList;[catalog newList:nil];UIColorList *created=catalog.currentColorList;if(created!=old)[self.fixtureLists addObject:created];
            [self record:@"New palette clears the old query and displays its initial color" passed:created!=old&&search.text.length==0&&[[catalog valueForKey:@"visibleKeys"]count]==created.allKeys.count&&created.allKeys.count==1 details:@{}];
            NSString *name=[@"InputStateImport-" stringByAppendingString:NSUUID.UUID.UUIDString];UIColorList *source=[[UIColorList alloc]initWithName:name];[source setColorValue:self.panel.colorValue forKey:@"Keep"];self.importFixtureURL=[NSURL fileURLWithPath:[NSTemporaryDirectory()stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"clr"]]];NSError *error=nil;
            if(![source writeToURL:self.importFixtureURL error:&error]){[self record:@"temporary import fixture saves" passed:NO details:@{@"error":error.localizedDescription?:@""}];[self finish];return;}
            UIColorList *expectedImport=[[UIColorList alloc]initWithName:source.name fromFile:self.importFixtureURL.path];UIColorValue *beforeImport=self.panel.colorValue;
            search.text=@"No matching fixture color";[catalog searchBar:search textDidChange:search.text];[catalog importListAtURL:self.importFixtureURL];UIColorList *imported=catalog.currentColorList;if(imported!=created)[self.fixtureLists addObject:imported];
            BOOL importedExact=UIInteractionExactColor([imported colorValueWithKey:@"Keep"],[expectedImport colorValueWithKey:@"Keep"]),importKeptCanonical=UIInteractionExactColor(self.panel.colorValue,beforeImport);
            [self record:@"imported palette clears the old query and reveals its real color row" passed:imported!=created&&search.text.length==0&&[[catalog valueForKey:@"visibleKeys"]isEqual:@[@"Keep"]]&&importedExact&&importKeptCanonical details:@{@"exactArchivedColor":@(importedExact),@"canonicalUnchanged":@(importKeptCanonical),@"scope":@"Exact comparison to the parsed source .clr, whose established %.10g numeric archive contract is distinct from the unarchived canonical source."}];
            search.text=@"Keep";[catalog searchBar:search textDidChange:search.text];[catalog tableView:[catalog valueForKey:@"tableView"] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];self.renameName=[imported.name stringByAppendingString:@"-renamed"];[catalog renameList:nil];[self waitForStep:103 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==103){[self invokeAlertStyle:UIAlertActionStyleDefault text:self.renameName nextStep:104];
        }else if(step==104){
            if([catalog.currentColorList.name isEqual:self.renameName])[self.fixtureLists addObject:catalog.currentColorList];
            [self record:@"Rename preserves query selected key and matching visible row" passed:[catalog.currentColorList.name isEqual:self.renameName]&&[search.text isEqual:@"Keep"]&&[[catalog valueForKey:@"selectedKey"]isEqual:@"Keep"]&&[[catalog valueForKey:@"visibleKeys"]isEqual:@[@"Keep"]] details:@{}];
            self.failingList=[[UIInputStateFailingColorList alloc]initWithName:[@"InputStateFailure-" stringByAppendingString:NSUUID.UUID.UUIDString]];[self.failingList setColorValue:self.panel.colorValue forKey:@"First"];[self.failingList setColorValue:[self.panel.colorValue copyWithAlpha:.4] forKey:@"Second"];[self.fixtureLists addObject:self.failingList];NSError *error=nil;
            if(![self.failingList writeToURL:nil error:&error]){[self record:@"transaction fixture registers a real saved palette" passed:NO details:@{@"error":error.localizedDescription?:@""}];[self finish];return;}
            UIColorList *baseline=[[UIColorList alloc]initWithName:self.failingList.name fromFile:[self.failingList valueForKey:@"fileName"]];
            [self.controller attachColorList:self.failingList];[catalog selectListAtIndex:[catalog.colorLists indexOfObjectIdenticalTo:self.failingList]];[catalog tableView:[catalog valueForKey:@"tableView"] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];UITableView *table=[catalog valueForKey:@"tableView"];[table selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            self.catalogSnapshot=@{@"keys":[self.failingList.allKeys copy],@"keysIdentity":self.failingList.allKeys,@"values":@[[self.failingList colorValueWithKey:@"First"],[self.failingList colorValueWithKey:@"Second"]],@"persistedValues":@[[baseline colorValueWithKey:@"First"],[baseline colorValueWithKey:@"Second"]],@"fileName":[self.failingList valueForKey:@"fileName"],@"dirty":[self.failingList valueForKey:@"dirty"],@"selectedKey":[catalog valueForKey:@"selectedKey"],@"selectedRowIndex":[catalog valueForKey:@"selectedRowIndex"],@"selectedPath":table.indexPathForSelectedRow,@"color":self.panel.colorValue};self.actions=0;self.notifications=0;self.listNotifications=0;self.failingList.failWrites=YES;
            __weak typeof(self) weakSelf=self;self.listObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIColorListDidChangeNotification object:self.failingList queue:nil usingBlock:^(NSNotification *note){weakSelf.listNotifications++;}];[catalog addColor:nil];[self waitForStep:105 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==105){[self invokeAlertStyle:UIAlertActionStyleDefault text:@"Added" nextStep:106];
        }else if(step==106){
            [self record:@"failed Add leaves attached list registry contents selection and notifications unchanged" passed:self.failingList.failedWrites==1&&[self catalogTransactionUnchanged] details:@{@"failedWrites":@(self.failingList.failedWrites)}];[self invokeAlertStyle:UIAlertActionStyleDefault text:nil nextStep:107];
        }else if(step==107){[catalog confirmDeleteColor:nil];[self waitForStep:108 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==108){[self invokeAlertStyle:UIAlertActionStyleDestructive text:nil nextStep:109];
        }else if(step==109){
            [self record:@"failed confirmed Delete retains original attached list and selected key" passed:self.failingList.failedWrites==2&&[self catalogTransactionUnchanged] details:@{@"failedWrites":@(self.failingList.failedWrites)}];[self invokeAlertStyle:UIAlertActionStyleDefault text:nil nextStep:110];
        }else if(step==110){[catalog tableView:[catalog valueForKey:@"tableView"] commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];[self waitForStep:111 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==111){
            [self record:@"failed swipe Delete of another row retains the original selected key and table row" passed:self.failingList.failedWrites==3&&[self catalogTransactionUnchanged] details:@{@"failedWrites":@(self.failingList.failedWrites)}];[self invokeAlertStyle:UIAlertActionStyleDefault text:nil nextStep:112];
        }else if(step==112){self.failingList.failWrites=NO;[catalog addColor:nil];[self waitForStep:113 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==113){[self invokeAlertStyle:UIAlertActionStyleDefault text:@"Added" nextStep:114];
        }else if(step==114){
            NSString *path=[self.failingList valueForKey:@"fileName"];UIColorList *saved=[[UIColorList alloc]initWithName:self.failingList.name fromFile:path];NSArray *expectedKeys=[self.catalogSnapshot[@"keys"]arrayByAddingObject:@"Added"],*expectedValues=[self.catalogSnapshot[@"values"]arrayByAddingObject:self.catalogSnapshot[@"color"]],*persistedValues=[self.catalogSnapshot[@"persistedValues"]arrayByAddingObject:self.catalogSnapshot[@"persistedValues"][0]];BOOL same=catalog.currentColorList==self.failingList&&[UIColorList colorListNamed:self.failingList.name]==self.failingList&&self.failingList.allKeys==self.catalogSnapshot[@"keysIdentity"]&&[self.failingList.allKeys isEqual:expectedKeys]&&[saved.allKeys isEqual:expectedKeys]&&self.listNotifications==1&&self.actions==0&&self.notifications==0;
            for(NSUInteger index=0;index<expectedKeys.count;index++){NSString *key=expectedKeys[index];same=same&&UIInteractionExactColor([self.failingList colorValueWithKey:key],expectedValues[index])&&UIInteractionExactColor([saved colorValueWithKey:key],persistedValues[index]);}
            [self record:@"Add succeeds after failure with stable attached identity one notification and exact saved colors" passed:same&&UIInteractionExactColor([self.failingList colorValueWithKey:@"Added"],self.catalogSnapshot[@"color"]) details:@{@"modelNotifications":@(self.listNotifications)}];
            [catalog deleteColor:@"Added"];saved=[[UIColorList alloc]initWithName:self.failingList.name fromFile:path];same=catalog.currentColorList==self.failingList&&[UIColorList colorListNamed:self.failingList.name]==self.failingList&&self.failingList.allKeys==self.catalogSnapshot[@"keysIdentity"]&&[self.failingList.allKeys isEqual:self.catalogSnapshot[@"keys"]]&&[saved.allKeys isEqual:self.catalogSnapshot[@"keys"]]&&self.listNotifications==2&&self.actions==0&&self.notifications==0;
            for(NSUInteger index=0;index<[self.catalogSnapshot[@"keys"]count];index++){NSString *key=self.catalogSnapshot[@"keys"][index];same=same&&UIInteractionExactColor([self.failingList colorValueWithKey:key],expectedValues[index])&&UIInteractionExactColor([saved colorValueWithKey:key],persistedValues[index]);}
            [self record:@"Delete succeeds after failure with stable attached identity one additional notification and exact saved colors" passed:same details:@{@"modelNotifications":@(self.listNotifications)}];[self finish];}
    }@catch(NSException *exception){[self record:@"input-state repair fixture exception" passed:NO details:@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""}];[self finish];}
}
- (void)checkScopedMetadata {
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGColorRef cg=CGColorCreate(space,(CGFloat[]){.25,.5,.75,.5});CGColorSpaceRelease(space);
    NSArray *identities=@[@{@"catalogName":@"Scoped Review A 🎨",@"colorName":@"颜色 A"},@{@"catalogName":@"Scoped Review B 🎨",@"colorName":@"颜色 B"},NSNull.null];NSMutableArray<UIColorValue *> *values=[NSMutableArray new];NSMutableArray<NSData *> *archives=[NSMutableArray new];
    for(id identity in identities){UIColorValue *seed=[[UIColorValue alloc]initWithCGColor:cg];if(identity!=NSNull.null)objc_setAssociatedObject(seed,&UIColorArchiveMetadataAssociationKey,identity,OBJC_ASSOCIATION_RETAIN_NONATOMIC);NSData *data=[UIColorArchive archivedDataWithColorValue:seed error:NULL];UIColorValue *parsed=data?[UIColorArchive colorValueFromNSColorArchiveData:data error:NULL]:nil;if(parsed){[values addObject:parsed];[archives addObject:data];}}
    CGColorRelease(cg);if(values.count!=3){[self record:@"named archive fixture decodes its two identities and unnamed fallback" passed:NO details:@{}];return;}
    UIColorPanelWell *well=[[UIColorPanelWell alloc]initWithFrame:CGRectMake(0,0,44,44)];[self.controller.view addSubview:well];
    @try {
        for(NSUInteger recipient=0;recipient<2;recipient++)for(NSUInteger transport=0;transport<2;transport++){
            BOOL valid=YES;NSMutableArray *stages=[NSMutableArray new];
            for(NSUInteger index=0;index<3;index++){
                UIColorValue *input=values[index];UIColor *uiInput=[UIColorArchive colorFromNSColorArchiveData:archives[index] error:NULL];
                if(recipient==0){if(transport==0)self.panel.colorValue=input;else self.panel.color=uiInput;}else{if(transport==0)well.colorValue=input;else well.color=uiInput;}
                UIColorValue *output=recipient==0?self.panel.colorValue:well.colorValue;UIColor *uiOutput=recipient==0?self.panel.color:well.color;
                NSData *valueData=[UIColorArchive archivedDataWithColorValue:output error:NULL],*uiData=[UIColorArchive archivedDataWithColor:uiOutput error:NULL];
                UIColorValue *valueRoundTrip=valueData?[UIColorArchive colorValueFromNSColorArchiveData:valueData error:NULL]:nil,*uiRoundTrip=uiData?[UIColorArchive colorValueFromNSColorArchiveData:uiData error:NULL]:nil;
                id expected=identities[index]==NSNull.null?nil:identities[index];BOOL metadata=YES;
                for(id object in @[output?:NSNull.null,uiOutput?:NSNull.null,valueRoundTrip?:NSNull.null,uiRoundTrip?:NSNull.null]){id actual=objc_getAssociatedObject(object,&UIColorArchiveMetadataAssociationKey);metadata=metadata&&(expected?[expected isEqual:actual]:actual==nil);}
                BOOL exact=UIInteractionExactColor(input,output)&&UIInteractionExactColor(input,valueRoundTrip)&&UIInteractionExactColor(input,uiRoundTrip)&&CGColorEqualToColor(input.CGColor,uiOutput.CGColor);valid=valid&&metadata&&exact;
                [stages addObject:@{@"identity":identities[index],@"metadataPreserved":@(metadata),@"exactNumericColor":@(exact)}];
            }
            [self record:[NSString stringWithFormat:@"%@ %@ assignment preserves named archive identity and clears it for the identical unnamed fallback",recipient==0?@"panel":@"well",transport==0?@"UIColorValue":@"UIColor"] passed:valid details:@{@"stages":stages,@"scope":@"Synthetic named archive records decoded by the production bridge; A to B to unnamed have identical exact RGBA/profile. Public setters/getters and archive round trips, without editing or activating the well."}];
        }
    }@finally{[well removeFromSuperview];}
}
- (void)checkScopedSwatches {
    UIColorPickerSwatchesView *swatches=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectMake(0,0,160,120)];swatches.favoriteLayout.itemSize=CGSizeMake(44,44);swatches.favoriteLayout.itemSpacing=8;swatches.favoriteLayout.sectionInset=UIEdgeInsetsMake(8,8,8,8);[self.controller.view addSubview:swatches];
    @try {
        [swatches setColor:[[UIColorValue alloc]initWithCGColor:UIColor.blackColor.CGColor] forSlot:0];[swatches setColor:[[UIColorValue alloc]initWithCGColor:[UIColor colorWithWhite:1 alpha:.25].CGColor] forSlot:1];[swatches layoutIfNeeded];UICollectionView *collection=swatches.collectionView;[collection layoutIfNeeded];NSMutableArray *states=[NSMutableArray new];BOOL valid=swatches.persistenceKey.length==0;
        for(NSUInteger selected=0;selected<2;selected++){
            [collection selectItemAtIndexPath:[NSIndexPath indexPathForItem:selected inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];[collection layoutIfNeeded];BOOL step=YES;
            for(NSUInteger item=0;item<2;item++){UICollectionViewCell *cell=[collection cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];BOOL expected=item==selected;step=step&&cell.window==self.panel.window&&cell.selected==expected&&((cell.accessibilityTraits&UIAccessibilityTraitSelected)!=0)==expected;}
            valid=valid&&step;[states addObject:@{@"selectedItem":@(selected),@"actualCellAndAXAgree":@(step)}];
        }
        [swatches deleteCurrentColorAndSelectPrevious];[collection layoutIfNeeded];UICollectionViewCell *remaining=[collection cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];BOOL moved=swatches.presentedColors.count==1&&remaining.selected&&(remaining.accessibilityTraits&UIAccessibilityTraitSelected)!=0;
        [collection deselectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO];BOOL cleared=!remaining.selected&&(remaining.accessibilityTraits&UIAccessibilityTraitSelected)==0;
        [self record:@"attached saved-color cells synchronize actual selection and AX after select delete and deselect" passed:valid&&moved&&cleared details:@{@"states":states,@"deleteSelectsPrevious":@(moved),@"deselectionClearsAX":@(cleared),@"scope":@"Real UICollectionView cells and programmatic selection on a local swatches view with no persistence key; no physical tap or spoken VoiceOver claim. Ring appearance is separately visually reviewed."}];
    }@finally{[swatches cancelPendingDrops];[NSObject cancelPreviousPerformRequestsWithTarget:swatches.favoriteStore];[swatches removeFromSuperview];}
}
- (void)runScopedReviewStep:(NSUInteger)step {
    @try {
        UIColorPickerCatalogController *catalog=[self.controller valueForKey:@"catalogController"];
        if(step==200){
            [self.panel.window layoutIfNeeded];[self.controller.view layoutIfNeeded];[self checkScopedMetadata];[self checkScopedSwatches];
            for(NSDictionary *entry in [UIEyedropperValidation grabOffsetCasesInView:self.controller.view])[self record:entry[@"name"] passed:[entry[@"passed"]boolValue] details:entry];
            self.panel.mode=UIColorPanelModeColorList;[self.controller.view layoutIfNeeded];catalog=[self.controller valueForKey:@"catalogController"];
            self.renameOriginal=[[UIColorList alloc]initWithName:[@"ScopedSelection-" stringByAppendingString:NSUUID.UUID.UUIDString]];[self.fixtureLists addObject:self.renameOriginal];
            UIColorValue *a=[[UIColorValue alloc]initWithCGColor:[UIColor colorWithRed:.25 green:.5 blue:.75 alpha:.5].CGColor],*b=[[UIColorValue alloc]initWithCGColor:[UIColor colorWithRed:.75 green:.5 blue:.25 alpha:.5].CGColor];[self.renameOriginal setColorValue:a forKey:@"A"];[self.renameOriginal setColorValue:b forKey:@"B"];NSError *error=nil;
            if(![self.renameOriginal writeToURL:nil error:&error]){[self record:@"scoped selection fixture persists its unique palette" passed:NO details:@{@"error":error.localizedDescription?:@""}];[self finish];return;}
            UIColorList *baseline=[[UIColorList alloc]initWithName:self.renameOriginal.name fromFile:[self.renameOriginal valueForKey:@"fileName"]];self.catalogSnapshot=@{@"keysIdentity":self.renameOriginal.allKeys,@"values":@[a,b,a],@"persistedValues":@[[baseline colorValueWithKey:@"A"],[baseline colorValueWithKey:@"B"],[baseline colorValueWithKey:@"A"]]};
            [catalog installList:self.renameOriginal replacing:nil];[catalog tableView:[catalog valueForKey:@"tableView"] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];self.renameColor=self.panel.colorValue;self.actions=0;self.notifications=0;self.listNotifications=0;
            __weak typeof(self) weakSelf=self;self.listObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIColorListDidChangeNotification object:self.renameOriginal queue:nil usingBlock:^(NSNotification *note){weakSelf.listNotifications++;}];[catalog addColor:nil];[self waitForStep:201 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==201){[self invokeAlertStyle:UIAlertActionStyleDefault text:@"C" nextStep:202];
        }else if(step==202||step==204||step==206||step==208){
            UIColorList *list=catalog.currentColorList;BOOL deleted=step>=206,renamed=step==204||step==208;NSArray *keys=deleted?@[@"A",@"B"]:@[@"A",@"B",@"C"];
            UIColorList *saved=[[UIColorList alloc]initWithName:list.name fromFile:[list valueForKey:@"fileName"]];UITableView *table=[catalog valueForKey:@"tableView"];[table layoutIfNeeded];NSString *selectedKey=[catalog valueForKey:@"selectedKey"];NSInteger selectedIndex=[[catalog valueForKey:@"selectedRowIndex"]integerValue];NSIndexPath *path=table.indexPathForSelectedRow;
            BOOL selection=deleted?!selectedKey&&selectedIndex==-1&&!path:[selectedKey isEqual:@"C"]&&selectedIndex==2&&path&&path.row==2;
            if(!deleted){UITableViewCell *cell=[table cellForRowAtIndexPath:path];selection=selection&&cell.selected&&(cell.accessibilityTraits&UIAccessibilityTraitSelected)!=0;}
            BOOL exact=[list.allKeys isEqual:keys]&&[saved.allKeys isEqual:keys];for(NSUInteger index=0;index<keys.count;index++)exact=exact&&UIInteractionExactColor([list colorValueWithKey:keys[index]],self.catalogSnapshot[@"values"][index])&&UIInteractionExactColor([saved colorValueWithKey:keys[index]],self.catalogSnapshot[@"persistedValues"][index]);
            BOOL identity=(renamed?[list.name isEqual:self.renameName]:list==self.renameOriginal&&list.allKeys==self.catalogSnapshot[@"keysIdentity"])&&[UIColorList colorListNamed:list.name]==list;
            BOOL quiet=self.actions==0&&self.notifications==0&&UIInteractionExactColor(self.panel.colorValue,self.renameColor)&&self.listNotifications==1;
            [self record:step==202?@"Add C updates key row highlight while preserving identity persistence and one list notification":step==204?@"Rename after Add C retains the same selected C and canonical color":step==206?@"Delete C clears key row and highlight while preserving persistence and one list notification":@"Rename after Delete leaves no ghost row or logical selection" passed:selection&&exact&&identity&&quiet details:@{@"selectedKey":selectedKey?:NSNull.null,@"selectedRow":@(selectedIndex),@"selectedPath":path?@(path.row):NSNull.null,@"exactContents":@(exact),@"identity":@(identity),@"modelNotifications":@(self.listNotifications),@"colorActions":@(self.actions),@"colorNotifications":@(self.notifications)}];
            if(step==202||step==206){self.renameName=[list.name stringByAppendingString:@"-renamed"];[catalog renameList:nil];[self waitForStep:step+1 deadline:NSProcessInfo.processInfo.systemUptime+2];}
            else if(step==204){[NSNotificationCenter.defaultCenter removeObserver:self.listObserver];self.renameOriginal=list;NSMutableDictionary *snapshot=[self.catalogSnapshot mutableCopy];snapshot[@"keysIdentity"]=list.allKeys;self.catalogSnapshot=snapshot;self.listNotifications=0;__weak typeof(self) weakSelf=self;self.listObserver=[NSNotificationCenter.defaultCenter addObserverForName:UIColorListDidChangeNotification object:list queue:nil usingBlock:^(NSNotification *note){weakSelf.listNotifications++;}];[catalog confirmDeleteColor:nil];[self waitForStep:205 deadline:NSProcessInfo.processInfo.systemUptime+2];}
            else{self.panel.mode=UIColorPanelModeRGB;[self.controller.view layoutIfNeeded];self.panel.target=nil;self.panel.action=NULL;self.responderController=[UIScopedChangeColorController new];[self.host.rootViewController addChildViewController:self.responderController];self.responderController.view.frame=CGRectMake(0,0,44,44);[self.host.rootViewController.view addSubview:self.responderController.view];[self.responderController didMoveToParentViewController:self.host.rootViewController];self.responderView=[[UIScopedChangeColorView alloc]initWithFrame:self.responderController.view.bounds];[self.responderController.view addSubview:self.responderView];[self waitForStep:210 deadline:NSProcessInfo.processInfo.systemUptime+2];}
        }else if(step==203||step==207){[self invokeAlertStyle:UIAlertActionStyleDefault text:self.renameName nextStep:step+1];
        }else if(step==205){[self invokeAlertStyle:UIAlertActionStyleDestructive text:nil nextStep:206];
        }else if(step==210||step==212){
            [self.host makeKeyWindow];UIResponder *responder=step==210?(UIResponder *)self.responderView:self.responderController;BOOL accepted=[responder becomeFirstResponder];NSUInteger before=step==210?self.responderView.changes:self.responderController.changes;self.panel.color=[UIColor colorWithRed:step==210?.125:.375 green:.25 blue:.5 alpha:.75];NSUInteger after=step==210?self.responderView.changes:self.responderController.changes;
            [self record:step==210?@"host UIView first responder receives public panel changeColor before key transfer":@"host UIViewController first responder receives public panel changeColor before key transfer" passed:accepted&&responder.isFirstResponder&&self.host.isKeyWindow&&after==before+1 details:@{@"accepted":@(accepted),@"actualFirstResponder":@(responder.isFirstResponder),@"hostKey":@(self.host.isKeyWindow),@"deliveredChanges":@(after-before)}];
            self.hexDraft=[[self.controller valueForKey:@"componentFields"]firstObject];BOOL fieldAccepted=[self.hexDraft becomeFirstResponder];[self record:@"production panel numeric field accepts actual first responder" passed:fieldAccepted details:@{@"hostType":step==210?@"UIView":@"UIViewController"}];if(!fieldAccepted){[self finish];return;}[self waitForStep:step+1 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==211||step==213){
            UIResponder *responder=step==211?(UIResponder *)self.responderView:self.responderController;BOOL retained=responder.isFirstResponder;NSUInteger before=step==211?self.responderView.changes:self.responderController.changes;self.panel.color=self.panel.color;NSUInteger after=step==211?self.responderView.changes:self.responderController.changes;
            [self record:step==211?@"host UIView receives same-color public assignment while actual panel input owns key window":@"host UIViewController receives same-color public assignment while actual panel input owns key window" passed:retained&&responder.isFirstResponder&&self.panel.window.isKeyWindow&&self.hexDraft.isFirstResponder&&after==before+1 details:@{@"hostRetainedActualFirstResponder":@(retained),@"panelFieldFirstResponder":@(self.hexDraft.isFirstResponder),@"panelKey":@(self.panel.window.isKeyWindow),@"deliveredChanges":@(after-before),@"scope":@"Real UIKit responder objects and same-color public assignment in the default continuous mode. This triggers first-responder dispatch without installing a new source, whose established contract cancels panel editing. No direct _sendResponderAction call or fabricated isFirstResponder. If UIKit resigns the host on key transfer, the required route is not established by this fixture."}];
            [self.hexDraft resignFirstResponder];[self waitForStep:step+1 deadline:NSProcessInfo.processInfo.systemUptime+2];
        }else if(step==214){[self finish];}
    }@catch(NSException *exception){[self record:@"scoped-review fixture exception" passed:NO details:@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""}];[self finish];}
}
- (void)finish {
    self.reenterClose=NO;self.pendingHostOverride=nil;self.panel.target=nil;self.panel.action=NULL;
    if(self.colorObserver)[NSNotificationCenter.defaultCenter removeObserver:self.colorObserver];if(self.closeObserver)[NSNotificationCenter.defaultCenter removeObserver:self.closeObserver];if(self.listObserver)[NSNotificationCenter.defaultCenter removeObserver:self.listObserver];self.colorObserver=nil;self.closeObserver=nil;self.listObserver=nil;
    if(self.panel){[self.controller endTransientInteractionsForClose:YES];[self.panel close];UIColor.ignoresAlpha=self.oldIgnoresAlpha;}
    NSMutableArray<NSString *> *scopedPaths=[NSMutableArray new];if(self.scopedReviewRepairs)for(UIColorList *list in self.fixtureLists){NSString *path=[list valueForKey:@"fileName"];if(path)[scopedPaths addObject:path];}
    for(UIColorList *list in self.fixtureLists)[list removeFile];[self.fixtureLists removeAllObjects];
    if(self.importFixtureURL)[NSFileManager.defaultManager removeItemAtURL:self.importFixtureURL error:NULL];self.importFixtureURL=nil;
    id originalCatalogSelection=self.savedCatalogSelection;
    if(self.didSaveCatalogSelection){if(self.savedCatalogSelection)[NSUserDefaults.standardUserDefaults setObject:self.savedCatalogSelection forKey:@"UIColorPickerCatalog.SelectedList.v1"];else[NSUserDefaults.standardUserDefaults removeObjectForKey:@"UIColorPickerCatalog.SelectedList.v1"];self.didSaveCatalogSelection=NO;self.savedCatalogSelection=nil;}
    if(self.scopedReviewRepairs&&self.panel){
        [self.responderView resignFirstResponder];[self.responderController resignFirstResponder];[self.responderController willMoveToParentViewController:nil];[self.responderController.view removeFromSuperview];[self.responderController removeFromParentViewController];
        BOOL childRemoved=!self.responderController.view.window&&!self.responderController.parentViewController;self.responderView=nil;self.responderController=nil;[self.host makeKeyWindow];BOOL responderRestored=!self.savedHostResponder||[self.savedHostResponder becomeFirstResponder];responderRestored=responderRestored&&(!self.savedHostResponder||self.savedHostResponder.isFirstResponder);self.savedHostResponder=nil;
        BOOL removed=YES;for(NSString *path in scopedPaths)removed=removed&&![NSFileManager.defaultManager fileExistsAtPath:path];id restoredSelection=[NSUserDefaults.standardUserDefaults objectForKey:@"UIColorPickerCatalog.SelectedList.v1"];BOOL preferenceRestored=originalCatalogSelection?[originalCatalogSelection isEqual:restoredSelection]:restoredSelection==nil;
        [self record:@"scoped fixture restores host children responder alpha preference and temporary palette files" passed:self.host.isKeyWindow&&childRemoved&&responderRestored&&removed&&preferenceRestored&&UIColor.ignoresAlpha==self.oldIgnoresAlpha details:@{@"hostKey":@(self.host.isKeyWindow),@"childRemoved":@(childRemoved),@"originalResponderRestored":@(responderRestored),@"paletteFilesRemoved":@(removed),@"catalogPreferenceRestored":@(preferenceRestored),@"alphaPolicyRestored":@(UIColor.ignoresAlpha==self.oldIgnoresAlpha)}];
    }
    NSString *scope=self.scopedReviewRepairs?@"Current scoped review repairs only: Add C/Rename and Delete/Rename selection with exact in-memory and archive-baseline persistence plus list/color notifications; real local UICollectionView cell selection and AX traits without a persistence key; named metadata through both public color transports and archive; real host UIView/UIViewController first responders before/after an actual panel field makes its window key; bounded sampler grab-offset cases. Attached UIAlertAction stored handlers, collection selections and recognizer states are programmatic, not physical input. No old seven-case rerun, spoken VoiceOver, screenshot archive or global accessibility settings.":self.inputStateRepairs?@"Seven current defects only: HSB achromatic state and synchronous host override; Hex ASCII validation/drafts; New/import/Rename search; failed Add/menu Delete/swipe Delete atomicity and subsequent successful Add/Delete persistence; pencil touch-end preview recorded as requiring native acceptance; actual Tab first responder and toolbar arrows; Reduce Motion layer end state only when the current preference is enabled. Uses production actions and real attached alerts with test-only stored handler invocation after dismissal. No manufactured UITouch, physical touch/key delivery, pointer hover, spoken VoiceOver, locale matrix or system accessibility preference changes.":@"Finite actual UIWindow hit testing and appearance transitions; production Spectrum sampling, known image pixels, exact rename selection/persistence and programmatic overlapping production slider drag/end/cancel calls. Rename invokes the attached real UIAlertAction stored handler through test-only KVC. Does not synthesize UITouch, physically tap alerts, verify spoken VoiceOver or substitute for actual touch acceptance.";
    NSDictionary *result=@{@"passed":@(self.failures==0),@"caseCount":@(self.cases.count),@"failureCount":@(self.failures),@"cases":self.cases?:@[],@"scope":scope,@"readinessPolicy":@"At most two seconds of 50ms main-queue polling per owned UIKit transition; no nested run loop or simulator preference changes."};
    NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];[data writeToURL:self.outputURL options:NSDataWritingAtomic error:nil];
}
@end

// A finite, attached embedded-controller fixture. Short main-queue boundaries
// observe presentation separately from the synchronously committed color.
// It never changes global motion, language, alpha-policy or persistence settings.
@interface UISliderAnimationRunner : NSObject <UIColorPanelViewControllerDelegate>
@property(nonatomic,strong) NSURL *outputURL;
@property(nonatomic,strong) UIWindow *host;
@property(nonatomic,strong) UIViewController *anchor,*holder;
@property(nonatomic,strong) UIColorPanelViewController *controller;
@property(nonatomic,strong) UIColorPanelColorProfile *srgb,*p3;
@property(nonatomic,strong) UIColorValue *initial,*expected,*settledColor,*sampleExpected;
@property(nonatomic,strong) UIGradientSlider *red,*opacity;
@property(nonatomic,strong) UITouchRefinementsRecorder *recorder;
@property(nonatomic,strong) NSMutableArray<NSDictionary *> *cases;
@property(nonatomic,copy) void (^selectionHook)(UIColorPanelViewController *panel);
@property(nonatomic) NSUInteger failures,selections,beforeSelections,settledSelections;
@property(nonatomic) CGFloat startX,finalX,sampleStartX;
@property(nonatomic) NSTimeInterval presentationDeadline;
@property(nonatomic) BOOL finished,waitingForSample,expectsAnimation;
- (void)start;
- (void)runStep:(NSUInteger)step;
- (void)scheduleStep:(NSUInteger)step after:(NSTimeInterval)delay;
- (void)finish;
@end
@implementation UISliderAnimationRunner
- (void)record:(NSString *)name passed:(BOOL)passed details:(NSDictionary *)details {
    NSMutableDictionary *entry=[@{@"name":name,@"passed":@(passed)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[self.cases addObject:entry];if(!passed)self.failures++;
}
- (void)layout {
    [self.controller.view setNeedsLayout];[self.controller.view layoutIfNeeded];
    for(UIGradientSlider *slider in [self.controller valueForKey:@"componentSliders"])[slider layoutIfNeeded];[self.opacity layoutIfNeeded];
}
- (NSDictionary *)position:(UIColorPickerColorSlider *)slider {
    UIView *knob=[slider valueForKey:@"knob"];CALayer *shown=knob.layer.presentationLayer?:knob.layer;
    NSMutableArray<NSString *> *owned=[NSMutableArray new];for(NSString *key in knob.layer.animationKeys)if([key hasPrefix:@"UIColorPicker.position."])[owned addObject:key];
    return @{@"model":@(knob.layer.position.x),@"presentation":@(shown.position.x),@"keys":knob.layer.animationKeys?:@[],@"ownedPositionKeys":owned,@"positionAnimation":@(owned.count>0)};
}
- (BOOL)fieldsMatchColor {
    NSArray<UITextField *> *fields=[self.controller valueForKey:@"componentFields"];const CGFloat *components=CGColorGetComponents(self.controller.selectedColor.CGColor);
    if(fields.count!=3||CGColorGetNumberOfComponents(self.controller.selectedColor.CGColor)!=4)return NO;
    for(NSUInteger i=0;i<3;i++)if(![fields[i].text isEqualToString:[UIColorPanelAppearance formatNumber:components[i]*255 significantDigits:0]])return NO;
    return YES;
}
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {
    self.selections++;
    if(self.selectionHook)self.selectionHook(panel);
    if(self.waitingForSample){
        self.waitingForSample=NO;
        // The callback is inside the host's model update. Observe after that
        // update returns so the explicit presentation transaction can finish.
        dispatch_async(dispatch_get_main_queue(),^{
            if(self.finished)return;
            BOOL final=UIInteractionExactColor(self.controller.selectedColor,self.sampleExpected)&&self.selections==self.beforeSelections+1&&self.opacity==[self.controller valueForKey:@"opacitySlider"]&&fabs(self.opacity.value-CGColorGetAlpha(self.sampleExpected.CGColor))<1e-12;
            [self record:@"eyedropper completion commits its exact source once and retains opacity control" passed:final details:@{@"selections":@(self.selections-self.beforeSelections),@"position":[self position:self.opacity],@"scope":@"Actual public-image picker presentation and production completion; commit is programmatic."}];
            self.finalX=[[self position:self.opacity][@"model"] doubleValue];[self scheduleStep:8 after:.08];
        });
    }
}
- (void)scheduleStep:(NSUInteger)step after:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(delay*NSEC_PER_SEC)),dispatch_get_main_queue(),^{if(!self.finished)[self runStep:step];});
}
- (void)start {
    self.cases=[NSMutableArray new];self.host=UIApplication.sharedApplication.keyWindow;self.anchor=self.host.rootViewController;
    BOOL attached=NSThread.isMainThread&&self.host&&!self.host.hidden&&self.anchor.view.window==self.host&&!self.anchor.presentedViewController;
    [self record:@"animation fixture has an attached idle host" passed:attached details:@{}];if(!attached){[self finish];return;}
    CGColorSpaceRef srgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB),p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    self.srgb=[[UIColorPanelColorProfile alloc]initWithColorSpace:srgb displayName:nil];self.p3=[[UIColorPanelColorProfile alloc]initWithColorSpace:p3 displayName:nil];
    CGFloat components[]={.9,.16,.12,.65};CGColorRef cg=CGColorCreate(srgb,components);self.initial=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);CGColorSpaceRelease(srgb);CGColorSpaceRelease(p3);
    UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeRGB;configuration.showsAlpha=YES;configuration.savedColorsKey=nil;
    self.controller=[[UIColorPanelViewController alloc]initWithColor:self.initial configuration:configuration];self.controller.delegate=self;
    self.holder=[UIViewController new];[self.anchor addChildViewController:self.holder];self.holder.view.frame=self.anchor.view.bounds;self.holder.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.anchor.view addSubview:self.holder.view];[self.holder didMoveToParentViewController:self.anchor];
    [self.holder addChildViewController:self.controller];[self.holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryLarge] forChildViewController:self.controller];self.controller.view.frame=self.holder.view.bounds;self.controller.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.holder.view addSubview:self.controller.view];[self.controller didMoveToParentViewController:self.holder];
    self.opacity=[self.controller valueForKey:@"opacitySlider"];[self layout];self.red=[[self.controller valueForKey:@"componentSliders"]firstObject];self.recorder=[UITouchRefinementsRecorder new];[self.recorder observeSlider:self.red];
    self.expectsAnimation=UIView.areAnimationsEnabled;[self scheduleStep:0 after:.1];
}
- (void)runStep:(NSUInteger)step {
    switch(step){
        case 0:{
            self.startX=[[self position:self.red][@"model"] doubleValue];self.beforeSelections=self.selections;self.expected=[self.initial colorByConvertingToSpace:self.p3.CGColorSpace error:nil];
            NSError *error=nil;BOOL changed=[self.controller selectColorProfile:self.p3 error:&error animated:YES];[self layout];self.finalX=[[self position:self.red][@"model"] doubleValue];
            BOOL final=changed&&!error&&UIInteractionExactColor(self.controller.selectedColor,self.expected)&&CFEqual(self.controller.activeColorProfile.CGColorSpace,self.p3.CGColorSpace)&&CGColorGetAlpha(self.controller.selectedColor.CGColor)==.65&&self.selections==self.beforeSelections+1&&[self fieldsMatchColor];
            [self record:@"animated profile change commits final model profile and text immediately" passed:final details:@{@"selections":@(self.selections-self.beforeSelections),@"position":[self position:self.red]}];[self scheduleStep:1 after:.08];break;
        }
        case 1:{
            NSDictionary *position=[self position:self.red];CGFloat x=[position[@"presentation"]doubleValue];BOOL intermediate=x>MIN(self.startX,self.finalX)+.01&&x<MAX(self.startX,self.finalX)-.01;
            BOOL motion=self.expectsAnimation?([position[@"positionAnimation"]boolValue]&&intermediate):fabs(x-self.finalX)<.01;
            BOOL silent=self.selections==self.beforeSelections+1&&self.recorder.events.count==0&&UIInteractionExactColor(self.controller.selectedColor,self.expected);
            [self record:@"profile presentation moves without interpolated model or input events" passed:motion&&silent details:@{@"position":position,@"start":@(self.startX),@"end":@(self.finalX),@"expectsAnimation":@(self.expectsAnimation),@"inputEvents":self.recorder.events}];[self scheduleStep:2 after:.45];break;
        }
        case 2:{
            NSDictionary *position=[self position:self.red];BOOL settled=fabs([position[@"presentation"]doubleValue]-self.finalX)<.01&&![position[@"positionAnimation"]boolValue]&&UIInteractionExactColor(self.controller.selectedColor,self.expected)&&self.selections==self.beforeSelections+1;
            [self record:@"profile animation settles without another color callback" passed:settled details:position];
            self.beforeSelections=self.selections;BOOL same=[self.controller selectColorProfile:self.p3 error:nil animated:YES];[self layout];position=[self position:self.red];
            [self record:@"same profile has no manufactured position transition" passed:same&&self.selections==self.beforeSelections&&![position[@"positionAnimation"]boolValue]&&fabs([position[@"presentation"]doubleValue]-self.finalX)<.01 details:position];
            UIColorValue *converted=[self.controller.selectedColor colorByConvertingToSpace:self.srgb.CGColorSpace error:nil];BOOL direct=[self.controller selectColorProfile:self.srgb error:nil];[self layout];position=[self position:self.red];UIColorValue *before=self.controller.selectedColor;
            self.red.value=.7;[self.red layoutIfNeeded];NSDictionary *setter=[self position:self.red];BOOL setterSilent=UIInteractionExactColor(before,self.controller.selectedColor)&&self.selections==self.beforeSelections+1&&![setter[@"positionAnimation"]boolValue];[self.controller updateControls];[self layout];
            [self record:@"public profile API and ordinary value setter remain static" passed:direct&&UIInteractionExactColor(converted,self.controller.selectedColor)&&![position[@"positionAnimation"]boolValue]&&setterSilent details:@{@"profile":position,@"setter":setter}];
            self.beforeSelections=self.selections;const CGFloat *components=CGColorGetComponents(self.controller.selectedColor.CGColor);CGFloat target[]={.4,components[1],components[2],components[3]};CGColorRef cg=CGColorCreate(self.controller.activeColorProfile.CGColorSpace,target);self.expected=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);
            CGFloat h=self.red.bounds.size.height,w=self.red.bounds.size.width;[self.red dragChangedAtPoint:CGPointMake(h*.5+(w-h)*.4,h*.5)];[self.red dragEnded];[self layout];position=[self position:self.red];
            BOOL drag=UIInteractionComponents(self.controller.selectedColor,target,1e-12)&&CFEqual(self.controller.activeColorProfile.CGColorSpace,self.srgb.CGColorSpace)&&self.selections==self.beforeSelections+1&&self.recorder.begins==1&&self.recorder.changes==1&&self.recorder.ends==1&&!self.red.active&&![position[@"positionAnimation"]boolValue];
            [self record:@"ordinary programmatic drag follows directly with one input lifecycle" passed:drag details:@{@"position":position,@"inputEvents":[self.recorder.events copy],@"selections":@(self.selections-self.beforeSelections)}];
            self.beforeSelections=self.selections;[self.controller selectColorProfile:self.p3 error:nil animated:YES];[self layout];[self scheduleStep:3 after:.08];break;
        }
        case 3:{
            NSDictionary *before=[self position:self.red];[self.controller selectColorProfile:self.srgb error:nil animated:YES];[self layout];NSDictionary *after=[self position:self.red];NSArray<NSString *> *oldKeys=before[@"ownedPositionKeys"],*newKeys=after[@"ownedPositionKeys"];
            BOOL retained=oldKeys.count>0;for(NSString *key in oldKeys)retained=retained&&[newKeys containsObject:key];
            BOOL retarget=self.expectsAnimation?retained&&newKeys.count>oldKeys.count&&fabs([after[@"presentation"]doubleValue]-[before[@"presentation"]doubleValue])<.5:![after[@"positionAnimation"]boolValue];
            [self record:@"quick profile reversal preserves presentation and the existing curve" passed:retarget&&self.selections==self.beforeSelections+2 details:@{@"before":before,@"after":after}];[self scheduleStep:4 after:.08];break;
        }
        case 4:{
            self.beforeSelections=self.selections;NSUInteger begins=self.recorder.begins,changes=self.recorder.changes,ends=self.recorder.ends;CGFloat h=self.red.bounds.size.height,w=self.red.bounds.size.width;
            [self.red dragChangedAtPoint:CGPointMake(h*.5+(w-h)*.55,h*.5)];[self.red dragEnded];[self layout];NSDictionary *position=[self position:self.red];self.settledColor=self.controller.selectedColor;self.settledSelections=self.selections;
            // Core Animation can still expose the preceding committed presentation
            // during this synchronous drag call. Its owned keys must be gone now;
            // the following asynchronous step checks the visible final position.
            BOOL takeover=fabs(self.red.value-.55)<1e-12&&![position[@"positionAnimation"]boolValue]&&self.selections==self.beforeSelections+1&&self.recorder.begins==begins+1&&self.recorder.changes==changes+1&&self.recorder.ends==ends+1;
            [self record:@"programmatic drag takes over an active profile animation" passed:takeover details:@{@"position":position,@"selections":@(self.selections-self.beforeSelections)}];[self scheduleStep:5 after:.45];break;
        }
        case 5:{
            NSDictionary *position=[self position:self.red];BOOL stable=UIInteractionExactColor(self.controller.selectedColor,self.settledColor)&&self.selections==self.settledSelections&&fabs(self.red.value-.55)<1e-12&&![position[@"positionAnimation"]boolValue]&&fabs([position[@"presentation"]doubleValue]-[position[@"model"]doubleValue])<.01;
            [self record:@"taken-over slider has no delayed return or color callback" passed:stable details:position];
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(8,8),YES,1);[[UIColor colorWithRed:.22 green:.46 blue:.68 alpha:1]setFill];UIRectFill(CGRectMake(0,0,8,8));self.controller.samplingImage=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();self.controller.allowsApplicationSampling=YES;
            self.sampleStartX=[[self position:self.opacity][@"model"] doubleValue];self.presentationDeadline=NSProcessInfo.processInfo.systemUptime+2;[[self.controller valueForKey:@"sampleButton"]sendActionsForControlEvents:UIControlEventTouchUpInside];[self scheduleStep:6 after:.4];break;
        }
        case 6:{
            UIEyedropperViewController *picker=[self.controller valueForKey:@"activeSamplingController"];BOOL presented=picker&&picker.viewIfLoaded.window==self.host&&!picker.isBeingPresented&&!picker.transitionCoordinator;
            if(!presented&&NSProcessInfo.processInfo.systemUptime<self.presentationDeadline){[self scheduleStep:6 after:.05];break;}
            [self record:@"public-image eyedropper is presented through the production sample action" passed:presented details:@{}];if(!presented){[self finish];break;}
            [picker moveToPoint:CGPointMake(CGRectGetMidX(picker.view.bounds),CGRectGetMidY(picker.view.bounds))];self.sampleExpected=picker.selectedColor;self.beforeSelections=self.selections;self.waitingForSample=YES;[picker commit];[self scheduleStep:10 after:2];break;
        }
        case 8:{
            NSDictionary *position=[self position:self.opacity];CGFloat x=[position[@"presentation"]doubleValue];BOOL intermediate=x>MIN(self.sampleStartX,self.finalX)+.01&&x<MAX(self.sampleStartX,self.finalX)-.01;
            BOOL motion=self.expectsAnimation?[position[@"positionAnimation"]boolValue]&&intermediate:fabs(x-self.finalX)<.01;
            [self record:@"eyedropper result animates the retained opacity presentation" passed:motion&&self.selections==self.beforeSelections+1 details:@{@"position":position,@"start":@(self.sampleStartX),@"end":@(self.finalX)}];[self scheduleStep:9 after:.45];break;
        }
        case 9:{
            NSDictionary *position=[self position:self.opacity];BOOL settled=!self.controller.presentedViewController&&![self.controller valueForKey:@"activeSamplingController"]&&UIInteractionExactColor(self.controller.selectedColor,self.sampleExpected)&&self.selections==self.beforeSelections+1&&![position[@"positionAnimation"]boolValue]&&fabs([position[@"presentation"]doubleValue]-[position[@"model"]doubleValue])<.01;
            [self record:@"eyedropper animation settles with one final color and no owned presentation" passed:settled details:position];[self scheduleStep:11 after:0];break;
        }
        case 10:if(self.waitingForSample){[self record:@"eyedropper completion arrived within its bounded window" passed:NO details:@{}];[self finish];}break;
        case 11:{
            UIColorPickerColorSlider *red=[[self.controller valueForKey:@"componentSliders"]firstObject];UIColorValue *beforeColor=self.controller.selectedColor;NSUInteger beforeSelections=self.selections;
            red.value=.2;[red layoutIfNeeded];CGFloat start=[[self position:red][@"model"] doubleValue];
            [UIColorPickerColorSlider animateChangesToSliders:@[red] updates:^{red.value=.8;[UIColorPickerColorSlider animateChangesToSliders:@[red] updates:^{red.value=.4;}];}];
            NSDictionary *position=[self position:red];NSArray<NSString *> *keys=position[@"ownedPositionKeys"];UIView *knob=[red valueForKey:@"knob"];CABasicAnimation *animation=keys.count?(CABasicAnimation *)[knob.layer animationForKey:keys.firstObject]:nil;NSValue *offset=animation.fromValue;
            BOOL delta=self.expectsAnimation?keys.count==1&&animation.additive&&fabs(offset.CGPointValue.x-(start-[position[@"model"]doubleValue]))<.01:keys.count==0;
            [self record:@"nested slider batches contribute only their outer model delta" passed:delta&&red.window==self.host&&fabs(red.value-.4)<1e-12&&self.selections==beforeSelections&&UIInteractionExactColor(self.controller.selectedColor,beforeColor) details:@{@"position":position,@"start":@(start),@"delta":offset?@[@(offset.CGPointValue.x),@(offset.CGPointValue.y)]:(id)NSNull.null}];
            [self.controller updateControls];self.controller.selectedColor=self.initial;[self layout];
            NSMutableArray<UIColorPickerColorSlider *> *candidates=[[self.controller valueForKey:@"componentSliders"]mutableCopy];[candidates addObject:self.opacity];UIColorValue *override=self.initial;beforeSelections=self.selections;
            self.selectionHook=^(UIColorPanelViewController *panel){panel.selectedColor=override;};BOOL selected=[self.controller selectColorProfile:self.p3 error:nil animated:YES];self.selectionHook=nil;[self layout];[candidates addObjectsFromArray:[self.controller valueForKey:@"componentSliders"]];
            BOOL quiet=YES;NSMutableArray *positions=[NSMutableArray new];for(UIColorPickerColorSlider *candidate in candidates){NSDictionary *state=[self position:candidate];quiet=quiet&&![state[@"positionAnimation"]boolValue];[positions addObject:state];}
            [self record:@"synchronous host color override cancels every candidate bridge animation" passed:selected&&quiet&&UIInteractionExactColor(self.controller.selectedColor,override)&&self.selections==beforeSelections+1&&CGColorGetAlpha(self.controller.selectedColor.CGColor)==.65 details:@{@"positions":positions,@"selections":@(self.selections-beforeSelections)}];[self scheduleStep:12 after:0];break;
        }
        case 12:{
            self.controller.selectedColor=self.initial;[self layout];NSMutableArray<UIColorPickerColorSlider *> *candidates=[[self.controller valueForKey:@"componentSliders"]mutableCopy];[candidates addObject:self.opacity];NSUInteger beforeSelections=self.selections,generation=[[self.controller valueForKey:@"transientGeneration"]unsignedIntegerValue];UIColorValue *expected=[self.initial colorByConvertingToSpace:self.p3.CGColorSpace error:nil];
            self.selectionHook=^(UIColorPanelViewController *panel){[panel endTransientInteractionsForClose:YES];};BOOL selected=[self.controller selectColorProfile:self.p3 error:nil animated:YES];self.selectionHook=nil;[self layout];[candidates addObjectsFromArray:[self.controller valueForKey:@"componentSliders"]];
            BOOL quiet=YES;NSMutableArray *positions=[NSMutableArray new];for(UIColorPickerColorSlider *candidate in candidates){NSDictionary *state=[self position:candidate];quiet=quiet&&![state[@"positionAnimation"]boolValue];[positions addObject:state];}
            [self record:@"synchronous host close cancels every candidate bridge animation" passed:selected&&quiet&&UIInteractionExactColor(self.controller.selectedColor,expected)&&self.selections==beforeSelections+1&&[[self.controller valueForKey:@"transientGeneration"]unsignedIntegerValue]!=generation details:@{@"positions":positions,@"selections":@(self.selections-beforeSelections)}];[self finish];break;
        }
    }
}
- (void)finish {
    if(self.finished)return;self.finished=YES;self.selectionHook=nil;self.controller.delegate=nil;[self.controller endTransientInteractionsForClose:YES];
    [self.red removeTarget:self.recorder action:NULL forControlEvents:UIControlEventAllEvents];
    if(self.controller.parentViewController){[self.controller willMoveToParentViewController:nil];[self.controller.view removeFromSuperview];[self.controller removeFromParentViewController];}
    if(self.holder.parentViewController){[self.holder willMoveToParentViewController:nil];[self.holder.view removeFromSuperview];[self.holder removeFromParentViewController];}
    NSDictionary *result=@{@"passed":@(self.failures==0),@"failureCount":@(self.failures),@"caseCount":@(self.cases.count),@"cases":self.cases?:@[],@"reduceMotion":@(UIAccessibilityIsReduceMotionEnabled()),@"animationsEnabled":@(UIView.areAnimationsEnabled),@"scope":@"Finite asynchronous attached embedded-controller transactions and explicit presentation-layer observations. Profile menu-core action, public profile API, setters, drag/end, rapid reversal, drag takeover, nested batches, synchronous host color override/close, and an actual public-image eyedropper presentation/production completion. Input and commit are programmatic, not physical touch. No timing-equivalence claim against the original binary, private capture, spoken VoiceOver, global preference changes or broad static/localization rerun."};
    [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:self.outputURL options:NSDataWritingAtomic error:nil];
}
@end

@implementation UIColorPanelUIFidelityValidation
+ (BOOL)runCircleRefinementsWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray new];__block BOOL passed=YES;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL valid,NSDictionary *details){passed=passed&&valid;NSMutableDictionary *entry=[@{@"name":name,@"passed":@(valid)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];};
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIViewController *anchor=window.rootViewController;
    if([anchor isKindOfClass:UINavigationController.class])anchor=((UINavigationController *)anchor).visibleViewController;
    BOOL attached=NSThread.isMainThread&&window&&!window.hidden&&anchor.view.window==window&&!anchor.presentedViewController;
    record(@"attached host without an active presentation",attached,@{});
    if(attached){
        UIViewController *holder=[UIViewController new];
        @try {
            [anchor addChildViewController:holder];holder.view.frame=CGRectMake(0,0,320,260);[anchor.view addSubview:holder.view];[holder didMoveToParentViewController:anchor];
            UIViewController *elements=[UIViewController new];
            @try {
                [holder addChildViewController:elements];elements.view.frame=holder.view.bounds;[holder.view addSubview:elements.view];[elements didMoveToParentViewController:holder];
                UIColorPickerGridView *grid=[[UIColorPickerGridView alloc]initWithFrame:CGRectMake(12,10,288,240)];[elements.view addSubview:grid];[grid layoutIfNeeded];
                NSArray<UIColorValue *> *colors=[grid valueForKey:@"colors"];NSArray<UIAccessibilityElement *> *cells=grid.accessibilityElements;NSUInteger index=54;
                BOOL hasCells=colors.count==120&&cells.count==120;record(@"Grid fixture exposes the original 120 cells",hasCells,@{@"colors":@(colors.count),@"elements":@(cells.count)});
                if(hasCells)for(NSNumber *alpha in @[@0,@.35,@1])for(NSNumber *accessibility in @[@NO,@YES]){
                    grid.selectedColor=[colors[11]copyWithAlpha:alpha.doubleValue];
                    UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];
                    [grid addTarget:recorder action:@selector(began:) forControlEvents:UIControlEventEditingDidBegin];[grid addTarget:recorder action:@selector(changed:) forControlEvents:UIControlEventValueChanged];[grid addTarget:recorder action:@selector(ended:) forControlEvents:UIControlEventEditingDidEnd];
                    BOOL accepted=YES;
                    @try {
                        if(accessibility.boolValue)accepted=[cells[index]accessibilityActivate];
                        else [grid sampleAtPoint:CGPointMake(((index%12)+.5)*grid.bounds.size.width/12,((index/12)+.5)*grid.bounds.size.height/10)];
                    }@finally{[grid removeTarget:recorder action:NULL forControlEvents:UIControlEventAllEvents];}
                    UIColorValue *expected=[colors[index]copyWithAlpha:alpha.doubleValue];NSUInteger visibleIndex=[[grid valueForKey:@"selectedIndex"]unsignedIntegerValue],selectedCount=0;BOOL cellTraits=YES;
                    for(UIAccessibilityElement *cell in cells){if(cell.accessibilityTraits&UIAccessibilityTraitSelected)selectedCount++;cellTraits=cellTraits&&(cell.accessibilityTraits&UIAccessibilityTraitButton)!=0&&cell.accessibilityLabel.length>0;}
                    BOOL color=grid.sampledColor&&CGColorEqualToColor(expected.CGColor,grid.sampledColor.CGColor)&&CGColorEqualToColor(expected.CGColor,grid.selectedColor.CGColor);
                    BOOL events=recorder.changes==1&&recorder.begins==(accessibility.boolValue?1:0)&&recorder.ends==(accessibility.boolValue?1:0)&&!grid.active;
                    BOOL selection=visibleIndex==index&&selectedCount==(alpha.doubleValue==1?1:0)&&cellTraits;
                    record(accessibility.boolValue?@"Grid AX activation preserves alpha and its distinct selected trait":@"Grid common touch-sampling core preserves alpha and its visible selection",accepted&&color&&events&&selection,@{@"alpha":alpha,@"visibleIndex":@(visibleIndex),@"axSelectedCount":@(selectedCount),@"canonicalAndSample":@(color),@"events":recorder.events,@"input":accessibility.boolValue?@"UIAccessibilityElement.accessibilityActivate":@"Production sampleAtPoint shared by begin/continueTracking"});
                }
                if(hasCells){
                    UIColorValue *initial=[[UIColorValue alloc]initWithCGColor:[UIColor colorWithDisplayP3Red:.2 green:.4 blue:.6 alpha:.35].CGColor];grid.selectedColor=initial;
                    CGColorRef converted=CGColorCreateCopyByMatchingToColorSpace(CGColorGetColorSpace(initial.CGColor),kCGRenderingIntentPerceptual,colors[index].CGColor,NULL);
                    UIColorValue *expected=converted?[[[UIColorValue alloc]initWithCGColor:converted]copyWithAlpha:.35]:nil;if(converted)CGColorRelease(converted);
                    [grid sampleAtPoint:CGPointMake(((index%12)+.5)*grid.bounds.size.width/12,((index/12)+.5)*grid.bounds.size.height/10)];
                    BOOL profile=expected&&CFEqual(CGColorGetColorSpace(initial.CGColor),CGColorGetColorSpace(grid.selectedColor.CGColor))&&CGColorEqualToColor(expected.CGColor,grid.selectedColor.CGColor)&&CGColorEqualToColor(expected.CGColor,grid.sampledColor.CGColor);
                    record(@"Grid converts a swatch into the current Display P3 profile before retaining alpha",profile,@{@"alpha":@(CGColorGetAlpha(grid.selectedColor.CGColor)),@"profileAndSample":@(profile)});
                }
                [grid removeFromSuperview];
                UIColorPickerSliderKnob *knob=[[UIColorPickerSliderKnob alloc]initWithFrame:CGRectMake(20,20,36,36)];knob.selectedColor=[UIColor colorWithRed:.9 green:.2 blue:.1 alpha:.35];[elements.view addSubview:knob];
                NSArray<NSNumber *> *styles=@[@0];if(@available(iOS 13.0,*))styles=@[@(UIUserInterfaceStyleLight),@(UIUserInterfaceStyleDark)];
                for(NSNumber *style in styles){
                    if(@available(iOS 13.0,*))[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:style.integerValue] forChildViewController:elements];
                    [elements.view layoutIfNeeded];[knob layoutIfNeeded];CALayer *outer=[knob valueForKey:@"whiteCircle"],*inner=[knob valueForKey:@"colorCircle"];
                    UIColor *expected=UIColor.whiteColor;BOOL traits=YES;
                    if(@available(iOS 13.0,*)){expected=[UIColor.systemBackgroundColor resolvedColorWithTraitCollection:knob.traitCollection];traits=knob.traitCollection.userInterfaceStyle==style.integerValue;}
                    BOOL semantic=outer.backgroundColor&&CGColorEqualToColor(outer.backgroundColor,expected.CGColor);
                    BOOL composition=inner.backgroundColor&&CGColorEqualToColor(inner.backgroundColor,knob.selectedColor.CGColor)&&CGRectEqualToRect(outer.frame,CGRectInset(knob.bounds,2,2))&&CGRectEqualToRect(inner.frame,CGRectInset(outer.bounds,3,3));
                    record(@"Slider knob resolves and refreshes its semantic outer circle",traits&&semantic&&composition,@{@"style":style,@"semanticColor":@(semantic),@"selectedAlphaAndPadding":@(composition),@"fallback":style.integerValue==0?@"iOS12 white":@"systemBackgroundColor in current view traits"});
                }
                // One three-pixel source makes fit geometry independent of image
                // interpolation, orientation and a broad pixel-sampling matrix.
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(3,1),YES,1);[UIColor.redColor setFill];UIRectFill(CGRectMake(0,0,1,1));[UIColor.greenColor setFill];UIRectFill(CGRectMake(1,0,1,1));[UIColor.blueColor setFill];UIRectFill(CGRectMake(2,0,1,1));UIImage *source=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();
                UIColorValue *lensColor=[[UIColorValue alloc]initWithCGColor:[UIColor.redColor colorWithAlphaComponent:.35].CGColor];
                UIColorPickerSpectrum *spectrum=[[UIColorPickerSpectrum alloc]initWithFrame:CGRectMake(0,0,144,144)];UIColorPickerWheelView *wheel=[[UIColorPickerWheelView alloc]initWithFrame:spectrum.frame];UIColorPickerUserView *image=[[UIColorPickerUserView alloc]initWithFrame:CGRectMake(0,0,240,120)];
                UITouchRefinementsRecorder *lensRecorder=[UITouchRefinementsRecorder new];
                for(UIControl *control in @[spectrum,wheel,image]){[control addTarget:lensRecorder action:@selector(changed:) forControlEvents:UIControlEventAllEvents];[elements.view addSubview:control];}
                spectrum.selectedColor=lensColor;wheel.colorValue=lensColor;image.image=source;image.contentMode=UIViewContentModeScaleAspectFit;image.selectedColor=lensColor;image.samplePoint=CGPointMake(40,60);
                BOOL common=lensRecorder.changes==0;NSMutableArray *lensDetails=[NSMutableArray new];
                for(UIControl *control in @[spectrum,wheel,image]){
                    [control layoutIfNeeded];UIColorPickerSpectrumLens *lens=[control valueForKey:@"lensLayer"];CALayer *outer=lens.sublayers.firstObject,*inner=lens.sublayers.lastObject;
                    BOOL valid=[lens isKindOfClass:UIColorPickerSpectrumLens.class]&&!lens.hidden&&lens.sublayers.count==2&&outer.superlayer==lens&&inner.superlayer==lens&&CGSizeEqualToSize(lens.bounds.size,CGSizeMake(33,33))&&CGRectEqualToRect(outer.frame,lens.bounds)&&CGRectEqualToRect(inner.frame,CGRectInset(lens.bounds,3,3))&&outer.backgroundColor&&inner.backgroundColor&&CGColorEqualToColor(outer.backgroundColor,lensColor.CGColor)&&CGColorEqualToColor(inner.backgroundColor,lensColor.CGColor)&&fabs(outer.shadowOpacity-.33)<1e-6&&outer.shadowRadius==2&&CGSizeEqualToSize(outer.shadowOffset,CGSizeZero)&&inner.shadowOpacity==0;
                    common=common&&valid;[lensDetails addObject:@{@"control":NSStringFromClass(control.class),@"passed":@(valid),@"siblings":@(lens.sublayers.count),@"alpha":@(CGColorGetAlpha(lensColor.CGColor))}];
                }
                common=common&&lensRecorder.changes==0;record(@"Spectrum wheel and image share the alpha-preserving sibling lens without actions",common,@{@"layers":lensDetails,@"eventCount":@(lensRecorder.changes)});
                image.samplePoint=CGPointMake(-1,-1);BOOL rejected=![image sampleAtPoint:CGPointMake(120,1)]&&image.sampledColor==nil&&lensRecorder.changes==0;
                BOOL sampled=[image sampleAtPoint:CGPointMake(40,60)];UIColorValue *pixel=image.sampledColor;NSUInteger events=lensRecorder.changes;CGPoint before=image.samplePoint;
                image.frame=CGRectMake(0,0,120,180);[image layoutIfNeeded];CGPoint after=image.samplePoint;
                BOOL reproject=sampled&&pixel&&events==1&&image.sampledColor==pixel&&lensRecorder.changes==events&&fabs(before.x-40)<1e-6&&fabs(before.y-60)<1e-6&&fabs(after.x-20)<1e-6&&fabs(after.y-90)<1e-6;
                UIColorValue *replacement=[[UIColorValue alloc]initWithCGColor:[UIColor.blueColor colorWithAlphaComponent:.6].CGColor];image.selectedColor=replacement;[image layoutIfNeeded];UIColorPickerSpectrumLens *imageLens=[image valueForKey:@"lensLayer"];
                BOOL indicatorOnly=image.sampledColor==pixel&&CGPointEqualToPoint(image.samplePoint,after)&&lensRecorder.changes==events&&CGColorEqualToColor(imageLens.sublayers.firstObject.backgroundColor,replacement.CGColor)&&CGColorEqualToColor(imageLens.sublayers.lastObject.backgroundColor,replacement.CGColor);
                image.selectedColor=nil;[image layoutIfNeeded];BOOL standalone=!imageLens.hidden&&image.sampledColor==pixel&&lensRecorder.changes==events&&CGColorEqualToColor(imageLens.sublayers.firstObject.backgroundColor,pixel.CGColor)&&CGColorEqualToColor(imageLens.sublayers.lastObject.backgroundColor,pixel.CGColor);
                record(@"AspectFit rejects letterbox input and reprojects the indicator without resampling",rejected&&reproject&&indicatorOnly&&standalone,@{@"letterboxRejectedWithoutAction":@(rejected),@"resizedPoint":NSStringFromCGPoint(after),@"sampleUnchangedOnResize":@(reproject),@"selectedColorChangesOnlyLens":@(indicatorOnly),@"standaloneSamplerUsesSampledColor":@(standalone),@"eventCount":@(lensRecorder.changes)});
                for(UIControl *control in @[spectrum,wheel,image])[control removeTarget:lensRecorder action:NULL forControlEvents:UIControlEventAllEvents];
            }@finally{
                [holder setOverrideTraitCollection:nil forChildViewController:elements];[elements willMoveToParentViewController:nil];[elements.view removeFromSuperview];[elements removeFromParentViewController];
            }
#if UICOLORPANEL_ENABLE_PENCILS
            NSArray *pencilFixtures=@[@{@"category":UIContentSizeCategoryLarge,@"switch":@YES},@{@"category":UIContentSizeCategoryAccessibilityExtraExtraExtraLarge,@"switch":@YES},@{@"category":UIContentSizeCategoryLarge,@"switch":@NO}];
            for(NSDictionary *fixture in pencilFixtures){
                UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModePencils;configuration.savedColorsKey=nil;configuration.use_spi=NO;configuration.showsAlpha=YES;
                UIColorPanelViewController *content=[[UIColorPanelViewController alloc]initWithColor:[[UIColorValue alloc]initWithCGColor:UIColor.redColor.CGColor] configuration:configuration];content.pickerMask=UIColorPanelCrayonModeMask|([fixture[@"switch"]boolValue]?UIColorPanelGridModeMask:0);
                @try {
                    [holder addChildViewController:content];[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:fixture[@"category"]] forChildViewController:content];content.view.frame=holder.view.bounds;[holder.view addSubview:content.view];[content didMoveToParentViewController:holder];
                    UIColorPickerPencilView *pencils=[content valueForKey:@"pencilContainer"];UILabel *name=[content valueForKey:@"pencilNameLabel"];NSArray<UIColoredPencil *> *items=[pencils _pencils];UIColoredPencil *longest=nil;CGFloat longestWidth=-1;
                    for(UIColoredPencil *item in items){CGFloat width=[item.accessibilityLabel sizeWithAttributes:@{NSFontAttributeName:name.font}].width;if(width>longestWidth){longest=item;longestWidth=width;}}
                    if(longest)content.selectedColor=longest.color;
                    [content.view setNeedsLayout];[content.view layoutIfNeeded];
                    UIView *canvas=[content valueForKey:@"rootStack"],*provider=[content valueForKey:@"providerHost"],*footer=[content valueForKey:@"footer"],*opacity=[content valueForKey:@"opacityRow"];UIScrollView *overflow=[content valueForKey:@"overflowScroll"];UISegmentedControl *mode=[content valueForKey:@"discreteModeControl"];
                    CGRect nameRect=[name convertRect:name.bounds toView:canvas],artRect=[pencils convertRect:pencils.bounds toView:canvas],providerRect=[provider convertRect:provider.bounds toView:canvas];CGFloat tolerance=1/window.screen.scale;
                    CGFloat minimumScale=MIN(1,MAX(0,provider.bounds.size.width-24)/228),scale=hypot(pencils.transform.a,pencils.transform.b);CGSize nameFit=[name sizeThatFits:CGSizeMake(name.bounds.size.width,CGFLOAT_MAX)];
                    BOOL artwork=fabs(pencils.bounds.size.width-228)<.01&&fabs(pencils.bounds.size.height-214)<.01&&scale+1e-6>=minimumScale&&CGRectContainsRect(CGRectInset(providerRect,-tolerance,-tolerance),artRect)&&CGRectGetMaxY(artRect)<=CGRectGetMinY(opacity.frame)+tolerance;
                    CGFloat expectedFont=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:content.traitCollection].pointSize;
                    BOOL label=longest&&name.text.length&&[name.text isEqualToString:longest.accessibilityLabel]&&name.numberOfLines==0&&fabs(name.font.pointSize-expectedFont)<.01&&name.bounds.size.height+tolerance>=ceil(nameFit.height)&&CGRectGetMaxY(nameRect)<=CGRectGetMinY(artRect)+tolerance&&(longest.accessibilityTraits&UIAccessibilityTraitSelected)!=0;
                    BOOL segment=[fixture[@"switch"]boolValue]?(mode&&mode.numberOfSegments==2&&mode.selectedSegmentIndex==0&&[mode titleForSegmentAtIndex:0].length&&[mode titleForSegmentAtIndex:1].length&&mode.bounds.size.height>0&&CGRectGetMaxY([mode.superview convertRect:mode.superview.bounds toView:canvas])<=CGRectGetMinY(nameRect)+tolerance):mode==nil;
                    BOOL scroll=overflow.scrollEnabled&&overflow.contentSize.height>overflow.bounds.size.height&&CGSizeEqualToSize(overflow.contentSize,canvas.bounds.size)&&CGRectContainsRect(CGRectInset(canvas.bounds,-tolerance,-tolerance),footer.frame)&&CGAffineTransformIsIdentity(canvas.transform);
                    [overflow scrollRectToVisible:footer.frame animated:NO];CGRect viewport=(CGRect){overflow.contentOffset,overflow.bounds.size};BOOL footerReachable=CGRectContainsRect(CGRectInset(viewport,-tolerance,-tolerance),footer.frame);
                    record(@"Short pencil host preserves artwork name and optional segment through root overflow",artwork&&label&&segment&&scroll&&footerReachable,@{@"fixture":fixture,@"name":name.text?:@"",@"fontSize":@(name.font.pointSize),@"artBounds":NSStringFromCGRect(pencils.bounds),@"artFrame":NSStringFromCGRect(artRect),@"minimumScale":@(minimumScale),@"scale":@(scale),@"nameFits":@(label),@"segmentFits":@(segment),@"contentSize":NSStringFromCGSize(overflow.contentSize),@"footerReachable":@(footerReachable)});
                }@finally{
                    [holder setOverrideTraitCollection:nil forChildViewController:content];[content willMoveToParentViewController:nil];[content.view removeFromSuperview];[content removeFromParentViewController];
                }
            }
#endif
            UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeGray;configuration.savedColorsKey=nil;configuration.use_spi=NO;
            UIColorPanelViewController *content=[[UIColorPanelViewController alloc]initWithColor:[[UIColorValue alloc]initWithCGColor:UIColor.grayColor.CGColor] configuration:configuration];UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:content];
            @try {
                [holder addChildViewController:navigation];navigation.view.frame=holder.view.bounds;[holder.view addSubview:navigation.view];[navigation didMoveToParentViewController:holder];[navigation.view layoutIfNeeded];[content.view setNeedsLayout];[content.view layoutIfNeeded];
                UIBarButtonItem *organize=[content valueForKey:@"savedColorsItem"];NSArray<UIBarButtonItem *> *items=content.navigationItem.rightBarButtonItems;
                BOOL management=organize&&organize.target==content&&[NSStringFromSelector(organize.action)isEqualToString:@"showSavedColors:"]&&items.count==2&&items[1]==organize&&organize.enabled&&organize.accessibilityLabel.length>0&&!navigation.navigationBarHidden&&navigation.visibleViewController==content&&navigation.navigationBar.window==window;
                record(@"Saved-color management uses the visible native Organize navigation item",management,@{@"identifier":organize.accessibilityIdentifier?:@"",@"rightItemCount":@(items.count),@"scope":@"Attached native navigation bar and production target/action wiring; no modal interaction."});
                NSArray<UIColorPanelColorWell *> *buttons=[content valueForKey:@"grayShortcutButtons"];BOOL circular=buttons.count==5;NSMutableArray *targets=[NSMutableArray new];
                for(UIColorPanelColorWell *button in buttons){BOOL target=button.usesCircularPresentation&&button.bounds.size.width>=44-.01&&button.bounds.size.height>=44-.01&&button.accessibilityLabel.length>0&&[[button actionsForTarget:content forControlEvent:UIControlEventTouchUpInside]containsObject:@"grayShortcut:"]&&[button pointInside:CGPointMake(CGRectGetMidX(button.bounds),CGRectGetMidY(button.bounds)) withEvent:nil];circular=circular&&target;[targets addObject:@{@"bounds":NSStringFromCGRect(button.bounds),@"passed":@(target)}];}
                record(@"Gray shortcuts use five circular presentations with native 44pt targets",circular,@{@"targets":targets});
            }@finally{[navigation willMoveToParentViewController:nil];[navigation.view removeFromSuperview];[navigation removeFromParentViewController];}
        }@catch(NSException *exception){record(@"circle refinement fixture exception",NO,@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""});}
        @finally{[holder willMoveToParentViewController:nil];[holder.view removeFromSuperview];[holder removeFromParentViewController];}
    }
    NSDictionary *result=@{@"passed":@(passed),@"caseCount":@(cases.count),@"cases":cases,@"runtime":NSProcessInfo.processInfo.operatingSystemVersionString,@"scope":@"Finite attached production Grid common-sample and AX actions at alpha0/.35/1 plus one current-P3 swatch conversion; knob light/dark semantic refresh (white fallback on12); three shared sibling lenses; one3x1 AspectFit source, letterbox rejection and resize reprojection; three short pencil-host fixtures; native Organize wiring and five circular Gray targets. Programmatic methods, AX activation and scrollRectToVisible do not establish physical touch, spoken VoiceOver or native pixel equivalence. No global preferences, persistent fixtures or old full-suite rerun."};
    return [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES]&&passed;
}
+ (BOOL)runSpectrumLensWithOutputURL:(NSURL *)url {
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIViewController *parent=window.rootViewController;
    if([parent isKindOfClass:UINavigationController.class])parent=((UINavigationController *)parent).visibleViewController;
    BOOL attached=NSThread.isMainThread&&window&&!window.hidden&&parent.view.window==window&&!parent.presentedViewController;
    NSMutableArray *cases=[NSMutableArray new],*images=[NSMutableArray new];BOOL passed=attached;
    UIViewController *fixture=[UIViewController new];
    if(attached){
        [parent addChildViewController:fixture];fixture.view.frame=parent.view.bounds;[parent.view addSubview:fixture.view];[fixture didMoveToParentViewController:parent];
        NSArray<UIColor *> *backgrounds=@[UIColor.whiteColor,[UIColor colorWithRed:.1 green:.11 blue:.12 alpha:1]];
        NSArray<NSString *> *backgroundNames=@[@"white",@"dark"],*alphaNames=@[@"0.0",@"0.48",@"1.0"];
        for(NSUInteger backgroundIndex=0;backgroundIndex<2;backgroundIndex++)for(NSUInteger alphaIndex=0;alphaIndex<3;alphaIndex++){
            CGFloat alpha=alphaNames[alphaIndex].doubleValue;UIView *canvas=[[UIView alloc]initWithFrame:CGRectMake(20,20+cases.count*75,65,65)];canvas.backgroundColor=backgrounds[backgroundIndex];[fixture.view addSubview:canvas];
            UIColorPickerSpectrum *spectrum=[[UIColorPickerSpectrum alloc]initWithFrame:CGRectZero];UIColorValue *selected=[[UIColorValue alloc]initWithCGColor:[UIColor.redColor colorWithAlphaComponent:alpha].CGColor];spectrum.selectedColor=selected;
            CALayer *lens=[spectrum makeLens];lens.position=CGPointMake(32.5,32.5);[canvas.layer addSublayer:lens];[fixture.view layoutIfNeeded];
            UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat new];format.scale=2;format.preferredRange=UIGraphicsImageRendererFormatRangeStandard;
            UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithBounds:canvas.bounds format:format];__block BOOL drawn=NO;
            UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){drawn=[canvas drawViewHierarchyInRect:canvas.bounds afterScreenUpdates:YES];}];
            BOOL dimensions=CGImageGetWidth(image.CGImage)==130&&CGImageGetHeight(image.CGImage)==130;NSMutableData *storage=[NSMutableData dataWithLength:130*130*4];uint8_t *bytes=storage.mutableBytes;
            CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGContextRef bitmap=CGBitmapContextCreate(bytes,130,130,8,130*4,space,kCGImageAlphaPremultipliedLast);CGColorSpaceRelease(space);
            if(bitmap){CGContextDrawImage(bitmap,CGRectMake(0,0,130,130),image.CGImage);CGContextRelease(bitmap);}
            NSMutableArray *center=[NSMutableArray new],*ring=[NSMutableArray new];for(NSUInteger channel=0;channel<4;channel++){[center addObject:@(bytes[(65*130+65)*4+channel])];[ring addObject:@(bytes[(35*130+65)*4+channel])];}
            BOOL valid=drawn&&dimensions&&bitmap&&spectrum.selectedColor==selected&&CGColorGetAlpha(selected.CGColor)==alpha;passed=passed&&valid;
            NSString *name=[NSString stringWithFormat:@"%@-%@",backgroundNames[backgroundIndex],alphaNames[alphaIndex]];
            [cases addObject:@{@"case":name,@"passed":@(valid),@"background":backgroundNames[backgroundIndex],@"alpha":@(alpha),@"objc":@{@"centerRGBA":center,@"outerRingRGBA":ring},@"rasterDimensions":@[@(CGImageGetWidth(image.CGImage)),@(CGImageGetHeight(image.CGImage))]}];[images addObject:image];
        }
        [fixture willMoveToParentViewController:nil];[fixture.view removeFromSuperview];[fixture removeFromParentViewController];
    }
    NSURL *imageURL=[[url URLByDeletingPathExtension]URLByAppendingPathExtension:@"png"];BOOL imageWritten=NO;
    if(images.count){UIGraphicsBeginImageContextWithOptions(CGSizeMake(260,images.count*80),YES,2);[UIColor.whiteColor setFill];UIRectFill(CGRectMake(0,0,260,images.count*80));
        for(NSUInteger index=0;index<images.count;index++){[cases[index][@"case"]drawAtPoint:CGPointMake(10,index*80+25) withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14],NSForegroundColorAttributeName:UIColor.blackColor}];[images[index]drawAtPoint:CGPointMake(180,index*80+5)];}
        UIImage *collage=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();imageWritten=[UIImagePNGRepresentation(collage)writeToURL:imageURL atomically:YES];
    }
    passed=passed&&cases.count==6&&imageWritten;
    NSDictionary *report=@{@"passed":@(passed),@"runtime":NSProcessInfo.processInfo.operatingSystemVersionString,@"attachedHost":@(attached),@"cases":cases,@"canvas":@"65x65pt at2x; lens33pt centered; sRGB premultiplied RGBA8",@"collage":imageURL.lastPathComponent,@"scope":@"Six actual production makeLens rasters, red alpha0/.48/1 on the same white/dark backgrounds as the15.5 research runner. Raw center and outer-ring samples permit cross-runtime comparison. This alone does not establish native equivalence, Spectrum gestures or spoken accessibility."};
    return [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES]&&passed;
}
+ (void)runSliderAnimationWithOutputURL:(NSURL *)url {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self runSliderAnimationWithOutputURL:url];});return;}
    UISliderAnimationRunner *runner=[UISliderAnimationRunner new];runner.outputURL=url;[runner start];
}
+ (void)runInteractionRepairsWithOutputURL:(NSURL *)url {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self runInteractionRepairsWithOutputURL:url];});return;}
    UIInteractionRepairsRunner *runner=[UIInteractionRepairsRunner new];runner.outputURL=url;[runner start];
}
+ (void)runInputStateRepairsWithOutputURL:(NSURL *)url {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self runInputStateRepairsWithOutputURL:url];});return;}
    UIInteractionRepairsRunner *runner=[UIInteractionRepairsRunner new];runner.outputURL=url;runner.inputStateRepairs=YES;[runner start];
}
+ (void)runScopedReviewRepairsWithOutputURL:(NSURL *)url {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self runScopedReviewRepairsWithOutputURL:url];});return;}
    UIInteractionRepairsRunner *runner=[UIInteractionRepairsRunner new];runner.outputURL=url;runner.scopedReviewRepairs=YES;[runner start];
}
+ (BOOL)runMajorRefinementsWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray new];__block BOOL passed=YES;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL valid,NSDictionary *details){passed=passed&&valid;NSMutableDictionary *entry=[@{@"name":name,@"passed":@(valid)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];};
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIViewController *anchor=window.rootViewController;
    if([anchor isKindOfClass:UINavigationController.class])anchor=((UINavigationController *)anchor).visibleViewController;
    BOOL attached=NSThread.isMainThread&&window&&!window.hidden&&anchor.view.window==window&&!anchor.presentedViewController;
    record(@"attached UIKit host",attached,@{});
    if(attached)@try {
        UIColorPanelWell *well=[[UIColorPanelWell alloc]initWithFrame:CGRectMake(0,0,44,44)];[anchor.view addSubview:well];
        @try {
            NSString *initialAX=well.accessibilityValue;BOOL initialValid=initialAX.length>0&&[initialAX containsString:[UIColorPanelAppearance localizedString:@"Opacity"]]&&[well.accessibilityLabel isEqualToString:[UIColorPanelAppearance localizedString:@"Current color"]];
            well.color=[UIColor colorWithRed:.9 green:.16 blue:.12 alpha:.65];NSString *redAX=well.accessibilityValue;well.color=[UIColor colorWithRed:.12 green:.16 blue:.9 alpha:.65];NSString *blueAX=well.accessibilityValue;
            well.accessibilityLabel=@"Host color label";well.accessibilityValue=@"Host color value";well.color=UIColor.whiteColor;
            record(@"public well initial, changed and host AX",initialValid&&redAX.length&&blueAX.length&&![initialAX isEqualToString:redAX]&&![redAX isEqualToString:blueAX]&&[well.accessibilityLabel isEqualToString:@"Host color label"]&&[well.accessibilityValue isEqualToString:@"Host color value"],@{});
        }@finally{[well removeFromSuperview];}
        for(NSNumber *width in @[@320,@414])for(NSString *category in @[UIContentSizeCategoryLarge,UIContentSizeCategoryAccessibilityExtraLarge])for(NSNumber *rtl in @[@NO,@YES])@autoreleasepool {
            UIViewController *holder=[UIViewController new];UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeRGB;configuration.savedColorsKey=nil;
            UIColorValue *initial=[[UIColorValue alloc]initWithCGColor:[UIColor colorWithDisplayP3Red:.9 green:.16 blue:.12 alpha:.65].CGColor];
            UIColorPanelViewController *content=[[UIColorPanelViewController alloc]initWithColor:initial configuration:configuration];
            @try {
            [anchor addChildViewController:holder];holder.view.frame=CGRectMake(0,0,width.doubleValue,736);[anchor.view addSubview:holder.view];[holder didMoveToParentViewController:anchor];
            [holder addChildViewController:content];[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:category] forChildViewController:content];content.view.frame=holder.view.bounds;[holder.view addSubview:content.view];[content didMoveToParentViewController:holder];
            content.view.semanticContentAttribute=rtl.boolValue?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;
                void (^layout)(void)=^{[content.view setNeedsLayout];[content.view layoutIfNeeded];};layout();CGFloat tolerance=1.0/window.screen.scale;
                CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);UIColorPanelColorProfile *requested=[[UIColorPanelColorProfile alloc]initWithColorSpace:space displayName:@"Phase A sRGB"];CGColorSpaceRelease(space);
                BOOL profileValid=[content selectColorProfile:requested error:nil];layout();UILabel *hexLabel=[content valueForKey:@"hexLabel"];UITextField *hex=[content valueForKey:@"hexField"];
                profileValid=profileValid&&content.activeColorProfile.displayName.length&&[hexLabel.text containsString:content.activeColorProfile.displayName]&&[hex.accessibilityLabel isEqualToString:hexLabel.text];
                UIColorValue *beforeDraft=content.selectedColor;BOOL draftsValid=YES;NSMutableArray *draftWidths=[NSMutableArray new];
                NSArray *fields=[[content valueForKey:@"componentFields"]arrayByAddingObjectsFromArray:@[hex,[content valueForKey:@"opacityField"]]];
                for(UITextField *field in fields){
                    NSString *original=field.text;CGFloat before=field.bounds.size.width;
                    field.text=@"9";[field sendActionsForControlEvents:UIControlEventEditingChanged];layout();CGFloat shortWidth=field.bounds.size.width;
                    NSString *draft=@"12345678901234567890";field.text=draft;[field sendActionsForControlEvents:UIControlEventEditingChanged];layout();CGFloat longWidth=field.bounds.size.width;
                    draftsValid=draftsValid&&before>0&&fabs(before-shortWidth)<=tolerance&&fabs(before-longWidth)<=tolerance&&[field.text isEqualToString:draft]&&[content.selectedColor isEqual:beforeDraft];
                    [draftWidths addObject:@[@(before),@(shortWidth),@(longWidth)]];field.text=original;[[content valueForKey:@"editedFields"]removeObject:field];
                }
                content.mode=UIColorPanelModeHSB;layout();UILabel *profileLabel=[content valueForKey:@"spaceLabel"];
                profileValid=profileValid&&!profileLabel.hidden&&profileLabel.text.length&&[profileLabel.text isEqualToString:content.activeColorProfile.displayName];
                NSMutableArray *headers=[NSMutableArray new];NSArray *baselineFooter=nil;BOOL footerValid=YES,searchValid=YES;
                for(NSNumber *mode in @[@(UIColorPanelModeRGB),@(UIColorPanelModeColorList),@(UIColorPanelModeImage),@(UIColorPanelModeWheel),@(UICOLORPANEL_ENABLE_PENCILS ? UIColorPanelModePencils : UIColorPanelModeGrid)]){
                    content.mode=mode.integerValue;layout();UIView *canvas=[content valueForKey:@"rootStack"];
                    NSMutableArray *geometry=[NSMutableArray new];for(NSString *key in @[@"footer",@"opacityRow",@"currentWell",@"savedColorsButton"]){UIView *view=[content valueForKey:key];[geometry addObject:NSStringFromCGRect([view convertRect:view.bounds toView:canvas])];}
                    if(!baselineFooter)baselineFooter=geometry;else footerValid=footerValid&&[baselineFooter isEqualToArray:geometry];
                    if(mode.integerValue==UIColorPanelModeRGB||mode.integerValue==UIColorPanelModeColorList||mode.integerValue==UIColorPanelModeImage){
                        id provider=mode.integerValue==UIColorPanelModeColorList?[content valueForKey:@"catalogController"]:mode.integerValue==UIColorPanelModeImage?[content valueForKey:@"imagePaletteController"]:content;
                        UIColorPanelMenuButton *selection=[provider valueForKey:mode.integerValue==UIColorPanelModeRGB?@"modelMenuButton":mode.integerValue==UIColorPanelModeColorList?@"listButton":@"chooseButton"];
                        UIColorPanelMenuButton *more=[provider valueForKey:mode.integerValue==UIColorPanelModeRGB?@"optionsMenuButton":mode.integerValue==UIColorPanelModeColorList?@"actionsButton":@"manageButton"];
                        [selection setTitle:@"Color profile and display configuration" forState:UIControlStateNormal];layout();[[(UIViewController *)provider view]setNeedsLayout];[[(UIViewController *)provider view]layoutIfNeeded];layout();
                        UILabel *title=[selection valueForKey:@"menuTitle"];UIView *image=[more valueForKey:@"menuImage"];CGRect textRect=[title convertRect:title.bounds toView:canvas],moreRect=[image convertRect:image.bounds toView:canvas];
                        [headers addObject:@[@(rtl.boolValue?CGRectGetMaxX(textRect):CGRectGetMinX(textRect)),@(CGRectGetMidX(moreRect)),@(CGRectGetMidY(moreRect)),@(title.window==window&&title.bounds.size.width>0&&image.bounds.size.width>0)]];
                    }
                    if(mode.integerValue==UIColorPanelModeColorList){
                        UIColorPickerCatalogController *catalog=[content valueForKey:@"catalogController"];UISearchBar *search=[catalog valueForKey:@"searchBar"];NSUInteger count=[[catalog valueForKey:@"visibleKeys"]count];UIColorValue *beforeSearch=content.selectedColor,*catalogColor=catalog.selectedColor;
                        search.text=@"__ui_major_no_matching_color__";[search.delegate searchBar:search textDidChange:search.text];layout();UILabel *empty=[catalog valueForKey:@"emptyLabel"];UIButton *clear=[catalog valueForKey:@"clearSearchButton"];
                        searchValid=count>0&&[[catalog valueForKey:@"visibleKeys"]count]==0&&[empty isDescendantOfView:catalog.view]&&[empty.text isEqualToString:[UIColorPanelAppearance localizedString:@"No matching colors"]]&&!clear.hidden&&[content.selectedColor isEqual:beforeSearch]&&[catalog.selectedColor isEqual:catalogColor];
                        [clear sendActionsForControlEvents:UIControlEventTouchUpInside];layout();searchValid=searchValid&&search.text.length==0&&[[catalog valueForKey:@"visibleKeys"]count]==count&&[content.selectedColor isEqual:beforeSearch]&&[catalog.selectedColor isEqual:catalogColor];
                    }
                }
                BOOL headersValid=headers.count==3;for(NSArray *metric in headers){headersValid=headersValid&&[metric[3]boolValue]&&(rtl.boolValue?[metric[1]doubleValue]<width.doubleValue/2:[metric[1]doubleValue]>width.doubleValue/2);for(NSUInteger axis=0;axis<3;axis++)headersValid=headersValid&&fabs([metric[axis]doubleValue]-[headers.firstObject[axis]doubleValue])<=tolerance;}
                record(@"Phase A layout and state",headersValid&&footerValid&&draftsValid&&profileValid&&searchValid,@{@"width":width,@"category":category,@"rtl":rtl,@"headers":headers,@"headersAligned":@(headersValid),@"footerStable":@(footerValid),@"draftStable":@(draftsValid),@"draftWidths":draftWidths,@"profileLabels":@(profileValid),@"searchClear":@(searchValid)});
            }@finally{
                [holder setOverrideTraitCollection:nil forChildViewController:content];[content willMoveToParentViewController:nil];[content.view removeFromSuperview];[content removeFromParentViewController];
                [holder willMoveToParentViewController:nil];[holder.view removeFromSuperview];[holder removeFromParentViewController];
            }
        }
    }@catch(NSException *exception){record(@"Phase A exception",NO,@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""});}
    NSDictionary *result=@{@"passed":@(passed),@"cases":cases,@"scope":@"Attached UIKit layout, scoped content-size/RTL traits, draft-only editing events, profile labels, search clear and AX values. No global preferences changed. No modal gesture, keyboard/IME, VoiceOver speech or conversion-failure injection; unavailable-profile explanation remains source-reviewed."};
    return [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES]&&passed;
}
// Deliberately separate from the historical full review. These finite fixtures
// invoke production methods programmatically; they are not physical-touch proof.
+ (BOOL)runTouchRefinementsWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray new];__block BOOL passed=YES;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL valid,NSDictionary *details){passed=passed&&valid;NSMutableDictionary *entry=[@{@"name":name,@"passed":@(valid)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];};
    BOOL (^exactColor)(UIColorValue *,UIColorValue *)=^BOOL(UIColorValue *a,UIColorValue *b){CGColorRef x=a.CGColor,y=b.CGColor;return x&&y&&CGColorEqualToColor(x,y)&&CFEqual(CGColorGetColorSpace(x),CGColorGetColorSpace(y))&&CGColorGetNumberOfComponents(x)==CGColorGetNumberOfComponents(y)&&memcmp(CGColorGetComponents(x),CGColorGetComponents(y),CGColorGetNumberOfComponents(x)*sizeof(CGFloat))==0;};
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIViewController *anchor=window.rootViewController;
    if([anchor isKindOfClass:UINavigationController.class])anchor=((UINavigationController *)anchor).visibleViewController;
    UIColorPanel *panel=NSThread.isMainThread?UIColorPanel.sharedColorPanel:nil;
    BOOL attached=NSThread.isMainThread&&window&&!window.hidden&&anchor.view.window==window&&!anchor.presentedViewController&&panel&&!panel.visible&&!panel.transitioning;
    NSMutableArray<UIView *> *views=[UIApplication.sharedApplication.windows mutableCopy];while(views.count){UIView *view=views.lastObject;[views removeLastObject];if([view isKindOfClass:UIColorPanelWell.class]&&((UIColorPanelWell *)view).active)attached=NO;[views addObjectsFromArray:view.subviews];}
    record(@"attached host and idle shared panel",attached,@{});
    if(attached)@try {
        CGColorSpaceRef srgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB),p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3),cmyk=CGColorSpaceCreateDeviceCMYK();
        const CFStringRef *extendedName=dlsym(RTLD_DEFAULT,"kCGColorSpaceExtendedDisplayP3");
        CGColorSpaceRef extended=extendedName?CGColorSpaceCreateWithName(*extendedName):NULL;
        CGColorSpaceRef (*createExtended)(CGColorSpaceRef)=dlsym(RTLD_DEFAULT,"CGColorSpaceCreateExtended");
        if(!extended&&createExtended)extended=createExtended(p3);
        BOOL extendedP3=extended!=NULL;if(!extended)extended=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
        const CGFloat white[]={.95047,1,1.08883},black[]={0,0,0},gamma[]={2.2,2.2,2.2},matrix[]={.4124564,.2126729,.0193339,.3575761,.7151522,.119192,.1804375,.072175,.9503041};
        CGColorSpaceRef calibrated=CGColorSpaceCreateCalibratedRGB(white,black,gamma,matrix);NSData *customICC=calibrated?CFBridgingRelease(CGColorSpaceCopyICCData(calibrated)):nil;CGColorSpaceRef custom=customICC?CGColorSpaceCreateWithICCData((__bridge CFDataRef)customICC):NULL;
        UIColorValue *(^value)(CGColorSpaceRef,const CGFloat *)=^UIColorValue *(CGColorSpaceRef space,const CGFloat *components){if(!space)return nil;CGColorRef cg=CGColorCreate(space,components);UIColorValue *color=cg?[[UIColorValue alloc]initWithCGColor:cg]:nil;if(cg)CGColorRelease(cg);return color;};
        UIColorValue *initial=value(srgb,(CGFloat[]){.2,.5,.7,.65});
        NSArray *colors=@[value(custom,(CGFloat[]){.2,.5,.7,.42})?:NSNull.null,value(extended,(CGFloat[]){-.125,1.375,.314159265,.65})?:NSNull.null,value(srgb,(CGFloat[]){.99999601,1,1,.65})?:NSNull.null,value(cmyk,(CGFloat[]){.1,.3,.2,.4,.65})?:NSNull.null,value(p3,(CGFloat[]){.9,.16,.12,0})?:NSNull.null];
        if(srgb)CGColorSpaceRelease(srgb);if(extended)CGColorSpaceRelease(extended);if(p3)CGColorSpaceRelease(p3);if(cmyk)CGColorSpaceRelease(cmyk);if(calibrated)CGColorSpaceRelease(calibrated);if(custom)CGColorSpaceRelease(custom);
        UIViewController *holder=[UIViewController new];UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeRGB;configuration.savedColorsKey=nil;
        UIColorPanelViewController *content=[[UIColorPanelViewController alloc]initWithColor:initial configuration:configuration];
        @try {
            [anchor addChildViewController:holder];holder.view.frame=CGRectMake(0,0,414,736);[anchor.view addSubview:holder.view];[holder didMoveToParentViewController:anchor];[holder addChildViewController:content];[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryLarge] forChildViewController:content];content.view.frame=holder.view.bounds;[holder.view addSubview:content.view];[content didMoveToParentViewController:holder];
            void (^layout)(void)=^{[content.view setNeedsLayout];[content.view layoutIfNeeded];};
            NSArray *names=@[@"RGB 8-bit custom ICC",extendedP3?@"extended Display P3 float":@"extended sRGB float (extended P3 unavailable)",@"HSB seven-stop hue",@"CMYK four components",@"zero alpha Display P3"];
            NSArray *modes=@[@(UIColorPanelModeRGB),@(UIColorPanelModeRGB),@(UIColorPanelModeHSB),@(UIColorPanelModeCMYK),@(UIColorPanelModeRGB)];
            for(NSUInteger index=0;index<colors.count;index++){
                if(colors[index]==NSNull.null){record(names[index],NO,@{@"reason":@"Runtime color-space fixture unavailable"});continue;}
                content.mode=[modes[index]integerValue];content.selectedColor=colors[index];
                if(content.mode==UIColorPanelModeRGB){UISegmentedControl *precision=[content valueForKey:@"precision"];precision.selectedSegmentIndex=index==1?1:0;[content precisionChanged:precision];}
                UIColorValue *before=content.selectedColor;NSData *beforeICC=CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(before.CGColor)));[content updateControls];layout();
                NSArray<UIGradientSlider *> *sliders=[content valueForKey:@"componentSliders"];BOOL controls=sliders.count==(index==3?4:3);NSMutableArray *stops=[NSMutableArray new];
                for(UIGradientSlider *slider in sliders){[slider setNeedsLayout];[slider layoutIfNeeded];CAGradientLayer *gradient=[slider valueForKey:@"gradient"];[stops addObject:@(gradient.colors.count)];controls=controls&&[slider isKindOfClass:UIColorPickerColorSlider.class]&&gradient.colors.count==slider.gradientColors.count&&slider.value>=0&&slider.value<=1;}
                UIGradientSlider *alpha=[content valueForKey:@"opacitySlider"];NSData *afterICC=CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(content.selectedColor.CGColor)));
                BOOL preserved=exactColor(before,colors[index])&&exactColor(before,content.selectedColor)&&(beforeICC?[beforeICC isEqual:afterICC]:afterICC==nil);
                if(index==0)preserved=preserved&&customICC.length>0&&beforeICC.length>0;
                if(index==1)controls=controls&&sliders.firstObject.value==0&&sliders[1].value==1;
                if(index==2){controls=controls&&sliders.firstObject.gradientColors.count==7;for(UITextField *field in [content valueForKey:@"componentFields"]){NSString *text=field.text;[field setNeedsLayout];[field layoutIfNeeded];controls=controls&&fabs(field.bounds.size.width-76)<.01&&fabs(field.bounds.size.height-36)<.01&&field.textAlignment==NSTextAlignmentCenter&&field.adjustsFontSizeToFitWidth&&[field.text isEqualToString:text];}}
                if(index==4)controls=controls&&alpha.showsOpacityBackground&&alpha.value==0;
                record(names[index],preserved&&controls,@{@"canonicalAndICCUnchanged":@(preserved),@"gradientStops":stops,@"iccBytes":@(beforeICC.length)});
            }
            UIColorPickerColorSlider *recovered=[[UIColorPickerColorSlider alloc]initWithFrame:CGRectMake(0,0,240,36)];UIGradientSlider *adapter=[[UIGradientSlider alloc]initWithFrame:recovered.frame];
            @try {
                for(UIColorPickerColorSlider *slider in @[recovered,adapter]){slider.value=.37;slider.fromColor=UIColor.redColor;slider.toColor=UIColor.blueColor;slider.selectedColor=UIColor.purpleColor;slider.showsOpacityBackground=YES;[holder.view addSubview:slider];}
                adapter.gradientColors=@[adapter.fromColor,adapter.toColor];[recovered layoutIfNeeded];[adapter layoutIfNeeded];
                UIView *aCapsule=[adapter valueForKey:@"capsule"],*rCapsule=[recovered valueForKey:@"capsule"],*aKnob=[adapter valueForKey:@"knob"],*rKnob=[recovered valueForKey:@"knob"];CAGradientLayer *aGradient=[adapter valueForKey:@"gradient"],*rGradient=[recovered valueForKey:@"gradient"];
                BOOL equivalent=CGRectEqualToRect(aCapsule.frame,rCapsule.frame)&&aCapsule.layer.cornerRadius==rCapsule.layer.cornerRadius&&CGRectEqualToRect(aKnob.frame,rKnob.frame)&&CGRectEqualToRect(aGradient.frame,rGradient.frame)&&CGPointEqualToPoint(aGradient.startPoint,rGradient.startPoint)&&CGPointEqualToPoint(aGradient.endPoint,rGradient.endPoint)&&[aGradient.colors isEqual:rGradient.colors]&&((UIView *)[adapter valueForKey:@"checker"]).hidden==((UIView *)[recovered valueForKey:@"checker"]).hidden;
                record(@"adapter inherits recovered two-stop layer geometry",equivalent,@{@"scope":@"Attached control geometry and gradient/checker layer properties only; no raster or original-binary rerun."});
            }@finally{[recovered removeFromSuperview];[adapter removeFromSuperview];}
            content.mode=UIColorPanelModeRGB;content.selectedColor=initial;UISegmentedControl *precision=[content valueForKey:@"precision"];precision.selectedSegmentIndex=0;[content precisionChanged:precision];layout();
            UITextField *red=[[content valueForKey:@"componentFields"]firstObject];NSString *draft=[UIColorPanelAppearance formatNumber:128 significantDigits:0];red.text=draft;[red sendActionsForControlEvents:UIControlEventEditingChanged];[content updateControls];layout();
            BOOL draftPreserved=[red.text isEqualToString:draft]&&exactColor(initial,content.selectedColor);UIGradientSlider *opacity=[content valueForKey:@"opacitySlider"];opacity.value=.35;[opacity sendActionsForControlEvents:UIControlEventValueChanged];layout();
            draftPreserved=draftPreserved&&[red.text isEqualToString:draft]&&[[content valueForKey:@"editedFields"]containsObject:red];BOOL committed=[content commitField:red];CGColorSpaceRef working=content.activeColorProfile.CGColorSpace;CGFloat components[4]={0};BOOL converted=[content.selectedColor getRGBComponents:components inColorSpace:working error:nil];
            record(@"valid draft survives redraw and internal alpha update before commit",draftPreserved&&committed&&converted&&fabs(components[0]-128/255.0)<1e-9&&fabs(components[1]-.5)<1e-9&&fabs(components[2]-.7)<1e-9&&fabs(components[3]-.35)<1e-9&&![[content valueForKey:@"editedFields"]containsObject:red],@{@"draftPreserved":@(draftPreserved),@"committed":@(committed)});
            CGColorSpaceRef graySpace=CGColorSpaceCreateWithName(kCGColorSpaceGenericGrayGamma2_2);UIColorValue *gray=value(graySpace,(CGFloat[]){.6,.42});if(graySpace)CGColorSpaceRelease(graySpace);
            UIColorValue *green=value(CGColorGetColorSpace(initial.CGColor),(CGFloat[]){0,1,0,.65});
            NSArray *sliderFixtures=@[
                @{@"name":@"RGB float 1/3",@"mode":@(UIColorPanelModeRGB),@"precision":@1,@"seed":colors[0],@"channel":@0,@"input":@(1.0/3),@"expected":@[@(1.0/3),@.5,@.7,@.42]},
                @{@"name":@"RGB 8-bit 1/7",@"mode":@(UIColorPanelModeRGB),@"precision":@0,@"seed":colors[0],@"channel":@0,@"input":@(1.0/7),@"expected":@[@(1.0/7),@.5,@.7,@.42]},
                @{@"name":@"Gray",@"mode":@(UIColorPanelModeGray),@"seed":gray?:NSNull.null,@"channel":@0,@"input":@(1.0/3),@"expected":@[@(1.0/3),@.42]},
                @{@"name":@"CMYK",@"mode":@(UIColorPanelModeCMYK),@"seed":colors[3],@"channel":@0,@"input":@(1.0/3),@"expected":@[@(1.0/3),@.3,@.2,@.4,@.65]},
                @{@"name":@"HSB green brightness",@"mode":@(UIColorPanelModeHSB),@"seed":green?:NSNull.null,@"channel":@2,@"input":@(1.0/3),@"expected":@[@0,@(1.0/3),@0,@.65]}];
            BOOL sliderPrecision=YES;NSMutableArray *precisionDetails=[NSMutableArray new];
            for(NSDictionary *fixture in sliderFixtures){
                if(fixture[@"seed"]==NSNull.null){sliderPrecision=NO;[precisionDetails addObject:@{@"name":fixture[@"name"],@"passed":@NO,@"reason":@"Runtime color-space fixture unavailable"}];continue;}
                content.selectedColor=fixture[@"seed"];content.mode=[fixture[@"mode"]integerValue];
                if(content.mode==UIColorPanelModeRGB){UISegmentedControl *selector=[content valueForKey:@"precision"];selector.selectedSegmentIndex=[fixture[@"precision"]integerValue];[content precisionChanged:selector];}layout();
                UIColorPanelColorProfile *profile=content.activeColorProfile;NSArray<UITextField *> *fields=[content valueForKey:@"componentFields"];NSUInteger channel=[fixture[@"channel"]unsignedIntegerValue];UIGradientSlider *slider=[content valueForKey:@"componentSliders"][channel];
                NSMutableArray<UITextField *> *draftFields=[NSMutableArray arrayWithObject:[content valueForKey:@"opacityField"]];if(fields.count>1)[draftFields addObject:fields[(channel+1)%fields.count]];
                NSString *otherDraft=@"12.3456789012345";for(UITextField *field in draftFields){field.text=otherDraft;[field sendActionsForControlEvents:UIControlEventEditingChanged];}
                double input=[fixture[@"input"]doubleValue];slider.value=input;[slider sendActionsForControlEvents:UIControlEventValueChanged];[content updateControls];layout();
                CGColorRef result=content.selectedColor.CGColor;NSArray *expected=fixture[@"expected"];const CGFloat *actual=CGColorGetComponents(result);NSUInteger count=CGColorGetNumberOfComponents(result);
                // Same-space fixtures avoid ICC conversion loss; pure green HSB
                // brightness has the independent expected RGB (0, input, 0).
                BOOL valid=count==expected.count&&CFEqual(CGColorGetColorSpace(result),profile.CGColorSpace)&&[profile.identifier isEqual:content.activeColorProfile.identifier]&&fabs(slider.value-input)<1e-12;
                for(NSUInteger i=0;i<MIN(count,expected.count);i++)valid=valid&&fabs(actual[i]-[expected[i]doubleValue])<1e-12;
                for(UITextField *field in draftFields)valid=valid&&[field.text isEqualToString:otherDraft]&&[[content valueForKey:@"editedFields"]containsObject:field];
                valid=valid&&![[content valueForKey:@"editedFields"]containsObject:fields[channel]];sliderPrecision=sliderPrecision&&valid;[precisionDetails addObject:@{@"name":fixture[@"name"],@"passed":@(valid),@"input":@(input),@"sliderValue":@(slider.value)}];
            }
            record(@"component sliders retain direct normalized precision profiles alpha and other drafts",sliderPrecision,@{@"samples":precisionDetails});
            content.selectedColor=initial;content.mode=UIColorPanelModeRGB;precision=[content valueForKey:@"precision"];precision.selectedSegmentIndex=0;[content precisionChanged:precision];layout();
            NSArray *layouts=@[@[@320,@736,UIContentSizeCategoryLarge,@NO,@76],@[@414,@736,UIContentSizeCategoryLarge,@YES,@76],@[@320,@320,UIContentSizeCategoryLarge,@NO,@76],@[@414,@736,UIContentSizeCategoryAccessibilityExtraLarge,@YES,@76],@[@736,@414,UIContentSizeCategoryLarge,@NO,@60]];
            for(NSArray *fixture in layouts){
                holder.view.frame=CGRectMake(0,0,[fixture[0]doubleValue],[fixture[1]doubleValue]);[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:fixture[2]] forChildViewController:content];content.view.frame=holder.view.bounds;content.view.semanticContentAttribute=[fixture[3]boolValue]?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;layout();
                UIView *canvas=[content valueForKey:@"rootStack"],*footer=[content valueForKey:@"footer"];BOOL geometry=CGRectContainsRect(CGRectInset(canvas.bounds,-.01,-.01),footer.frame)&&CGAffineTransformIsIdentity(canvas.transform);BOOL fieldGeometry=YES,targets=YES;NSMutableArray *widths=[NSMutableArray new];UIColorValue *before=content.selectedColor;BOOL large=UIContentSizeCategoryIsAccessibilityCategory(fixture[2]);CGFloat expectedWidth=[fixture[4]doubleValue];
                NSArray *fields=[[content valueForKey:@"componentFields"]arrayByAddingObjectsFromArray:@[[content valueForKey:@"hexField"],[content valueForKey:@"opacityField"]]];
                for(UITextField *field in fields){UIView *wrapper=field.superview;NSString *original=field.text;CGFloat width=wrapper.bounds.size.width;field.text=@"9";[field sendActionsForControlEvents:UIControlEventEditingChanged];layout();CGFloat shortWidth=wrapper.bounds.size.width;field.text=@"12345678901234567890";[field sendActionsForControlEvents:UIControlEventEditingChanged];layout();CGFloat longWidth=wrapper.bounds.size.width;
                    fieldGeometry=fieldGeometry&&[wrapper isKindOfClass:NSClassFromString(@"UIColorPanelNumericField")]&&field.borderStyle==UITextBorderStyleNone&&wrapper.bounds.size.height>=44-.01&&width>0&&fabs(width-shortWidth)<.01&&fabs(width-longWidth)<.01&&CGRectContainsRect(CGRectInset(wrapper.bounds,-.01,-.01),field.frame)&&field.accessibilityLabel.length>0&&[field.text isEqualToString:@"12345678901234567890"];
                    if(field!=[content valueForKey:@"hexField"])fieldGeometry=fieldGeometry&&fabs(width-expectedWidth)<.01&&fabs(field.bounds.size.width-expectedWidth)<.01&&field.textAlignment==NSTextAlignmentCenter&&field.adjustsFontSizeToFitWidth&&(large||fabs(field.bounds.size.height-36)<.01);
                    [widths addObject:@[@(width),@(shortWidth),@(longWidth)]];field.text=original;[[content valueForKey:@"editedFields"]removeObject:field];}
                NSArray *sliders=[[content valueForKey:@"componentSliders"]arrayByAddingObject:[content valueForKey:@"opacitySlider"]];
                for(UIGradientSlider *slider in sliders){UIView *capsule=[slider valueForKey:@"capsule"];CGFloat x=CGRectGetMidX(slider.bounds);UIView *parent=slider.superview;UIView *top=[parent hitTest:[slider convertPoint:CGPointMake(x,-3.5) toView:parent] withEvent:nil],*bottom=[parent hitTest:[slider convertPoint:CGPointMake(x,CGRectGetMaxY(slider.bounds)+3.5) toView:parent] withEvent:nil];
                    UITextField *field=slider==[content valueForKey:@"opacitySlider"]?[content valueForKey:@"opacityField"]:[content valueForKey:@"componentFields"][slider.tag];CGRect sliderRect=[slider convertRect:slider.bounds toView:canvas],fieldRect=[field.superview convertRect:field.superview.bounds toView:canvas];geometry=geometry&&!CGRectIntersectsRect(sliderRect,fieldRect);
                    if(!large){CGFloat spacing=[fixture[3]boolValue]?CGRectGetMinX(sliderRect)-CGRectGetMaxX(fieldRect):CGRectGetMinX(fieldRect)-CGRectGetMaxX(sliderRect);geometry=geometry&&fabs(spacing-16)<.01;}
                    targets=targets&&[slider isKindOfClass:UIColorPickerColorSlider.class]&&fabs(slider.bounds.size.height-36)<.01&&fabs(capsule.bounds.size.height-36)<.01&&slider.bounds.size.width>36&&(top==slider||[top isDescendantOfView:slider])&&(bottom==slider||[bottom isDescendantOfView:slider])&&![slider pointInside:CGPointMake(x,-4.5) withEvent:nil];
                }
                record(@"responsive wrapper and 36pt track with 44pt parent hit area",geometry&&fieldGeometry&&targets&&exactColor(before,content.selectedColor),@{@"fixture":fixture,@"wrapperWidths":widths,@"fields":@(fieldGeometry),@"sliderParentHits":@(targets),@"footerInCanvas":@(geometry)});
            }
        }@finally{[holder setOverrideTraitCollection:nil forChildViewController:content];[content willMoveToParentViewController:nil];[content.view removeFromSuperview];[content removeFromParentViewController];[holder willMoveToParentViewController:nil];[holder.view removeFromSuperview];[holder removeFromParentViewController];}
        UIColorPanelViewController *shared=[panel valueForKey:@"pickerController"];id oldTarget=panel.target;SEL oldAction=panel.action;UIColorValue *oldColor=panel.colorValue;UIColorPanelMode oldMode=panel.mode;BOOL oldContinuous=panel.continuous,oldAlpha=panel.showsAlpha,oldIgnores=UIColor.ignoresAlpha;CGRect oldFrame=shared.view.frame;UISemanticContentAttribute oldDirection=shared.view.semanticContentAttribute;
        @try {
            panel.target=nil;panel.action=NULL;UIColor.ignoresAlpha=NO;panel.showsAlpha=YES;panel.mode=UIColorPanelModeWheel;shared.view.frame=CGRectMake(0,0,414,736);[shared.view setNeedsLayout];[shared.view layoutIfNeeded];
            for(NSNumber *continuous in @[@YES,@NO]){
                panel.target=nil;panel.continuous=continuous.boolValue;panel.colorValue=initial;UIGradientSlider *slider=[shared valueForKey:@"opacitySlider"];UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];[recorder observeSlider:slider];panel.target=recorder;panel.action=@selector(panelAction:);
                @try {
                    CGPoint (^point)(double)=^CGPoint(double fraction){CGFloat h=slider.bounds.size.height;return CGPointMake(h*.5+(slider.bounds.size.width-h)*fraction,h*.5);};
                    [slider dragChangedAtPoint:point(.2)];[slider dragChangedAtPoint:point(.4)];NSUInteger during=recorder.panelActions;[slider dragEnded];NSUInteger ended=recorder.panelActions;[slider dragChangedAtPoint:point(.7)];[slider cancelTrackingWithEvent:nil];
                    BOOL valid=during==(continuous.boolValue?2:0)&&ended==(continuous.boolValue?2:1)&&recorder.panelActions==(continuous.boolValue?3:2)&&recorder.begins==2&&recorder.changes==3&&recorder.ends==2&&recorder.cancels==1&&!slider.active&&fabs(CGColorGetAlpha(panel.colorValue.CGColor)-.7)<1e-9&&[recorder.events isEqual:@[@"begin",@"change",@"change",@"end",@"begin",@"change",@"end",@"cancel"]];
                    record(@"production programmatic drag end and cancel dispatch",valid,@{@"continuous":continuous,@"duringDrag":@(during),@"afterEnd":@(ended),@"afterCancel":@(recorder.panelActions),@"events":recorder.events});
                }@finally{[slider removeTarget:recorder action:NULL forControlEvents:UIControlEventAllEvents];panel.target=nil;if(slider.active)[slider cancelTrackingWithEvent:nil];}
            }
            panel.continuous=NO;
            for(NSNumber *rtl in @[@NO,@YES]){
                shared.view.semanticContentAttribute=rtl.boolValue?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;panel.color=[UIColor colorWithWhite:.5 alpha:.65];[shared.view setNeedsLayout];[shared.view layoutIfNeeded];BOOL valid=YES;NSMutableArray *details=[NSMutableArray new];
                for(NSString *key in @[@"opacitySlider",@"brightnessSlider"]){
                    UIGradientSlider *slider=[shared valueForKey:key];UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];[recorder observeSlider:slider];panel.target=recorder;panel.action=@selector(panelAction:);double before=slider.value;BOOL brightness=[key isEqualToString:@"brightnessSlider"];
                    @try {
                        [slider accessibilityIncrement];double incremented=slider.value;CGFloat brighter=CGColorGetComponents(panel.colorValue.CGColor)[0];[slider accessibilityDecrement];double decremented=slider.value;CGFloat darker=CGColorGetComponents(panel.colorValue.CGColor)[0];
                        BOOL direction=brightness?(slider.accessibilityValueReversed&&incremented<before&&decremented>incremented&&brighter>darker):(incremented>before&&decremented<incremented);BOOL enabled=slider.enabled;slider.enabled=NO;[slider accessibilityIncrement];[slider accessibilityDecrement];slider.enabled=enabled;
                        BOOL item=direction&&recorder.panelActions==2&&recorder.begins==2&&recorder.changes==2&&recorder.ends==2&&recorder.cancels==0&&[recorder.events isEqual:@[@"begin",@"change",@"end",@"begin",@"change",@"end"]]&&fabs(CGColorGetAlpha(panel.colorValue.CGColor)-.65)<1e-9&&(slider.accessibilityTraits&UIAccessibilityTraitAdjustable)&&slider.accessibilityValue.length>0;valid=valid&&item;[details addObject:@{@"slider":key,@"events":recorder.events,@"panelActions":@(recorder.panelActions),@"direction":@(direction)}];
                    }@finally{[slider removeTarget:recorder action:NULL forControlEvents:UIControlEventAllEvents];panel.target=nil;}
                }
                record(@"AX editing lifecycle semantic brightness and disabled behavior",valid,@{@"rtl":rtl,@"sliders":details});
            }
        }@finally{panel.target=nil;panel.action=NULL;UIColor.ignoresAlpha=oldIgnores;panel.continuous=oldContinuous;panel.showsAlpha=oldAlpha;panel.colorValue=oldColor;panel.mode=oldMode;shared.view.semanticContentAttribute=oldDirection;shared.view.frame=oldFrame;[shared.view setNeedsLayout];[shared.view layoutIfNeeded];panel.target=oldTarget;panel.action=oldAction;}
    }@catch(NSException *exception){record(@"touch refinement exception",NO,@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""});}
    NSDictionary *result=@{@"passed":@(passed),@"caseCount":@(cases.count),@"cases":cases,@"scope":@"Finite attached UIKit fixtures and actual production drag/end/cancel and AX method calls. Programmatic, not physical touch. No modal animation, keyboard/IME, error alert, spoken VoiceOver, raster equivalence or original-binary rerun. No global device preference changes."};
    return [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES]&&passed;
}
+ (BOOL)runCompactInputRepairsWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray new];__block BOOL passed=YES;
    BOOL hexOnly=[NSUserDefaults.standardUserDefaults boolForKey:@"UICompactInputRepairsHexOnly"];
    BOOL numericOnly=[NSUserDefaults.standardUserDefaults boolForKey:@"UICompactInputRepairsNumericOnly"];
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL valid,NSDictionary *details){passed=passed&&valid;NSMutableDictionary *entry=[@{@"name":name,@"passed":@(valid)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];};
    BOOL (^exactColor)(UIColorValue *,UIColorValue *)=^BOOL(UIColorValue *a,UIColorValue *b){CGColorRef x=a.CGColor,y=b.CGColor;return x&&y&&CGColorEqualToColor(x,y)&&CFEqual(CGColorGetColorSpace(x),CGColorGetColorSpace(y))&&CGColorGetNumberOfComponents(x)==CGColorGetNumberOfComponents(y)&&memcmp(CGColorGetComponents(x),CGColorGetComponents(y),CGColorGetNumberOfComponents(x)*sizeof(CGFloat))==0;};
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIViewController *anchor=window.rootViewController;
    if([anchor isKindOfClass:UINavigationController.class])anchor=((UINavigationController *)anchor).visibleViewController;
    BOOL attached=NSThread.isMainThread&&window&&!window.hidden&&anchor.view.window==window&&!anchor.presentedViewController;
    NSMutableArray<UIView *> *views=window?[NSMutableArray arrayWithObject:window]:[NSMutableArray new];while(views.count){UIView *view=views.lastObject;[views removeLastObject];if(view.isFirstResponder)attached=NO;[views addObjectsFromArray:view.subviews];}
    if(!attached)record(@"attached idle UIKit host",NO,@{});
    else @try {
        CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
        UIColorValue *(^value)(double)=^UIColorValue *(double red){CGFloat components[]={red,.4,.7,.65};CGColorRef cg=CGColorCreate(space,components);UIColorValue *color=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);return color;};
        UIColorValue *initial=value(.5);
        UIViewController *holder=[UIViewController new];UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=UIColorPanelModeRGB;configuration.savedColorsKey=nil;
        UIColorPanelViewController *content=[[UIColorPanelViewController alloc]initWithColor:initial configuration:configuration];
        id savedList=[NSUserDefaults.standardUserDefaults objectForKey:@"UIColorPickerCatalog.SelectedList.v1"];
        @try {
            [anchor addChildViewController:holder];holder.view.frame=CGRectMake(0,0,320,640);[anchor.view addSubview:holder.view];[holder didMoveToParentViewController:anchor];
            [holder addChildViewController:content];[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryLarge] forChildViewController:content];content.view.frame=holder.view.bounds;[holder.view addSubview:content.view];[content didMoveToParentViewController:holder];
            void (^layout)(void)=^{[content.view setNeedsLayout];[content.view layoutIfNeeded];};layout();
            if(numericOnly){
                UITextField *red=[[content valueForKey:@"componentFields"]firstObject],*hex=[content valueForKey:@"hexField"],*opacity=[content valueForKey:@"opacityField"];
                UIGradientSlider *redSlider=[[content valueForKey:@"componentSliders"]firstObject];
                record(@"native RGB truncation differs intentionally from Float/lroundf Hex",[red.text isEqual:@"127"]&&[redSlider.accessibilityValue isEqual:@"127"]&&[hex.text isEqual:@"8066B3"]&&exactColor(initial,content.selectedColor),@{@"RGB":red.text?:@"",@"Hex":hex.text?:@""});
                for(NSArray *fixture in @[@[@320,@640,UIContentSizeCategoryLarge],@[@640,@320,UIContentSizeCategoryLarge],@[@320,@640,UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]]){
                    CGFloat width=[fixture[0]doubleValue],height=[fixture[1]doubleValue];
                    holder.view.frame=CGRectMake(0,0,width,height);[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:fixture[2]] forChildViewController:content];content.view.frame=holder.view.bounds;layout();
                    BOOL capped=UIContentSizeCategoryIsAccessibilityCategory(fixture[2]),geometry=YES;NSMutableArray *details=[NSMutableArray new];
                    for(UITextField *field in @[red,hex,opacity]){
                        UIContentSizeCategory category=capped?(field==hex?UIContentSizeCategoryExtraExtraExtraLarge:UIContentSizeCategoryAccessibilityExtraLarge):UIContentSizeCategoryLarge;
                        CGFloat expectedFont=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:category]].pointSize;
                        CGFloat expectedWidth=field==hex?100:width>height&&width>450?60:76;
                        CGFloat renderedFont=field.font.pointSize;[field.superview performSelector:NSSelectorFromString(@"refreshFont")];CGFloat configuredFont=field.font.pointSize;
                        BOOL valid=fabs(field.bounds.size.height-36)<.01&&fabs(field.superview.bounds.size.height-44)<.01&&fabs(field.bounds.size.width-expectedWidth)<.01&&renderedFont<=expectedFont+.01&&fabs(configuredFont-expectedFont)<.01&&field.backgroundColor&&CGColorGetAlpha(field.backgroundColor.CGColor)>0&&(!field.superview.backgroundColor||CGColorGetAlpha(field.superview.backgroundColor.CGColor)==0)&&field.adjustsFontSizeToFitWidth&&CGRectContainsRect(field.superview.bounds,field.frame);
                        geometry=geometry&&valid;[details addObject:@{@"tag":@(field.tag),@"field":NSStringFromCGRect(field.frame),@"container":NSStringFromCGRect(field.superview.bounds),@"renderedFont":@(renderedFont),@"configuredFont":@(configuredFont),@"maximumFont":@(expectedFont),@"passed":@(valid)}];
                    }
                    UILabel *hexLabel=[content valueForKey:@"hexLabel"];geometry=geometry&&fabs(hexLabel.font.pointSize-hex.font.pointSize)<.01&&exactColor(initial,content.selectedColor);
                    record(@"36pt decoration inside44pt targets with native field widths and15.5 font caps",geometry,@{@"category":fixture[2],@"width":@(width),@"fields":details});
                }
                holder.view.frame=CGRectMake(0,0,320,640);[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryLarge] forChildViewController:content];content.view.frame=holder.view.bounds;layout();
                UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];content.delegate=recorder;
                hex.text=@" #F80 ";[hex sendActionsForControlEvents:UIControlEventEditingChanged];[hex sendActionsForControlEvents:UIControlEventEditingDidEnd];
                const CGFloat *rgba=CGColorGetComponents(content.selectedColor.CGColor);
                record(@"three-digit Hex expands nibbles on explicit commit and preserves profile alpha callback",rgba[0]==1&&rgba[1]==136/255.0&&rgba[2]==0&&rgba[3]==.65&&CFEqual(CGColorGetColorSpace(content.selectedColor.CGColor),space)&&recorder.selections==1&&![[content valueForKey:@"editedFields"]containsObject:hex],@{@"selections":@(recorder.selections),@"green":@(rgba[1])});
                content.selectedColor=[initial copyWithAlpha:.123456789];recorder.selections=0;
                NSNumberFormatter *percent=[NSNumberFormatter new];percent.numberStyle=NSNumberFormatterPercentStyle;percent.minimumFractionDigits=0;percent.maximumFractionDigits=0;percent.usesGroupingSeparator=NO;
                BOOL idle=[opacity.text isEqual:[percent stringFromNumber:@(.123456789)]],focused=[opacity becomeFirstResponder];NSString *editing=opacity.text;UIColorValue *beforeReturn=content.selectedColor;
                BOOL returned=[opacity.delegate textFieldShouldReturn:opacity];
                record(@"idle opacity rounds display while clean fractional editing leaves canonical alpha exact",idle&&focused&&![editing isEqual:[percent stringFromNumber:@(.123456789)]]&&returned&&exactColor(beforeReturn,content.selectedColor)&&recorder.selections==0,@{@"editing":editing?:@"",@"idle":opacity.text?:@"",@"selections":@(recorder.selections)});
                [opacity becomeFirstResponder];opacity.text=@"44.125%";[opacity sendActionsForControlEvents:UIControlEventEditingChanged];UIToolbar *toolbar=(UIToolbar *)opacity.inputAccessoryView;UIBarButtonItem *done=toolbar.items.lastObject;
                [UIApplication.sharedApplication sendAction:done.action to:done.target from:done forEvent:nil];
                record(@"DecimalPad Done uses existing explicit commit and keeps fractional alpha",opacity.keyboardType==UIKeyboardTypeDecimalPad&&done&&fabs(CGColorGetAlpha(content.selectedColor.CGColor)-.44125)<1e-12&&recorder.selections==1&&!opacity.isFirstResponder&&red.keyboardType==UIKeyboardTypeNumbersAndPunctuation&&hex.keyboardType==UIKeyboardTypeASCIICapable,@{@"alpha":@(CGColorGetAlpha(content.selectedColor.CGColor)),@"selections":@(recorder.selections)});
                [opacity becomeFirstResponder];BOOL selectionValid=YES;
                for(NSString *text in @[@"44.125%",@"\u061c٪٤٤٫١٢٥",@"𝟜𝟜.𝟙𝟚𝟝%"]){
                    opacity.text=text;NSRange first=[text rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet],last=[text rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet options:NSBackwardsSearch];
                    for(NSNumber *offset in @[@0,@(text.length)]){UITextPosition *position=[opacity positionFromPosition:opacity.beginningOfDocument offset:offset.integerValue];opacity.selectedTextRange=[opacity textRangeFromPosition:position toPosition:position];NSInteger actual=[opacity offsetFromPosition:opacity.beginningOfDocument toPosition:opacity.selectedTextRange.start];selectionValid=selectionValid&&actual>=first.location&&actual<=NSMaxRange(last);}
                    UITextPosition *start=[opacity positionFromPosition:opacity.beginningOfDocument offset:first.location],*end=[opacity positionFromPosition:opacity.beginningOfDocument offset:NSMaxRange(last)];opacity.selectedTextRange=[opacity textRangeFromPosition:start toPosition:end];selectionValid=selectionValid&&[opacity offsetFromPosition:opacity.beginningOfDocument toPosition:opacity.selectedTextRange.start]==first.location&&[opacity offsetFromPosition:opacity.beginningOfDocument toPosition:opacity.selectedTextRange.end]==NSMaxRange(last);
                }
                UIColor *tint=[UIColor colorWithRed:.7 green:.1 blue:.4 alpha:1];opacity.tintColor=tint;
                record(@"percentage caret uses UTF16 numeric bounds and accessory tracks tint",selectionValid&&[opacity.inputAccessoryView.tintColor isEqual:tint],@{@"selectionValid":@(selectionValid)});
                [opacity resignFirstResponder];content.delegate=nil;
            }else if(hexOnly){
                UITextField *hex=[content valueForKey:@"hexField"];UILabel *hexLabel=[content valueForKey:@"hexLabel"];UIStackView *hexRow=(UIStackView *)hex.superview.superview;
                UIColorValue *beforeHexLayout=content.selectedColor;
                NSArray *hexFixtures=@[
                    @[@414,UIContentSizeCategoryLarge,@"sRGB IEC61966-2.1 Hex-Farbe #",@"9AFB65"],
                    @[@320,UIContentSizeCategoryLarge,@"sRGB IEC61966-2.1 Hex-Farbe #",@"9AFB65"],
                    @[@320,UIContentSizeCategoryLarge,@"sRGB IEC61966-2.1 十六进制颜色编号",@"09D38E"],
                    @[@320,UIContentSizeCategoryAccessibilityExtraLarge,@"sRGB IEC61966-2.1 Hex-Farbe #",@"9AFB65"]];
                for(NSArray *fixture in hexFixtures){
                    holder.view.frame=CGRectMake(0,0,[fixture[0]doubleValue],640);[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:fixture[1]] forChildViewController:content];content.view.frame=holder.view.bounds;hexLabel.text=fixture[2];hex.text=fixture[3];layout();
                    CGRect textRect=[hex textRectForBounds:hex.bounds];CGFloat textWidth=[hex.text sizeWithAttributes:@{NSFontAttributeName:hex.font}].width;
                    BOOL accessibility=UIContentSizeCategoryIsAccessibilityCategory(fixture[1]);
                    BOOL valid=fabs(hex.superview.bounds.size.width-100)<.01&&fabs(hex.bounds.size.width-100)<.01&&hex.textAlignment==NSTextAlignmentCenter&&hex.adjustsFontSizeToFitWidth&&hex.semanticContentAttribute==UISemanticContentAttributeForceLeftToRight&&[hex.text isEqual:fixture[3]]&&CGRectContainsRect(CGRectInset(hexRow.bounds,-.01,-.01),hexLabel.frame)&&CGRectContainsRect(CGRectInset(hexRow.bounds,-.01,-.01),hex.superview.frame)&&exactColor(beforeHexLayout,content.selectedColor);
                    BOOL separated=hexRow.axis==UILayoutConstraintAxisVertical?CGRectGetMaxY(hexLabel.frame)<=CGRectGetMinY(hex.superview.frame)+.01:CGRectGetMaxX(hexLabel.frame)<=CGRectGetMinX(hex.superview.frame)+.01;
                    valid=valid&&(accessibility||textWidth<=textRect.size.width)&&separated;
                    record(@"six-digit Hex keeps an independent editor beside a wrapping profile label",valid,@{@"width":fixture[0],@"category":fixture[1],@"label":fixture[2],@"text":hex.text,@"textWidth":@(textWidth),@"textRect":NSStringFromCGRect(textRect),@"editor":NSStringFromCGRect(hex.superview.frame),@"labelFrame":NSStringFromCGRect(hexLabel.frame)});
                }
                [holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryLarge] forChildViewController:content];layout();
                BOOL hexFocused=[hex becomeFirstResponder];hex.text=@"09D38E";[hex sendActionsForControlEvents:UIControlEventEditingChanged];hex.selectedTextRange=[hex textRangeFromPosition:[hex positionFromPosition:hex.beginningOfDocument offset:2] toPosition:[hex positionFromPosition:hex.beginningOfDocument offset:4]];
                holder.view.frame=CGRectMake(0,0,414,640);content.view.frame=holder.view.bounds;layout();
                BOOL draftPreserved=hexFocused&&hex.isFirstResponder&&[hex.text isEqual:@"09D38E"]&&[hex offsetFromPosition:hex.beginningOfDocument toPosition:hex.selectedTextRange.start]==2&&[hex offsetFromPosition:hex.beginningOfDocument toPosition:hex.selectedTextRange.end]==4&&exactColor(beforeHexLayout,content.selectedColor);
                record(@"Hex reflow preserves the focused draft, selection and canonical color",draftPreserved,@{@"firstResponderAccepted":@(hexFocused),@"text":hex.text});
                [hex resignFirstResponder];content.selectedColor=initial;holder.view.frame=CGRectMake(0,0,320,640);content.view.frame=holder.view.bounds;layout();
            }else{
            if(![NSUserDefaults.standardUserDefaults boolForKey:@"UICompactInputRepairsCatalogOnly"]){
            BOOL extendedValid=YES;NSMutableArray *adjustments=[NSMutableArray new];
            for(NSNumber *red in @[@(-.25),@1.25,@.5]){
                content.selectedColor=value(red.doubleValue);layout();UIColorValue *before=content.selectedColor;NSData *beforeICC=CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(before.CGColor)));
                UIGradientSlider *slider=[[content valueForKey:@"componentSliders"]firstObject];UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];content.delegate=recorder;[recorder observeSlider:slider];
                @try {
                    BOOL extended=red.doubleValue<0||red.doubleValue>1,blocked=YES;
                    if(extended){if(red.doubleValue<0)[slider accessibilityDecrement];else[slider accessibilityIncrement];blocked=exactColor(before,content.selectedColor)&&recorder.events.count==0&&recorder.selections==0;}
                    if(red.doubleValue>1)[slider accessibilityDecrement];else[slider accessibilityIncrement];
                    double expected=red.doubleValue<0?.1:red.doubleValue>1?.9:.6;const CGFloat *components=CGColorGetComponents(content.selectedColor.CGColor);
                    BOOL inward=fabs(components[0]-expected)<1e-12;
                    if(!extended){[slider accessibilityDecrement];expected=.5;components=CGColorGetComponents(content.selectedColor.CGColor);}
                    NSData *afterICC=CFBridgingRelease(CGColorSpaceCopyICCData(CGColorGetColorSpace(content.selectedColor.CGColor)));
                    NSArray *events=extended?@[@"begin",@"change",@"end"]:@[@"begin",@"change",@"end",@"begin",@"change",@"end"];
                    BOOL valid=blocked&&inward&&fabs(components[0]-expected)<1e-12&&components[1]==.4&&components[2]==.7&&components[3]==.65&&CFEqual(CGColorGetColorSpace(content.selectedColor.CGColor),space)&&(beforeICC?[beforeICC isEqual:afterICC]:afterICC==nil)&&[recorder.events isEqual:events]&&recorder.selections==(extended?1:2);
                    extendedValid=extendedValid&&valid;[adjustments addObject:@{@"sourceRed":red,@"passed":@(valid),@"outwardSuppressed":@(blocked),@"resultRed":@(components[0]),@"events":recorder.events,@"selections":@(recorder.selections)}];
                }@finally{[slider removeTarget:recorder action:NULL forControlEvents:UIControlEventAllEvents];content.delegate=nil;}
            }
            record(@"extended AX directions preserve canonical values and edit lifecycle",extendedValid,@{@"samples":adjustments});
            content.selectedColor=initial;UISegmentedControl *precision=[content valueForKey:@"precision"];precision.selectedSegmentIndex=0;[content precisionChanged:precision];layout();
            UITextField *field=[[content valueForKey:@"componentFields"]firstObject];UIGradientSlider *slider=[[content valueForKey:@"componentSliders"]firstObject];UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];content.delegate=recorder;[recorder observeSlider:slider];
            @try {
                BOOL focused=[field becomeFirstResponder]&&field.isFirstResponder,displayValid=focused;NSMutableArray *displays=[NSMutableArray new];
                [slider sendActionsForControlEvents:UIControlEventEditingDidBegin];
                for(NSNumber *input in @[@(1.0/3),@(1.0/7)]){slider.value=input.doubleValue;[slider sendActionsForControlEvents:UIControlEventValueChanged];NSString *expected=[UIColorPanelAppearance formatNumber:trunc(input.doubleValue*255) significantDigits:0];displayValid=displayValid&&field.isFirstResponder&&[field.text isEqual:expected]&&fabs(CGColorGetComponents(content.selectedColor.CGColor)[0]-input.doubleValue)<1e-12;[displays addObject:field.text?:@""];}
                [slider sendActionsForControlEvents:UIControlEventEditingDidEnd];UIColorValue *beforeReturn=content.selectedColor;NSUInteger beforeSelections=recorder.selections;
                BOOL returned=[field.delegate textFieldShouldReturn:field];
                BOOL valid=displayValid&&returned&&!field.isFirstResponder&&exactColor(beforeReturn,content.selectedColor)&&recorder.selections==beforeSelections&&beforeSelections==2&&![[content valueForKey:@"editedFields"]containsObject:field]&&[recorder.events isEqual:@[@"begin",@"change",@"change",@"end"]];
                record(@"focused RGB 8-bit display and Return preserve slider precision",valid,@{@"firstResponderAccepted":@(focused),@"displays":displays,@"returnAccepted":@(returned),@"resultRed":@(CGColorGetComponents(content.selectedColor.CGColor)[0]),@"events":recorder.events});
            }@finally{[field resignFirstResponder];[slider removeTarget:recorder action:NULL forControlEvents:UIControlEventAllEvents];content.delegate=nil;}
            }
            content.mode=UIColorPanelModeColorList;UIColorPickerCatalogController *catalog=[content valueForKey:@"catalogController"];
            UIColorList *list=[[UIColorList alloc]initWithName:@"A long color palette title for the compact layout"];
            NSString *firstName=@"A long first color name that wraps onto several lines";[list setColorValue:initial forKey:firstName];[content attachColorList:list];[catalog setValue:list forKey:@"currentColorList"];[catalog reloadCatalog];
            UISearchBar *search=[catalog valueForKey:@"searchBar"];UITableView *table=[catalog valueForKey:@"tableView"];BOOL catalogValid=YES;NSMutableArray *geometries=[NSMutableArray new];
            for(NSString *category in @[UIContentSizeCategoryLarge,UIContentSizeCategoryAccessibilityExtraLarge]){
                holder.view.frame=CGRectMake(0,0,320,320);[holder setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:category] forChildViewController:content];content.view.frame=holder.view.bounds;search.text=@"";[catalog reloadCatalog];layout();
                CGRect keyboard=[content.view convertRect:CGRectMake(0,200,320,120) toCoordinateSpace:window.screen.coordinateSpace];[content keyboardChanged:[NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification object:nil userInfo:@{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:keyboard]}]];
                // Provider self-sizing invalidates its parent once; consume that layout pass.
                [catalog.view layoutIfNeeded];layout();[table layoutIfNeeded];
                CGRect row=[table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];CGFloat viewport=table.bounds.size.height-table.adjustedContentInset.top-table.adjustedContentInset.bottom;
                UIView *header=[catalog valueForKey:@"headerStack"];CGRect headerRect=[header convertRect:header.bounds toView:catalog.view],searchRect=[search convertRect:search.bounds toView:catalog.view],tableRect=[table convertRect:table.bounds toView:catalog.view];
                BOOL valid=[table numberOfRowsInSection:0]==1&&viewport+1/window.screen.scale>=row.size.height&&row.size.height>=44&&CGRectGetMaxY(headerRect)<=CGRectGetMinY(searchRect)+.01&&CGRectGetMaxY(searchRect)<=CGRectGetMinY(tableRect)+.01&&[[[catalog valueForKey:@"listButton"]currentTitle]isEqual:list.name]&&[content.traitCollection.preferredContentSizeCategory isEqual:category];
                search.text=@"no matching compact fixture";[catalog reloadCatalog];[catalog.view layoutIfNeeded];layout();[table layoutIfNeeded];UIView *empty=[catalog valueForKey:@"emptyView"];CGFloat emptyViewport=table.bounds.size.height-table.adjustedContentInset.top-table.adjustedContentInset.bottom;
                valid=valid&&[table numberOfRowsInSection:0]==0&&table.tableHeaderView==empty&&empty.bounds.size.height>0&&emptyViewport+1/window.screen.scale>=empty.bounds.size.height;catalogValid=catalogValid&&valid;
                [geometries addObject:@{@"category":category,@"passed":@(valid),@"tableViewport":@(viewport),@"firstRowHeight":@(row.size.height),@"emptyViewport":@(emptyViewport),@"emptyHeight":@(empty.bounds.size.height)}];
            }
            record(@"compact catalog keeps a complete first row and empty state",catalogValid,@{@"width":@320,@"height":@320,@"syntheticKeyboardHeight":@120,@"fixtures":geometries});
            }
        }@finally{
            [content.view endEditing:YES];content.delegate=nil;[content setValue:[NSValue valueWithCGRect:CGRectNull] forKey:@"keyboardFrame"];
            [holder setOverrideTraitCollection:nil forChildViewController:content];[content willMoveToParentViewController:nil];[content.view removeFromSuperview];[content removeFromParentViewController];[holder willMoveToParentViewController:nil];[holder.view removeFromSuperview];[holder removeFromParentViewController];
            if(savedList)[NSUserDefaults.standardUserDefaults setObject:savedList forKey:@"UIColorPickerCatalog.SelectedList.v1"];else[NSUserDefaults.standardUserDefaults removeObjectForKey:@"UIColorPickerCatalog.SelectedList.v1"];CGColorSpaceRelease(space);
        }
    }@catch(NSException *exception){record(@"compact input repair exception",NO,@{@"exception":exception.name?:@"",@"reason":exception.reason?:@""});}
    NSDictionary *result=@{@"passed":@(passed),@"caseCount":@(cases.count),@"cases":cases,@"scope":numericOnly?@"Focused numeric-field geometry/font caps, native display fixtures, three-digit Hex, exact fractional opacity, programmatic UITextInput selection and real first-responder/toolbar action. No physical typing, spoken VoiceOver or original-binary runtime rerun.":hexOnly?@"Focused Hex editor geometry at 414/320pt, German/Chinese label stress strings, scoped Dynamic Type and actual first-responder draft/selection preservation across reflow. Text changes and selection are programmatic; no physical touch, IME, spoken VoiceOver, global settings or original-binary rerun.":@"Three finite attached UIKit fixtures: programmatic AX/control events, actual first-responder status with a programmatic Return delegate call, and synthetic keyboard-frame/scoped Dynamic Type geometry. No physical touch, IME, spoken VoiceOver, global settings, saved palette writes or original-binary rerun."};
    return [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES]&&passed;
}
+ (void)runReviewRepairsWithOutputURL:(NSURL *)url {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self runReviewRepairsWithOutputURL:url];});return;}
    UIReviewRepairsRunner *runner=[UIReviewRepairsRunner new];runner.outputURL=url;[runner start];
}
+ (BOOL)runWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray array];BOOL passed=YES;
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);CGFloat components[]={.9,.16,.12,.65};CGColorRef cg=CGColorCreate(space,components);UIColorValue *initial=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);CGColorSpaceRelease(space);
    NSArray *sizes=@[[NSValue valueWithCGSize:CGSizeMake(280,460)],[NSValue valueWithCGSize:CGSizeMake(320,568)],[NSValue valueWithCGSize:CGSizeMake(375,667)],[NSValue valueWithCGSize:CGSizeMake(414,736)],[NSValue valueWithCGSize:CGSizeMake(336,645)],[NSValue valueWithCGSize:CGSizeMake(640,600)],[NSValue valueWithCGSize:CGSizeMake(768,600)],[NSValue valueWithCGSize:CGSizeMake(320,360)],[NSValue valueWithCGSize:CGSizeMake(304,460)]];
    NSMutableDictionary<NSNumber *,UIColorPanelViewController *> *providerPanels=[NSMutableDictionary new];
    for(NSValue *value in sizes){
        NSArray *commonFooterGeometry=nil;
        for(NSNumber *mode in @[@(UIColorPanelModeWheel),@(UIColorPanelModeRGB),@(UIColorPanelModeColorList),@(UIColorPanelModeImage),@(UICOLORPANEL_ENABLE_PENCILS ? UIColorPanelModePencils : UIColorPanelModeGrid)]){
            // Resize the same loaded provider through narrow, wide, then narrow
            // hosts; rebuilding it here could conceal stale constraint state.
            UIColorPanelViewController *panel=providerPanels[mode];
            if(!panel){UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];configuration.initialMode=mode.integerValue;configuration.savedColorsKey=nil;configuration.showsAlpha=YES;panel=[[UIColorPanelViewController alloc]initWithColor:initial configuration:configuration];[panel loadViewIfNeeded];providerPanels[mode]=panel;}
            panel.view.frame=(CGRect){CGPointZero,value.CGSizeValue};[panel.view setNeedsLayout];[panel.view layoutIfNeeded];
            UIView *canvas=[panel valueForKey:@"rootStack"],*host=[panel valueForKey:@"providerHost"],*footer=[panel valueForKey:@"footer"];[canvas layoutIfNeeded];[host layoutIfNeeded];
            BOOL valid=CGAffineTransformIsIdentity(canvas.transform)&&CGRectContainsRect(CGRectInset(canvas.bounds,-.000001,-.000001),host.frame)&&CGRectContainsRect(CGRectInset(canvas.bounds,-.000001,-.000001),footer.frame);NSMutableDictionary *entry=[@{@"size":NSStringFromCGSize(value.CGSizeValue),@"mode":mode,@"canvas":NSStringFromCGRect(canvas.bounds),@"provider":NSStringFromCGRect(host.frame)}mutableCopy];
            UISegmentedControl *toolbar=[panel valueForKey:@"modeControl"];CGRect toolbarRect=[toolbar convertRect:toolbar.bounds toView:canvas];
            UIView *opacityRow=[panel valueForKey:@"opacityRow"];UITextField *opacityField=[panel valueForKey:@"opacityField"];
            BOOL nativeBounds=[toolbar isKindOfClass:UISegmentedControl.class]&&toolbar.bounds.size.height>=44-.01&&toolbar.accessibilityLabel.length>0&&CGRectContainsRect(CGRectInset(canvas.bounds,-.01,-.01),toolbarRect)&&CGRectContainsRect(CGRectInset(opacityRow.bounds,-.01,-.01),[opacityField.superview convertRect:opacityField.superview.bounds toView:opacityRow])&&[opacityField.superview isKindOfClass:NSClassFromString(@"UIColorPanelNumericField")]&&opacityField.borderStyle==UITextBorderStyleNone&&opacityField.superview.bounds.size.height>=44-.01;
            NSNumberFormatter *percentFormatter=[NSNumberFormatter new];percentFormatter.numberStyle=NSNumberFormatterPercentStyle;percentFormatter.maximumFractionDigits=0;NSString *originalOpacityText=opacityField.text;opacityField.text=[percentFormatter stringFromNumber:@1];CGRect opacityTextRect=[opacityField textRectForBounds:opacityField.bounds];CGSize opacityTextSize=[opacityField.text sizeWithAttributes:@{NSFontAttributeName:opacityField.font}];nativeBounds=nativeBounds&&opacityTextRect.size.width+.01>=ceil(opacityTextSize.width);opacityField.text=originalOpacityText;
            for(UITextField *field in [panel valueForKey:@"componentFields"]){CGRect inRow=[field convertRect:field.bounds toView:field.superview];nativeBounds=nativeBounds&&[field.superview isKindOfClass:NSClassFromString(@"UIColorPanelNumericField")]&&field.borderStyle==UITextBorderStyleNone&&CGRectContainsRect(CGRectInset(field.superview.bounds,-.01,-.01),inRow)&&field.superview.bounds.size.height>=44-.01&&field.bounds.size.width>0;}
            UITextField *hex=[panel valueForKey:@"hexField"];if(hex.superview)nativeBounds=nativeBounds&&[hex.superview isKindOfClass:NSClassFromString(@"UIColorPanelNumericField")]&&hex.borderStyle==UITextBorderStyleNone&&hex.superview.bounds.size.height>=44-.01&&CGRectContainsRect(CGRectInset(hex.superview.bounds,-.01,-.01),hex.frame);
            if(mode.integerValue==UIColorPanelModeColorList){UIColorPickerCatalogController *catalog=[panel valueForKey:@"catalogController"];[catalog.view layoutIfNeeded];UISearchBar *search=[catalog valueForKey:@"searchBar"];CGRect searchRect=[search convertRect:search.bounds toView:host];nativeBounds=nativeBounds&&[search isKindOfClass:UISearchBar.class]&&search.bounds.size.width>0&&CGRectContainsRect(CGRectInset(host.bounds,-.01,-.01),searchRect);entry[@"search"]=NSStringFromCGRect(searchRect);}
            valid=valid&&nativeBounds;entry[@"nativeControlsContained"]=@(nativeBounds);entry[@"toolbar"]=NSStringFromCGRect(toolbarRect);entry[@"opacityField"]=NSStringFromCGRect(opacityField.frame);
            UIColorPickerSwatchesView *swatches=[panel valueForKey:@"swatchesView"];[swatches layoutIfNeeded];[swatches.collectionView layoutIfNeeded];
            UIButton *saved=[panel valueForKey:@"savedColorsButton"];UIColorPanelColorWell *well=[panel valueForKey:@"currentWell"];
            NSInteger columns=[swatches.favoriteLayout numberOfItemsFittingInBoundsWidth:swatches.bounds.size.width];
            BOOL compact=swatches.superview==saved&&!swatches.userInteractionEnabled&&swatches.accessibilityElementsHidden&&saved.bounds.size.width>=44&&saved.bounds.size.height>=44&&saved.accessibilityLabel.length>0&&saved.accessibilityHint.length>0&&well.bounds.size.width>=44&&well.bounds.size.height>=44&&well.accessibilityValue.length>0;
            if(!swatches.hidden)compact=compact&&CGRectContainsRect(CGRectInset(saved.bounds,-.01,-.01),swatches.frame);
            NSArray *geometry=@[NSStringFromCGRect(footer.frame),NSStringFromCGRect(well.frame),NSStringFromCGRect(opacityRow.frame),NSStringFromCGRect(saved.frame)];
            BOOL sharedGeometry=!commonFooterGeometry||[commonFooterGeometry isEqual:geometry];if(!commonFooterGeometry)commonFooterGeometry=geometry;
            valid=valid&&compact&&sharedGeometry&&columns>=1&&!swatches.collectionView.alwaysBounceHorizontal&&swatches.collectionView.contentSize.width<=swatches.bounds.size.width+.01;entry[@"favoriteColumns"]=@(columns);entry[@"compactPreviewIsNoninteractive"]=@(compact);entry[@"commonFooterAcrossModes"]=@(sharedGeometry);entry[@"rootTransform"]=NSStringFromCGAffineTransform(canvas.transform);entry[@"footer"]=geometry;
            if(mode.integerValue==UIColorPanelModeWheel){UIColorPickerWheelView *wheel=[panel valueForKey:@"wheel"];UIGradientSlider *brightness=[panel valueForKey:@"brightnessSlider"];CGRect wheelRect=[wheel convertRect:wheel.bounds toView:host],track=[brightness convertRect:brightness.bounds toView:host];valid=valid&&CGRectContainsRect(host.bounds,wheelRect)&&CGRectContainsRect(host.bounds,track)&&CGRectGetMaxY(wheelRect)<=CGRectGetMinY(track)+.01&&fabs(wheelRect.size.width-wheelRect.size.height)<.01;entry[@"wheel"]=NSStringFromCGRect(wheelRect);entry[@"brightness"]=NSStringFromCGRect(track);}
            if(mode.integerValue==UIColorPanelModeImage){UIColorPickerUserView *sampler=[panel valueForKey:@"imageSampler"];valid=valid&&sampler.image.CGImage&&sampler.contentMode==UIViewContentModeScaleAspectFit;entry[@"imagePixels"]=@[@(CGImageGetWidth(sampler.image.CGImage)),@(CGImageGetHeight(sampler.image.CGImage))];}
#if UICOLORPANEL_ENABLE_PENCILS
            if(mode.integerValue==UIColorPanelModePencils){UIColorPickerPencils *pencils=[panel valueForKey:@"pencilsPicker"];valid=valid&&pencils.pencilView!=nil&&[pencils.pencilView _pencils].count==48;}
#endif
            entry[@"canonicalColorPreserved"]=@([panel.selectedColor isEqual:initial]);if(mode.integerValue!=UIColorPanelModeColorList)valid=valid&&[panel.selectedColor isEqual:initial];
            entry[@"passed"]=@(valid);[cases addObject:entry];passed=passed&&valid;
        }
    }
    UIColorPanelConfiguration *config=[UIColorPanelConfiguration new];config.savedColorsKey=nil;config.showsAlpha=YES;UIColorPanelViewController *panel=[[UIColorPanelViewController alloc]initWithColor:initial configuration:config];[panel loadViewIfNeeded];panel.view.frame=CGRectMake(0,0,336,645);[panel.view layoutIfNeeded];
    UIColorPickerSwatchesView *favorites=[panel valueForKey:@"swatchesView"];for(NSUInteger index=0;index<45;index++)[favorites setColor:index==0?[initial copyWithAlpha:0]:initial forSlot:index];
    NSArray *savedSlots=favorites.slots;UIColorPanelSavedColorsController *manager=[[UIColorPanelSavedColorsController alloc]initWithSwatchesView:favorites];__weak UIColorPanelViewController *weakPanel=panel;manager.restorationHandler=^{[weakPanel restoreSavedColors];};[manager loadViewIfNeeded];manager.view.frame=CGRectMake(0,0,320,220);[manager.view setNeedsLayout];[manager.view layoutIfNeeded];[favorites.collectionView layoutIfNeeded];
    UICollectionViewLayoutAttributes *first=[favorites.favoriteLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]],*next=[favorites.favoriteLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    BOOL overflow=favorites.presentedColors.count==45&&CGColorGetAlpha([favorites colorAtIndex:0].CGColor)==0&&[favorites.slots isEqual:savedSlots]&&favorites.userInteractionEnabled&&!favorites.accessibilityElementsHidden&&first.frame.size.width>=44&&first.frame.size.height>=44&&!CGRectIntersectsRect(first.frame,next.frame)&&favorites.collectionView.contentSize.height>favorites.bounds.size.height&&favorites.collectionView.contentSize.width<=favorites.bounds.size.width+.01;
    [manager viewDidDisappear:NO];[panel.view setNeedsLayout];[panel.view layoutIfNeeded];BOOL restored=favorites.superview==[panel valueForKey:@"savedColorsButton"]&&!favorites.userInteractionEnabled&&favorites.accessibilityElementsHidden&&[favorites.slots isEqual:savedSlots];
    [cases addObject:@{@"name":@"expanded saved colors reuse all 45 slots with nonoverlapping 44pt targets and restore compact preview",@"passed":@(overflow&&restored),@"firstTarget":NSStringFromCGRect(first.frame),@"nextTarget":NSStringFromCGRect(next.frame),@"previewRestored":@(restored)}];passed=passed&&overflow&&restored;
    panel.showsAlpha=NO;[panel.view layoutIfNeeded];UIView *host=[panel valueForKey:@"providerHost"],*footer=[panel valueForKey:@"footer"];BOOL hidden=CGRectGetMaxY(host.frame)==CGRectGetMinY(footer.frame);[cases addObject:@{@"name":@"hidden alpha reclaims provider height",@"passed":@(hidden)}];passed=passed&&hidden;
    // Native appearance is now intentional. Check the mode/mask contract, not
    // the former arrangement of five individual buttons or AppKit dimensions.
    UIColorPanelConfiguration *nativeConfiguration=[UIColorPanelConfiguration new];nativeConfiguration.savedColorsKey=nil;nativeConfiguration.showsAlpha=YES;
    UIColorPanelViewController *nativePanel=[[UIColorPanelViewController alloc]initWithColor:initial configuration:nativeConfiguration];[nativePanel loadViewIfNeeded];nativePanel.view.frame=CGRectMake(0,0,336,645);
    UISegmentedControl *modeControl=[nativePanel valueForKey:@"modeControl"];
    NSArray<NSNumber *> *expectedModes=@[@(UIColorPanelModeWheel),@(UIColorPanelModeRGB),@(UIColorPanelModeColorList),@(UIColorPanelModeCustomPalette),@(UICOLORPANEL_ENABLE_PENCILS ? UIColorPanelModePencils : UIColorPanelModeGrid)];
    BOOL modeMapping=[modeControl isKindOfClass:UISegmentedControl.class]&&[[nativePanel valueForKey:@"modeSegmentModes"] isEqual:expectedModes]&&modeControl.numberOfSegments==expectedModes.count;
    for(NSInteger mode=UIColorPanelModeGray;mode<=UIColorPanelModeCrayon;mode++){
        nativePanel.mode=mode;NSInteger representative=mode<=UIColorPanelModeHSB?UIColorPanelModeRGB:nativePanel.mode;
        modeMapping=modeMapping&&modeControl.selectedSegmentIndex==(NSInteger)[expectedModes indexOfObject:@(representative)];
    }
    nativePanel.mode=UIColorPanelModeHSB;
    modeControl.selectedSegmentIndex=0;[modeControl sendActionsForControlEvents:UIControlEventValueChanged];modeMapping=modeMapping&&nativePanel.mode==UIColorPanelModeWheel;
    modeControl.selectedSegmentIndex=1;[modeControl sendActionsForControlEvents:UIControlEventValueChanged];modeMapping=modeMapping&&nativePanel.mode==UIColorPanelModeHSB;
    [cases addObject:@{@"name":@"native segmented toolbar preserves all mode mappings and last numeric mode",@"passed":@(modeMapping)}];passed=passed&&modeMapping;
    nativePanel.pickerMask=UIColorPanelWheelModeMask|UIColorPanelGrayModeMask|UIColorPanelHSBModeMask;
    NSArray *limitedModes=@[@(UIColorPanelModeWheel),@(UIColorPanelModeRGB)];BOOL masks=[[nativePanel valueForKey:@"modeSegmentModes"] isEqual:limitedModes]&&modeControl.numberOfSegments==2;
    nativePanel.mode=UIColorPanelModeHSB;modeControl.selectedSegmentIndex=0;[modeControl sendActionsForControlEvents:UIControlEventValueChanged];modeControl.selectedSegmentIndex=1;[modeControl sendActionsForControlEvents:UIControlEventValueChanged];masks=masks&&nativePanel.mode==UIColorPanelModeHSB&&modeControl.selectedSegmentIndex==1;
    nativePanel.pickerMask=UIColorPanelCustomPaletteModeMask|UIColorPanelCrayonModeMask;
    NSArray *imagePencilModes=@[@(UIColorPanelModeCustomPalette),@(UICOLORPANEL_ENABLE_PENCILS ? UIColorPanelModePencils : UIColorPanelModeGrid)];masks=masks&&[[nativePanel valueForKey:@"modeSegmentModes"] isEqual:imagePencilModes]&&modeControl.numberOfSegments==2;
    for(NSInteger index=0;index<2;index++){modeControl.selectedSegmentIndex=index;[modeControl sendActionsForControlEvents:UIControlEventValueChanged];masks=masks&&nativePanel.mode==[imagePencilModes[index] integerValue]&&modeControl.selectedSegmentIndex==index;}
    [cases addObject:@{@"name":@"picker mask removes unavailable segments without changing mode identity",@"passed":@(masks)}];passed=passed&&masks;
    nativePanel.pickerMask=UIColorPanelAllModesMask;nativePanel.showsAlpha=YES;BOOL rounded=YES;NSMutableArray *fieldChecks=[NSMutableArray array];
    for(NSInteger mode=UIColorPanelModeGray;mode<=UIColorPanelModeHSB;mode++){
        nativePanel.mode=mode;[nativePanel.view setNeedsLayout];[nativePanel.view layoutIfNeeded];
        NSMutableArray<UITextField *> *fields=[[nativePanel valueForKey:@"componentFields"] mutableCopy];
        UITextField *hex=[nativePanel valueForKey:@"hexField"];if(hex.superview)[fields addObject:hex];
        UITextField *opacity=[nativePanel valueForKey:@"opacityField"];[fields addObject:opacity];
        for(UITextField *field in fields){BOOL valid=[field isKindOfClass:UITextField.class]&&[field.superview isKindOfClass:NSClassFromString(@"UIColorPanelNumericField")]&&field.borderStyle==UITextBorderStyleNone&&field.superview.bounds.size.height>=44-.01&&field.bounds.size.width>0&&CGRectContainsRect(CGRectInset(field.superview.bounds,-.01,-.01),field.frame);rounded=rounded&&valid;[fieldChecks addObject:@{@"mode":@(mode),@"field":field.accessibilityLabel?:@"",@"bounds":NSStringFromCGRect(field.bounds),@"passed":@(valid)}];}
    }
    UITextField *opacity=[nativePanel valueForKey:@"opacityField"];NSNumberFormatter *fullPercent=[NSNumberFormatter new];fullPercent.numberStyle=NSNumberFormatterPercentStyle;fullPercent.maximumFractionDigits=0;NSString *priorText=opacity.text;opacity.text=[fullPercent stringFromNumber:@1];CGRect textRect=[opacity textRectForBounds:opacity.bounds];CGSize percentSize=[opacity.text sizeWithAttributes:@{NSFontAttributeName:opacity.font}];BOOL percentVisible=textRect.size.width+.01>=ceil(percentSize.width)&&textRect.size.height+.01>=ceil(opacity.font.lineHeight);opacity.text=priorText;rounded=rounded&&percentVisible;
    [cases addObject:@{@"name":@"numeric and hex fields use recovered rounded wrappers and borderless text with visible full opacity",@"passed":@(rounded),@"fields":fieldChecks,@"opacityTextRect":NSStringFromCGRect(textRect),@"percentTextSize":NSStringFromCGSize(percentSize)}];passed=passed&&rounded;
    UIColorList *searchList=[[UIColorList alloc]initWithName:@"Native UI filter validation"];
    [searchList setColor:UIColor.redColor forKey:@"Crimson"];[searchList setColor:UIColor.yellowColor forKey:@"Cream"];[searchList setColor:UIColor.blueColor forKey:@"Azure"];
    UIColorPickerCatalogController *catalog=[[UIColorPickerCatalogController alloc]initWithColorLists:@[searchList] selectedColor:initial];[catalog loadViewIfNeeded];catalog.view.frame=CGRectMake(0,0,224,320);[catalog.view layoutIfNeeded];
    UISearchBar *bar=[catalog valueForKey:@"searchBar"];BOOL search=[bar isKindOfClass:UISearchBar.class]&&bar.delegate==(id)catalog&&bar.bounds.size.height>=44-.01;
    if(search){bar.text=@"cr";[bar.delegate searchBar:bar textDidChange:bar.text];search=[[catalog valueForKey:@"visibleKeys"] isEqual:@[@"Crimson",@"Cream"]];bar.text=@"";[bar.delegate searchBar:bar textDidChange:bar.text];search=search&&[[catalog valueForKey:@"visibleKeys"] count]==3;}
    [cases addObject:@{@"name":@"native UISearchBar delegate filters and clears the existing catalog",@"passed":@(search),@"searchBounds":NSStringFromCGRect(bar.bounds)}];passed=passed&&search;
    nativePanel.mode=UIColorPanelModeRGB;
    UIColorPickerImagePaletteController *imageController=[nativePanel valueForKey:@"imagePaletteController"];[imageController loadViewIfNeeded];
    UIColorList *builtin=[UIColorList colorListNamed:@"Apple"];
    UIColorPickerCatalogController *builtinCatalog=[[UIColorPickerCatalogController alloc]initWithColorLists:builtin?@[builtin]:@[] selectedColor:initial];[builtinCatalog loadViewIfNeeded];
    NSArray<UIColorPanelMenuButton *> *popupButtons=@[[nativePanel valueForKey:@"modelMenuButton"],[nativePanel valueForKey:@"optionsMenuButton"],[builtinCatalog valueForKey:@"listButton"],[builtinCatalog valueForKey:@"actionsButton"],[imageController valueForKey:@"chooseButton"],[imageController valueForKey:@"manageButton"]];
    BOOL menuRoutes=YES;for(UIColorPanelMenuButton *button in popupButtons){
        menuRoutes=menuRoutes&&[button isKindOfClass:UIColorPanelMenuButton.class];
        if(@available(iOS 14.0,*)){[button reloadMenu];menuRoutes=menuRoutes&&button.usesPrimaryMenu&&[button.menu isKindOfClass:UIMenu.class];}
        else if(@available(iOS 13.0,*)){BOOL context=NO;for(id<UIInteraction> interaction in button.interactions)context=context||[interaction isKindOfClass:UIContextMenuInteraction.class];menuRoutes=menuRoutes&&!button.usesPrimaryMenu&&context&&button.allTargets.count>0;}
        else menuRoutes=menuRoutes&&!button.usesPrimaryMenu&&button.allTargets.count>0;
    }
    [cases addObject:@{@"name":@"all six popup buttons use the version appropriate public menu transport",@"passed":@(menuRoutes)}];passed=passed&&menuRoutes;
    if(@available(iOS 13.0,*)){
        UIMenu *models=[nativePanel sliderModelMenu],*options=[nativePanel sliderOptionsMenu],*lists=[builtinCatalog menuForColorLists],*listActions=[builtinCatalog menuForColorListActions],*images=[imageController menuForImagePalettes],*imageActions=[imageController menuForImagePaletteActions];
        BOOL modelStates=models.children.count==4;NSUInteger modelChecked=0;
        for(UIAction *action in models.children)if([action isKindOfClass:UIAction.class]&&action.state==UIMenuElementStateOn)modelChecked++;
        BOOL optionsStates=options.children.count==2;
        for(UIMenu *group in options.children){NSUInteger checked=0;for(UIAction *action in group.children)if([action isKindOfClass:UIAction.class]&&action.state==UIMenuElementStateOn)checked++;optionsStates=optionsStates&&checked==1;}
        BOOL protectedLists=lists.children.count==1&&((UIAction *)lists.children.firstObject).state==UIMenuElementStateOn&&listActions.children.count==2;
        if(listActions.children.count==2){UIMenu *paletteGroup=(UIMenu *)listActions.children[0],*colorGroup=(UIMenu *)listActions.children[1];protectedLists=protectedLists&&[paletteGroup isKindOfClass:UIMenu.class]&&[colorGroup isKindOfClass:UIMenu.class]&&paletteGroup.children.count==4&&colorGroup.children.count==2&&(paletteGroup.options&UIMenuOptionsDisplayInline)&&(colorGroup.options&UIMenuOptionsDisplayInline);
            if(paletteGroup.children.count==4&&colorGroup.children.count==2){UIAction *rename=(UIAction *)paletteGroup.children[2],*remove=(UIAction *)paletteGroup.children[3],*add=(UIAction *)colorGroup.children[0],*delete=(UIAction *)colorGroup.children[1];protectedLists=protectedLists&&(rename.attributes&UIMenuElementAttributesDisabled)&&(remove.attributes&UIMenuElementAttributesDisabled)&&(remove.attributes&UIMenuElementAttributesDestructive)&&(add.attributes&UIMenuElementAttributesDisabled)&&(delete.attributes&UIMenuElementAttributesDisabled)&&(delete.attributes&UIMenuElementAttributesDestructive);}}
        BOOL protectedImage=images.children.count>0&&((UIAction *)images.children.firstObject).state==UIMenuElementStateOn&&imageActions.children.count==5;
        if(imageActions.children.count==5){UIAction *rename=(UIAction *)imageActions.children[1],*remove=(UIAction *)imageActions.children[2];protectedImage=protectedImage&&(rename.attributes&UIMenuElementAttributesDisabled)&&(remove.attributes&UIMenuElementAttributesDisabled)&&(remove.attributes&UIMenuElementAttributesDestructive);}
        BOOL menuStates=modelStates&&modelChecked==1&&optionsStates&&protectedLists&&protectedImage;
        [cases addObject:@{@"name":@"native menus retain independent checked groups and protected builtin management actions",@"passed":@(menuStates)}];passed=passed&&menuStates;
    }
    // Scoped traits and semantic direction leave the device's language, text
    // size and orientation untouched. These are finite layout fixtures, not a
    // claim of a VoiceOver or translated-screen walkthrough.
    NSMutableArray *longNameChecks=[NSMutableArray new];BOOL longNames=YES;
    for(NSString *name in @[@"Eine besonders lange benutzerdefinierte Farbpalette für die Darstellung",@"用于检查原生选择按钮布局的较长自定义颜色目录名称",@"لوحة ألوان مخصصة ذات اسم طويل لاختبار اتجاه الواجهة"]){
        UIColorList *list=[[UIColorList alloc]initWithName:name];[list setColor:UIColor.redColor forKey:@"Red"];
        UIColorPickerCatalogController *longCatalog=[[UIColorPickerCatalogController alloc]initWithColorLists:@[list] selectedColor:initial];[longCatalog loadViewIfNeeded];longCatalog.view.frame=CGRectMake(0,0,280,460);
        BOOL arabic=[name hasPrefix:@"لوحة"];longCatalog.view.semanticContentAttribute=arabic?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;[longCatalog.view setNeedsLayout];[longCatalog.view layoutIfNeeded];
        UIColorPanelMenuButton *choose=[longCatalog valueForKey:@"listButton"],*manage=[longCatalog valueForKey:@"actionsButton"];UISearchBar *searchBar=[longCatalog valueForKey:@"searchBar"];
        CGRect chooseRect=[choose convertRect:choose.bounds toView:longCatalog.view],manageRect=[manage convertRect:manage.bounds toView:longCatalog.view],searchRect=[searchBar convertRect:searchBar.bounds toView:longCatalog.view];
        BOOL valid=[choose.currentTitle isEqualToString:name]&&[choose.accessibilityLabel containsString:name]&&choose.titleLabel.adjustsFontForContentSizeCategory&&choose.bounds.size.height>=44-.01&&manage.bounds.size.width>=44-.01&&manage.bounds.size.height>=44-.01&&CGRectContainsRect(CGRectInset(longCatalog.view.bounds,-.01,-.01),chooseRect)&&CGRectContainsRect(CGRectInset(longCatalog.view.bounds,-.01,-.01),manageRect)&&CGRectContainsRect(CGRectInset(longCatalog.view.bounds,-.01,-.01),searchRect)&&!CGRectIntersectsRect(chooseRect,manageRect)&&CGRectGetMaxY(chooseRect)<=CGRectGetMinY(searchRect)+.01;
        valid=valid&&(arabic?CGRectGetMaxX(manageRect)<=CGRectGetMinX(chooseRect)+.01:CGRectGetMaxX(chooseRect)<=CGRectGetMinX(manageRect)+.01);longNames=longNames&&valid;[longNameChecks addObject:@{@"name":name,@"rtl":@(arabic),@"choose":NSStringFromCGRect(chooseRect),@"manage":NSStringFromCGRect(manageRect),@"search":NSStringFromCGRect(searchRect),@"passed":@(valid)}];
    }
    [cases addObject:@{@"name":@"long German Chinese and Arabic palette names retain full AX labels and separate native search row",@"passed":@(longNames),@"fixtures":longNameChecks}];passed=passed&&longNames;
    UIViewController *traitHost=[UIViewController new];[traitHost loadViewIfNeeded];traitHost.view.frame=CGRectMake(0,0,320,900);
    UIColorPanelConfiguration *axConfig=[UIColorPanelConfiguration new];axConfig.savedColorsKey=nil;axConfig.showsAlpha=YES;axConfig.initialMode=UIColorPanelModeRGB;
    UIColorPanelViewController *axPanel=[[UIColorPanelViewController alloc]initWithColor:initial configuration:axConfig];[traitHost addChildViewController:axPanel];[traitHost setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge] forChildViewController:axPanel];[traitHost.view addSubview:axPanel.view];[axPanel didMoveToParentViewController:traitHost];axPanel.view.frame=traitHost.view.bounds;axPanel.view.semanticContentAttribute=UISemanticContentAttributeForceRightToLeft;[axPanel.view setNeedsLayout];[axPanel.view layoutIfNeeded];
    BOOL accessible=CGAffineTransformIsIdentity(((UIView *)[axPanel valueForKey:@"rootStack"]).transform);NSMutableArray *axFields=[NSMutableArray new];
    NSMutableArray<UITextField *> *largeFields=[[axPanel valueForKey:@"componentFields"] mutableCopy];UITextField *largeHex=[axPanel valueForKey:@"hexField"];if(largeHex)[largeFields addObject:largeHex];[largeFields addObject:[axPanel valueForKey:@"opacityField"]];
    for(UITextField *field in largeFields){CGFloat expectedFont=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:field==largeHex?UIContentSizeCategoryExtraExtraExtraLarge:UIContentSizeCategoryAccessibilityExtraLarge]].pointSize;BOOL valid=field.font.pointSize<=expectedFont+.01&&!field.adjustsFontForContentSizeCategory&&field.accessibilityLabel.length>0&&[field.superview isKindOfClass:NSClassFromString(@"UIColorPanelNumericField")]&&field.borderStyle==UITextBorderStyleNone&&field.superview.bounds.size.height>=44&&field.bounds.size.width>0&&CGRectContainsRect(CGRectInset(field.superview.bounds,-.01,-.01),field.frame);if(field==largeHex)valid=valid&&field.semanticContentAttribute==UISemanticContentAttributeForceLeftToRight;accessible=accessible&&valid;[axFields addObject:@{@"label":field.accessibilityLabel?:@"",@"fontSize":@(field.font.pointSize),@"bounds":NSStringFromCGRect(field.bounds),@"passed":@(valid)}];}
    UISegmentedControl *largeToolbar=[axPanel valueForKey:@"modeControl"];UIButton *largeSaved=[axPanel valueForKey:@"savedColorsButton"];UIView *largeWell=[axPanel valueForKey:@"currentWell"];UIColorPickerSwatchesView *largePreview=[axPanel valueForKey:@"swatchesView"];
    accessible=accessible&&largeToolbar.bounds.size.height>=44&&largeSaved.bounds.size.height>=44&&largePreview.hidden&&largeSaved.accessibilityLabel.length>0&&CGRectGetMaxX(largeSaved.frame)<=CGRectGetMinX(largeWell.frame)+.01&&[axPanel.selectedColor isEqual:initial]&&axPanel.pickerMask==UIColorPanelAllModesMask;
    [cases addObject:@{@"name":@"scoped AX XXXL RTL layout caps numeric and Hex fonts and preserves exact color",@"passed":@(accessible),@"numericMaximumCategory":UIContentSizeCategoryAccessibilityExtraLarge,@"hexMaximumCategory":UIContentSizeCategoryExtraExtraExtraLarge,@"fields":axFields}];passed=passed&&accessible;
    UIColorPanelSavedColorsController *largeManager=[[UIColorPanelSavedColorsController alloc]initWithSwatchesView:largePreview];[largeManager loadViewIfNeeded];largeManager.view.frame=CGRectMake(0,0,320,460);[largeManager.view layoutIfNeeded];BOOL largeManagerVisible=!largePreview.hidden&&largePreview.userInteractionEnabled&&!largePreview.accessibilityElementsHidden&&largePreview.favoriteLayout.itemSize.width>=44;[cases addObject:@{@"name":@"hidden AX compact preview becomes visible in expanded saved colors",@"passed":@(largeManagerVisible)}];passed=passed&&largeManagerVisible;[axPanel restoreSavedColors];
    [axPanel willMoveToParentViewController:nil];[axPanel.view removeFromSuperview];[axPanel removeFromParentViewController];
    UIColorValue *beforeNumericResize=nativePanel.selectedColor;nativePanel.mode=UIColorPanelModeRGB;nativePanel.view.frame=CGRectMake(0,0,320,360);[nativePanel.view setNeedsLayout];[nativePanel.view layoutIfNeeded];UIScrollView *numericScroll=[nativePanel valueForKey:@"scroll"];UIView *numericHost=[nativePanel valueForKey:@"providerHost"],*numericWorkspace=[nativePanel valueForKey:@"workspace"];
    BOOL numericOverflow=numericScroll.scrollEnabled&&numericScroll.contentSize.height>numericScroll.bounds.size.height&&numericScroll.contentSize.width<=numericScroll.bounds.size.width+.01&&CGRectContainsRect(CGRectInset(numericHost.bounds,-.01,-.01),numericScroll.frame)&&numericWorkspace.bounds.size.height>=numericScroll.contentSize.height-.01&&[nativePanel.selectedColor isEqual:beforeNumericResize];
    [cases addObject:@{@"name":@"tall numeric content scrolls vertically inside the provider without scaling the public shell",@"passed":@(numericOverflow),@"viewport":NSStringFromCGRect(numericScroll.bounds),@"contentSize":NSStringFromCGSize(numericScroll.contentSize)}];passed=passed&&numericOverflow;
    nativePanel.view.frame=CGRectMake(0,0,336,645);[nativePanel.view setNeedsLayout];[nativePanel.view layoutIfNeeded];
    // Inspect only this app's existing host window. Do not rotate the device or
    // modify scene configuration to manufacture a resize event.
    UIWindow *hostWindow=UIApplication.sharedApplication.keyWindow;UIViewController *anchor=hostWindow.rootViewController;
    if(UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPhone){
        UIColorPanel *defaultPanel=[UIColorPanel new];[defaultPanel orderFront:anchor];[defaultPanel.window layoutIfNeeded];
        CGRect sceneBounds=defaultPanel.window.screen.bounds;if(@available(iOS 13.0,*))if(defaultPanel.window.windowScene)sceneBounds=defaultPanel.window.windowScene.coordinateSpace.bounds;
        CGFloat openedWidth=defaultPanel.frame.size.width;BOOL defaultWidth=hostWindow!=nil&&fabs(openedWidth-sceneBounds.size.width)<.01;
        [defaultPanel.window setNeedsLayout];[defaultPanel.window layoutIfNeeded];
        defaultWidth=defaultWidth&&fabs(defaultPanel.frame.size.width-sceneBounds.size.width)<.01&&CGSizeEqualToSize(nativePanel.preferredContentSize,CGSizeZero);
        CGFloat relayoutWidth=defaultPanel.frame.size.width;[defaultPanel close];defaultWidth=defaultWidth&&!defaultPanel.isVisible&&hostWindow.isKeyWindow;
        [cases addObject:@{@"name":@"default phone panel fills the scene width across repeated layouts",@"passed":@(defaultWidth),@"sceneBounds":NSStringFromCGRect(sceneBounds),@"openedWidth":@(openedWidth),@"relayoutWidth":@(relayoutWidth)}];passed=passed&&defaultWidth;
    }
    CGFloat explicitWidth=MIN(240,hostWindow.bounds.size.width/2),explicitHeight=MIN(180,hostWindow.bounds.size.height/3);UIPanel *explicitPanel=[[UIPanel alloc]initWithFrame:CGRectMake(20,100,explicitWidth,explicitHeight)];[explicitPanel orderFront:anchor];[explicitPanel.window layoutIfNeeded];
    CGFloat actualExplicitWidth=explicitPanel.frame.size.width;BOOL explicitSizing=hostWindow!=nil&&explicitWidth>0&&fabs(actualExplicitWidth-explicitWidth)<.01&&fabs(explicitPanel.frame.size.height-explicitHeight)<.01;[explicitPanel close];explicitSizing=explicitSizing&&!explicitPanel.isVisible&&hostWindow.isKeyWindow;
    UIPanel *postInitPanel=[UIPanel new];postInitPanel.frame=CGRectMake(20,100,explicitWidth,explicitHeight);[postInitPanel orderFront:anchor];[postInitPanel.window layoutIfNeeded];
    CGFloat postInitWidth=postInitPanel.frame.size.width,postInitHeight=postInitPanel.frame.size.height;explicitSizing=explicitSizing&&fabs(postInitWidth-explicitWidth)<.01&&fabs(postInitHeight-explicitHeight)<.01;[postInitPanel close];explicitSizing=explicitSizing&&!postInitPanel.isVisible&&hostWindow.isKeyWindow;
    [cases addObject:@{@"name":@"explicit initial and post-init panel widths remain caller owned",@"passed":@(explicitSizing),@"requestedWidth":@(explicitWidth),@"initialFrameWidth":@(actualExplicitWidth),@"postInitFrameWidth":@(postInitWidth),@"requestedHeight":@(explicitHeight),@"postInitFrameHeight":@(postInitHeight)}];passed=passed&&explicitSizing;
    NSDictionary *result=@{@"passed":@(passed),@"caseCount":@(cases.count),@"cases":cases,@"minimumViewport":@{@"smallestFullProviderFixtureHeight":@360,@"excludedShortHostHeight":@180,@"limitation":@"180pt cannot accommodate native toolbar, opacity and compact footer plus complete provider content. This is not claimed as a supported full-UI viewport; large text may require more height. Numeric providers scroll internally."},@"scope":@"Finite native-point layout across phone/host widths; common five-mode footer; compact/expanded favorites lifecycle; scoped AX XXXL and RTL/long user names; native font and numeric scroll geometry; default/explicit panel width, mode/mask mapping, search delegate and menu models. Does not change device language, text size or orientation, synthesize physical touch or verify VoiceOver focus, actual modal/menu presentation, hover, or system Files UI."};NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];return[data writeToURL:url options:NSDataWritingAtomic error:nil]&&passed;
}
+ (void)runWindowEditingWithOutputURL:(NSURL *)url {
    // A nonshared panel reads the global alpha policy during construction;
    // later policy changes synchronize the shared panel only.
    BOOL initialIgnoresAlpha=UIColor.ignoresAlpha;UIColor.ignoresAlpha=NO;
    UIWindow *host=UIApplication.sharedApplication.keyWindow;UIColorPanel *panel=[UIColorPanel new];panel.mode=UIColorPanelModeRGB;[panel orderFront:host.rootViewController];[panel.window layoutIfNeeded];UIColorPanelViewController *controller=[panel valueForKey:@"pickerController"];[controller.view layoutIfNeeded];
    BOOL controllerShowsAlpha=controller.showsAlpha,opacityRowHidden=[[controller valueForKey:@"opacityRow"]isHidden];
    __block NSUInteger keyboardNotifications=0;__block CGRect screenKeyboard=CGRectNull;
    id observer=[NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *n){keyboardNotifications++;screenKeyboard=[n.userInfo[UIKeyboardFrameEndUserInfoKey]CGRectValue];}];
    UITextField *field=[controller valueForKey:@"opacityField"];BOOL accepted=[field becomeFirstResponder];dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.7*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
    CGRect onScreen=[field convertRect:field.bounds toCoordinateSpace:panel.window.screen.coordinateSpace];BOOL aboveKeyboard=CGRectIsNull(screenKeyboard)||CGRectGetMaxY(onScreen)<=CGRectGetMinY(screenKeyboard)+1;
    NSDictionary *diagnostic=@{@"firstResponderAccepted":@(accepted),@"panelIsKeyDuringEditing":@(panel.window.isKeyWindow),@"hostIsKeyDuringEditing":@(host.isKeyWindow),@"keyboardNotifications":@(keyboardNotifications),@"fieldOnScreen":NSStringFromCGRect(onScreen),@"keyboardOnScreen":NSStringFromCGRect(screenKeyboard),@"fieldAboveKeyboard":@(aboveKeyboard),@"initialIgnoresAlphaPolicy":@(initialIgnoresAlpha),@"controllerShowsAlpha":@(controllerShowsAlpha),@"opacityRowHidden":@(opacityRowHidden)};
    CGRect softwareFrame=CGRectMake(0,panel.window.screen.bounds.size.height-352,panel.window.screen.bounds.size.width,352);
    [controller keyboardChanged:[NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification object:nil userInfo:@{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:softwareFrame]}]];[controller.view layoutIfNeeded];CGRect fullKeyboardField=[field convertRect:field.bounds toCoordinateSpace:panel.window.screen.coordinateSpace];BOOL fullKeyboardGeometry=CGRectGetMaxY(fullKeyboardField)<=CGRectGetMinY(softwareFrame)+1;
    UIView *canvas=[controller valueForKey:@"rootStack"],*opacityRow=[controller valueForKey:@"opacityRow"];
    CGRect sceneBounds=panel.window.screen.bounds;if(@available(iOS 13.0,*))if(panel.window.windowScene)sceneBounds=panel.window.windowScene.coordinateSpace.bounds;
    NSDictionary *syntheticGeometry=@{@"panelFrame":NSStringFromCGRect(panel.frame),@"panelBounds":NSStringFromCGRect(panel.window.bounds),@"sceneBounds":NSStringFromCGRect(sceneBounds),@"controllerBounds":NSStringFromCGRect(controller.view.bounds),@"controllerFrame":NSStringFromCGRect(controller.view.frame),@"controllerOnScreen":NSStringFromCGRect([controller.view convertRect:controller.view.bounds toCoordinateSpace:panel.window.screen.coordinateSpace]),@"controllerSafeArea":NSStringFromUIEdgeInsets(controller.view.safeAreaInsets),@"keyboardFrameInController":NSStringFromCGRect([[controller valueForKey:@"keyboardFrame"]CGRectValue]),@"rootStackBounds":NSStringFromCGRect(canvas.bounds),@"rootStackFrame":NSStringFromCGRect(canvas.frame),@"rootStackTransform":NSStringFromCGAffineTransform(canvas.transform),@"opacityRowFrame":NSStringFromCGRect(opacityRow.frame),@"opacityRowBounds":NSStringFromCGRect(opacityRow.bounds),@"fieldFrame":NSStringFromCGRect(field.frame),@"fieldBounds":NSStringFromCGRect(field.bounds),@"fieldSuperviewClass":NSStringFromClass(field.superview.class),@"fieldSuperviewFrame":NSStringFromCGRect(field.superview.frame),@"fieldSuperviewBounds":NSStringFromCGRect(field.superview.bounds)};
    BOOL ended=[controller.view endEditing:YES];dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.3*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
    BOOL restoredAfterEnd=host.isKeyWindow;NSMutableArray *remainingResponders=[NSMutableArray new],*pendingResponders=[NSMutableArray arrayWithObject:panel.window];while(pendingResponders.count){UIView *candidate=pendingResponders.lastObject;[pendingResponders removeLastObject];if(candidate.isFirstResponder)[remainingResponders addObject:NSStringFromClass(candidate.class)];[pendingResponders addObjectsFromArray:candidate.subviews];}BOOL fieldRemains=field.isFirstResponder;[panel close];[NSNotificationCenter.defaultCenter removeObserver:observer];UIColor.ignoresAlpha=initialIgnoresAlpha;BOOL policyRestored=UIColor.ignoresAlpha==initialIgnoresAlpha;BOOL passed=controllerShowsAlpha&&!opacityRowHidden&&accepted&&keyboardNotifications>0&&aboveKeyboard&&fullKeyboardGeometry&&restoredAfterEnd&&host.isKeyWindow&&policyRestored;
    NSDictionary *result=@{@"passed":@(passed),@"diagnostic":diagnostic,@"hostKeyRestored":@(host.isKeyWindow),@"restoredAfterEditingBeforeClose":@(restoredAfterEnd),@"endEditingReturned":@(ended),@"fieldStillFirstResponder":@(fieldRemains),@"remainingFirstResponders":remainingResponders,@"fullKeyboardGeometryPassed":@(fullKeyboardGeometry),@"syntheticFullKeyboardFrame":NSStringFromCGRect(softwareFrame),@"fieldAfterSyntheticFrame":NSStringFromCGRect(fullKeyboardField),@"syntheticGeometry":syntheticGeometry,@"initialIgnoresAlphaPolicy":@(initialIgnoresAlpha),@"alphaPolicyRestored":@(policyRestored),@"scope":@"Actual UIKit first-responder/keyboard notifications and screen-coordinate field visibility; programmatic focus with current simulator hardware keyboard, plus a separately synthetic352pt screen-frame layout check. Asynchronous main-queue barriers let owned key restoration complete; no physical tap or full software keyboard gesture claim."};NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];[data writeToURL:url options:NSDataWritingAtomic error:nil];
    });
    });
}
+ (BOOL)runWellRenderingWithOutputURL:(NSURL *)url {
    // Test-only access to the two implementations' observed iOS15 layer topology.
    // Both controls are attached to one child controller; no device preferences,
    // user color, presentation session or application defaults are changed.
    UIWindow *window=UIApplication.sharedApplication.keyWindow;
    UIViewController *parent=window.rootViewController;
    if(!parent){
        [[NSJSONSerialization dataWithJSONObject:@{@"passed":@NO,@"failure":@"No existing host window"} options:NSJSONWritingPrettyPrinted error:nil]writeToURL:url options:NSDataWritingAtomic error:nil];
        return NO;
    }
    UIViewController *fixture=[UIViewController new];
    [parent addChildViewController:fixture];
    fixture.view.frame=window.bounds;
    fixture.view.userInteractionEnabled=NO;
    [parent.view addSubview:fixture.view];
    [fixture didMoveToParentViewController:parent];
    NSMutableArray<NSDictionary *> *cases=[NSMutableArray new],*pictures=[NSMutableArray new];
    __block BOOL passed=YES;
    BOOL nativeAvailable=NO;
    if(@available(iOS 15.0,*))nativeAvailable=YES;
    CGFloat scale=window.screen.scale;
    UIColor *translucent=[UIColor colorWithRed:.8 green:.2 blue:.4 alpha:.35];
    NSArray<NSDictionary *> *samples=@[
        @{@"name":@"28pt black",@"size":[NSValue valueWithCGSize:CGSizeMake(28,28)],@"color":UIColor.blackColor},
        @{@"name":@"28pt nil",@"size":[NSValue valueWithCGSize:CGSizeMake(28,28)],@"color":NSNull.null},
        @{@"name":@"28pt alpha .35",@"size":[NSValue valueWithCGSize:CGSizeMake(28,28)],@"color":translucent},
        @{@"name":@"28pt alpha zero",@"size":[NSValue valueWithCGSize:CGSizeMake(28,28)],@"color":[translucent colorWithAlphaComponent:0]},
        @{@"name":@"28pt archive restore",@"size":[NSValue valueWithCGSize:CGSizeMake(28,28)],@"color":translucent,@"archive":@YES},
        @{@"name":@"36pt regular",@"size":[NSValue valueWithCGSize:CGSizeMake(36,36)],@"color":UIColor.blackColor,@"regular":@YES},
        @{@"name":@"40 by 32 bounds",@"size":[NSValue valueWithCGSize:CGSizeMake(40,32)],@"color":UIColor.blackColor},
        @{@"name":@"28pt dark",@"size":[NSValue valueWithCGSize:CGSizeMake(28,28)],@"color":UIColor.blackColor,@"dark":@YES}
    ];
    NSDictionary *(^render)(UIView *,BOOL)=^NSDictionary *(UIView *view,BOOL dark){
        size_t width=(size_t)llround(view.bounds.size.width*scale),height=(size_t)llround(view.bounds.size.height*scale);
        NSMutableData *bytes=[NSMutableData dataWithLength:width*height*4];
        CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGContextRef context=CGBitmapContextCreate(bytes.mutableBytes,width,height,8,width*4,space,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(space);
        if(!context)return @{@"valid":@NO};
        CGContextSetRGBFillColor(context,dark?0:1,dark?0:1,dark?0:1,1);
        CGContextFillRect(context,CGRectMake(0,0,width,height));
        CGContextScaleCTM(context,scale,scale);
        [view.layer renderInContext:context];
        CGImageRef image=CGBitmapContextCreateImage(context);
        UIImage *result=image?[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]:nil;
        if(image)CGImageRelease(image);
        CGContextRelease(context);
        NSUInteger chromaticPixels=0;const uint8_t *pixels=bytes.bytes;
        for(NSUInteger index=0;index<bytes.length;index+=4)if(pixels[index]!=pixels[index+1]||pixels[index+1]!=pixels[index+2])chromaticPixels++;
        return result?@{@"valid":@(chromaticPixels>0),@"bytes":bytes,@"image":result,@"width":@(width),@"height":@(height),@"chromaticPixels":@(chromaticPixels)}:@{@"valid":@NO};
    };
    UIView *(^visualStyle)(UIControl *)=^UIView *(UIControl *well){
        NSString *className=[well isKindOfClass:UIColorPickerWell.class]?@"UIColorPickerWelliOSVisualStyle":@"_UIColorWelliOSVisualStyle";
        // UIView decoding can restore an archived style before commonInit adds
        // the newly owned style. Report those subviews rather than deleting them.
        for(UIView *view in well.subviews.reverseObjectEnumerator)
            if([NSStringFromClass(view.class)isEqual:className])return view;
        return nil;
    };
    id (^roundTrip)(id,NSMutableDictionary *)=^id(id object,NSMutableDictionary *report){
        NSError *error=nil;
        @try {
            NSData *data=[NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:&error];
            id restored=data?[NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error]:nil;
            Class expectedClass=[object isKindOfClass:UIColor.class]?UIColor.class:[object class];
            BOOL restoredClass=[restored isKindOfClass:expectedClass];
            report[@"archiveBytes"]=@(data.length);report[@"restoredExpectedClass"]=@(restoredClass);
            if(error)report[@"error"]=error.localizedDescription;
            return restoredClass?restored:nil;
        } @catch(NSException *exception) {
            report[@"exception"]=exception.name;report[@"reason"]=exception.reason?:@"";
            return nil;
        }
    };
    NSDictionary *(^colorDetails)(UIColor *)=^NSDictionary *(UIColor *color){
        if(!color)return @{@"present":@NO};
        CGColorRef cg=color.CGColor;CGColorSpaceRef space=CGColorGetColorSpace(cg);
        NSMutableArray *components=[NSMutableArray new];const CGFloat *values=CGColorGetComponents(cg);
        for(NSUInteger index=0;index<CGColorGetNumberOfComponents(cg);index++)[components addObject:@(values[index])];
        NSString *name=CFBridgingRelease(CGColorSpaceCopyName(space));
        return @{@"present":@YES,@"class":NSStringFromClass(color.class),@"components":components,@"colorSpaceName":name?:NSNull.null,@"colorSpaceModel":@(CGColorSpaceGetModel(space))};
    };
    NSDictionary *(^layers)(UIControl *)=^NSDictionary *(UIControl *well){
        UIView *style=visualStyle(well);
        if(!style){NSMutableArray *classes=[NSMutableArray new];for(UIView *view in well.subviews)[classes addObject:NSStringFromClass(view.class)];return @{@"valid":@NO,@"rootSubviewClasses":classes};}
        UIImageView *gradient=[style valueForKey:@"gradientView"];
        UIView *border=[style valueForKey:@"borderView"];
        UIButton *button=[style valueForKey:@"button"];
        NSUInteger styleCount=0;for(UIView *view in well.subviews)styleCount+=view.class==style.class;
        BOOL imageValid=[gradient isKindOfClass:UIImageView.class]&&gradient.image&&gradient.image.size.width>0&&gradient.image.size.height>0;
        UIColor *color=[well valueForKey:@"selectedColor"],*styleColor=[style valueForKey:@"selectedColor"];
        NSString *title=[well valueForKey:@"title"],*styleTitle=[style valueForKey:@"pickerTitle"];
        return @{@"valid":@YES,@"styleClass":NSStringFromClass(style.class),@"rootAlpha":@(well.alpha),@"styleAlpha":@(style.alpha),
                 @"visualStyleCount":@(styleCount),@"selectedVisualStyleIndex":@([well.subviews indexOfObjectIdenticalTo:style]),@"styleOwnerMatches":@([style valueForKey:@"colorWell"]==well),
                 @"styleColorMatchesPublic":@(styleColor==color||[styleColor isEqual:color]),@"title":title?:NSNull.null,@"styleTitle":styleTitle?:NSNull.null,
                 @"supportsAlpha":[well valueForKey:@"supportsAlpha"],@"styleSupportsAlpha":[style valueForKey:@"supportsAlpha"],
                 @"styleFrame":NSStringFromCGRect(style.frame),@"gradientFrame":NSStringFromCGRect(gradient.frame),
                 @"imagePresent":@(imageValid),@"imageSize":NSStringFromCGSize(gradient.image.size),@"imageScale":@(gradient.image.scale),
                 @"borderFrame":NSStringFromCGRect(border.frame),@"borderRadius":@(border.layer.cornerRadius),@"borderAlpha":@(border.alpha),
                 @"buttonFrame":NSStringFromCGRect(button.frame),@"buttonRadius":@(button.layer.cornerRadius),@"buttonBorderWidth":@(button.layer.borderWidth)};
    };
    for(NSDictionary *sample in samples){
        BOOL regular=[sample[@"regular"]boolValue],dark=[sample[@"dark"]boolValue],archived=[sample[@"archive"]boolValue];
        if(dark&&!nativeAvailable)continue; // iOS12 has no system dark appearance.
        NSMutableArray<UITraitCollection *> *traits=[NSMutableArray arrayWithObject:[UITraitCollection traitCollectionWithHorizontalSizeClass:regular?UIUserInterfaceSizeClassRegular:UIUserInterfaceSizeClassCompact]];
        if(@available(iOS 13.0,*))[traits addObject:[UITraitCollection traitCollectionWithUserInterfaceStyle:dark?UIUserInterfaceStyleDark:UIUserInterfaceStyleLight]];
        [parent setOverrideTraitCollection:[UITraitCollection traitCollectionWithTraitsFromCollections:traits] forChildViewController:fixture];
        fixture.view.backgroundColor=dark?UIColor.blackColor:UIColor.whiteColor;
        CGSize size=[sample[@"size"]CGSizeValue];
        UIColor *color=sample[@"color"]==NSNull.null?nil:sample[@"color"];
        UIColorPickerWell *recovered=[[UIColorPickerWell alloc]initWithFrame:CGRectMake(40,30,size.width,size.height)];
        recovered.selectedColor=color;recovered.alpha=.8;
        NSString *archiveTitle=@"Archive 色 🎨";
        NSMutableDictionary *archiveRecovered=[NSMutableDictionary new],*archiveNative=[NSMutableDictionary new],*archiveReference=[NSMutableDictionary new];
        UIColor *decodedColor=archived?roundTrip(color,archiveReference):color;
        if(archived){archiveReference[@"inputColor"]=colorDetails(color);archiveReference[@"decodedColor"]=colorDetails(decodedColor);archiveReference[@"decodedEqualsInput"]=@([decodedColor isEqual:color]);archiveReference[@"criterion"]=@"Control color must equal an independently archived and decoded UIColor on this runtime; this does not claim exact preservation of the original input RGBA or representation.";}
        if(archived){recovered.title=archiveTitle;recovered.supportsAlpha=NO;recovered=(UIColorPickerWell *)roundTrip(recovered,archiveRecovered);}
        UIControl *native=nil;
        if(@available(iOS 15.0,*)){
            UIColorWell *original=[[UIColorWell alloc]initWithFrame:CGRectMake(120,30,size.width,size.height)];
            original.selectedColor=color;original.alpha=.8;native=original;
            if(archived){original.title=archiveTitle;original.supportsAlpha=NO;native=roundTrip(original,archiveNative);}
        }
        if(!recovered||(nativeAvailable&&!native)||(archived&&!decodedColor)){
            passed=NO;[cases addObject:@{@"name":sample[@"name"],@"passed":@NO,@"archiveRecovered":archiveRecovered,@"archiveNative":nativeAvailable?(id)archiveNative:NSNull.null,@"archiveReference":archiveReference}];continue;
        }
        [fixture.view addSubview:recovered];if(native)[fixture.view addSubview:native];
        // The opaque28 fixture also compares the original's press/release
        // callbacks. sendActions is programmatic, not a physical touch claim.
        NSUInteger states=[sample[@"name"]isEqual:@"28pt black"]?3:1;
        for(NSUInteger state=0;state<states;state++){
            if(state){
                UIControlEvents event=state==1?UIControlEventTouchDown:UIControlEventTouchCancel;
                [[visualStyle(recovered) valueForKey:@"button"]sendActionsForControlEvents:event];
                if(native)[[visualStyle(native) valueForKey:@"button"]sendActionsForControlEvents:event];
            }
            [fixture.view setNeedsLayout];[fixture.view layoutIfNeeded];
            [recovered setNeedsLayout];[recovered layoutIfNeeded];
            UIView *recoveredStyle=visualStyle(recovered);[recoveredStyle setNeedsLayout];[recoveredStyle layoutIfNeeded];
            if(native){[native setNeedsLayout];[native layoutIfNeeded];UIView *style=visualStyle(native);[style setNeedsLayout];[style layoutIfNeeded];}
            NSDictionary *actual=layers(recovered),*original=native?layers(native):nil;
            if(![actual[@"valid"]boolValue]||(native&&![original[@"valid"]boolValue])){
                passed=NO;[cases addObject:@{@"name":sample[@"name"],@"passed":@NO,@"recovered":actual,@"native":original?:NSNull.null}];break;
            }
            CGFloat width=MAX(28,MIN(36,size.width)),height=MAX(28,MIN(36,size.height));
            CGRect expected=CGRectMake((size.width-width)*.5,(size.height-height)*.5,width,height);
            CGRect border=CGRectInset(expected,3,3),button=CGRectInset(expected,5,5);
            BOOL geometry=[actual[@"imagePresent"]boolValue]&&CGRectEqualToRect(CGRectFromString(actual[@"styleFrame"]),(CGRect){CGPointZero,size})&&CGRectEqualToRect(CGRectFromString(actual[@"gradientFrame"]),expected)&&CGRectEqualToRect(CGRectFromString(actual[@"borderFrame"]),border)&&CGRectEqualToRect(CGRectFromString(actual[@"buttonFrame"]),button)&&fabs([actual[@"buttonRadius"]doubleValue]-button.size.width*.5)<1e-6&&fabs([actual[@"borderRadius"]doubleValue]-border.size.width*.5)<1e-6&&[actual[@"buttonBorderWidth"]doubleValue]==0&&fabs([actual[@"rootAlpha"]doubleValue]-.8)<1e-6&&fabs([actual[@"styleAlpha"]doubleValue]-(state==1?.5:1))<1e-6&&[actual[@"borderAlpha"]doubleValue]==(color?1:0);
            BOOL layerMatch=original!=nil;
            if(original)for(NSString *key in @[@"rootAlpha",@"styleAlpha",@"styleFrame",@"gradientFrame",@"imagePresent",@"borderFrame",@"borderRadius",@"borderAlpha",@"buttonFrame",@"buttonRadius",@"buttonBorderWidth",@"visualStyleCount",@"selectedVisualStyleIndex",@"styleOwnerMatches",@"styleColorMatchesPublic",@"title",@"styleTitle",@"supportsAlpha",@"styleSupportsAlpha"])
                layerMatch=layerMatch&&[actual[key]isEqual:original[key]];
            BOOL archiveState=YES;
            if(archived){
                archiveState=[recovered.selectedColor isEqual:decodedColor]&&[recovered.title isEqual:archiveTitle]&&!recovered.supportsAlpha&&[actual[@"styleOwnerMatches"]boolValue]&&[actual[@"styleColorMatchesPublic"]boolValue]&&[actual[@"styleTitle"]isEqual:archiveTitle]&&![actual[@"styleSupportsAlpha"]boolValue];
                if(native)archiveState=archiveState&&[[native valueForKey:@"selectedColor"]isEqual:decodedColor]&&[original[@"title"]isEqual:archiveTitle]&&![original[@"supportsAlpha"]boolValue]&&[original[@"styleOwnerMatches"]boolValue]&&[original[@"styleColorMatchesPublic"]boolValue]&&[original[@"styleTitle"]isEqual:archiveTitle]&&![original[@"styleSupportsAlpha"]boolValue];
            }
            NSDictionary *recoveredRaster=render(recovered,dark),*nativeRaster=native?render(native,dark):nil;
            BOOL rasterValid=[recoveredRaster[@"valid"]boolValue]&&(!native||[nativeRaster[@"valid"]boolValue]);
            double mean=0;NSUInteger maximum=0,different=0;
            BOOL sameRaster=NO, artworkMatches=NO, unchangedAreasMatch=YES;
            if(native&&rasterValid){
                NSData *a=recoveredRaster[@"bytes"],*b=nativeRaster[@"bytes"];
                if(a.length==b.length&&a.length){
                    const uint8_t *aa=a.bytes,*bb=b.bytes;
                    NSUInteger rowWidth=[recoveredRaster[@"width"] unsignedIntegerValue];
                    CGFloat opaqueRadius=MAX(0,MIN(border.size.width,border.size.height)*0.5-1/scale);
                    for(NSUInteger i=0;i<a.length;i+=4){
                        CGPoint point=CGPointMake(((i/4)%rowWidth+0.5)/scale,((i/4)/rowWidth+0.5)/scale);
                        BOOL outside=!CGRectContainsPoint(CGRectInset(expected,-1/scale,-1/scale),point);
                        BOOL covered=color && hypot(point.x-CGRectGetMidX(border),point.y-CGRectGetMidY(border)) < opaqueRadius;
                        for(NSUInteger c=0;c<4;c++){
                            NSUInteger delta=(NSUInteger)abs((int)aa[i+c]-(int)bb[i+c]);
                            mean+=delta;maximum=MAX(maximum,delta);different+=delta!=0;
                            if(delta && (outside || covered || c==3))unchangedAreasMatch=NO;
                        }
                    }
                    mean/=a.length;sameRaster=different==0;
                    artworkMatches=unchangedAreasMatch&&mean<=1.25&&maximum<=24;
                }
            }
            NSString *name=[sample[@"name"]stringByAppendingString:state==1?@" pressed":state==2?@" released":@""];
            BOOL casePassed=geometry&&archiveState&&rasterValid&&(!native||(layerMatch&&artworkMatches));passed=passed&&casePassed;
            NSMutableDictionary *entry=[@{@"name":name,@"passed":@(casePassed),@"geometry":@(geometry),@"nativeCompared":@(native!=nil),@"recovered":actual,@"native":original?:NSNull.null,@"rasterValid":@(rasterValid),@"recoveredChromaticPixels":recoveredRaster[@"chromaticPixels"]?:@0,@"nativeChromaticPixels":nativeRaster[@"chromaticPixels"]?:@0,@"pixelComparison":native?@{@"exact":@(sameRaster),@"unchangedAreasExact":@(unchangedAreasMatch),@"meanAbsolute8BitChannelDifference":@(mean),@"maximum8BitChannelDifference":@(maximum),@"differentChannels":@(different)}:(id)NSNull.null}mutableCopy];
            if(archived){archiveRecovered[@"restoredColor"]=colorDetails(recovered.selectedColor);archiveRecovered[@"colorMatchesDecodedReference"]=@([recovered.selectedColor isEqual:decodedColor]);if(native){archiveNative[@"restoredColor"]=colorDetails([native valueForKey:@"selectedColor"]);archiveNative[@"colorMatchesDecodedReference"]=@([[native valueForKey:@"selectedColor"]isEqual:decodedColor]);}entry[@"archiveStateRestored"]=@(archiveState);entry[@"archiveRecovered"]=archiveRecovered;entry[@"archiveNative"]=native?(id)archiveNative:NSNull.null;entry[@"archiveReference"]=archiveReference;}
            [cases addObject:entry];
            if(rasterValid)[pictures addObject:@{@"name":name,@"recovered":recoveredRaster[@"image"],@"native":nativeRaster[@"image"]?:NSNull.null,@"dark":@(dark)}];
        }
        [native removeFromSuperview];[recovered removeFromSuperview];
    }
    // The optional appearances are component extensions, not UIKit equivalence
    // claims. Exercise each outline once while keeping one canonical color.
    NSMutableArray<NSDictionary *> *alphaExtensions=[NSMutableArray new];
    void (^layoutWell)(UIColorPickerWell *)=^(UIColorPickerWell *well){
        [fixture.view setNeedsLayout];[fixture.view layoutIfNeeded];
        [well setNeedsLayout];[well layoutIfNeeded];
        UIView *style=visualStyle(well);[style setNeedsLayout];[style layoutIfNeeded];
    };
    BOOL (^sameExterior)(NSDictionary *,NSDictionary *,CGRect)=^BOOL(NSDictionary *first,NSDictionary *second,CGRect center){
        NSData *a=first[@"bytes"],*b=second[@"bytes"];
        if(!a.length||a.length!=b.length||![first[@"width"]isEqual:second[@"width"]])return NO;
        const uint8_t *aa=a.bytes,*bb=b.bytes;NSUInteger width=[first[@"width"]unsignedIntegerValue],height=[first[@"height"]unsignedIntegerValue];
        // One pixel around the center belongs to its antialiased boundary.
        CGRect excluded=CGRectInset(center,-1/scale,-1/scale);
        for(NSUInteger y=0;y<height;y++)for(NSUInteger x=0;x<width;x++){
            if(CGRectContainsPoint(excluded,CGPointMake((x+.5)/scale,(y+.5)/scale)))continue;
            NSUInteger offset=(y*width+x)*4;
            if(memcmp(aa+offset,bb+offset,4))return NO;
        }
        return YES;
    };
    NSArray<NSNumber *> *(^pixelAt)(NSDictionary *,CGPoint)=^NSArray<NSNumber *> *(NSDictionary *raster,CGPoint point){
        NSUInteger width=[raster[@"width"]unsignedIntegerValue],height=[raster[@"height"]unsignedIntegerValue];
        NSInteger x=(NSInteger)floor(point.x*scale),y=(NSInteger)floor(point.y*scale);NSData *bytes=raster[@"bytes"];
        if(x<0||y<0||x>=(NSInteger)width||y>=(NSInteger)height||bytes.length!=width*height*4)return @[];
        const uint8_t *rgba=(const uint8_t *)bytes.bytes+((NSUInteger)y*width+(NSUInteger)x)*4;
        return @[@(rgba[0]),@(rgba[1]),@(rgba[2]),@(rgba[3])];
    };
    BOOL (^neutralPixel)(NSArray<NSNumber *> *,NSUInteger)=^BOOL(NSArray<NSNumber *> *pixel,NSUInteger expected){
        return pixel.count==4&&abs(pixel[0].intValue-(int)expected)<=2&&abs(pixel[1].intValue-(int)expected)<=2&&abs(pixel[2].intValue-(int)expected)<=2&&pixel[3].intValue==255;
    };
    NSMutableArray<UITraitCollection *> *extensionTraits=[NSMutableArray arrayWithObject:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular]];
    if(@available(iOS 13.0,*))[extensionTraits addObject:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
    [parent setOverrideTraitCollection:[UITraitCollection traitCollectionWithTraitsFromCollections:extensionTraits] forChildViewController:fixture];
    fixture.view.backgroundColor=UIColor.whiteColor;
    for(NSNumber *shapeNumber in @[@(UIColorPickerWellShapeCircle),@(UIColorPickerWellShapeRoundedRectangle)]){
        UIColorPickerWellShape shape=shapeNumber.integerValue;BOOL rectangle=shape==UIColorPickerWellShapeRoundedRectangle;
        UIColorPickerWell *well=[[UIColorPickerWell alloc]initWithFrame:CGRectMake(40,30,rectangle?64:36,36)];
        UITouchRefinementsRecorder *recorder=[UITouchRefinementsRecorder new];
        [well addTarget:recorder action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
        well.shape=shape;well.selectedColor=translucent;well.title=@"Alpha 拡張 🎨";well.supportsAlpha=NO;well.alpha=.8;
        [fixture.view addSubview:well];layoutWell(well);
        NSString *initialAX=well.accessibilityValue;CGColorRef initialColor=well.selectedColor.CGColor;
        NSDictionary *baseline=render(well,NO),*baselineLayers=layers(well);
        CGRect center=CGRectFromString(baselineLayers[@"buttonFrame"]);
        BOOL semantic=YES,exterior=YES,changedCenter=YES,capabilityIndependent=YES;
        for(NSNumber *appearance in @[@(UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground),@(UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground)]){
            well.centerAlphaAppearance=appearance.integerValue;layoutWell(well);
            NSDictionary *actual=render(well,NO),*actualLayers=layers(well);
            semantic=semantic&&well.selectedColor==translucent&&well.selectedColor.CGColor==initialColor&&fabs(well.alpha-.8)<1e-6&&!well.supportsAlpha&&[well.title isEqual:@"Alpha 拡張 🎨"]&&[well.accessibilityValue isEqual:initialAX];
            exterior=exterior&&sameExterior(baseline,actual,center);
            for(NSString *key in @[@"styleFrame",@"gradientFrame",@"borderFrame",@"borderRadius",@"borderAlpha",@"buttonFrame",@"buttonRadius",@"styleAlpha"])
                exterior=exterior&&[baselineLayers[key]isEqual:actualLayers[key]];
            changedCenter=changedCenter&&![baseline[@"bytes"]isEqual:actual[@"bytes"]];
            well.supportsAlpha=YES;layoutWell(well);
            capabilityIndependent=capabilityIndependent&&[actual[@"bytes"]isEqual:render(well,NO)[@"bytes"]]&&well.selectedColor==translucent;
            well.supportsAlpha=NO;
        }
        well.centerAlphaAppearance=UIColorPickerWellCenterAlphaAppearanceNativeCompositing;layoutWell(well);
        BOOL baselineRestored=[baseline[@"bytes"]isEqual:render(well,NO)[@"bytes"]];

        // Pixel checks use full root opacity so expected backing values do not
        // depend on Core Animation's ancestor group-opacity behavior. All
        // samples lie on the center's horizontal midline; the bitmap's vertical
        // orientation therefore cannot exchange the two reference regions.
        well.alpha=1;well.selectedColor=[translucent colorWithAlphaComponent:0];
        NSMutableArray *transparentPixels=[NSMutableArray new];BOOL transparent=YES;
        for(NSNumber *appearance in @[@(UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground),@(UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground)]){
            well.centerAlphaAppearance=appearance.integerValue;layoutWell(well);
            NSDictionary *raster=render(well,NO);CGFloat shorter=MIN(center.size.width,center.size.height);
            CGPoint first=CGPointMake(CGRectGetMinX(center)+(appearance.integerValue==UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground?center.size.width*.25:shorter/6),CGRectGetMidY(center));
            CGPoint second=CGPointMake(CGRectGetMinX(center)+(appearance.integerValue==UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground?center.size.width*.75:shorter*.5),CGRectGetMidY(center));
            NSArray *left=pixelAt(raster,first),*right=pixelAt(raster,second);
            BOOL pixels=neutralPixel(left,appearance.integerValue==UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground?0:191)&&neutralPixel(right,255);
            transparent=transparent&&pixels;[transparentPixels addObject:@{@"appearance":appearance,@"firstRGBA":left,@"secondRGBA":right,@"passed":@(pixels)}];
        }
        well.selectedColor=[translucent colorWithAlphaComponent:1];well.centerAlphaAppearance=UIColorPickerWellCenterAlphaAppearanceNativeCompositing;layoutWell(well);
        NSDictionary *opaqueBaseline=render(well,NO);BOOL opaque=YES;
        for(NSNumber *appearance in @[@(UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground),@(UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground)]){
            well.centerAlphaAppearance=appearance.integerValue;layoutWell(well);opaque=opaque&&[opaqueBaseline[@"bytes"]isEqual:render(well,NO)[@"bytes"]];
        }
        well.selectedColor=nil;well.centerAlphaAppearance=UIColorPickerWellCenterAlphaAppearanceNativeCompositing;layoutWell(well);
        NSDictionary *nilBaseline=render(well,NO);BOOL nilUnchanged=YES;
        for(NSNumber *appearance in @[@(UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground),@(UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground)]){
            well.centerAlphaAppearance=appearance.integerValue;layoutWell(well);nilUnchanged=nilUnchanged&&[nilBaseline[@"bytes"]isEqual:render(well,NO)[@"bytes"]];
        }
        well.selectedColor=translucent;well.alpha=.8;
        well.centerAlphaAppearance=rectangle?UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground:UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground;
        NSMutableDictionary *archive=[NSMutableDictionary new],*colorArchive=[NSMutableDictionary new];
        UIColorPickerWell *restored=roundTrip(well,archive);UIColor *decodedColor=roundTrip(translucent,colorArchive);
        BOOL archiveRestored=restored&&decodedColor&&restored.shape==shape&&restored.centerAlphaAppearance==well.centerAlphaAppearance&&[restored.selectedColor isEqual:decodedColor]&&[restored.title isEqual:well.title]&&!restored.supportsAlpha&&fabs(restored.alpha-.8)<1e-6;
        if(restored){[fixture.view addSubview:restored];layoutWell(restored);NSDictionary *restoredLayers=layers(restored);archiveRestored=archiveRestored&&[restoredLayers[@"visualStyleCount"]unsignedIntegerValue]==1&&[restoredLayers[@"styleColorMatchesPublic"]boolValue];[restored removeFromSuperview];}
        BOOL silent=recorder.changes==0;
        BOOL extensionPassed=semantic&&exterior&&changedCenter&&capabilityIndependent&&baselineRestored&&transparent&&opaque&&nilUnchanged&&archiveRestored&&silent;
        passed=passed&&extensionPassed;
        [alphaExtensions addObject:@{@"shape":rectangle?@"rounded rectangle":@"circle",@"passed":@(extensionPassed),@"canonicalColorAlphaAXAndRootAlphaUnchanged":@(semantic),@"unchangedExteriorAndGeometry":@(exterior),@"translucentCenterChanges":@(changedCenter),@"supportsAlphaIndependent":@(capabilityIndependent),@"nativeBaselineRestored":@(baselineRestored),@"transparentBackingPixels":transparentPixels,@"opaqueBackingHidden":@(opaque),@"nilIgnoresAppearance":@(nilUnchanged),@"appearanceArchiveRestored":@(archiveRestored),@"archive":archive,@"decodedColorReference":colorArchive,@"valueChangedCount":@(recorder.changes),@"silent":@(silent)}];
        [well removeFromSuperview];
    }
    [parent setOverrideTraitCollection:nil forChildViewController:fixture];
    [fixture willMoveToParentViewController:nil];[fixture.view removeFromSuperview];[fixture removeFromParentViewController];
    NSURL *imageURL=[[url URLByDeletingPathExtension]URLByAppendingPathExtension:@"png"];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(480,42+pictures.count*84),YES,1);
    [UIColor.whiteColor setFill];UIRectFill(CGRectMake(0,0,480,42+pictures.count*84));
    NSDictionary *text=@{NSFontAttributeName:[UIFont systemFontOfSize:14],NSForegroundColorAttributeName:UIColor.blackColor};
    [@"Native UIKit" drawAtPoint:CGPointMake(278,12) withAttributes:text];[@"Recovered" drawAtPoint:CGPointMake(382,12) withAttributes:text];
    [pictures enumerateObjectsUsingBlock:^(NSDictionary *picture,NSUInteger index,BOOL *stop){
        CGFloat y=42+index*84;[picture[@"name"]drawInRect:CGRectMake(8,y+24,250,48) withAttributes:text];
        if(picture[@"native"]!=NSNull.null)[picture[@"native"]drawInRect:CGRectMake(290,y+4,64,64)];
        else [@"N/A" drawAtPoint:CGPointMake(302,y+26) withAttributes:text];
        [picture[@"recovered"]drawInRect:CGRectMake(390,y+4,64,64)];
    }];
    UIImage *collage=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();
    BOOL imageWritten=[UIImagePNGRepresentation(collage)writeToURL:imageURL options:NSDataWritingAtomic error:nil];
    passed=passed&&imageWritten&&cases.count>0;
    NSDictionary *result=@{@"passed":@(passed),@"nativeAvailable":@(nativeAvailable),@"caseCount":@(cases.count),@"cases":cases,@"alphaExtensionCaseCount":@(alphaExtensions.count),@"alphaExtensions":alphaExtensions,@"rasterColorSpace":@"sRGB premultiplied RGBA8",@"scale":@(scale),@"pixelCriterion":@"Both rasters must contain chromatic pixels. The runtime-drawn artwork permits mean RGBA8 error up to 1.25 and maximum error up to 24. Alpha, pixels outside the artwork, and the interior covered by the native border remain exact.",@"collageWritten":@(imageWritten),@"collage":imageURL.lastPathComponent,@"scope":@"Finite attached layer geometry and same-renderer raster comparisons for the UIKit15 well drawing. Programmatic button press/cancel actions verify style opacity and unchanged caller root alpha. One real keyed archive/unarchive restores a translucent color, Unicode title and supportsAlpha=NO, checks the newly owned style state, records restored style subviews and compares drawing. Archive errors or exceptions fail that row. Two separate optional-appearance rows exercise circle and rounded rectangle: native/diagonal/checker switching, unchanged canonical color/AX value/root alpha and exterior, silent assignments, supportsAlpha independence, alpha-zero backing pixels, opaque/nil compositing, and real shape/appearance archive restoration against independently decoded UIColor. These extensions are not native-equivalence claims; old archives missing the new keys are source-reviewed only. Does not establish physical touch, picker presentation, drag/drop, spoken accessibility, all states or physical-device parity. Native comparison requires the iOS15 style topology. On older runtimes, rows check adopted geometry, generated image and state restoration; iOS12 has no native UIColorWell, and no native-equivalence or dark-appearance claim is made there."};
    return[[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url options:NSDataWritingAtomic error:nil]&&passed;
}
+ (BOOL)runLocaleInputWithOutputURL:(NSURL *)url {
    NSString *language=[NSLocale.currentLocale objectForKey:NSLocaleLanguageCode];BOOL german=[language isEqual:@"de"],arabic=[language isEqual:@"ar"];
    NSString *input=arabic?@"١٫٢٥":german?@"1,25":@"1.25",*opacity=arabic?@"٦٥٪":@"65%";
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);CGFloat components[]={.2,.4,.6,.8};CGColorRef cg=CGColorCreate(space,components);UIColorValue *original=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);CGColorSpaceRelease(space);
    UIColorPanelConfiguration *config=[UIColorPanelConfiguration new];config.initialMode=UIColorPanelModeRGB;UIColorPanelViewController *panel=[[UIColorPanelViewController alloc]initWithColor:original configuration:config];[panel loadViewIfNeeded];panel.view.frame=CGRectMake(0,0,375,667);[panel.view layoutIfNeeded];
    BOOL unchanged=[panel.selectedColor isEqual:original];UISegmentedControl *precision=[panel valueForKey:@"precision"];precision.selectedSegmentIndex=1;[panel performSelector:@selector(precisionChanged:) withObject:precision];
    UITextField *red=[[panel valueForKey:@"componentFields"] firstObject];red.text=input;[red sendActionsForControlEvents:UIControlEventEditingChanged];[red sendActionsForControlEvents:UIControlEventEditingDidEnd];const CGFloat *actual=CGColorGetComponents(panel.selectedColor.CGColor);BOOL component=fabs(actual[0]-1.25)<1e-12&&fabs(actual[1]-.4)<1e-12&&fabs(CGColorGetAlpha(panel.selectedColor.CGColor)-.8)<1e-12;
    UITextField *alpha=[panel valueForKey:@"opacityField"];alpha.text=opacity;[alpha sendActionsForControlEvents:UIControlEventEditingChanged];[alpha sendActionsForControlEvents:UIControlEventEditingDidEnd];BOOL percent=fabs(CGColorGetAlpha(panel.selectedColor.CGColor)-.65)<1e-12;
    UITextField *hex=[panel valueForKey:@"hexField"];hex.text=@"FF8800";[hex sendActionsForControlEvents:UIControlEventEditingChanged];[hex sendActionsForControlEvents:UIControlEventEditingDidEnd];actual=CGColorGetComponents(panel.selectedColor.CGColor);BOOL hexadecimal=fabs(actual[0]-1)<1e-12&&fabs(actual[1]-136/255.0)<1e-12&&actual[2]==0&&fabs(CGColorGetAlpha(panel.selectedColor.CGColor)-.65)<1e-12&&hex.semanticContentAttribute==UISemanticContentAttributeForceLeftToRight;
    BOOL passed=unchanged&&component&&percent&&hexadecimal;NSDictionary *result=@{@"passed":@(passed),@"locale":NSLocale.currentLocale.localeIdentifier,@"componentInput":input,@"opacityInput":opacity,@"unmodifiedBeforeEditing":@(unchanged),@"extendedComponentRetained":@(component),@"percentParsed":@(percent),@"hexLTRAndExact":@(hexadecimal),@"display":@{ @"red":red.text?:@"",@"opacity":alpha.text?:@""},@"scope":@"Real text-field editing events in an isolated embedded panel using the process locale. No global language setting or persistence change, no keyboard gesture or VoiceOver speech claim."};return [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES]&&passed;
}

@end
