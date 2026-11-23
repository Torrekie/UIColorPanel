#import "UIColorPickerGridView.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPickerColorAccessibility.h"
#import <math.h>

// BINMAP-DATA: original=ColorPicker14_5-x86_64 initializer=sub_100005960
// ea=0x100005960 end=0x100008d91. The binary's array headers contain 10 rows,
// 12 columns. Every SomeColor initializer passes profile 0 (sRGB), alpha 1.
// Decimal constants below are the binary doubles, not image samples.
static const CGFloat UIColorPickerGridComponents[120][4] = {
    { 1.0, 1.0, 1.0, 1.0 }, // 0:0
    { 0.9215686274509803, 0.9215686274509803, 0.9215686274509803, 1.0 }, // 0:1
    { 0.8392156862745098, 0.8392156862745098, 0.8392156862745098, 1.0 }, // 0:2
    { 0.7607843137254902, 0.7607843137254902, 0.7607843137254902, 1.0 }, // 0:3
    { 0.6784313725490196, 0.6784313725490196, 0.6784313725490196, 1.0 }, // 0:4
    { 0.6, 0.6, 0.6, 1.0 }, // 0:5
    { 0.5215686274509804, 0.5215686274509804, 0.5215686274509804, 1.0 }, // 0:6
    { 0.4392156862745098, 0.4392156862745098, 0.4392156862745098, 1.0 }, // 0:7
    { 0.3607843137254902, 0.3607843137254902, 0.3607843137254902, 1.0 }, // 0:8
    { 0.2784313725490196, 0.2784313725490196, 0.2784313725490196, 1.0 }, // 0:9
    { 0.2, 0.2, 0.2, 1.0 }, // 0:10
    { 0.0, 0.0, 0.0, 1.0 }, // 0:11
    { 0.0, 0.21568627450980393, 0.2901960784313726, 1.0 }, // 1:0
    { 0.00392156862745098, 0.11372549019607843, 0.3411764705882353, 1.0 }, // 1:1
    { 0.06666666666666667, 0.0196078431372549, 0.23137254901960785, 1.0 }, // 1:2
    { 0.1803921568627451, 0.023529411764705882, 0.23921568627450981, 1.0 }, // 1:3
    { 0.23529411764705882, 0.027450980392156862, 0.10588235294117647, 1.0 }, // 1:4
    { 0.3607843137254902, 0.027450980392156862, 0.00392156862745098, 1.0 }, // 1:5
    { 0.35294117647058826, 0.10980392156862745, 0.0, 1.0 }, // 1:6
    { 0.34509803921568627, 0.2, 0.0, 1.0 }, // 1:7
    { 0.33725490196078434, 0.23921568627450981, 0.0, 1.0 }, // 1:8
    { 0.4, 0.3803921568627451, 0.0, 1.0 }, // 1:9
    { 0.30980392156862746, 0.3333333333333333, 0.01568627450980392, 1.0 }, // 1:10
    { 0.14901960784313725, 0.24313725490196078, 0.058823529411764705, 1.0 }, // 1:11
    { 0.0, 0.30196078431372547, 0.396078431372549, 1.0 }, // 2:0
    { 0.00392156862745098, 0.1843137254901961, 0.4823529411764706, 1.0 }, // 2:1
    { 0.10196078431372549, 0.0392156862745098, 0.3215686274509804, 1.0 }, // 2:2
    { 0.27058823529411763, 0.050980392156862744, 0.34901960784313724, 1.0 }, // 2:3
    { 0.3333333333333333, 0.06274509803921569, 0.1607843137254902, 1.0 }, // 2:4
    { 0.5137254901960784, 0.06666666666666667, 0.0, 1.0 }, // 2:5
    { 0.4823529411764706, 0.1607843137254902, 0.0, 1.0 }, // 2:6
    { 0.47843137254901963, 0.2901960784313726, 0.0, 1.0 }, // 2:7
    { 0.47058823529411764, 0.34509803921568627, 0.0, 1.0 }, // 2:8
    { 0.5529411764705883, 0.5254901960784314, 0.00784313725490196, 1.0 }, // 2:9
    { 0.43529411764705883, 0.4627450980392157, 0.0392156862745098, 1.0 }, // 2:10
    { 0.2196078431372549, 0.3411764705882353, 0.10196078431372549, 1.0 }, // 2:11
    { 0.00392156862745098, 0.43137254901960786, 0.5607843137254902, 1.0 }, // 3:0
    { 0.0, 0.25882352941176473, 0.6627450980392157, 1.0 }, // 3:1
    { 0.17254901960784313, 0.03529411764705882, 0.4666666666666667, 1.0 }, // 3:2
    { 0.3803921568627451, 0.09411764705882353, 0.48627450980392156, 1.0 }, // 3:3
    { 0.4745098039215686, 0.10196078431372549, 0.23921568627450981, 1.0 }, // 3:4
    { 0.7098039215686275, 0.10196078431372549, 0.0, 1.0 }, // 3:5
    { 0.6784313725490196, 0.24313725490196078, 0.0, 1.0 }, // 3:6
    { 0.6627450980392157, 0.40784313725490196, 0.0, 1.0 }, // 3:7
    { 0.6509803921568628, 0.4823529411764706, 0.00392156862745098, 1.0 }, // 3:8
    { 0.7686274509803922, 0.7372549019607844, 0.0, 1.0 }, // 3:9
    { 0.6078431372549019, 0.6470588235294118, 0.054901960784313725, 1.0 }, // 3:10
    { 0.3058823529411765, 0.47843137254901963, 0.15294117647058825, 1.0 }, // 3:11
    { 0.0, 0.5490196078431373, 0.7058823529411765, 1.0 }, // 4:0
    { 0.0, 0.33725490196078434, 0.8392156862745098, 1.0 }, // 4:1
    { 0.21568627450980393, 0.10196078431372549, 0.5803921568627451, 1.0 }, // 4:2
    { 0.47843137254901963, 0.12941176470588237, 0.6196078431372549, 1.0 }, // 4:3
    { 0.6, 0.1411764705882353, 0.30980392156862746, 1.0 }, // 4:4
    { 0.8862745098039215, 0.1411764705882353, 0.0, 1.0 }, // 4:5
    { 0.8549019607843137, 0.3176470588235294, 0.0, 1.0 }, // 4:6
    { 0.8274509803921568, 0.5137254901960784, 0.00392156862745098, 1.0 }, // 4:7
    { 0.8196078431372549, 0.615686274509804, 0.00392156862745098, 1.0 }, // 4:8
    { 0.9607843137254902, 0.9254901960784314, 0.0, 1.0 }, // 4:9
    { 0.7647058823529411, 0.8196078431372549, 0.09019607843137255, 1.0 }, // 4:10
    { 0.4, 0.615686274509804, 0.20392156862745098, 1.0 }, // 4:11
    { 0.0, 0.6313725490196078, 0.8470588235294118, 1.0 }, // 5:0
    { 0.0, 0.3803921568627451, 0.996078431372549, 1.0 }, // 5:1
    { 0.30196078431372547, 0.13333333333333333, 0.6980392156862745, 1.0 }, // 5:2
    { 0.596078431372549, 0.16470588235294117, 0.7372549019607844, 1.0 }, // 5:3
    { 0.7254901960784313, 0.17647058823529413, 0.36470588235294116, 1.0 }, // 5:4
    { 1.0, 0.25098039215686274, 0.08235294117647059, 1.0 }, // 5:5
    { 1.0, 0.41568627450980394, 0.0, 1.0 }, // 5:6
    { 1.0, 0.6705882352941176, 0.00392156862745098, 1.0 }, // 5:7
    { 0.9921568627450981, 0.7803921568627451, 0.0, 1.0 }, // 5:8
    { 0.996078431372549, 0.984313725490196, 0.2549019607843137, 1.0 }, // 5:9
    { 0.8509803921568627, 0.9254901960784314, 0.21568627450980393, 1.0 }, // 5:10
    { 0.4627450980392157, 0.7333333333333333, 0.25098039215686274, 1.0 }, // 5:11
    { 0.00392156862745098, 0.7803921568627451, 0.9882352941176471, 1.0 }, // 6:0
    { 0.22745098039215686, 0.5294117647058824, 0.996078431372549, 1.0 }, // 6:1
    { 0.3686274509803922, 0.18823529411764706, 0.9215686274509803, 1.0 }, // 6:2
    { 0.7450980392156863, 0.2196078431372549, 0.9529411764705882, 1.0 }, // 6:3
    { 0.9019607843137255, 0.23137254901960785, 0.47843137254901963, 1.0 }, // 6:4
    { 1.0, 0.3843137254901961, 0.3137254901960784, 1.0 }, // 6:5
    { 1.0, 0.5254901960784314, 0.2823529411764706, 1.0 }, // 6:6
    { 0.996078431372549, 0.7058823529411765, 0.24705882352941178, 1.0 }, // 6:7
    { 0.996078431372549, 0.796078431372549, 0.24313725490196078, 1.0 }, // 6:8
    { 1.0, 0.9686274509803922, 0.4196078431372549, 1.0 }, // 6:9
    { 0.8941176470588236, 0.9372549019607843, 0.396078431372549, 1.0 }, // 6:10
    { 0.5882352941176471, 0.8274509803921568, 0.37254901960784315, 1.0 }, // 6:11
    { 0.3215686274509804, 0.8392156862745098, 0.9882352941176471, 1.0 }, // 7:0
    { 0.4549019607843137, 0.6549019607843137, 1.0, 1.0 }, // 7:1
    { 0.5254901960784314, 0.30980392156862746, 0.996078431372549, 1.0 }, // 7:2
    { 0.8274509803921568, 0.3411764705882353, 0.996078431372549, 1.0 }, // 7:3
    { 0.9333333333333333, 0.44313725490196076, 0.6196078431372549, 1.0 }, // 7:4
    { 1.0, 0.5490196078431373, 0.5098039215686274, 1.0 }, // 7:5
    { 1.0, 0.6470588235294118, 0.49019607843137253, 1.0 }, // 7:6
    { 1.0, 0.7803921568627451, 0.4666666666666667, 1.0 }, // 7:7
    { 1.0, 0.8509803921568627, 0.4666666666666667, 1.0 }, // 7:8
    { 1.0, 0.9764705882352941, 0.5803921568627451, 1.0 }, // 7:9
    { 0.9176470588235294, 0.9490196078431372, 0.5607843137254902, 1.0 }, // 7:10
    { 0.6941176470588235, 0.8666666666666667, 0.5450980392156862, 1.0 }, // 7:11
    { 0.5764705882352941, 0.8901960784313725, 0.9921568627450981, 1.0 }, // 8:0
    { 0.6549019607843137, 0.7764705882352941, 1.0, 1.0 }, // 8:1
    { 0.6941176470588235, 0.5490196078431373, 0.996078431372549, 1.0 }, // 8:2
    { 0.8862745098039215, 0.5725490196078431, 0.996078431372549, 1.0 }, // 8:3
    { 0.9568627450980393, 0.6431372549019608, 0.7529411764705882, 1.0 }, // 8:4
    { 1.0, 0.7098039215686275, 0.6862745098039216, 1.0 }, // 8:5
    { 1.0, 0.7725490196078432, 0.6705882352941176, 1.0 }, // 8:6
    { 1.0, 0.8509803921568627, 0.6588235294117647, 1.0 }, // 8:7
    { 0.996078431372549, 0.8941176470588236, 0.6588235294117647, 1.0 }, // 8:8
    { 1.0, 0.984313725490196, 0.7254901960784313, 1.0 }, // 8:9
    { 0.9490196078431372, 0.9686274509803922, 0.7176470588235294, 1.0 }, // 8:10
    { 0.803921568627451, 0.9098039215686274, 0.7098039215686275, 1.0 }, // 8:11
    { 0.796078431372549, 0.9411764705882353, 1.0, 1.0 }, // 9:0
    { 0.8274509803921568, 0.8862745098039215, 1.0, 1.0 }, // 9:1
    { 0.8509803921568627, 0.788235294117647, 0.996078431372549, 1.0 }, // 9:2
    { 0.9372549019607843, 0.792156862745098, 1.0, 1.0 }, // 9:3
    { 0.9764705882352941, 0.8274509803921568, 0.8784313725490196, 1.0 }, // 9:4
    { 1.0, 0.8588235294117647, 0.8470588235294118, 1.0 }, // 9:5
    { 1.0, 0.8862745098039215, 0.8392156862745098, 1.0 }, // 9:6
    { 1.0, 0.9254901960784314, 0.8313725490196079, 1.0 }, // 9:7
    { 1.0, 0.9490196078431372, 0.8352941176470589, 1.0 }, // 9:8
    { 0.996078431372549, 0.9882352941176471, 0.8666666666666667, 1.0 }, // 9:9
    { 0.9686274509803922, 0.9803921568627451, 0.8588235294117647, 1.0 }, // 9:10
    { 0.8745098039215686, 0.9333333333333333, 0.8313725490196079, 1.0 } // 9:11
};

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000171D0 ea=0x1000171d0 end=0x1000172d6
static UIColorValue *UIColorPickerGridSRGBColor(UIColorValue *color) {
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGColorSpaceRef source = CGColorGetColorSpace(color.CGColor);
    if (source && CFEqual(source, space)) {
        CGColorSpaceRelease(space);
        return color;
    }
    CGColorRef converted = CGColorCreateCopyByMatchingToColorSpace(space, kCGRenderingIntentPerceptual, color.CGColor, NULL);
    CGColorSpaceRelease(space);
    // BINNOTE: UIColorValue also admits pattern/unsupported conversion inputs;
    // unlike binary SomeColor's two valid RGB cases, those have no grid selection.
    if (!converted) return nil;
    UIColorValue *result = [[UIColorValue alloc] initWithCGColor:converted];
    CGColorRelease(converted);
    return result;
}

// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_1000173D0 ea=0x1000173d0 end=0x100017461
static BOOL UIColorPickerGridColorsEqual(UIColorValue *left, UIColorValue *right, BOOL compareAlpha) {
    if (!CFEqual(CGColorGetColorSpace(left.CGColor), CGColorGetColorSpace(right.CGColor))) return NO;
    const CGFloat *a = CGColorGetComponents(left.CGColor);
    const CGFloat *b = CGColorGetComponents(right.CGColor);
    return fabs(a[0] - b[0]) < .001 && fabs(a[1] - b[1]) < .001 &&
           fabs(a[2] - b[2]) < .001 && (!compareAlpha || fabs(a[3] - b[3]) < .001);
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100017500 ea=0x100017500 end=0x100017729
static UIColorValue *UIColorPickerGridColorInSelectedSpace(UIColorValue *swatch, UIColorValue *selected) {
    CGColorSpaceRef space = CGColorGetColorSpace(selected.CGColor);
    if (CFEqual(CGColorGetColorSpace(swatch.CGColor), space)) return swatch;
    CGColorRef converted = CGColorCreateCopyByMatchingToColorSpace(space, kCGRenderingIntentPerceptual, swatch.CGColor, NULL);
    // BINNOTE: Original SomeColor supports sRGB/P3. The UIKit value model may carry
    // other CG spaces; preserve that space when conversion succeeds, otherwise
    // leave the selected value unchanged instead of substituting a profile.
    if (!converted) return nil;
    UIColorValue *result = [[UIColorValue alloc] initWithCGColor:converted];
    CGColorRelease(converted);
    return result;
}

@interface UIColorPickerGridAccessibilityElement : UIAccessibilityElement
@property(nonatomic, weak) UIColorPickerGridView *grid;
@property(nonatomic) NSUInteger index;
@end

@interface UIColorPickerGridView ()
@property(nonatomic, strong, readwrite, nullable) UIColorValue *sampledColor;
@property(nonatomic, readwrite, getter=isActive) BOOL active;
@property(nonatomic, strong) NSArray<UIColorValue *> *colors;
@property(nonatomic, strong) NSArray<UIColorPickerGridAccessibilityElement *> *cells;
@property(nonatomic) NSUInteger selectedIndex;
+ (NSArray<UIColorValue *> *)colorTable;
- (void)initializeGrid;
- (void)updateSelection;
- (UIAccessibilityTraits)accessibilityTraitsForColor:(UIColorValue *)color;
- (void)sampleAtPoint:(CGPoint)point;
- (void)endInteraction;
- (BOOL)activateCellAtIndex:(NSUInteger)index;
- (UIBezierPath *)crosshairPathForRect:(CGRect)rect corners:(UIRectCorner)corners;
@end

@implementation UIColorPickerGridAccessibilityElement
// BINMAP-ADAPT: id=grid-uikit-14 manifest=reimpl/grid_api_manifest.json
- (BOOL)accessibilityActivate {
    return [self.grid activateCellAtIndex:self.index];
}
@end

@implementation UIColorPickerGridView

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100005960 ea=0x100005960 end=0x100008d91
+ (NSArray<UIColorValue *> *)colorTable {
    NSMutableArray<UIColorValue *> *colors = [NSMutableArray arrayWithCapacity:120];
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    for (NSUInteger index = 0; index < 120; index++) {
        CGColorRef color = CGColorCreate(space, UIColorPickerGridComponents[index]);
        [colors addObject:[[UIColorValue alloc] initWithCGColor:color]];
        CGColorRelease(color);
    }
    CGColorSpaceRelease(space);
    return colors;
}

// BINMAP-ADAPT: id=grid-uikit-01 manifest=reimpl/grid_api_manifest.json
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) [self initializeGrid];
    return self;
}

