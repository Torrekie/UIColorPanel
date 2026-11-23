#import "UIColorPanelAppearance.h"
#import "UIColorPanelSymbolOutlines.h"
#import <string.h>
#import <math.h>

#if UICOLORPANEL_ENABLE_PRIVATE_API
#import <objc/runtime.h>
@interface CALayer (UIColorPanelOptionalCorners)
- (void)setContinuousCorners:(BOOL)continuous;
@end
#endif

@implementation UIColorPanelAppearance
// BINMAP-ADAPT: UIColorPanelAppearance.resourceBundle manifest=reimpl/polish_appearance_extras.json
+ (NSBundle *)resourceBundle {
    NSBundle *owner=[NSBundle bundleForClass:self];
    NSURL *url=[owner URLForResource:@"UIColorPanelKit" withExtension:@"bundle"]?:[NSBundle.mainBundle URLForResource:@"UIColorPanelKit" withExtension:@"bundle"];
    return url?[NSBundle bundleWithURL:url]?:owner:owner;
}
// BINMAP-ADAPT: UIColorPanelAppearance.localizedString: manifest=reimpl/polish_appearance_extras.json
+ (NSString *)localizedString:(NSString *)englishKey {
    if(!englishKey.length)return englishKey?:@"";
    NSString *missing=@"\uFFFCUIColorPanelKit.missing";
    NSString *host=[NSBundle.mainBundle localizedStringForKey:englishKey value:missing table:@"UIColorPanelKit"];
    if(![host isEqualToString:missing])return host;
    NSBundle *bundle=[self resourceBundle];NSString *value=[bundle localizedStringForKey:englishKey value:missing table:@"UIColorPanelKit"];
    if(![value isEqualToString:missing])return value;
    NSString *path=[bundle pathForResource:@"en" ofType:@"lproj"];
    NSBundle *english=path?[NSBundle bundleWithPath:path]:nil;
    return english?[english localizedStringForKey:englishKey value:englishKey table:@"UIColorPanelKit"]:englishKey;
}
// BINMAP-ADAPT: UIColorPanelAppearance.imageForSymbol:size: manifest=reimpl/polish_appearance_extras.json
+ (UIImage *)imageForSymbol:(NSString *)name size:(CGFloat)size {
    size=isfinite(size)?MAX(8,MIN(64,size)):20;
    if(@available(iOS 13.0,*)){
        NSString *systemName=@{@"wheel":@"camera.aperture",@"sliders":@"slider.horizontal.3",@"palette":@"square.grid.2x2",@"image":@"photo",@"grid":@"square.grid.3x3.fill",@"pencils":@"pencil.tip"}[name];
        if(systemName){
            UIImageSymbolConfiguration *configuration=[UIImageSymbolConfiguration configurationWithPointSize:size weight:UIImageSymbolWeightRegular scale:UIImageSymbolScaleMedium];
            UIImage *image=[UIImage systemImageNamed:systemName withConfiguration:configuration];
            if(image)return[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
    NSString *symbol=[name isEqualToString:@"close"]?@"xmark":name;
    const UIColorPanelSymbolOutline *outline=NULL;
    for(NSUInteger index=0;index<sizeof(UIColorPanelSymbolOutlines)/sizeof(UIColorPanelSymbolOutlines[0]);index++){
        if(strcmp(symbol.UTF8String?:"",UIColorPanelSymbolOutlines[index].name)==0){outline=&UIColorPanelSymbolOutlines[index];break;}
    }
    // Older systems and unavailable SF Symbols retain the authored artwork.
    // Preserve the existing visible fallback for unknown component names.
    if(!outline)outline=&UIColorPanelSymbolOutlines[0];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size,size),NO,0);CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context,size/24,size/24);CGContextSetFillColorWithColor(context,UIColor.blackColor.CGColor);CGContextSetStrokeColorWithColor(context,UIColor.blackColor.CGColor);
    CGContextSetLineWidth(context,1.75);CGContextSetLineCap(context,kCGLineCapRound);CGContextSetLineJoin(context,kCGLineJoinRound);CGContextBeginPath(context);
    for(NSUInteger index=0;index<outline->count;index++){
        UIColorPanelSymbolCommand command=outline->commands[index];CGFloat *p=command.coordinates;
        switch(command.operation){
            case 'M':CGContextMoveToPoint(context,p[0],p[1]);break;
            case 'L':CGContextAddLineToPoint(context,p[0],p[1]);break;
            case 'Q':CGContextAddQuadCurveToPoint(context,p[0],p[1],p[2],p[3]);break;
            case 'C':CGContextAddCurveToPoint(context,p[0],p[1],p[2],p[3],p[4],p[5]);break;
            case 'Z':CGContextClosePath(context);break;
            case 'E':CGContextAddEllipseInRect(context,CGRectMake(p[0],p[1],p[2],p[3]));break;
            case 'R':{CGPathRef path=CGPathCreateWithRoundedRect(CGRectMake(p[0],p[1],p[2],p[3]),p[4],p[4],NULL);CGContextAddPath(context,path);CGPathRelease(path);break;}
            case 'S':CGContextStrokePath(context);break;
            case 'F':CGContextFillPath(context);break;
        }
    }
    CGContextFillPath(context);UIImage *image=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();return[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}
// BINMAP-ADAPT: UIColorPanelAppearance.smoothPathForRect:radius: manifest=reimpl/polish_appearance_extras.json
+ (UIBezierPath *)smoothPathForRect:(CGRect)rect radius:(CGFloat)radius {
    CGRect bounds=CGRectStandardize(rect);
    // Radius keeps the familiar 45-degree inset of a circular corner. A longer
    // transition reaches zero curvature at each straight edge. This authored
    // public approximation does not claim CoreAnimation's private geometry.
    CGFloat diagonalRatio=1-M_SQRT1_2,reachRatio=3-M_SQRT2;
    CGFloat r=isfinite(radius)?MAX(0,MIN(radius,MIN(bounds.size.width,bounds.size.height)/(2*reachRatio))):0;
    if(r<=0)return[UIBezierPath bezierPathWithRect:bounds];
    CGFloat d=r*diagonalRatio,reach=r*reachRatio;
    CGFloat left=CGRectGetMinX(bounds),right=CGRectGetMaxX(bounds),top=CGRectGetMinY(bounds),bottom=CGRectGetMaxY(bounds);
    // The two cubics meet at the diagonal with matching first and second
    // derivatives. Their edge endpoints have collinear derivative vectors,
    // hence zero curvature. Clamp the full reach, not just nominal radius.
    UIBezierPath *path=[UIBezierPath bezierPath];[path moveToPoint:CGPointMake(left+reach,top)];[path addLineToPoint:CGPointMake(right-reach,top)];
    [path addCurveToPoint:CGPointMake(right-d,top+d) controlPoint1:CGPointMake(right-4*d,top) controlPoint2:CGPointMake(right-2*d,top)];
    [path addCurveToPoint:CGPointMake(right,top+reach) controlPoint1:CGPointMake(right,top+2*d) controlPoint2:CGPointMake(right,top+4*d)];[path addLineToPoint:CGPointMake(right,bottom-reach)];
    [path addCurveToPoint:CGPointMake(right-d,bottom-d) controlPoint1:CGPointMake(right,bottom-4*d) controlPoint2:CGPointMake(right,bottom-2*d)];
    [path addCurveToPoint:CGPointMake(right-reach,bottom) controlPoint1:CGPointMake(right-2*d,bottom) controlPoint2:CGPointMake(right-4*d,bottom)];[path addLineToPoint:CGPointMake(left+reach,bottom)];
    [path addCurveToPoint:CGPointMake(left+d,bottom-d) controlPoint1:CGPointMake(left+4*d,bottom) controlPoint2:CGPointMake(left+2*d,bottom)];
    [path addCurveToPoint:CGPointMake(left,bottom-reach) controlPoint1:CGPointMake(left,bottom-2*d) controlPoint2:CGPointMake(left,bottom-4*d)];[path addLineToPoint:CGPointMake(left,top+reach)];
    [path addCurveToPoint:CGPointMake(left+d,top+d) controlPoint1:CGPointMake(left,top+4*d) controlPoint2:CGPointMake(left,top+2*d)];
    [path addCurveToPoint:CGPointMake(left+reach,top) controlPoint1:CGPointMake(left+2*d,top) controlPoint2:CGPointMake(left+4*d,top)];[path closePath];return path;
}
// BINMAP-ADAPT: UIColorPanelAppearance.applyCornersToView:radius:useSPI: manifest=reimpl/polish_appearance_extras.json
+ (void)applyCornersToView:(UIView *)view radius:(CGFloat)radius useSPI:(BOOL)useSPI {
    CALayer *layer=view.layer;CGFloat r=isfinite(radius)?MAX(0,radius):0;
    if(@available(iOS 13.0,*)){
        if([layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"])layer.mask=nil;
        layer.cornerRadius=r;layer.cornerCurve=kCACornerCurveContinuous;layer.masksToBounds=YES;return;
    }
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(useSPI&&[layer respondsToSelector:@selector(setContinuousCorners:)]){
        Method method=class_getInstanceMethod(object_getClass(layer),@selector(setContinuousCorners:));
        const char *encoding=method?method_getTypeEncoding(method):NULL;
        NSMethodSignature *signature=encoding?[NSMethodSignature signatureWithObjCTypes:encoding]:nil;
        const char *result=signature.methodReturnType,*argument=signature.numberOfArguments==3?[signature getArgumentTypeAtIndex:2]:NULL;
        while(result&&*result&&strchr("rnNoORV",*result))result++;
        while(argument&&*argument&&strchr("rnNoORV",*argument))argument++;
        BOOL compatible=signature.numberOfArguments==3&&result&&result[0]=='v'&&result[1]=='\0'&&argument&&(argument[0]=='B'||argument[0]=='c')&&argument[1]=='\0';
        if(compatible){
            if([layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"])layer.mask=nil;
            layer.cornerRadius=r;[layer setContinuousCorners:YES];layer.masksToBounds=YES;return;
        }
    }
#else
    (void)useSPI;
#endif
    layer.cornerRadius=0;CAShapeLayer *mask=[layer.mask isKindOfClass:CAShapeLayer.class]&&[layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"]?(CAShapeLayer *)layer.mask:[CAShapeLayer layer];
    mask.name=@"UIColorPanelAppearance.smoothMask";mask.frame=layer.bounds;mask.path=[self smoothPathForRect:mask.bounds radius:r].CGPath;mask.fillColor=UIColor.blackColor.CGColor;layer.mask=mask;
}
// BINMAP-ADAPT: UIColorPanelAppearance.formatNumber:significantDigits: manifest=reimpl/polish_appearance_extras.json
+ (NSString *)formatNumber:(double)number significantDigits:(NSUInteger)digits {return[self formatNumber:number significantDigits:digits locale:nil];}
// BINMAP-ADAPT: UIColorPanelAppearance.formatNumber:significantDigits:locale: manifest=reimpl/polish_appearance_extras.json
+ (NSString *)formatNumber:(double)number significantDigits:(NSUInteger)digits locale:(NSLocale *)locale {
    if(!isfinite(number))return @"—";
    NSNumberFormatter *formatter=[NSNumberFormatter new];formatter.locale=locale?:NSLocale.currentLocale;formatter.usesGroupingSeparator=NO;formatter.roundingMode=NSNumberFormatterRoundHalfEven;
    NSInteger exponent=number==0?0:(NSInteger)floor(log10(fabs(number)));
    formatter.numberStyle=digits&&(exponent>=(NSInteger)digits||exponent< -4)?NSNumberFormatterScientificStyle:NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator=NO;formatter.maximumIntegerDigits=309;
    if(digits){formatter.usesSignificantDigits=YES;formatter.minimumSignificantDigits=1;formatter.maximumSignificantDigits=MIN((NSUInteger)17,digits);}
    else{formatter.usesSignificantDigits=NO;formatter.minimumFractionDigits=0;formatter.maximumFractionDigits=0;}
    return[formatter stringFromNumber:@(number)]?:@"—";
}
// BINMAP-ADAPT: UIColorPanelAppearance.parseNumber: manifest=reimpl/polish_appearance_extras.json
+ (NSNumber *)parseNumber:(NSString *)text {return[self parseNumber:text locale:nil];}
// BINMAP-ADAPT: UIColorPanelAppearance.parseNumber:locale: manifest=reimpl/polish_appearance_extras.json
+ (NSNumber *)parseNumber:(NSString *)text locale:(NSLocale *)locale {
    NSString *clean=[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    // Number formatters may emit directional marks around localized signs.
    NSArray<NSString *> *directionalMarks=@[@"\u061C",@"\u200E",@"\u200F",@"\u202A",@"\u202B",@"\u202C",@"\u202D",@"\u202E",@"\u2066",@"\u2067",@"\u2068",@"\u2069"];
    for(NSString *mark in directionalMarks)clean=[clean stringByReplacingOccurrencesOfString:mark withString:@""];
    if(!clean.length)return nil;
    for(NSNumber *style in @[@(NSNumberFormatterDecimalStyle),@(NSNumberFormatterScientificStyle)]){
        NSNumberFormatter *formatter=[NSNumberFormatter new];formatter.locale=locale?:NSLocale.currentLocale;formatter.numberStyle=style.unsignedIntegerValue;formatter.usesGroupingSeparator=NO;formatter.lenient=NO;formatter.generatesDecimalNumbers=NO;
        if(formatter.groupingSeparator.length&&![formatter.groupingSeparator isEqualToString:formatter.decimalSeparator]&&[clean rangeOfString:formatter.groupingSeparator].location!=NSNotFound)continue;
        NSRange range=NSMakeRange(0,clean.length);id number=nil;NSError *error=nil;
        if([formatter getObjectValue:&number forString:clean range:&range error:&error]&&NSMaxRange(range)==clean.length&&[number isKindOfClass:NSNumber.class]&&isfinite([number doubleValue]))return number;
    }
    // Some older ICU formatters emit a localized exponent token that their
    // own parser does not accept (iOS12 ar_EG is one observed example). Derive
    // that token from real output instead of hard-coding a language spelling.
    NSNumberFormatter *scientific=[NSNumberFormatter new];scientific.locale=locale?:NSLocale.currentLocale;scientific.numberStyle=NSNumberFormatterScientificStyle;scientific.usesGroupingSeparator=NO;scientific.maximumFractionDigits=0;
    NSNumberFormatter *decimal=[NSNumberFormatter new];decimal.locale=scientific.locale;decimal.numberStyle=NSNumberFormatterDecimalStyle;decimal.usesGroupingSeparator=NO;decimal.lenient=NO;
    if(decimal.groupingSeparator.length&&![decimal.groupingSeparator isEqualToString:decimal.decimalSeparator]&&[clean rangeOfString:decimal.groupingSeparator].location!=NSNotFound)return nil;
    NSString *probe=[scientific stringFromNumber:@10000000],*minus=decimal.minusSign?:@"-",*plus=decimal.plusSign?:@"+",*declared=scientific.exponentSymbol?:@"";
    for(NSString *mark in directionalMarks){probe=[probe stringByReplacingOccurrencesOfString:mark withString:@""];minus=[minus stringByReplacingOccurrencesOfString:mark withString:@""];plus=[plus stringByReplacingOccurrencesOfString:mark withString:@""];declared=[declared stringByReplacingOccurrencesOfString:mark withString:@""];}
    NSMutableCharacterSet *probeEdges=[NSCharacterSet.decimalDigitCharacterSet mutableCopy];[probeEdges addCharactersInString:minus];[probeEdges addCharactersInString:plus];
    NSString *observed=[probe stringByTrimmingCharactersInSet:probeEdges];NSMutableArray<NSString *> *markers=[NSMutableArray new];if(observed.length)[markers addObject:observed];if(declared.length&&![markers containsObject:declared])[markers addObject:declared];
    for(NSString *marker in markers){
        NSArray<NSString *> *parts=[clean componentsSeparatedByString:marker];if(parts.count!=2)continue;
        NSMutableArray<NSString *> *asciiParts=[NSMutableArray new];BOOL valid=YES;
        for(NSUInteger index=0;index<2;index++){
            NSString *token=parts[index];if(minus.length)token=[token stringByReplacingOccurrencesOfString:minus withString:@"-"];if(plus.length)token=[token stringByReplacingOccurrencesOfString:plus withString:@"+"];
            if(index==0&&decimal.decimalSeparator.length)token=[token stringByReplacingOccurrencesOfString:decimal.decimalSeparator withString:@"."];
            NSMutableString *ascii=[NSMutableString new];NSUInteger digitCount=0;
            for(NSUInteger offset=0;offset<token.length;){NSRange range=[token rangeOfComposedCharacterSequenceAtIndex:offset];offset=NSMaxRange(range);NSString *piece=[token substringWithRange:range];
                if([piece rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location!=NSNotFound){NSNumber *digit=[decimal numberFromString:piece];if(!digit||digit.integerValue<0||digit.integerValue>9){valid=NO;break;}[ascii appendFormat:@"%ld",(long)digit.integerValue];digitCount++;}
                else if(([piece isEqualToString:@"-"]||[piece isEqualToString:@"+"])&&range.location==0)[ascii appendString:piece];
                else if(index==0&&[piece isEqualToString:@"."])[ascii appendString:piece];
                else{valid=NO;break;}
            }
            if(!valid||digitCount==0){valid=NO;break;}[asciiParts addObject:ascii];
        }
        if(!valid)continue;
        NSString *canonical=[NSString stringWithFormat:@"%@E%@",asciiParts[0],asciiParts[1]];NSScanner *scanner=[NSScanner scannerWithString:canonical];scanner.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US_POSIX"];scanner.charactersToBeSkipped=nil;double number=0;
        if([scanner scanDouble:&number]&&scanner.isAtEnd&&isfinite(number)){
            // A nonzero component must not silently become zero by underflow.
            if(number==0&&[asciiParts[0] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"123456789"]].location!=NSNotFound)continue;
            return @(number);
        }
    }
    return nil;
}
@end
