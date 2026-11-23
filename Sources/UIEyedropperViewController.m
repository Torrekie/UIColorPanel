#import "UIEyedropperViewController.h"
#import "UIEyedropperLensView.h"
#import "UIColorPanelAppearance.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#if UICOLORPANEL_ENABLE_PRIVATE_API
#import <CoreImage/CoreImage.h>
#import <TargetConditionals.h>
#import <dlfcn.h>
#import <string.h>
#import <objc/runtime.h>
typedef IOSurfaceRef (*UIEyedropperRenderDisplayImport)(NSDictionary *,IOSurfaceRef (^)(CGSize,NSDictionary *));
typedef IOSurfaceRef (*UIEyedropperBufferCreateImport)(NSDictionary *,CGSize);
@interface CALayer (UIEyedropperCaptureExclusion)
- (void)setDisableUpdateMask:(uint32_t)mask;
@end
#endif

@interface UIEyedropperViewController () <UIEyedropperLensViewDelegate,UIGestureRecognizerDelegate> {
    CGPoint _panGrabOffset;
}
@property(nonatomic,strong) UIImage *sourceImage;
@property(nonatomic,strong) UIImageView *imageView;
@property(nonatomic,strong) UIEyedropperLensView *lens;
@property(nonatomic,strong) UILabel *scopeLabel,*instructionLabel;
@property(nonatomic,strong) UIButton *cancelButton,*commitButton;
@property(nonatomic,strong,readwrite) UIColorValue *selectedColor;
@property(nonatomic,strong,readwrite) NSError *sampleError;
@property(nonatomic,copy,readwrite) NSString *sourceKind;
@property(nonatomic,readwrite) BOOL samplingAvailable;
@property(nonatomic) BOOL finished;
@property(nonatomic) CGRect imageContentRect;
@property(nonatomic,strong) UIColorValue *pendingColor;
@property(nonatomic,copy,readwrite) NSDictionary *systemCaptureDetails;
@property(nonatomic,readwrite) BOOL liveSystemSampling;
@property(nonatomic,strong) UIScreen *systemScreen;
@property(nonatomic,strong) UIWindow *liveWindow;
@property(nonatomic,weak) UIWindow *previousKeyWindow;
@property(nonatomic,strong) CADisplayLink *liveDisplayLink;
- (UIImage *)captureSystemImageInRect:(CGRect)rect orientation:(UIInterfaceOrientation)orientation;
@end

@implementation UIEyedropperViewController
@synthesize use_spi=_use_spi;
// BINMAP-ADAPT: UIEyedropperViewController.initWithSourceView: — explicit public application-owned snapshot; taken before overlay presentation.
- (instancetype)initWithSourceView:(UIView *)sourceView {
    NSAssert(NSThread.isMainThread,@"Eyedropper UI must run on the main thread.");
    UIImage *snapshot=nil;
    if(sourceView.window&&sourceView.bounds.size.width>0&&sourceView.bounds.size.height>0){
        UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat defaultFormat];format.scale=sourceView.window.screen.scale;format.opaque=YES;format.preferredRange=UIGraphicsImageRendererFormatRangeExtended;
        UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithBounds:sourceView.bounds format:format];__block BOOL drew=NO;
        snapshot=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){[UIColor.whiteColor setFill];UIRectFill(sourceView.bounds);drew=[sourceView drawViewHierarchyInRect:sourceView.bounds afterScreenUpdates:YES];}];
        if(!drew)snapshot=nil;
    }
    self=[self initWithImage:snapshot?:[UIImage new]];
    if(self){self.sourceKind=@"Application Snapshot";if(!snapshot)self.sampleError=[NSError errorWithDomain:@"UIColorPanelKit.Eyedropper" code:1 userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"This snapshot cannot be sampled."]}];}
    return self;
}
// BINMAP-ADAPT: UIEyedropperViewController.initWithImage: — retain an immutable explicit source image, never a display-service handle.
- (instancetype)initWithImage:(UIImage *)image {
    NSAssert(NSThread.isMainThread,@"Eyedropper UI must run on the main thread.");
    if((self=[super initWithNibName:nil bundle:nil])){
        UIImage *firstFrame=image.images.firstObject?:image;CGImageRef pixels=firstFrame.CGImage;
        _sourceImage=pixels?[UIImage imageWithCGImage:pixels scale:firstFrame.scale orientation:firstFrame.imageOrientation]:firstFrame;
        _sourceKind=@"Image Snapshot";_use_spi=NO;_systemCaptureDetails=@{};_samplingAvailable=_sourceImage.CGImage&&_sourceImage.size.width>0&&_sourceImage.size.height>0;
        if(!_samplingAvailable)_sampleError=[NSError errorWithDomain:@"UIColorPanelKit.Eyedropper" code:1 userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"This snapshot cannot be sampled."]}];
        self.modalPresentationStyle=UIModalPresentationOverFullScreen;
    }return self;
}
// BINMAP-ADAPT: UIEyedropperViewController.supportsSystemCapture — physical render-server authorization and runtime ABI preflight.
+ (BOOL)supportsSystemCapture {
#if UICOLORPANEL_ENABLE_PRIVATE_API
#if !TARGET_OS_SIMULATOR
    // The device render server restricts capture to the client's PID without this
    // signed entitlement. Process signing state is stable across panel layouts.
    static BOOL authorizedForDisplay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFTypeRef (*createSelf)(CFAllocatorRef)=dlsym(RTLD_DEFAULT,"SecTaskCreateFromSelf");
        CFTypeRef (*copyValue)(CFTypeRef,CFStringRef,CFErrorRef *)=dlsym(RTLD_DEFAULT,"SecTaskCopyValueForEntitlement");
        if(!createSelf||!copyValue)return;
        CFTypeRef task=createSelf(kCFAllocatorDefault);
        if(!task)return;
        CFTypeRef value=copyValue(task,CFSTR("com.apple.QuartzCore.global-capture"),NULL);
        if(value){
            if(CFGetTypeID(value)==CFBooleanGetTypeID()){
                authorizedForDisplay=CFBooleanGetValue((CFBooleanRef)value);
            }else if(CFGetTypeID(value)==CFNumberGetTypeID()){
                int number=0;
                authorizedForDisplay=CFNumberGetValue((CFNumberRef)value,kCFNumberIntType,&number)&&number!=0;
            }
            CFRelease(value);
        }
        CFRelease(task);
    });
    if(!authorizedForDisplay)return NO;
