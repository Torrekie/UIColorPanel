#import "UIColorPanelWell+Internal.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelColorProfile.h"
#import "UIColorPanel.h"
#import "UIColorValue+AppKitEquality.h"
#import "UIPanel.h"
#import "UIColorArchiveRecord.h"
#import <objc/runtime.h>

@protocol UIColorPanelColorSource
- (UIColor *)color;
@end

static NSMutableArray<UIColorPanelWell *> *UIColorPanelActiveWells;

@implementation UIColorPanelWell {
    UIColorValue *_colorValue;
    BOOL _active;
    BOOL _notContinuous;
    BOOL _bordered;
    BOOL _orderColorPanelOnActivate;
}

// BINMAP-ADAPT: UIColorPanelWell.initialize
+ (void)initialize {
    if (self == UIColorPanelWell.class) UIColorPanelActiveWells = [NSMutableArray new];
    // NSColorWell's observer registration is retained; UIKit has no AppKit global bootstrap.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(colorPanelColorChanged:)
                                              name:UIColorPanelColorDidChangeNotification object:nil];
}

// BINMAP-ADAPT: UIColorPanelWell.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _bordered = YES;
        _orderColorPanelOnActivate = YES;
        _colorValue = [[UIColorValue alloc] initWithCGColor:UIColor.whiteColor.CGColor];
        self.opaque = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityLabel = [UIColorPanelAppearance localizedString:@"Current color"];
    }
    return self;
}

// BINMAP-ADAPT: UIColorPanelWell.initWithCoder:
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        _bordered = YES;
        _orderColorPanelOnActivate = YES;
        _colorValue = [[UIColorValue alloc] initWithCGColor:UIColor.whiteColor.CGColor];
        self.opaque = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityLabel = [UIColorPanelAppearance localizedString:@"Current color"];
    }
    return self;
}

// BINMAP-ADAPT: UIColorPanelWell.dealloc
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell color] ea=0x183a31cac end=0x183a31cbc
- (UIColor *)color {
    return _colorValue.UIColor;
}

// BINMAP-ADAPT: UIColorPanelWell.colorValue
- (UIColorValue *)colorValue {
    return _colorValue;
}

// BINMAP-ADAPT: UIColorPanelWell.setColorValue:
- (void)setColorValue:(UIColorValue *)colorValue {
    NSParameterAssert(colorValue);
    self.color = colorValue.UIColor;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell setColor:] ea=0x183979d28 end=0x183979e6c
- (void)setColor:(UIColor *)color {
    NSParameterAssert(color);
    UIColorValue *value = [[UIColorValue alloc] initWithCGColor:color.CGColor];
    // BINMAP-ADAPT: a named source and its numerically identical fallback are
    // distinct assignments; component edits still produce unnamed values.
    NSDictionary *metadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey),*currentMetadata=objc_getAssociatedObject(_colorValue,&UIColorArchiveMetadataAssociationKey);
    BOOL sameMetadata=metadata==currentMetadata||[metadata isEqual:currentMetadata];
    if (!sameMetadata||![value isEqualForColorPanel:_colorValue]) {
        if(metadata)objc_setAssociatedObject(value,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self willChangeValueForKey:@"objectValue"];
        _colorValue = value;
        [self setNeedsDisplay];
        if (self.active && UIColorPanel.sharedColorPanelExists)
            UIColorPanel.sharedColorPanel.colorValue = _colorValue;
        [self didChangeValueForKey:@"objectValue"];
    }
}

// BINMAP-ADAPT: UIColorPanelWell.accessibilityValue
- (NSString *)accessibilityValue {
    NSString *provided=[super accessibilityValue];if(provided)return provided;
    CGColorRef color=_colorValue.CGColor;UIColorPanelColorProfile *profile=[[UIColorPanelColorProfile alloc]initWithColorSpace:CGColorGetColorSpace(color) displayName:nil];
    NSMutableArray *parts=[NSMutableArray arrayWithObject:profile.displayName?:[UIColorPanelAppearance localizedString:@"Original ICC profile"]];
    const CGFloat *components=CGColorGetComponents(color);NSUInteger count=CGColorGetNumberOfComponents(color);
    for(NSUInteger index=0;index+1<count;index++)[parts addObject:[UIColorPanelAppearance formatNumber:components[index] significantDigits:6]];
    NSNumberFormatter *percent=[NSNumberFormatter new];percent.numberStyle=NSNumberFormatterPercentStyle;percent.maximumFractionDigits=3;percent.usesGroupingSeparator=NO;
    [parts addObject:[NSString stringWithFormat:@"%@: %@",[UIColorPanelAppearance localizedString:@"Opacity"],[percent stringFromNumber:@(CGColorGetAlpha(color))]]];
    return[parts componentsJoinedByString:@", "];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell isActive] ea=0x183979f24 end=0x183979f38
- (BOOL)isActive {
    return _active;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell isContinuous] ea=0x183b47db0 end=0x183b47dc8
- (BOOL)isContinuous {
    return !_notContinuous;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell setContinuous:] ea=0x183b47dc8 end=0x183b47df0
