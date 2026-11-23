#import "EyedropperValidation.h"
#import "UIEyedropperColor.h"
#import "UIEyedropperLensView.h"
#import "UIEyedropperViewController.h"
#import "UIColorPanelAppearance.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <string.h>
#import <dispatch/dispatch.h>

@interface UIEyedropperViewController (EyedropperValidation)
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
- (BOOL)accessibilityMoveLeft:(UIAccessibilityCustomAction *)action;
- (BOOL)accessibilityMoveRight:(UIAccessibilityCustomAction *)action;
- (BOOL)accessibilityMoveUp:(UIAccessibilityCustomAction *)action;
- (BOOL)accessibilityMoveDown:(UIAccessibilityCustomAction *)action;
@end

// Test-only recognized state/coordinate transport. No UIKit touch sequence is
// synthesized; points and translations are declared in the picker's root view.
@interface UIEyedropperPanFixture : UIPanGestureRecognizer
@property(nonatomic) UIGestureRecognizerState fixtureState;
@property(nonatomic) CGPoint fixtureLocation,fixtureTranslation;
@end
@implementation UIEyedropperPanFixture
- (UIGestureRecognizerState)state { return self.fixtureState; }
- (CGPoint)locationInView:(UIView *)view { return self.fixtureLocation; }
- (CGPoint)translationInView:(UIView *)view { return self.fixtureTranslation; }
@end

static BOOL UIEyedropperMatches(UIColorValue *value,double r,double g,double b,double tolerance) {
    if(!value)return NO;CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);CGFloat actual[4];BOOL valid=[value getRGBComponents:actual inColorSpace:space error:nil];CGColorSpaceRelease(space);return valid&&fabs(actual[0]-r)<tolerance&&fabs(actual[1]-g)<tolerance&&fabs(actual[2]-b)<tolerance&&fabs(actual[3]-1)<tolerance;
}

static NSArray *UIEyedropperComponents(UIColorValue *value) {
    if(!value)return @[];CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);CGFloat actual[4]={0};BOOL valid=[value getRGBComponents:actual inColorSpace:space error:nil];CGColorSpaceRelease(space);return valid?@[@(actual[0]),@(actual[1]),@(actual[2]),@(actual[3])]:@[];
}

// Forward-map an independently selected raw source pixel into UIImage display
// coordinates. The production reader starts from display coordinates instead.
static CGPoint UIEyedropperDisplayedPoint(NSUInteger x,NSUInteger y,NSUInteger width,NSUInteger height,UIImageOrientation orientation) {
    switch(orientation){
        case UIImageOrientationUp:return CGPointMake(x,y);
        case UIImageOrientationDown:return CGPointMake(width-1-x,height-1-y);
        case UIImageOrientationLeft:return CGPointMake(y,width-1-x);
        case UIImageOrientationRight:return CGPointMake(height-1-y,x);
        case UIImageOrientationUpMirrored:return CGPointMake(width-1-x,y);
        case UIImageOrientationDownMirrored:return CGPointMake(x,height-1-y);
        case UIImageOrientationLeftMirrored:return CGPointMake(y,x);
        case UIImageOrientationRightMirrored:return CGPointMake(height-1-y,width-1-x);
    }
    return CGPointMake(NAN,NAN);
}

#if UICOLORPANEL_ENABLE_PRIVATE_API
static BOOL UIEyedropperValidateSystemCapture(NSMutableArray *cases,UIWindow *snapshotWindow,UIEyedropperViewController *__autoreleasing *outController) {
    BOOL passed=YES;
    // A separate UIWindow is deliberately outside the application host's view
    // hierarchy. This verifies full compositor capture instead of host UIView drawing.
    UIScreen *captureScreen=UIScreen.mainScreen;CGRect markerFrame=captureScreen.bounds;UIWindow *markerWindow=[[UIWindow alloc]initWithFrame:markerFrame];
    if(@available(iOS 13.0,*)){if(snapshotWindow.windowScene)markerWindow.windowScene=snapshotWindow.windowScene;markerWindow.frame=markerFrame;}
    markerWindow.windowLevel=UIWindowLevelAlert+10;UIViewController *markerController=[UIViewController new];markerController.view.backgroundColor=UIColor.whiteColor;markerWindow.rootViewController=markerController;
    UIView *centerMarker=[[UIView alloc]initWithFrame:CGRectMake(CGRectGetMidX(markerController.view.bounds)-48,CGRectGetMidY(markerController.view.bounds)-48,96,96)];centerMarker.backgroundColor=[UIColor colorWithRed:1 green:0 blue:1 alpha:1];[markerController.view addSubview:centerMarker];
    NSMutableArray<UIView *> *cornerMarkers=[NSMutableArray new];NSMutableArray<NSDictionary *> *cornerSources=[NSMutableArray new];
    const CGFloat cornerValues[4][4]={{.22,.46,.68,1},{.70,.35,.24,1},{.32,.66,.44,1},{.62,.38,.73,1}};
    for(NSUInteger corner=0;corner<4;corner++){
        CGColorSpaceRef sourceSpace=CGColorSpaceCreateWithName(corner==1||corner==2?kCGColorSpaceDisplayP3:kCGColorSpaceSRGB);CGColorRef sourceColor=CGColorCreate(sourceSpace,cornerValues[corner]);CGColorSpaceRelease(sourceSpace);
        UIView *marker=[[UIView alloc]initWithFrame:CGRectMake(0,0,64,64)];marker.backgroundColor=[UIColor colorWithCGColor:sourceColor];CGColorRelease(sourceColor);[markerController.view addSubview:marker];[cornerMarkers addObject:marker];
        [cornerSources addObject:@{@"name":@[@"topLeft-sRGB",@"topRight-P3",@"bottomLeft-P3",@"bottomRight-sRGB"][corner],@"profile":corner==1||corner==2?@"Display P3":@"sRGB",@"sourceComponents":@[@(cornerValues[corner][0]),@(cornerValues[corner][1]),@(cornerValues[corner][2]),@1]}];
    }
    UIEyedropperViewController *systemController=nil;NSMutableArray *cornerResults=[NSMutableArray new];BOOL cornerCapture=YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIInterfaceOrientation observedOrientation=UIApplication.sharedApplication.statusBarOrientation;
#pragma clang diagnostic pop
    if(@available(iOS 13.0,*))if(snapshotWindow.windowScene)observedOrientation=snapshotWindow.windowScene.interfaceOrientation;
    NSNumber *nativeGamut=nil;SEL gamutSelector=NSSelectorFromString(@"gamut");if([captureScreen respondsToSelector:gamutSelector]){NSInteger(*getGamut)(id,SEL)=(NSInteger(*)(id,SEL))[captureScreen methodForSelector:gamutSelector];nativeGamut=@(getGamut(captureScreen,gamutSelector));}
    @try {
        markerWindow.hidden=NO;[markerWindow layoutIfNeeded];[markerController.view layoutIfNeeded];CGRect content=markerController.view.bounds;centerMarker.center=CGPointMake(CGRectGetMidX(content),CGRectGetMidY(content));
        for(NSUInteger corner=0;corner<4;corner++){BOOL right=corner==1||corner==3,bottom=corner>=2;cornerMarkers[corner].center=CGPointMake(CGRectGetMinX(content)+content.size.width*(right?.82:.18),CGRectGetMinY(content)+content.size.height*(bottom?.82:.18));}
        [CATransaction flush];
    // CA flush submits a transaction; it does not establish that the compositor
    // has presented it. Let the real run loop deliver display frames before
    // sampling. Keep the independent magenta-pixel expectation unchanged.
        NSDate *presentationDeadline=[NSDate dateWithTimeIntervalSinceNow:.15];
        while(presentationDeadline.timeIntervalSinceNow>0)[NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:MIN(.02,presentationDeadline.timeIntervalSinceNow)]];
        systemController=[[UIEyedropperViewController alloc]initWithSystemScreen:captureScreen useSPI:YES];
        UIImage *captured=[systemController valueForKey:@"sourceImage"];CGColorSpaceRef expectedSpace=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
        for(NSUInteger corner=0;corner<4;corner++){
            UIView *marker=cornerMarkers[corner];CGPoint screenPoint=[marker convertPoint:CGPointMake(CGRectGetMidX(marker.bounds),CGRectGetMidY(marker.bounds)) toCoordinateSpace:captureScreen.coordinateSpace];CGPoint pixel=CGPointMake((screenPoint.x-CGRectGetMinX(captureScreen.bounds))*captureScreen.scale,(screenPoint.y-CGRectGetMinY(captureScreen.bounds))*captureScreen.scale);
            CGColorRef expectedColor=CGColorCreateCopyByMatchingToColorSpace(expectedSpace,kCGRenderingIntentDefault,marker.backgroundColor.CGColor,NULL);const CGFloat *expected=expectedColor?CGColorGetComponents(expectedColor):NULL;
            UIEyedropperSample *sample=captured.CGImage?[UIEyedropperPixelReader sampleImage:captured atPixel:pixel]:nil;BOOL withinScreen=CGRectContainsPoint(captureScreen.bounds,screenPoint),match=withinScreen&&expected&&CGColorGetNumberOfComponents(expectedColor)==4&&UIEyedropperMatches(sample.color,expected[0],expected[1],expected[2],.02);cornerCapture&=match;
            NSMutableDictionary *entry=[cornerSources[corner]mutableCopy];entry[@"screenPoint"]=NSStringFromCGPoint(screenPoint);entry[@"withinScreen"]=@(withinScreen);entry[@"sourcePixel"]=NSStringFromCGPoint(pixel);entry[@"expectedExtendedSRGB"]=expected?@[@(expected[0]),@(expected[1]),@(expected[2]),@(expected[3])]:@[];entry[@"actualExtendedSRGB"]=UIEyedropperComponents(sample.color);entry[@"passed"]=@(match);entry[@"tolerance"]=@.02;[cornerResults addObject:entry];if(expectedColor)CGColorRelease(expectedColor);
        }
        CGColorSpaceRelease(expectedSpace);
    } @finally {markerWindow.hidden=YES;}
    UIImage *systemImage=[systemController valueForKey:@"sourceImage"];UIEyedropperSample *systemCenter=systemImage.CGImage?[UIEyedropperPixelReader sampleImage:systemImage atPixel:CGPointMake(CGImageGetWidth(systemImage.CGImage)/2,CGImageGetHeight(systemImage.CGImage)/2)]:nil;
    BOOL screenCapture=[UIEyedropperViewController supportsSystemCapture]&&systemController.samplingAvailable&&[systemController.systemCaptureDetails[@"backend"]isEqual:@"_UIRenderDisplay"]&&fabs(CGImageGetWidth(systemImage.CGImage)-UIScreen.mainScreen.bounds.size.width*UIScreen.mainScreen.scale)<1&&fabs(CGImageGetHeight(systemImage.CGImage)-UIScreen.mainScreen.bounds.size.height*UIScreen.mainScreen.scale)<1&&UIEyedropperMatches(systemCenter.color,1,0,1,.02);
    [cases addObject:@{@"name":@"private full display capture includes an independent UIWindow outside the host view tree",@"passed":@(screenCapture),@"captureDetails":systemController.systemCaptureDetails?:@{},@"centerRGBA":UIEyedropperComponents(systemCenter.color),@"error":systemController.sampleError.localizedDescription?:@"",@"errorDetails":systemController.sampleError.userInfo[@"UIEyedropperCaptureDetails"]?:@{}}];passed&=screenCapture;
    [cases addObject:@{@"name":@"private nonendpoint sRGB and P3 corner markers match independent Core Graphics conversion in the observed orientation",@"passed":@(systemController.samplingAvailable&&cornerCapture&&cornerResults.count==4),@"markers":cornerResults,@"orientation":@(observedOrientation),@"screenBounds":NSStringFromCGRect(captureScreen.bounds),@"fixedCoordinateBounds":NSStringFromCGRect(captureScreen.fixedCoordinateSpace.bounds),@"markerWindowBounds":NSStringFromCGRect(markerWindow.bounds),@"markerHostBounds":NSStringFromCGRect(markerController.view.bounds),@"publicDisplayGamut":@(captureScreen.traitCollection.displayGamut),@"nativeScreenGamut":nativeGamut?:NSNull.null,@"otherOrientationsExercised":@NO,@"scope":@"This capture checks the observed orientation and does not request rotation itself. Other directions require separate orientation-wrapper results. Expected colors use CGColorCreateCopyByMatchingToColorSpace independently of the production pixel reader."}];passed&=systemController.samplingAvailable&&cornerCapture&&cornerResults.count==4;
    if(outController)*outController=systemController;else[systemController cancel];return passed;
}

