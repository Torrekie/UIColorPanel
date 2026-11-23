#import "UIColorPanel.h"
#import "UIColorValue+AppKitEquality.h"
#import "UIColorPanelWell+Internal.h"
#import "UIColorPanelViewController.h"
#import "UIColorPanelAppearance.h"
#import "UIColorArchiveRecord.h"
#import <objc/runtime.h>

NSNotificationName const UIColorPanelColorDidChangeNotification = @"UIColorPanelColorDidChangeNotification";
NSNotificationName const UIPanelWillCloseNotification = @"UIPanelWillCloseNotification";
static UIColorPanel *UISharedColorPanel;
static UIColorPanelOptions UIPickerMask = UIColorPanelAllModesMask;
static UIColorPanelMode UIPickerMode = UIColorPanelModeWheel;
static BOOL UIIgnoresAlpha = YES;

@interface UIWindow (UIColorPanelWindowContext)
@property(nonatomic, readonly, weak) UIWindow *previousKeyWindow;
@end

@interface UIPanel (UIColorPanelSizeTransition)
- (void)beginSizeTransitionWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
@end

@interface UIColorPanelNavigationController : UINavigationController
@end
@implementation UIColorPanelNavigationController
// BINMAP-ADAPT: UIColorPanelNavigationController.viewWillTransitionToSize:withTransitionCoordinator:
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    UIWindow *window=self.viewIfLoaded.window;
    [[UIPanel panelForWindow:window] beginSizeTransitionWithCoordinator:coordinator];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
@end

@interface UIColorPanelViewController (UIColorPanelTransientLifecycle)
- (void)endTransientInteractionsForClose:(BOOL)closing;
@end

@interface UIColorPanel () <UIColorPanelViewControllerDelegate> {
    NSUInteger _colorSettingSuppressionCount;
    BOOL _interactionInProgress;
    BOOL _handlingOpacityMoveAction;
    BOOL _opacityEnabled;
    CGFloat _opacity;
    UIColorPanelOptions _initialPickerMask;
    __weak id _target;
    SEL _action;
    BOOL _continuous;
    BOOL _hasModalAppearance;
    BOOL _closingPanel;
}
@property(nonatomic, strong) UIColorValue *storedColor;
@property(nonatomic, strong) UIColorPanelViewController *pickerController;
- (BOOL)_allowsColorSetting;
- (void)_withColorSettingDisabled:(void (^)(void))body;
- (void)_forceSetColor:(UIColor *)color;
- (void)_storeNewColorInColorWell:(UIColor *)color;
- (void)_validateOpacitySlider;
- (void)_resetOpacity:(NSNumber *)sender andForceSetColor:(BOOL)force;
- (void)_switchToAppropriateModeForColorIfNecessary:(UIColor *)color;
- (void)_forceSendAction:(BOOL)action notification:(BOOL)notification firstResponder:(BOOL)firstResponder;
- (void)_sendActionAndNotification;
- (BOOL)isUsingModalAppearance;
- (void)_set:(id)sender;
- (void)_sendResponderAction:(SEL)action;
- (void)_setShowAlpha:(BOOL)show andForce:(BOOL)force;
@end

@implementation UIColor (UIColorPanelSupport)
// BINMAP-ADAPT: UIColor(UIColorPanelSupport).ignoresAlpha — main-thread UIKit global policy, separate from AppKit preferences/locking.
+ (BOOL)ignoresAlpha { return UIIgnoresAlpha; }
// BINMAP-ADAPT: UIColor(UIColorPanelSupport).setIgnoresAlpha: — NSColor's global policy and shared-panel update, UIKit lifetime bridge.
+ (void)setIgnoresAlpha:(BOOL)ignoresAlpha {
    if(UIIgnoresAlpha != ignoresAlpha) {
        UIIgnoresAlpha=ignoresAlpha;
        if([UIColorPanel sharedColorPanelExists]) [[UIColorPanel sharedColorPanel] _setShowAlpha:!ignoresAlpha andForce:YES];
    }
}
@end

