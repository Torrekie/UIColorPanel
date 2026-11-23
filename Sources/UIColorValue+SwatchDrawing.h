#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN
/// Explicit Core Graphics transport for imported NSColor swatch drawing; never changes the value.
@interface UIColorValue (SwatchDrawing)
#if TARGET_OS_IOS
- (void)drawSwatchInRect:(CGRect)rect;
#endif
- (void)drawSwatchInRect:(CGRect)rect context:(CGContextRef)context drawingToScreen:(BOOL)screen flipped:(BOOL)flipped;
@end
NS_ASSUME_NONNULL_END
