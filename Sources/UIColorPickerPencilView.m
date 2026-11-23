#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import "UIColorPickerPencilView.h"
#import "UIColoredPencilArtwork.h"
#import "UIColorPanelAppearance.h"
#import "UIColorValue+AppKitEquality.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
@interface UIImage (UIColorPencilHitTesting)
- (BOOL)hitTestRect:(CGRect)rect withImageDestinationRect:(CGRect)destination context:(CGContextRef)context hints:(NSDictionary *)hints flipped:(BOOL)flipped;
@end
@interface UIColorPickerPencilView ()
@property(nonatomic) BOOL usesInternalColorList;
- (void)_pencilViewCommonInit;
- (void)layout;
- (void)_updateFocusRing;
- (void)_addFocusToLayer:(CALayer *)layer animate:(BOOL)animate;
- (void)_removeFocusFromLayer:(CALayer *)layer;
- (CALayer *)_layerForPencil:(UIColoredPencil *)pencil;
- (void)_setLayer:(CALayer *)layer forPencil:(UIColoredPencil *)pencil;
- (void)_removeAllPencilLayers;
- (void)_enumeratePencilsWithBlock:(void (^)(UIColoredPencil *,NSInteger,NSInteger))block;
- (void)_row:(NSInteger *)row column:(NSInteger *)column ofPencil:(UIColoredPencil *)pencil;
- (UIColoredPencil *)_pencilAtRow:(NSInteger)row column:(NSInteger)column;
- (UIColoredPencil *)_pencilBelow:(UIColoredPencil *)pencil;
- (UIColoredPencil *)_focusedPencil;
- (UIColoredPencil *)_namedPencil;
- (BOOL)_shouldShowFocusRing;
- (BOOL)_hasFocusRing;
- (CGRect)_calculateFrameForPencil:(UIColoredPencil *)pencil;
- (CGRect)_frameOfPencil:(UIColoredPencil *)pencil;
- (void)_updateFramesForPencils:(NSArray *)pencils duration:(NSTimeInterval)duration;
- (void)_hoverAndSelectPencilWithEvent:(UITouch *)event;
- (UIColoredPencil *)_pencilAtEventLocation:(UITouch *)event;
- (UIColorList *)_colorList;
- (void)mouseDown:(UITouch *)event;
- (void)mouseDragged:(UITouch *)event;
- (void)mouseUp:(UITouch *)event;
@end
@implementation UIColorPickerPencilView {
    NSMutableArray<UIColoredPencil *> *_pencils;
    NSMutableDictionary<NSString *,CALayer *> *_pencilLayers;
    UIColorList *_crayonList;
    UIColoredPencil *_selectedPencil;
    __weak UIColoredPencil *_hoveredPencil;
    UIColoredPencil *_currentFocusedPencil;
    BOOL _didHoverOutsideSelectedPencil;
    BOOL _didCompleteScaledRender;
    NSMapTable<UIColoredPencil *,NSArray<UIImage *> *> *_scaledRepresentations;
    NSLayoutConstraint *_aspectRatioConstraint;
    UIHoverGestureRecognizer *_hoverRecognizer API_AVAILABLE(ios(13.0));
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView initWithFrame:] ea=0x183b27780 end=0x183b277d4
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){
        [self _pencilViewCommonInit];
        // BINNOTE: public UIKit code construction replaces the original compiled-nib awake call.
        [self awakeFromNib];
    }return self;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView initWithCoder:] ea=0x183b277d4 end=0x183b27828
- (instancetype)initWithCoder:(NSCoder *)coder {
    if((self=[super initWithCoder:coder]))[self _pencilViewCommonInit];return self;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilViewCommonInit] ea=0x183b27828 end=0x183b27868
- (void)_pencilViewCommonInit {
    self.clipsToBounds=NO;self.opaque=NO;
    // NSFeatureFlag/compiled-nib import bridge: preserve the recovered defaults
    // and the original nib's native inequalities (all priority1000).
    NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
    _selectedPencilStaysUp=[defaults objectForKey:@"NSPencilPickerSelectedPencilStaysUp"]?[defaults boolForKey:@"NSPencilPickerSelectedPencilStaysUp"]:YES;
    _lowerHoveredPencil=[defaults objectForKey:@"NSPencilPickerLowerHoveredPencil"]?[defaults boolForKey:@"NSPencilPickerLowerHoveredPencil"]:YES;
    _strictAspectRatio=[defaults boolForKey:@"NSPencilPickerStrictAspectRatio"];
    _prerenderScaledPencilRepresentations=[defaults boolForKey:@"NSPencilPickerPrerenderScaledPencilRepresentations"];
    _aspectRatioConstraint=[self.widthAnchor constraintEqualToAnchor:self.heightAnchor multiplier:1.0654205083847046];
    [NSLayoutConstraint activateConstraints:@[
        [self.widthAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor multiplier:1.149999976158142],
        [self.heightAnchor constraintGreaterThanOrEqualToConstant:214],
        [self.widthAnchor constraintGreaterThanOrEqualToAnchor:self.heightAnchor multiplier:.6665999889373779],
        _aspectRatioConstraint,
        [self.widthAnchor constraintLessThanOrEqualToConstant:408],
        [self.widthAnchor constraintGreaterThanOrEqualToConstant:228]]];
    self.isAccessibilityElement=NO;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_windowChangedKeyState) name:UIWindowDidBecomeKeyNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_windowChangedKeyState) name:UIWindowDidResignKeyNotification object:nil];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView awakeFromNib] ea=0x183b27868 end=0x183b278f0
- (void)awakeFromNib {
    [super awakeFromNib];
    [self _updatePencilsFromColorList];
    if(!self.strictAspectRatio)_aspectRatioConstraint.active=NO;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView dealloc] ea=0x183b278f0 end=0x183b27978
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    _pencils=nil;_selectedPencil=nil;_pencilLayers=nil;
    if(@available(iOS 13.0,*))_hoverRecognizer=nil;
    _crayonList=nil; // ARC supplies superclass/remaining synthesized-ivar destruction.
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView acceptsFirstResponder] ea=0x183b27978 end=0x183b27980
- (BOOL)acceptsFirstResponder {
    return YES;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView becomeFirstResponder] ea=0x183b27980 end=0x183b279d8