- (void)setContinuous:(BOOL)continuous {
    _notContinuous = !continuous;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell isBordered] ea=0x183b46b98 end=0x183b46bac
- (BOOL)isBordered {
    return _bordered;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell setBordered:] ea=0x183979b58 end=0x183979bb0
// BINMAP-ADAPT: manifest=reimpl/touch_well_extras.json — invalidate UIKit's cached border and fill inset when the drawing state changes.
- (void)setBordered:(BOOL)bordered {
    // The mobile well implements AppKit's classic style (0); its newer pull-down styles are separate UI.
    if (_bordered != bordered) {
        _bordered = bordered;
        [self setNeedsDisplay];
    }
}

// BINMAP: original=AppKit ida_name=-[NSColorWell orderColorPanelOnActivate] ea=0x183b49218 end=0x183b4922c
- (BOOL)orderColorPanelOnActivate {
    return _orderColorPanelOnActivate;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell setOrderColorPanelOnActivate:] ea=0x183b4922c end=0x183b4923c
- (void)setOrderColorPanelOnActivate:(BOOL)orderColorPanelOnActivate {
    _orderColorPanelOnActivate = orderColorPanelOnActivate;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell _shouldOrderFront] ea=0x183b45f50 end=0x183b45f54
- (BOOL)_shouldOrderFront {
    return self.orderColorPanelOnActivate;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell _ownsColorPanelExclusively] ea=0x183b47df0 end=0x183b47df8
- (BOOL)_ownsColorPanelExclusively {
    return NO;
}

// BINMAP: original=AppKit ida_name=+[NSColorWell _exclusiveColorPanelOwner] ea=0x183b47df8 end=0x183b47e80
+ (UIColorPanelWell *)_exclusiveColorPanelOwner {
    UIColorPanelWell *owner = nil;
    @synchronized (UIColorPanelWell.class) {
        if (UIColorPanelActiveWells.count == 1) {
            owner = UIColorPanelActiveWells[0];
            if (![owner _ownsColorPanelExclusively]) owner = nil;
        }
    }
    return owner;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell activate:] ea=0x183b47efc end=0x183b4815c
- (void)activate:(BOOL)exclusive {
    UIColor *color = self.color;
    @synchronized (UIColorPanelWell.class) {
        if (exclusive || (UIColorPanelActiveWells.count == 1 && [UIColorPanelActiveWells[0] _ownsColorPanelExclusively])) {
            NSMutableArray *wells = UIColorPanelActiveWells;
            UIColorPanelActiveWells = nil;
            [wells removeObject:self];
            [wells makeObjectsPerformSelector:@selector(deactivate)];
            [wells removeAllObjects];
            [wells addObject:self];
            UIColorPanelActiveWells = wells;
        } else if (![UIColorPanelActiveWells containsObject:self]) {
            [UIColorPanelActiveWells addObject:self];
        }
    }
    if (!_active) {
        _active = YES;
        UIColorPanelWell *previous = nil;
        @synchronized (UIColorPanelWell.class) {
            if (UIColorPanelActiveWells.count >= 2) previous = UIColorPanelActiveWells[0];
        }
        if (previous) [self takeColorFrom:previous];
        else UIColorPanel.sharedColorPanel.color = color;
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserver:self selector:@selector(windowWillClose:) name:UIPanelWillCloseNotification object:UIColorPanel.sharedColorPanel];
        if (self.window) [center addObserver:self selector:@selector(windowWillClose:) name:UIPanelWillCloseNotification object:self.window];
        [self setNeedsDisplay];
    }
    if ([self _shouldOrderFront]) [UIColorPanel.sharedColorPanel orderFront:self];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell deactivate] ea=0x183b47c58 end=0x183b47d78
- (void)deactivate {
    if (UIColorPanel.sharedColorPanelExists) {
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center removeObserver:self name:UIPanelWillCloseNotification object:UIColorPanel.sharedColorPanel];
        if (self.window) [center removeObserver:self name:UIPanelWillCloseNotification object:self.window];
    }
    __attribute__((objc_precise_lifetime)) UIColorPanelWell *keepAlive = self;
    @synchronized (UIColorPanelWell.class) {
        [UIColorPanelActiveWells removeObject:self];
    }
    _active = NO;
    [self setNeedsDisplay];
    (void)keepAlive;
}

// BINMAP: original=AppKit ida_name=+[NSColorWell _deactivateAllColorWells] ea=0x183b47eb8 end=0x183b47efc
+ (void)_deactivateAllColorWells {
    [UIColorPanelActiveWells makeObjectsPerformSelector:@selector(deactivate)];
    [UIColorPanelActiveWells removeAllObjects];
}

// BINMAP: original=AppKit ida_name=+[NSColorWell colorPanelColorChanged:] ea=0x183b46d64 end=0x183b46e14
+ (void)colorPanelColorChanged:(NSNotification *)notification {
    id panel = notification.object;
    NSArray *wells;
    @synchronized (UIColorPanelWell.class) {
        wells = [UIColorPanelActiveWells copy];
    }
    SEL selector = [panel isContinuous] ? @selector(_takeColorFromAndSendActionIfContinuous:) : @selector(_takeColorFromDoAction:);
    [wells makeObjectsPerformSelector:selector withObject:panel];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell _takeColorFrom:andSendAction:] ea=0x183b46a80 end=0x183b46b28
