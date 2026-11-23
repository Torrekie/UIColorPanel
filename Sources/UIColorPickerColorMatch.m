#import "UIColorPickerColorMatch.h"
#import "UIColorValue+AppKitEquality.h"
#import <math.h>

// BINMAP: original=AppKit ida_name=sub_183B31F7C ea=0x183b31f7c end=0x183b32148
static double UIColorPickerRGBToLab(double *lightness, double *a, double *b, double red, double green, double blue) {
    double r = pow(red, 1.8), g = pow(green, 1.8), bl = pow(blue, 1.8);
    double x = fma(bl, 0.183, fma(r, 0.418, g * 0.363)) / 0.9642;
    double y = fma(bl, 0.072, fma(r, 0.213, g * 0.715));
    double z = fma(bl, 0.72, fma(r, 0.015, g * 0.09));
    double fx = x <= 0.008856 ? fma(x, 7.787, 0.13793103448275862) : pow(x, 0.3333);
    z /= 0.8249;
    double fy = y <= 0.008856 ? fma(y, 7.787, 0.13793103448275862) : pow(y, 0.3333);
    double fz = z <= 0.008856 ? fma(z, 7.787, 0.13793103448275862) : pow(z, 0.3333);
    *lightness = fma(fy, 116.0, -16.0);
    *a = (fx - fy) * 500.0;
    double result = (fy - fz) * 200.0;
    *b = result;
    return result;
}

@implementation UIColorPickerColorMatch {
    NSArray<UIColorValue *> *_colors;
    UIColorValue *_color;
    CGColorSpaceRef _matchingColorSpace;
}

// BINMAP-ADAPT: UIColorPickerColorMatch.initWithColors:color:selectedIndex:
- (instancetype)initWithColors:(NSArray<UIColorValue *> *)colors color:(UIColorValue *)color selectedIndex:(NSInteger)selectedIndex {
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    self = [self initWithColors:colors color:color selectedIndex:selectedIndex matchingColorSpace:space];
    if (space) CGColorSpaceRelease(space);
    return self;
}

// BINMAP-ADAPT: UIColorPickerColorMatch.initWithColors:color:selectedIndex:matchingColorSpace:
- (instancetype)initWithColors:(NSArray<UIColorValue *> *)colors color:(UIColorValue *)color selectedIndex:(NSInteger)selectedIndex matchingColorSpace:(CGColorSpaceRef)matchingColorSpace {
    if ((self = [super init])) {
        _colors = [colors copy];
        _color = color;
        _selectedIndex = selectedIndex;
        _matchingColorSpace = matchingColorSpace ? CGColorSpaceRetain(matchingColorSpace) : NULL;
        _profileAvailable = matchingColorSpace && CGColorSpaceGetModel(matchingColorSpace) == kCGColorSpaceModelRGB;
    }
    return self;
}

// BINMAP-ADAPT: UIColorPickerColorMatch.dealloc
- (void)dealloc {
    if (_matchingColorSpace) CGColorSpaceRelease(_matchingColorSpace);
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPageableNameList _matchQualityOfColorAtIndex:toColor:ifBetterThan:] ea=0x183b2e308 end=0x183b2e570
- (double)_matchQualityOfColorAtIndex:(NSUInteger)index toColor:(UIColorValue *)color ifBetterThan:(double)best {
    NSUInteger count = _colors.count;
    double quality = 0.0;
    if (count > index && count != (NSUInteger)NSIntegerMax) {
        UIColorValue *candidate = _colors[index];
        quality = 5.0;
        if (best >= 5.0 || ![color isEqualForColorPanel:candidate]) {
            // BINNOTE: NSColor colorSpaceName pointer/description imports are bridged
            // by equal CG spaces and %g component descriptions for canonical numeric colors.
            // Catalog identity and dynamic-color description equivalence are unverified.
            CGColorSpaceRef inputSpace = CGColorGetColorSpace(color.CGColor);
            CGColorSpaceRef candidateSpace = CGColorGetColorSpace(candidate.CGColor);
            BOOL sameDescription = inputSpace && candidateSpace && CFEqual(inputSpace, candidateSpace) &&
                                   CGColorGetNumberOfComponents(color.CGColor) == CGColorGetNumberOfComponents(candidate.CGColor);
            if (sameDescription) {
                const CGFloat *left = CGColorGetComponents(color.CGColor), *right = CGColorGetComponents(candidate.CGColor);
                for (size_t component = 0; component < CGColorGetNumberOfComponents(color.CGColor); component++) {
                    if (![[NSString stringWithFormat:@"%g",(double)left[component]] isEqual:[NSString stringWithFormat:@"%g",(double)right[component]]]) { sameDescription = NO; break; }
                }
            }
            if (best >= 4.0 || !sameDescription) {
                quality = 3.0;
                if (best >= 3.0 || ![[color copyWithAlpha:1.0] isEqualForColorPanel:[candidate copyWithAlpha:1.0]]) {
                    UIColorValue *input = [color colorByConvertingToSpace:_matchingColorSpace error:NULL];
                    UIColorValue *other = [candidate colorByConvertingToSpace:_matchingColorSpace error:NULL];
                    quality = 0.0;
                    if (input && other) {
                        quality = 2.0;
                        if (best >= 2.0 || ![input isEqualForColorPanel:other]) {
                            const CGFloat *first = CGColorGetComponents(input.CGColor), *second = CGColorGetComponents(other.CGColor);
                            double l1 = 0, a1 = 0, b1 = 0, l2 = 0, a2 = 0, b2 = 0;
                            UIColorPickerRGBToLab(&l1, &a1, &b1, first[0], first[1], first[2]);
                            UIColorPickerRGBToLab(&l2, &a2, &b2, second[0], second[1], second[2]);
                            double da = a1 - a2, dl = l1 - l2, db = b1 - b2;
                            double distance = sqrt(fma(db, db, fma(dl, dl, da * da)));
                            quality = 0.0;
                            if (distance < 20.0) return distance / -20.0 + 1.0;
                        }
                    }
                }
            } else quality = 4.0;
        }
    }
    return quality;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerPageableNameList _colorIndexInTableView] ea=0x183b2e570 end=0x183b2e654
- (NSInteger)_colorIndexInTableView {
    if (_color) {
        if (_selectedIndex != -1) {
            double quality = [self _matchQualityOfColorAtIndex:(NSUInteger)_selectedIndex toColor:_color ifBetterThan:1.0];
            if (quality >= 2.0) return _selectedIndex;
        }
        NSInteger count = (NSInteger)_colors.count;
        if (count >= 1) {
            NSInteger selected = -1;
            double best = 0.0;
            for (NSInteger index = 0; index < count; index++) {
                double quality = [self _matchQualityOfColorAtIndex:(NSUInteger)index toColor:_color ifBetterThan:best];
                if (quality > best) { selected = index; best = quality; }
            }
            return selected;
        }
    }
    return -1;
}
@end