- (BOOL)becomeFirstResponder {
    BOOL result=[super becomeFirstResponder];if(result)[self _updateFocusRing];return result;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView resignFirstResponder] ea=0x183b279d8 end=0x183b27a40
- (BOOL)resignFirstResponder {
    BOOL result=[super resignFirstResponder];if(result)[self performSelector:@selector(_updateFocusRing) withObject:nil afterDelay:0];return result;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView needsPanelToBecomeKey] ea=0x183b27a40 end=0x183b27a48
- (BOOL)needsPanelToBecomeKey {
    return NO;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _windowChangedKeyState] ea=0x183b27a48 end=0x183b27a94
- (void)_windowChangedKeyState {
    [self _updateFocusRing];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _namedPencil] ea=0x183b27a94 end=0x183b27ab8
- (UIColoredPencil *)_namedPencil {
    return _hoveredPencil?:_selectedPencil;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView localizedColorNameComponent] ea=0x183b27ab8 end=0x183b27b28
- (NSString *)localizedColorNameComponent {
    if(![self _namedPencil].name)return @"";
    UIColorList *list=[self _colorList];NSString *name=[self _namedPencil].name;
    return self.usesInternalColorList?[UIColorPanelAppearance localizedString:name]:[list localizedColorNameWithKey:name]; // Only original built-in/fallback names are translated.
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView setColor:] ea=0x183b27b28 end=0x183b27b6c
- (void)setColor:(UIColorValue *)color {
    [self _selectPencil:[self _pencilWithColor:color] updateSelection:NO animate:NO];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView color] ea=0x183b27b6c end=0x183b27bac
- (UIColorValue *)color {
    return [self _selectedPencil].color?:[[UIColorValue alloc]initWithCGColor:UIColor.blackColor.CGColor];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView isFlipped] ea=0x183b27bac end=0x183b27bb4
- (BOOL)isFlipped {
    return YES;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView layout] ea=0x183b27bb4 end=0x183b27c54
- (void)layout {
    // BINNOTE: super.layout is called by the UIKit layoutSubviews import bridge.
    CALayer *rootLayer=self.layer;NSString *minificationFilter=kCAFilterTrilinear;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(self.use_spi)minificationFilter=@"lanczos";
#endif
    // BINMAP-BLOCK: invoke_ea=0x183b27c54 parent=-[NSColorPickerPencilView layout] reconstructed_as=block_literal
    [self _enumeratePencilsWithBlock:^(UIColoredPencil *pencil,NSInteger row,NSInteger column){
        CALayer *layer=[self _layerForPencil:pencil];
        if(!layer){layer=[CALayer layer];layer.name=pencil.name;layer.contents=(__bridge id)pencil.image.CGImage;
            layer.contentsGravity=kCAGravityResizeAspect;layer.minificationFilter=minificationFilter;layer.anchorPoint=CGPointZero;
            [layer setValue:row?@.34:@.17 forKey:@"preferredShadowOpacity"];
            [rootLayer addSublayer:layer];[self _setLayer:layer forPencil:pencil];}
        CGRect frame=[self _calculateFrameForPencil:pencil atRow:row column:column];
        if(self.prerenderScaledPencilRepresentations){
            if(self->_didCompleteScaledRender){layer.minificationFilter=kCAFilterLinear;
                CGFloat scale=frame.size.width/pencil.image.size.width*self.contentScaleFactor;
                NSArray *reps=[self->_scaledRepresentations objectForKey:pencil];UIImage *chosen=pencil.image;
                if(scale<=.25&&reps.count>0)chosen=reps[0];else if(scale<=.5&&reps.count>1)chosen=reps[1];
                // NSImage recommendedLayerContentsScale/layerContentsForContentsScale import bridge.
                layer.contents=(__bridge id)chosen.CGImage;
            }else layer.minificationFilter=minificationFilter;
        }
        [CATransaction setDisableActions:YES];
        if([self _focusedPencil]==pencil)[self _addFocusToLayer:layer animate:NO];else[self _removeFocusFromLayer:layer];
        layer.bounds=(CGRect){CGPointZero,frame.size};layer.frame=frame;[CATransaction setDisableActions:NO];
    }];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView viewWillStartLiveResize] ea=0x183b27ee8 end=0x183b27fb8
- (void)viewWillStartLiveResize {
    if(!self.prerenderScaledPencilRepresentations){
        // BINMAP-BLOCK: invoke_ea=0x183b27fb8 parent=-[NSColorPickerPencilView viewWillStartLiveResize] reconstructed_as=block_literal
        [self _enumeratePencilsWithBlock:^(UIColoredPencil *pencil,NSInteger row,NSInteger column){CALayer *layer=[self _layerForPencil:pencil];if(layer){layer.minificationFilter=kCAFilterTrilinear;layer.minificationFilterBias=-.6f;}}];
    } // UIKit has no super live-resize notification; caller may bracket a live resize.

}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView viewDidEndLiveResize] ea=0x183b28020 end=0x183b280f0
- (void)viewDidEndLiveResize {
    NSString *minificationFilter=kCAFilterTrilinear;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(self.use_spi)minificationFilter=@"lanczos";
#endif
    if(!self.prerenderScaledPencilRepresentations){
        // BINMAP-BLOCK: invoke_ea=0x183b280f0 parent=-[NSColorPickerPencilView viewDidEndLiveResize] reconstructed_as=block_literal
        [self _enumeratePencilsWithBlock:^(UIColoredPencil *pencil,NSInteger row,NSInteger column){CALayer *layer=[self _layerForPencil:pencil];if(layer)layer.minificationFilter=minificationFilter;}];
    }
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _layerForPencil:] ea=0x183b28138 end=0x183b28180
- (CALayer *)_layerForPencil:(UIColoredPencil *)pencil {
    return _pencilLayers[pencil.name];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _setLayer:forPencil:] ea=0x183b28180 end=0x183b28220
- (void)_setLayer:(CALayer *)layer forPencil:(UIColoredPencil *)pencil {
    if(!_pencilLayers)_pencilLayers=[[NSMutableDictionary alloc]initWithCapacity:_pencils.count];_pencilLayers[pencil.name]=layer;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _removeAllPencilLayers] ea=0x183b28220 end=0x183b28270
- (void)_removeAllPencilLayers {
    for(CALayer *layer in _pencilLayers.allValues)[layer removeFromSuperlayer];[_pencilLayers removeAllObjects];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _updateFramesForPencils:duration:] ea=0x183b28270 end=0x183b282f0
