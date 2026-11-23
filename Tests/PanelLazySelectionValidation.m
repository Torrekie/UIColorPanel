#import "PanelLazySelectionValidation.h"
#import "UIColorPanel.h"
#import "UIColorPanelViewController.h"
#import "UIColorPickerCatalogController.h"
#import <math.h>
@interface UIColorPanelLazyRecorder : NSObject
@property(nonatomic, strong) NSMutableArray *events;
@property(nonatomic) BOOL switchToListOnNextAction;
- (void)colorChanged:(UIColorPanel *)panel;
@end
@implementation UIColorPanelLazyRecorder
- (void)colorChanged:(UIColorPanel *)panel {
    [self.events addObject:@{@"event":@"action",@"mode":@(panel.mode),@"alpha":@(panel.alpha)}];
    if(self.switchToListOnNextAction){self.switchToListOnNextAction=NO;panel.mode=UIColorPanelModeColorList;}
}
@end
@implementation UIColorPanelLazySelectionValidation
+ (BOOL)runWithOutputURL:(NSURL *)url unmatchedP3:(BOOL)unmatchedP3 {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"UIColorPickerCatalog.SelectedList.v1"];
    [UIColorPanel setPickerMask:UIColorPanelAllModesMask];[UIColorPanel setPickerMode:UIColorPanelModeWheel];
    UIColorPanel *panel=UIColorPanel.sharedColorPanel;panel.showsAlpha=YES;
    CGColorSpaceRef space=CGColorSpaceCreateWithName(unmatchedP3?kCGColorSpaceDisplayP3:kCGColorSpaceSRGB);
    CGFloat values[4]={unmatchedP3?.25:1,unmatchedP3?.7:1,unmatchedP3?.9:0,.37};
    CGColorRef cg=CGColorCreate(space,values);UIColorValue *input=[[UIColorValue alloc]initWithCGColor:cg];CGColorRelease(cg);CGColorSpaceRelease(space);panel.colorValue=input;
    UIColorPanelLazyRecorder *recorder=[UIColorPanelLazyRecorder new];recorder.events=[NSMutableArray new];panel.target=recorder;panel.action=@selector(colorChanged:);
    id token=[NSNotificationCenter.defaultCenter addObserverForName:UIColorPanelColorDidChangeNotification object:panel queue:nil usingBlock:^(NSNotification *n){[recorder.events addObject:@{@"event":@"notification",@"mode":@(panel.mode),@"alpha":@(panel.alpha)}];}];
    panel.mode=UIColorPanelModeColorList;
    NSArray *firstEvents=[recorder.events copy];UIColorValue *firstColor=panel.colorValue;
    BOOL passed=panel.mode==UIColorPanelModeColorList;
    if(unmatchedP3)passed=passed&&firstEvents.count==0&&[firstColor isEqual:input];
    else {
        const CGFloat *p=CGColorGetComponents(firstColor.CGColor);
        passed=passed&&firstEvents.count==2&&[firstEvents[0][@"event"] isEqual:@"action"]&&[firstEvents[1][@"event"] isEqual:@"notification"]&&[firstEvents[0][@"mode"]integerValue]==UIColorPanelModeWheel&&[firstEvents[1][@"mode"]integerValue]==UIColorPanelModeWheel;
        passed=passed&&CGColorGetNumberOfComponents(firstColor.CGColor)==4&&fabs(p[0]-.9994240403)<1e-12&&fabs(p[1]-.9855536819)<1e-12&&p[2]==0&&p[3]==1;
    }
    panel.mode=UIColorPanelModeWheel;panel.colorValue=input;[recorder.events removeAllObjects];panel.mode=UIColorPanelModeColorList;
    BOOL revisit=recorder.events.count==0&&[panel.colorValue isEqual:input];passed=passed&&revisit;
    NSMutableArray *focusedCases=[NSMutableArray new];
    UIColorPanelViewController *controller=[panel valueForKey:@"pickerController"];
    UIColorPickerCatalogController *catalog=[controller valueForKey:@"catalogController"];
    UIColorList *originalApple=catalog.currentColorList;
    CGColorSpaceRef p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    CGFloat p3InputComponents[4]={.25,.7,.9,.37},nearComponents[4]={.2501,.7001,.9001,.37};
    CGColorRef p3InputCG=CGColorCreate(p3,p3InputComponents),nearCG=CGColorCreate(p3,nearComponents);
    UIColorValue *p3Input=[[UIColorValue alloc]initWithCGColor:p3InputCG],*near=[[UIColorValue alloc]initWithCGColor:nearCG];
    CGColorRelease(p3InputCG);CGColorRelease(nearCG);CGColorSpaceRelease(p3);
    UIColorList *replacement=[[UIColorList alloc]initWithName:originalApple.name];[replacement setColorValue:near forKey:@"Near P3"];
    panel.colorValue=p3Input;[recorder.events removeAllObjects];[panel attachColorList:replacement];
    NSArray *replacementEvents=[recorder.events copy];
    BOOL replacementPassed=catalog.currentColorList==replacement&&[panel.colorValue isEqual:near]&&[controller.selectedColor isEqual:panel.colorValue]&&replacementEvents.count==2&&[replacementEvents[0][@"event"]isEqual:@"action"]&&[replacementEvents[1][@"event"]isEqual:@"notification"];
    [focusedCases addObject:@{@"name":@"sameNamedActiveReplacementSelectsNearColor",@"passed":@(replacementPassed),@"events":replacementEvents}];passed=passed&&replacementPassed;
    // Reloading the same selected row must not invent another selection callback.
    panel.colorValue=p3Input;UIColorList *unrelated=[[UIColorList alloc]initWithName:@"UIColorPanelLazyFixture"];
    [unrelated setColorValue:near forKey:@"Fixture"];[recorder.events removeAllObjects];[panel attachColorList:unrelated];
    BOOL unchangedRowPassed=recorder.events.count==0&&[panel.colorValue isEqual:p3Input];
    [focusedCases addObject:@{@"name":@"unchangedRowRefreshDoesNotSendColor",@"passed":@(unchangedRowPassed),@"events":[recorder.events copy]}];passed=passed&&unchangedRowPassed;
    UIColorList *fallback=nil;for(UIColorList *list in catalog.colorLists)if(list!=replacement){fallback=list;break;}
    UIColorValue *fallbackColor=[fallback colorValueWithKey:fallback.allKeys.firstObject];
    panel.colorValue=[fallbackColor copyWithAlpha:.37];[recorder.events removeAllObjects];[panel detachColorList:replacement];
    NSArray *detachEvents=[recorder.events copy];
    BOOL detachPassed=fallback&&catalog.currentColorList==fallback&&[panel.colorValue isEqual:fallbackColor]&&[controller.selectedColor isEqual:panel.colorValue]&&detachEvents.count==2&&[detachEvents[0][@"event"]isEqual:@"action"]&&[detachEvents[1][@"event"]isEqual:@"notification"];
    [focusedCases addObject:@{@"name":@"activeDetachFallbackSelectsColor",@"passed":@(detachPassed),@"events":detachEvents}];passed=passed&&detachPassed;
    [panel detachColorList:unrelated];[panel attachColorList:originalApple];
    [NSNotificationCenter.defaultCenter removeObserver:token];panel.target=nil;panel.action=NULL;[panel close];
    // A new panel gives this case its first, still-unloaded ColorList view.
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"UIColorPickerCatalog.SelectedList.v1"];
    UIColorPanel *reentrantPanel=[UIColorPanel new];reentrantPanel.showsAlpha=YES;
    UIColorPanelLazyRecorder *reentrantRecorder=[UIColorPanelLazyRecorder new];reentrantRecorder.events=[NSMutableArray new];reentrantRecorder.switchToListOnNextAction=YES;
    reentrantPanel.target=reentrantRecorder;reentrantPanel.action=@selector(colorChanged:);
    id reentrantToken=[NSNotificationCenter.defaultCenter addObserverForName:UIColorPanelColorDidChangeNotification object:reentrantPanel queue:nil usingBlock:^(NSNotification *n){[reentrantRecorder.events addObject:@{@"event":@"notification",@"mode":@(reentrantPanel.mode),@"alpha":@(reentrantPanel.alpha)}];}];
    CGColorSpaceRef yellowSpace=CGColorSpaceCreateWithName(kCGColorSpaceSRGB);CGFloat yellowComponents[4]={1,1,0,.37};CGColorRef yellowCG=CGColorCreate(yellowSpace,yellowComponents);
    UIColorValue *yellow=[[UIColorValue alloc]initWithCGColor:yellowCG];CGColorRelease(yellowCG);CGColorSpaceRelease(yellowSpace);
    reentrantPanel.colorValue=yellow;
    UIColorPanelViewController *reentrantController=[reentrantPanel valueForKey:@"pickerController"];
    UIColorPickerCatalogController *reentrantCatalog=[reentrantController valueForKey:@"catalogController"];
    BOOL reentrantPassed=reentrantPanel.mode==UIColorPanelModeColorList&&[reentrantPanel.colorValue isEqual:yellow]&&[reentrantController.selectedColor isEqual:yellow]&&[reentrantCatalog.selectedColor isEqual:yellow]&&reentrantRecorder.events.count==2&&[reentrantRecorder.events[0][@"event"]isEqual:@"action"]&&[reentrantRecorder.events[1][@"event"]isEqual:@"notification"];
    [focusedCases addObject:@{@"name":@"reentrantFirstListCallbackKeepsCanonicalColor",@"passed":@(reentrantPassed),@"events":[reentrantRecorder.events copy],@"panelControllerEqual":@([reentrantController.selectedColor isEqual:reentrantPanel.colorValue]),@"panelCatalogEqual":@([reentrantCatalog.selectedColor isEqual:reentrantPanel.colorValue])}];passed=passed&&reentrantPassed;
    [NSNotificationCenter.defaultCenter removeObserver:reentrantToken];reentrantPanel.target=nil;reentrantPanel.action=NULL;[reentrantPanel close];
    NSMutableArray *components=[NSMutableArray array];const CGFloat *p=CGColorGetComponents(firstColor.CGColor);for(NSUInteger i=0;i<CGColorGetNumberOfComponents(firstColor.CGColor);i++)[components addObject:@(p[i])];
    NSDictionary *result=@{@"passed":@(passed),@"input":unmatchedP3?@"unmatched P3":@"near Apple Yellow",@"firstEvents":firstEvents,@"firstColorComponents":components,@"revisitPreservesInput":@(revisit),@"focusedCases":focusedCases,@"nativeReference":@"reference/provider/equivalence/lazy-direct.json / lazy-p3.json; reimpl/panel_api_evidence.json attach/refresh/select and panel suppression branches"};
    NSData *data=[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];return [data writeToURL:url options:NSDataWritingAtomic error:nil]&&passed;
}
@end
