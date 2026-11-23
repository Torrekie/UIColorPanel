#import "PolishValidation.h"
#import "../Sources/UIColorPanelAppearance.h"
#import "../Sources/UIColorPanelViewController.h"
#import "../Sources/UIColorPanelChoiceController.h"
#import "../Sources/UIColorPanelMenuButton.h"
#import <math.h>

#if UICOLORPANEL_ENABLE_PRIVATE_API
#import <objc/runtime.h>
#import <string.h>
@interface UIPolishValidationWrongCornerLayer : CALayer
@property(nonatomic) NSUInteger continuousCornerCalls;
- (void)setContinuousCorners:(NSInteger)value;
@end
@implementation UIPolishValidationWrongCornerLayer
- (void)setContinuousCorners:(NSInteger __unused)value {self.continuousCornerCalls++;}
@end
@interface UIPolishValidationBoolCornerLayer : CALayer
@property(nonatomic) NSUInteger continuousCornerCalls;
- (void)setContinuousCorners:(BOOL)value;
@end
@implementation UIPolishValidationBoolCornerLayer
- (void)setContinuousCorners:(BOOL __unused)value {self.continuousCornerCalls++;}
@end
@interface UIPolishValidationWrongCornerView : UIView
@end
@implementation UIPolishValidationWrongCornerView
+ (Class)layerClass {return UIPolishValidationWrongCornerLayer.class;}
@end
@interface UIPolishValidationBoolCornerView : UIView
@end
@implementation UIPolishValidationBoolCornerView
+ (Class)layerClass {return UIPolishValidationBoolCornerLayer.class;}
@end
#endif