- (void)_updateFramesForPencils:(NSArray *)pencils duration:(NSTimeInterval)duration {
    // BINMAP-ADAPT: iOS Reduce Motion changes presentation, not selection geometry.
    BOOL reduceMotion=UIAccessibilityIsReduceMotionEnabled();if(reduceMotion)duration=0;
    // NSAnimationContext runAnimationGroup import bridge: same lexical update block, CA timing/duration.
    // BINMAP-BLOCK: invoke_ea=0x183b282f0 parent=-[NSColorPickerPencilView _updateFramesForPencils:duration:] reconstructed_as=block_literal
    void (^updates)(void)=^{[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [CATransaction setAnimationDuration:duration];for(UIColoredPencil *pencil in pencils){CALayer *layer=[self _layerForPencil:pencil];if(reduceMotion)[layer removeAnimationForKey:@"position"];layer.frame=[self _calculateFrameForPencil:pencil];}};
    [CATransaction begin];[CATransaction setDisableActions:duration==0];updates();[CATransaction commit];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView acceptsFirstMouse:] ea=0x183b28434 end=0x183b2843c
- (BOOL)acceptsFirstMouse:(id)event {
    return YES;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseDownCanMoveWindow] ea=0x183b2843c end=0x183b28444
- (BOOL)mouseDownCanMoveWindow {
    return NO;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseDown:] ea=0x183b28444 end=0x183b28448
- (void)mouseDown:(UITouch *)event {
    [self _hoverAndSelectPencilWithEvent:event];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseDragged:] ea=0x183b28448 end=0x183b2844c
- (void)mouseDragged:(UITouch *)event {
    [self _hoverAndSelectPencilWithEvent:event];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseUp:] ea=0x183b2844c end=0x183b28450
- (void)mouseUp:(UITouch *)event {
    [self _hoverAndSelectPencilWithEvent:event];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _hoverAndSelectPencilWithEvent:] ea=0x183b28450 end=0x183b284b4
- (void)_hoverAndSelectPencilWithEvent:(UITouch *)event {
    UIColoredPencil *pencil=[self _pencilAtEventLocation:event];[self _hoverPencil:pencil];if(pencil)[self _selectPencil:pencil updateSelection:YES animate:YES];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseMoved:] ea=0x183b284b4 end=0x183b284f0
- (void)mouseMoved:(UITouch *)event {
    [self _hoverPencil:[self _pencilAtEventLocation:event]];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseEntered:] ea=0x183b284f0 end=0x183b284f4
- (void)mouseEntered:(UITouch *)event {
    [self mouseMoved:event];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView mouseExited:] ea=0x183b284f4 end=0x183b284fc
- (void)mouseExited:(id)event {
    [self _hoverPencil:nil];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilAtEventLocation:] ea=0x183b284fc end=0x183b285a8
- (UIColoredPencil *)_pencilAtEventLocation:(UITouch *)event {
    CGPoint point=[event locationInView:self];if(!CGRectContainsPoint(self.bounds,point))return nil;return[self _pencilAtViewPoint:point];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView updateTrackingAreas] ea=0x183b285a8 end=0x183b28628
- (void)updateTrackingAreas {
    // Public hover recognizer imports the native active-in-key-window mouse tracking area.
    if(@available(iOS 13.0,*)){if(!_hoverRecognizer){_hoverRecognizer=[[UIHoverGestureRecognizer alloc]initWithTarget:self action:@selector(hoverGesture:)];[self addGestureRecognizer:_hoverRecognizer];}}
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _selectedPencil] ea=0x183b28628 end=0x183b28638
- (UIColoredPencil *)_selectedPencil {
    return _selectedPencil;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _colorList] ea=0x183b28638 end=0x183b2870c
- (UIColorList *)_colorList {
    if(!_crayonList){_crayonList=[UIColorList colorListNamed:@"Crayons"];
        if(_crayonList.allKeys.count!=48){
            NSLog(@"Colored pencil picker only supports %d colors, found %d in crayon list: '%@'. \n Falling back to internal color list.",48,(int)_crayonList.allKeys.count,_crayonList);
            // Original fallback Crayons.clr import becomes the already observed canonical built-in JSON resource.
            NSString *path=[[UIColorPanelAppearance resourceBundle]pathForResource:@"UIBuiltInPalettes"ofType:@"json"]?:[[NSBundle bundleForClass:self.class]pathForResource:@"UIBuiltInPalettes"ofType:@"json"]?:[NSBundle.mainBundle pathForResource:@"UIBuiltInPalettes"ofType:@"json"];
            NSDictionary *data=path?[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]options:0 error:NULL]:nil;
            _crayonList=[[UIColorList alloc]initWithName:@"Crayons"];self.usesInternalColorList=YES;
            for(NSDictionary *palette in data[@"palettes"])if([palette[@"name"]isEqual:@"Crayons"]){for(NSDictionary *entry in palette[@"colors"]){NSArray *c=entry[@"cgComponents"]?:entry[@"components"];CGFloat v[4];for(NSUInteger i=0;i<4;i++)v[i]=[c[i]doubleValue];CGColorSpaceRef space=CGColorSpaceCreateWithName((__bridge CFStringRef)entry[@"cgSpaceName"]);if(space){CGColorRef cg=CGColorCreate(space,v);if(cg){[_crayonList setColorValue:[[UIColorValue alloc]initWithCGColor:cg]forKey:entry[@"name"]];CGColorRelease(cg);}CGColorSpaceRelease(space);}}break;}
        }
    }return _crayonList;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencils] ea=0x183b2870c end=0x183b2872c
- (NSArray<UIColoredPencil *> *)_pencils {
    return _pencils?:@[];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilWithColor:] ea=0x183b2872c end=0x183b28854
- (UIColoredPencil *)_pencilWithColor:(UIColorValue *)color {
    for(UIColoredPencil *pencil in _pencils){
        // NSCustomColorSpace name conversion keeps custom numeric space identity; calibrated/named NSColor imports have no direct UIColorValue subclass counterpart.
        if([pencil.color isEqualForColorPanel:color])return pencil;
    }return nil;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _enumeratePencilsWithBlock:] ea=0x183b28854 end=0x183b289c4