// BINMAP-ADAPT: id=grid-uikit-02 manifest=reimpl/grid_api_manifest.json
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) [self initializeGrid];
    return self;
}

// BINMAP-ADAPT: id=grid-uikit-03 manifest=reimpl/grid_api_manifest.json
- (void)initializeGrid {
    _colors = [self.class colorTable];
    _selectedColor = _colors[11];
    _selectedIndex = 11;
    self.opaque = NO;
    self.multipleTouchEnabled = NO;
    self.isAccessibilityElement = NO;
    self.accessibilityIdentifier = @"ui.grid";
    // UIKit adaptation: fix visual/hit order to the recovered matrix's numeric
    // coordinates. SwiftUI ancestor layout-direction behavior is not recreated.
    self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:self.colors.count];
    for (NSUInteger index = 0; index < self.colors.count; index++) {
        UIColorPickerGridAccessibilityElement *element = [[UIColorPickerGridAccessibilityElement alloc] initWithAccessibilityContainer:self];
        element.grid = self;
        element.index = index;
        element.accessibilityLabel = UIColorPickerAXColorStringForColor(self.colors[index].UIColor,1);
        element.accessibilityIdentifier = [NSString stringWithFormat:@"ui.grid.cell.%lu.%lu", (unsigned long)(index / 12), (unsigned long)(index % 12)];
        [elements addObject:element];
    }
    _cells = elements;
    self.accessibilityElements = elements;
    [self updateSelection];
}