static UIInterfaceOrientation UIEyedropperObservedOrientation(UIWindow *window) {
    if(@available(iOS 13.0,*))if(window.windowScene)return window.windowScene.interfaceOrientation;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return UIApplication.sharedApplication.statusBarOrientation;
#pragma clang diagnostic pop
}

static NSDictionary *UIEyedropperOrientationState(UIWindow *window,UIViewController *host) {
    UIScreen *screen=window.screen?:UIScreen.mainScreen;NSMutableDictionary *state=[@{@"interfaceOrientation":@(UIEyedropperObservedOrientation(window)),@"deviceOrientation":@(UIDevice.currentDevice.orientation),@"generatingOrientationNotifications":@(UIDevice.currentDevice.isGeneratingDeviceOrientationNotifications),@"screenBounds":NSStringFromCGRect(screen.bounds),@"fixedCoordinateBounds":NSStringFromCGRect(screen.fixedCoordinateSpace.bounds),@"windowBounds":NSStringFromCGRect(window.bounds),@"hostBounds":NSStringFromCGRect(host.view.bounds),@"windowHidden":@(window.hidden),@"transitionActive":@(host.transitionCoordinator!=nil)}mutableCopy];
    if(@available(iOS 13.0,*))if(window.windowScene)state[@"sceneBounds"]=NSStringFromCGRect(window.windowScene.coordinateSpace.bounds);return state;
}

static void UIEyedropperAwaitOrientation(UIWindow *window,UIViewController *host,UIInterfaceOrientation requested,void (^completion)(BOOL,NSDictionary *)) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];__block NSUInteger stable=0;__block void (^poll)(void)=nil;
    poll=^{
        CGSize screen=(window.screen?:UIScreen.mainScreen).bounds.size,windowSize=window.bounds.size,hostSize=host.view.bounds.size;BOOL landscape=UIInterfaceOrientationIsLandscape(requested);
        BOOL geometry=screen.width>0&&screen.height>0&&windowSize.width>0&&windowSize.height>0&&hostSize.width>0&&hostSize.height>0&&((screen.width>screen.height)==landscape)&&((windowSize.width>windowSize.height)==landscape)&&((hostSize.width>hostSize.height)==landscape)&&fabs(windowSize.width-screen.width)<1&&fabs(windowSize.height-screen.height)<1&&fabs(hostSize.width-windowSize.width)<1&&fabs(hostSize.height-windowSize.height)<1;
        BOOL match=UIEyedropperObservedOrientation(window)==requested&&geometry&&!window.hidden&&window.rootViewController==host&&!host.transitionCoordinator;stable=match?stable+1:0;
        if(stable>=2||deadline.timeIntervalSinceNow<=0){NSDictionary *state=UIEyedropperOrientationState(window,host);BOOL reached=stable>=2;poll=nil;completion(reached,state);return;}
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.05*NSEC_PER_SEC)),dispatch_get_main_queue(),poll);
    };dispatch_async(dispatch_get_main_queue(),poll);
}

static void UIEyedropperAwaitPicker(UIWindow *window,UIViewController *host,UIEyedropperViewController *picker,BOOL presented,void (^completion)(BOOL)) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];__block NSUInteger stable=0;__block void (^poll)(void)=nil;
    poll=^{
        BOOL attached=picker.presentingViewController!=nil&&host.presentedViewController==picker&&picker.viewIfLoaded.window==window;
        CGSize size=picker.viewIfLoaded.bounds.size,windowSize=window.bounds.size;
        BOOL match=presented?(attached&&!picker.beingPresented&&!picker.beingDismissed&&!picker.transitionCoordinator&&fabs(size.width-windowSize.width)<1&&fabs(size.height-windowSize.height)<1):(!picker.presentingViewController&&host.presentedViewController!=picker&&!picker.viewIfLoaded.window);
        stable=match?stable+1:0;
        if(stable>=2||deadline.timeIntervalSinceNow<=0){BOOL reached=stable>=2;poll=nil;completion(reached);return;}
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.05*NSEC_PER_SEC)),dispatch_get_main_queue(),poll);
    };dispatch_async(dispatch_get_main_queue(),poll);
}

static void UIEyedropperAwaitCompletion(NSUInteger (^count)(void),void (^completion)(BOOL)) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];__block void (^poll)(void)=nil;
    poll=^{
        if(count()>0||deadline.timeIntervalSinceNow<=0){BOOL reached=count()>0;poll=nil;completion(reached);return;}
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.05*NSEC_PER_SEC)),dispatch_get_main_queue(),poll);
    };dispatch_async(dispatch_get_main_queue(),poll);
}

