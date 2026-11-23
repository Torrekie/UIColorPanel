#import "UIPanel.h"
#import "UIColorPanelAppearance.h"
@interface UIPanel (SizeTransition)
- (void)beginSizeTransitionWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
@end

@interface UIPanelWindow : UIWindow {
    BOOL _adjustingPanelFrame;
    BOOL _automaticallyMatchesPhoneWidth;
    BOOL _desiredPanelVisible;
    BOOL _visibilityTransitioning;
    NSUInteger _visibilityGeneration;
    CGFloat _visiblePanelAlpha;
    id<UIViewControllerTransitionCoordinator> _frameTransitionCoordinator;
}
@property(nonatomic, weak) UIPanel *panelOwner;
@property(nonatomic) BOOL use_spi;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;
@property(nonatomic, readonly, getter=isTransitioning) BOOL transitioning;
@property(nonatomic, weak) UIViewController *presentationViewController;
@property(nonatomic, weak) UIWindow *previousKeyWindow;
@property(nonatomic, copy) NSString *panelTitle;
@property(nonatomic) CGSize requestedPanelSize;
@property(nonatomic, strong) UIViewPropertyAnimator *visibilityAnimator;
- (void)orderFront:(id)sender;
- (void)orderOut:(id)sender;
- (void)close;
- (void)transitionToVisible:(BOOL)visible animated:(BOOL)animated;
- (void)restorePreviousKeyWindow;
- (void)beginSizeTransitionWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
@end

@interface UIPanelContentViewController : UIViewController
@end
@implementation UIPanelContentViewController
// BINMAP-ADAPT: UIPanelContentViewController.viewWillTransitionToSize:withTransitionCoordinator:
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    UIWindow *window=self.viewIfLoaded.window;
    [[UIPanel panelForWindow:window] beginSizeTransitionWithCoordinator:coordinator];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
@end

