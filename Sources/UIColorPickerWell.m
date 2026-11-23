#import "UIColorPickerWell.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface UIColorPickerWellVisualStyle : UIView
- (instancetype)initWithColorWell:(UIColorPickerWell *)colorWell;
- (void)setSelectedColor:(nullable UIColor *)selectedColor notifyingPicker:(BOOL)notifyingPicker;
- (CGSize)intrinsicSizeWithinSize:(CGSize)size;
@property (nonatomic, weak) UIColorPickerWell *colorWell;
@property (nonatomic, strong, nullable) UIColor *selectedColor;
@property (nonatomic, strong, nullable) NSString *pickerTitle;
@property (nonatomic) BOOL supportsAlpha;
@property (nonatomic) BOOL wantsSystemDragAndDrop;
@property (nonatomic) BOOL wantsExtraTouchInsets;
@end

@interface UIColorPickerWellGradientView : UIView
- (void)gradientCommonInit;
@end

@interface UIColorPickerWelliOSVisualStyle : UIColorPickerWellVisualStyle {
@public
    UIImageView *_gradientView;
    UIView *_borderView;
    UIButton *_button;
@private
    BOOL _isSelected;
    UIColorPickerWellGradientView *_rectangularGradientView;
    UIView *_alphaBackgroundView;
    CAShapeLayer *_alphaContrastLayer;
}
- (void)touchDown:(id)sender;
- (void)touchUp:(id)sender;
- (CGFloat)widthForTraitCollection:(UITraitCollection *)traits;
- (void)invokeColorPicker:(id)sender;
@end

@interface UIColorPickerWell () <UIColorPanelViewControllerDelegate, UIDragInteractionDelegate, UIDropInteractionDelegate>
- (void)pickerWellCommonInit;
- (void)setSelectedColor:(nullable UIColor *)color notifyingPicker:(BOOL)notifyingPicker sendingAction:(BOOL)sendingAction;
- (UIControlEvents)pickerActionEvents;
- (BOOL)pickerPrefersFixedWidth;
- (BOOL)pickerPrefersFixedHeight;
- (CGSize)pickerIntrinsicSizeWithinSize:(CGSize)size;
- (CGFloat)pickerWidthForTraitCollection:(UITraitCollection *)traits;
- (void)invokeColorPicker:(nullable id)sender;
- (void)setPickerTitle:(nullable NSString *)title;
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)picker API_AVAILABLE(ios(14.0));
@end

@implementation UIColorPickerWellVisualStyle

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle initWithColorWell:] ea=0x1837b9e6c end=0x1837b9ee4
- (instancetype)initWithColorWell:(UIColorPickerWell *)colorWell {
    if ((self = [super init])) [self setColorWell:colorWell];
    return self;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setSelectedColor:notifyingPicker:] ea=0x1837b9ee4 end=0x1837b9fc0
- (void)setSelectedColor:(UIColor *)selectedColor notifyingPicker:(BOOL)notifyingPicker {
    [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self file:@"_UIColorWellVisualStyle.m" lineNumber:22 description:@"%@ should provide an implementation for %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle intrinsicSizeWithinSize:] ea=0x1837b9fc0 end=0x1837ba09c
- (CGSize)intrinsicSizeWithinSize:(CGSize)size {
    [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self file:@"_UIColorWellVisualStyle.m" lineNumber:26 description:@"%@ should provide an implementation for %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];
    return CGSizeZero;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle colorWell] ea=0x1837ba09c end=0x1837ba0d0
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setColorWell:] ea=0x1837ba0d0 end=0x1837ba0e4
@synthesize colorWell = _colorWell;
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle selectedColor] ea=0x1837ba0e4 end=0x1837ba0f4
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setSelectedColor:] ea=0x1837ba0f4 end=0x1837ba108
@synthesize selectedColor = _selectedColor;
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle pickerTitle] ea=0x1837ba108 end=0x1837ba118
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setPickerTitle:] ea=0x1837ba118 end=0x1837ba12c
@synthesize pickerTitle = _pickerTitle;
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle supportsAlpha] ea=0x1837ba12c end=0x1837ba13c
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setSupportsAlpha:] ea=0x1837ba13c end=0x1837ba14c
@synthesize supportsAlpha = _supportsAlpha;
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle wantsSystemDragAndDrop] ea=0x1837ba14c end=0x1837ba15c
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setWantsSystemDragAndDrop:] ea=0x1837ba15c end=0x1837ba16c
@synthesize wantsSystemDragAndDrop = _wantsSystemDragAndDrop;
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle wantsExtraTouchInsets] ea=0x1837ba16c end=0x1837ba17c
// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle setWantsExtraTouchInsets:] ea=0x1837ba17c end=0x1837ba18c
@synthesize wantsExtraTouchInsets = _wantsExtraTouchInsets;

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWellVisualStyle .cxx_destruct] ea=0x1837ba18c end=0x1837ba1ec
// ARC generates the original weak color-well teardown and strong color/title releases.
@end