- (instancetype)_takeColorFrom:(id)sender andSendAction:(BOOL)sendAction {
    if (self.enabled) {
        UIColor *color = [(id<UIColorPanelColorSource>)sender color];
        UIColorValue *value = [[UIColorValue alloc] initWithCGColor:color.CGColor];
        // BINMAP-ADAPT: active-well propagation preserves named-source changes
        // even when their archived numeric fallbacks are identical.
        NSDictionary *metadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey),*currentMetadata=objc_getAssociatedObject(_colorValue,&UIColorArchiveMetadataAssociationKey);
        BOOL sameMetadata=metadata==currentMetadata||[metadata isEqual:currentMetadata];
        if (!sameMetadata||![value isEqualForColorPanel:_colorValue]) {
            self.color = color;
            if (sendAction) [self sendAction:self.action to:self.target];
        }
    }
    return self;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell _takeColorFromAndSendActionIfContinuous:] ea=0x183b46b28 end=0x183b46b6c
- (instancetype)_takeColorFromAndSendActionIfContinuous:(id)sender {
    return [self _takeColorFrom:sender andSendAction:self.continuous];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell _takeColorFromDoAction:] ea=0x183b46b6c end=0x183b46b98
- (instancetype)_takeColorFromDoAction:(id)sender {
    [self _takeColorFrom:sender andSendAction:YES];
    return self;
}

// BINMAP: original=AppKit ida_name=-[NSColorWell takeColorFrom:] ea=0x183b47da8 end=0x183b47db0
- (void)takeColorFrom:(id)sender {
    [self _takeColorFrom:sender andSendAction:NO];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell windowWillClose:] ea=0x183b4859c end=0x183b485a0
- (void)windowWillClose:(NSNotification *)notification {
    [self deactivate];
}

// BINMAP: original=AppKit ida_name=-[NSColorWell setEnabled:] ea=0x18397b448 end=0x18397b4bc
- (void)setEnabled:(BOOL)enabled {
    if (self.enabled != enabled) {
        [super setEnabled:enabled];
        [self setNeedsDisplay];
    }
}

// BINMAP-ADAPT: UIColorPanelWell.sendAction:to:
- (BOOL)sendAction:(SEL)action to:(id)target {
    return action ? [UIApplication.sharedApplication sendAction:action to:target from:self forEvent:nil] : NO;
}

// BINMAP-ADAPT: UIColorPanelWell.intrinsicContentSize
- (CGSize)intrinsicContentSize {
    return CGSizeMake(44, 32);
}

// BINMAP-ADAPT: UIColorPanelWell.drawRect:
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect well = CGRectInset(self.bounds, self.bordered ? 3 : 0, self.bordered ? 3 : 0);
    CGContextSaveGState(context);
    CGContextAddPath(context, [UIColorPanelAppearance smoothPathForRect:well radius:3].CGPath);
    CGContextClip(context);
    for (CGFloat y = CGRectGetMinY(well); y < CGRectGetMaxY(well); y += 6) {
        for (CGFloat x = CGRectGetMinX(well); x < CGRectGetMaxX(well); x += 6) {
            NSInteger column = (NSInteger)((x - CGRectGetMinX(well)) / 6), row = (NSInteger)((y - CGRectGetMinY(well)) / 6);
            CGContextSetGrayFillColor(context, (column + row) % 2 ? 0.72 : 0.94, 1);
            CGContextFillRect(context, CGRectMake(x, y, 6, 6));
        }
    }
    CGContextSetFillColorWithColor(context, _colorValue.CGColor);
    CGContextFillRect(context, well);
    CGContextRestoreGState(context);
    if (self.bordered) {
        UIColor *border = self.active ? self.tintColor : [UIColor colorWithWhite:0.55 alpha:self.enabled ? 1 : 0.4];
        CGContextSetStrokeColorWithColor(context, border.CGColor);
        CGContextSetLineWidth(context, self.active ? 2 : 1);
        CGContextAddPath(context, [UIColorPanelAppearance smoothPathForRect:CGRectInset(self.bounds, 1, 1) radius:5].CGPath);
        CGContextStrokePath(context);
    }
}

// BINMAP-ADAPT: UIColorPanelWell.endTrackingWithTouch:withEvent:
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    if (touch && self.enabled && CGRectContainsPoint(self.bounds, [touch locationInView:self])) {
        if (self.active) [self deactivate];
        else [self activate:YES];
    }
}

// BINMAP-ADAPT: UIColorPanelWell.accessibilityActivate
- (BOOL)accessibilityActivate {
    if (!self.enabled) return NO;
    if (self.active) [self deactivate];
    else [self activate:YES];
    return YES;
}

// BINMAP-ADAPT: UIColorPanelWell.willMoveToWindow:
- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (!newWindow && self.window && self.active) [self deactivate];
}
@end