@implementation UIPanelWindow
// BINMAP-ADAPT: UIPanelWindow.initWithFrame: — bounded nonmodal UIKit window, not an NSWindow reconstruction.
- (instancetype)initWithFrame:(CGRect)frame {
    CGRect screen=UIScreen.mainScreen.bounds;
    BOOL automaticPhoneWidth=CGRectIsEmpty(frame)&&UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPhone;
    if(CGRectIsEmpty(frame)) frame=CGRectMake(automaticPhoneWidth?CGRectGetMinX(screen):CGRectGetMidX(screen)-168,CGRectGetMidY(screen)-344.5,automaticPhoneWidth?CGRectGetWidth(screen):336,689);
    if((self=[super initWithFrame:frame])) {
        _automaticallyMatchesPhoneWidth=automaticPhoneWidth;
        _requestedPanelSize=frame.size;
        _visiblePanelAlpha=1;
        self.windowLevel=UIWindowLevelNormal+1;
        self.backgroundColor=UIColor.clearColor;
        self.hidden=YES;
        self.rootViewController=[UIPanelContentViewController new];
        self.rootViewController.view.backgroundColor=UIColor.whiteColor;
        self.panelTitle=@"";
        for(NSNotificationName name in @[UITextFieldTextDidBeginEditingNotification,UITextViewTextDidBeginEditingNotification])[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(editingDidBegin:) name:name object:nil];
        for(NSNotificationName name in @[UITextFieldTextDidEndEditingNotification,UITextViewTextDidEndEditingNotification])[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(editingDidEnd:) name:name object:nil];
    }
    return self;
}
// BINMAP-ADAPT: UIPanelWindow.dealloc
- (void)dealloc { [[NSNotificationCenter defaultCenter]removeObserver:self]; }
// BINMAP-ADAPT: UIPanelWindow.editingDidBegin:
- (void)editingDidBegin:(NSNotification *)notification {
    UIView *responder=[notification.object isKindOfClass:UIView.class]?notification.object:nil;
    if(responder.window==self&&self.isVisible&&!self.isKeyWindow)[self makeKeyWindow];
}
// BINMAP-ADAPT: UIPanelWindow.editingDidEnd:
- (void)editingDidEnd:(NSNotification *)notification {
    UIView *responder=[notification.object isKindOfClass:UIView.class]?notification.object:nil;if(responder.window!=self)return;
    __weak typeof(self) weakSelf=self;dispatch_async(dispatch_get_main_queue(),^{ // BINMAP-ADAPT-BLOCK: UIKit responder handoff completes before testing remaining owned first responders.
        UIPanelWindow *panel=weakSelf;if(!panel||!panel.isVisible||!panel.isKeyWindow)return;
        NSMutableArray<UIView *> *pending=[NSMutableArray arrayWithObject:panel];while(pending.count){UIView *view=pending.lastObject;[pending removeLastObject];if(view.isFirstResponder)return;[pending addObjectsFromArray:view.subviews];}
        [panel restorePreviousKeyWindow];
    });
}
// BINMAP-ADAPT: UIPanelWindow.contentView — NSWindow content surface via root UIViewController.
- (UIView *)contentView { return self.rootViewController.view; }
// BINMAP-ADAPT: UIPanelWindow.setContentView: — host controller retains supplied content.
- (void)setContentView:(UIView *)contentView { NSParameterAssert(contentView);self.rootViewController.view=contentView; }
// BINMAP-ADAPT: UIPanelWindow.title — namespaced NSWindow title analogue.
- (NSString *)title { return self.panelTitle; }
// BINMAP-ADAPT: UIPanelWindow.setTitle: — synchronize native navigation/accessibility title.
- (void)setTitle:(NSString *)title { self.panelTitle=[title copy]?:@"";self.rootViewController.title=self.panelTitle;self.accessibilityLabel=self.panelTitle; }
// BINMAP-ADAPT: UIPanelWindow.isVisible — a retiring nonmodal window is logically hidden before its visual transition ends.
- (BOOL)isVisible { return _visibilityTransitioning?_desiredPanelVisible:!self.hidden; }
// BINMAP-ADAPT: UIPanelWindow.isTransitioning — source-scoped sampling waits for a stable owned window appearance.
- (BOOL)isTransitioning { return _visibilityTransitioning; }
// BINMAP-ADAPT: UIPanelWindow.restorePreviousKeyWindow — only surrender this panel's own key ownership, never another window's.
- (void)restorePreviousKeyWindow {
    UIWindow *host=self.previousKeyWindow;
    if(!self.isKeyWindow||!host||host==self||host.hidden)return;
    if(@available(iOS 13.0,*))if(self.windowScene&&host.windowScene!=self.windowScene)return;
    [host makeKeyWindow];
}
// BINMAP-ADAPT: UIPanelWindow.transitionToVisible:animated: — interruptible UIKit appearance bridge; window geometry and modeless scope are preserved.
- (void)transitionToVisible:(BOOL)visible animated:(BOOL)animated {
    if(_visibilityTransitioning&&_desiredPanelVisible==visible)return;
    if(!_visibilityTransitioning&&self.hidden==!visible){_desiredPanelVisible=visible;return;}
    BOOL wasHidden=self.hidden;
    if(!_visibilityTransitioning)_visiblePanelAlpha=self.layer.opacity;
    CGFloat currentAlpha=self.layer.presentationLayer?self.layer.presentationLayer.opacity:self.layer.opacity;
    [self.visibilityAnimator stopAnimation:YES];self.visibilityAnimator=nil;
    NSUInteger generation=++_visibilityGeneration;_desiredPanelVisible=visible;_visibilityTransitioning=YES;
    [UIView performWithoutAnimation:^{ // BINMAP-ADAPT-BLOCK: settle only the previous owned appearance before changing its destination.
        self.alpha=wasHidden?0:currentAlpha;
        if(visible){
            // First showing a window can synchronously orient its frame before
            // its root controller has joined the window hierarchy.
            BOOL wasAdjusting=self->_adjustingPanelFrame;self->_adjustingPanelFrame=YES;
            self.hidden=NO;
            self->_adjustingPanelFrame=wasAdjusting;[self setNeedsLayout];
        }
    }];
    BOOL animate=animated&&UIView.areAnimationsEnabled;
    if(!animate){
        self.hidden=!visible;self.alpha=_visiblePanelAlpha;_visibilityTransitioning=NO;return;
    }
    __weak typeof(self) weakSelf=self;
    UIViewPropertyAnimator *animator=[[UIViewPropertyAnimator alloc]initWithDuration:UIAccessibilityIsReduceMotionEnabled()?.1:.2 curve:UIViewAnimationCurveEaseInOut animations:^{ // BINMAP-ADAPT-BLOCK: alpha-only transition avoids changing UIWindow frame or sampling coordinates.
        UIPanelWindow *panel=weakSelf;if(panel)panel.alpha=visible?panel->_visiblePanelAlpha:0;
    }];
    self.visibilityAnimator=animator;
    [animator addCompletion:^(UIViewAnimatingPosition position){ // BINMAP-ADAPT-BLOCK: a superseded exit cannot hide a newly reopened panel.
        UIPanelWindow *panel=weakSelf;if(!panel||panel->_visibilityGeneration!=generation)return;
        panel.visibilityAnimator=nil;panel->_visibilityTransitioning=NO;
        [UIView performWithoutAnimation:^{panel.hidden=!panel->_desiredPanelVisible;panel.alpha=panel->_visiblePanelAlpha;}];
    }];
    [animator startAnimation];
}
// BINMAP-ADAPT: UIPanelWindow.orderFront: — public scene selection and non-key floating presentation.
- (void)orderFront:(id)sender {
    UIView *anchor=[sender isKindOfClass:UIView.class]?sender:self.presentationViewController.view;
    UIWindow *host=anchor.window;
    if(!host && [sender isKindOfClass:UIViewController.class]) host=[(UIViewController *)sender view].window;
    if(@available(iOS 13.0,*)) {
        UIWindowScene *scene=host.windowScene;
        if(!scene) for(UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
            if(candidate.activationState==UISceneActivationStateForegroundActive && [candidate isKindOfClass:UIWindowScene.class]) {scene=(UIWindowScene *)candidate;break;}
        }
        if(scene && self.windowScene!=scene) self.windowScene=scene;
        if(!host) for(UIWindow *window in scene.windows) if(window.isKeyWindow && window!=self) {host=window;break;}
    } else {
        if(!host) host=UIApplication.sharedApplication.keyWindow;
    }
    if(host && host!=self && !self.isKeyWindow) self.previousKeyWindow=host;
    CGRect available=self.screen.bounds;
    if(@available(iOS 13.0,*))if(self.windowScene)available=self.windowScene.coordinateSpace.bounds;
    UIEdgeInsets safe=host.safeAreaInsets;
    if(_automaticallyMatchesPhoneWidth){safe.left=0;safe.right=0;}
    available=UIEdgeInsetsInsetRect(available,safe);
    available=CGRectInset(available,_automaticallyMatchesPhoneWidth?0:8,8);
    CGRect rect=self.frame;rect.size=self.requestedPanelSize;
    rect.size.width=_automaticallyMatchesPhoneWidth?available.size.width:MIN(rect.size.width,available.size.width);
    rect.size.height=MIN(rect.size.height,available.size.height);
    rect.origin.x=MAX(CGRectGetMinX(available),MIN(rect.origin.x,CGRectGetMaxX(available)-rect.size.width));
    rect.origin.y=MAX(CGRectGetMinY(available),MIN(rect.origin.y,CGRectGetMaxY(available)-rect.size.height));
    _adjustingPanelFrame=YES;self.frame=rect;_adjustingPanelFrame=NO;
    [self transitionToVisible:YES animated:YES];
}
// BINMAP-ADAPT: UIPanelWindow.beginSizeTransitionWithCoordinator:
- (void)beginSizeTransitionWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    _frameTransitionCoordinator=coordinator;
    __weak typeof(self) weakSelf=self;
    __weak id<UIViewControllerTransitionCoordinator> weakCoordinator=coordinator;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context){ // BINMAP-ADAPT-BLOCK: UIKit owns intermediate window frames until this transition completes.
        UIPanelWindow *panel=weakSelf;
        if(panel && panel->_frameTransitionCoordinator==weakCoordinator){panel->_frameTransitionCoordinator=nil;[panel setNeedsLayout];}
    }];
}
// BINMAP-ADAPT: UIPanelWindow.setFrame:
- (void)setFrame:(CGRect)frame {
    if(!_adjustingPanelFrame && !_frameTransitionCoordinator){
        if(_automaticallyMatchesPhoneWidth){
            CGRect sceneBounds=self.screen.bounds;
            if(@available(iOS 13.0,*))if(self.windowScene)sceneBounds=self.windowScene.coordinateSpace.bounds;
            // Outside UIKit's size transition, a narrower/wider frame restores
            // caller-controlled sizing. Rotation frames are presentation only.
            if(ABS(frame.size.width-CGRectGetWidth(sceneBounds))>0.5)_automaticallyMatchesPhoneWidth=NO;
        }
        if(!_automaticallyMatchesPhoneWidth)self.requestedPanelSize=frame.size;
    }
    [super setFrame:frame];
}
// BINMAP-ADAPT: UIPanelWindow.layoutSubviews
- (void)layoutSubviews {
    if(self.isVisible){
        UIWindow *host=self.previousKeyWindow;CGRect available=self.screen.bounds;
        if(@available(iOS 13.0,*))if(self.windowScene)available=self.windowScene.coordinateSpace.bounds;
        UIEdgeInsets safe=host.safeAreaInsets;if(_automaticallyMatchesPhoneWidth){safe.left=0;safe.right=0;}
        available=CGRectInset(UIEdgeInsetsInsetRect(available,safe),_automaticallyMatchesPhoneWidth?0:8,8);
        CGRect rect=self.frame;rect.size=CGSizeMake(_automaticallyMatchesPhoneWidth?available.size.width:MIN(self.requestedPanelSize.width,available.size.width),MIN(self.requestedPanelSize.height,available.size.height));rect.origin.x=MAX(CGRectGetMinX(available),MIN(rect.origin.x,CGRectGetMaxX(available)-rect.size.width));rect.origin.y=MAX(CGRectGetMinY(available),MIN(rect.origin.y,CGRectGetMaxY(available)-rect.size.height));if(!CGRectEqualToRect(rect,self.frame)){BOOL wasAdjusting=_adjustingPanelFrame;_adjustingPanelFrame=YES;self.frame=rect;_adjustingPanelFrame=wasAdjusting;}
    }
    [super layoutSubviews];if(self.layer.cornerRadius>0||self.layer.mask)[UIColorPanelAppearance applyCornersToView:self radius:12 useSPI:self.use_spi];
}
// BINMAP-ADAPT: UIPanelWindow.orderOut: — hiding does not close the shared color session.
- (void)orderOut:(id)sender {
    [self endEditing:YES];
    [self restorePreviousKeyWindow];
    [self transitionToVisible:NO animated:YES];
}
// BINMAP-ADAPT: UIPanelWindow.close — base lifecycle; UIColorPanel owns active-well teardown.
- (void)close { [self endEditing:YES];[self orderOut:nil];self.previousKeyWindow=nil; }
// BINMAP-ADAPT: UIPanelWindow.hitTest:withEvent: — prevent window from intercepting touches beyond its content rectangle.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event { return self.isVisible&&!self.isTransitioning&&CGRectContainsPoint(self.bounds,point)?[super hitTest:point withEvent:event]:nil; }
@end