@implementation UIColorPickerWellGradientView {
    CAGradientLayer *_alphaLayer;
}

// BINMAP: original=UIKitCore ida_name=+[_UIColorWellConicalGradientBackgroundView layerClass] ea=0x1823eeeec end=0x1823eeef8
+ (Class)layerClass {
    return CAGradientLayer.class;
}

// BINMAP: original=UIKitCore ida_name=-[_UIColorWellConicalGradientBackgroundView _commonInit] ea=0x1823eeef8 end=0x1823ef488
- (void)gradientCommonInit {
    CAGradientLayer *layer = (CAGradientLayer *)self.layer;
    layer.cornerRadius = CGRectGetHeight(layer.bounds) * 0.5;
    layer.startPoint = CGPointMake(0.5, 0.5);
    layer.endPoint = CGPointMake(0.5, 0);
    layer.type = kCAGradientLayerConic;
    layer.colors = @[
        (__bridge id)[UIColor colorWithDisplayP3Red:1 green:1 blue:0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:1 green:0.5 blue:0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:1 green:0 blue:0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:1 green:0 blue:1 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:0 green:0 blue:1 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:0 green:1 blue:1 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:0 green:1 blue:0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:0.63 green:0.88 blue:0.03 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithDisplayP3Red:1 green:1 blue:0 alpha:1].CGColor,
    ];
    _alphaLayer = [CAGradientLayer layer];
    _alphaLayer.cornerRadius = layer.cornerRadius;
    _alphaLayer.type = kCAGradientLayerRadial;
    _alphaLayer.startPoint = CGPointMake(0.5, 0.5);
    _alphaLayer.endPoint = CGPointMake(1, 1);
    _alphaLayer.anchorPoint = CGPointZero;
    [layer addSublayer:_alphaLayer];
    _alphaLayer.bounds = layer.bounds;
    _alphaLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:1 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithWhite:1 alpha:0.3].CGColor,
    ];
}

// BINMAP: original=UIKitCore ida_name=-[_UIColorWellConicalGradientBackgroundView initWithCoder:] ea=0x1823ef488 end=0x1823ef4e4
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) [self gradientCommonInit];
    return self;
}

// BINMAP: original=UIKitCore ida_name=-[_UIColorWellConicalGradientBackgroundView initWithFrame:] ea=0x1823ef4e4 end=0x1823ef540
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) [self gradientCommonInit];
    return self;
}