- (void)_enumeratePencilsWithBlock:(void (^)(UIColoredPencil *,NSInteger,NSInteger))block {
    NSInteger row=0,column=0;for(UIColoredPencil *pencil in [self _pencils]){NSAssert(row<4,@"Pencil row exceeds four rows");block(pencil,row,column);if(++column==12){column=0;row++;}}
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _row:column:ofPencil:] ea=0x183b289c4 end=0x183b28a34
- (void)_row:(NSInteger *)row column:(NSInteger *)column ofPencil:(UIColoredPencil *)pencil {
    NSUInteger index=[_pencils indexOfObject:pencil];if(index==NSNotFound){*row=NSNotFound;*column=NSNotFound;}else{*row=(NSInteger)index/12;*column=(NSInteger)index%12;}
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilAtRow:column:] ea=0x183b28a34 end=0x183b28aac
- (UIColoredPencil *)_pencilAtRow:(NSInteger)row column:(NSInteger)column {
    NSUInteger index=(NSUInteger)column+12*(NSUInteger)row;if((index&(1ULL<<63))||index>=_pencils.count)return nil;return _pencils[index];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _updatePencilsFromColorList] ea=0x183b28aac end=0x183b28c48
- (void)_updatePencilsFromColorList {
    UIColorList *list=[self _colorList];NSUInteger count=list.allKeys.count;[self _removeAllPencilLayers];
    for(UIColoredPencil *pencil in _pencils)pencil.owningPencilView=nil;
    _pencils=[[NSMutableArray alloc]initWithCapacity:count];_didCompleteScaledRender=NO;
    static dispatch_queue_t queue;static dispatch_once_t once;
    if(self.prerenderScaledPencilRepresentations){
        // BINMAP-BLOCK: invoke_ea=0x183b28c60 parent=-[NSColorPickerPencilView _updatePencilsFromColorList] reconstructed_as=block_literal
        dispatch_once(&once,^{dispatch_queue_attr_t attr=dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_DEFAULT,0);queue=dispatch_queue_create("com.apple.AppKit.NSColorPickerPencilView",attr);});
    }
    // BINMAP-COMPILER: exception_ea=0x183b28c48 parent_ea=0x183b28aac generated_by=ARC_block_unwind
    // BINMAP-COMPILER: exception_ea=0x183b290f0 parent_ea=0x183b28eb4 generated_by=ARC_weak_unwind
    // BINMAP-COMPILER: copy_ea=0x183b29200 dispose_ea=0x183b29288 parent_ea=0x183b29110 generated_by=ARC_block_captures
    // BINMAP-COMPILER: copy_ea=0x183b292f8 dispose_ea=0x183b29370 parent_ea=0x183b28eb4 generated_by=ARC_block_captures
    __block NSUInteger completed=0;
    // BINMAP-BLOCK: invoke_ea=0x183b28ca0 parent=-[NSColorPickerPencilView _updatePencilsFromColorList] reconstructed_as=block_literal
    [list.allKeys enumerateObjectsUsingBlock:^(NSString *key,NSUInteger index,BOOL *stop){
        UIColorValue *color=[list colorValueWithKey:key];
        NSString *suffix=[key.capitalizedString stringByReplacingOccurrencesOfString:@" " withString:@""];
        UIImage *image=self.imageProvider ? self.imageProvider([@"NSColorPanelPencil" stringByAppendingString:suffix])
                                          : UIColorPanelPencilArtwork(suffix);
        UIColoredPencil *pencil=[[UIColoredPencil alloc]initWithName:key color:color image:image];
        if(self.prerenderScaledPencilRepresentations&&image.CGImage){
            __weak UIColorPickerPencilView *weakSelf=self;__weak UIColoredPencil *weakPencil=pencil;
            // BINMAP-BLOCK: invoke_ea=0x183b28eb4 parent=-[NSColorPickerPencilView _updatePencilsFromColorList] reconstructed_as=block_literal
            dispatch_async(queue,^{@autoreleasepool{
                CIImage *input=[[CIImage alloc]initWithCGImage:image.CGImage];CIFilter *filter=[CIFilter filterWithName:@"CILanczosScaleTransform"];[filter setDefaults];[filter setValue:input forKey:kCIInputImageKey];[filter setValue:@.25 forKey:kCIInputScaleKey];CIContext *ctx=[CIContext contextWithOptions:nil];CIImage *output=filter.outputImage;CGImageRef quarter=[ctx createCGImage:output fromRect:output.extent];[filter setValue:@.5 forKey:kCIInputScaleKey];output=filter.outputImage;CGImageRef half=[ctx createCGImage:output fromRect:output.extent];UIImage *a=quarter?[UIImage imageWithCGImage:quarter scale:1 orientation:UIImageOrientationUp]:nil,*b=half?[UIImage imageWithCGImage:half scale:1 orientation:UIImageOrientationUp]:nil;if(quarter)CGImageRelease(quarter);if(half)CGImageRelease(half);
                // BINMAP-BLOCK: invoke_ea=0x183b29110 parent=-[NSColorPickerPencilView _updatePencilsFromColorList] reconstructed_as=block_literal
                void (^finish)(void)=^{UIColorPickerPencilView *view=weakSelf;UIColoredPencil *model=weakPencil;if(view&&model){if(!view->_scaledRepresentations)view->_scaledRepresentations=[NSMapTable weakToStrongObjectsMapTable];if(a&&b)[view->_scaledRepresentations setObject:@[a,b]forKey:model];if(++completed==count){view->_didCompleteScaledRender=YES;[view setNeedsLayout];}}};
                // BINMAP-BLOCK: invoke_ea=0x183b2aa70 parent=-[NSColorPickerPencilView _updatePencilsFromColorList] reconstructed_as=block_literal
                CFRunLoopPerformBlock(CFRunLoopGetMain(),kCFRunLoopCommonModes,^{@autoreleasepool{finish();}});if(CFRunLoopGetCurrent()!=CFRunLoopGetMain())CFRunLoopWakeUp(CFRunLoopGetMain());
            }});
        }
        [self->_pencils addObject:pencil];pencil.owningPencilView=self;
    }];[self setNeedsDisplay];[self setNeedsLayout];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _selectPencil:updateSelection:animate:] ea=0x183b293d4 end=0x183b299f0
