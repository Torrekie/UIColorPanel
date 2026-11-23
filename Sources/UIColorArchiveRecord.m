#import "UIColorArchiveRecord.h"
#import <objc/runtime.h>
#import <math.h>

const char UIColorArchiveMetadataAssociationKey = 0;

@implementation UIColorSpaceArchiveRecord {
    CGColorSpaceRef _space;
}
@synthesize CGColorSpace = _space;
// BINMAP-ADAPT: UIColorSpaceArchiveRecord.supportsSecureCoding manifest=reimpl/color_list_extras.json
+ (BOOL)supportsSecureCoding { return YES; }
// BINMAP-ADAPT: UIColorSpaceArchiveRecord.initWithCGColorSpace: manifest=reimpl/color_list_extras.json
- (instancetype)initWithCGColorSpace:(CGColorSpaceRef)space {
    if (!space) return nil;
    if ((self = [super init])) _space = CGColorSpaceRetain(space);
    return self;
}
// BINMAP-ADAPT: UIColorSpaceArchiveRecord.dealloc manifest=reimpl/color_list_extras.json
- (void)dealloc { if (_space) CGColorSpaceRelease(_space); }
// BINMAP-ADAPT: UIColorSpaceArchiveRecord.initWithCoder: manifest=reimpl/color_list_extras.json
// Native schema/control cases: -[NSColorSpace initWithCoder:] 0x18375e87c, panel_api_evidence.json.
- (instancetype)initWithCoder:(NSCoder *)coder {
    NSInteger identifier = [coder decodeIntegerForKey:[coder containsValueForKey:@"NSSpaceID"] ? @"NSSpaceID" : @"NSID"];
    CGColorSpaceRef space = NULL;
    switch (identifier) {
        case 1: space=CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB); break;
        case 2: space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGray); break;
        case 3: space=CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK); break;
        case 4: space=CGColorSpaceCreateDeviceRGB(); break;
        case 5: space=CGColorSpaceCreateDeviceGray(); break;
        case 6: space=CGColorSpaceCreateDeviceCMYK(); break;
        case 7: space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB); break;
        case 8: space=CGColorSpaceCreateWithName(kCGColorSpaceAdobeRGB1998); break;
        case 9: space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGrayGamma2_2); break;
        case 12: space=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3); break;
        case 14: space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB); break;
        case 15: space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedGray); break;
        default: break;
    }
    if (!space) {
        NSData *profile=[coder decodeObjectOfClass:NSData.class forKey:@"NSICC"];
        if (profile) space=CGColorSpaceCreateWithICCData((__bridge CFDataRef)profile);
        else {
            NSInteger model=[coder containsValueForKey:@"NSModel"]?[coder decodeIntegerForKey:@"NSModel"]:1;
            if (model==0) space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
            else if (model==1) space=CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            else if (model==2) space=CGColorSpaceCreateDeviceCMYK();
        }
    }
    if (!space) return nil;
    self=[self initWithCGColorSpace:space];CGColorSpaceRelease(space);return self;
}
// BINMAP-ADAPT: UIColorSpaceArchiveRecord.encodeWithCoder: manifest=reimpl/color_list_extras.json
// Native schema: -[NSColorSpace encodeWithCoder:] 0x183936584; IDs verified with native space-N.keyed fixtures.
- (void)encodeWithCoder:(NSCoder *)coder {
    CFStringRef name=CGColorSpaceCopyName(_space);
    NSDictionary *identifiers=@{(__bridge NSString *)kCGColorSpaceGenericRGB:@1,(__bridge NSString *)kCGColorSpaceGenericGray:@2,(__bridge NSString *)kCGColorSpaceGenericCMYK:@3,@"kCGColorSpaceDeviceRGB":@4,@"kCGColorSpaceDeviceGray":@5,@"kCGColorSpaceDeviceCMYK":@6,(__bridge NSString *)kCGColorSpaceSRGB:@7,(__bridge NSString *)kCGColorSpaceAdobeRGB1998:@8,(__bridge NSString *)kCGColorSpaceGenericGrayGamma2_2:@9,(__bridge NSString *)kCGColorSpaceDisplayP3:@12,(__bridge NSString *)kCGColorSpaceExtendedSRGB:@14,(__bridge NSString *)kCGColorSpaceExtendedGray:@15};
    NSInteger identifier=name?[identifiers[(__bridge NSString *)name] integerValue]:0;
    if (name) CFRelease(name);
    if (identifier) [coder encodeInteger:identifier forKey:identifier>11?@"NSSpaceID":@"NSID"];
    if (identifier==0||identifier>=7) {
        CGColorSpaceModel model=CGColorSpaceGetModel(_space);
        if (model!=kCGColorSpaceModelRGB) [coder encodeInteger:model forKey:@"NSModel"];
        CFDataRef profile=CGColorSpaceCopyICCData(_space);
        if (profile) { [coder encodeObject:(__bridge NSData *)profile forKey:@"NSICC"];CFRelease(profile); }
    }
}
@end