// BINMAP-ADAPT: id=grid-uikit-04 manifest=reimpl/grid_api_manifest.json
- (CGSize)intrinsicContentSize {
    // UIKit host sizing uses 26pt preferred cells. Layout and hit testing divide
    // the actual supplied bounds, as the source geometry reader does.
    return CGSizeMake(312, 260);
}

// BINMAP-ADAPT: id=grid-uikit-05 manifest=reimpl/grid_api_manifest.json
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width / 12;
    CGFloat height = self.bounds.size.height / 10;
    for (NSUInteger index = 0; index < self.cells.count; index++) {
        self.cells[index].accessibilityFrameInContainerSpace = CGRectMake(
            self.bounds.origin.x + (index % 12) * width,
            self.bounds.origin.y + (index / 12) * height, width, height);
    }
    [self setNeedsDisplay];
}

// BINMAP-ADAPT: id=grid-uikit-06 manifest=reimpl/grid_api_manifest.json
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [[UIColorPanelAppearance smoothPathForRect:self.bounds radius:8] addClip];
    CGContextSetShouldAntialias(context, NO);
    CGFloat width = self.bounds.size.width / 12;
    CGFloat height = self.bounds.size.height / 10;
    for (NSUInteger index = 0; index < self.colors.count; index++) {
        CGRect cell = CGRectMake(self.bounds.origin.x + (index % 12) * width,
                                 self.bounds.origin.y + (index / 12) * height, width, height);
        CGContextSetFillColorWithColor(context, self.colors[index].CGColor);
        CGContextFillRect(context, cell);
    }
    if (self.selectedIndex != NSNotFound) {
        NSUInteger row = self.selectedIndex / 12, column = self.selectedIndex % 12;
        CGRect cell = CGRectMake(self.bounds.origin.x + column * width,
                                 self.bounds.origin.y + row * height, width, height);
        UIRectCorner corners = 0;
        if (row == 0 && column == 0) corners = UIRectCornerTopLeft;
        else if (row == 0 && column == 11) corners = UIRectCornerTopRight;
        else if (row == 9 && column == 0) corners = UIRectCornerBottomLeft;
        else if (row == 9 && column == 11) corners = UIRectCornerBottomRight;
        CGContextSaveGState(context);
        [[UIColorPanelAppearance smoothPathForRect:cell radius:2] addClip];
        CGContextSetShouldAntialias(context, YES);
        UIColor *stroke;
        if (@available(iOS 13, *)) stroke = UIColor.systemBackgroundColor;
        else stroke = UIColor.whiteColor;
        [stroke setStroke];
        UIBezierPath *path = [self crosshairPathForRect:CGRectInset(cell, 1, 1) corners:corners];
        path.lineWidth = 3;
        // BINNOTE: Source SwiftUI applies padding +/-1 and a separate 2pt
        // rounded clip. UIKit preserves its border/corner semantics; raster
        // alignment is an explicit native drawing adaptation.
        [path stroke];
        CGContextRestoreGState(context);
    }
    CGContextRestoreGState(context);
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100010610 ea=0x100010610 end=0x100010722
- (UIBezierPath *)crosshairPathForRect:(CGRect)rect corners:(UIRectCorner)corners {
    if (!corners) return [UIColorPanelAppearance smoothPathForRect:rect radius:0];
    CGRect bounds = CGRectStandardize(rect);
    UIBezierPath *smooth = [UIColorPanelAppearance smoothPathForRect:bounds radius:8];
    UIBezierPath *path = [UIBezierPath bezierPath];
    // BINMAP-ADAPT: grid-smooth-corner-element-block manifest=reimpl/grid_api_manifest.json
    // Keep the binary's corner mask while using the shared authored curve.
    CGPathApplyWithBlock(smooth.CGPath, ^(const CGPathElement *element) {
        const CGPoint *points = element->points;
        switch (element->type) {
            case kCGPathElementMoveToPoint: [path moveToPoint:points[0]]; break;
            case kCGPathElementAddLineToPoint: [path addLineToPoint:points[0]]; break;
            case kCGPathElementAddQuadCurveToPoint:
                [path addQuadCurveToPoint:points[1] controlPoint:points[0]]; break;
            case kCGPathElementAddCurveToPoint: {
                BOOL right = points[0].x > CGRectGetMidX(bounds);
                BOOL bottom = points[0].y > CGRectGetMidY(bounds);
                UIRectCorner corner = bottom ? (right ? UIRectCornerBottomRight : UIRectCornerBottomLeft) : (right ? UIRectCornerTopRight : UIRectCornerTopLeft);
                if (corners & corner) [path addCurveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]];
                else if (points[2].x == CGRectGetMinX(bounds) || points[2].x == CGRectGetMaxX(bounds) || points[2].y == CGRectGetMinY(bounds) || points[2].y == CGRectGetMaxY(bounds)) {
                    [path addLineToPoint:CGPointMake(right ? CGRectGetMaxX(bounds) : CGRectGetMinX(bounds), bottom ? CGRectGetMaxY(bounds) : CGRectGetMinY(bounds))];
                    [path addLineToPoint:points[2]];
                }
                break;
            }
            case kCGPathElementCloseSubpath: [path closePath]; break;
        }
    });
    return path;
}