static BOOL UIEyedropperValidatePresentedCapture(NSMutableArray *cases,UIWindow *window,UIViewController *host,UIEyedropperViewController *picker,UIImage *frozenImage,NSData *frozenBytes,NSArray *markers,NSUInteger (^completionCount)(void),NSString *phase) {
    [picker.view setNeedsLayout];[picker.view layoutIfNeeded];
    UIImage *image=[picker valueForKey:@"sourceImage"];UIImageView *imageView=[picker valueForKey:@"imageView"];UIEyedropperLensView *lens=[picker valueForKey:@"lens"];CGRect content=[[picker valueForKey:@"imageContentRect"]CGRectValue];
    NSData *currentBytes=image.CGImage?CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage))):nil;
    BOOL frozen=image==frozenImage&&imageView.image==frozenImage&&image.CGImage==frozenImage.CGImage&&image.imageOrientation==UIImageOrientationUp&&frozenBytes.length>0&&[currentBytes isEqualToData:frozenBytes];
    CGFloat width=image.CGImage?CGImageGetWidth(image.CGImage):0,height=image.CGImage?CGImageGetHeight(image.CGImage):0;
    CGFloat fit=width>0&&height>0?MIN(imageView.bounds.size.width/width,imageView.bounds.size.height/height):0;
    BOOL geometry=fit>0&&content.size.width>0&&content.size.height>0&&fabs(content.size.width-width*fit)<.01&&fabs(content.size.height-height*fit)<.01&&fabs(CGRectGetMidX(content)-CGRectGetMidX(imageView.frame))<.01&&fabs(CGRectGetMidY(content)-CGRectGetMidY(imageView.frame))<.01&&CGRectContainsRect(CGRectInset(imageView.frame,-.01,-.01),content)&&CGRectContainsRect(picker.view.bounds,content);
    BOOL attached=picker.presentingViewController!=nil&&host.presentedViewController==picker&&picker.view.window==window&&!picker.beingPresented&&!picker.beingDismissed&&!picker.transitionCoordinator;
    BOOL positions=geometry&&markers.count==4;NSMutableArray *samples=[NSMutableArray new];
    if(geometry)for(NSDictionary *marker in markers){
        CGPoint source=CGPointFromString(marker[@"sourcePixel"]?:@"{nan, nan}");CGFloat x=floor(source.x),y=floor(source.y);NSArray *expected=marker[@"expectedExtendedSRGB"];
        BOOL valid=isfinite(x)&&isfinite(y)&&x>=0&&y>=0&&x+1<width&&y+1<height&&expected.count==4;
        CGPoint point=valid?CGPointMake(CGRectGetMinX(content)+(x+.5)*content.size.width/width,CGRectGetMinY(content)+(y+.5)*content.size.height/height):CGPointMake(NAN,NAN);
        [picker moveToPoint:point];CGPoint actualPixel=lens.sample?lens.sample.pixel:CGPointMake(NAN,NAN);CGPoint initialPosition=lens.lastPosition;
        BOOL touch=valid&&lens.sample&&actualPixel.x==x&&actualPixel.y==y&&fabs(initialPosition.x-point.x)<1e-6&&fabs(initialPosition.y-point.y)<1e-6&&UIEyedropperMatches(picker.selectedColor,[expected[0]doubleValue],[expected[1]doubleValue],[expected[2]doubleValue],.02);
        BOOL movedRight=[picker accessibilityMoveRight:nil];CGPoint rightPosition=lens.lastPosition,rightPixel=lens.sample?lens.sample.pixel:CGPointMake(NAN,NAN);
        BOOL right=valid&&movedRight&&rightPixel.x==x+1&&rightPixel.y==y&&fabs(rightPosition.x-initialPosition.x-content.size.width/width)<1e-6&&fabs(rightPosition.y-initialPosition.y)<1e-6&&UIEyedropperMatches(picker.selectedColor,[expected[0]doubleValue],[expected[1]doubleValue],[expected[2]doubleValue],.02);
        BOOL movedDown=[picker accessibilityMoveDown:nil];CGPoint downPosition=lens.lastPosition,downPixel=lens.sample?lens.sample.pixel:CGPointMake(NAN,NAN);
        BOOL down=valid&&movedDown&&downPixel.x==x+1&&downPixel.y==y+1&&fabs(downPosition.x-rightPosition.x)<1e-6&&fabs(downPosition.y-rightPosition.y-content.size.height/height)<1e-6&&UIEyedropperMatches(picker.selectedColor,[expected[0]doubleValue],[expected[1]doubleValue],[expected[2]doubleValue],.02);
        BOOL samplePassed=touch&&right&&down&&completionCount()==0;positions&=samplePassed;
        [samples addObject:@{@"name":marker[@"name"]?:@"",@"sourcePixel":NSStringFromCGPoint(source),@"viewPoint":NSStringFromCGPoint(point),@"touchPixel":NSStringFromCGPoint(actualPixel),@"rightPixel":NSStringFromCGPoint(rightPixel),@"downPixel":NSStringFromCGPoint(downPixel),@"rightViewDelta":NSStringFromCGPoint(CGPointMake(rightPosition.x-initialPosition.x,rightPosition.y-initialPosition.y)),@"downViewDelta":NSStringFromCGPoint(CGPointMake(downPosition.x-rightPosition.x,downPosition.y-rightPosition.y)),@"expectedExtendedSRGB":expected?:@[],@"actualExtendedSRGB":UIEyedropperComponents(picker.selectedColor),@"touchPassed":@(touch),@"rightPassed":@(right),@"downPassed":@(down),@"passed":@(samplePassed)}];
    }
    BOOL noCompletion=completionCount()==0,passed=frozen&&geometry&&attached&&positions&&noCompletion;
    [cases addObject:@{@"name":[NSString stringWithFormat:@"presented frozen system capture preserves source, touch mapping and exact AX pixel steps %@",phase],@"passed":@(passed),@"frozenSourceUnchanged":@(frozen),@"imageContentRect":NSStringFromCGRect(content),@"imageViewFrame":NSStringFromCGRect(imageView.frame),@"pickerBounds":NSStringFromCGRect(picker.view.bounds),@"windowBounds":NSStringFromCGRect(window.bounds),@"sourcePixelSize":NSStringFromCGSize(CGSizeMake(width,height)),@"sourceOrientation":@(image.imageOrientation),@"geometryPassed":@(geometry),@"presentationAttached":@(attached),@"completionCount":@(completionCount()),@"noPrematureCompletion":@(noCompletion),@"samples":samples,@"scope":@"Real modal hierarchy and interface rotation; public moveToPoint transport and accessibility action selectors, not physical gestures or VoiceOver focus/speech. Raw capture pixels and independent CGColor-converted expectations are retained across rotation."}];return passed;
}
#endif

@implementation UIEyedropperValidation
+ (NSArray<NSDictionary *> *)grabOffsetCasesInView:(UIView *)hostView {
    NSAssert(NSThread.isMainThread,@"Eyedropper validation must run on the main thread.");
    NSMutableArray<NSDictionary *> *cases=[NSMutableArray new];
    NSString *scope=@"Image-scoped picker attached as a temporary subview. Test-only UIPanGestureRecognizer supplies declared root-view location, translation and state to the production handlePan: method. No real touch injection, gesture-recognition threshold, modal presentation, system capture or VoiceOver interaction is verified.";
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL passed,NSDictionary *details){
        NSMutableDictionary *scoped=[details mutableCopy];scoped[@"scope"]=scope;[cases addObject:[@{@"name":name,@"passed":@(passed),@"details":scoped}mutableCopy]];
    };
    uint8_t pixels[16*16*4];for(NSUInteger y=0;y<16;y++)for(NSUInteger x=0;x<16;x++){NSUInteger index=(y*16+x)*4;pixels[index]=(uint8_t)(x*17);pixels[index+1]=(uint8_t)(y*17);pixels[index+2]=64;pixels[index+3]=255;}
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef provider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:pixels length:sizeof(pixels)]);
    CGImageRef cg=CGImageCreate(16,16,8,32,16*4,space,kCGImageAlphaLast,provider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(provider);CGColorSpaceRelease(space);
    UIEyedropperViewController *picker=[[UIEyedropperViewController alloc]initWithImage:cg?[UIImage imageWithCGImage:cg]:[UIImage new]];if(cg)CGImageRelease(cg);
    __block NSUInteger completions=0;__block UIColorValue *returnedColor=nil;picker.completionHandler=^(UIColorValue *color){completions++;returnedColor=color;};
    @try {
        picker.view.frame=hostView.bounds;[hostView addSubview:picker.view];[picker.view setNeedsLayout];[picker.view layoutIfNeeded];
        CGRect content=[[picker valueForKey:@"imageContentRect"]CGRectValue];UIEyedropperLensView *lens=[picker valueForKey:@"lens"];
        CGPoint initial=CGPointMake(CGRectGetMidX(content),CGRectGetMidY(content));[picker moveToPoint:initial];
        BOOL geometry=hostView!=nil&&picker.view.superview==hostView&&picker.samplingAvailable&&content.size.width>220&&content.size.height>220&&lens.sample!=nil;
        if(!geometry)record(@"eyedropper grab fixture has sufficient attached image geometry",NO,@{@"imageContentRect":NSStringFromCGRect(content),@"pickerBounds":NSStringFromCGRect(picker.view.bounds),@"samplingAvailable":@(picker.samplingAvailable)});
        else {
            UIEyedropperPanFixture *pan=[[UIEyedropperPanFixture alloc]initWithTarget:nil action:NULL];
            BOOL (^atPosition)(CGPoint)=^BOOL(CGPoint expected){return lens.sample&&fabs(lens.lastPosition.x-expected.x)<1e-6&&fabs(lens.lastPosition.y-expected.y)<1e-6&&fabs(lens.center.x-expected.x)<1e-6&&fabs(lens.center.y-expected.y)<1e-6;};
            CGPoint grab=CGPointMake(35,-24),start=CGPointMake(initial.x+grab.x,initial.y+grab.y),delta=CGPointMake(8,7);
            BOOL inside=[lens pointInside:[lens convertPoint:start fromView:picker.view] withEvent:nil];
            pan.fixtureState=UIGestureRecognizerStateBegan;pan.fixtureLocation=CGPointMake(start.x+delta.x,start.y+delta.y);pan.fixtureTranslation=delta;[picker handlePan:pan];
            CGPoint beganPosition=lens.lastPosition;BOOL began=atPosition(CGPointMake(initial.x+delta.x,initial.y+delta.y));
            delta=CGPointMake(23,17);pan.fixtureState=UIGestureRecognizerStateChanged;pan.fixtureLocation=CGPointMake(start.x+delta.x,start.y+delta.y);pan.fixtureTranslation=delta;[picker handlePan:pan];
            CGPoint changedPosition=lens.lastPosition,expected=CGPointMake(initial.x+delta.x,initial.y+delta.y);
            record(@"eyedropper off-center lens grab preserves center plus pan displacement",inside&&began&&atPosition(expected)&&completions==0,@{@"initialCenter":NSStringFromCGPoint(initial),@"grabOffset":NSStringFromCGPoint(grab),@"beganTranslation":NSStringFromCGPoint(CGPointMake(8,7)),@"beganCenter":NSStringFromCGPoint(beganPosition),@"changedTranslation":NSStringFromCGPoint(delta),@"expectedCenter":NSStringFromCGPoint(expected),@"actualCenter":NSStringFromCGPoint(changedPosition),@"selectedRGBA":UIEyedropperComponents(picker.selectedColor)});

            delta=CGPointMake(28,21);pan.fixtureState=UIGestureRecognizerStateEnded;pan.fixtureLocation=CGPointMake(start.x+delta.x,start.y+delta.y);pan.fixtureTranslation=delta;[picker handlePan:pan];
            expected=CGPointMake(initial.x+delta.x,initial.y+delta.y);CGPoint endedOffset=[[picker valueForKey:@"panGrabOffset"]CGPointValue];
            record(@"eyedropper pan ending retains the chosen position without committing",atPosition(expected)&&CGPointEqualToPoint(endedOffset,CGPointZero)&&completions==0&&![[picker valueForKey:@"finished"]boolValue],@{@"expectedCenter":NSStringFromCGPoint(expected),@"actualCenter":NSStringFromCGPoint(lens.lastPosition),@"remainingGrabOffset":NSStringFromCGPoint(endedOffset),@"completionCount":@(completions),@"selectedRGBA":UIEyedropperComponents(picker.selectedColor)});

            [picker moveToPoint:initial];CGPoint directStart=CGPointMake(CGRectGetMinX(content)+content.size.width*.1,CGRectGetMinY(content)+content.size.height*.1),directDelta=CGPointMake(-5,6),direct=CGPointMake(directStart.x+directDelta.x,directStart.y+directDelta.y);
            BOOL outside=![lens pointInside:[lens convertPoint:directStart fromView:picker.view] withEvent:nil];
            pan.fixtureState=UIGestureRecognizerStateBegan;pan.fixtureLocation=direct;pan.fixtureTranslation=directDelta;[picker handlePan:pan];BOOL directBegan=atPosition(direct);
            pan.fixtureState=UIGestureRecognizerStateEnded;[picker handlePan:pan];
            record(@"eyedropper image drag outside the lens positions the sample directly",outside&&directBegan&&atPosition(direct)&&completions==0,@{@"touchDown":NSStringFromCGPoint(directStart),@"expectedCenter":NSStringFromCGPoint(direct),@"actualCenter":NSStringFromCGPoint(lens.lastPosition),@"selectedRGBA":UIEyedropperComponents(picker.selectedColor)});

            for(NSNumber *terminal in @[@(UIGestureRecognizerStateCancelled),@(UIGestureRecognizerStateFailed)]){
                [picker moveToPoint:initial];pan.fixtureState=UIGestureRecognizerStateBegan;pan.fixtureTranslation=CGPointMake(8,7);pan.fixtureLocation=CGPointMake(start.x+8,start.y+7);[picker handlePan:pan];
                CGPoint held=lens.lastPosition,seededOffset=[[picker valueForKey:@"panGrabOffset"]CGPointValue];BOOL seeded=fabs(seededOffset.x-grab.x)<1e-6&&fabs(seededOffset.y-grab.y)<1e-6;
                pan.fixtureState=(UIGestureRecognizerState)terminal.integerValue;[picker handlePan:pan];CGPoint clearedOffset=[[picker valueForKey:@"panGrabOffset"]CGPointValue];BOOL cleared=CGPointEqualToPoint(clearedOffset,CGPointZero)&&atPosition(held);
                pan.fixtureState=UIGestureRecognizerStateBegan;pan.fixtureLocation=direct;pan.fixtureTranslation=directDelta;[picker handlePan:pan];BOOL restarted=atPosition(direct);
                pan.fixtureState=UIGestureRecognizerStateEnded;[picker handlePan:pan];
                BOOL failed=terminal.integerValue==UIGestureRecognizerStateFailed;
                record(failed?@"eyedropper supplied Failed state clears a prior offset before a new drag":@"eyedropper cancelled drag clears its offset before a new drag",seeded&&cleared&&restarted&&atPosition(direct)&&completions==0,@{@"terminalState":terminal,@"seededGrabOffset":NSStringFromCGPoint(seededOffset),@"remainingGrabOffset":NSStringFromCGPoint(clearedOffset),@"expectedRestartCenter":NSStringFromCGPoint(direct),@"actualRestartCenter":NSStringFromCGPoint(lens.lastPosition),@"completionCount":@(completions),@"stateSequenceScope":failed?@"Forced terminal-branch input after seeding an offset; this does not claim UIKit permits Began to Failed in a real pan sequence.":@"Declared Began, Cancelled, new Began and Ended handler inputs; no physical gesture dispatch."});
            }
        }
    } @finally {[picker cancel];[picker.view removeFromSuperview];}
    BOOL cleanup=picker.view.superview==nil&&completions==1&&returnedColor==nil;
    for(NSMutableDictionary *entry in cases){NSMutableDictionary *details=entry[@"details"];details[@"cleanup"]=@{@"temporaryViewRemoved":@(picker.view.superview==nil),@"completionCountAfterCancel":@(completions),@"cancelReturnedNil":@(returnedColor==nil)};entry[@"passed"]=@([entry[@"passed"]boolValue]&&cleanup);}
    return cases;
}

