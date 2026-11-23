#import "UIColorPickerCPTextField.h"
#import "UIColorPickerFormatting.h"
@class UIColorPickerCPTextFieldCoordinator;
@interface UIColorPickerSelectionTextField : UITextField
@property(nonatomic, weak) UIColorPickerCPTextFieldCoordinator *selectionCoordinator;
@property(nonatomic) BOOL forwardingSelection;
@end
@interface UIColorPickerCPTextField ()
@property(nonatomic, strong, readwrite) UITextField *view;
@property(nonatomic, strong) UIColorPickerCPTextFieldCoordinator *coordinator;
@property(nonatomic, readwrite, getter=isEditing) BOOL editing;
- (UITextField *)makeView;
- (UIColorPickerCPTextFieldCoordinator *)makeCoordinator;
@end
@interface UIColorPickerCPTextFieldCoordinator : NSObject <UITextFieldDelegate, UIScribbleInteractionDelegate>
@property(nonatomic, weak) UIColorPickerCPTextField *field;
- (instancetype)initWithField:(UIColorPickerCPTextField *)field;
- (void)textFieldValueChangedWithTextfield:(UITextField *)textField;
- (void)textFieldDidChangeSelection:(UITextField *)textField;
@end
@implementation UIColorPickerCPTextField
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001AF10 ea=0x10001af10 end=0x10001afff
- (instancetype)initWithGetter:(double (^)(void))getter setter:(void (^)(double))setter allowUpdatesWhileEditing:(BOOL)allow selectionOnNumber:(BOOL)selection keyboardType:(UIKeyboardType)keyboard toString:(NSString *(^)(double))toString toValue:(NSNumber *(^)(NSString *))toValue shouldChange:(BOOL (^)(NSString *,NSRange,NSString *))shouldChange {
    if((self=[super init])){_getter=[getter copy];_setter=[setter copy];_allowUpdatesWhileEditing=allow;_selectionOnNumber=selection;_keyboardType=keyboard;_conversionToString=[toString copy];_conversionToValue=[toValue copy];_shouldChangeCharacters=[shouldChange copy];_coordinator=[self makeCoordinator];_view=[self makeView];[self updateView];}return self;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100019610 ea=0x100019610 end=0x100019b88
- (UITextField *)makeView {
    UITextField *view;
    if(@available(iOS 13,*))view=[UITextField new];
    else {UIColorPickerSelectionTextField *selection=[UIColorPickerSelectionTextField new];selection.selectionCoordinator=self.coordinator;view=selection;}
    view.delegate=self.coordinator;[view addTarget:self.coordinator action:@selector(textFieldValueChangedWithTextfield:) forControlEvents:UIControlEventEditingChanged];
    view.autocapitalizationType=UITextAutocapitalizationTypeAllCharacters;view.autocorrectionType=UITextAutocorrectionTypeNo;view.keyboardType=self.keyboardType;view.textAlignment=NSTextAlignmentCenter;view.adjustsFontForContentSizeCategory=YES;
    UIFontDescriptor *descriptor=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];descriptor=[descriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightMedium)}}];view.font=[UIFont fontWithDescriptor:descriptor size:0];
    view.adjustsFontSizeToFitWidth=YES;[view setContentCompressionResistancePriority:250 forAxis:UILayoutConstraintAxisHorizontal];[view setContentCompressionResistancePriority:250 forAxis:UILayoutConstraintAxisVertical];
    if(self.keyboardType==UIKeyboardTypeDecimalPad&&UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPhone){UIToolbar *toolbar=[UIToolbar new];toolbar.items=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:view action:@selector(resignFirstResponder)]];[toolbar sizeToFit];view.inputAccessoryView=toolbar;}
    if(@available(iOS 14,*)){UIScribbleInteraction *scribble=[[UIScribbleInteraction alloc]initWithDelegate:self.coordinator];[view addInteraction:scribble];}
    // BINNOTE: The original changes Scribble's horizontal hit tolerance through
    // an SPI delegate selector. Public builds intentionally use system defaults.
    return view;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100019B90 ea=0x100019b90 end=0x100019cec
- (UIColorPickerCPTextFieldCoordinator *)makeCoordinator {return [[UIColorPickerCPTextFieldCoordinator alloc]initWithField:self];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001BA80 ea=0x10001ba80 end=0x10001bc7d
- (void)updateView {
    if(self.editing&&!self.allowUpdatesWhileEditing)return;
    NSString *text=self.conversionToString(self.getter());if([self.view.text isEqualToString:text])return;
    self.view.text=text;
}
// BINMAP-ADAPT: UIColorPickerCPTextField.refreshFont
- (void)refreshFont {
    UIFontDescriptor *descriptor=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.view.traitCollection];descriptor=[descriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightMedium)}}];self.view.font=[UIFont fontWithDescriptor:descriptor size:0];
}
@end
@implementation UIColorPickerCPTextFieldCoordinator
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100019CF0 ea=0x100019cf0 end=0x100019e9c
- (instancetype)initWithField:(UIColorPickerCPTextField *)field {if((self=[super init]))_field=field;return self;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001A650 ea=0x10001a650 end=0x10001a7b5
- (void)textFieldValueChangedWithTextfield:(UITextField *)textField {
    if(!textField.text)return;NSNumber *value=self.field.conversionToValue(textField.text);if(value)self.field.setter(value.doubleValue);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001A810 ea=0x10001a810 end=0x10001a8b5
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacement {
    if(!textField.text)__builtin_trap();return self.field.shouldChangeCharacters(textField.text,range,replacement);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001BC80 ea=0x10001bc80 end=0x10001bc9e
- (void)textFieldDidEndEditing:(UITextField *)textField {self.field.editing=NO;[self.field updateView];}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001BCA0 ea=0x10001bca0 end=0x10001bcc1
- (void)textFieldDidBeginEditing:(UITextField *)textField {self.field.editing=YES;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001AA30 ea=0x10001aa30 end=0x10001aa44
- (BOOL)textFieldShouldReturn:(UITextField *)textField {[textField resignFirstResponder];return YES;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001AA70 ea=0x10001aa70 end=0x10001ad58
- (void)textFieldDidChangeSelection:(UITextField *)textField {
    if(!self.field.selectionOnNumber)return;
    UITextRange *selection=textField.selectedTextRange;
    if(!selection||![selection.start isEqual:selection.end]||!textField.text)return;
    NSRange digits=UIColorPickerFirstNumberRange(textField.text);if(digits.location==NSNotFound)return;
    NSInteger current=[textField offsetFromPosition:textField.beginningOfDocument toPosition:selection.start];
    NSInteger end=(NSInteger)NSMaxRange(digits);if(current>=(NSInteger)digits.location&&current<=end)return;
    NSInteger clamped=current<(NSInteger)digits.location?(NSInteger)digits.location:end;
    UITextPosition *position=[textField positionFromPosition:textField.beginningOfDocument offset:clamped];if(!position)__builtin_trap();
    textField.selectedTextRange=[textField textRangeFromPosition:position toPosition:position];
}
@end
@implementation UIColorPickerSelectionTextField
// BINMAP-ADAPT: UIColorPickerSelectionTextField.setSelectedTextRange:
- (void)setSelectedTextRange:(UITextRange *)range {
    [super setSelectedTextRange:range];if(self.forwardingSelection)return;
    self.forwardingSelection=YES;[self.selectionCoordinator textFieldDidChangeSelection:self];self.forwardingSelection=NO;
}
@end