// BINMAP-ADAPT: id=grid-uikit-07 manifest=reimpl/grid_api_manifest.json
- (void)setSelectedColor:(UIColorValue *)selectedColor {
    _selectedColor = selectedColor;
    [self updateSelection];
}

// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_1000059A0 ea=0x1000059a0 end=0x100005e5e
- (void)updateSelection {
    UIColorValue *normalized = UIColorPickerGridSRGBColor(self.selectedColor);
    _selectedIndex = NSNotFound;
    if (normalized) {
        for (NSUInteger index = 0; index < self.colors.count; index++) {
            if (UIColorPickerGridColorsEqual(normalized, self.colors[index], NO)) {
                _selectedIndex = index;
                break;
            }
        }
    }
    for (NSUInteger index = 0; index < self.cells.count; index++) {
        self.cells[index].accessibilityTraits = [self accessibilityTraitsForColor:self.colors[index]];
    }
    [self setNeedsDisplay];
}

// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_100006740 ea=0x100006740 end=0x100006959
- (UIAccessibilityTraits)accessibilityTraitsForColor:(UIColorValue *)color {
    UIColorValue *normalized = UIColorPickerGridSRGBColor(self.selectedColor);
    // Original15.5 keeps AX RGBA matching distinct from the visible RGB crosshair.
    BOOL selected = normalized && UIColorPickerGridColorsEqual(normalized, color, YES);
    return UIAccessibilityTraitButton | (selected ? UIAccessibilityTraitSelected : 0);
}

