#import "UIColorArchive.h"
#import "UIColorArchiveRecord.h"
#import "UIColorLegacyColorListReader.h"
#import <objc/runtime.h>

NSErrorDomain const UIColorArchiveErrorDomain=@"UIColorArchiveErrorDomain";

@implementation UIColorArchive
// BINMAP-ADAPT: UIColorArchive.colorValueFromNSColorArchiveData:error: manifest=reimpl/color_list_extras.json
+ (UIColorValue *)colorValueFromNSColorArchiveData:(NSData *)data error:(NSError **)error {
    @try {
        NSKeyedUnarchiver *reader=[[NSKeyedUnarchiver alloc]initForReadingFromData:data error:error];
        if(!reader)return nil;
        reader.requiresSecureCoding=YES;reader.decodingFailurePolicy=NSDecodingFailurePolicySetErrorAndReturn;
        [reader setClass:UIColorArchiveRecord.class forClassName:@"NSColor"];
        [reader setClass:UIColorSpaceArchiveRecord.class forClassName:@"NSColorSpace"];
        UIColorArchiveRecord *record=[reader decodeObjectOfClass:UIColorArchiveRecord.class forKey:NSKeyedArchiveRootObjectKey];
        [reader finishDecoding];
        if(record.colorValue&&!reader.error)return record.colorValue;
        if(error)*error=reader.error?:[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorUnsupportedColor userInfo:@{NSLocalizedDescriptionKey:@"The archive does not contain a supported component color."}];
    }@catch(NSException *exception){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorInvalidData userInfo:@{NSLocalizedDescriptionKey:exception.reason?:@"The color archive is invalid."}];}
    return nil;
}
// BINMAP-ADAPT: UIColorArchive.archivedDataWithColorValue:error: manifest=reimpl/color_list_extras.json
+ (NSData *)archivedDataWithColorValue:(UIColorValue *)color error:(NSError **)error {
    UIColorArchiveRecord *record=[[UIColorArchiveRecord alloc]initWithColorValue:color];
    if(!record){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorUnsupportedColor userInfo:@{NSLocalizedDescriptionKey:@"This color cannot be represented by the component archive bridge."}];return nil;}
    @try {
        NSKeyedArchiver *writer=[[NSKeyedArchiver alloc]initRequiringSecureCoding:YES];
        [writer setClassName:@"NSColor" forClass:UIColorArchiveRecord.class];
        [writer setClassName:@"NSColorSpace" forClass:UIColorSpaceArchiveRecord.class];
        [writer encodeObject:record forKey:NSKeyedArchiveRootObjectKey];[writer finishEncoding];return writer.encodedData;
    }@catch(NSException *exception){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorInvalidData userInfo:@{NSLocalizedDescriptionKey:exception.reason?:@"The color could not be archived."}];return nil;}
}
#if TARGET_OS_IOS
// BINMAP-ADAPT: UIColorArchive.colorFromNSColorArchiveData:error: manifest=reimpl/color_list_extras.json
+ (UIColor *)colorFromNSColorArchiveData:(NSData *)data error:(NSError **)error {
    UIColorValue *value=[self colorValueFromNSColorArchiveData:data error:error];UIColor *color=value.UIColor;
    NSDictionary *metadata=value?objc_getAssociatedObject(value,&UIColorArchiveMetadataAssociationKey):nil;
    if(metadata&&color)objc_setAssociatedObject(color,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return color;
}
// BINMAP-ADAPT: UIColorArchive.archivedDataWithColor:error: manifest=reimpl/color_list_extras.json
+ (NSData *)archivedDataWithColor:(UIColor *)color error:(NSError **)error {
    UIColorValue *value=[[UIColorValue alloc]initWithCGColor:color.CGColor];NSDictionary *metadata=objc_getAssociatedObject(color,&UIColorArchiveMetadataAssociationKey);
    if(metadata&&value)objc_setAssociatedObject(value,&UIColorArchiveMetadataAssociationKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [self archivedDataWithColorValue:value error:error];
}
#endif
// BINMAP-ADAPT: UIColorArchive.colorListContentsFromData:error: manifest=reimpl/color_list_extras.json
+ (NSDictionary<NSString *,NSArray *> *)colorListContentsFromData:(NSData *)data error:(NSError **)error {
    if(data.length>=13&&memcmp(data.bytes,"\x04\x0bstreamtyped",13)==0)return [[[UIColorLegacyColorListReader alloc]initWithData:data]colorListContentsWithError:error];
    @try {
        NSKeyedUnarchiver *reader=[[NSKeyedUnarchiver alloc]initForReadingFromData:data error:error];if(!reader)return nil;
        reader.requiresSecureCoding=YES;reader.decodingFailurePolicy=NSDecodingFailurePolicySetErrorAndReturn;
        [reader setClass:UIColorArchiveRecord.class forClassName:@"NSColor"];
        [reader setClass:UIColorSpaceArchiveRecord.class forClassName:@"NSColorSpace"];
        NSArray *keys=[reader decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class,NSString.class,nil] forKey:@"NSKeys"];
        NSArray *records=[reader decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class,UIColorArchiveRecord.class,nil] forKey:@"NSColors"];
        [reader finishDecoding];
        if(!keys&&!records&&!reader.error)return @{@"keys":@[],@"values":@[]};
        if(!reader.error&&keys.count==records.count){
            NSMutableArray *values=[NSMutableArray arrayWithCapacity:records.count];BOOL valid=YES;
            for(id key in keys)if(![key isKindOfClass:NSString.class]){valid=NO;break;}
            for(id entry in records){if(![entry isKindOfClass:UIColorArchiveRecord.class]||![entry colorValue]){valid=NO;break;}[values addObject:[entry colorValue]];}
            if(valid)return @{@"keys":keys,@"values":values};
        }
        if(error)*error=reader.error?:[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorInvalidData userInfo:@{NSLocalizedDescriptionKey:@"The list keys and color records do not match."}];
    }@catch(NSException *exception){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorInvalidData userInfo:@{NSLocalizedDescriptionKey:exception.reason?:@"The color-list archive is invalid."}];}
    return nil;
}
// BINMAP-ADAPT: UIColorArchive.archivedColorListWithKeys:values:error: manifest=reimpl/color_list_extras.json
+ (NSData *)archivedColorListWithKeys:(NSArray<NSString *> *)keys values:(NSArray<UIColorValue *> *)values error:(NSError **)error {
    if(keys.count!=values.count){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorInvalidData userInfo:@{NSLocalizedDescriptionKey:@"Color-list keys and values must have the same count."}];return nil;}
    NSMutableArray *records=[NSMutableArray arrayWithCapacity:values.count];
    for(UIColorValue *value in values){UIColorArchiveRecord *record=[[UIColorArchiveRecord alloc]initWithColorValue:value];if(!record){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorUnsupportedColor userInfo:@{NSLocalizedDescriptionKey:@"A color in this list cannot be saved by the component archive bridge."}];return nil;}[records addObject:record];}
    @try {
        NSKeyedArchiver *writer=[[NSKeyedArchiver alloc]initRequiringSecureCoding:YES];
        [writer setClassName:@"NSColor" forClass:UIColorArchiveRecord.class];[writer setClassName:@"NSColorSpace" forClass:UIColorSpaceArchiveRecord.class];
        if(keys.count){[writer encodeObject:[keys mutableCopy] forKey:@"NSKeys"];[writer encodeObject:records forKey:@"NSColors"];}
        [writer finishEncoding];return writer.encodedData;
    }@catch(NSException *exception){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorInvalidData userInfo:@{NSLocalizedDescriptionKey:exception.reason?:@"The color list could not be archived."}];return nil;}
}
@end