NSDictionary *runPolishValidation(void) {
    if(!NSThread.isMainThread)return @{ @"passed":@NO,@"caseCount":@0,@"failureCount":@1,@"error":@"runPolishValidation must run on the main thread." };
    NSMutableArray *cases=[NSMutableArray new];__block NSUInteger failures=0;
    void (^record)(NSString *,BOOL,NSDictionary *)=^(NSString *name,BOOL passed,NSDictionary *details){NSMutableDictionary *entry=[@{@"name":name,@"passed":@(passed)}mutableCopy];[entry addEntriesFromDictionary:details?:@{}];[cases addObject:entry];if(!passed)failures++;};

    NSArray *locales=@[@"en_US",@"de_DE",@"ar_EG"];
    NSArray *literalInputs=@[@"12.5",@"12,5",@"١٢٫٥"];
    NSArray *negativeInputs=@[@"-0.125",@"-0,125",@"\u061C-٠٫١٢٥"];
    NSArray *groupedInputs=@[@"1,234",@"1.234",@"١٬٢٣٤"];
    NSArray *values=@[@(-.125),@1.375,@.314159265,@0,@255,@1.25e-7,@1.25e8];
    for(NSUInteger index=0;index<locales.count;index++){
        NSLocale *locale=[[NSLocale alloc]initWithLocaleIdentifier:locales[index]];NSMutableArray *roundTrips=[NSMutableArray new];BOOL passed=YES;
        NSNumber *literal=[UIColorPanelAppearance parseNumber:literalInputs[index] locale:locale];NSNumber *negative=[UIColorPanelAppearance parseNumber:negativeInputs[index] locale:locale];
        passed=literal&&fabs(literal.doubleValue-12.5)<1e-12&&negative&&fabs(negative.doubleValue+.125)<1e-12;
        for(NSNumber *value in values){NSString *formatted=[UIColorPanelAppearance formatNumber:value.doubleValue significantDigits:9 locale:locale];NSNumber *parsed=[UIColorPanelAppearance parseNumber:formatted locale:locale];double tolerance=MAX(1,fabs(value.doubleValue))*1e-9;BOOL exactEnough=parsed&&fabs(parsed.doubleValue-value.doubleValue)<=tolerance;passed=passed&&exactEnough;[roundTrips addObject:@{@"input":value,@"formatted":formatted,@"parsed":parsed?:NSNull.null,@"passed":@(exactEnough)}];}
        record([NSString stringWithFormat:@"localized number round trips (%@)",locales[index]],passed,@{@"literal":literal?:NSNull.null,@"negative":negative?:NSNull.null,@"values":roundTrips});
        BOOL rejects=[UIColorPanelAppearance parseNumber:groupedInputs[index] locale:locale]==nil;
        for(NSString *invalid in @[@"",@" ",@"12tail",@"NaN",@"Infinity",@"—",@"1 2"]){rejects=rejects&&[UIColorPanelAppearance parseNumber:invalid locale:locale]==nil;}
        record([NSString stringWithFormat:@"reject partial, grouped and nonfinite numbers (%@)",locales[index]],rejects,@{@"groupedFixture":groupedInputs[index]});
    }
    NSString *nonfinite=[UIColorPanelAppearance formatNumber:NAN significantDigits:9 locale:[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"]];
    NSString *infinite=[UIColorPanelAppearance formatNumber:INFINITY significantDigits:9 locale:[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"]];
    record(@"nonfinite display is an explicit placeholder",[nonfinite isEqualToString:@"—"]&&[infinite isEqualToString:@"—"],@{@"nan":nonfinite,@"infinity":infinite});
    record(@"new configuration keeps optional private API disabled at runtime",![UIColorPanelConfiguration new].use_spi,@{@"compileGate":@(UICOLORPANEL_ENABLE_PRIVATE_API),@"scope":@"Runtime defaults stay off in both public/private variants; this receipt records the actual translation-unit compile policy."});

#if UICOLORPANEL_ENABLE_PRIVATE_API
    for(NSNumber *correctSignature in @[@NO,@YES]){
        BOOL correct=correctSignature.boolValue;UIView *cornerView=correct?[[UIPolishValidationBoolCornerView alloc]initWithFrame:CGRectMake(0,0,64,40)]:[[UIPolishValidationWrongCornerView alloc]initWithFrame:CGRectMake(0,0,64,40)];CALayer *layer=cornerView.layer;Method method=class_getInstanceMethod(object_getClass(layer),@selector(setContinuousCorners:));const char *encoding=method?method_getTypeEncoding(method):NULL;NSMethodSignature *signature=encoding?[NSMethodSignature signatureWithObjCTypes:encoding]:nil;const char *argument=signature.numberOfArguments==3?[signature getArgumentTypeAtIndex:2]:NULL;BOOL actualSignatureMatches=argument&&(correct?(!strcmp(argument,"B")||!strcmp(argument,"c")):!strcmp(argument,"q"));NSUInteger beforeCalls=correct?((UIPolishValidationBoolCornerLayer *)layer).continuousCornerCalls:((UIPolishValidationWrongCornerLayer *)layer).continuousCornerCalls;
        [UIColorPanelAppearance applyCornersToView:cornerView radius:12 useSPI:YES];NSUInteger calls=correct?((UIPolishValidationBoolCornerLayer *)layer).continuousCornerCalls:((UIPolishValidationWrongCornerLayer *)layer).continuousCornerCalls;BOOL pathPresent=[layer.mask isKindOfClass:CAShapeLayer.class]&&((CAShapeLayer *)layer.mask).path&&!CGPathIsEmpty(((CAShapeLayer *)layer.mask).path);BOOL privateGuardExercised=NO,okay=actualSignatureMatches;NSString *branch=nil;
        if(@available(iOS 13.0,*)){branch=@"public cornerCurve on the actual iOS13+ runtime";okay&=[layer.cornerCurve isEqualToString:kCACornerCurveContinuous]&&fabs(layer.cornerRadius-12)<1e-10&&layer.masksToBounds&&layer.mask==nil;}
        else{privateGuardExercised=YES;branch=@"iOS12 real applyCornersToView:radius:useSPI: ABI gate";okay&=beforeCalls==0;if(correct)okay&=calls==1&&fabs(layer.cornerRadius-12)<1e-10&&layer.masksToBounds&&layer.mask==nil;else okay&=calls==0&&layer.cornerRadius==0&&pathPresent&&[layer.mask.name isEqualToString:@"UIColorPanelAppearance.smoothMask"];}
        NSString *caseName=privateGuardExercised?(correct?@"continuous corner BOOL signature accepts the native branch":@"continuous corner integer signature is rejected with a public smooth-mask fallback"):(correct?@"public continuous corners apply with the test BOOL callback layer":@"public continuous corners apply with the test integer callback layer");record(caseName,okay,@{@"actualBranch":branch,@"privateABIGuardExercised":@(privateGuardExercised),@"methodTypeEncoding":encoding?[NSString stringWithUTF8String:encoding]:@"missing",@"argumentEncoding":argument?[NSString stringWithUTF8String:argument]:@"missing",@"setterCallsBefore":@(beforeCalls),@"setterCallsAfter":@(calls),@"publicSmoothMaskHasPath":@(pathPresent),@"scope":@"Only test-owned UIView/CALayer subclasses are used; no system method is replaced or swizzled. The integer-argument implementation never reads its argument. Actual iOS12 checks the production ABI rejection and BOOL positive control. Actual iOS13+ checks the public cornerCurve branch and does not claim that the private ABI guard ran. No OS version is substituted."});
    }
#endif

    __block NSUInteger callbacks=0;
    UIColorPanelChoiceItem *integer=[UIColorPanelChoiceItem itemWithTitle:@"8-bit" selected:YES enabled:YES destructive:NO handler:^{callbacks++;}];
    UIColorPanelChoiceItem *floating=[UIColorPanelChoiceItem itemWithTitle:@"Floating point" selected:NO enabled:YES destructive:NO handler:^{callbacks++;}];
    UIColorPanelChoiceItem *srgb=[UIColorPanelChoiceItem itemWithTitle:@"sRGB" selected:NO enabled:YES destructive:NO handler:^{callbacks++;}];
    UIColorPanelChoiceItem *p3=[UIColorPanelChoiceItem itemWithTitle:@"Display P3" selected:YES enabled:YES destructive:NO handler:^{callbacks++;}];
    UIColorPanelChoiceItem *lockedRow=[UIColorPanelChoiceItem itemWithTitle:@"Unavailable built-in operation" selected:NO enabled:NO destructive:YES handler:^{callbacks++;}];
    NSArray *sections=@[[UIColorPanelChoiceSection sectionWithTitle:@"Precision" items:@[integer,floating]],[UIColorPanelChoiceSection sectionWithTitle:@"Color Profile" items:@[srgb,p3,lockedRow]]];
    UIColorPanelChoiceController *choice=[[UIColorPanelChoiceController alloc]initWithTitle:@"Slider Options" sections:sections];[choice loadViewIfNeeded];choice.view.frame=CGRectMake(0,0,320,480);[choice.tableView reloadData];[choice.view setNeedsLayout];[choice.view layoutIfNeeded];
    BOOL groups=choice.sections.count==2&&[choice numberOfSectionsInTableView:choice.tableView]==2&&callbacks==0;NSUInteger checked=0;NSMutableArray *rows=[NSMutableArray new];
    for(NSUInteger section=0;section<sections.count;section++)for(NSUInteger row=0;row<[sections[section] items].count;row++){
        NSIndexPath *index=[NSIndexPath indexPathForRow:row inSection:section];UIColorPanelChoiceItem *item=[sections[section] items][row];UITableViewCell *cell=[choice tableView:choice.tableView cellForRowAtIndexPath:index];CGRect rect=[choice.tableView rectForRowAtIndexPath:index];BOOL valid=rect.size.height>=44-.01&&cell.textLabel.adjustsFontForContentSizeCategory&&cell.textLabel.numberOfLines==0&&((cell.accessoryType==UITableViewCellAccessoryCheckmark)==item.selected);if(item.selected)checked++;
        valid=valid&&([choice tableView:choice.tableView shouldHighlightRowAtIndexPath:index]==item.enabled)&&(!item.enabled?((cell.accessibilityTraits&UIAccessibilityTraitNotEnabled)!=0):YES);groups=groups&&valid;
        [rows addObject:@{@"section":@(section),@"row":@(row),@"height":@(rect.size.height),@"checked":@(item.selected),@"enabled":@(item.enabled),@"passed":@(valid)}];
    }
    groups=groups&&checked==2&&integer.selected&&p3.selected&&lockedRow.destructive&&!lockedRow.enabled;
    record(@"choice lists preserve independent groups and standard growing rows",groups,@{@"checkedAcrossGroups":@(checked),@"rows":rows,@"callbacksDuringConstruction":@(callbacks),@"scope":@"Descriptor, cell and row geometry checks; no modal selection/cancel gesture is simulated."});

    UIWindow *hostWindow=nil;for(UIWindow *candidate in UIApplication.sharedApplication.windows)if(candidate.isKeyWindow&&!candidate.hidden){hostWindow=candidate;break;}
    UIViewController *liveRoot=hostWindow.rootViewController,*fixtureHost=nil;
    if([liveRoot isKindOfClass:UINavigationController.class])liveRoot=((UINavigationController *)liveRoot).visibleViewController;
    if(liveRoot){fixtureHost=[UIViewController new];[fixtureHost loadViewIfNeeded];fixtureHost.view.frame=CGRectMake(-10000,-10000,320,600);fixtureHost.view.hidden=YES;[liveRoot addChildViewController:fixtureHost];[liveRoot.view addSubview:fixtureHost.view];[fixtureHost didMoveToParentViewController:liveRoot];}
    BOOL buttonsFit=fixtureHost!=nil;NSMutableArray *buttonChecks=[NSMutableArray new];
    NSArray *titles=@[@"Display P3",@"Farbprofil mit erweitertem Farbumfang",@"ملف تعريف الألوان ذي النطاق الواسع"];
    NSArray *categories=@[UIContentSizeCategoryLarge,UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];
    @try {
    if(fixtureHost)for(NSString *category in categories)for(NSNumber *width in @[@160,@240,@320])for(NSUInteger language=0;language<titles.count;language++){
        UIViewController *content=[UIViewController new];[content loadViewIfNeeded];[fixtureHost addChildViewController:content];[fixtureHost setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:category] forChildViewController:content];content.view.frame=CGRectMake(0,0,width.doubleValue,600);[fixtureHost.view addSubview:content.view];[content didMoveToParentViewController:fixtureHost];
        UIColorPanelMenuButton *button=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];[content.view addSubview:button];[fixtureHost.view setNeedsLayout];[fixtureHost.view layoutIfNeeded];[content.view setNeedsLayout];[content.view layoutIfNeeded];button.semanticContentAttribute=language==2?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;[button setTitle:titles[language] forState:UIControlStateNormal];button.frame=CGRectMake(0,0,width.doubleValue,44);[button setNeedsLayout];[button layoutIfNeeded];CGSize intrinsic=button.intrinsicContentSize;button.frame=CGRectMake(0,0,width.doubleValue,ceil(intrinsic.height));[button setNeedsLayout];[button layoutIfNeeded];
        CGRect title=button.titleLabel.frame,icon=button.imageView.frame;BOOL rtl=button.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft;
        BOOL valid=intrinsic.height>=44&&button.bounds.size.height>=44&&CGRectContainsRect(button.bounds,title)&&CGRectContainsRect(button.bounds,icon)&&!CGRectIntersectsRect(title,icon)&&[button.currentTitle isEqual:titles[language]]&&!button.displaysMoreActions&&CGAffineTransformIsIdentity(button.transform);
        CGFloat expectedFont=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:category]].pointSize;
        valid=valid&&button.window==hostWindow&&[button.traitCollection.preferredContentSizeCategory isEqualToString:category]&&[button.titleLabel.traitCollection.preferredContentSizeCategory isEqualToString:category]&&fabs(button.titleLabel.font.pointSize-expectedFont)<.01&&(rtl==(language==2))&&(rtl?CGRectGetMaxX(icon)<=CGRectGetMinX(title):CGRectGetMaxX(title)<=CGRectGetMinX(icon));buttonsFit=buttonsFit&&valid;
        [buttonChecks addObject:@{@"category":category,@"actualCategory":button.traitCollection.preferredContentSizeCategory,@"labelCategory":button.titleLabel.traitCollection.preferredContentSizeCategory,@"controllerCategory":content.traitCollection.preferredContentSizeCategory,@"windowAttached":@(button.window==hostWindow),@"fontSize":@(button.titleLabel.font.pointSize),@"expectedFontSize":@(expectedFont),@"width":width,@"language":@(language),@"height":@(button.bounds.size.height),@"titleFrame":NSStringFromCGRect(title),@"iconFrame":NSStringFromCGRect(icon),@"rtl":@(rtl),@"passed":@(valid)}];
        [content willMoveToParentViewController:nil];[content.view removeFromSuperview];[content removeFromParentViewController];
    }
    } @finally {
        if(fixtureHost){[fixtureHost willMoveToParentViewController:nil];[fixtureHost.view removeFromSuperview];[fixtureHost removeFromParentViewController];}
    }
    BOOL hostRemoved=!fixtureHost.parentViewController&&!fixtureHost.view.superview;
    buttonsFit=buttonsFit&&hostRemoved;
    UIColorPanelMenuButton *more=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];more.displaysMoreActions=YES;more.frame=CGRectMake(0,0,44,44);[more setNeedsLayout];[more layoutIfNeeded];
    BOOL moreFits=more.displaysMoreActions&&more.intrinsicContentSize.width>=44&&more.intrinsicContentSize.height>=44&&CGRectContainsRect(more.bounds,more.imageView.frame)&&more.currentTitle.length==0;
    record(@"menu buttons fit standard, long, RTL and accessibility text",buttonsFit&&moreFits,@{@"checks":buttonChecks,@"moreIconFrame":NSStringFromCGRect(more.imageView.frame),@"morePassed":@(moreFits),@"liveWindowAvailable":@(hostWindow!=nil),@"temporaryHostRemoved":@(hostRemoved),@"scope":@"A temporary hidden/offscreen child attached to the existing key window supplies scoped child-controller traits. The real production button and its native label must both inherit the category and render the expected font. The temporary hierarchy is removed in finally; no key-window, global locale/text setting, modal presentation or VoiceOver focus changes."});

    return @{@"passed":@(failures==0),@"caseCount":@(cases.count),@"failureCount":@(failures),@"cases":cases,@"scope":@"Finite locale parsing/formatting, explicit private-build policy/runtime default, independent choice groups and native button/row layout checks. Private builds also check test-owned corner callback signatures using the actual OS branch. No file writes, persistence mutation, modal presentation, system setting changes or physical-device actions."};
}