// BINMAP: original=ColorPicker15_5-x86_64 ida_name=sub_10000B350 ea=0x10000b350 end=0x10000b669
- (void)sampleAtPoint:(CGPoint)point {
    NSInteger row = (NSInteger)floor((point.y - self.bounds.origin.y) / (self.bounds.size.height / 10));
    NSInteger column = (NSInteger)floor((point.x - self.bounds.origin.x) / (self.bounds.size.width / 12));
    row = MAX(0, MIN(9, row));
    column = MAX(0, MIN(11, column));
    UIColorValue *sample = UIColorPickerGridColorInSelectedSpace(self.colors[(NSUInteger)row * 12 + (NSUInteger)column], self.selectedColor);
    if (!sample) return;
    // Original15.5 replaces component3 after profile conversion;14.5 stayed opaque.
    // The existing canonical-model operation replaces SomeColor's value transport.
    sample = [sample copyWithAlpha:CGColorGetAlpha(self.selectedColor.CGColor)];
    _sampledColor = sample;
    self.selectedColor = sample;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

// BINMAP-ADAPT: id=grid-uikit-08 manifest=reimpl/grid_api_manifest.json
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (!self.enabled || self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return NO;
    _active = YES;
    _sampledColor = nil;
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if (!self.active) return NO;
    [self sampleAtPoint:[touch locationInView:self]];
    return self.active;
}

// BINMAP-ADAPT: id=grid-uikit-09 manifest=reimpl/grid_api_manifest.json
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (!self.active) return NO;
    [self sampleAtPoint:[touch locationInView:self]];
    return self.active;
}