#endif
    Method exclusion=class_getInstanceMethod(CALayer.class,@selector(setDisableUpdateMask:));
    const char *exclusionEncoding=exclusion?method_getTypeEncoding(exclusion):NULL;
    NSMethodSignature *exclusionSignature=exclusionEncoding?[NSMethodSignature signatureWithObjCTypes:exclusionEncoding]:nil;
    const char *exclusionResult=exclusionSignature.methodReturnType,*mask=exclusionSignature.numberOfArguments==3?[exclusionSignature getArgumentTypeAtIndex:2]:NULL;
    while(exclusionResult&&*exclusionResult&&strchr("rnNoORV",*exclusionResult))exclusionResult++;
    while(mask&&*mask&&strchr("rnNoORV",*mask))mask++;
    if(exclusionSignature.numberOfArguments!=3||!exclusionResult||strcmp(exclusionResult,@encode(void))!=0||!mask||strcmp(mask,@encode(uint32_t))!=0)return NO;
    if(!dlsym(RTLD_DEFAULT,"_UIRenderDisplay")||!dlsym(RTLD_DEFAULT,"_UIRenderingBufferCreate"))return NO;
    const char *keys[]={"kUIRenderingSourceScreen","kUIRenderingDestinationGamut","kUIRenderingDestinationOpaque","kUIRenderingDestinationScale","kUIRenderingSourceOrientation","kUIRenderingEnforceSecureMode","kUIRenderingSourceRect"};
    NSMutableSet<NSString *> *optionKeys=[NSMutableSet setWithCapacity:7];
    for(NSUInteger index=0;index<7;index++){
        const CFStringRef *address=dlsym(RTLD_DEFAULT,keys[index]);CFStringRef value=address?*address:NULL;
        if(!value||CFGetTypeID(value)!=CFStringGetTypeID()||CFStringGetLength(value)==0)return NO;
        [optionKeys addObject:(__bridge NSString *)value];
    }
    if(optionKeys.count!=7)return NO;
    const char *serverImports[]={"CARenderServerBufferGetTypeID","CARenderServerGetBufferWidth","CARenderServerGetBufferHeight","CARenderServerGetBufferRowBytes","CARenderServerGetBufferDataSize","CARenderServerGetBufferData"};
    BOOL hasServerConversion=YES;
    for(NSUInteger index=0;index<6;index++)if(!dlsym(RTLD_DEFAULT,serverImports[index]))hasServerConversion=NO;
    BOOL hasSurfaceType=dlsym(RTLD_DEFAULT,"IOSurfaceGetTypeID")!=NULL;
    Method initializer=class_getInstanceMethod(CIImage.class,@selector(initWithIOSurface:options:));
    const char *encoding=initializer?method_getTypeEncoding(initializer):NULL;
    NSMethodSignature *signature=encoding?[NSMethodSignature signatureWithObjCTypes:encoding]:nil;
    const char *result=signature.methodReturnType,*surface=signature.numberOfArguments==4?[signature getArgumentTypeAtIndex:2]:NULL,*options=signature.numberOfArguments==4?[signature getArgumentTypeAtIndex:3]:NULL;
    while(result&&*result&&strchr("rnNoORV",*result))result++;
    while(surface&&*surface&&strchr("rnNoORV",*surface))surface++;
    while(options&&*options&&strchr("rnNoORV",*options))options++;
    BOOL hasSurfaceInitializer=signature.numberOfArguments==4&&result&&strcmp(result,@encode(id))==0&&surface&&strcmp(surface,@encode(IOSurfaceRef))==0&&options&&strcmp(options,@encode(id))==0;
    const char *surfaceImports[]={"IOSurfaceGetWidth","IOSurfaceGetHeight","IOSurfaceGetBytesPerRow","IOSurfaceGetBaseAddress","IOSurfaceGetPixelFormat","IOSurfaceLock","IOSurfaceUnlock"};
    BOOL hasRawSurfaceConversion=YES;
    for(NSUInteger index=0;index<7;index++)if(!dlsym(RTLD_DEFAULT,surfaceImports[index]))hasRawSurfaceConversion=NO;
    return hasServerConversion||(hasSurfaceType&&(hasSurfaceInitializer||hasRawSurfaceConversion));
#else
    return NO;