+ (void)runOrientationWithOutputURL:(NSURL *)url {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self runOrientationWithOutputURL:url];});return;}
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
#if UICOLORPANEL_ENABLE_PRIVATE_API
    NSString *argument=[NSUserDefaults.standardUserDefaults stringForKey:@"UIEyedropperInterfaceOrientation"]?:@"";UIInterfaceOrientation requested=UIInterfaceOrientationUnknown;
    if([argument isEqualToString:@"landscape-left"])requested=UIInterfaceOrientationLandscapeLeft;else if([argument isEqualToString:@"landscape-right"])requested=UIInterfaceOrientationLandscapeRight;
    BOOL shouldCommit=[argument isEqualToString:@"landscape-left"];
    UIWindow *window=UIApplication.sharedApplication.keyWindow;UIViewController *host=window.rootViewController;UIDevice *device=UIDevice.currentDevice;UIInterfaceOrientation original=window?UIEyedropperObservedOrientation(window):UIInterfaceOrientationUnknown;UIDeviceOrientation originalDevice=device.orientation;BOOL wasGenerating=device.isGeneratingDeviceOrientationNotifications;
    NSMutableArray *cases=[NSMutableArray new];NSMutableDictionary *result=[@{@"privateBuild":@YES,@"supported":@YES,@"passed":@NO,@"requested":argument,@"requestedInterfaceOrientation":@(requested),@"otherOrientationsExercised":@NO,@"cases":cases,@"scope":@"Actual UIKit interface rotation and one private screen capture, followed by the same presented frozen picker rotating back to its original interface. Public movement transport and AX action selectors, not physical gestures, VoiceOver speech, Mac desktop input or permanent settings."}mutableCopy];
    result[@"endingAction"]=shouldCommit?@"commit":@"cancel";
    if(window&&host)result[@"originalState"]=UIEyedropperOrientationState(window,host);
    UIInterfaceOrientationMask supported=window?[UIApplication.sharedApplication supportedInterfaceOrientationsForWindow:window]:0;
    BOOL originalConflict=UIDeviceOrientationIsValidInterfaceOrientation(originalDevice)&&(UIInterfaceOrientation)originalDevice!=original;
    if(!window||!host||window.hidden||host.presentedViewController||requested==UIInterfaceOrientationUnknown||requested==original||!(supported&(1UL<<requested))||original==UIInterfaceOrientationUnknown||originalConflict){
        result[@"supported"]=@NO;result[@"error"]=@"A visible rotation-capable host without another modal, a different supported requested direction and a restorable original interface/device state are required.";result[@"caseCount"]=@0;result[@"restorationPassed"]=@YES;
        [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES];return;
    }
    if(!wasGenerating)[device beginGeneratingDeviceOrientationNotifications];
    __block UIEyedropperViewController *picker=nil;__block UIImage *frozenImage=nil;__block NSData *frozenBytes=nil;__block NSArray *markers=nil;
    __block UIColorValue *expectedEndingColor=nil,*returnedColor=nil;
    __block NSUInteger completions=0,cancellations=0;__block BOOL pickerOpened=NO,restoring=NO;
    void (^publishFinal)(BOOL)=^(BOOL restored){
        if(wasGenerating&&!UIDeviceOrientationIsValidInterfaceOrientation(originalDevice)){
            @try{[device setValue:@(originalDevice) forKey:@"orientation"];}
            @catch(NSException *exception){result[@"restoreDeviceError"]=exception.reason?:exception.name;}
        }
        if(!wasGenerating)[device endGeneratingDeviceOrientationNotifications];
        // Allow the lens's existing 250ms dismissal animation to finish too;
        // neither its completion nor UIKit disappearance may finish twice.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.3*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            BOOL dismissed=!picker||(!picker.presentingViewController&&host.presentedViewController!=picker&&!picker.viewIfLoaded.window);
            if(picker){
                [picker cancel];[picker commit];BOOL movementRejected=![picker accessibilityMoveRight:nil];UIEyedropperLensView *lens=[picker valueForKey:@"lens"];BOOL lensFinished=lens.lensState==2;
                NSArray *independentExpected=markers.lastObject[@"expectedExtendedSRGB"];BOOL exactCanonical=returnedColor&&[returnedColor isEqual:expectedEndingColor];
                BOOL expectedColor=shouldCommit?(exactCanonical&&independentExpected.count==4&&UIEyedropperMatches(returnedColor,[independentExpected[0]doubleValue],[independentExpected[1]doubleValue],[independentExpected[2]doubleValue],.02)):(returnedColor==nil);
                BOOL exactlyOnce=[result[@"endingCompletionReached"]boolValue]&&completions==1&&cancellations==(shouldCommit?0:1)&&expectedColor&&movementRejected&&lensFinished&&dismissed;
                [cases addObject:@{@"name":[NSString stringWithFormat:@"presented frozen picker %@s exactly once after repeated commit/cancel, disappearance and lens-animation completion",shouldCommit?@"commit":@"cancel"],@"passed":@(exactlyOnce),@"endingAction":result[@"endingAction"],@"completionCount":@(completions),@"cancelCompletionCount":@(cancellations),@"commitCompletionCount":@(completions-cancellations),@"exactCanonicalColorPreserved":@(exactCanonical),@"independentExpectedExtendedSRGB":independentExpected?:@[],@"selectedBeforeEndingExtendedSRGB":UIEyedropperComponents(expectedEndingColor),@"returnedExtendedSRGB":UIEyedropperComponents(returnedColor),@"postFinishMovementRejected":@(movementRejected),@"lensDismissalFinished":@(lensFinished),@"ownedPickerDismissed":@(dismissed)}];result[@"pickerFinalizationPassed"]=@(exactlyOnce);
            }
            NSDictionary *finalState=UIEyedropperOrientationState(window,host);BOOL notificationsRestored=device.isGeneratingDeviceOrientationNotifications==wasGenerating,deviceRestored=device.orientation==originalDevice;
            BOOL restoration=restored&&UIEyedropperObservedOrientation(window)==original&&notificationsRestored&&deviceRestored&&dismissed;
            BOOL allCases=YES;for(NSDictionary *entry in cases)allCases&=[entry[@"passed"]boolValue];
            result[@"restoredState"]=finalState;result[@"restorationPassed"]=@(restoration);result[@"orientationNotificationsRestored"]=@(notificationsRestored);result[@"deviceOrientationRestored"]=@(deviceRestored);result[@"ownedPickerDismissed"]=@(dismissed);result[@"caseCount"]=@(cases.count);result[@"passed"]=@([result[@"orientationReached"]boolValue]&&[result[@"capturePassed"]boolValue]&&[result[@"pickerBeforePassed"]boolValue]&&[result[@"pickerAfterPassed"]boolValue]&&[result[@"pickerFinalizationPassed"]boolValue]&&allCases&&restoration);
            [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES];
        });
    };
    void (^dismissOwnedPicker)(BOOL)=^(BOOL restored){
        if(picker.presentingViewController&&host.presentedViewController==picker){
            // Dismiss only the controller this probe created; never a foreign modal.
            [host dismissViewControllerAnimated:NO completion:nil];
            UIEyedropperAwaitPicker(window,host,picker,NO,^(BOOL dismissed){if(!dismissed)result[@"dismissError"]=@"Owned picker did not detach before the deadline.";publishFinal(restored&&dismissed);});
        }else if(!picker.presentingViewController&&!picker.viewIfLoaded.window)publishFinal(restored);
        else{result[@"dismissError"]=@"Picker presentation ownership changed; no unrelated controller was dismissed.";publishFinal(NO);}
    };
    void (^closeOwnedPicker)(BOOL)=^(BOOL restored){
        if(!picker){publishFinal(restored);return;}
        expectedEndingColor=[picker.selectedColor copy];
        if(shouldCommit){[picker commit];[picker commit];}else{[picker cancel];[picker cancel];[picker commit];}
        UIEyedropperAwaitCompletion(^NSUInteger(void){return completions;},^(BOOL completed){
            result[@"endingCompletionReached"]=@(completed);if(!completed)result[@"endingError"]=@"Picker did not deliver its expected ending completion before the deadline.";
            [picker cancel];[picker commit];dismissOwnedPicker(restored);
        });
    };
    void (^restore)(void)=^{
        if(restoring)return;restoring=YES;
        // The same owned picker stays presented during this actual rotation.
        // UIKit aliases opposite named landscape device/interface enum values.
        @try{[device setValue:@((UIDeviceOrientation)original) forKey:@"orientation"];[UIViewController attemptRotationToDeviceOrientation];}
        @catch(NSException *exception){result[@"restoreError"]=exception.reason?:exception.name;}
        UIEyedropperAwaitOrientation(window,host,original,^(BOOL restored,NSDictionary *state){
            result[@"restoredWhilePickerOpenState"]=state;
            if(!pickerOpened){closeOwnedPicker(restored);return;}
            UIEyedropperAwaitPicker(window,host,picker,YES,^(BOOL attached){
                result[@"pickerRotatedToOriginal"]=@(restored&&attached);BOOL after=NO;
                @try{after=UIEyedropperValidatePresentedCapture(cases,window,host,picker,frozenImage,frozenBytes,markers,^NSUInteger(void){return completions;},@"after rotation back to the original interface");}
                @catch(NSException *exception){result[@"pickerAfterError"]=exception.reason?:exception.name;}
                result[@"pickerAfterPassed"]=@(after&&restored&&attached);closeOwnedPicker(restored);
            });
        });
    };
    @try{[device setValue:@((UIDeviceOrientation)requested) forKey:@"orientation"];[UIViewController attemptRotationToDeviceOrientation];}
    @catch(NSException *exception){result[@"error"]=exception.reason?:exception.name;restore();return;}
    UIEyedropperAwaitOrientation(window,host,requested,^(BOOL reached,NSDictionary *state){
        result[@"rotatedState"]=state;result[@"orientationReached"]=@(reached);
        if(!reached){result[@"capturePassed"]=@NO;result[@"error"]=@"UIKit did not reach the requested real interface orientation and stable screen/window/host geometry before the deadline.";restore();return;}
        // The real system rotation snapshot may outlast transitionCoordinator.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.4*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            @try{
                UIEyedropperViewController *capturedController=nil;result[@"capturePassed"]=@(UIEyedropperValidateSystemCapture(cases,window,&capturedController));picker=capturedController;
                frozenImage=[picker valueForKey:@"sourceImage"];frozenBytes=frozenImage.CGImage?CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(frozenImage.CGImage))):nil;markers=[cases.lastObject[@"markers"]copy];
                picker.completionHandler=^(UIColorValue *color){completions++;returnedColor=color;if(!color)cancellations++;};
                if(!picker.samplingAvailable||!frozenBytes.length||markers.count!=4){result[@"pickerBeforeError"]=@"The single captured source and its four independent marker expectations are required.";restore();return;}
                [host presentViewController:picker animated:NO completion:nil];
            }@catch(NSException *exception){result[@"captureError"]=exception.reason?:exception.name;result[@"capturePassed"]=@NO;restore();return;}
            UIEyedropperAwaitPicker(window,host,picker,YES,^(BOOL attached){
                pickerOpened=attached;BOOL before=NO;
                @try{before=UIEyedropperValidatePresentedCapture(cases,window,host,picker,frozenImage,frozenBytes,markers,^NSUInteger(void){return completions;},@"before rotating the open picker");}
                @catch(NSException *exception){result[@"pickerBeforeError"]=exception.reason?:exception.name;}
                result[@"pickerBeforePassed"]=@(before&&attached);if(!attached)result[@"presentationError"]=@"Owned picker did not reach a stable real modal hierarchy before the deadline.";restore();
            });
        });
    });