// BINMAP: original=UIKitCore ida_name=-[_UIColorWellConicalGradientBackgroundView layoutSubviews] ea=0x1823ef540 end=0x1823ef674
- (void)layoutSubviews {
    [super layoutSubviews];
    CALayer *layer = self.layer;
    // BINMAP-ADAPT: explicit rounded-rectangle appearance extension.
    if (((UIColorPickerWellVisualStyle *)self.superview).colorWell.shape == UIColorPickerWellShapeRoundedRectangle) {
        [UIColorPanelAppearance applyCornersToView:self radius:6 useSPI:NO];
        // The parent smooth outline clips both gradients as one background.
        _alphaLayer.cornerRadius = 0;
    } else {
        if ([layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"]) layer.mask = nil;
        if (@available(iOS 13.0, *)) layer.cornerCurve = kCACornerCurveCircular;
        layer.masksToBounds = NO;
        layer.cornerRadius = CGRectGetHeight(self.bounds) * 0.5;
        _alphaLayer.cornerRadius = layer.cornerRadius;
    }
    _alphaLayer.bounds = layer.bounds;
}

// BINMAP: original=UIKitCore ida_name=-[_UIColorWellConicalGradientBackgroundView .cxx_destruct] ea=0x1823ef674 end=0x1823ef688
// ARC generates the original strong alpha-layer release; no handwritten destructor.
@end

@implementation UIColorPickerWelliOSVisualStyle

// BINMAP-ADAPT: UIColorPickerWelliOSVisualStyle.circularBackgroundImage manifest=reimpl/uikit_well_ios15_rendering_api_manifest.json
+ (UIImage *)circularBackgroundImage {
    static UIImage *background;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // The center is visible when the well has no selection. Draw the entire disk
        // in encoded sRGB with an angular hue ramp and saturation growing with radius.
        static const uint8_t rim[8][3] = {
            {232, 54, 54}, {182, 54, 208}, {99, 55, 231}, {54, 189, 233},
            {53, 232, 130}, {129, 230, 51}, {230, 226, 55}, {233, 156, 54}
        };
        const size_t size = 108;
        const double radius = size * 0.5;
        CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGContextRef context = CGBitmapContextCreate(NULL, size, size, 8, size * 4, space,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(space);
        if (!context) return;
        CGRect bounds = CGRectMake(0, 0, size, size);
        CGContextClearRect(context, bounds);
        // Match the reference image's antialiasing around the 108-pixel disk.
        CGContextSetFlatness(context, 0.6);
        CGContextFillEllipseInRect(context, bounds);
        uint8_t *pixels = CGBitmapContextGetData(context);
        for (size_t y = 0; y < size; y++) {
            for (size_t x = 0; x < size; x++) {
                uint8_t *pixel = pixels + (y * size + x) * 4;
                if (!pixel[3]) continue;
                double dx = x + 0.5 - radius, dy = y + 0.5 - radius;
                double radial = fmin(1, hypot(dx, dy) / radius);
                // The reference hue ramp is centered half a point below and to the right.
                double sector = atan2(dy - 1.5, dx - 1.5) * (4 / M_PI);
                if (sector < 0) sector += 8;
                NSUInteger first = (NSUInteger)sector % 8, next = (first + 1) % 8;
                double weight = sector - floor(sector);
                for (NSUInteger c = 0; c < 3; c++) {
                    double edge = rim[first][c] + weight * (rim[next][c] - rim[first][c]);
                    pixel[c] = (uint8_t)lround((231 + radial * (edge - 231)) * pixel[3] / 255.0);
                }
            }
        }
        CGImageRef image = CGBitmapContextCreateImage(context);
        if (image) {
            background = [UIImage imageWithCGImage:image scale:3 orientation:UIImageOrientationUp];
            CGImageRelease(image);
        }
        CGContextRelease(context);
    });
    return background;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle initWithColorWell:] ea=0x183999a50 end=0x183999cd8
- (instancetype)initWithColorWell:(UIColorPickerWell *)colorWell {
    if ((self = [super initWithColorWell:colorWell])) {
        [self setWantsSystemDragAndDrop:YES];
        _button = [UIButton buttonWithType:UIButtonTypeSystem];
        _gradientView = [[UIImageView alloc] initWithImage:[UIColorPickerWelliOSVisualStyle circularBackgroundImage]];
        _borderView = [UIView new];
        if (@available(iOS 13.0, *)) {
            _borderView.backgroundColor = UIColor.systemBackgroundColor;
        } else {
            _borderView.backgroundColor = UIColor.whiteColor;
        }
        _button.backgroundColor = self.selectedColor;
        [self addSubview:_gradientView];
        [self addSubview:_borderView];
        [self addSubview:_button];
        _gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_button addTarget:self action:@selector(invokeColorPicker:) forControlEvents:UIControlEventTouchUpInside];
        [_button addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
        [_button addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchDragExit | UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [self setWantsExtraTouchInsets:YES];
    }
    return self;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle setSelectedColor:] ea=0x183999cd8 end=0x183999d2c
- (void)setSelectedColor:(UIColor *)selectedColor {
    [super setSelectedColor:selectedColor];
    [self setNeedsLayout];
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle layoutSubviews] ea=0x183999d2c end=0x18399a0a4
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = MIN(MAX(CGRectGetWidth(self.bounds), 28), 36);
    CGFloat height = MIN(MAX(CGRectGetHeight(self.bounds), 28), 36);
    CGRect frame = CGRectMake(CGRectGetMidX(self.bounds) - width * 0.5, CGRectGetMidY(self.bounds) - height * 0.5, width, height);
    BOOL rectangle = self.colorWell.shape == UIColorPickerWellShapeRoundedRectangle;
    // BINMAP-ADAPT: the explicitly selected rectangle shape keeps its procedural renderer.
    if (rectangle) {
        frame = self.bounds;
        if (!_rectangularGradientView) {
            _rectangularGradientView = [[UIColorPickerWellGradientView alloc] initWithFrame:frame];
            _rectangularGradientView.userInteractionEnabled = NO;
            _rectangularGradientView.accessibilityElementsHidden = YES;
            [self insertSubview:_rectangularGradientView belowSubview:_borderView];
        }
        _rectangularGradientView.frame = frame;
        [_rectangularGradientView setNeedsLayout];
    }
    _gradientView.hidden = rectangle;
    _rectangularGradientView.hidden = !rectangle;
    _gradientView.frame = frame;
    CGRect borderFrame = CGRectInset(frame, rectangle ? 2 : 3, rectangle ? 2 : 3);
    CGRect buttonFrame = CGRectInset(frame, rectangle ? 4 : 5, rectangle ? 4 : 5);
    _button.frame = buttonFrame;
    _borderView.frame = borderFrame;
    if (rectangle) {
        [UIColorPanelAppearance applyCornersToView:_button radius:2 useSPI:NO];
    } else {
        // Keep the original individual nil-tolerant sends: a UIView-decoded
        // archived style can have restored subviews but no owned view ivars.
        CALayer *layer = _button.layer;
        if ([layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"]) layer.mask = nil;
        if (@available(iOS 13.0, *)) layer.cornerCurve = kCACornerCurveCircular;
        layer.masksToBounds = NO;
        layer.cornerRadius = CGRectGetWidth(buttonFrame) * 0.5;
    }
    _button.backgroundColor = self.selectedColor;
    if (rectangle) {
        [UIColorPanelAppearance applyCornersToView:_borderView radius:4 useSPI:NO];
    } else {
        CALayer *layer = _borderView.layer;
        if ([layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"]) layer.mask = nil;
        if (@available(iOS 13.0, *)) layer.cornerCurve = kCACornerCurveCircular;
        layer.masksToBounds = NO;
        layer.cornerRadius = CGRectGetWidth(borderFrame) * 0.5;
    }
    _borderView.alpha = self.selectedColor ? 1 : 0;
    self.alpha = _isSelected ? 0.5 : 1;

    // BINMAP-ADAPT: optional reference backing below the entire unchanged color.
    UIColorPickerWellCenterAlphaAppearance appearance = self.colorWell.centerAlphaAppearance;
    // Opaque colors need no backing; hiding it also preserves their antialiased edge.
    BOOL hasBacking = self.selectedColor && CGColorGetAlpha(self.selectedColor.CGColor) < 1 && (appearance == UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground || appearance == UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground);
    if (hasBacking && !_alphaBackgroundView) {
        _alphaBackgroundView = [UIView new];
        _alphaBackgroundView.backgroundColor = UIColor.whiteColor;
        _alphaBackgroundView.userInteractionEnabled = NO;
        _alphaBackgroundView.accessibilityElementsHidden = YES;
        _alphaBackgroundView.clipsToBounds = YES;
        _alphaContrastLayer = [CAShapeLayer layer];
        [_alphaBackgroundView.layer addSublayer:_alphaContrastLayer];
        [self insertSubview:_alphaBackgroundView belowSubview:_button];
    }
    _alphaBackgroundView.hidden = !hasBacking;
    if (_alphaBackgroundView) {
        _alphaBackgroundView.frame = _button.frame;
        if (rectangle) {
            [UIColorPanelAppearance applyCornersToView:_alphaBackgroundView radius:2 useSPI:NO];
        } else {
            CALayer *layer = _alphaBackgroundView.layer;
            if ([layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"]) layer.mask = nil;
            if (@available(iOS 13.0, *)) layer.cornerCurve = kCACornerCurveCircular;
            layer.cornerRadius = CGRectGetWidth(_alphaBackgroundView.frame) * 0.5;
        }
        _alphaContrastLayer.frame = _alphaBackgroundView.bounds;
        CGMutablePathRef contrast = CGPathCreateMutable();
        CGFloat width = CGRectGetWidth(_alphaBackgroundView.bounds);
        CGFloat height = CGRectGetHeight(_alphaBackgroundView.bounds);
        if (appearance == UIColorPickerWellCenterAlphaAppearanceCheckerboardBackground) {
            _alphaContrastLayer.fillColor = [UIColor colorWithWhite:0.75 alpha:1].CGColor;
            // A zero-size control can be laid out before its constraints resolve.
            if (width > 0 && height > 0) {
                CGFloat cell = MIN(width, height) / 3;
                for (NSUInteger row = 0; row * cell < height; row++) {
                    for (NSUInteger column = 0; column * cell < width; column++) {
                        if ((row + column) % 2) CGPathAddRect(contrast, NULL, CGRectMake(column * cell, row * cell, cell, cell));
                    }
                }
            }
        } else {
            _alphaContrastLayer.fillColor = UIColor.blackColor.CGColor;
            CGPathMoveToPoint(contrast, NULL, 0, 0);
            CGPathAddLineToPoint(contrast, NULL, width, 0);
            CGPathAddLineToPoint(contrast, NULL, 0, height);
            CGPathCloseSubpath(contrast);
        }
        _alphaContrastLayer.path = contrast;
        CGPathRelease(contrast);
    }
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle touchDown:] ea=0x18399a0a4 end=0x18399a0c0
- (void)touchDown:(id)sender {
    _isSelected = YES;
    [self setNeedsLayout];
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle touchUp:] ea=0x18399a0c0 end=0x18399a0d8
- (void)touchUp:(id)sender {
    _isSelected = NO;
    [self setNeedsLayout];
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle _widthForTraitCollection:] ea=0x18399a0d8 end=0x18399a110
- (CGFloat)widthForTraitCollection:(UITraitCollection *)traits {
    return traits.horizontalSizeClass == UIUserInterfaceSizeClassCompact ? 28 : 36;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle intrinsicSizeWithinSize:] ea=0x18399a110 end=0x18399a178
- (CGSize)intrinsicSizeWithinSize:(CGSize)size {
    CGFloat width = [self widthForTraitCollection:self.traitCollection];
    return CGSizeMake(width, width);
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle traitCollectionDidChange:] ea=0x18399a178 end=0x18399a1dc
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle _invokeColorPicker:] ea=0x18399a1dc end=0x18399a230
- (void)invokeColorPicker:(id)sender {
    // BINMAP-ADAPT: the root owns the public UIKit presentation and older-system bridge.
    [self.colorWell invokeColorPicker:sender];
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[_UIColorWelliOSVisualStyle .cxx_destruct] ea=0x18399a230 end=0x18399a294
// ARC generates releases for the original three views and the optional appearance extensions.
@end

@implementation UIColorPickerWell {
    UIColorPickerWelliOSVisualStyle *_style;
    __weak UIViewController *_colorPicker;
    UIDragInteraction *_dragInteraction;
    UIDropInteraction *_dropInteraction;
    UIColor *_selectedColor;
    NSString *_title;
    BOOL _supportsAlpha;
    UIColorPickerWellShape _shape;
    UIColorPickerWellCenterAlphaAppearance _centerAlphaAppearance;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[UIColorWell _commonInit] ea=0x182edc434 end=0x182edc5b0
- (void)pickerWellCommonInit {
    _supportsAlpha = YES;
    // BINMAP-ADAPT: direct iOS style replaces UIKit's private platform-style factory.
    _style = [[UIColorPickerWelliOSVisualStyle alloc] initWithColorWell:self];
    _style.selectedColor = _selectedColor;
    _style.pickerTitle = _title;
    _style.supportsAlpha = _supportsAlpha;
    _style.frame = self.bounds;
    [self addSubview:_style];
    // BINMAP-ADAPT: public drag/drop delegates and centered minimum touch region.
    _dragInteraction = [[UIDragInteraction alloc] initWithDelegate:self];
    [self addInteraction:_dragInteraction];
    _dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
    [self addInteraction:_dropInteraction];

    // BINMAP-ADAPT: public equivalents of UIView's recovered fixed-size priority hooks.
    [self setContentHuggingPriority:[self pickerPrefersFixedWidth] ? 750 : 250 forAxis:UILayoutConstraintAxisHorizontal];
    [self setContentHuggingPriority:[self pickerPrefersFixedHeight] ? 750 : 250 forAxis:UILayoutConstraintAxisVertical];
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    _style.accessibilityElementsHidden = YES;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell initWithFrame:] ea=0x182242e4c end=0x182242ea8
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) [self pickerWellCommonInit];
    return self;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[UIColorWell initWithCoder:] ea=0x182edc60c end=0x182edc758
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        // BINMAP-ADAPT: public custom controls encode implementation subviews;
        // native UIColorWell omits its style. Preserve host subviews and their z-order.
        NSArray<UIView *> *decodedSubviews = self.subviews;
        NSUInteger styleIndex = NSNotFound;
        for (NSUInteger index = 0; index < decodedSubviews.count; index++) {
            UIView *view = decodedSubviews[index];
            if ([view isKindOfClass:UIColorPickerWellVisualStyle.class]) {
                if (styleIndex == NSNotFound) styleIndex = index;
                [view removeFromSuperview];
            }
        }
        [self pickerWellCommonInit];
        if (styleIndex != NSNotFound) [self insertSubview:_style atIndex:styleIndex];
        [self setSelectedColor:[coder decodeObjectOfClass:UIColor.class forKey:@"UIColorWellColor"]];
        [self setPickerTitle:[coder decodeObjectOfClass:NSString.class forKey:@"UIColorWellTitle"]];
        [self setSupportsAlpha:[coder decodeBoolForKey:@"UIColorWellSupportsAlpha"]];
        // BINMAP-ADAPT: component-only appearance keys; absent keys decode as zero.
        [self setShape:(UIColorPickerWellShape)[coder decodeIntegerForKey:@"UIColorPickerWellShape"]];
        [self setCenterAlphaAppearance:(UIColorPickerWellCenterAlphaAppearance)[coder decodeIntegerForKey:@"UIColorPickerWellCenterAlphaAppearance"]];
    }
    return self;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell encodeWithCoder:] ea=0x182242fd8 end=0x1822430a8
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_selectedColor forKey:@"UIColorWellColor"];
    [coder encodeObject:_title forKey:@"UIColorWellTitle"];
    [coder encodeBool:_supportsAlpha forKey:@"UIColorWellSupportsAlpha"];
    // BINMAP-ADAPT: preserve independent appearance extensions when archived.
    [coder encodeInteger:_shape forKey:@"UIColorPickerWellShape"];
    [coder encodeInteger:_centerAlphaAppearance forKey:@"UIColorPickerWellCenterAlphaAppearance"];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell setPickerTitle:] ea=0x1822430a8 end=0x182243134
- (void)setPickerTitle:(NSString *)title {
    _title = title;
    _style.pickerTitle = title;
    _colorPicker.title = title;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell setSupportsAlpha:] ea=0x182243134 end=0x182243198
- (void)setSupportsAlpha:(BOOL)supportsAlpha {
    _supportsAlpha = supportsAlpha;
    _style.supportsAlpha = supportsAlpha;
    if (@available(iOS 14.0, *)) {
        ((UIColorPickerViewController *)_colorPicker).supportsAlpha = supportsAlpha;
    } else {
        // BINMAP-ADAPT: old component's opacity editing capability; selectedColor stays untouched.
        ((UIColorPanelViewController *)_colorPicker).supportsAlpha = supportsAlpha;
    }
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell setSelectedColor:] ea=0x182243198 end=0x1822431ac
- (void)setSelectedColor:(UIColor *)selectedColor {
    [self setSelectedColor:selectedColor notifyingPicker:YES sendingAction:NO];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell _setSelectedColor:notifyingPicker:sendingAction:] ea=0x1822431ac end=0x1822432d0
- (void)setSelectedColor:(UIColor *)color notifyingPicker:(BOOL)notifyingPicker sendingAction:(BOOL)sendingAction {
    [self willChangeValueForKey:@"selectedColor"];
    _selectedColor = color;
    [self didChangeValueForKey:@"selectedColor"];
    _style.selectedColor = _selectedColor;
    [self setNeedsLayout];
    if (notifyingPicker) {
        if (@available(iOS 14.0, *)) {
            ((UIColorPickerViewController *)_colorPicker).selectedColor = _selectedColor;
        } else if (_selectedColor) {
            // BINMAP-ADAPT: the old panel's UIColorValue transport is nonnull; nil remains in the well.
            ((UIColorPanelViewController *)_colorPicker).selectedColor = [[UIColorValue alloc] initWithCGColor:_selectedColor.CGColor];
        }
    }
    if (sendingAction) [self sendActionsForControlEvents:[self pickerActionEvents]];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell _controlEventsForActionTriggered] ea=0x1822432d0 end=0x1822432d8
- (UIControlEvents)pickerActionEvents {
    return UIControlEventValueChanged;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell _contentHuggingDefault_isUsuallyFixedWidth] ea=0x1822432d8 end=0x1822432e0
- (BOOL)pickerPrefersFixedWidth {
    return YES;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell _contentHuggingDefault_isUsuallyFixedHeight] ea=0x1822432e0 end=0x1822432e8
- (BOOL)pickerPrefersFixedHeight {
    return YES;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell _intrinsicSizeWithinSize:] ea=0x1822432e8 end=0x182243350
- (CGSize)pickerIntrinsicSizeWithinSize:(CGSize)size {
    // BINMAP-ADAPT: sizing is owned by the recovered iOS15 visual style.
    return [_style intrinsicSizeWithinSize:size];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell sizeThatFits:] ea=0x182243350 end=0x18224335c
- (CGSize)sizeThatFits:(CGSize)size {
    return [self pickerIntrinsicSizeWithinSize:size];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell _widthForTraitCollection:] ea=0x18224335c end=0x182243394
- (CGFloat)pickerWidthForTraitCollection:(UITraitCollection *)traits {
    return traits.horizontalSizeClass == UIUserInterfaceSizeClassCompact ? 28 : 36;
}

// BINMAP: original=UIKitCore.iOS15 ida_name=-[UIColorWell layoutSubviews] ea=0x182edca40 end=0x182edcb50
- (void)layoutSubviews {
    [super layoutSubviews];
    _style.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell invokeColorPicker:] ea=0x1822435a4 end=0x1822436e4
- (void)invokeColorPicker:(id)sender {
    UIViewController *picker;
    UIViewController *presentation;
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *systemPicker = [UIColorPickerViewController new];
        systemPicker.selectedColor = _selectedColor;
        systemPicker.supportsAlpha = _supportsAlpha;
        systemPicker.title = _title;
        systemPicker.delegate = (id<UIColorPickerViewControllerDelegate>)self;
        picker = systemPicker;
        presentation = picker;
    } else {
        // BINMAP-ADAPT: nonnull presentation seed only. The well retains nil until user selection.
        UIColor *initialColor = _selectedColor;
        if (!initialColor) initialColor = self.traitCollection.displayGamut == UIDisplayGamutP3
            ? [UIColor colorWithDisplayP3Red:0 green:0 blue:0 alpha:1]
            : [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
        UIColorPanelConfiguration *configuration = [UIColorPanelConfiguration new];
        configuration.supportsAlpha = _supportsAlpha;
        UIColorPanelViewController *panel = [[UIColorPanelViewController alloc] initWithColor:[[UIColorValue alloc] initWithCGColor:initialColor.CGColor] configuration:configuration];
        panel.title = _title;
        panel.delegate = self;
        picker = panel;
        // BINMAP-ADAPT: the old panel owns its Done action in a navigation item.
        presentation = [[UINavigationController alloc] initWithRootViewController:panel];
    }
    presentation.modalPresentationStyle = UIModalPresentationPopover;
    presentation.popoverPresentationController.sourceView = self;
    // BINMAP-ADAPT: public responder traversal replaces UIView's private ancestor-controller query.
    UIResponder *ancestor = self.nextResponder;
    while (ancestor && ![ancestor isKindOfClass:UIViewController.class]) ancestor = ancestor.nextResponder;
    [(UIViewController *)ancestor presentViewController:presentation animated:YES completion:nil];
    _colorPicker = picker;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell traitCollectionDidChange:] ea=0x1822436e4 end=0x182243748
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell colorPickerViewControllerDidSelectColor:] ea=0x182243748 end=0x1822437b4
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)picker {
    [self setSelectedColor:picker.selectedColor notifyingPicker:NO sendingAction:YES];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell dragInteraction:itemsForBeginningSession:] ea=0x1822437b4 end=0x1822438cc
- (NSArray<UIDragItem *> *)dragInteraction:(UIDragInteraction *)interaction itemsForBeginningSession:(id<UIDragSession>)session {
    NSItemProvider *provider = [[NSItemProvider alloc] initWithObject:self.selectedColor];
    return @[[[UIDragItem alloc] initWithItemProvider:provider]];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell dragInteraction:previewForLiftingItem:session:] ea=0x1822438cc end=0x182243920
- (UITargetedDragPreview *)dragInteraction:(UIDragInteraction *)interaction previewForLiftingItem:(UIDragItem *)item session:(id<UIDragSession>)session {
    return [[UITargetedDragPreview alloc] initWithView:_style->_button];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell dropInteraction:canHandleSession:] ea=0x182243920 end=0x182243998
- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session {
    return [session canLoadObjectsOfClass:UIColor.class];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell dropInteraction:sessionDidUpdate:] ea=0x182243998 end=0x1822439d8
- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session {
    return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell dropInteraction:performDrop:] ea=0x1822439d8 end=0x182243a98
- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session {
    // BINMAP: original=UIKitCore ida_name=___43-[UIColorWell dropInteraction:performDrop:]_block_invoke ea=0x182243a98 end=0x182243b08
    [session loadObjectsOfClass:UIColor.class completion:^(NSArray<__kindof id<NSItemProviderReading>> *objects) {
        [self setSelectedColor:objects.firstObject notifyingPicker:YES sendingAction:YES];
    }];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell selectedColor] ea=0x182243b18 end=0x182243b28
- (UIColor *)selectedColor {
    return _selectedColor;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell title] ea=0x182243b28 end=0x182243b38
- (NSString *)title {
    return _title;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell setTitle:] ea=0x182243b38 end=0x182243b44
- (void)setTitle:(NSString *)title {
    _title = [title copy];
    _style.pickerTitle = _title;
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell supportsAlpha] ea=0x182243b44 end=0x182243b54
- (BOOL)supportsAlpha {
    return _supportsAlpha;
}

// BINMAP-ADAPT: UIColorPickerWell.intrinsicContentSize
- (CGSize)intrinsicContentSize {
    return [self pickerIntrinsicSizeWithinSize:CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric)];
}