#endif
}
// BINMAP-ADAPT: UIEyedropperViewController.initWithSystemScreen:useSPI: — live provider of EDLensView._displayLinkFired0x4825; no frozen substitution.
- (instancetype)initWithSystemScreen:(UIScreen *)screen useSPI:(BOOL)useSPI {
    NSAssert(NSThread.isMainThread,@"Eyedropper UI must run on the main thread.");
    if((self=[super initWithNibName:nil bundle:nil])){
        _systemScreen=screen;_liveSystemSampling=YES;_use_spi=useSPI;_sourceKind=@"Screen color sampling";
        _samplingAvailable=useSPI&&[self.class supportsSystemCapture];
        _systemCaptureDetails=@{@"liveSystemSampling":@YES,@"runtimeEnabled":@(useSPI)};
        if(!_samplingAvailable)_sampleError=[NSError errorWithDomain:@"UIColorPanelKit.Eyedropper" code:3 userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"Color sampling is unavailable."]}];
    }return self;
}
// BINMAP-ADAPT: UIEyedropperViewController.captureSystemImageInRect:orientation: — original0x4825 seven-key capture and bounded transport; source rect is in fixed screen coordinates.
- (UIImage *)captureSystemImageInRect:(CGRect)rect orientation:(UIInterfaceOrientation)orientation {
    UIImage *snapshot=nil;NSDictionary *details=nil;NSMutableDictionary *diagnostics=[NSMutableDictionary new];
#if UICOLORPANEL_ENABLE_PRIVATE_API
    UIScreen *screen=self.systemScreen;
    if(self.use_spi&&self.samplingAvailable&&screen){
        UIEyedropperRenderDisplayImport renderDisplay=(UIEyedropperRenderDisplayImport)dlsym(RTLD_DEFAULT,"_UIRenderDisplay");
        UIEyedropperBufferCreateImport bufferCreate=(UIEyedropperBufferCreateImport)dlsym(RTLD_DEFAULT,"_UIRenderingBufferCreate");
        const char *names[]={"kUIRenderingSourceScreen","kUIRenderingDestinationGamut","kUIRenderingDestinationOpaque","kUIRenderingDestinationScale","kUIRenderingSourceOrientation","kUIRenderingEnforceSecureMode","kUIRenderingSourceRect"};
        NSMutableDictionary *options=[NSMutableDictionary dictionaryWithCapacity:7];
        diagnostics[@"sourceOrientation"]=@(orientation);diagnostics[@"sourceRect"]=NSStringFromCGRect(rect);diagnostics[@"fixedCoordinateBounds"]=NSStringFromCGRect(screen.fixedCoordinateSpace.bounds);
        NSArray *values=@[screen,@(screen.traitCollection.displayGamut),@YES,@(screen.scale),@(orientation),@NO,[NSValue valueWithCGRect:rect]];
        for(NSUInteger index=0;index<7;index++){
            const CFStringRef *key=dlsym(RTLD_DEFAULT,names[index]);CFStringRef value=key?*key:NULL;
            if(value&&CFGetTypeID(value)==CFStringGetTypeID()&&CFStringGetLength(value)>0)options[(__bridge NSString *)value]=values[index];
        }
        if(renderDisplay&&bufferCreate&&options.count==7){
            diagnostics[@"optionCount"]=@(options.count);
            // BINMAP-BLOCK-ADAPT: original=Eyedropper invoke_ea=0x4cec parent_ea=0x4825; preserve dictionary/CGSize imported-call ABI.
            IOSurfaceRef surface=renderDisplay(options,^IOSurfaceRef(CGSize size,NSDictionary *attributes){diagnostics[@"allocatorRequestedSize"]=NSStringFromCGSize(size);return bufferCreate(attributes,size);});
            diagnostics[@"surfaceReturned"]=@(surface!=NULL);
            if(surface){
                CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
                CGImageRef pixels=NULL;NSString *conversion=@"CoreImage IOSurface initializer";
                CFTypeID(*getServerBufferType)(void)=dlsym(RTLD_DEFAULT,"CARenderServerBufferGetTypeID");CFTypeID(*getSurfaceType)(void)=dlsym(RTLD_DEFAULT,"IOSurfaceGetTypeID");CFTypeID actualType=CFGetTypeID(surface);
                BOOL isServerBuffer=getServerBufferType&&actualType==getServerBufferType(),isSurface=getSurfaceType&&actualType==getSurfaceType();diagnostics[@"bufferTypeID"]=@(actualType);diagnostics[@"isCARenderServerBuffer"]=@(isServerBuffer);diagnostics[@"isIOSurface"]=@(isSurface);
                if(isServerBuffer){
                    // BINMAP-ADAPT: iOS12 QuartzCore native capture buffer,
                    // not an IOSurface. IDA9.5 confirms format1=BGRA8888,
                    // its fixed4-byte source layout and these native getters.
                    size_t(*getWidth)(CFTypeRef)=dlsym(RTLD_DEFAULT,"CARenderServerGetBufferWidth"),(*getHeight)(CFTypeRef)=dlsym(RTLD_DEFAULT,"CARenderServerGetBufferHeight"),(*getStride)(CFTypeRef)=dlsym(RTLD_DEFAULT,"CARenderServerGetBufferRowBytes"),(*getSize)(CFTypeRef)=dlsym(RTLD_DEFAULT,"CARenderServerGetBufferDataSize");const uint8_t *(*getData)(CFTypeRef)=dlsym(RTLD_DEFAULT,"CARenderServerGetBufferData");
                    BOOL importsAvailable=getWidth&&getHeight&&getStride&&getSize&&getData;diagnostics[@"serverBufferImportsAvailable"]=@(importsAvailable);
                    if(importsAvailable){
                        size_t width=getWidth(surface),height=getHeight(surface),stride=getStride(surface),dataSize=getSize(surface);const uint8_t *source=getData(surface);diagnostics[@"serverBufferWidth"]=@(width);diagnostics[@"serverBufferHeight"]=@(height);diagnostics[@"serverBufferStride"]=@(stride);diagnostics[@"serverBufferDataSize"]=@(dataSize);diagnostics[@"serverBufferHasData"]=@(source!=NULL);diagnostics[@"nativeSourceFormat"]=@"BGRA8888";
                        if(source&&width&&height&&width<=NSUIntegerMax/(4*sizeof(float))&&height<=NSUIntegerMax/(width*4*sizeof(float))&&stride>=width*4&&height<=NSUIntegerMax/stride&&dataSize>=height*stride){
                            NSMutableData *floating=[NSMutableData dataWithLength:width*height*4*sizeof(float)];float *destination=floating.mutableBytes;
                            for(size_t y=0;y<height;y++)for(size_t x=0;x<width;x++){const uint8_t *input=source+y*stride+x*4;float *output=destination+(y*width+x)*4;output[0]=input[2]/255.f;output[1]=input[1]/255.f;output[2]=input[0]/255.f;output[3]=1;}
                            CGDataProviderRef provider=CGDataProviderCreateWithCFData((__bridge CFDataRef)floating);pixels=CGImageCreate(width,height,32,128,width*4*sizeof(float),space,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast,provider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(provider);conversion=@"CARenderServerBuffer native BGRA8888 to float32";
                        }
                    }
                }
                // iOS12 does not implement +imageWithIOSurface: even though the
                // newer SDK declares it for older OS versions. Check the actual
                // designated initializer instead of trusting SDK availability.
                Method initializer=class_getInstanceMethod(CIImage.class,@selector(initWithIOSurface:options:));
                const char *encoding=initializer?method_getTypeEncoding(initializer):NULL;
                NSMethodSignature *signature=encoding?[NSMethodSignature signatureWithObjCTypes:encoding]:nil;
                const char *result=signature.methodReturnType,*surfaceType=signature.numberOfArguments==4?[signature getArgumentTypeAtIndex:2]:NULL,*optionsType=signature.numberOfArguments==4?[signature getArgumentTypeAtIndex:3]:NULL;
                while(result&&*result&&strchr("rnNoORV",*result))result++;
                while(surfaceType&&*surfaceType&&strchr("rnNoORV",*surfaceType))surfaceType++;
                while(optionsType&&*optionsType&&strchr("rnNoORV",*optionsType))optionsType++;
                BOOL hasSurfaceInitializer=signature.numberOfArguments==4&&result&&strcmp(result,@encode(id))==0&&surfaceType&&strcmp(surfaceType,@encode(IOSurfaceRef))==0&&optionsType&&strcmp(optionsType,@encode(id))==0;
                diagnostics[@"coreImageSurfaceInitializerAvailable"]=@(hasSurfaceInitializer);if(encoding)diagnostics[@"coreImageSurfaceInitializerEncoding"]=@(encoding);
                if(!pixels&&isSurface&&hasSurfaceInitializer){
                    CIImage *image=[[CIImage alloc]initWithIOSurface:surface options:nil];
                    CIContext *context=[CIContext contextWithOptions:@{kCIContextWorkingColorSpace:(__bridge id)space,kCIContextOutputColorSpace:(__bridge id)space,kCIContextUseSoftwareRenderer:@YES}];
                    if(image)pixels=[context createCGImage:image fromRect:image.extent format:kCIFormatRGBAh colorSpace:space];
                }
                diagnostics[@"coreImageConverted"]=@(isSurface&&pixels!=NULL);
                if(!pixels&&isSurface){
                    // BINMAP-ADAPT: older-runtime surface transport. The source
                    // formats/arithmetic are the original analyzer0x7648; use a
                    // floating CGImage so w30r values outside0...1 survive.
                    const char *surfaceImports[]={"IOSurfaceGetWidth","IOSurfaceGetHeight","IOSurfaceGetBytesPerRow","IOSurfaceGetBaseAddress","IOSurfaceGetPixelFormat","IOSurfaceLock","IOSurfaceUnlock"};NSMutableDictionary *globalSymbols=[NSMutableDictionary new];
                    for(NSUInteger index=0;index<7;index++){BOOL found=dlsym(RTLD_DEFAULT,surfaceImports[index])!=NULL;globalSymbols[@(surfaceImports[index])]=@(found);}diagnostics[@"globalSurfaceSymbols"]=globalSymbols;
                    void *surfaceLibrary=RTLD_DEFAULT;
                    size_t(*getWidth)(IOSurfaceRef)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceGetWidth"):NULL,(*getHeight)(IOSurfaceRef)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceGetHeight"):NULL,(*getStride)(IOSurfaceRef)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceGetBytesPerRow"):NULL;
                    void *(*getBase)(IOSurfaceRef)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceGetBaseAddress"):NULL;uint32_t(*getFormat)(IOSurfaceRef)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceGetPixelFormat"):NULL;
                    int32_t(*lock)(IOSurfaceRef,uint32_t,uint32_t *)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceLock"):NULL,(*unlock)(IOSurfaceRef,uint32_t,uint32_t *)=surfaceLibrary?dlsym(surfaceLibrary,"IOSurfaceUnlock"):NULL;
                    BOOL importsAvailable=getWidth&&getHeight&&getStride&&getBase&&getFormat&&lock&&unlock;diagnostics[@"surfaceImportsAvailable"]=@(importsAvailable);int32_t lockResult=importsAvailable?lock(surface,1,NULL):-1;diagnostics[@"surfaceLockResult"]=@(lockResult);
                    if(importsAvailable&&lockResult==0){
                        size_t width=getWidth(surface),height=getHeight(surface),stride=getStride(surface);uint32_t format=getFormat(surface);const uint8_t *source=getBase(surface);
                        diagnostics[@"surfaceWidth"]=@(width);diagnostics[@"surfaceHeight"]=@(height);diagnostics[@"surfaceStride"]=@(stride);diagnostics[@"surfacePixelFormat"]=@(format);diagnostics[@"surfaceHasBaseAddress"]=@(source!=NULL);
                        if(source&&width&&height&&width<=NSUIntegerMax/(4*sizeof(float))&&height<=NSUIntegerMax/(width*4*sizeof(float))&&stride>=width*4&&height<=NSUIntegerMax/stride&&(format==UIEyedropperPixelFormatBGRA8||format==UIEyedropperPixelFormatW30R)){
                            NSMutableData *floating=[NSMutableData dataWithLength:width*height*4*sizeof(float)];float *destination=floating.mutableBytes;
                            for(size_t y=0;y<height;y++)for(size_t x=0;x<width;x++){
                                const uint8_t *input=source+y*stride+x*4;float *output=destination+(y*width+x)*4;
                                if(format==UIEyedropperPixelFormatBGRA8){output[0]=input[2]/255.f;output[1]=input[1]/255.f;output[2]=input[0]/255.f;}
                                else{uint32_t packed;memcpy(&packed,input,sizeof(packed));output[0]=((float)((packed>>20)&1023)-384.f)/510.f;output[1]=((float)((packed>>10)&1023)-384.f)/510.f;output[2]=((float)(packed&1023)-384.f)/510.f;}
                                output[3]=1;
                            }
                            CGDataProviderRef provider=CGDataProviderCreateWithCFData((__bridge CFDataRef)floating);pixels=CGImageCreate(width,height,32,128,width*4*sizeof(float),space,kCGBitmapFloatComponents|kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast,provider,NULL,NO,kCGRenderingIntentDefault);CGDataProviderRelease(provider);conversion=@"IOSurface original BGRA8/w30r to float32";
                        }
                        unlock(surface,1,NULL);
                    }
                }
                if(pixels){snapshot=[UIImage imageWithCGImage:pixels scale:screen.scale orientation:UIImageOrientationUp];details=@{@"backend":@"_UIRenderDisplay",@"conversion":conversion,@"width":@(CGImageGetWidth(pixels)),@"height":@(CGImageGetHeight(pixels)),@"scale":@(screen.scale),@"screenBounds":NSStringFromCGRect(screen.bounds),@"outputColorSpace":@"extended-sRGB",@"outputBitsPerComponent":@(CGImageGetBitsPerComponent(pixels)),@"liveSystemSampling":@YES,@"sourceRect":NSStringFromCGRect(rect),@"sourceOrientation":@(orientation),@"diagnostics":diagnostics};CGImageRelease(pixels);}
                CGColorSpaceRelease(space);CFRelease(surface);
            }
        }
    }