- (void)_selectPencil:(UIColoredPencil *)pencil updateSelection:(BOOL)update animate:(BOOL)animate {
    // BINMAP-ADAPT: the static final selection remains visible with Reduce Motion.
    BOOL reduceMotion=UIAccessibilityIsReduceMotionEnabled();
    if(reduceMotion){animate=NO;[CATransaction begin];[CATransaction setDisableActions:YES];for(CALayer *layer in _pencilLayers.allValues){[layer removeAnimationForKey:@"position"];[layer removeAnimationForKey:@"shadowOpacity"];[layer removeAnimationForKey:@"shadowRadius"];}}
    if(_selectedPencil==pencil){
        if(pencil&&!self.selectedPencilStaysUp&&_didHoverOutsideSelectedPencil){_didHoverOutsideSelectedPencil=NO;
            CALayer *layer=[self _layerForPencil:pencil];if(layer&&animate){
                CGRect start=layer.presentationLayer.frame,target=[self _calculateFrameForPencil:pencil],frame=layer.frame;
                CGFloat mid=(start.origin.y+frame.size.height)*.5+((start.origin.y+frame.size.height)*.5-target.origin.y)*.5;
                if(mid==target.origin.y&&_hoveredPencil!=_selectedPencil)mid+=-15;
                [CATransaction begin];[CATransaction setDisableActions:YES];CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];animation.duration=.26;
                animation.values=@[[NSValue valueWithCGPoint:start.origin],[NSValue valueWithCGPoint:CGPointMake(frame.origin.x,mid)],[NSValue valueWithCGPoint:target.origin]];animation.keyTimes=@[@0,@0.6153846153846154,@1];
                // BINNOTE: Both timing imports verified by native nondefault bounce fixture: easeInEaseOut, easeIn.
                animation.timingFunctions=@[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
                [layer addAnimation:animation forKey:@"position"];layer.position=target.origin;[CATransaction commit];
            }else if(layer)layer.position=[self _calculateFrameForPencil:pencil].origin;
        }
    }else{
        BOOL showFocus=[self _shouldShowFocusRing];UIColoredPencil *old=_selectedPencil;
        // AppKit AXValueChanged posting maps to UIKit element trait/value reads and a layout-change announcement.
        if(old)UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,old);
        _selectedPencil=pencil;if(_selectedPencil==_hoveredPencil)_didHoverOutsideSelectedPencil=NO;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,self);if(_selectedPencil)UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,_selectedPencil);
        if(update||showFocus){/* Imported AppKit keyboard-UI state update has no public UIKit counterpart. */}
        if(self.selectedPencilStaysUp){NSMutableArray *changed=[[NSMutableArray alloc]initWithCapacity:2];if(old)[changed addObject:old];if(_selectedPencil)[changed addObject:_selectedPencil];[self _updateFramesForPencils:changed duration:animate?.18:0];}
        else if(pencil){
            CALayer *layer=[self _layerForPencil:pencil];if(layer&&animate){
                CGRect start=layer.presentationLayer.frame,target=[self _calculateFrameForPencil:pencil],frame=layer.frame;
                CGFloat mid=(start.origin.y+frame.size.height)*.5+((start.origin.y+frame.size.height)*.5-target.origin.y)*.5;
                if(mid==target.origin.y&&_hoveredPencil!=_selectedPencil)mid+=-15;
                [CATransaction begin];[CATransaction setDisableActions:YES];CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];animation.duration=.26;
                animation.values=@[[NSValue valueWithCGPoint:start.origin],[NSValue valueWithCGPoint:CGPointMake(frame.origin.x,mid)],[NSValue valueWithCGPoint:target.origin]];animation.keyTimes=@[@0,@0.6153846153846154,@1];
                // BINNOTE: Both timing imports verified by native nondefault bounce fixture: easeInEaseOut, easeIn.
                animation.timingFunctions=@[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
                [layer addAnimation:animation forKey:@"position"];layer.position=target.origin;[CATransaction commit];
            }else if(layer)layer.position=[self _calculateFrameForPencil:pencil].origin;
        }[self _updateFocusRing];
    }
    if(reduceMotion)[CATransaction commit];
    if(update)[self.controllingPicker changeColor:self];else[self.controllingPicker changeDisplayedColorName:self];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _hoverPencil:] ea=0x183b299f0 end=0x183b29ae0
- (void)_hoverPencil:(UIColoredPencil *)pencil {
    if(_hoveredPencil!=pencil){UIColoredPencil *old=_hoveredPencil;_hoveredPencil=pencil;if(pencil!=_selectedPencil)_didHoverOutsideSelectedPencil=YES;
        NSMutableArray *changed=[[NSMutableArray alloc]initWithCapacity:2];if(old)[changed addObject:old];if(pencil)[changed addObject:pencil];[self _updateFramesForPencils:changed duration:.12];[self.controllingPicker changeDisplayedColorName:self];}
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _calculateFrameForPencil:] ea=0x183b29ae0 end=0x183b29b30
- (CGRect)_calculateFrameForPencil:(UIColoredPencil *)pencil {
    NSInteger row,column;[self _row:&row column:&column ofPencil:pencil];return[self _calculateFrameForPencil:pencil atRow:row column:column];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _calculateFrameForPencil:atRow:column:] ea=0x183b29b30 end=0x183b29d70
- (CGRect)_calculateFrameForPencil:(UIColoredPencil *)pencil atRow:(NSInteger)row column:(NSInteger)column {
    // BINNOTE: the UIKit resource contract fixes the recovered80x576 drawing coordinates;
    // custom providers must not depend on loading an unrelated bundled Snow image.
    const CGSize imageSize = {80,576};
    CGFloat width=self.bounds.size.width/12.0+.7;
    CGFloat rowPitch=self.bounds.size.height/4.553191489361702;
    CGFloat lift=width*.7894736842105263;
    CGFloat y=fma((double)row,rowPitch,fmax(lift+-16.0,0.0));
    CGFloat hoverLift=lift*(self.lowerHoveredPencil?.4:1.0);
    if(_hoveredPencil==pencil){if(_selectedPencil!=pencil)y-=hoverLift;else if(self.selectedPencilStaysUp)y-=lift;else y-=_didHoverOutsideSelectedPencil?hoverLift:0;}
    else if(_selectedPencil==pencil)y-=self.selectedPencilStaysUp?lift:0;
    return CGRectMake((width+-.7)*(double)column,y,width,width/(imageSize.width/imageSize.height));
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _unobscuredFrameOfPencil:] ea=0x183b29d70 end=0x183b29e6c
- (CGRect)_unobscuredFrameOfPencil:(UIColoredPencil *)pencil {
    CGRect frame=[self _frameOfPencil:pencil];for(UIColoredPencil *below=[self _pencilBelow:pencil];below;below=[self _pencilBelow:below]){CGRect next=[self _frameOfPencil:below];if(CGRectIntersectsRect(frame,next))frame.size.height-=CGRectIntersection(frame,next).size.height;}return frame;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _frameOfPencil:] ea=0x183b29e6c end=0x183b29f48
