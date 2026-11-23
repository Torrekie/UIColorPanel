#import "UIColorValue+AppKitEquality.h"
@implementation UIColorValue (AppKitEquality)
// BINMAP: original=AppKit ida_name=-[NSColorSpaceColor isEqual:] ea=0x18382e758 end=0x18382e8f8
- (BOOL)isEqualForColorPanel:(id)object {
    if (self == object) return YES;
    // BINNOTE: NSColor class/name guards use the canonical numeric UIColorValue bridge.
    // CG-backed NSColorSpace equality is CFEqual (0x18380632c); profile-backed
    // names, catalog/dynamic dispatch, and pattern identity are not represented.
    if (![object isKindOfClass:UIColorValue.class]) return NO;
    CGColorSpaceRef otherSpace = CGColorGetColorSpace([object CGColor]);
    CGColorSpaceRef space = CGColorGetColorSpace(self.CGColor);
    if (!otherSpace || !space || !CFEqual(otherSpace, space)) return NO;
    if (CGColorSpaceGetModel(space) == kCGColorSpaceModelPattern) return NO;
    NSInteger count = (NSInteger)CGColorGetNumberOfComponents(self.CGColor);
    // BINNOTE: valid same-space CG numeric colors guarantee equal component counts;
    // this transport guard avoids the original NSColor getComponents: class contract.
    if (count != (NSInteger)CGColorGetNumberOfComponents([object CGColor])) return NO;
    const CGFloat *other = CGColorGetComponents([object CGColor]);
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    if (count < 1) return YES;
    if ((float)other[0] != (float)components[0]) return NO;
    NSInteger index = 1, compared;
    do {
        compared = index;
        if (count == index) break;
        float left = (float)other[index], right = (float)components[index++];
        if (left != right) break;
    } while (YES);
    return compared >= count;
}
@end