@implementation UIApplication (UIColorPanelSupport)
// BINMAP-ADAPT: UIApplication(UIColorPanelSupport).orderFrontColorPanel: — source-compatible UIApplication entry point for AppKit's application action.
- (void)orderFrontColorPanel:(id)sender { [[UIColorPanel sharedColorPanel] orderFront:sender]; }
@end

@implementation UIColorPanel
// BINMAP: original=AppKit ida_name=+[NSColorPanel sharedColorPanel] ea=0x183b22080 end=0x183b220c4
+ (UIColorPanel *)sharedColorPanel {
    if(!UISharedColorPanel) { UISharedColorPanel=[self alloc]; UISharedColorPanel=[UISharedColorPanel init]; }
    return UISharedColorPanel;
}
// BINMAP: original=AppKit ida_name=+[NSColorPanel sharedColorPanelExists] ea=0x1837ef490 end=0x1837ef4a4
+ (BOOL)sharedColorPanelExists { return UISharedColorPanel != nil; }
// BINMAP: original=AppKit ida_name=+[NSColorPanel setPickerMask:] ea=0x183b2210c end=0x183b22118
+ (void)setPickerMask:(UIColorPanelOptions)mask {
    UIPickerMask=mask;
    // UIKit providers are linked into the application; no desktop plug-in discovery bridge is required.
}
// BINMAP: original=AppKit ida_name=+[NSColorPanel setPickerMode:] ea=0x183b22118 end=0x183b22170
+ (void)setPickerMode:(UIColorPanelMode)mode {
    UIPickerMode=mode;
    if([self sharedColorPanelExists]) [[self sharedColorPanel] setMode:mode];
}
// BINMAP-ADAPT: UIColorPanel.init — NSPanel resources become a shared UIKit controller and floating window.
- (instancetype)init {
    if((self=[super initWithContentRect:CGRectZero])) {
        _continuous=YES;_opacity=1;_opacityEnabled=YES;_initialPickerMask=UIPickerMask;
        _storedColor=[[UIColorValue alloc] initWithCGColor:UIColor.whiteColor.CGColor];
        UIColorPanelConfiguration *configuration=[UIColorPanelConfiguration new];
        configuration.showsAlpha=!UIColor.ignoresAlpha;configuration.initialMode=UIPickerMode;
        _pickerController=[[UIColorPanelViewController alloc] initWithColor:_storedColor configuration:configuration];
        _pickerController.pickerMask=_initialPickerMask;_initialPickerMask=_pickerController.pickerMask;_pickerController.delegate=self;
        self.window.rootViewController=[[UIColorPanelNavigationController alloc] initWithRootViewController:_pickerController];
        self.title=[UIColorPanelAppearance localizedString:@"Colors"];[UIColorPanelAppearance applyCornersToView:self.window radius:12 useSPI:NO];
        [_pickerController loadViewIfNeeded];
    }
    return self;
}
// BINMAP-ADAPT: UIColorPanel.setUse_spi: manifest=reimpl/ui_corrections_extras.json
- (void)setUse_spi:(BOOL)value {[super setUse_spi:value];self.pickerController.use_spi=value;[self.window setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanel.colorProfiles manifest=reimpl/slider_profile_extras.json
- (NSArray<UIColorPanelColorProfile *> *)colorProfiles {return self.pickerController.colorProfiles;}
// BINMAP-ADAPT: UIColorPanel.setColorProfiles: manifest=reimpl/slider_profile_extras.json
- (void)setColorProfiles:(NSArray<UIColorPanelColorProfile *> *)profiles {self.pickerController.colorProfiles=profiles;}
// BINMAP-ADAPT: UIColorPanel.availableColorProfiles manifest=reimpl/slider_profile_extras.json
- (NSArray<UIColorPanelColorProfile *> *)availableColorProfiles {return self.pickerController.availableColorProfiles;}
// BINMAP-ADAPT: UIColorPanel.activeColorProfile manifest=reimpl/slider_profile_extras.json
- (UIColorPanelColorProfile *)activeColorProfile {return self.pickerController.activeColorProfile;}
// BINMAP-ADAPT: UIColorPanel.selectColorProfile:error: manifest=reimpl/slider_profile_extras.json
- (BOOL)selectColorProfile:(UIColorPanelColorProfile *)profile error:(NSError **)error {
    if(![self _allowsColorSetting]){if(error)*error=[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorSelectionSuppressed userInfo:@{NSLocalizedDescriptionKey:@"The panel is already delivering a color change."}];return NO;}
    return[self.pickerController selectColorProfile:profile error:error];
}
// BINMAP-ADAPT: UIColorPanel.refreshColorProfiles manifest=reimpl/slider_profile_extras.json
- (void)refreshColorProfiles {[self.pickerController refreshColorProfiles];}
// BINMAP: original=AppKit ida_name=-[NSColorPanel setTarget:] ea=0x183b2294c end=0x183b2295c
- (void)setTarget:(id)target { _target=target; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel target] ea=0x183b2295c end=0x183b2296c
- (id)target { return _target; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel setAction:] ea=0x183b228d8 end=0x183b22908
- (void)setAction:(SEL)action { _action=action?:NULL; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel action] ea=0x183b22908 end=0x183b2294c
- (SEL)action { return _action; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel color] ea=0x183b25610 end=0x183b25620
- (UIColor *)color { return self.storedColor.UIColor; }
// BINMAP-ADAPT: UIColorPanel.colorValue — preserve the canonical CGColor across the public UIColor boundary.
- (UIColorValue *)colorValue { return self.storedColor; }
// BINMAP-ADAPT: UIColorPanel.setColorValue: — exact-color entry follows the same setColor: dispatch pipeline.
- (void)setColorValue:(UIColorValue *)colorValue { [self setColor:colorValue.UIColor]; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel _allowsColorSetting] ea=0x183b25724 end=0x183b2573c
- (BOOL)_allowsColorSetting { return _colorSettingSuppressionCount==0; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel _withColorSettingDisabled:] ea=0x183b2573c end=0x183b257dc
- (void)_withColorSettingDisabled:(void (^)(void))body {
    ++_colorSettingSuppressionCount;body();
    NSAssert(_colorSettingSuppressionCount!=0,@"_colorSettingSuppressionCount underflow");
    --_colorSettingSuppressionCount;
    // Deliberately no @finally: the original does not restore this counter after an exception.
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel setColor:] ea=0x183b259c8 end=0x183b25aac
- (void)setColor:(UIColor *)color {
    if(![self _allowsColorSetting])return;
    UIColorValue *incoming=color?[[UIColorValue alloc] initWithCGColor:color.CGColor]:nil;
    // BINMAP-ADAPT: equal numeric fallbacks do not erase a newly supplied
    // catalog identity, or retain one after an explicit component-color edit.
    NSDictionary *currentMetadata=objc_getAssociatedObject(self.storedColor,&UIColorArchiveMetadataAssociationKey),*incomingMetadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey);
    BOOL sameMetadata=currentMetadata==incomingMetadata||[currentMetadata isEqual:incomingMetadata];
    if(sameMetadata&&[self.storedColor isEqualForColorPanel:incoming]) {
        if(_continuous) { [self _forceSendAction:NO notification:NO firstResponder:YES];return; }
    } else [self _forceSetColor:color];
    // UIKit tracking replaces NSEvent.pressedMouseButtons & 1.
    if(!_continuous && _interactionInProgress)return;
    [self _sendActionAndNotification];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel _forceSetColor:] ea=0x183b25b88 end=0x183b25c14
- (void)_forceSetColor:(UIColor *)color {
    if(color && [self _allowsColorSetting]) {
        // BINMAP-BLOCK: invoke_ea=0x183b25c14 end=0x183b25d1c parent_ea=0x183b25b88 reconstructed_as=block_literal
        [self _withColorSettingDisabled:^{
            CGFloat alpha=CGColorGetAlpha(color.CGColor);
            UIColor *value=(UIColor.ignoresAlpha && alpha<1)?[color colorWithAlphaComponent:1]:color;
            if(!value)return;
            [self _storeNewColorInColorWell:value];
            if(!UIColor.ignoresAlpha) {
                if(!self->_handlingOpacityMoveAction)self->_opacity=alpha;
                [self _resetOpacity:@(self->_opacity) andForceSetColor:NO];
            }
            [self _switchToAppropriateModeForColorIfNecessary:value];
            self.pickerController.selectedColor=self.storedColor;
        }];
    }
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel _storeNewColorInColorWell:] ea=0x183b229e8 end=0x183b22a2c
- (void)_storeNewColorInColorWell:(UIColor *)color {
    self.storedColor=[[UIColorValue alloc] initWithCGColor:color.CGColor];
    // BINMAP-ADAPT: use the same private metadata transport as UIColorArchive
    // and UIColorList; CGColor remains the unchanged numeric/ICC authority.
    NSDictionary *metadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey);
    if(metadata)objc_setAssociatedObject(self.storedColor,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self _validateOpacitySlider];
}
// BINMAP-ADAPT: UIColorPanel._validateOpacitySlider — NSColor alpha capability uses canonical CGColor copying and UIKit controls.
- (void)_validateOpacitySlider {
    _opacityEnabled=[self.storedColor copyWithAlpha:.5]!=nil;
    self.pickerController.alphaEditingEnabled=_opacityEnabled;
}
// BINMAP-ADAPT: UIColorPanel._resetOpacity:andForceSetColor: — the controller validates text/range; NSNumber transports the double-valued slider state.
- (void)_resetOpacity:(NSNumber *)sender andForceSetColor:(BOOL)force {
    CGFloat previous=CGColorGetAlpha(self.storedColor.CGColor),value=sender.doubleValue;
    _opacity=value;
    if(force || previous!=value) {
        UIColorValue *color=[self.storedColor copyWithAlpha:value];
        if(color)[self setColor:color.UIColor];
    }
}
// BINMAP-ADAPT: UIColorPanel._switchToAppropriateModeForColorIfNecessary: — UIKit CGColor space model replaces NSColor's custom-space selector.
- (void)_switchToAppropriateModeForColorIfNecessary:(UIColor *)color {
    CGColorSpaceModel model=CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    if(model<kCGColorSpaceModelMonochrome || model>kCGColorSpaceModelCMYK)return;
    UIColorPanelMode mode=self.mode;
    if(mode>=UIColorPanelModeGray && mode<=UIColorPanelModeHSB) {
        UIColorPanelMode desired=model==kCGColorSpaceModelMonochrome?UIColorPanelModeGray:model==kCGColorSpaceModelCMYK?UIColorPanelModeCMYK:UIColorPanelModeRGB;
        // HSB and RGB share the native RGB model; changing between them is unnecessary.
        if(!(desired==UIColorPanelModeRGB && mode==UIColorPanelModeHSB) && desired!=mode)self.mode=desired;
    }
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel _forceSendAction:notification:firstResponder:] ea=0x183b2580c end=0x183b25884
- (void)_forceSendAction:(BOOL)action notification:(BOOL)notification firstResponder:(BOOL)firstResponder {
    // BINMAP-BLOCK: invoke_ea=0x183b25884 end=0x183b25984 parent_ea=0x183b2580c reconstructed_as=block_literal
    [self _withColorSettingDisabled:^{
        if(![UIColorPanelWell _exclusiveColorPanelOwner]) {
            if(action && self->_action && self->_target)[UIApplication.sharedApplication sendAction:self->_action to:self->_target from:self forEvent:nil];
            if(firstResponder)[self _sendResponderAction:NSSelectorFromString(@"changeColor:")];
        }
        if(notification)[NSNotificationCenter.defaultCenter postNotificationName:UIColorPanelColorDidChangeNotification object:self];
    }];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel _sendActionAndNotification] ea=0x183b25984 end=0x183b259c8
