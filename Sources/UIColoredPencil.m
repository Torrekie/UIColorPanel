#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import "UIColorPanelAppearance.h"
#import "UIColoredPencil.h"
#import "UIColorPickerPencilView.h"
#import "UIColorList.h"
@interface UIColorPickerPencilView (LocalizationSource)
@property(nonatomic,readonly) BOOL usesInternalColorList;
- (UIColorList *)_colorList;
@end
@implementation UIColoredPencil {
    NSString *_name;
    UIColorValue *_color;
    UIImage *_image;
    __weak UIColorPickerPencilView *_owningPencilView;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil initWithName:color:image:] ea=0x183b5e908 end=0x183b5e98c
- (instancetype)initWithName:(NSString *)name color:(UIColorValue *)color image:(UIImage *)image {
    // BINNOTE: UIAccessibilityElement replaces NSObject plus AppKit AX informal protocol.
    // Its weak container temporarily points to this allocated model; setOwningPencilView: replaces it before the model is exposed.
    if((self=[super initWithAccessibilityContainer:self])){_name=[name copy];_color=color;_image=image;}
    return self;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil dealloc] ea=0x183b5e98c end=0x183b5e9e8
- (void)dealloc {
    _name=nil;_color=nil;_image=nil; // ARC supplies releases.
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil name] ea=0x183b5ea68 end=0x183b5ea74
- (NSString *)name {
    return _name;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil color] ea=0x183b5ea74 end=0x183b5ea80
- (UIColorValue *)color {
    return _color;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil image] ea=0x183b5ea5c end=0x183b5ea68
- (UIImage *)image {
    return _image;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil owningPencilView] ea=0x183b2aa64 end=0x183b2aa70
- (UIColorPickerPencilView *)owningPencilView {
    return _owningPencilView;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil debugDescription] ea=0x183b5e9e8 end=0x183b5ea5c
- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"{\"%@\",%@,%@}",self.name,self.color.description,self.image.description];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil setOwningPencilView:] ea=0x183b2aa04 end=0x183b2aa64
- (void)setOwningPencilView:(UIColorPickerPencilView *)view {
    // BINNOTE: zeroing weak replaces native associated assign ownership.
    if(_owningPencilView!=view){_owningPencilView=view;self.accessibilityContainer=view;}
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsIgnored] ea=0x183b2da48 end=0x183b2da50
- (BOOL)colorPanelAccessibilityIsIgnored {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityRoleAttribute] ea=0x183b2db48 end=0x183b2db58
- (NSString *)colorPanelAccessibilityRoleAttribute {
    return @"AXRadioButton";
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityRoleDescriptionAttribute] ea=0x183b2db60 end=0x183b2db74
- (NSString *)colorPanelAccessibilityRoleDescriptionAttribute {
    return @"Pencil";
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityDescriptionAttribute] ea=0x183b2dbac end=0x183b2dbb0
- (NSString *)colorPanelAccessibilityDescriptionAttribute {
    return self.name;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityParentAttribute] ea=0x183b2db7c end=0x183b2dba4
- (id)colorPanelAccessibilityParentAttribute {
    return self.owningPencilView;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityWindowAttribute] ea=0x183b2dbb8 end=0x183b2dbe0
- (id)colorPanelAccessibilityWindowAttribute {
    return self.owningPencilView.window;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityTopLevelUIElementAttribute] ea=0x183b2dbe8 end=0x183b2dc10
- (id)colorPanelAccessibilityTopLevelUIElementAttribute {
    return self.owningPencilView.window;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityValueAttribute] ea=0x183b2dcf8 end=0x183b2dd44
- (NSNumber *)colorPanelAccessibilityValueAttribute {
    return @([self.owningPencilView _selectedPencil]==self);
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityActionNames] ea=0x183b2dd64 end=0x183b2dd7c
- (NSArray *)colorPanelAccessibilityActionNames {
    return @[@"AXPress"];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsDescriptionAttributeSettable] ea=0x183b2dbb0 end=0x183b2dbb8
- (BOOL)colorPanelAccessibilityIsDescriptionAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsParentAttributeSettable] ea=0x183b2dba4 end=0x183b2dbac
- (BOOL)colorPanelAccessibilityIsParentAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsPositionAttributeSettable] ea=0x183b2dc88 end=0x183b2dc90
- (BOOL)colorPanelAccessibilityIsPositionAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsRoleAttributeSettable] ea=0x183b2db58 end=0x183b2db60
- (BOOL)colorPanelAccessibilityIsRoleAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsRoleDescriptionAttributeSettable] ea=0x183b2db74 end=0x183b2db7c
- (BOOL)colorPanelAccessibilityIsRoleDescriptionAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsSizeAttributeSettable] ea=0x183b2dcf0 end=0x183b2dcf8
- (BOOL)colorPanelAccessibilityIsSizeAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsTopLevelUIElementAttributeSettable] ea=0x183b2dc10 end=0x183b2dc18
- (BOOL)colorPanelAccessibilityIsTopLevelUIElementAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsValueAttributeSettable] ea=0x183b2dd44 end=0x183b2dd4c
- (BOOL)colorPanelAccessibilityIsValueAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsWindowAttributeSettable] ea=0x183b2dbe0 end=0x183b2dbe8
- (BOOL)colorPanelAccessibilityIsWindowAttributeSettable {
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityPositionAttribute] ea=0x183b2dc18 end=0x183b2dc88
- (NSValue *)colorPanelAccessibilityPositionAttribute {
    CGRect rect=[self.owningPencilView _unobscuredFrameOfPencil:self];
    rect=UIAccessibilityConvertFrameToScreenCoordinates(rect,self.owningPencilView);
    return [NSValue valueWithCGPoint:rect.origin];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilitySizeAttribute] ea=0x183b2dc90 end=0x183b2dcf0