@implementation UIColorArchiveRecord {
    NSString *_catalogName;
    NSString *_colorName;
}
// BINMAP-ADAPT: UIColorArchiveRecord.supportsSecureCoding manifest=reimpl/color_list_extras.json
+ (BOOL)supportsSecureCoding { return YES; }
// BINMAP-ADAPT: UIColorArchiveRecord.initWithColorValue: manifest=reimpl/color_list_extras.json
- (instancetype)initWithColorValue:(UIColorValue *)value {
    CGColorSpaceRef space=value?CGColorGetColorSpace(value.CGColor):NULL;
    if (!space||CGColorSpaceGetModel(space)==kCGColorSpaceModelPattern||CGColorSpaceGetModel(space)==kCGColorSpaceModelIndexed) return nil;
    if ((self=[super init])) {
        _colorValue=value;
        NSDictionary *metadata=objc_getAssociatedObject(value,&UIColorArchiveMetadataAssociationKey);
        _catalogName=metadata[@"catalogName"];_colorName=metadata[@"colorName"];
    }return self;
}
// BINMAP-ADAPT: UIColorArchiveRecord.initWithCoder: manifest=reimpl/color_list_extras.json
// Schema derived from NSColor initWithCoder: + concrete newWithCoder:zone: evidence; no NSColor runtime replacement.
- (instancetype)initWithCoder:(NSCoder *)coder {
    NSInteger code=[coder decodeIntegerForKey:@"NSColorSpace"];
    if (code==6) {
        NSString *catalog=[coder decodeObjectOfClass:NSString.class forKey:@"NSCatalogName"];
        NSString *name=[coder decodeObjectOfClass:NSString.class forKey:@"NSColorName"];
        UIColorArchiveRecord *fallback=[coder decodeObjectOfClass:UIColorArchiveRecord.class forKey:@"NSColor"];
        if (!fallback.colorValue||!catalog||!name) return nil;
        self=[self initWithColorValue:[[UIColorValue alloc]initWithCGColor:fallback.colorValue.CGColor]];
        if(self){_catalogName=[catalog copy];_colorName=[name copy];objc_setAssociatedObject(_colorValue,&UIColorArchiveMetadataAssociationKey,@{@"catalogName":_catalogName,@"colorName":_colorName},OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
        return self;
    }
    UIColorSpaceArchiveRecord *custom=[coder decodeObjectOfClass:UIColorSpaceArchiveRecord.class forKey:@"NSCustomColorSpace"];
    CGColorSpaceRef space=custom.CGColorSpace?CGColorSpaceRetain(custom.CGColorSpace):NULL;
    NSString *key=@"NSComponents";
    if (![coder containsValueForKey:key]) {
        if (code==1||code==2) key=@"NSRGB";
        else if (code==3||code==4) key=@"NSWhite";
        else if (code==5) key=@"NSCMYK";
        else if ([coder containsValueForKey:@"NSSRGB"]) key=@"NSSRGB";
        else { if(space)CGColorSpaceRelease(space);return nil; }
    }
    if(!space){
        if([key isEqual:@"NSSRGB"])space=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        else switch(code){case 1:space=CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);break;case 2:space=CGColorSpaceCreateDeviceRGB();break;case 3:space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);break;case 4:space=CGColorSpaceCreateDeviceGray();break;case 5:space=CGColorSpaceCreateDeviceCMYK();break;default:break;}
    }
    if(!space)return nil;
    NSUInteger length=0;const uint8_t *bytes=[coder decodeBytesForKey:key returnedLength:&length];
    if(!bytes||!length||length>2048){CGColorSpaceRelease(space);return nil;}
    if(bytes[length-1]==0)length--;
    NSString *text=[[NSString alloc]initWithBytes:bytes length:length encoding:NSASCIIStringEncoding];
    NSScanner *scanner=text?[NSScanner scannerWithString:text]:nil;scanner.locale=@{NSLocaleDecimalSeparator:@"."};
    NSUInteger count=CGColorSpaceGetNumberOfComponents(space);CGFloat values[6]={0};
    if(!scanner||count<1||count>5){CGColorSpaceRelease(space);return nil;}
    BOOL valid=YES;
    for(NSUInteger i=0;i<count;i++){double number;if(![scanner scanDouble:&number]||!isfinite(number)){valid=NO;break;}values[i]=number;}
    values[count]=1;
    if(valid&&!scanner.isAtEnd){double alpha;valid=[scanner scanDouble:&alpha]&&isfinite(alpha)&&scanner.isAtEnd;if(valid)values[count]=alpha;}
    if(valid){
        // NSColorSpaceColor bounds ordinary spaces on decode; extended-range spaces retain RGB/gray excursions.
        if(!CGColorSpaceUsesExtendedRange(space)&&CGColorSpaceGetModel(space)!=kCGColorSpaceModelLab)for(NSUInteger i=0;i<count;i++)values[i]=MAX(0,MIN(1,values[i]));
        values[count]=MAX(0,MIN(1,values[count]));
    }
    CGColorRef color=valid?CGColorCreate(space,values):NULL;CGColorSpaceRelease(space);
    if(!color)return nil;
    self=[self initWithColorValue:[[UIColorValue alloc]initWithCGColor:color]];CGColorRelease(color);return self;
}
// BINMAP-ADAPT: UIColorArchiveRecord.encodeWithCoder: manifest=reimpl/color_list_extras.json
// Native fields and precision from concrete encoders and sub_183B17C98 in panel_api_evidence.json.
- (void)encodeWithCoder:(NSCoder *)coder {
    if(_catalogName&&_colorName){
        [coder encodeInteger:6 forKey:@"NSColorSpace"];[coder encodeObject:_catalogName forKey:@"NSCatalogName"];[coder encodeObject:_colorName forKey:@"NSColorName"];
        UIColorArchiveRecord *fallback=[[UIColorArchiveRecord alloc]initWithColorValue:_colorValue];fallback->_catalogName=nil;fallback->_colorName=nil;[coder encodeObject:fallback forKey:@"NSColor"];return;
    }
    CGColorSpaceRef space=CGColorGetColorSpace(_colorValue.CGColor);CGColorSpaceModel model=CGColorSpaceGetModel(space);
    NSUInteger count=CGColorSpaceGetNumberOfComponents(space);const CGFloat *values=CGColorGetComponents(_colorValue.CGColor);
    NSMutableArray *components=[NSMutableArray array];for(NSUInteger i=0;i<=count;i++)[components addObject:[NSString stringWithFormat:@"%.10g",(double)values[i]]];
    NSData *exact=[[components componentsJoinedByString:@" "] dataUsingEncoding:NSASCIIStringEncoding];
    CGColorSpaceRef device=NULL;
    if(model==kCGColorSpaceModelRGB)device=CGColorSpaceCreateDeviceRGB();else if(model==kCGColorSpaceModelMonochrome)device=CGColorSpaceCreateDeviceGray();else if(model==kCGColorSpaceModelCMYK)device=CGColorSpaceCreateDeviceCMYK();
    BOOL isDevice=device&&CFEqual(space,device);if(device)CGColorSpaceRelease(device);
    NSInteger code=model==kCGColorSpaceModelMonochrome?(isDevice?4:3):model==kCGColorSpaceModelCMYK?5:isDevice?2:1;
    [coder encodeInteger:code forKey:@"NSColorSpace"];
    NSString *legacyKey=code==3||code==4?@"NSWhite":code==5?@"NSCMYK":@"NSRGB";
    CGColorSpaceRef fallbackSpace=code==1?CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB):code==2?CGColorSpaceCreateDeviceRGB():code==3?CGColorSpaceCreateWithName(kCGColorSpaceGenericGray):code==4?CGColorSpaceCreateDeviceGray():CGColorSpaceCreateDeviceCMYK();
    UIColorValue *fallback=fallbackSpace?[_colorValue colorByConvertingToSpace:fallbackSpace error:NULL]:nil;
    if(fallbackSpace)CGColorSpaceRelease(fallbackSpace);
    const CGFloat *fallbackValues=fallback?CGColorGetComponents(fallback.CGColor):NULL;
    NSUInteger fallbackCount=fallback?CGColorGetNumberOfComponents(fallback.CGColor):model==kCGColorSpaceModelMonochrome?2:4;
    NSMutableArray *legacy=[NSMutableArray array];
    for(NSUInteger i=0;i<fallbackCount;i++){
        double component=fallbackValues?fallbackValues[i]:(i==fallbackCount-1?1:0);
        // The legacy component classes store floats for RGB/white, doubles for device CMYK.
        if(code!=5)component=(float)component;
        if(i==fallbackCount-1&&component>=1)break;
        [legacy addObject:[NSString stringWithFormat:@"%.10g",component]];
    }
    NSMutableData *legacyBytes=[[[legacy componentsJoinedByString:@" "] dataUsingEncoding:NSASCIIStringEncoding]mutableCopy];uint8_t zero=0;[legacyBytes appendBytes:&zero length:1];
    [coder encodeBytes:legacyBytes.bytes length:legacyBytes.length forKey:legacyKey];
    if(!isDevice){[coder encodeObject:[[UIColorSpaceArchiveRecord alloc]initWithCGColorSpace:space] forKey:@"NSCustomColorSpace"];[coder encodeBytes:exact.bytes length:exact.length forKey:@"NSComponents"];}
}
@end
