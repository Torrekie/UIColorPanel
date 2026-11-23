#import "UIColorPickerColorTextField.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPickerFormatting.h"
@interface UIColorPickerColorTextField ()
@property(nonatomic, strong, readwrite) UITextField *textField;
@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic) CGFloat fieldWidth;
- (void)body;
@end
@implementation UIColorPickerColorTextField
// BINMAP-ADAPT: UIColorPickerColorTextField.initWithTitle:width:text:
- (instancetype)initWithTitle:(NSString *)title width:(CGFloat)width text:(NSString *)text {
    if((self=[super initWithFrame:CGRectZero])){_placeholder=[title copy];_fieldWidth=width;_text=[text copy];[self body];}return self;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000325E0 ea=0x1000325e0 end=0x100032b7f
- (void)body {
    os_log_debug(UIColorPickerLog(),"ColorTextField body");
    self.textField=[UITextField new];self.textField.borderStyle=UITextBorderStyleNone;self.textField.placeholder=self.placeholder;self.textField.text=self.text;
    self.textField.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];self.textField.adjustsFontForContentSizeCategory=YES;
    if(@available(iOS 13,*))self.backgroundColor=UIColor.systemBackgroundColor;else self.backgroundColor=UIColor.whiteColor;
    [self.textField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];self.textField.translatesAutoresizingMaskIntoConstraints=NO;[self addSubview:self.textField];
    [NSLayoutConstraint activateConstraints:@[[self.widthAnchor constraintEqualToConstant:self.fieldWidth],[self.textField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],[self.textField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],[self.textField.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],[self.textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8]]];
    self.textField.textAlignment=self.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?NSTextAlignmentRight:NSTextAlignmentLeft;
}
// BINMAP-ADAPT: UIColorPickerColorTextField.intrinsicContentSize
- (CGSize)intrinsicContentSize {CGSize size=self.textField.intrinsicContentSize;return CGSizeMake(self.fieldWidth,size.height+16);}
// BINMAP-ADAPT: UIColorPickerColorTextField.layoutSubviews
- (void)layoutSubviews {[super layoutSubviews];self.textField.textAlignment=self.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?NSTextAlignmentRight:NSTextAlignmentLeft;[UIColorPanelAppearance applyCornersToView:self radius:6 useSPI:NO];}
// BINMAP-ADAPT: UIColorPickerColorTextField.textChanged:
- (void)textChanged:(UITextField *)field {_text=[field.text copy]?:@"";[self sendActionsForControlEvents:UIControlEventValueChanged];}
// BINMAP-ADAPT: UIColorPickerColorTextField.setText:
- (void)setText:(NSString *)text {_text=[text copy];self.textField.text=text;}
// BINMAP-ADAPT: UIColorPickerColorTextField.traitCollectionDidChange:
- (void)traitCollectionDidChange:(UITraitCollection *)previous {[super traitCollectionDidChange:previous];self.textField.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];self.textField.textAlignment=self.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?NSTextAlignmentRight:NSTextAlignmentLeft;[self invalidateIntrinsicContentSize];}
@end
