#import "UIColorPickerColorAccessibility.h"
#import "UIColorPanelAppearance.h"
#import <math.h>
#import <os/log.h>

// The original arm64 instructions multiply and add separately.
#pragma STDC FP_CONTRACT OFF

// BINMAP: original=Accessibility15_5 ida_name=_AXLocalizedString ea=0xa62c end=0xa6cc
static NSString * UIColorPickerAXLocalizedString(NSString *key) {
    // BINNOTE: Package the original table with the component instead of looking
    // up the private system framework's bundle. Empty value preserves native
    // literal-key fallback, including the missing "blue green" translation.
    NSURL *url=[[UIColorPanelAppearance resourceBundle] URLForResource:@"ColorAccessibility" withExtension:@"bundle"];
    NSBundle *bundle=url?[NSBundle bundleWithURL:url]:nil;
    return [bundle localizedStringForKey:key value:@"" table:@"Accessibility"];
}

// BINMAP: original=Accessibility15_5 ida_name=_AXColorDescriptionFromAttributeDescriptions ea=0x2a6c end=0x2bcc
static NSString * UIColorPickerAXColorDescriptionFromAttributeDescriptions(NSString *lightness,NSString *saturation,NSString *hue) {
    if(lightness.length){
        if(saturation.length)return [NSString localizedStringWithFormat:UIColorPickerAXLocalizedString(@"color.attributes.format.all"),lightness,saturation,hue];
        return [NSString localizedStringWithFormat:UIColorPickerAXLocalizedString(@"color.attributes.format.lightness.hue"),lightness,hue];
    }
    if(saturation.length)return [NSString localizedStringWithFormat:UIColorPickerAXLocalizedString(@"color.attributes.format.saturation.hue"),saturation,hue];
    return hue;
}

// BINMAP: original=Accessibility15_5 ida_name=_AXColorGetLightnessDescription ea=0x2bcc end=0x2c24
static NSString * UIColorPickerAXColorGetLightnessDescription(double luma) {
    if(luma<(double)0.35f)return UIColorPickerAXLocalizedString(@"dark");
    if(luma>(double)0.85f)return UIColorPickerAXLocalizedString(@"light");
    return nil;
}