@interface UIPanel ()
@property(nonatomic, strong) UIPanelWindow *panelWindow;
@end

@implementation UIPanel
// BINMAP-ADAPT: UIPanel.init — NSResponder-style owner separates window rendering from color alpha.
- (instancetype)init { return [self initWithContentRect:CGRectZero]; }
// BINMAP-ADAPT: UIPanel.initWithContentRect:
- (instancetype)initWithContentRect:(CGRect)rect { return [self initWithFrame:rect]; }
// BINMAP-ADAPT: UIPanel.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super init])){_panelWindow=[[UIPanelWindow alloc]initWithFrame:frame];_panelWindow.panelOwner=self;}
    return self;
}
// BINMAP-ADAPT: UIPanel.window
- (UIWindow *)window { return self.panelWindow; }
// BINMAP-ADAPT: UIPanel.panelForWindow:
+ (UIPanel *)panelForWindow:(UIWindow *)window { return [window isKindOfClass:UIPanelWindow.class]?((UIPanelWindow *)window).panelOwner:nil; }
// BINMAP-ADAPT: UIPanel.frame
- (CGRect)frame { return self.panelWindow.frame; }
// BINMAP-ADAPT: UIPanel.setFrame:
- (void)setFrame:(CGRect)frame { self.panelWindow.frame=frame; }
// BINMAP-ADAPT: UIPanel.contentView
- (UIView *)contentView { return self.panelWindow.contentView; }
// BINMAP-ADAPT: UIPanel.setContentView:
- (void)setContentView:(UIView *)view { self.panelWindow.contentView=view; }
// BINMAP-ADAPT: UIPanel.title
- (NSString *)title { return self.panelWindow.title; }
// BINMAP-ADAPT: UIPanel.setTitle:
- (void)setTitle:(NSString *)title { self.panelWindow.title=title; }
// BINMAP-ADAPT: UIPanel.isVisible
- (BOOL)isVisible { return self.panelWindow.visible; }
// BINMAP-ADAPT: UIPanel.isTransitioning
- (BOOL)isTransitioning { return self.panelWindow.transitioning; }
// BINMAP-ADAPT: UIPanel.use_spi
- (BOOL)use_spi { return self.panelWindow.use_spi; }
// BINMAP-ADAPT: UIPanel.setUse_spi:
- (void)setUse_spi:(BOOL)value { self.panelWindow.use_spi=value; }
// BINMAP-ADAPT: UIPanel.presentationViewController
- (UIViewController *)presentationViewController { return self.panelWindow.presentationViewController; }
// BINMAP-ADAPT: UIPanel.setPresentationViewController:
- (void)setPresentationViewController:(UIViewController *)controller { self.panelWindow.presentationViewController=controller; }
// BINMAP-ADAPT: UIPanel.beginSizeTransitionWithCoordinator:
- (void)beginSizeTransitionWithCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator { [self.panelWindow beginSizeTransitionWithCoordinator:coordinator]; }
// BINMAP-ADAPT: UIPanel.orderFront:
- (void)orderFront:(id)sender { [self.panelWindow orderFront:sender]; }
// BINMAP-ADAPT: UIPanel.orderOut:
- (void)orderOut:(id)sender { [self.panelWindow orderOut:sender]; }
// BINMAP-ADAPT: UIPanel.close
- (void)close { [self.panelWindow close]; }
@end