// BINMAP-ADAPT: UIColorPickerWell.pointInside:withEvent:
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect touchBounds = self.bounds;
    if (_style.wantsExtraTouchInsets) {
        CGFloat width = MAX(CGRectGetWidth(touchBounds), 44);
        CGFloat height = MAX(CGRectGetHeight(touchBounds), 44);
        touchBounds = CGRectMake(CGRectGetMidX(touchBounds) - width * 0.5, CGRectGetMidY(touchBounds) - height * 0.5, width, height);
    }
    return [super pointInside:point withEvent:event] || CGRectContainsPoint(touchBounds, point);
}

// BINMAP-ADAPT: UIColorPickerWell.hitTest:withEvent:
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (!self.enabled) return nil;
    if (hit && [self pointInside:point withEvent:event]) return _style->_button;
    return hit;
}

// BINMAP-ADAPT: UIColorPickerWell.colorPanel:didSelectColor:
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {
    // The old panel retains source alpha during RGB editing. Enforce only the new user selection's capability.
    UIColorValue *pickedColor = _supportsAlpha ? color : [color copyWithAlpha:1];
    if (!_supportsAlpha) panel.selectedColor = pickedColor;
    [self setSelectedColor:pickedColor.UIColor notifyingPicker:NO sendingAction:YES];
}