- (NSValue *)colorPanelAccessibilitySizeAttribute {
    CGRect rect=[self.owningPencilView _unobscuredFrameOfPencil:self];
    rect=UIAccessibilityConvertFrameToScreenCoordinates(rect,self.owningPencilView);
    return [NSValue valueWithCGSize:rect.size];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityPerformAction:] ea=0x183b2dde8 end=0x183b2de6c
- (void)colorPanelAccessibilityPerformAction:(NSString *)action {
    if([action isEqualToString:@"AXPress"])[self.owningPencilView _selectPencil:self updateSelection:YES animate:YES];
    else [NSException raise:NSInvalidArgumentException format:@"Unsupported pencil action %@",action];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityActionDescription:] ea=0x183b2dd7c end=0x183b2dde8
- (NSString *)colorPanelAccessibilityActionDescription:(NSString *)action {
    if([action isEqualToString:@"AXPress"])return @"Press";
    [NSException raise:NSInvalidArgumentException format:@"Unsupported pencil action %@",action];return nil;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityIsAttributeSettable:] ea=0x183b2dd54 end=0x183b2dd5c
- (BOOL)colorPanelAccessibilityIsAttributeSettable:(NSString *)attribute {
    // BINNOTE: every pencil AX attribute is read-only in the recovered class.
    return NO;
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilitySetValue:forAttribute:] ea=0x183b2dd5c end=0x183b2dd64
- (void)colorPanelAccessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    // BINNOTE: UIKit has no imported NSAccessibilitySetAttributeValue dispatcher.
    [NSException raise:NSInvalidArgumentException format:@"Pencil attribute %@ is read-only",attribute];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityAttributeValue:] ea=0x183b2dd4c end=0x183b2dd54
- (id)colorPanelAccessibilityAttributeValue:(NSString *)attribute {
    // BINNOTE: imported AppKit generic AX dispatch becomes a local known-attribute UIKit bridge.
    NSDictionary *values=@{@"AXRole":[self colorPanelAccessibilityRoleAttribute],@"AXRoleDescription":[self colorPanelAccessibilityRoleDescriptionAttribute],@"AXDescription":[self colorPanelAccessibilityDescriptionAttribute],@"AXValue":[self colorPanelAccessibilityValueAttribute],@"AXPosition":[self colorPanelAccessibilityPositionAttribute],@"AXSize":[self colorPanelAccessibilitySizeAttribute]};
    if([attribute isEqual:@"AXParent"])return [self colorPanelAccessibilityParentAttribute];
    if([attribute isEqual:@"AXWindow"])return [self colorPanelAccessibilityWindowAttribute];
    if([attribute isEqual:@"AXTopLevelUIElement"])return [self colorPanelAccessibilityTopLevelUIElementAttribute];
    return values[attribute];
}
// BINMAP: original=AppKit ida_name=-[NSColoredPencil accessibilityAttributeNames] ea=0x183b2da50 end=0x183b2da94
- (NSArray *)colorPanelAccessibilityAttributeNames {
    static NSArray *attributes;static dispatch_once_t once;
    // BINMAP-BLOCK: invoke_ea=0x183b2da94 parent_ea=0x183b2da50 reconstructed_as=block_literal
    dispatch_once(&once,^{attributes=@[@"AXRole",@"AXRoleDescription",@"AXParent",@"AXWindow",@"AXTopLevelUIElement",@"AXPosition",@"AXSize",@"AXDescription",@"AXValue"];});return attributes;
}
// BINMAP-ADAPT: UIColoredPencil.accessibilityLabel
- (NSString *)accessibilityLabel { UIColorPickerPencilView *view=self.owningPencilView;UIColorList *list=[view _colorList];return view.usesInternalColorList?[UIColorPanelAppearance localizedString:self.name]:([list localizedColorNameWithKey:self.name]?:self.name); }
// BINMAP-ADAPT: UIColoredPencil.accessibilityTraits
- (UIAccessibilityTraits)accessibilityTraits { return UIAccessibilityTraitButton|([self.colorPanelAccessibilityValueAttribute boolValue]?UIAccessibilityTraitSelected:0); }
// BINMAP-ADAPT: UIColoredPencil.accessibilityFrame
- (CGRect)accessibilityFrame { return (CGRect){[[self colorPanelAccessibilityPositionAttribute]CGPointValue],[[self colorPanelAccessibilitySizeAttribute]CGSizeValue]}; }
// BINMAP-ADAPT: UIColoredPencil.accessibilityActivate
- (BOOL)accessibilityActivate { [self colorPanelAccessibilityPerformAction:@"AXPress"];return YES; }
@end
#endif