// BINMAP: original=Accessibility15_5 ida_name=_AXNameFromColor ea=0x2094 end=0x2a6c
NSString * UIColorPickerAXNameFromColor(CGColorRef color) {
    const CGFloat *components=CGColorGetComponents(color);
    CGFloat alpha=CGColorGetAlpha(color);
    CGColorSpaceRef sourceSpace=CGColorGetColorSpace(color);
    CGFloat convertedComponents[4]={0};
    BOOL converted=NO;
    double red=-1,green=-1,blue=-1,colorAlpha=-1;
    if(components){
        static CGColorSpaceRef sRGB;
        static dispatch_once_t sRGBOnce;
        // BINMAP-BLOCK: original=Accessibility15_5 invoke_ea=0x2c24 end=0x2c4c parent_ea=0x2094 reconstructed_as=block_literal
        dispatch_once(&sRGBOnce,^{sRGB=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);});
        BOOL isRGB=sourceSpace==sRGB;
        if(!isRGB){
            static CGColorSpaceRef extendedSRGB;
            static dispatch_once_t extendedOnce;
            // BINMAP-BLOCK: original=Accessibility15_5 invoke_ea=0x2c4c end=0x2c74 parent_ea=0x2094 reconstructed_as=block_literal
            dispatch_once(&extendedOnce,^{extendedSRGB=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);});
            isRGB=sourceSpace==extendedSRGB;
        }
        if(!isRGB){
            // BINNOTE: The original calls private CGColorTransform conversion.
            // Use the component's public color-matching boundary and preserve
            // alpha. ICC threshold equivalence remains a scoped acceptance item.
            CGColorRef matched=CGColorCreateCopyByMatchingToColorSpace(sRGB,kCGRenderingIntentDefault,color,NULL);
            if(matched){
                const CGFloat *values=CGColorGetComponents(matched);
                convertedComponents[0]=values[0];convertedComponents[1]=values[1];convertedComponents[2]=values[2];convertedComponents[3]=alpha;
                components=convertedComponents;isRGB=YES;
                CGColorRelease(matched);
            }
        }
        if(isRGB){red=components[0];green=components[1];blue=components[2];colorAlpha=components[3];converted=YES;}
    }
    double minimum,maximum;
    if(red<green||red<blue){
        if(green<blue||green<red){minimum=green>=red?red:green;maximum=blue;}
        else {minimum=red>=blue?blue:red;maximum=green;}
    }else {minimum=green>=blue?blue:green;maximum=red;}
    double saturation=0,hueSector=0;
    if(maximum>0){
        saturation=(maximum-minimum)/maximum;
        double redDistance=(maximum-red)/(maximum-minimum);
        double greenDistance=(maximum-green)/(maximum-minimum);
        double blueDistance=(maximum-blue)/(maximum-minimum);
        double first=5-redDistance;
        if(minimum==red)first=greenDistance+3;
        double second=redDistance+1;
        if(minimum!=blue)second=3-blueDistance;
        if(maximum!=green)second=first;
        double third=1-greenDistance;
        if(minimum==green)third=blueDistance+5;
        if(maximum!=red)third=second;
        hueSector=saturation==0?0:third;
    }
    NSMutableDictionary *attributes=[@{@"red":@(red),@"green":@(green),@"blue":@(blue)} mutableCopy];
    if(converted)[attributes setValuesForKeysWithDictionary:@{@"hue":@(fmod(hueSector/6,1)),@"saturation":@(saturation),@"brightness":@(maximum),@"alpha":@(colorAlpha)}];
    BOOL hasHue=attributes[@"hue"]!=nil;
    double hue=[attributes[@"hue"] doubleValue];
    saturation=[attributes[@"saturation"] doubleValue];
    colorAlpha=[attributes[@"alpha"] doubleValue];
    red=[attributes[@"red"] doubleValue];green=[attributes[@"green"] doubleValue];blue=[attributes[@"blue"] doubleValue];
    if(!hasHue)return nil;
    if(colorAlpha==0)return UIColorPickerAXLocalizedString(@"transparent");
    double luma=fmin(fmax(colorAlpha*(red*(double)0.2126f+green*(double)0.7152f+blue*(double)0.0722f),0),1);
    if(luma>(double)0.99f)return UIColorPickerAXLocalizedString(@"white");
    if(luma<(double)0.01f)return UIColorPickerAXLocalizedString(@"black");
    if(saturation<(double)0.05f)return UIColorPickerAXColorDescriptionFromAttributeDescriptions(UIColorPickerAXColorGetLightnessDescription(luma),nil,UIColorPickerAXLocalizedString(@"gray"));
    NSString *lightness=UIColorPickerAXColorGetLightnessDescription(luma);
    NSString *saturationDescription=nil;
    if(saturation<(double)0.2f)saturationDescription=UIColorPickerAXLocalizedString(@"grayish");
    else if(saturation>(double)0.9f&&luma>(double)0.7f)saturationDescription=UIColorPickerAXLocalizedString(@"vibrant");
    NSString *hueKey=nil;
    // BINNOTE:15.5 changes14.5's brown luma threshold from0.43f to0.54f.
    if(hue>(double)0.056f&&hue<(double)0.111f&&luma<(double)0.54f){hueKey=@"brown";} else if(hue<0||hue>1){
        // BINMAP: original=Accessibility15_5 ida_name=_AXNameFromColor.cold.1 ea=0xf7ec end=0xf864 reconstructed_as=public_os_log_macro
        os_log_error(OS_LOG_DEFAULT,"Hue value should be in range [0..1f], got %f",hue);
    }
    else if(hue<(double)0.028f)hueKey=@"red";
    else if(hue<(double)0.056f)hueKey=@"red orange";
    else if(hue<(double)0.111f)hueKey=@"orange";
    else if(hue<(double)0.129f)hueKey=@"orange yellow";
    else if(hue<(double)0.167f)hueKey=@"yellow";
    else if(hue<(double)0.222f)hueKey=@"yellow green";
    else if(hue<(double)0.389f)hueKey=@"green";
    else if(hue<(double)0.469f)hueKey=@"blue green";
    else if(hue<(double)0.540f)hueKey=@"cyan";
    else if(hue<(double)0.611f)hueKey=@"cyan blue";
    else if(hue<(double)0.667f)hueKey=@"blue";
    else if(hue<(double)0.800f)hueKey=@"blue magenta";
    else if(hue<(double)0.889f)hueKey=@"magenta";
    else if(hue<(double)0.917f)hueKey=@"magenta pink";
    else if(hue<(double)0.958f)hueKey=@"pink";
    else if(hue<(double)0.986f)hueKey=@"pink red";
    else hueKey=@"red";
    return UIColorPickerAXColorDescriptionFromAttributeDescriptions(lightness,saturationDescription,hueKey?UIColorPickerAXLocalizedString(hueKey):nil);
}

// BINMAP: original=AXUIUtilities14_5 ida_name=AXColorGetLuma ea=0xb758 end=0xb7dc
static double UIColorPickerAXColorGetLuma(UIColor *color) {
    CGFloat red,green,blue,alpha;
    // BINNOTE: The original ignores failure and reads uninitialized locals.
    // Preserve success math; report unavailable luma for unsupported UIColors.
    if(![color getRed:&red green:&green blue:&blue alpha:&alpha])return NAN;
    return fmin(fmax(alpha*(red*(double)0.2126f+green*(double)0.7152f+blue*(double)0.0722f),0),1);
}

// BINMAP: original=AXUIUtilities14_5 ida_name=AXColorStringForColor ea=0xb5b4 end=0xb710
NSString * UIColorPickerAXColorStringForColor(UIColor *color,unsigned char options) {
    NSString *name;
    // Public API replaces the original private framework import on newer iOS.
    if(@available(iOS 14.0,*))name=color.accessibilityName;
    else name=UIColorPickerAXNameFromColor(color.CGColor);
    if(!name)return nil;
    NSMutableString *result=[name mutableCopy];
    if(options&1){
        static NSNumberFormatter *formatter;
        static dispatch_once_t once;
        // BINMAP-BLOCK: original=AXUIUtilities14_5 invoke_ea=0xb710 end=0xb758 parent_ea=0xb5b4 reconstructed_as=block_literal
        dispatch_once(&once,^{formatter=[NSNumberFormatter new];formatter.numberStyle=NSNumberFormatterDecimalStyle;});
        double luma=UIColorPickerAXColorGetLuma(color);
        if(isnan(luma))return [NSString stringWithString:result];
        NSUInteger rounded=(NSUInteger)round(luma*100);
        [result appendFormat:@" %@",[formatter stringFromNumber:@(rounded)]];
    }
    return [NSString stringWithString:result];
}
