#import "ColorMatchTests.h"
#import "ColorSpaceProbe.h"
#import "UIColorValue+AppKitEquality.h"
#import "UIColorPickerColorMatch.h"
@implementation UIColorColorMatchTests
+ (BOOL)runWithOutputURL:(NSURL *)url {
    CGColorSpaceRef rgb=CGColorSpaceCreateWithName(kCGColorSpaceSRGB), p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    if(!rgb || !p3) { if(rgb)CGColorSpaceRelease(rgb);if(p3)CGColorSpaceRelease(p3);return NO; }
    NSArray *specifications=@[
        @{@"name":@"exact",@"left":@[@.5,@.25,@.75,@.37],@"right":@[@.5,@.25,@.75,@.37],@"expected":@YES},
        @{@"name":@"sameFloatDifferentDouble",@"left":@[@.5,@.25,@.75,@.37],@"right":@[@.500000001,@.25,@.75,@.37],@"expected":@YES,@"exactExpected":@NO},
        @{@"name":@"differentFloat",@"left":@[@.5,@.25,@.75,@.37],@"right":@[@.500001,@.25,@.75,@.37],@"expected":@NO},
        @{@"name":@"alphaSameFloat",@"left":@[@.5,@.25,@.75,@.37],@"right":@[@.5,@.25,@.75,@.370000001],@"expected":@YES},
        @{@"name":@"alphaDifferentFloat",@"left":@[@.5,@.25,@.75,@.37],@"right":@[@.5,@.25,@.75,@.370001],@"expected":@NO},
        @{@"name":@"differentProfileSameComponents",@"left":@[@.5,@.25,@.75,@.37],@"right":@[@.5,@.25,@.75,@.37],@"expected":@NO,@"p3":@YES}
    ];
    NSMutableArray *cases=[NSMutableArray new]; NSUInteger failures=0;
    for(NSDictionary *spec in specifications) {
        CGFloat left[4],right[4];for(NSUInteger i=0;i<4;i++){left[i]=[spec[@"left"][i]doubleValue];right[i]=[spec[@"right"][i]doubleValue];}
        CGColorRef a=CGColorCreate(rgb,left),b=CGColorCreate([spec[@"p3"]boolValue]?p3:rgb,right);
        UIColorValue *av=[[UIColorValue alloc]initWithCGColor:a],*bv=[[UIColorValue alloc]initWithCGColor:b];CGColorRelease(a);CGColorRelease(b);
        BOOL actual=[av isEqualForColorPanel:bv],pass=actual==[spec[@"expected"]boolValue];
        if(spec[@"exactExpected"])pass=pass&&[av isEqual:bv]==[spec[@"exactExpected"]boolValue];
        if(!pass)failures++;
        [cases addObject:@{@"name":spec[@"name"],@"expected":spec[@"expected"],@"actual":@(actual),@"canonicalExact":@([av isEqual:bv]),@"pass":@(pass)}];
    }
    CGFloat values[4]={.5,.25,.75,.37}; CGColorRef color=CGColorCreate(rgb,values);UIColorValue *value=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);
    BOOL guards=[value isEqualForColorPanel:value]&&![value isEqualForColorPanel:nil]&&![value isEqualForColorPanel:@"not a color"];
    [cases addObject:@{@"name":@"identityNilAndClassGuards",@"pass":@(guards)}];if(!guards)failures++;
    UIColorPickerColorMatch *noProfile=[[UIColorPickerColorMatch alloc]initWithColors:@[value]color:value selectedIndex:0 matchingColorSpace:NULL];
    BOOL profileGuard=!noProfile.profileAvailable;[cases addObject:@{@"name":@"missingProfileIsExplicit",@"pass":@(profileGuard)}];if(!profileGuard)failures++;
    NSDictionary *output=@{@"cases":cases,@"failureCount":@(failures),@"capabilities":[UIColorColorSpaceProbe environmentState],@"scope":@"Finite numeric AppKit equality contract; native host differential is reference/provider/equivalence/color-match-comparison.json. No catalog/dynamic identity claim."};
    NSData *data=[NSJSONSerialization dataWithJSONObject:output options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];
    CGColorSpaceRelease(rgb);CGColorSpaceRelease(p3);
    return [data writeToURL:url atomically:YES]&&failures==0;
}
@end