#endif
    self.systemCaptureDetails=details?:@{@"liveSystemSampling":@YES,@"diagnostics":diagnostics};
    return snapshot;
}
// BINMAP-ADAPT: UIEyedropperViewController.presentLiveFromViewController: — EDWindow0x52f6 layer exclusion; public same-scene window ownership replaces daemon-only orientation/input controls.
- (void)presentLiveFromViewController:(UIViewController *)controller {
    NSAssert(NSThread.isMainThread,@"Eyedropper UI must run on the main thread.");
    if(!self.liveSystemSampling||self.finished||self.liveWindow)return;
    UIWindow *hostWindow=controller.view.window;
    if(!self.use_spi||!self.samplingAvailable||!hostWindow||hostWindow.screen!=self.systemScreen){
        self.samplingAvailable=NO;
        if(!self.sampleError)self.sampleError=[NSError errorWithDomain:@"UIColorPanelKit.Eyedropper" code:3 userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"Color sampling is unavailable."]}];
        [self finishWithColor:nil];return;
    }
#if UICOLORPANEL_ENABLE_PRIVATE_API
    UIWindow *window=nil;
    if(@available(iOS 13.0,*)){
        if(hostWindow.windowScene){window=[[UIWindow alloc]initWithWindowScene:hostWindow.windowScene];window.frame=hostWindow.windowScene.coordinateSpace.bounds;}
    }
    if(!window){window=[[UIWindow alloc]initWithFrame:self.systemScreen.bounds];window.screen=self.systemScreen;}
    // The service's own screenshot level is proven. Its absence changes only
    // this app-local UIKit window level, using the public alert level instead.
    const CGFloat *serviceLevel=dlsym(RTLD_DEFAULT,"UIScreenshotServicesWindowLevel");
    window.windowLevel=serviceLevel?*serviceLevel-1:UIWindowLevelAlert+1;
    window.backgroundColor=UIColor.clearColor;[window.layer setDisableUpdateMask:2];
    if(@available(iOS 13.0,*)){
        for(UIWindow *candidate in hostWindow.windowScene.windows)if(candidate.isKeyWindow){self.previousKeyWindow=candidate;break;}
    }
    if(!self.previousKeyWindow&&hostWindow.isKeyWindow)self.previousKeyWindow=hostWindow;
    self.liveWindow=window;window.rootViewController=self;[window makeKeyAndVisible];
