#import "UIColorLegacyColorListReader.h"
#import "UIColorArchiveRecord.h"
#import <objc/runtime.h>
#import <math.h>

@interface UIColorLegacyColorListReader () {
    NSData *_data;
    NSUInteger _offset,_depth,_classDepth;
    NSMutableArray<NSString *> *_strings;
    NSMutableArray *_references;
}
- (uint8_t)readByte;
- (int64_t)readInteger;
- (NSString *)readSharedString;
- (id)readClass;
- (double)readFloat;
- (id)readObject;
- (NSArray *)readGroup:(NSString *)expected;
@end
@implementation UIColorLegacyColorListReader
// BINMAP-ADAPT: UIColorLegacyColorListReader.initWithData: manifest=reimpl/color_list_extras.json
- (instancetype)initWithData:(NSData *)data {if((self=[super init])){_data=[data copy];_strings=[NSMutableArray array];_references=[NSMutableArray array];}return self;}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readByte manifest=reimpl/color_list_extras.json
- (uint8_t)readByte {if(_offset>=_data.length)[NSException raise:NSInvalidUnarchiveOperationException format:@"Truncated legacy color list."];return ((const uint8_t *)_data.bytes)[_offset++];}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readInteger manifest=reimpl/color_list_extras.json
- (int64_t)readInteger {
    int8_t head=(int8_t)[self readByte];
    if((uint8_t)head==0x81){uint16_t bits=[self readByte];bits|=(uint16_t)[self readByte]<<8;return (int16_t)bits;}
    if((uint8_t)head==0x82){uint32_t bits=0;for(NSUInteger i=0;i<4;i++)bits|=(uint32_t)[self readByte]<<(8*i);return (int32_t)bits;}
    if(head>=-110)return head;
    [NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported integer tag in legacy color list."];return 0;
}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readSharedString manifest=reimpl/color_list_extras.json
- (NSString *)readSharedString {
    uint8_t head=[self readByte];
    if(head==0x84){
        int64_t length=[self readInteger];
        if(length<0||(uint64_t)length>_data.length-_offset)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy string length."];
        NSString *string=[[NSString alloc]initWithBytes:((const uint8_t *)_data.bytes)+_offset length:(NSUInteger)length encoding:NSASCIIStringEncoding];_offset+=(NSUInteger)length;
        if(!string)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy shared string."];
        [_strings addObject:string];return string;
    }
    _offset--;int64_t index=[self readInteger]+110;
    if(index<0||(uint64_t)index>=_strings.count)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy shared string reference."];
    return _strings[(NSUInteger)index];
}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readClass manifest=reimpl/color_list_extras.json
- (id)readClass {
    if(++_classDepth>16)[NSException raise:NSInvalidUnarchiveOperationException format:@"Legacy color-list class nesting exceeds the supported grammar."];
    uint8_t head=[self readByte];id result=nil;
    if(head==0x85)result=NSNull.null;
    else if(head==0x84){
        NSString *name=[self readSharedString];int64_t version=[self readInteger];
        NSUInteger slot=_references.count;[_references addObject:NSNull.null];id superclass=[self readClass];
        result=@{@"class":name,@"version":@(version),@"superclass":superclass};_references[slot]=result;
    }else{
        _offset--;int64_t index=[self readInteger]+110;
        if(index<0||(uint64_t)index>=_references.count||![_references[(NSUInteger)index]isKindOfClass:NSDictionary.class])[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy class reference."];
        result=_references[(NSUInteger)index];
    }
    _classDepth--;return result;
}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readFloat manifest=reimpl/color_list_extras.json
- (double)readFloat {
    uint8_t head=[self readByte];
    if(head==0x83){uint32_t bits=0;for(NSUInteger i=0;i<4;i++)bits|=(uint32_t)[self readByte]<<(8*i);float value;memcpy(&value,&bits,sizeof(value));if(!isfinite(value))[NSException raise:NSInvalidUnarchiveOperationException format:@"Non-finite legacy color component."];return value;}
    _offset--;return (double)[self readInteger];
}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readObject manifest=reimpl/color_list_extras.json
- (id)readObject {
    if(++_depth>64)[NSException raise:NSInvalidUnarchiveOperationException format:@"Legacy color-list nesting exceeds the supported grammar."];
    uint8_t head=[self readByte];id result=nil;
    if(head==0x85){_depth--;return NSNull.null;}
    if(head!=0x84){_offset--;int64_t index=[self readInteger]+110;if(index<0||(uint64_t)index>=_references.count)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy object reference."];result=_references[(NSUInteger)index];if(![result isKindOfClass:NSString.class]&&![result isKindOfClass:UIColorValue.class])[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy object reference type."];_depth--;return result;}
    NSUInteger slot=_references.count;[_references addObject:NSNull.null];id classInfo=[self readClass];
    if(![classInfo isKindOfClass:NSDictionary.class])[NSException raise:NSInvalidUnarchiveOperationException format:@"Missing legacy object class."];
    NSString *name=classInfo[@"class"];
    if([name isEqual:@"NSString"]||[name isEqual:@"NSMutableString"]){
        if([classInfo[@"version"]integerValue]!=1)[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy NSString version."];
        result=[self readGroup:@"+"][0];
    }else if([name isEqual:@"NSColor"]){
        if([classInfo[@"version"]integerValue]!=0)[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy NSColor version."];
        NSInteger code=[[self readGroup:@"c"][0]integerValue];
        if(code==6){NSArray *parts=[self readGroup:@"@@@"];if(![parts[0]isKindOfClass:NSString.class]||![parts[1]isKindOfClass:NSString.class]||![parts[2]isKindOfClass:UIColorValue.class])[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy catalog color."];result=[[UIColorValue alloc]initWithCGColor:[parts[2]CGColor]];objc_setAssociatedObject(result,&UIColorArchiveMetadataAssociationKey,@{@"catalogName":parts[0],@"colorName":parts[1]},OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
        else{
            CGColorSpaceRef space=NULL;NSString *encoding=nil;
            switch(code){case 1:case 2:encoding=@"ffff";break;case 3:case 4:encoding=@"ff";break;case 5:encoding=@"fffff";break;default:[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy color kind %ld.",(long)code];}
            NSArray *numbers=[self readGroup:encoding];CGFloat values[5]={0};for(NSUInteger i=0;i<numbers.count;i++)values[i]=MAX(0,MIN(1,[numbers[i]doubleValue]));
            switch(code){case 1:space=CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);break;case 2:space=CGColorSpaceCreateDeviceRGB();break;case 3:space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);break;case 4:space=CGColorSpaceCreateDeviceGray();break;case 5:space=CGColorSpaceCreateDeviceCMYK();break;}
            CGColorRef color=space?CGColorCreate(space,values):NULL;if(space)CGColorSpaceRelease(space);if(!color)[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy color space."];
            result=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);
        }
    }else [NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy color-list object class %@.",name];
    if([self readByte]!=0x86)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy object terminator."];
    _references[slot]=result;_depth--;return result;
}
// BINMAP-ADAPT: UIColorLegacyColorListReader.readGroup: manifest=reimpl/color_list_extras.json
- (NSArray *)readGroup:(NSString *)expected {
    NSString *encoding=[self readSharedString];if(![encoding isEqual:expected])[NSException raise:NSInvalidUnarchiveOperationException format:@"Expected legacy group %@, got %@.",expected,encoding];
    NSMutableArray *values=[NSMutableArray array];
    for(NSUInteger i=0;i<encoding.length;i++){
        unichar type=[encoding characterAtIndex:i];
        if(type=='@')[values addObject:[self readObject]];
        else if(type=='f')[values addObject:@([self readFloat])];
        else if(type=='i'||type=='c')[values addObject:@([self readInteger])];
        else if(type=='+'){
            int64_t length=[self readInteger];if(length<0||(uint64_t)length>_data.length-_offset)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy text length."];
            NSString *string=[[NSString alloc]initWithBytes:((const uint8_t *)_data.bytes)+_offset length:(NSUInteger)length encoding:NSUTF8StringEncoding];_offset+=(NSUInteger)length;
            if(!string)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy UTF-8 text."];[values addObject:string];
        }else [NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy type %C.",type];
    }
    return values;
}
// BINMAP-ADAPT: UIColorLegacyColorListReader.colorListContentsWithError: manifest=reimpl/color_list_extras.json
- (NSDictionary<NSString *,NSArray *> *)colorListContentsWithError:(NSError **)error {
    @try{
        if(_data.length<16||memcmp(_data.bytes,"\x04\x0bstreamtyped",13)!=0)[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy color-list header."];
        _offset=13;if([self readInteger]!=1000)[NSException raise:NSInvalidUnarchiveOperationException format:@"Unsupported legacy system version."];
        if([[self readGroup:@"i"][0]integerValue]!=1)[NSException raise:NSInvalidUnarchiveOperationException format:@"Only the observed legacy v1 color-list layout is supported."];
        NSArray *header=[self readGroup:@"@i"];NSInteger count=[header[1]integerValue];
        if(count<0||(NSUInteger)count>_data.length)[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy color count."];
        NSMutableArray *keys=[NSMutableArray array],*values=[NSMutableArray array];
        for(NSInteger i=0;i<count;i++){NSArray *entry=[self readGroup:@"@@"];if(![entry[0]isKindOfClass:UIColorValue.class]||![entry[1]isKindOfClass:NSString.class])[NSException raise:NSInvalidUnarchiveOperationException format:@"Invalid legacy color-list entry."];[values addObject:entry[0]];[keys addObject:entry[1]];}
        if(_offset!=_data.length)[NSException raise:NSInvalidUnarchiveOperationException format:@"Trailing data in legacy color list."];
        return @{@"keys":keys,@"values":values};
    }@catch(NSException *exception){if(error)*error=[NSError errorWithDomain:UIColorArchiveErrorDomain code:UIColorArchiveErrorUnsupportedLegacyData userInfo:@{NSLocalizedDescriptionKey:exception.reason?:@"The legacy color-list format is unsupported."}];return nil;}
}
@end