// BINMAP-ADAPT: id=grid-uikit-10 manifest=reimpl/grid_api_manifest.json
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self endInteraction];
}

// BINMAP-ADAPT: id=grid-uikit-11 manifest=reimpl/grid_api_manifest.json
- (void)cancelTrackingWithEvent:(UIEvent *)event {
    // UIKit cancellation ends the edit; prior onChanged samples stay committed.
    [self endInteraction];
}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10000B190 ea=0x10000b190 end=0x10000b226
- (void)endInteraction {
    if (!self.active) return;
    _active = NO;
    [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
}

// BINMAP-ADAPT: id=grid-uikit-12 manifest=reimpl/grid_api_manifest.json
- (BOOL)activateCellAtIndex:(NSUInteger)index {
    if (!self.enabled || self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return NO;
    _active = YES;
    _sampledColor = nil;
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if (!self.active) return NO;
    CGPoint point = CGPointMake(self.bounds.origin.x + ((index % 12) + .5) * self.bounds.size.width / 12,
                                self.bounds.origin.y + ((index / 12) + .5) * self.bounds.size.height / 10);
    [self sampleAtPoint:point];
    [self endInteraction];
    return YES;
}

// BINMAP-ADAPT: id=grid-uikit-13 manifest=reimpl/grid_api_manifest.json
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}
@end