#else
    NSDictionary *result=@{@"privateBuild":@NO,@"supported":@NO,@"passed":@NO,@"caseCount":@0,@"cases":@[],@"error":@"Orientation capture validation requires a private-enabled test build."};
    [[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:url atomically:YES];
#endif
}

+ (BOOL)runWithOutputURL:(NSURL *)url {
    NSMutableArray *cases=[NSMutableArray new];BOOL passed=YES;
    UIEyedropperRGB a=UIEyedropperColorMake(-1,.5,1.25),b=UIEyedropperColorMake(2,1,.75),sum=UIEyedropperColorCombineColors(a,b),division=UIEyedropperColorDivide(sum,2);
    BOOL math=UIEyedropperColorEqualToColor(sum,UIEyedropperColorMake(1,1.5,2))&&UIEyedropperColorEqualToColor(division,UIEyedropperColorMake(.5,.75,1))&&!UIEyedropperColorApproxEqualToColor(a,a,0)&&UIEyedropperColorApproxEqualToColor(a,a,.001)&&fabs(UIEyedropperColorDistanceToColor(UIEyedropperColorMake(0,0,0),UIEyedropperColorMake(1,2,2))-3)<1e-12;
    [cases addObject:@{@"name":@"recovered RGB aggregate arithmetic and strict tolerance",@"passed":@(math)}];passed&=math;

    uint8_t bytes[3*16]={0};for(NSUInteger y=0;y<3;y++)for(NSUInteger x=0;x<3;x++){bytes[y*16+x*4]=(uint8_t)(20+y*50);bytes[y*16+x*4+1]=(uint8_t)(30+x*40);bytes[y*16+x*4+2]=(uint8_t)(10+x*30+y*20);bytes[y*16+x*4+3]=7;}
    NSData *data=[NSData dataWithBytes:bytes length:sizeof(bytes)];BOOL raw8=YES;for(NSUInteger y=0;y<3;y++)for(NSUInteger x=0;x<3;x++){UIColorValue *value=[UIEyedropperPixelReader colorAtX:x y:y inData:data width:3 height:3 bytesPerRow:16 pixelFormat:UIEyedropperPixelFormatBGRA8];raw8&=UIEyedropperMatches(value,(10+x*30+y*20)/255.,(30+x*40)/255.,(20+y*50)/255.,1e-6);}
    [cases addObject:@{@"name":@"BGRA8 center offsets, padded row stride and original opaque output",@"passed":@(raw8),@"samples":@9}];passed&=raw8;

    BOOL raw10=YES;for(NSUInteger i=0;i<4;i++){uint32_t channels[4]={0,384,894,1023};uint32_t red=channels[i],green=channels[(i+1)%4],blue=channels[(i+2)%4],packed=(red<<20)|(green<<10)|blue;UIColorValue *value=[UIEyedropperPixelReader colorAtX:0 y:0 inData:[NSData dataWithBytes:&packed length:4] width:1 height:1 bytesPerRow:4 pixelFormat:UIEyedropperPixelFormatW30R];raw10&=UIEyedropperMatches(value,(float)((float)red-384)/510.f,(float)((float)green-384)/510.f,(float)((float)blue-384)/510.f,1e-6);}
    [cases addObject:@{@"name":@"packed w30r black/white and extended negative/greater-than-one components",@"passed":@(raw10),@"samples":@4}];passed&=raw10;

    BOOL invalid=[UIEyedropperPixelReader colorAtX:3 y:0 inData:data width:3 height:3 bytesPerRow:16 pixelFormat:UIEyedropperPixelFormatBGRA8]==nil&&[UIEyedropperPixelReader colorAtX:0 y:0 inData:data width:3 height:3 bytesPerRow:8 pixelFormat:UIEyedropperPixelFormatBGRA8]==nil&&[UIEyedropperPixelReader colorAtX:0 y:0 inData:data width:NSUIntegerMax height:3 bytesPerRow:16 pixelFormat:UIEyedropperPixelFormatBGRA8]==nil&&[UIEyedropperPixelReader colorAtX:0 y:0 inData:[NSData data] width:3 height:3 bytesPerRow:16 pixelFormat:UIEyedropperPixelFormatBGRA8]==nil&&[UIEyedropperPixelReader colorAtX:0 y:0 inData:data width:3 height:3 bytesPerRow:16 pixelFormat:(UIEyedropperPixelFormat)0]==nil;
    [cases addObject:@{@"name":@"public buffer adapter rejects truncated/overflow/unsupported input",@"passed":@(invalid)}];passed&=invalid;

    uint8_t rgba[16]={255,0,0,255,0,255,0,255,0,0,255,255,255,255,255,255};CGColorSpaceRef rgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef provider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:rgba length:16]);CGImageRef cg=CGImageCreate(2,2,8,32,8,rgb,kCGImageAlphaLast,provider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(provider);CGColorSpaceRelease(rgb);
    UIImage *image=cg?[UIImage imageWithCGImage:cg scale:1 orientation:UIImageOrientationUp]:[UIImage new],*down=cg?[UIImage imageWithCGImage:cg scale:1 orientation:UIImageOrientationDown]:[UIImage new];if(cg)CGImageRelease(cg);
    UIEyedropperSample *redSample=[UIEyedropperPixelReader sampleImage:image atPixel:CGPointZero],*greenSample=[UIEyedropperPixelReader sampleImage:image atPixel:CGPointMake(1,0)],*whiteSample=[UIEyedropperPixelReader sampleImage:down atPixel:CGPointZero];
    UIEyedropperSample *unrotatedWhite=[UIEyedropperPixelReader sampleImage:image atPixel:CGPointMake(1,1)];
    CGImageRef croppedWhite=CGImageCreateWithImageInRect(image.CGImage,CGRectMake(1,1,1,1));UIEyedropperSample *cropSample=croppedWhite?[UIEyedropperPixelReader sampleImage:[UIImage imageWithCGImage:croppedWhite] atPixel:CGPointZero]:nil;if(croppedWhite)CGImageRelease(croppedWhite);
    CFDataRef originalBytes=CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));const uint8_t *originalBuffer=originalBytes?CFDataGetBytePtr(originalBytes):NULL;NSArray *lastSourcePixel=originalBytes&&CFDataGetLength(originalBytes)>=16?@[@(originalBuffer[12]),@(originalBuffer[13]),@(originalBuffer[14]),@(originalBuffer[15])]:@[];if(originalBytes)CFRelease(originalBytes);
    CGColorSpaceRef premulSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef premulProvider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:rgba length:16]);CGImageRef premulImage=CGImageCreate(2,2,8,32,8,premulSpace,kCGImageAlphaPremultipliedLast,premulProvider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(premulProvider);CGColorSpaceRelease(premulSpace);UIEyedropperSample *premulWhite=premulImage?[UIEyedropperPixelReader sampleImage:[UIImage imageWithCGImage:premulImage scale:1 orientation:UIImageOrientationDown] atPixel:CGPointZero]:nil;if(premulImage)CGImageRelease(premulImage);
    BOOL imagePixels=UIEyedropperMatches(redSample.color,1,0,0,1e-5)&&UIEyedropperMatches(greenSample.color,0,1,0,1e-5)&&UIEyedropperMatches(whiteSample.color,1,1,1,1e-5)&&CGImageGetWidth(redSample.magnifiedPixels.CGImage)==9&&CGImageGetHeight(redSample.magnifiedPixels.CGImage)==9;
    [cases addObject:@{@"name":@"bounded9x9 image source, center mapping and UIImage orientation",@"passed":@(imagePixels),@"red":UIEyedropperComponents(redSample.color),@"green":UIEyedropperComponents(greenSample.color),@"downWhite":UIEyedropperComponents(whiteSample.color),@"unrotatedWhite":UIEyedropperComponents(unrotatedWhite.color),@"croppedWhite":UIEyedropperComponents(cropSample.color),@"premultipliedDownWhite":UIEyedropperComponents(premulWhite.color),@"lastSourcePixelRGBA":lastSourcePixel,@"sourceAlphaInfo":@(CGImageGetAlphaInfo(image.CGImage)),@"patchWidth":@(redSample.magnifiedPixels.CGImage?CGImageGetWidth(redSample.magnifiedPixels.CGImage):0),@"patchHeight":@(redSample.magnifiedPixels.CGImage?CGImageGetHeight(redSample.magnifiedPixels.CGImage):0)}];passed&=imagePixels;
    UIEyedropperSample *clamped=[UIEyedropperPixelReader sampleImage:image atPixel:CGPointMake(-10,500)];BOOL bounds=UIEyedropperMatches(clamped.color,0,0,1,1e-5)&&CGPointEqualToPoint(clamped.pixel,CGPointMake(0,1))&&[UIEyedropperPixelReader sampleImage:image atPixel:CGPointMake(NAN,0)]==nil;
    [cases addObject:@{@"name":@"image source finite coordinates and explicit edge clamping",@"passed":@(bounds)}];passed&=bounds;

    // Independent expected displayed color IDs for a non-square2x3 image:
    // R G / B Y / M C. Rows below enumerate each oriented image, not the reader's transform.
    const uint8_t rectangle[24]={255,0,0,255,0,255,0,255,0,0,255,255,255,255,0,255,255,0,255,255,0,255,255,255};
    const double colors[6][3]={{1,0,0},{0,1,0},{0,0,1},{1,1,0},{1,0,1},{0,1,1}};
    const NSUInteger expected[8][6]={{0,1,2,3,4,5},{5,4,3,2,1,0},{1,3,5,0,2,4},{4,2,0,5,3,1},{1,0,3,2,5,4},{4,5,2,3,0,1},{0,2,4,1,3,5},{5,3,1,4,2,0}};
    CGColorSpaceRef rectangleSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef rectangleProvider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:rectangle length:sizeof(rectangle)]);CGImageRef rectangleImage=CGImageCreate(2,3,8,32,8,rectangleSpace,kCGImageAlphaLast,rectangleProvider,NULL,NO,kCGRenderingIntentDefault);CGColorSpaceRelease(rectangleSpace);CGDataProviderRelease(rectangleProvider);
    BOOL allOrientations=rectangleImage!=NULL;NSUInteger checkedPixels=0;NSMutableArray *orientationFailures=[NSMutableArray new];
    if(rectangleImage)for(NSUInteger scale=1;scale<=3;scale++)for(NSUInteger orientation=0;orientation<8;orientation++){
        UIImage *oriented=[UIImage imageWithCGImage:rectangleImage scale:scale orientation:(UIImageOrientation)orientation];NSUInteger displayedWidth=(orientation==2||orientation==3||orientation==6||orientation==7)?3:2,displayedHeight=displayedWidth==3?2:3;
        BOOL dimensions=fabs(oriented.size.width*oriented.scale-displayedWidth)<1e-10&&fabs(oriented.size.height*oriented.scale-displayedHeight)<1e-10;allOrientations&=dimensions;
        for(NSUInteger y=0;y<displayedHeight;y++)for(NSUInteger x=0;x<displayedWidth;x++){
            NSUInteger colorID=expected[orientation][y*displayedWidth+x];UIEyedropperSample *sample=[UIEyedropperPixelReader sampleImage:oriented atPixel:CGPointMake(x,y)];BOOL correct=dimensions&&UIEyedropperMatches(sample.color,colors[colorID][0],colors[colorID][1],colors[colorID][2],1e-5);allOrientations&=correct;checkedPixels++;
            if(!correct)[orientationFailures addObject:@{@"orientation":@(orientation),@"scale":@(scale),@"x":@(x),@"y":@(y),@"expectedColorID":@(colorID),@"actual":UIEyedropperComponents(sample.color),@"logicalSize":NSStringFromCGSize(oriented.size)}];
        }
    }
    if(rectangleImage)CGImageRelease(rectangleImage);
    [cases addObject:@{@"name":@"non-square eight UIImage orientations at scale1/2/3",@"passed":@(allOrientations),@"checkedPixels":@(checkedPixels),@"failures":orientationFailures}];passed&=allOrientations;

    BOOL patchNeighborhood=YES;NSMutableArray *patchFailures=[NSMutableArray new];
    for(NSUInteger orientation=0;orientation<8;orientation++){
        CGColorSpaceRef patchSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef patchProvider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:rectangle length:sizeof(rectangle)]);CGImageRef patchSource=CGImageCreate(2,3,8,32,8,patchSpace,kCGImageAlphaLast,patchProvider,NULL,NO,kCGRenderingIntentDefault);CGColorSpaceRelease(patchSpace);CGDataProviderRelease(patchProvider);
        if(!patchSource){patchNeighborhood=NO;continue;}UIImage *oriented=[UIImage imageWithCGImage:patchSource scale:1 orientation:(UIImageOrientation)orientation];CGImageRelease(patchSource);UIEyedropperSample *patch=[UIEyedropperPixelReader sampleImage:oriented atPixel:CGPointZero];NSUInteger displayedWidth=(orientation==2||orientation==3||orientation==6||orientation==7)?3:2,displayedHeight=displayedWidth==3?2:3;
        for(NSUInteger y=0;y<displayedHeight;y++)for(NSUInteger x=0;x<displayedWidth;x++){NSUInteger colorID=expected[orientation][y*displayedWidth+x];UIEyedropperSample *cell=[UIEyedropperPixelReader sampleImage:patch.magnifiedPixels atPixel:CGPointMake(4+x,4+y)];BOOL correct=UIEyedropperMatches(cell.color,colors[colorID][0],colors[colorID][1],colors[colorID][2],1e-5);patchNeighborhood&=correct;if(!correct)[patchFailures addObject:@{@"orientation":@(orientation),@"x":@(x),@"y":@(y),@"actual":UIEyedropperComponents(cell.color)}];}
    }
    [cases addObject:@{@"name":@"9x9 magnification neighborhood matches oriented source pixels",@"passed":@(patchNeighborhood),@"checkedPixels":@48,@"failures":patchFailures}];passed&=patchNeighborhood;

    const NSUInteger dimensions[6][2]={{3,2},{3,3},{4,3},{5,2},{11,13},{13,11}};BOOL terminalPixels=YES;NSUInteger terminalSamples=0,terminalFailureCount=0;NSMutableArray *terminalFailures=[NSMutableArray new],*sourceDiagnostics=[NSMutableArray new];
    for(NSUInteger fixture=0;fixture<6;fixture++){
        NSUInteger sourceWidth=dimensions[fixture][0],sourceHeight=dimensions[fixture][1],sourceStride=sourceWidth*4+12;NSMutableData *sourceBytes=[NSMutableData dataWithLength:sourceStride*sourceHeight];uint8_t *sourceBuffer=sourceBytes.mutableBytes;
        memset(sourceBuffer,0xee,sourceBytes.length);
        for(NSUInteger y=0;y<sourceHeight;y++)for(NSUInteger x=0;x<sourceWidth;x++){NSUInteger index=y*sourceWidth+x;uint8_t *p=sourceBuffer+y*sourceStride+x*4;p[0]=(index&1)?255:0;p[1]=(index&2)?255:0;p[2]=(index&4)?255:0;p[3]=255;}
        CGColorSpaceRef fixtureSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef fixtureProvider=CGDataProviderCreateWithCFData((__bridge CFDataRef)sourceBytes);CGImageRef fixtureImage=CGImageCreate(sourceWidth,sourceHeight,8,32,sourceStride,fixtureSpace,kCGImageAlphaLast,fixtureProvider,NULL,NO,kCGRenderingIntentDefault);CGColorSpaceRelease(fixtureSpace);CGDataProviderRelease(fixtureProvider);
        if(!fixtureImage){terminalPixels=NO;terminalFailureCount++;[terminalFailures addObject:@{@"width":@(sourceWidth),@"height":@(sourceHeight),@"error":@"CGImage creation failed"}];continue;}
        CFDataRef copiedProvider=CGDataProviderCopyData(CGImageGetDataProvider(fixtureImage));const uint8_t *copiedBytes=copiedProvider?CFDataGetBytePtr(copiedProvider):NULL;BOOL providerMatches=copiedProvider&&CFDataGetLength(copiedProvider)==(CFIndex)sourceBytes.length&&CGImageGetBytesPerRow(fixtureImage)==sourceStride;
        NSMutableArray *lastTwoPixels=[NSMutableArray new];
        if(providerMatches)for(NSUInteger x=sourceWidth-2;x<sourceWidth;x++){NSUInteger offset=(sourceHeight-1)*sourceStride+x*4;const uint8_t *p=copiedBytes+offset;providerMatches&=memcmp(p,sourceBuffer+offset,4)==0;[lastTwoPixels addObject:@[@(p[0]),@(p[1]),@(p[2]),@(p[3])]];}
        [sourceDiagnostics addObject:@{@"width":@(CGImageGetWidth(fixtureImage)),@"height":@(CGImageGetHeight(fixtureImage)),@"bytesPerRow":@(CGImageGetBytesPerRow(fixtureImage)),@"providerLength":@(copiedProvider?CFDataGetLength(copiedProvider):0),@"alphaInfo":@(CGImageGetAlphaInfo(fixtureImage)),@"providerMatches":@(providerMatches),@"lastTwoPixelsRGBA":lastTwoPixels}];terminalPixels&=providerMatches;if(copiedProvider)CFRelease(copiedProvider);
        for(NSUInteger scale=1;scale<=3;scale++)for(NSUInteger orientation=0;orientation<8;orientation++){
            UIImage *oriented=[UIImage imageWithCGImage:fixtureImage scale:scale orientation:(UIImageOrientation)orientation];
            for(NSUInteger y=0;y<sourceHeight;y++)for(NSUInteger x=0;x<sourceWidth;x++){
                // Small images exhaust every pixel. Large images target the last
                // two pixels of the last row, forcing a clipped9x9 source ROI.
                if(fixture>=4&&(y!=sourceHeight-1||x<sourceWidth-2))continue;
                NSUInteger sourceIndex=y*sourceWidth+x;CGPoint displayed=UIEyedropperDisplayedPoint(x,y,sourceWidth,sourceHeight,(UIImageOrientation)orientation);UIEyedropperSample *sample=[UIEyedropperPixelReader sampleImage:oriented atPixel:displayed];double r=(sourceIndex&1)?1:0,g=(sourceIndex&2)?1:0,b=(sourceIndex&4)?1:0;BOOL correct=UIEyedropperMatches(sample.color,r,g,b,1e-5)&&CGPointEqualToPoint(sample.pixel,displayed);terminalPixels&=correct;terminalSamples++;
                if(!correct){terminalFailureCount++;if(terminalFailures.count<64)[terminalFailures addObject:@{@"width":@(sourceWidth),@"height":@(sourceHeight),@"orientation":@(orientation),@"scale":@(scale),@"rawX":@(x),@"rawY":@(y),@"displayX":@(displayed.x),@"displayY":@(displayed.y),@"expectedRGBA":@[@(r),@(g),@(b),@1],@"actualRGBA":UIEyedropperComponents(sample.color)}];}
            }
        }
        CGImageRelease(fixtureImage);
    }
    [cases addObject:@{@"name":@"different source dimensions and padded rows retain final two pixels in every orientation",@"passed":@(terminalPixels),@"checkedPixels":@(terminalSamples),@"failureCount":@(terminalFailureCount),@"failures":terminalFailures,@"sources":sourceDiagnostics}];passed&=terminalPixels;

    const float halfRed[4]={.5f,0,0,.5f};CGColorSpaceRef alphaSpace=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);CGDataProviderRef alphaProvider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:halfRed length:sizeof(halfRed)]);CGImageRef alphaImage=CGImageCreate(1,1,32,128,sizeof(halfRed),alphaSpace,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast,alphaProvider,NULL,NO,kCGRenderingIntentDefault);CGColorSpaceRelease(alphaSpace);CGDataProviderRelease(alphaProvider);UIEyedropperSample *opaque=alphaImage?[UIEyedropperPixelReader sampleImage:[UIImage imageWithCGImage:alphaImage] atPixel:CGPointZero]:nil;if(alphaImage)CGImageRelease(alphaImage);BOOL alpha=UIEyedropperMatches(opaque.color,1,.5,.5,1e-5);
    [cases addObject:@{@"name":@"half-transparent source red visually composites on white with opaque output",@"passed":@(alpha),@"expectedRGBA":@[@1,@0.5,@0.5,@1],@"actualRGBA":UIEyedropperComponents(opaque.color)}];passed&=alpha;

    UIImage *animated=[UIImage animatedImageWithImages:@[image,image] duration:1];UIEyedropperViewController *frozenController=[[UIEyedropperViewController alloc]initWithImage:animated];UIImage *frozen=[frozenController valueForKey:@"sourceImage"];BOOL firstFrame=frozenController.samplingAvailable&&frozen.images.count==0&&frozen.CGImage==image.CGImage&&frozen.scale==image.scale&&frozen.imageOrientation==image.imageOrientation;
    [cases addObject:@{@"name":@"animated UIImage freezes its first CGImage without resampling",@"passed":@(firstFrame)}];passed&=firstFrame;

    uint8_t p3Pixel[4]={255,0,0,255};CGColorSpaceRef p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);CGDataProviderRef p3Provider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:p3Pixel length:4]);CGImageRef p3Image=CGImageCreate(1,1,8,32,4,p3,kCGImageAlphaLast,p3Provider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(p3Provider);CGColorSpaceRelease(p3);
    UIEyedropperSample *extended=p3Image?[UIEyedropperPixelReader sampleImage:[UIImage imageWithCGImage:p3Image] atPixel:CGPointZero]:nil;if(p3Image)CGImageRelease(p3Image);
    CGFloat extendedRGB[4]={0};CGColorSpaceRef extendedSpace=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);BOOL profile=extended&&[extended.color getRGBComponents:extendedRGB inColorSpace:extendedSpace error:nil]&&extendedRGB[0]>1&&extendedRGB[1]<0;CGColorSpaceRelease(extendedSpace);
    [cases addObject:@{@"name":@"public float image adapter retains out-of-sRGB profile-converted components",@"passed":@(profile),@"components":@[@(extendedRGB[0]),@(extendedRGB[1]),@(extendedRGB[2])]}];passed&=profile;

    UIView *container=[[UIView alloc]initWithFrame:CGRectMake(0,0,400,400)];UIEyedropperLensView *lens=[[UIEyedropperLensView alloc]initWithFrame:CGRectMake(56,56,288,288)];lens.lastPosition=CGPointMake(200,200);[container addSubview:lens];[lens setNeedsLayout];[lens layoutIfNeeded];BOOL geometry=[lens _lensPosition]==0;CGPoint origins[8]={{-1,56},{113,56},{56,-1},{56,113},{-1,-1},{113,-1},{-1,113},{113,113}};for(NSUInteger i=0;i<8;i++){lens.frame=CGRectMake(origins[i].x,origins[i].y,288,288);geometry&=[lens _lensPosition]==(NSInteger)i+1;}geometry&=UIEyedropperEDLensPositionIsCorner(5)&&UIEyedropperEDLensPositionIsCorner(8)&&!UIEyedropperEDLensPositionIsCorner(4)&&!UIEyedropperEDLensPositionIsCorner(9)&&UIEyedropperEDLensPositionIsEdge(1)&&UIEyedropperEDLensPositionIsEdge(8)&&!UIEyedropperEDLensPositionIsEdge(0);
    [cases addObject:@{@"name":@"recovered lens edge/corner classification across all nine positions",@"passed":@(geometry)}];passed&=geometry;

    UIWindow *snapshotWindow=UIApplication.sharedApplication.keyWindow;UIView *snapshotSource=[[UIView alloc]initWithFrame:CGRectMake(20,20,24,24)];snapshotSource.backgroundColor=UIColor.redColor;[snapshotWindow addSubview:snapshotSource];UIEyedropperViewController *snapshotController=[[UIEyedropperViewController alloc]initWithSourceView:snapshotSource];snapshotSource.backgroundColor=UIColor.blueColor;[snapshotSource removeFromSuperview];snapshotController.view.frame=CGRectMake(0,0,320,600);[snapshotController.view setNeedsLayout];[snapshotController.view layoutIfNeeded];CGRect sourceRect=[[snapshotController valueForKey:@"imageContentRect"]CGRectValue];[snapshotController moveToPoint:CGPointMake(CGRectGetMidX(sourceRect),CGRectGetMidY(sourceRect))];BOOL appSnapshot=snapshotWindow!=nil&&snapshotController.samplingAvailable&&UIEyedropperMatches(snapshotController.selectedColor,1,0,0,1e-3);[cases addObject:@{@"name":@"attached application view freezes before source changes and detaches",@"passed":@(appSnapshot),@"actualRGBA":UIEyedropperComponents(snapshotController.selectedColor),@"scope":@"Public drawViewHierarchy of an app-owned attached view; no system display capture."}];passed&=appSnapshot;[snapshotController cancel];

    UIEyedropperViewController *invalidController=[[UIEyedropperViewController alloc]initWithSourceView:[UIView new]];__block NSUInteger cancels=0;invalidController.completionHandler=^(UIColorValue *color){if(!color)cancels++;};BOOL unavailable=!invalidController.samplingAvailable&&invalidController.sampleError!=nil&&invalidController.selectedColor==nil&&!invalidController.use_spi&&invalidController.systemCaptureDetails.count==0;[invalidController cancel];[invalidController cancel];unavailable&=cancels==1;
    [cases addObject:@{@"name":@"missing public source reports error, retains public semantics and cancels exactly once",@"passed":@(unavailable)}];passed&=unavailable;

    UIEyedropperViewController *disabledSystem=[[UIEyedropperViewController alloc]initWithSystemScreen:UIScreen.mainScreen useSPI:NO];BOOL runtimeGate=!disabledSystem.samplingAvailable&&disabledSystem.sampleError!=nil&&disabledSystem.systemCaptureDetails.count==0&&!disabledSystem.use_spi;