#endif
}
// BINMAP-ADAPT: UIEyedropperViewController.dismissLiveWithCompletion: — idempotent teardown; hiding/detaching the owned root breaks the window/controller cycle.
- (void)dismissLiveWithCompletion:(void (^)(void))completion {
    NSAssert(NSThread.isMainThread,@"Eyedropper UI must run on the main thread.");
    if(self.liveSystemSampling&&!self.finished){[self finishWithColor:nil];if(completion)completion();return;}
    [self stopLiveSampling];UIWindow *window=self.liveWindow;UIWindow *previous=self.previousKeyWindow;
    BOOL restoreKey=window.isKeyWindow&&previous&&!previous.hidden&&previous.screen==window.screen;
    if(@available(iOS 13.0,*))restoreKey=restoreKey&&previous.windowScene==window.windowScene;
    self.liveWindow=nil;self.previousKeyWindow=nil;window.hidden=YES;window.rootViewController=nil;
    if(restoreKey)[previous makeKeyWindow];
    if(completion)completion();
}
// BINMAP-ADAPT: UIEyedropperViewController.startLiveSampling — original EDLensView init0x3008/present0x4173 common-mode display link, owned only by the visible live session.
- (void)startLiveSampling {
    if(!self.liveSystemSampling||self.finished||!self.samplingAvailable||!self.use_spi||!self.liveWindow||self.liveWindow.hidden||self.liveDisplayLink)return;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    self.liveDisplayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(liveDisplayLinkFired:)];
    [self.liveDisplayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
// BINMAP-ADAPT: UIEyedropperViewController.stopLiveSampling — original paused lifecycle transported as invalidation to release the UIKit target cycle.
- (void)stopLiveSampling {
    [self.liveDisplayLink invalidate];self.liveDisplayLink=nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}
// BINMAP-ADAPT: UIEyedropperViewController.liveDisplayLinkFired: — original0x4825 presentation center and 9/screen.scale source square; current same-scene orientation is a UIKit adaptation.
- (void)liveDisplayLinkFired:(CADisplayLink *)displayLink {
    if(!self.liveSystemSampling||self.finished||!self.samplingAvailable||!self.use_spi||!self.liveWindow||self.liveWindow.hidden||self.lens.lensState==2)return;
    CALayer *presentation=self.lens.layer.presentationLayer;
    // The app-local public adapter can receive an initial drag before Core
    // Animation has a presentation tree. Use its initial model frame then.
    CGRect frame=presentation?presentation.frame:self.lens.frame;
    CGPoint point=[self.view convertPoint:CGPointMake(CGRectGetMidX(frame),CGRectGetMidY(frame)) toCoordinateSpace:self.systemScreen.fixedCoordinateSpace];
    CGFloat side=9/self.systemScreen.scale;CGRect rect=CGRectMake(point.x-side*.5,point.y-side*.5,side,side);
    UIInterfaceOrientation orientation=UIInterfaceOrientationPortrait;BOOL resolved=NO;
    if(@available(iOS 13.0,*)){
        UIInterfaceOrientation observed=self.liveWindow.windowScene.interfaceOrientation;
        if(observed!=UIInterfaceOrientationUnknown){orientation=observed;resolved=YES;}
    }
    if(!resolved&&self.systemScreen==UIScreen.mainScreen){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIInterfaceOrientation observed=UIApplication.sharedApplication.statusBarOrientation;
#pragma clang diagnostic pop
        if(observed!=UIInterfaceOrientationUnknown)orientation=observed;
    }
    UIImage *tile=[self captureSystemImageInRect:rect orientation:orientation];
    UIEyedropperSample *sample=tile?[UIEyedropperPixelReader sampleImage:tile atPixel:CGPointMake(CGImageGetWidth(tile.CGImage)*.5,CGImageGetHeight(tile.CGImage)*.5)]:nil;
    self.selectedColor=sample.color;self.lens.sample=sample;self.commitButton.enabled=sample!=nil;[self.lens layoutIfNeeded];
    if(!sample){
        self.samplingAvailable=NO;[self stopLiveSampling];
        self.sampleError=[NSError errorWithDomain:@"UIColorPanelKit.Eyedropper" code:3 userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"Color sampling is unavailable."],@"UIEyedropperCaptureDetails":self.systemCaptureDetails}];
        self.instructionLabel.text=self.sampleError.localizedDescription;
        [self finishWithColor:nil];
    }
}
// BINMAP-ADAPT: UIEyedropperViewController.applicationWillResignActive: — this UIKit implementation owns no daemon/global touch session.
- (void)applicationWillResignActive:(NSNotification *)notification { if(self.liveSystemSampling&&!self.finished)[self cancel]; }
// BINMAP-ADAPT: UIEyedropperViewController.setUse_spi: — runtime disabling ends live capture before any subsequent compositor call.
- (void)setUse_spi:(BOOL)useSPI { _use_spi=useSPI;if(!useSPI&&self.liveSystemSampling&&!self.finished)[self cancel]; }
// BINMAP-ADAPT: UIEyedropperViewController.dealloc — release only this controller's cadence and notification subscription.
- (void)dealloc { [_liveDisplayLink invalidate];[[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil]; }
// BINMAP-ADAPT: UIEyedropperViewController.viewDidLoad — standard public controller controls and frozen-source bridge.
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.whiteColor;if(@available(iOS 13.0,*)){self.view.backgroundColor=UIColor.systemBackgroundColor;self.modalInPresentation=YES;}
    UIColor *controlBackground=self.view.backgroundColor;
    if(self.liveSystemSampling){self.view.backgroundColor=UIColor.clearColor;self.view.opaque=NO;}
    self.imageView=[[UIImageView alloc]initWithImage:self.sourceImage];self.imageView.contentMode=UIViewContentModeScaleAspectFit;self.imageView.backgroundColor=UIColor.whiteColor;self.imageView.accessibilityElementsHidden=YES;[self.view addSubview:self.imageView];
    self.imageView.hidden=self.liveSystemSampling;
    self.scopeLabel=[UILabel new];self.scopeLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];self.scopeLabel.adjustsFontForContentSizeCategory=YES;self.scopeLabel.numberOfLines=0;self.scopeLabel.text=[UIColorPanelAppearance localizedString:self.sourceKind];[self.view addSubview:self.scopeLabel];
    self.instructionLabel=[UILabel new];self.instructionLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];self.instructionLabel.adjustsFontForContentSizeCategory=YES;self.instructionLabel.numberOfLines=0;self.instructionLabel.text=self.samplingAvailable?[UIColorPanelAppearance localizedString:@"Drag to choose a pixel. Tap Use Color to confirm."]:self.sampleError.localizedDescription;[self.view addSubview:self.instructionLabel];
    self.cancelButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.cancelButton setTitle:[UIColorPanelAppearance localizedString:@"Cancel"] forState:UIControlStateNormal];self.cancelButton.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.cancelButton.titleLabel.adjustsFontForContentSizeCategory=YES;[self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];self.cancelButton.accessibilityIdentifier=@"ui.eyedropper.cancel";[self.view addSubview:self.cancelButton];
    self.commitButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.commitButton setTitle:[UIColorPanelAppearance localizedString:@"Use Color"] forState:UIControlStateNormal];self.commitButton.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.commitButton.titleLabel.adjustsFontForContentSizeCategory=YES;[self.commitButton addTarget:self action:@selector(commit) forControlEvents:UIControlEventTouchUpInside];self.commitButton.enabled=NO;self.commitButton.accessibilityIdentifier=@"ui.eyedropper.commit";[self.view addSubview:self.commitButton];
    self.scopeLabel.hidden=self.liveSystemSampling;self.instructionLabel.hidden=self.liveSystemSampling;
    self.cancelButton.hidden=self.liveSystemSampling;self.commitButton.hidden=self.liveSystemSampling;
    self.lens=[[UIEyedropperLensView alloc]initWithFrame:CGRectMake(0,0,288,288)];self.lens.delegate=self;self.lens.floatingMode=YES;[self.view insertSubview:self.lens belowSubview:self.cancelButton];
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(self.liveSystemSampling&&self.samplingAvailable&&self.use_spi)[self.lens.layer setDisableUpdateMask:2];
#endif
    // Frozen sources keep native actions above the recovered164pt hit ring.
    // The live window contains only the lens and its accessibility actions.
    self.cancelButton.backgroundColor=controlBackground;self.commitButton.backgroundColor=controlBackground;
    __weak typeof(self) weakSelf=self;
    if(!self.liveSystemSampling)self.lens.samplingHandler=^UIEyedropperSample *(CGPoint point){
        UIEyedropperViewController *controller=weakSelf;if(!controller||controller.finished||!controller.samplingAvailable||CGRectIsEmpty(controller.imageContentRect))return nil;
        CGFloat width=controller.sourceImage.size.width*controller.sourceImage.scale,height=controller.sourceImage.size.height*controller.sourceImage.scale;
        CGPoint pixel=CGPointMake((point.x-CGRectGetMinX(controller.imageContentRect))*width/controller.imageContentRect.size.width,(point.y-CGRectGetMinY(controller.imageContentRect))*height/controller.imageContentRect.size.height);
        UIEyedropperSample *sample=[UIEyedropperPixelReader sampleImage:controller.sourceImage atPixel:pixel];controller.selectedColor=sample.color;controller.commitButton.enabled=sample!=nil;
        if(!sample){controller.samplingAvailable=NO;controller.sampleError=[NSError errorWithDomain:@"UIColorPanelKit.Eyedropper" code:2 userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"Color sampling is unavailable."]}];controller.instructionLabel.text=controller.sampleError.localizedDescription;}
        return sample;
    };
    NSMutableArray *actions=[NSMutableArray new];for(NSDictionary *spec in @[@{@"title":@"Move Left",@"selector":NSStringFromSelector(@selector(accessibilityMoveLeft:))},@{@"title":@"Move Right",@"selector":NSStringFromSelector(@selector(accessibilityMoveRight:))},@{@"title":@"Move Up",@"selector":NSStringFromSelector(@selector(accessibilityMoveUp:))},@{@"title":@"Move Down",@"selector":NSStringFromSelector(@selector(accessibilityMoveDown:))},@{@"title":@"Choose Color",@"selector":NSStringFromSelector(@selector(accessibilityChoose:))},@{@"title":@"Cancel",@"selector":NSStringFromSelector(@selector(accessibilityCancel:))}]){[actions addObject:[[UIAccessibilityCustomAction alloc]initWithName:[UIColorPanelAppearance localizedString:spec[@"title"]] target:self selector:NSSelectorFromString(spec[@"selector"])]];}self.lens.accessibilityCustomActions=actions;
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];pan.delegate=self;[self.view addGestureRecognizer:pan];
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];tap.delegate=self;[self.view addGestureRecognizer:tap];
}
// BINMAP-ADAPT: UIEyedropperViewController.viewDidLayoutSubviews — live lens uses the full screen; only frozen sources reserve control bars.
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if(self.liveSystemSampling){
        self.imageView.frame=self.view.bounds;self.imageContentRect=self.view.bounds;
        if(!self.finished&&self.samplingAvailable&&self.lens.lensState!=2)[self moveToPoint:self.lens.lastPosition];
        return;
    }
    CGRect safe=UIEdgeInsetsInsetRect(self.view.bounds,self.view.safeAreaInsets);CGFloat width=MAX(0,safe.size.width-32);
    CGFloat title=MAX(28,[self.scopeLabel sizeThatFits:CGSizeMake(width,CGFLOAT_MAX)].height),instruction=MAX(38,[self.instructionLabel sizeThatFits:CGSizeMake(width,CGFLOAT_MAX)].height);
    self.scopeLabel.frame=CGRectMake(CGRectGetMinX(safe)+16,CGRectGetMinY(safe)+8,width,title);self.instructionLabel.frame=CGRectMake(CGRectGetMinX(safe)+16,CGRectGetMaxY(self.scopeLabel.frame)+4,width,instruction);
    self.cancelButton.frame=CGRectMake(CGRectGetMinX(safe)+12,CGRectGetMaxY(safe)-52,MAX(0,safe.size.width*.5-18),44);self.commitButton.frame=CGRectMake(CGRectGetMidX(safe)+6,CGRectGetMaxY(safe)-52,MAX(0,safe.size.width*.5-18),44);
    self.imageView.frame=CGRectMake(CGRectGetMinX(safe),CGRectGetMaxY(self.instructionLabel.frame)+8,safe.size.width,MAX(0,CGRectGetMinY(self.cancelButton.frame)-8-CGRectGetMaxY(self.instructionLabel.frame)-8));
    CGFloat imageWidth=self.sourceImage.size.width* self.sourceImage.scale,imageHeight=self.sourceImage.size.height*self.sourceImage.scale;
    CGFloat fit=imageWidth>0&&imageHeight>0?MIN(self.imageView.bounds.size.width/imageWidth,self.imageView.bounds.size.height/imageHeight):0;
    self.imageContentRect=CGRectMake(CGRectGetMidX(self.imageView.frame)-imageWidth*fit*.5,CGRectGetMidY(self.imageView.frame)-imageHeight*fit*.5,imageWidth*fit,imageHeight*fit);
    if(!self.finished&&self.samplingAvailable&&self.lens.lensState!=2)[self moveToPoint:self.lens.lastPosition];
}
// BINMAP-ADAPT: UIEyedropperViewController.viewDidAppear: — floatEyeDropper block0x23dd defaults to screen center; the host can forward its initiating button point after presentation.
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated];if(self.samplingAvailable&&!self.finished){[self moveToPoint:CGPointMake(CGRectGetMidX(self.imageContentRect),CGRectGetMidY(self.imageContentRect))];[self startLiveSampling];} }
// BINMAP-ADAPT: UIEyedropperViewController.viewDidDisappear: — host dismissal is cancellation when no commit was made.
- (void)viewDidDisappear:(BOOL)animated { [super viewDidDisappear:animated];[self stopLiveSampling];if(!self.finished)[self cancel]; }
// BINMAP-ADAPT: UIEyedropperViewController.moveToPoint: — public touch/AX transport; coordinates are in this controller's root view.
- (void)moveToPoint:(CGPoint)point {
    NSAssert(NSThread.isMainThread,@"Eyedropper UI must run on the main thread.");[self loadViewIfNeeded];
    if(self.finished||!self.samplingAvailable||CGRectIsEmpty(self.imageContentRect)||!isfinite(point.x)||!isfinite(point.y))return;
    point.x=MAX(CGRectGetMinX(self.imageContentRect),MIN(CGRectGetMaxX(self.imageContentRect)-.001,point.x));point.y=MAX(CGRectGetMinY(self.imageContentRect),MIN(CGRectGetMaxY(self.imageContentRect)-.001,point.y));
    if(self.lens.lensState==2){[self.lens presentAtLocation:point];[self.lens layoutIfNeeded];}
    else{self.lens.lastPosition=point;[self.lens updateLensState:3];[self.lens setNeedsLayout];[self.lens layoutIfNeeded];}
    if(!self.liveSystemSampling)[self.lens _displayLinkFired];[self.lens layoutIfNeeded];
}
// BINMAP-ADAPT: UIEyedropperViewController.gestureRecognizer:shouldReceiveTouch: — native buttons retain their own interaction; trackedTouchesBegan0x2828 adjusts before Ended confirms.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    for(UIView *view=touch.view;view;view=view.superview)if([view isKindOfClass:UIControl.class])return NO;
    if(self.finished)return NO;
    if(self.liveSystemSampling&&[gesture isKindOfClass:UITapGestureRecognizer.class]){
        // Original _layoutStaticElements0x36d8 gives the center its9-cell
        // width plus4pt border. Only that target bypasses trackedTouchesBegan.
        CGFloat side=CGRectGetWidth(CGRectInset(self.lens.bounds,79,79))/9+4;
        CGRect center=CGRectMake(CGRectGetMidX(self.lens.bounds)-side*.5,CGRectGetMidY(self.lens.bounds)-side*.5,side,side);
        CGPoint point=[touch locationInView:self.view],local=[self.lens convertPoint:point fromView:self.view];
        if(!CGRectContainsPoint(center,local)){
            // Preserve presentAtLocation:'s >=200pt cancellation and nearer
            // one-pixel adjustment, allowing live refresh before touch end.
            [self.lens presentAtLocation:point];[self.lens layoutIfNeeded];
        }
    }
    return !self.finished;
}
// BINMAP-ADAPT: UIEyedropperViewController.handlePan: — original offset capture0x409b and subtraction0x45b2, transported through public UIKit pan coordinates.
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIGestureRecognizerState state=gesture.state;
    if(state==UIGestureRecognizerStateBegan||state==UIGestureRecognizerStateChanged||state==UIGestureRecognizerStateEnded){
        CGPoint point=[gesture locationInView:self.view];
        if(state==UIGestureRecognizerStateBegan){
            _panGrabOffset=CGPointZero;
            // Recognition begins after movement; classify the original touch
            // against the existing lens hit region, not the moved finger.
            CGPoint translation=[gesture translationInView:self.view],start=CGPointMake(point.x-translation.x,point.y-translation.y);
            if(self.lens.floatingMode&&!self.lens.hidden&&[self.lens pointInside:[self.lens convertPoint:start fromView:self.view] withEvent:nil])
                _panGrabOffset=CGPointMake(start.x-self.lens.lastPosition.x,start.y-self.lens.lastPosition.y);
        }
        [self moveToPoint:CGPointMake(point.x-_panGrabOffset.x,point.y-_panGrabOffset.y)];
    }
    if(state==UIGestureRecognizerStateEnded||state==UIGestureRecognizerStateCancelled||state==UIGestureRecognizerStateFailed)_panGrabOffset=CGPointZero;
}
// BINMAP-ADAPT: UIEyedropperViewController.handleTap: — public gesture transport of center confirmation0x4375 and tracked touch begin/end0x2828/0x290a; frozen taps select a source position.
- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if(gesture.state!=UIGestureRecognizerStateEnded)return;
    CGPoint point=[gesture locationInView:self.view];
    if(!self.liveSystemSampling){[self moveToPoint:point];return;}
    if(!self.finished)[self commit];
}
// BINMAP-ADAPT: UIEyedropperViewController.commit
- (void)commit { if(!self.finished&&self.selectedColor)[self.lens dismiss]; }
// BINMAP-ADAPT: UIEyedropperViewController.cancel
- (void)cancel { if(self.finished)return;[self.lens _dismissAndRemoveAlpha:YES];[self finishWithColor:nil]; }
// BINMAP-ADAPT: UIEyedropperViewController.finishWithColor: — stop/release live resources before a single session callback; public modal dismissal stays with the host.
- (void)finishWithColor:(UIColorValue *)color { if(self.finished)return;self.finished=YES;[self stopLiveSampling];if(self.isViewLoaded)self.view.userInteractionEnabled=NO;void(^completion)(UIColorValue *)=[self.completionHandler copy];self.completionHandler=nil;self.lens.samplingHandler=nil;if(self.liveSystemSampling)[self dismissLiveWithCompletion:nil];if(completion)completion(color); }
// BINMAP-ADAPT: UIEyedropperViewController.lensView:didSelectColor: — preserve the canonical value from the public source rather than round-tripping UI preview.
- (void)lensView:(UIEyedropperLensView *)lens didSelectColor:(UIColor *)color { self.pendingColor=self.selectedColor; }
// BINMAP-ADAPT: UIEyedropperViewController.lensViewDidDismiss:
- (void)lensViewDidDismiss:(UIEyedropperLensView *)lens { [self finishWithColor:self.pendingColor]; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityMoveLeft:
- (BOOL)accessibilityMoveLeft:(UIAccessibilityCustomAction *)action { if(!self.samplingAvailable||self.finished)return NO;CGPoint point=self.lens.lastPosition;point.x-=self.liveSystemSampling?1/self.systemScreen.scale:self.imageContentRect.size.width/(self.sourceImage.size.width*self.sourceImage.scale);[self moveToPoint:point];return YES; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityMoveRight:
- (BOOL)accessibilityMoveRight:(UIAccessibilityCustomAction *)action { if(!self.samplingAvailable||self.finished)return NO;CGPoint point=self.lens.lastPosition;point.x+=self.liveSystemSampling?1/self.systemScreen.scale:self.imageContentRect.size.width/(self.sourceImage.size.width*self.sourceImage.scale);[self moveToPoint:point];return YES; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityMoveUp:
- (BOOL)accessibilityMoveUp:(UIAccessibilityCustomAction *)action { if(!self.samplingAvailable||self.finished)return NO;CGPoint point=self.lens.lastPosition;point.y-=self.liveSystemSampling?1/self.systemScreen.scale:self.imageContentRect.size.height/(self.sourceImage.size.height*self.sourceImage.scale);[self moveToPoint:point];return YES; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityMoveDown:
- (BOOL)accessibilityMoveDown:(UIAccessibilityCustomAction *)action { if(!self.samplingAvailable||self.finished)return NO;CGPoint point=self.lens.lastPosition;point.y+=self.liveSystemSampling?1/self.systemScreen.scale:self.imageContentRect.size.height/(self.sourceImage.size.height*self.sourceImage.scale);[self moveToPoint:point];return YES; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityChoose:
- (BOOL)accessibilityChoose:(UIAccessibilityCustomAction *)action { if(!self.selectedColor||self.finished)return NO;[self commit];return YES; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityCancel:
- (BOOL)accessibilityCancel:(UIAccessibilityCustomAction *)action { if(self.finished)return NO;[self cancel];return YES; }
// BINMAP-ADAPT: UIEyedropperViewController.accessibilityPerformEscape
- (BOOL)accessibilityPerformEscape { if(self.finished)return NO;[self cancel];return YES; }
@end
