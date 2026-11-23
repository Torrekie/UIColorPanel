#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import "UIColorPickerPencils.h"
#import "UIColorPickerPencilView.h"
#import "UIColorPanel.h"
@implementation UIColorPickerPencils {
    UIView *_containerView;
    UILabel *_colorNameTextField;
    UIColorPickerPencilView *_pencilView;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils initWithPickerMask:colorPanel:] ea=0x183b27424 end=0x183b27470
- (instancetype)initWithPickerMask:(UIColorPanelOptions)mask colorPanel:(id)panel {
    self=[super init];
    if(self)self.colorPanel=panel;
    return (mask & UIColorPanelCrayonModeMask)?self:nil;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils dealloc] ea=0x183b27470 end=0x183b274d4
- (void)dealloc {
    _colorNameTextField=nil;_containerView=nil;_pencilView=nil; // ARC supplies superclass/ivar release.
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils provideNewButtonImage] ea=0x183b274d4 end=0x183b274e8
- (UIImage *)provideNewButtonImage {
    // BINNOTE: Draw the six miniature pencils and their sleeve on the original 24pt canvas.
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat new];
        format.scale = 2;
        format.preferredRange = UIGraphicsImageRendererFormatRangeStandard;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(24,24) format:format];
        image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *output) {
            CGContextRef context = output.CGContext;
            CGContextScaleCTM(context, 0.5, 0.5);
            CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
            // Edge, midtone, highlight and far edge of each miniature's lacquer.
            static const uint8_t lacquer[][4][3] = {
                {{126,29,32}, {203,46,49}, {247,66,70}, {196,42,46}},
                {{130,112,15}, {216,185,26}, {241,223,61}, {211,181,26}},
                {{12,97,13}, {26,177,28}, {40,216,42}, {24,172,29}},
                {{2,97,146}, {17,171,249}, {64,211,254}, {12,164,245}},
                {{1,13,124}, {7,39,227}, {39,80,251}, {5,29,198}},
                {{125,15,125}, {204,30,204}, {247,45,247}, {195,28,195}}
            };
            static const uint8_t lead[][2][3] = {
                {{168,7,15},{246,12,26}}, {{146,108,4},{215,159,6}},
                {{20,146,24},{37,219,40}}, {{2,145,225},{58,213,255}},
                {{6,19,168},{22,72,254}}, {{170,25,170},{247,40,247}}
            };
            static const uint8_t wood[4][3] = {{165,139,108},{227,203,169},{249,231,190},{210,184,147}};
            const CGFloat stops[] = {0.08, 0.42, 0.59, 0.74, 0.92};
            CGContextSetGrayFillColor(context, 0, 0.08);
            CGContextFillRect(context, CGRectMake(5,16,38,15));
            for (NSUInteger i = 0; i < 6; i++) {
                CGFloat x = 6 + 6*i;
                CGContextSaveGState(context);
                CGContextMoveToPoint(context, x+2.05, 6.25);
                CGContextAddLineToPoint(context, x+3.95, 6.25);
                CGContextAddLineToPoint(context, x+4.05, 7.5);
                CGContextAddLineToPoint(context, x+6, 15);
                CGContextAddLineToPoint(context, x+6, 31);
                CGContextAddLineToPoint(context, x, 31);
                CGContextAddLineToPoint(context, x, 15);
                CGContextAddLineToPoint(context, x+1.95, 7.5);
                CGContextClosePath(context);
                CGContextClip(context);
                CGContextBeginTransparencyLayer(context, NULL);
                // Overlay the wood and then the lead so fractional edges remain opaque.
                for (NSInteger band = 2; band >= 0; band--) {
                    static const CGFloat lowerEdge[] = {9.68, 15.24, 31};
                    const uint8_t (*colors)[3] = band == 0 ? lead[i] : band == 1 ? wood : lacquer[i];
                    CGFloat components[20];
                    size_t count = band == 0 ? 2 : 5;
                    for (size_t s = 0; s < count; s++) {
                        NSUInteger colorIndex = count == 5 && s >= 3 ? s-1 : s;
                        for (NSUInteger c = 0; c < 3; c++) components[s*4+c] = colors[colorIndex][c]/255.;
                        components[s*4+3] = 1;
                    }
                    CGGradientRef gradient = CGGradientCreateWithColorComponents(space, components, count == 2 ? NULL : stops, count);
                    CGContextSaveGState(context);
                    CGContextClipToRect(context, CGRectMake(x, 6, 6, lowerEdge[band]-6));
                    CGFloat inset = band == 0 ? 1.7 : 0;
                    CGContextDrawLinearGradient(context, gradient, CGPointMake(x+inset,0), CGPointMake(x+6-inset,0),
                                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
                    CGContextRestoreGState(context);
                    CGGradientRelease(gradient);
                }
                CGContextEndTransparencyLayer(context);
                CGContextRestoreGState(context);
            }
            CGColorSpaceRelease(space);
            // Silver sleeve with a light face and a one-pixel shadow under the folded edge.
            CGContextSetGrayFillColor(context, 0, 0.12);
            CGContextFillRect(context, CGRectMake(6,30,36,1));
            CGContextSetGrayFillColor(context, 189/255., 1);
            CGContextFillRect(context, CGRectMake(5,31,38,13));
            CGContextFillRect(context, CGRectMake(5.23,44,37.54,1));
            CGContextSetGrayFillColor(context, 236/255., 1);
            CGContextFillRect(context, CGRectMake(6,31,36,12));
            CGContextSetGrayFillColor(context, 134/255., 1);
            CGContextFillRect(context, CGRectMake(6,44,36,1));
        }];
    });
    return image;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils provideNewView:] ea=0x183b275d4 end=0x183b276c4