- (void)_sendActionAndNotification { BOOL modal=[self isUsingModalAppearance];[self _forceSendAction:YES notification:!modal firstResponder:!modal]; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel isUsingModalAppearance] ea=0x183b2352c end=0x183b2353c
- (BOOL)isUsingModalAppearance { return _hasModalAppearance; }
// BINMAP-ADAPT: UIColorPanel._sendResponderAction: — UIKit routing retains the host responder chain before and during panel text editing.
- (void)_sendResponderAction:(SEL)action {
    UIWindow *previous=[self.window previousKeyWindow];
    // This facade is not in its window's responder chain. Resolve the owned
    // host explicitly even while it remains key, before falling back to UIKit.
    if(previous && (previous.isKeyWindow||self.window.isKeyWindow)) {
        NSMutableArray<UIView *> *views=[NSMutableArray arrayWithObject:previous];
        for(NSUInteger i=0;i<views.count;i++) {
            UIView *view=views[i];
            // A visible host controller can itself own first-responder status.
            // Follow the public responder chain as far as that host window,
            // preserving the existing view-first-responder route as well.
            for(UIResponder *responder=view;responder;responder=responder.nextResponder) {
                if(responder.isFirstResponder) {
                    id target=[responder targetForAction:action withSender:self];
                    if(target)[UIApplication.sharedApplication sendAction:action to:target from:self forEvent:nil];
                    return;
                }
                if(responder==previous)break;
            }
            [views addObjectsFromArray:view.subviews];
        }
    }
    [UIApplication.sharedApplication sendAction:action to:nil from:self forEvent:nil];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel _set:] ea=0x183b25d1c end=0x183b25d8c
