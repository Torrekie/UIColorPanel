#import "UIColorPickerFormatting.h"
#import <math.h>
static NSNumberFormatter *percentageFormatter, *percentageParser, *integerFormatter;
static dispatch_once_t percentageOnce, percentageParserOnce, integerOnce;

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_1000304B0 ea=0x1000304b0 end=0x10003058f
static NSNumberFormatter *UIColorPickerMakePercentageFormatter(void) {
    NSNumberFormatter *formatter=[NSNumberFormatter new];
    formatter.locale=NSLocale.currentLocale;
    formatter.allowsFloats=NO; formatter.numberStyle=NSNumberFormatterPercentStyle;
    formatter.minimumFractionDigits=0; formatter.maximumFractionDigits=0;
    return formatter;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030490 ea=0x100030490 end=0x1000304a2
static void UIColorPickerInitializePercentageFormatter(void *context) {
    percentageFormatter=UIColorPickerMakePercentageFormatter();
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030590 ea=0x100030590 end=0x10003064e
NSString *UIColorPickerPercentageText(double value) {
    dispatch_once_f(&percentageOnce,NULL,UIColorPickerInitializePercentageFormatter);
    return [percentageFormatter stringFromNumber:@(value)]?:@"";
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100031290 ea=0x100031290 end=0x1000312b8
static void UIColorPickerInitializePercentageParser(void *context) {
    percentageParser=[NSNumberFormatter new];
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030650 ea=0x100030650 end=0x100030a1d
NSNumber *UIColorPickerPercentageValue(NSString *text) {
    NSMutableString *digits=[NSMutableString new];
    NSCharacterSet *nonDigits=NSCharacterSet.decimalDigitCharacterSet.invertedSet;
    for(NSUInteger index=0;index<text.length;) {
        NSRange range=[text rangeOfComposedCharacterSequenceAtIndex:index];
        NSString *character=[text substringWithRange:range];
        if([character rangeOfCharacterFromSet:nonDigits].location==NSNotFound)[digits appendString:character];
        index=NSMaxRange(range);
    }
    dispatch_once_f(&percentageParserOnce,NULL,UIColorPickerInitializePercentageParser);
    NSNumber *number=[percentageParser numberFromString:digits];
    // BINNOTE: Hex-Rays loses the Optional<Double> tag. Raw x86_64 sets dl=1
    // on failure, so returning zero here would incorrectly overwrite a draft.
    if(!number)return nil;
    double value=(double)number.integerValue/100.0;
    return @(fmin(value>=0?value:0,1));
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030AF0 ea=0x100030af0 end=0x100030c8a
BOOL UIColorPickerPercentageCharactersAllowed(NSString *text) {
    dispatch_once_f(&percentageOnce,NULL,UIColorPickerInitializePercentageFormatter);
    NSMutableCharacterSet *allowed=[NSCharacterSet.decimalDigitCharacterSet mutableCopy];
    [allowed formUnionWithCharacterSet:NSCharacterSet.whitespaceCharacterSet];
    [allowed addCharactersInString:percentageFormatter.percentSymbol];
    return [text rangeOfCharacterFromSet:allowed.invertedSet].location==NSNotFound;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030A20 ea=0x100030a20 end=0x100030ae1
BOOL UIColorPickerCanEditPercentage(NSString *text, NSRange range, NSString *replacement) {
    if(!UIColorPickerPercentageCharactersAllowed(text))return YES;
    return UIColorPickerPercentageCharactersAllowed([text stringByReplacingCharactersInRange:range withString:replacement]);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030C90 ea=0x100030c90 end=0x100030d3d
static void UIColorPickerInitializeIntegerFormatter(void *context) {
    integerFormatter=[NSNumberFormatter new]; integerFormatter.allowsFloats=NO;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030D40 ea=0x100030d40 end=0x100030e48
NSString *UIColorPickerIntegerText(double value) {
    double scaled=value*255.0;
    // Original Swift Int conversion traps for non-finite or overflowing values.
    if(!isfinite(scaled)||scaled<=-9.223372036854778e18||scaled>=9.223372036854776e18)__builtin_trap();
    NSInteger integer=(NSInteger)scaled;
    dispatch_once_f(&integerOnce,NULL,UIColorPickerInitializeIntegerFormatter);
    return [integerFormatter stringFromNumber:@(integer)]?:@"";
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030E50 ea=0x100030e50 end=0x100030f1b
NSNumber *UIColorPickerIntegerValue(NSString *text) {
    dispatch_once_f(&integerOnce,NULL,UIColorPickerInitializeIntegerFormatter);
    NSNumber *number=[integerFormatter numberFromString:text];
    if(!number)return nil;
    double value=fmin((double)number.integerValue/255.0,1);
    return @(value>=0?value:0);
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100030F20 ea=0x100030f20 end=0x100031071
BOOL UIColorPickerCanEditInteger(NSString *text, NSRange range, NSString *replacement) {
    NSString *candidate=[text stringByReplacingCharactersInRange:range withString:replacement];
    if([candidate rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location!=NSNotFound)return NO;
    NSUInteger count=0;
    for(NSUInteger index=0;index<candidate.length;count++)index=NSMaxRange([candidate rangeOfComposedCharacterSequenceAtIndex:index]);
    return count<4;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001BD00 ea=0x10001bd00 end=0x10001bfcb
NSRange UIColorPickerFirstNumberRange(NSString *text) {
    NSCharacterSet *nonDigits=NSCharacterSet.decimalDigitCharacterSet.invertedSet;
    NSUInteger ordinal=0,start=NSNotFound,length=0;
    for(NSUInteger index=0;index<text.length;ordinal++) {
        NSRange range=[text rangeOfComposedCharacterSequenceAtIndex:index];
        BOOL digit=[[text substringWithRange:range] rangeOfCharacterFromSet:nonDigits].location==NSNotFound;
        if(digit){if(start==NSNotFound)start=ordinal;length++;}
        else if(start!=NSNotFound)break;
        index=NSMaxRange(range);
    }
    return NSMakeRange(start,length);
}
@interface UIColorPickerSliderControlStyle ()
@property(nonatomic, readwrite) BOOL percentage;
@end
@implementation UIColorPickerSliderControlStyle
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100031080 ea=0x100031080 end=0x1000310be
+ (instancetype)integerStyle {
    UIColorPickerSliderControlStyle *style=[self new];
    style.floatToTextMapping=^NSString *(double value){return UIColorPickerIntegerText(value);};
    style.textToFloatMapping=^NSNumber *(NSString *text){return UIColorPickerIntegerValue(text);};
    style.shouldChangeCharacters=^BOOL(NSString *text,NSRange range,NSString *replacement){return UIColorPickerCanEditInteger(text,range,replacement);};
    return style;
}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100031150 ea=0x100031150 end=0x1000311c8
+ (instancetype)percentageStyle {
    UIColorPickerSliderControlStyle *style=[self new];style.percentage=YES;
    style.floatToTextMapping=^NSString *(double value){return UIColorPickerPercentageText(value);};
    style.textToFloatMapping=^NSNumber *(NSString *text){return UIColorPickerPercentageValue(text);};
    style.shouldChangeCharacters=^BOOL(NSString *text,NSRange range,NSString *replacement){return UIColorPickerCanEditPercentage(text,range,replacement);};
    return style;
}
// BINMAP-ADAPT: UIColorPickerSliderControlStyle.textForValue:
- (NSString *)textForValue:(double)value {return self.floatToTextMapping(value);}
// BINMAP-ADAPT: UIColorPickerSliderControlStyle.valueForText:
- (NSNumber *)valueForText:(NSString *)text {return self.textToFloatMapping(text);}
// BINMAP-ADAPT: UIColorPickerSliderControlStyle.canEditText:range:replacement:
- (BOOL)canEditText:(NSString *)text range:(NSRange)range replacement:(NSString *)replacement {return self.shouldChangeCharacters(text,range,replacement);}
@end

// Public equivalent of the original Swift os logging storage/accessors.
#import <os/log.h>
#import <os/signpost.h>
static os_log_t pickerLog;
static os_signpost_id_t pickerSignpost;
static dispatch_once_t pickerLogOnce,pickerSignpostOnce;
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100011200 ea=0x100011200 end=0x100011257
static void UIColorPickerInitializeLog(void *context) {pickerLog=os_log_create("com.apple.uikit.ColorPicker","ColorPicker");}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100011260 ea=0x100011260 end=0x10001128c
os_log_t UIColorPickerLog(void) {dispatch_once_f(&pickerLogOnce,NULL,UIColorPickerInitializeLog);return pickerLog;}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100011290 ea=0x100011290 end=0x1000112fd
static void UIColorPickerInitializeSignpost(void *context) {pickerSignpost=os_signpost_id_generate(UIColorPickerLog());}
// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_100011300 ea=0x100011300 end=0x10001133a
os_signpost_id_t UIColorPickerSignpostID(void) {dispatch_once_f(&pickerSignpostOnce,NULL,UIColorPickerInitializeSignpost);return pickerSignpost;}

// BINMAP: original=ColorPicker14_5-x86_64 ida_name=sub_10001ADC0 ea=0x10001adc0 end=0x10001ade8
UIEdgeInsets UIColorPickerScribbleHitTolerance(UIEdgeInsets defaultInsets) {return UIEdgeInsetsMake(defaultInsets.top,0,defaultInsets.bottom,0);}
