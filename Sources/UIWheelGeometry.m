#import "UIWheelGeometry.h"
#import "UIColorValue.h"
#import <math.h>

@implementation UIWheelGeometry

// BINMAP: original=AppKit ida_name=-[NSColorPickerWheelView _brightColorFromPoint:fullBrightness:] ea=0x183b42350 end=0x183b424d8
- (UIColorValue *)_brightColorFromPoint:(CGPoint)point fullBrightness:(BOOL)fullBrightness {
    double center = floor(fmin(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5));
    double dy = point.y - center;
    double dx = point.x - center;
    double angle;
    if (dy == 0.0) {
        angle = dx < 0.0 ? 3.141592653589793 : 0.0;
    } else if (dx == 0.0) {
        angle = dy < 0.0 ? 4.71238898038469 : 1.5707963267948966;
    } else {
        angle = atan(dy / dx);
        if (dx <= 0.0) angle += 3.141592653589793;
        else if (dy <= 0.0) angle += 6.283185307179586;
    }
    double hue = fmin(angle / 6.283185307179586, 1.0);
    double saturation;
    if (dx == 0.0) saturation = (1.0 / center) * (dy < 0.0 ? -dy : dy);
    else saturation = dx / ((center - 2.0) * cos(hue * 6.283185307179586));
    saturation = fmin(saturation, 1.0);
    double brightness = fullBrightness ? 1.0 : self.brightness;

    // BINMAP-ADAPT: NSColor colorWithColorSpace:hue:saturation:brightness:alpha:
    // is unavailable in CoreGraphics. Inline RGB construction preserves the supplied RGB space.
    double sector = hue * 6.0;
    double chroma = brightness * saturation;
    double secondary = chroma * (1.0 - fabs(fmod(sector, 2.0) - 1.0));
    double base = brightness - chroma;
    CGFloat components[4] = {base, base, base, self.alpha};
    if (sector < 1.0 || sector >= 6.0) { components[0] += chroma; components[1] += secondary; }
    else if (sector < 2.0) { components[0] += secondary; components[1] += chroma; }
    else if (sector < 3.0) { components[1] += chroma; components[2] += secondary; }
    else if (sector < 4.0) { components[1] += secondary; components[2] += chroma; }
    else if (sector < 5.0) { components[0] += secondary; components[2] += chroma; }
    else { components[0] += chroma; components[2] += secondary; }
    CGColorRef cgColor = CGColorCreate(self.colorSpace, components);
    UIColorValue *result = cgColor ? [[UIColorValue alloc] initWithCGColor:cgColor] : nil;
    if (cgColor) CGColorRelease(cgColor);
    return result;
}

// BINMAP: original=AppKit ida_name=-[NSColorPickerWheelView _pointFromColor:] ea=0x183b41f20 end=0x183b41fdc
- (CGPoint)_pointFromColor:(UIColorValue *)color {
    // BINMAP-ADAPT: CoreGraphics profile conversion replaces colorUsingColorSpace:.
    // The original's hueComponent/saturationComponent imports become inline RGB decomposition.
    CGFloat components[4] = {0, 0, 0, 0};
    [color getRGBComponents:components inColorSpace:self.colorSpace error:NULL];
    double maximum = fmax(components[0], fmax(components[1], components[2]));
    double minimum = fmin(components[0], fmin(components[1], components[2]));
    double delta = maximum - minimum;
    double hue = 0.0;
    double saturation = maximum == 0.0 ? 0.0 : delta / maximum;
    if (delta != 0.0) {
        if (maximum == components[0]) hue = (components[1] - components[2]) / delta;
        else if (maximum == components[1]) hue = (components[2] - components[0]) / delta + 2.0;
        else hue = (components[0] - components[1]) / delta + 4.0;
        hue /= 6.0;
        if (hue < 0.0) hue += 1.0;
    }
    double halfWidth = self.bounds.size.width * 0.5;
    if (hue == 0.0 && saturation == 0.0) return CGPointMake(floor(halfWidth), floor(halfWidth));
    double angle = hue * 6.283185307179586;
    double x = floor(fma(cos(angle) * (halfWidth - 2.0), saturation, halfWidth));
    double y = floor(fma(sin(angle) * (halfWidth - 2.0), saturation, halfWidth));
    return CGPointMake(x, y);
}
@end