- (UIView *)provideNewView:(BOOL)initial {
    if(initial) {
        // BINNOTE: explicit UIKit constraints replace the original compiled NSNib;
        // native logical frame228x263, label(18,12,192,16), pencils(0,49,228,214).
        _containerView=[[UIView alloc]initWithFrame:CGRectMake(0,0,228,263)];
        _containerView.clipsToBounds=YES;
        _colorNameTextField=[UILabel new];_colorNameTextField.text=@"";
        _colorNameTextField.font=[UIFont systemFontOfSize:13];_colorNameTextField.textAlignment=NSTextAlignmentCenter;
        _colorNameTextField.translatesAutoresizingMaskIntoConstraints=NO;
        _pencilView=[[UIColorPickerPencilView alloc]initWithFrame:CGRectMake(0,49,228,214)];
        _pencilView.controllingPicker=self;_pencilView.imageProvider=self.imageProvider;
        if(self.imageProvider)[_pencilView _updatePencilsFromColorList];
        _pencilView.translatesAutoresizingMaskIntoConstraints=NO;
        [_containerView addSubview:_colorNameTextField];[_containerView addSubview:_pencilView];
        [NSLayoutConstraint activateConstraints:@[
            [_colorNameTextField.topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:12],
            [_colorNameTextField.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:18],
            [_colorNameTextField.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-18],
            [_colorNameTextField.heightAnchor constraintEqualToConstant:16],
            [_pencilView.topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:49],
            [_pencilView.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor],
            [_pencilView.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor],
            [_pencilView.bottomAnchor constraintEqualToAnchor:_containerView.bottomAnchor]]];
        _containerView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return self.containerView;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils changeColor:] ea=0x183b274e8 end=0x183b2756c
- (void)changeColor:(UIColorPickerPencilView *)sender {
    id panel=self.colorPanel;UIColorValue *color=sender.color;
    self.colorNameTextField.text=self.pencilView.localizedColorNameComponent?:@"";
    // BINNOTE: callback is the embedded-controller substitute for imported NSColorPanel.setColor:.
    if(self.selectionHandler)self.selectionHandler(color);
    else if([panel respondsToSelector:@selector(setColorValue:)])[panel setColorValue:color];
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils changeDisplayedColorName:] ea=0x183b2756c end=0x183b275c0
- (void)changeDisplayedColorName:(UIColorPickerPencilView *)sender {
    self.colorNameTextField.text=self.pencilView.localizedColorNameComponent?:@"";
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils supportsMode:] ea=0x183b275c0 end=0x183b275cc
- (BOOL)supportsMode:(UIColorPanelMode)mode {
    return mode==7;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils currentMode] ea=0x183b275cc end=0x183b275d4
- (UIColorPanelMode)currentMode {
    return 7;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils _insertionOrder] ea=0x183b276c4 end=0x183b276d0
- (double)_insertionOrder {
    return .54;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils minContentSize] ea=0x183b276d0 end=0x183b276e0
- (CGSize)minContentSize {
    return CGSizeZero;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils buttonToolTip] ea=0x183b276e0 end=0x183b276f4
- (NSString *)buttonToolTip {
    return @"Pencils";
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils setColor:] ea=0x183b276f4 end=0x183b2772c
- (void)setColor:(UIColorValue *)color {
    [self.pencilView setColor:color];
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils colorNameTextField] ea=0x183b2772c end=0x183b2773c
- (UILabel *)colorNameTextField {
    return _colorNameTextField;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils setColorNameTextField:] ea=0x183b2773c end=0x183b27748
- (void)setColorNameTextField:(UILabel *)value {
    _colorNameTextField=value;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils containerView] ea=0x183b27748 end=0x183b27758
- (UIView *)containerView {
    return _containerView;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils setContainerView:] ea=0x183b27758 end=0x183b27764
- (void)setContainerView:(UIView *)value {
    _containerView=value;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils pencilView] ea=0x183b27764 end=0x183b27774
- (UIColorPickerPencilView *)pencilView {
    return _pencilView;
}
// BINMAP: original=AppKit ida_name=-[NSColorPickerPencils setPencilView:] ea=0x183b27774 end=0x183b27780
- (void)setPencilView:(UIColorPickerPencilView *)value {
    _pencilView=value;
}
@end
#endif
