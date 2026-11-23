#import "UIColorPickerSliderControl.h"
#import "UIColorPickerCPTextField.h"
#import "UIColorPanelAppearance.h"
@interface UIColorPickerSliderControl ()
@property(nonatomic, copy, readwrite) NSString *title;
@property(nonatomic, strong, readwrite) UIColorPickerColorSlider *slider;
@property(nonatomic, strong, readwrite) UITextField *textField;
@property(nonatomic, strong, readwrite) UIColorPickerSliderControlStyle *style;
@property(nonatomic, strong) UIColorPickerCPTextField *editor;
@property(nonatomic, strong) UIStackView *stack;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) NSLayoutConstraint *fieldWidth;
- (UIStackView *)body;
- (NSArray<UIView *> *)content;
- (NSArray<UIView *> *)controls;
- (NSString *)formattedValue:(double)value;
- (NSNumber *)parsedValue:(NSString *)text;
- (BOOL)shouldChangeText:(NSString *)text range:(NSRange)range replacement:(NSString *)replacement;
@end
@implementation UIColorPickerSliderControl
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000311D0 ea=0x1000311d0 end=0x100031285
- (instancetype)initWithTitle:(NSString *)title value:(double)value fromColor:(UIColor *)from toColor:(UIColor *)to style:(UIColorPickerSliderControlStyle *)style {
    if((self=[super initWithFrame:CGRectZero])){_title=[title copy];_value=value;_fromColor=from;_toColor=to;_selectedColor=to;_showsOpacityBackground=YES;_style=style;self.stack=[self body];self.stack.translatesAutoresizingMaskIntoConstraints=NO;[self addSubview:self.stack];[NSLayoutConstraint activateConstraints:@[[self.stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],[self.stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],[self.stack.topAnchor constraintEqualToAnchor:self.topAnchor],[self.stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]]];}return self;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100032590 ea=0x100032590 end=0x1000325d1
- (UIStackView *)body {
    UIStackView *stack=[[UIStackView alloc]initWithArrangedSubviews:[self content]];stack.axis=UILayoutConstraintAxisVertical;stack.alignment=UIStackViewAlignmentFill;stack.spacing=0;return stack;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100031380 ea=0x100031380 end=0x10003184e
- (NSArray<UIView *> *)content {
    self.titleLabel=[UILabel new];self.titleLabel.text=[self.title uppercaseStringWithLocale:NSLocale.currentLocale];self.titleLabel.numberOfLines=0;
    UIFontDescriptor *font=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote];font=[font fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightSemibold)}}];self.titleLabel.font=[UIFont fontWithDescriptor:font size:0];self.titleLabel.adjustsFontForContentSizeCategory=YES;
    if(@available(iOS 13,*))self.titleLabel.textColor=UIColor.secondaryLabelColor;else self.titleLabel.textColor=[UIColor colorWithRed:60.0/255 green:60.0/255 blue:67.0/255 alpha:.6];
    self.titleLabel.isAccessibilityElement=NO;
    UIView *paddedTitle=[UIView new];self.titleLabel.translatesAutoresizingMaskIntoConstraints=NO;[paddedTitle addSubview:self.titleLabel];[NSLayoutConstraint activateConstraints:@[[self.titleLabel.leadingAnchor constraintEqualToAnchor:paddedTitle.leadingAnchor],[self.titleLabel.trailingAnchor constraintEqualToAnchor:paddedTitle.trailingAnchor],[self.titleLabel.topAnchor constraintEqualToAnchor:paddedTitle.topAnchor],[self.titleLabel.bottomAnchor constraintEqualToAnchor:paddedTitle.bottomAnchor constant:-5]]];
    UIStackView *row=[[UIStackView alloc]initWithArrangedSubviews:[self controls]];row.axis=UILayoutConstraintAxisHorizontal;row.alignment=UIStackViewAlignmentCenter;row.spacing=16;return @[paddedTitle,row];
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100031850 ea=0x100031850 end=0x10003236b
- (NSArray<UIView *> *)controls {
    self.slider=[UIColorPickerColorSlider new];self.slider.value=self.value;self.slider.fromColor=self.fromColor;self.slider.toColor=self.toColor;self.slider.selectedColor=self.selectedColor;self.slider.accessibilityLabel=self.title;self.slider.accessibilityValue=[self formattedValue:self.value];
    [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];[self.slider addTarget:self action:@selector(sliderEditingBegan:) forControlEvents:UIControlEventEditingDidBegin];[self.slider addTarget:self action:@selector(sliderEditingEnded:) forControlEvents:UIControlEventEditingDidEnd];
    __weak UIColorPickerSliderControl *weakSelf=self;
    self.editor=[[UIColorPickerCPTextField alloc]initWithGetter:^double{return weakSelf.value;} setter:^(double value){UIColorPickerSliderControl *row=weakSelf;if(!row)return;row.value=value;[row sendActionsForControlEvents:UIControlEventValueChanged];} allowUpdatesWhileEditing:YES selectionOnNumber:self.style.percentage keyboardType:UIKeyboardTypeDecimalPad toString:^NSString *(double value){return [weakSelf formattedValue:value]?:@"";} toValue:^NSNumber *(NSString *text){return [weakSelf parsedValue:text];} shouldChange:^BOOL(NSString *text,NSRange range,NSString *replacement){return [weakSelf shouldChangeText:text range:range replacement:replacement];}];
    // BINMAP-BLOCK: Swift closure adapters at 0x1000351f0/0x100035220/
    // 0x100035260 capture this SliderControl; UIKit uses weak owner closures.
    self.textField=self.editor.view;self.textField.accessibilityLabel=self.title;
    if(@available(iOS 13,*))self.textField.backgroundColor=UIColor.systemBackgroundColor;else self.textField.backgroundColor=UIColor.whiteColor;
    self.fieldWidth=[self.textField.widthAnchor constraintEqualToConstant:self.landscapeLayout?60:76];[NSLayoutConstraint activateConstraints:@[self.fieldWidth,[self.textField.heightAnchor constraintEqualToConstant:36],[self.slider.heightAnchor constraintEqualToConstant:36]]];
    return @[self.slider,self.textField];
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100032370 ea=0x100032370 end=0x10003240b
- (NSString *)formattedValue:(double)value {return self.style.floatToTextMapping(value);}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100032410 ea=0x100032410 end=0x1000324b0
- (NSNumber *)parsedValue:(NSString *)text {return self.style.textToFloatMapping(text);}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000324B0 ea=0x1000324b0 end=0x100032569
- (BOOL)shouldChangeText:(NSString *)text range:(NSRange)range replacement:(NSString *)replacement {return self.style.shouldChangeCharacters(text,range,replacement);}
// BINMAP-ADAPT: UIColorPickerSliderControl.intrinsicContentSize
- (CGSize)intrinsicContentSize {return CGSizeMake(UIViewNoIntrinsicMetric,[self.stack systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);}
// BINMAP-ADAPT: UIColorPickerSliderControl.layoutSubviews
- (void)layoutSubviews {[super layoutSubviews];self.titleLabel.textAlignment=self.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?NSTextAlignmentRight:NSTextAlignmentLeft;[self.stack layoutIfNeeded];[UIColorPanelAppearance applyCornersToView:self.textField radius:8 useSPI:NO];}
// BINMAP-ADAPT: UIColorPickerSliderControl.setValue:
- (void)setValue:(double)value {_value=value;self.slider.value=value;self.slider.accessibilityValue=[self formattedValue:value];[self.editor updateView];}
// BINMAP-ADAPT: UIColorPickerSliderControl.setSelectedColor:
- (void)setSelectedColor:(UIColor *)color {_selectedColor=color;self.slider.selectedColor=color;}
// BINMAP-ADAPT: UIColorPickerSliderControl.setLandscapeLayout:
- (void)setLandscapeLayout:(BOOL)landscape {_landscapeLayout=landscape;self.fieldWidth.constant=landscape?60:76;}
// BINMAP-ADAPT: UIColorPickerSliderControl.setFromColor:
- (void)setFromColor:(UIColor *)color {_fromColor=color;self.slider.fromColor=color;}
// BINMAP-ADAPT: UIColorPickerSliderControl.setToColor:
- (void)setToColor:(UIColor *)color {_toColor=color;self.slider.toColor=color;}
// BINMAP-ADAPT: UIColorPickerSliderControl.setShowsOpacityBackground:
- (void)setShowsOpacityBackground:(BOOL)shows {_showsOpacityBackground=shows;self.slider.showsOpacityBackground=shows;}
// BINMAP-ADAPT: UIColorPickerSliderControl.sliderChanged:
- (void)sliderChanged:(UIColorPickerColorSlider *)slider {self.value=slider.value;[self sendActionsForControlEvents:UIControlEventValueChanged];}
// BINMAP-ADAPT: UIColorPickerSliderControl.sliderEditingBegan:
- (void)sliderEditingBegan:(UIColorPickerColorSlider *)slider {[self sendActionsForControlEvents:UIControlEventEditingDidBegin];}
// BINMAP-ADAPT: UIColorPickerSliderControl.sliderEditingEnded:
- (void)sliderEditingEnded:(UIColorPickerColorSlider *)slider {[self sendActionsForControlEvents:UIControlEventEditingDidEnd];}
// BINMAP-ADAPT: UIColorPickerSliderControl.traitCollectionDidChange:
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];[self.editor refreshFont];
    UIFontDescriptor *font=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote compatibleWithTraitCollection:self.traitCollection];font=[font fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightSemibold)}}];self.titleLabel.font=[UIFont fontWithDescriptor:font size:0];[self invalidateIntrinsicContentSize];[self setNeedsLayout];
}
@end