// BINMAP-ADAPT: UIColorPickerWell.colorPanelDidFinish:
- (void)colorPanelDidFinish:(UIColorPanelViewController *)panel {
    [panel dismissViewControllerAnimated:YES completion:nil];
}

// BINMAP-ADAPT: UIColorPickerWell.accessibilityLabel
- (NSString *)accessibilityLabel {
    return [super accessibilityLabel] ?: _title ?: [UIColorPanelAppearance localizedString:@"Choose Color"];
}

// BINMAP-ADAPT: UIColorPickerWell.accessibilityValue
- (NSString *)accessibilityValue {
    NSString *provided = [super accessibilityValue];
    if (provided) return provided;
    if (!_selectedColor) return [UIColorPanelAppearance localizedString:@"None"];
    CGColorRef color = _selectedColor.CGColor;
    UIColorPanelColorProfile *profile = [[UIColorPanelColorProfile alloc] initWithColorSpace:CGColorGetColorSpace(color) displayName:nil];
    NSMutableArray *parts = [NSMutableArray arrayWithObject:profile.displayName ?: [UIColorPanelAppearance localizedString:@"Original ICC profile"]];
    const CGFloat *components = CGColorGetComponents(color);
    NSUInteger count = CGColorGetNumberOfComponents(color);
    for (NSUInteger index = 0; index + 1 < count; index++)
        [parts addObject:[UIColorPanelAppearance formatNumber:components[index] significantDigits:6]];
    NSNumberFormatter *percent = [NSNumberFormatter new];
    percent.numberStyle = NSNumberFormatterPercentStyle;
    percent.maximumFractionDigits = 3;
    percent.usesGroupingSeparator = NO;
    [parts addObject:[NSString stringWithFormat:@"%@: %@", [UIColorPanelAppearance localizedString:@"Opacity"], [percent stringFromNumber:@(CGColorGetAlpha(color))]]];
    return [parts componentsJoinedByString:@", "];
}