- (CGRect)_frameOfPencil:(UIColoredPencil *)pencil {
    CALayer *layer=[self _layerForPencil:pencil];CGRect rect=[layer convertRect:layer.bounds toLayer:self.layer];CGRect clipping=[self.superview convertRect:self.superview.bounds toView:self];CGRect result=CGRectIntersection(rect,clipping);return CGRectIsNull(result)?CGRectZero:result; // NSIntersectionRect empty result uses zero, rather than CGRectNull.
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilAtViewPoint:] ea=0x183b29f48 end=0x183b2a104
- (UIColoredPencil *)_pencilAtViewPoint:(CGPoint)point {
    for(UIColoredPencil *pencil in _pencils.reverseObjectEnumerator){CGRect frame=[self _frameOfPencil:pencil];if(CGRectContainsPoint(frame,point)&&[pencil.image hitTestRect:(CGRect){point,CGSizeZero}withImageDestinationRect:frame context:NULL hints:nil flipped:self.isFlipped])return pencil;}return nil;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _focusedPencil] ea=0x183b2a104 end=0x183b2a150
- (UIColoredPencil *)_focusedPencil {
    return[self _shouldShowFocusRing]?[self _selectedPencil]:nil;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _hasFocusRing] ea=0x183b2a150 end=0x183b2a198
- (BOOL)_hasFocusRing {
    return self.isFirstResponder; // UIKit responder policy replaces effectiveFocusRingType!=None.
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _shouldShowFocusRing] ea=0x183b2a198 end=0x183b2a1e4
- (BOOL)_shouldShowFocusRing {
    return[self _hasFocusRing]&&self.window.isKeyWindow;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _updateFocusRing] ea=0x183b2a1e4 end=0x183b2a264
- (void)_updateFocusRing {
    UIColoredPencil *pencil=[self _focusedPencil];if(_currentFocusedPencil!=pencil){if(_currentFocusedPencil)[self _removeFocusFromLayer:[self _layerForPencil:_currentFocusedPencil]];if(pencil)[self _addFocusToLayer:[self _layerForPencil:pencil]animate:YES];_currentFocusedPencil=pencil;}
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _addFocusToLayer:] ea=0x183b2a264 end=0x183b2a26c
- (void)_addFocusToLayer:(CALayer *)layer {
    [self _addFocusToLayer:layer animate:NO];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _addFocusToLayer:animate:] ea=0x183b2a26c end=0x183b2a4e0
- (void)_addFocusToLayer:(CALayer *)layer animate:(BOOL)animate {
    // BINMAP-ADAPT: avoid both explicit and implicit focus interpolation on iOS.
    BOOL reduceMotion=UIAccessibilityIsReduceMotionEnabled();
    if(reduceMotion){animate=NO;[layer removeAnimationForKey:@"shadowOpacity"];[layer removeAnimationForKey:@"shadowRadius"];}
    if(![[layer valueForKey:@"hasFocus"]boolValue]){[CATransaction begin];
        if(reduceMotion)[CATransaction setDisableActions:YES];
        UIColor *blue=[UIColor colorWithRed:0 green:.47843137254901963 blue:1 alpha:1];
        if(animate){[CATransaction setDisableActions:YES];layer.shadowOffset=CGSizeMake(0,-3);layer.shadowColor=blue.CGColor;
            CABasicAnimation *opacity=[CABasicAnimation animationWithKeyPath:@"shadowOpacity"];opacity.fromValue=@.2;opacity.toValue=@1;opacity.duration=.25;opacity.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];[layer addAnimation:opacity forKey:@"shadowOpacity"];layer.shadowOpacity=1;
            CABasicAnimation *radius=[CABasicAnimation animationWithKeyPath:@"shadowRadius"];radius.fromValue=@30;radius.toValue=@4;radius.duration=.25;radius.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];[layer addAnimation:radius forKey:@"shadowRadius"];layer.shadowRadius=4;
        }else{layer.shadowColor=blue.CGColor;layer.shadowOpacity=1;layer.shadowRadius=4;layer.shadowOffset=CGSizeMake(0,-3);}
        [CATransaction commit];[layer setValue:@YES forKey:@"hasFocus"];
    }
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _removeFocusFromLayer:] ea=0x183b2a4e0 end=0x183b2a5e0
- (void)_removeFocusFromLayer:(CALayer *)layer {
    [CATransaction begin];[CATransaction setDisableActions:YES];[layer removeAnimationForKey:@"shadowRadius"];[layer removeAnimationForKey:@"shadowOpacity"];layer.shadowColor=UIColor.blackColor.CGColor;NSNumber *preferred=[layer valueForKey:@"preferredShadowOpacity"];layer.shadowOpacity=preferred?preferred.floatValue:.34f;layer.shadowRadius=3;layer.shadowOffset=CGSizeMake(-3,1);[CATransaction setDisableActions:NO];[CATransaction commit];[layer setValue:nil forKey:@"hasFocus"];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilAbove:] ea=0x183b2a5e0 end=0x183b2a630
- (UIColoredPencil *)_pencilAbove:(UIColoredPencil *)pencil {
    NSInteger row,column;[self _row:&row column:&column ofPencil:pencil];return[self _pencilAtRow:row-1 column:column];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilBelow:] ea=0x183b2a630 end=0x183b2a680
- (UIColoredPencil *)_pencilBelow:(UIColoredPencil *)pencil {
    NSInteger row,column;[self _row:&row column:&column ofPencil:pencil];return[self _pencilAtRow:row+1 column:column];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilLeftOf:] ea=0x183b2a680 end=0x183b2a6d0
- (UIColoredPencil *)_pencilLeftOf:(UIColoredPencil *)pencil {
    NSInteger row,column;[self _row:&row column:&column ofPencil:pencil];return[self _pencilAtRow:row column:column-1];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _pencilRightOf:] ea=0x183b2a6d0 end=0x183b2a720