#if !UICOLORPANEL_ENABLE_PRIVATE_API
    runtimeGate&=![UIEyedropperViewController supportsSystemCapture];UIEyedropperViewController *compiledOut=[[UIEyedropperViewController alloc]initWithSystemScreen:UIScreen.mainScreen useSPI:YES];runtimeGate&=!compiledOut.samplingAvailable&&compiledOut.sampleError!=nil&&compiledOut.systemCaptureDetails.count==0;[compiledOut cancel];
#endif
    [disabledSystem cancel];[cases addObject:@{@"name":@"system screen provider rejects runtime disabling and compile-disabled capture",@"passed":@(runtimeGate),@"privateBuild":@(UICOLORPANEL_ENABLE_PRIVATE_API)}];passed&=runtimeGate;

#if UICOLORPANEL_ENABLE_PRIVATE_API
    passed&=UIEyedropperValidateSystemCapture(cases,snapshotWindow,NULL);
#endif

    uint8_t tallBytes[4*16*4];for(NSUInteger pixel=0;pixel<4*16;pixel++){tallBytes[pixel*4]=64;tallBytes[pixel*4+1]=128;tallBytes[pixel*4+2]=192;tallBytes[pixel*4+3]=255;}
    CGColorSpaceRef tallSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGDataProviderRef tallProvider=CGDataProviderCreateWithCFData((__bridge CFDataRef)[NSData dataWithBytes:tallBytes length:sizeof(tallBytes)]);CGImageRef tallCG=CGImageCreate(4,16,8,32,16,tallSpace,kCGImageAlphaLast,tallProvider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(tallProvider);CGColorSpaceRelease(tallSpace);
    UIEyedropperViewController *edgeController=[[UIEyedropperViewController alloc]initWithImage:tallCG?[UIImage imageWithCGImage:tallCG]:[UIImage new]];if(tallCG)CGImageRelease(tallCG);edgeController.view.frame=CGRectMake(0,0,414,896);[edgeController.view setNeedsLayout];[edgeController.view layoutIfNeeded];
    UIButton *cancelButton=[edgeController valueForKey:@"cancelButton"],*commitButton=[edgeController valueForKey:@"commitButton"];CGRect contentRect=[[edgeController valueForKey:@"imageContentRect"]CGRectValue];BOOL edgeActions=edgeController.samplingAvailable;NSMutableArray *edgeResults=[NSMutableArray new];
    CGPoint edgePoints[5]={{CGRectGetMinX(contentRect),CGRectGetMinY(contentRect)},{CGRectGetMaxX(contentRect),CGRectGetMinY(contentRect)},{CGRectGetMinX(contentRect),CGRectGetMaxY(contentRect)},{CGRectGetMaxX(contentRect),CGRectGetMaxY(contentRect)},{CGRectGetMidX(contentRect),CGRectGetMaxY(contentRect)}};
    for(NSUInteger position=0;position<5;position++){
        [edgeController moveToPoint:edgePoints[position]];UIView *cancelHit=[edgeController.view hitTest:cancelButton.center withEvent:nil],*commitHit=[edgeController.view hitTest:commitButton.center withEvent:nil];BOOL cancelReachable=cancelHit==cancelButton||[cancelHit isDescendantOfView:cancelButton],commitReachable=commitHit==commitButton||[commitHit isDescendantOfView:commitButton];edgeActions&=cancelReachable&&commitReachable&&commitButton.enabled;
        [edgeResults addObject:@{@"point":NSStringFromCGPoint(edgePoints[position]),@"cancelHit":NSStringFromClass(cancelHit.class)?:@"nil",@"commitHit":NSStringFromClass(commitHit.class)?:@"nil",@"cancelReachable":@(cancelReachable),@"commitReachable":@(commitReachable)}];
    }
    [cases addObject:@{@"name":@"native action buttons remain hittable above the lens at all image corners and bottom edge",@"passed":@(edgeActions),@"positions":edgeResults,@"imageContentRect":NSStringFromCGRect(contentRect),@"cancelFrame":NSStringFromCGRect(cancelButton.frame),@"commitFrame":NSStringFromCGRect(commitButton.frame),@"scope":@"Actual UIKit hitTest hierarchy, not a synthesized physical tap or VoiceOver focus check."}];passed&=edgeActions;[edgeController cancel];

    UIEyedropperViewController *controller=[[UIEyedropperViewController alloc]initWithImage:image];controller.view.frame=CGRectMake(0,0,414,600);[controller.view setNeedsLayout];[controller.view layoutIfNeeded];__block NSUInteger commits=0;__block UIColorValue *committed=nil;controller.completionHandler=^(UIColorValue *color){commits++;committed=color;};[controller moveToPoint:CGPointMake(207,300)];BOOL session=controller.samplingAvailable&&controller.selectedColor!=nil;[controller commit];[controller cancel];[controller commit];session&=commits==1&&committed!=nil;
    [cases addObject:@{@"name":@"public move/commit/cancel session returns one canonical selected color",@"passed":@(session)}];passed&=session;

    UIEyedropperViewController *accessible=[[UIEyedropperViewController alloc]initWithImage:image];accessible.view.frame=CGRectMake(0,0,414,600);[accessible.view setNeedsLayout];[accessible.view layoutIfNeeded];[accessible moveToPoint:CGPointMake(207,300)];__block NSUInteger escapes=0;accessible.completionHandler=^(UIColorValue *color){if(!color)escapes++;};BOOL accessibility=[accessible accessibilityMoveLeft:nil]&&[accessible accessibilityMoveRight:nil]&&[accessible accessibilityMoveUp:nil]&&[accessible accessibilityMoveDown:nil]&&[accessible accessibilityPerformEscape]&&![accessible accessibilityPerformEscape]&&escapes==1;
    [cases addObject:@{@"name":@"non-gesture pixel movement and accessibility escape cancellation",@"passed":@(accessibility)}];passed&=accessibility;

    NSDictionary *result=@{@"passed":@(passed),@"caseCount":@(cases.count),@"cases":cases,@"privateBuild":@(UICOLORPANEL_ENABLE_PRIVATE_API),@"scope":@"Finite recovered RGB/pixel/lens checks, public snapshot lifecycle and optional private full-display provider. The private fixture uses a distinct UIWindow. No native-system differential, global input, physical gesture, arbitrary cross-process or secure-content bypass claim."};NSData *output=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];return[output writeToURL:url options:NSDataWritingAtomic error:nil]&&passed;
}
@end