- (void)_set:(id)sender {
    [self _forceSetColor:self.color];[self _sendActionAndNotification];
    [self _sendResponderAction:NSSelectorFromString(@"changeColor:")];
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel setContinuous:] ea=0x183b22ef4 end=0x183b22f04
- (void)setContinuous:(BOOL)continuous { _continuous=continuous; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel isContinuous] ea=0x183b22f04 end=0x183b22f14
- (BOOL)isContinuous { return _continuous; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel showsAlpha] ea=0x183b23ec8 end=0x183b23eec
- (BOOL)showsAlpha { return !UIColor.ignoresAlpha; }
// BINMAP: original=AppKit ida_name=-[NSColorPanel setShowsAlpha:] ea=0x183b23eb8 end=0x183b23ec8
- (void)setShowsAlpha:(BOOL)showsAlpha { UIColor.ignoresAlpha=!showsAlpha; }
// BINMAP-ADAPT: UIColorPanel._setShowAlpha:andForce: — UIKit layout replaces desktop minimum-size/key-view changes; coercion order is retained.
- (void)_setShowAlpha:(BOOL)show andForce:(BOOL)force {
    if(force || UIColor.ignoresAlpha==show) {
        if(!show) { _opacity=1;[self _resetOpacity:@1 andForceSetColor:NO]; }
        self.pickerController.showsAlpha=show;
    }
}
// BINMAP: original=AppKit ida_name=-[NSColorPanel alpha] ea=0x183b25620 end=0x183b25680
- (CGFloat)alpha { return self.showsAlpha?_opacity:1; }
// BINMAP-ADAPT: UIColorPanel.mode — the shared controller owns the current picker mode.
- (UIColorPanelMode)mode { return self.pickerController.mode; }
// BINMAP-ADAPT: UIColorPanel.setMode: — eight native numeric modes dispatch to the shared UIKit picker controller.
- (void)setMode:(UIColorPanelMode)mode { self.pickerController.mode=mode; }
// BINMAP-ADAPT: UIColorPanel.pickerMask — the native mask is captured when providers are instantiated.
- (UIColorPanelOptions)pickerMask { return _initialPickerMask; }
// BINMAP-ADAPT: UIColorPanel.accessoryView — UIKit embeds the caller's existing view.
- (UIView *)accessoryView { return self.pickerController.accessoryView; }
// BINMAP-ADAPT: UIColorPanel.setAccessoryView: — host view identity and removal are retained.
- (void)setAccessoryView:(UIView *)accessoryView { self.pickerController.accessoryView=accessoryView; }
// BINMAP-ADAPT: UIColorPanel.attachColorList: — UIKit catalog provider owns name-based attachment.
- (void)attachColorList:(UIColorList *)colorList { [self.pickerController attachColorList:colorList]; }
// BINMAP-ADAPT: UIColorPanel.detachColorList: — UIKit catalog provider handles explicit/file-backed identity.
- (void)detachColorList:(UIColorList *)colorList { [self.pickerController detachColorList:colorList]; }
// BINMAP-ADAPT: UIColorPanel.orderFront: — refreshes loaded favorites before the modeless window becomes visible.
- (void)orderFront:(id)sender {
    [self.pickerController refreshFavorites];
    [self.pickerController loadViewIfNeeded];
    [super orderFront:sender];
}
// BINMAP-ADAPT: UIColorPanel.orderOut: — cancel transient UIKit operations while preserving the active shared color-well session.
- (void)orderOut:(id)sender {
    [self.pickerController endTransientInteractionsForClose:NO];
    [super orderOut:sender];
}
// BINMAP-ADAPT: UIColorPanel.close — window-close observers deactivate active wells; orderOut: preserves them.
- (void)close {
    if(_closingPanel)return;_closingPanel=YES;
    [self.pickerController endTransientInteractionsForClose:YES];
    [NSNotificationCenter.defaultCenter postNotificationName:UIPanelWillCloseNotification object:self];
    [UIColorPanelWell _deactivateAllColorWells];[super close];
    _closingPanel=NO;
}
// BINMAP-ADAPT: UIColorPanel.colorPanel:didSelectColor: — all views feed the native setColor: pipeline.
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color { self.colorValue=color; }
// BINMAP-ADAPT: UIColorPanel.colorPanelWillBeginEditing: — primary touch maps to AppKit's pressed primary mouse button.
- (void)colorPanelWillBeginEditing:(UIColorPanelViewController *)panel { _interactionInProgress=YES; }
// BINMAP-ADAPT: UIColorPanel.colorPanelDidEndEditing: — noncontinuous touch release commits the current color.
- (void)colorPanelDidEndEditing:(UIColorPanelViewController *)panel { _interactionInProgress=NO;if(!_continuous)[self _set:panel]; }
// BINMAP-ADAPT: UIColorPanel.colorPanelDidFinish: — the Done button closes the modeless shared window.
- (void)colorPanelDidFinish:(UIColorPanelViewController *)panel { [self close]; }
// BINMAP-ADAPT: UIColorPanel.allowsApplicationSampling manifest=reimpl/polish_shell_extras.json
- (BOOL)allowsApplicationSampling {return self.pickerController.allowsApplicationSampling;}
// BINMAP-ADAPT: UIColorPanel.setAllowsApplicationSampling: manifest=reimpl/polish_shell_extras.json
- (void)setAllowsApplicationSampling:(BOOL)value {self.pickerController.allowsApplicationSampling=value;}
// BINMAP-ADAPT: UIColorPanel.samplingSourceView manifest=reimpl/polish_shell_extras.json
- (UIView *)samplingSourceView {return self.pickerController.samplingSourceView;}
// BINMAP-ADAPT: UIColorPanel.setSamplingSourceView: manifest=reimpl/polish_shell_extras.json
- (void)setSamplingSourceView:(UIView *)view {self.pickerController.samplingSourceView=view;}
// BINMAP-ADAPT: UIColorPanel.samplingImage manifest=reimpl/polish_shell_extras.json
- (UIImage *)samplingImage {return self.pickerController.samplingImage;}
// BINMAP-ADAPT: UIColorPanel.setSamplingImage: manifest=reimpl/polish_shell_extras.json
- (void)setSamplingImage:(UIImage *)image {self.pickerController.samplingImage=image;}

@end