- (UIColoredPencil *)_pencilRightOf:(UIColoredPencil *)pencil {
    NSInteger row,column;[self _row:&row column:&column ofPencil:pencil];return[self _pencilAtRow:row column:column+1];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _bottomMostPencil] ea=0x183b2a720 end=0x183b2a72c
- (UIColoredPencil *)_bottomMostPencil {
    return[self _pencilAtRow:3 column:11];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _topMostPencil] ea=0x183b2a72c end=0x183b2a738
- (UIColoredPencil *)_topMostPencil {
    return[self _pencilAtRow:0 column:0];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _leftMostPencil] ea=0x183b2a738 end=0x183b2a744
- (UIColoredPencil *)_leftMostPencil {
    return[self _pencilAtRow:3 column:0];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView _rightMostPencil] ea=0x183b2a744 end=0x183b2a750
- (UIColoredPencil *)_rightMostPencil {
    return[self _pencilAtRow:0 column:11];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView keyDown:] ea=0x183b2a750 end=0x183b2a794
- (void)keyDown:(UIKeyCommand *)event {
    // NSResponder interpretKeyEvents import becomes UIKit key command interpretation.
    if([event.input isEqual:UIKeyInputUpArrow])[self moveUp:event];else if([event.input isEqual:UIKeyInputDownArrow])[self moveDown:event];else if([event.input isEqual:UIKeyInputLeftArrow])[self moveLeft:event];else if([event.input isEqual:UIKeyInputRightArrow])[self moveRight:event];else if([event.input isEqual:@"\t"]){if(event.modifierFlags&UIKeyModifierShift)[self insertBacktab:event];else[self insertTab:event];}
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView insertTab:] ea=0x183b2a794 end=0x183b2a7ec
- (void)insertTab:(id)sender {
    // BINMAP-ADAPT: the UIKit owner supplies an actual forward focus target.
    if(!self.isFirstResponder||!self.keyboardFocusNavigationHandler)return;
    if(self.keyboardFocusNavigationHandler(NO)&&self.isFirstResponder)[self resignFirstResponder];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView insertBacktab:] ea=0x183b2a7ec end=0x183b2a844
- (void)insertBacktab:(id)sender {
    // BINMAP-ADAPT: backward traversal has its own owner-defined target.
    if(!self.isFirstResponder||!self.keyboardFocusNavigationHandler)return;
    if(self.keyboardFocusNavigationHandler(YES)&&self.isFirstResponder)[self resignFirstResponder];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView moveDown:] ea=0x183b2a844 end=0x183b2a8b4
- (void)moveDown:(id)sender {
    UIColoredPencil *selected=[self _selectedPencil];UIColoredPencil *pencil=selected?[self _pencilBelow:selected]:[self _bottomMostPencil];if(pencil)[self _selectPencil:pencil updateSelection:YES animate:YES];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView moveLeft:] ea=0x183b2a8b4 end=0x183b2a924
- (void)moveLeft:(id)sender {
    UIColoredPencil *selected=[self _selectedPencil];UIColoredPencil *pencil=selected?[self _pencilLeftOf:selected]:[self _leftMostPencil];if(pencil)[self _selectPencil:pencil updateSelection:YES animate:YES];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView moveRight:] ea=0x183b2a924 end=0x183b2a994
- (void)moveRight:(id)sender {
    UIColoredPencil *selected=[self _selectedPencil];UIColoredPencil *pencil=selected?[self _pencilRightOf:selected]:[self _rightMostPencil];if(pencil)[self _selectPencil:pencil updateSelection:YES animate:YES];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView moveUp:] ea=0x183b2a994 end=0x183b2aa04
- (void)moveUp:(id)sender {
    UIColoredPencil *selected=[self _selectedPencil];UIColoredPencil *pencil=selected?[self _pencilAbove:selected]:[self _topMostPencil];if(pencil)[self _selectPencil:pencil updateSelection:YES animate:YES];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityAttributeNames] ea=0x183b2d854 end=0x183b2d8e4
- (NSArray *)colorPanelAccessibilityAttributeNames {
    static NSArray *attributes;static dispatch_once_t once;
    // BINMAP-BLOCK: invoke_ea=0x183b2d8e4 parent=-[NSColorPickerPencilView accessibilityAttributeNames] reconstructed_as=block_literal
    dispatch_once(&once,^{attributes=@[@"AXRole",@"AXChildren",@"AXDescription",@"AXValue"];});return attributes; // UIKit imported base attributes replace AppKit super array.
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityRoleAttribute] ea=0x183b2d93c end=0x183b2d94c
- (NSString *)colorPanelAccessibilityRoleAttribute {
    return @"AXRadioGroup";
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityChildrenAttribute] ea=0x183b2d94c end=0x183b2d950
- (NSArray *)colorPanelAccessibilityChildrenAttribute {
    return[self _pencils];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityLabel] ea=0x183b2d950 end=0x183b2d964
- (NSString *)accessibilityLabel {
    return @"Pencils";
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityValueAttribute] ea=0x183b2d964 end=0x183b2d968
- (id)colorPanelAccessibilityValueAttribute {
    return[self _selectedPencil];
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityIsValueAttributeSettable] ea=0x183b2d968 end=0x183b2d970
- (BOOL)colorPanelAccessibilityIsValueAttributeSettable {
    return NO;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityIsIgnored] ea=0x183b2d970 end=0x183b2d978
- (BOOL)colorPanelAccessibilityIsIgnored {
    return NO;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityHitTest:] ea=0x183b2d978 end=0x183b2d9fc