// BINMAP-ADAPT: UIColorPickerWell.accessibilityActivate
- (BOOL)accessibilityActivate {
    if (!self.enabled) return NO;
    [self invokeColorPicker:self];
    return YES;
}

// BINMAP-ADAPT: UIColorPickerWell.shape
- (UIColorPickerWellShape)shape {
    return _shape;
}

// BINMAP-ADAPT: UIColorPickerWell.setShape:
- (void)setShape:(UIColorPickerWellShape)shape {
    _shape = shape;
    [_style setNeedsLayout];
    [self setNeedsLayout];
}

// BINMAP-ADAPT: UIColorPickerWell.centerAlphaAppearance
- (UIColorPickerWellCenterAlphaAppearance)centerAlphaAppearance {
    return _centerAlphaAppearance;
}

// BINMAP-ADAPT: UIColorPickerWell.setCenterAlphaAppearance:
- (void)setCenterAlphaAppearance:(UIColorPickerWellCenterAlphaAppearance)centerAlphaAppearance {
    _centerAlphaAppearance = centerAlphaAppearance;
    [_style setNeedsLayout];
    [self setNeedsLayout];
}

// BINMAP: original=UIKitCore ida_name=-[UIColorWell .cxx_destruct] ea=0x182243b54 end=0x182243bf4
// ARC generates strong releases and the weak picker teardown, including extension-owned layers.
@end