- (id)colorPanelAccessibilityHitTest:(CGPoint)point {
    CGPoint local=[self convertPoint:point fromView:nil];UIColoredPencil *pencil=[self _pencilAtViewPoint:local];return pencil?:self; // Public UIKit screen-coordinate bridge replaces NSAccessibilityUnignoredDescendant.
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPencilView accessibilityFocusedUIElement] ea=0x183b2d9fc end=0x183b2da48
- (id)colorPanelAccessibilityFocusedUIElement {
    return[self _focusedPencil]?:self; // UIKit container is imported superclass focus fallback.
}
// BINMAP-ADAPT: UIColorPickerPencilView.layoutSubviews
- (void)layoutSubviews { [super layoutSubviews];[self layout]; }
// BINMAP-ADAPT: UIColorPickerPencilView.canBecomeFirstResponder
- (BOOL)canBecomeFirstResponder { return[self acceptsFirstResponder]; }
// BINMAP-ADAPT: UIColorPickerPencilView.didMoveToWindow
- (void)didMoveToWindow { [super didMoveToWindow];[self updateTrackingAreas];[self _windowChangedKeyState]; }
// BINMAP-ADAPT: UIColorPickerPencilView.touchesBegan:withEvent:
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [super touchesBegan:touches withEvent:event];[self becomeFirstResponder];[self mouseDown:touches.anyObject]; }
// BINMAP-ADAPT: UIColorPickerPencilView.touchesMoved:withEvent:
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [super touchesMoved:touches withEvent:event];[self mouseDragged:touches.anyObject]; }
// BINMAP-ADAPT: UIColorPickerPencilView.touchesEnded:withEvent:
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self mouseUp:touches.anyObject];
    // Touch has no desktop mouse-exit event. Only a live hover recognizer may
    // retain preview after contact ends; the recovered selection is unchanged.
    UIColoredPencil *hovered=nil;
    if(@available(iOS 13.0,*)){if(_hoverRecognizer.state==UIGestureRecognizerStateBegan||_hoverRecognizer.state==UIGestureRecognizerStateChanged){CGPoint point=[_hoverRecognizer locationInView:self];if(CGRectContainsPoint(self.bounds,point))hovered=[self _pencilAtViewPoint:point];}}
    [self _hoverPencil:hovered];[super touchesEnded:touches withEvent:event];
}
// BINMAP-ADAPT: UIColorPickerPencilView.touchesCancelled:withEvent:
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UIColoredPencil *hovered=nil;
    if(@available(iOS 13.0,*)){if(_hoverRecognizer.state==UIGestureRecognizerStateBegan||_hoverRecognizer.state==UIGestureRecognizerStateChanged){CGPoint point=[_hoverRecognizer locationInView:self];if(CGRectContainsPoint(self.bounds,point))hovered=[self _pencilAtViewPoint:point];}}
    [self _hoverPencil:hovered];[super touchesCancelled:touches withEvent:event];
}
// BINMAP-ADAPT: UIColorPickerPencilView.keyCommands
- (NSArray<UIKeyCommand *> *)keyCommands {
    NSMutableArray *commands=[NSMutableArray arrayWithArray:@[[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(keyDown:)],[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(keyDown:)],[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(keyDown:)],[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(keyDown:)]]];
    if(self.keyboardFocusNavigationHandler)[commands addObjectsFromArray:@[[UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:0 action:@selector(keyDown:)],[UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:UIKeyModifierShift action:@selector(keyDown:)]]];
    return commands;
}
// BINMAP-ADAPT: UIColorPickerPencilView.hoverGesture:
- (void)hoverGesture:(UIHoverGestureRecognizer *)gesture API_AVAILABLE(ios(13.0)) { if(gesture.state==UIGestureRecognizerStateEnded||gesture.state==UIGestureRecognizerStateCancelled)[self mouseExited:gesture];else{CGPoint point=[gesture locationInView:self];[self _hoverPencil:CGRectContainsPoint(self.bounds,point)?[self _pencilAtViewPoint:point]:nil];} }
// BINMAP-ADAPT: UIColorPickerPencilView.accessibilityElements
- (NSArray *)accessibilityElements { return[self colorPanelAccessibilityChildrenAttribute]; }
@end

@implementation UIImage (UIColorPencilHitTesting)
// BINMAP: original=AppKit ida_name=-[NSImage hitTestRect:withImageDestinationRect:context:hints:flipped:] ea=0x183c2a144 end=0x183c2a3c8
- (BOOL)hitTestRect:(CGRect)rect withImageDestinationRect:(CGRect)destination context:(CGContextRef)context hints:(NSDictionary *)hints flipped:(BOOL)flipped {
    CGFloat scale=context?hypot(CGContextGetCTM(context).a,CGContextGetCTM(context).b):UIScreen.mainScreen.scale;
    if(CGSizeEqualToSize(rect.size,CGSizeZero)){
        // Original context/hints transform query defaults to screen backing scale.
        CGAffineTransform transform=context?CGContextGetCTM(context):CGAffineTransformMakeScale(scale,scale);
        CGAffineTransform inverse=CGAffineTransformInvert(transform);rect.size=CGSizeMake(inverse.a+inverse.c,inverse.b+inverse.d);
    }
    CGRect intersection=CGRectIntersection(rect,destination);if(CGRectIsEmpty(intersection))return NO;
    // BINNOTE: public CG snapshot replaces NSCGImageSnapshotRep. Native measured
    // snapshot uses outward device-pixel dimensions, fractional origin CTM,
    // 16-bit floating components and Copy composition. Any nonzero byte hits.
    size_t width=(size_t)(ceil(CGRectGetMaxX(intersection)*scale)-floor(CGRectGetMinX(intersection)*scale));
    size_t height=(size_t)(ceil(CGRectGetMaxY(intersection)*scale)-floor(CGRectGetMinY(intersection)*scale)),row=width*8;
    NSMutableData *data=[NSMutableData dataWithLength:row*height];CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
    CGContextRef snapshot=CGBitmapContextCreate(data.mutableBytes,width,height,16,row,space,kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents|kCGBitmapByteOrder16Little);CGColorSpaceRelease(space);
    if(!snapshot)return NO;
    CGContextScaleCTM(snapshot,scale,flipped?-scale:scale);
    CGContextTranslateCTM(snapshot,-intersection.origin.x,flipped?-CGRectGetMaxY(intersection):-intersection.origin.y);
    if(flipped){CGContextTranslateCTM(snapshot,0,2*destination.origin.y+destination.size.height);CGContextScaleCTM(snapshot,1,-1);}
    CGContextSetBlendMode(snapshot,kCGBlendModeCopy);CGContextSetInterpolationQuality(snapshot,kCGInterpolationHigh);
    CGContextDrawImage(snapshot,destination,self.CGImage);CGContextRelease(snapshot);
    const UInt8 *bytes=data.bytes;BOOL hit=NO;
    for(size_t y=0;y<height&&!hit;y++)for(size_t x=0;x<row;x++)if(bytes[y*row+x]){hit=YES;break;}
    return hit;
}
@end
#endif
