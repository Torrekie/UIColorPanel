#import "../Tests/ProfileEditingValidation.h"
#import <UIKit/UIKit.h>
#import "UIColorPanelViewController.h"
#import "UIColorPanel.h"
#import "UIColorPanelWell.h"
#import "UIColorPickerWell.h"
#import "UIColorPickerFavoritesStore.h"
#import "UIColorPanelAppearance.h"
#import "UIEyedropperViewController.h"
#import "../Tests/PanelAPIValidation.h"
#import "../Tests/ColorMatchTests.h"
#import "../Tests/ColorSpaceProbe.h"
#import "../Tests/ProfilePersistenceTests.h"
#import "../Tests/PanelLazySelectionValidation.h"
#import "../Tests/UIFidelityValidation.h"
#import "../Tests/FavoritesValidation.h"
#import "../Tests/PencilValidation.h"
#import "../Tests/EyedropperValidation.h"
#import "../Tests/PolishValidation.h"
#import "../Tests/RuntimeProfileProbe.h"
#import "UIColorPickerSwatchesView.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import "UIColorPickerPencils.h"
#import "UIColorPickerPencilView.h"
#import "UIColoredPencil.h"
#endif

// This executable is the demonstration / comparison harness, outside the reconstructed library.
@interface UIDemoViewController : UIViewController <UIColorPanelViewControllerDelegate, UIColorPickerViewControllerDelegate>
@property(nonatomic, strong) UIColorValue *color;
@property(nonatomic, strong) UIView *colorWell;
@property(nonatomic, strong) UILabel *componentLabel;
@property(nonatomic, strong) UIImage *samplingImage;
@property(nonatomic, strong) UIColorPanelWell *classicWell;
@property(nonatomic, strong) UIControl *systemWell;
@property(nonatomic, strong) UIColorPickerWell *recoveredWell;
@property(nonatomic, strong) UIColorPickerWell *appearanceWell;
@property(nonatomic, strong) UISegmentedControl *wellAlphaPresets;
@property(nonatomic) BOOL didAutoOpen;
@end

@implementation UIDemoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Color Panel Demo";
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.translucent = NO;
    if(@available(iOS 13.0,*)){
        UINavigationBarAppearance *appearance=[UINavigationBarAppearance new];
        [appearance configureWithOpaqueBackground];appearance.backgroundColor=UIColor.systemBackgroundColor;
        self.navigationController.navigationBar.standardAppearance=appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance=appearance;
    }
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    CGFloat values[] = {0.9, 0.16, 0.12, 0.65};
    CGColorRef initial = CGColorCreate(space, values);
    self.color = [[UIColorValue alloc] initWithCGColor:initial];
    CGColorRelease(initial);
    CGColorSpaceRelease(space);
    id saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"UIDemo.SelectedColor.v1"];
    UIColorValue *restored = saved ? [[UIColorValue alloc] initWithPropertyList:saved error:NULL] : nil;
    if (restored) self.color = restored;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 240), YES, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSArray<UIColor *> *bands = @[UIColor.redColor, UIColor.orangeColor, UIColor.yellowColor,
                                  UIColor.greenColor, UIColor.cyanColor, UIColor.blueColor, UIColor.magentaColor, UIColor.whiteColor];
    for (NSUInteger i = 0; i < bands.count; i++) {
        CGColorSpaceRef gradientSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        NSArray *colors = @[(__bridge id)bands[i].CGColor, (__bridge id)UIColor.blackColor.CGColor];
        CGGradientRef gradient = CGGradientCreateWithColors(gradientSpace, (__bridge CFArrayRef)colors, NULL);
        CGContextSaveGState(context);
        CGContextClipToRect(context, CGRectMake(i * 40, 0, 40, 240));
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, 240), 0);
        CGContextRestoreGState(context);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(gradientSpace);
    }
    self.samplingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:20],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-20],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-40]
    ]];
    UILabel *description = [UILabel new];
    description.text = @"The custom panel runs on iOS 12 and later. Compare the system picker on iOS 14 and later.";
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    description.adjustsFontForContentSizeCategory = YES;
    description.numberOfLines = 0;
    [stack addArrangedSubview:description];
    UIView *wellBacking = [UIView new];
    wellBacking.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    wellBacking.layer.borderWidth = 1;
    wellBacking.layer.borderColor = UIColor.lightGrayColor.CGColor;
    [wellBacking.heightAnchor constraintEqualToConstant:100].active = YES;
    self.colorWell = [UIView new];
    self.colorWell.translatesAutoresizingMaskIntoConstraints = NO;
    [wellBacking addSubview:self.colorWell];
    [NSLayoutConstraint activateConstraints:@[
        [self.colorWell.topAnchor constraintEqualToAnchor:wellBacking.topAnchor constant:1],
        [self.colorWell.bottomAnchor constraintEqualToAnchor:wellBacking.bottomAnchor constant:-1],
        [self.colorWell.leadingAnchor constraintEqualToAnchor:wellBacking.leadingAnchor constant:1],
        [self.colorWell.trailingAnchor constraintEqualToAnchor:wellBacking.trailingAnchor constant:-1]
    ]];
    wellBacking.isAccessibilityElement = YES;
    wellBacking.accessibilityLabel = @"Selected color preview";
    [stack addArrangedSubview:wellBacking];
    self.componentLabel = [UILabel new];
    self.componentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.componentLabel.adjustsFontForContentSizeCategory = YES;
    self.componentLabel.numberOfLines = 0;
    [stack addArrangedSubview:self.componentLabel];
    UIButton *custom = [UIButton buttonWithType:UIButtonTypeSystem];
    [custom setTitle:@"Open Custom Color Panel" forState:UIControlStateNormal];
    custom.accessibilityIdentifier = @"demo.customPicker";
    [custom addTarget:self action:@selector(openCustomPanel) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:custom];
    UIButton *shared=[UIButton buttonWithType:UIButtonTypeSystem];
    [shared setTitle:@"Open Shared Color Panel" forState:UIControlStateNormal];
    shared.accessibilityIdentifier=@"demo.sharedPanel";
    [shared addTarget:self action:@selector(openSharedPanel) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:shared];
    UIColorPanelWell *activeWell=[[UIColorPanelWell alloc]initWithFrame:CGRectZero];
    self.classicWell=activeWell;
    activeWell.colorValue=self.color;activeWell.target=self;activeWell.action=@selector(changeWellColor:);
    activeWell.accessibilityLabel=@"Classic AppKit color well";activeWell.accessibilityIdentifier=@"demo.colorWell";
    self.recoveredWell=[[UIColorPickerWell alloc]initWithFrame:CGRectZero];
    self.recoveredWell.title=@"Recovered UIKit color";
    self.recoveredWell.accessibilityIdentifier=@"demo.recoveredWell";
    [self.recoveredWell addTarget:self action:@selector(changePickerWellColor:) forControlEvents:UIControlEventValueChanged];
    self.appearanceWell=[[UIColorPickerWell alloc]initWithFrame:CGRectZero];
    self.appearanceWell.title=@"Custom well appearance";
    self.appearanceWell.shape=UIColorPickerWellShapeRoundedRectangle;
    self.appearanceWell.centerAlphaAppearance=UIColorPickerWellCenterAlphaAppearanceDiagonalBlackWhiteBackground;
    self.appearanceWell.accessibilityIdentifier=@"demo.appearanceWell";
    [self.appearanceWell addTarget:self action:@selector(changePickerWellColor:) forControlEvents:UIControlEventValueChanged];
    NSMutableArray *wellExamples=[NSMutableArray arrayWithObjects:
        @{@"name":@"Classic AppKit well",@"view":activeWell,@"width":@52,@"height":@36},
        @{@"name":@"Recovered UIKit circle",@"view":self.recoveredWell},
        @{@"name":@"Recovered appearance",@"view":self.appearanceWell,@"width":@64,@"height":@36},nil];
    if(@available(iOS 14.0,*)){
        UIColorWell *nativeWell=[UIColorWell new];nativeWell.title=@"System UIKit color";
        nativeWell.accessibilityIdentifier=@"demo.nativeWell";
        [nativeWell addTarget:self action:@selector(changePickerWellColor:) forControlEvents:UIControlEventValueChanged];
        self.systemWell=nativeWell;
        [wellExamples insertObject:@{@"name":@"System UIKit well",@"view":nativeWell} atIndex:1];
    }
    for(NSDictionary *example in wellExamples){
        UILabel *label=[UILabel new];label.text=example[@"name"];label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];label.adjustsFontForContentSizeCategory=YES;label.numberOfLines=0;
        UIView *well=example[@"view"];
        UIStackView *row=[[UIStackView alloc]initWithArrangedSubviews:@[label,well]];row.axis=UILayoutConstraintAxisHorizontal;row.alignment=UIStackViewAlignmentCenter;row.spacing=12;
        // Circular examples use their intrinsic size, including later trait changes.
        if(example[@"width"])[well.widthAnchor constraintEqualToConstant:[example[@"width"]doubleValue]].active=YES;
        if(example[@"height"])[well.heightAnchor constraintEqualToConstant:[example[@"height"]doubleValue]].active=YES;
        if(!example[@"width"]){
            [well setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [well setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [well setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [well setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        }
        [stack addArrangedSubview:row];
    }
    if(!self.systemWell){UILabel *availability=[UILabel new];availability.text=@"The system UIKit well is available on iOS 14 and later.";availability.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];availability.adjustsFontForContentSizeCategory=YES;availability.numberOfLines=0;[stack addArrangedSubview:availability];}
    UILabel *shapeLabel=[UILabel new];shapeLabel.text=@"Rounded rectangle";shapeLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];shapeLabel.adjustsFontForContentSizeCategory=YES;shapeLabel.numberOfLines=0;
    UISwitch *shapeSwitch=[UISwitch new];shapeSwitch.on=YES;shapeSwitch.accessibilityLabel=shapeLabel.text;shapeSwitch.accessibilityIdentifier=@"demo.wellShape";[shapeSwitch addTarget:self action:@selector(changeWellShape:) forControlEvents:UIControlEventValueChanged];
    UIStackView *shapeRow=[[UIStackView alloc]initWithArrangedSubviews:@[shapeLabel,shapeSwitch]];shapeRow.axis=UILayoutConstraintAxisHorizontal;shapeRow.alignment=UIStackViewAlignmentCenter;shapeRow.spacing=12;[stack addArrangedSubview:shapeRow];
    UILabel *alphaLabel=[UILabel new];alphaLabel.text=@"Center alpha display";alphaLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];alphaLabel.adjustsFontForContentSizeCategory=YES;alphaLabel.numberOfLines=0;
    UISegmentedControl *alphaStyles=[[UISegmentedControl alloc]initWithItems:@[@"Native",@"Diagonal",@"Checker"]];alphaStyles.selectedSegmentIndex=self.appearanceWell.centerAlphaAppearance;alphaStyles.accessibilityLabel=alphaLabel.text;alphaStyles.accessibilityIdentifier=@"demo.wellAlphaAppearance";[alphaStyles addTarget:self action:@selector(changeWellAlphaAppearance:) forControlEvents:UIControlEventValueChanged];
    UIStackView *alphaRow=[[UIStackView alloc]initWithArrangedSubviews:@[alphaLabel,alphaStyles]];alphaRow.axis=UILayoutConstraintAxisVertical;alphaRow.spacing=8;[stack addArrangedSubview:alphaRow];
    UILabel *presetsLabel=[UILabel new];presetsLabel.text=@"Opacity presets";presetsLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];presetsLabel.adjustsFontForContentSizeCategory=YES;presetsLabel.numberOfLines=0;
    self.wellAlphaPresets=[[UISegmentedControl alloc]initWithItems:@[@"0%",@"35%",@"100%"]];self.wellAlphaPresets.accessibilityLabel=presetsLabel.text;self.wellAlphaPresets.accessibilityIdentifier=@"demo.wellAlphaPresets";[self.wellAlphaPresets addTarget:self action:@selector(changeWellAlphaPreset:) forControlEvents:UIControlEventValueChanged];
    UIStackView *presetsRow=[[UIStackView alloc]initWithArrangedSubviews:@[presetsLabel,self.wellAlphaPresets]];presetsRow.axis=UILayoutConstraintAxisVertical;presetsRow.spacing=8;[stack addArrangedSubview:presetsRow];
    UIButton *system = [UIButton buttonWithType:UIButtonTypeSystem];
    [system setTitle:@"Compare System Color Picker" forState:UIControlStateNormal];
    system.accessibilityIdentifier = @"demo.systemPicker";
    [system addTarget:self action:@selector(openSystemPicker) forControlEvents:UIControlEventTouchUpInside];
    if (@available(iOS 14.0, *)) { system.enabled = YES; } else { system.enabled = NO; }
    [stack addArrangedSubview:system];
    UILabel *sampling = [UILabel new];
    if (UICOLORPANEL_ENABLE_PRIVATE_API && [NSUserDefaults.standardUserDefaults boolForKey:@"UIUseSPI"]) {
        sampling.text = [UIEyedropperViewController supportsSystemCapture]
            ? @"Image mode uses the native Spectrum palette. The eyedropper samples the live system display."
            : @"Image mode uses the native Spectrum palette. Screen sampling is unavailable in this host.";
    } else {
        sampling.text = @"Image mode uses the native Spectrum palette. Sampling uses only the supplied application image.";
    }
    sampling.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    sampling.adjustsFontForContentSizeCategory = YES;
    sampling.numberOfLines = 0;
    [stack addArrangedSubview:sampling];
    [self updatePreview];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunCircleRefinementsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [NSTimer scheduledTimerWithTimeInterval:.01 repeats:NO block:^(NSTimer *timer){self.componentLabel.text=[UIColorPanelUIFidelityValidation runCircleRefinementsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-circle-refinements-validation.json"]]?@"Circle refinement checks passed":@"Circle refinement checks failed";}];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunSpectrumLensProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [NSTimer scheduledTimerWithTimeInterval:.01 repeats:NO block:^(NSTimer *timer){self.componentLabel.text=[UIColorPanelUIFidelityValidation runSpectrumLensWithOutputURL:[documents URLByAppendingPathComponent:@"spectrum-lens-validation.json"]]?@"Spectrum lens rasters saved":@"Spectrum lens capture failed";}];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunNativeFooterProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [NSTimer scheduledTimerWithTimeInterval:.01 repeats:NO block:^(NSTimer *timer){self.componentLabel.text=[UIColorFavoritesValidation runNativeFooterWithOutputURL:[documents URLByAppendingPathComponent:@"native-footer-validation.json"]]?@"Native footer checks passed":@"Native footer checks failed";}];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunSliderAnimationProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;[UIColorPanelUIFidelityValidation runSliderAnimationWithOutputURL:[documents URLByAppendingPathComponent:@"ui-slider-animation-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunWellRenderingProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=[UIColorPanelUIFidelityValidation runWellRenderingWithOutputURL:[documents URLByAppendingPathComponent:@"ui-well-rendering-validation.json"]]?@"Well rendering checks passed":@"Well rendering checks failed";return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunScopedReviewRepairsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=@"Checking scoped review repairs…";[UIColorPanelUIFidelityValidation runScopedReviewRepairsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-scoped-review-repairs-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunInputStateRepairsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=@"Checking input-state repairs…";[UIColorPanelUIFidelityValidation runInputStateRepairsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-input-state-repairs-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunInteractionRepairsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=@"Checking interaction repairs…";[UIColorPanelUIFidelityValidation runInteractionRepairsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-interaction-repairs-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunCompactInputRepairsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=[UIColorPanelUIFidelityValidation runCompactInputRepairsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-compact-input-repairs-validation.json"]]?@"Compact input repairs passed":@"Compact input repairs failed";return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunTouchRefinementsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=[UIColorPanelUIFidelityValidation runTouchRefinementsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-touch-refinements-validation.json"]]?@"Touch UI refinements passed":@"Touch UI refinements failed";return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunMajorRefinementsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=[UIColorPanelUIFidelityValidation runMajorRefinementsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-major-refinements-validation.json"]]?@"Major UI refinements passed":@"Major UI refinements failed";return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunProfileEditingProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        // Run outside the appearance callback and the main dispatch drain: this
        // finite synchronous probe pumps the run loop for main-queue results.
        [NSTimer scheduledTimerWithTimeInterval:.01 repeats:NO block:^(NSTimer *timer){self.componentLabel.text=[UIColorPanelProfileEditingValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"profile-editing-validation.json"]]?@"Profile editing passed":@"Profile editing failed";}];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunRuntimeProfileProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;self.componentLabel.text=@"Inspecting runtime color-profile capabilities…";dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{BOOL passed=[UIColorPanelRuntimeProfileProbe runWithOutputURL:[documents URLByAppendingPathComponent:@"runtime-profile-probe.json"]];dispatch_async(dispatch_get_main_queue(),^{self.componentLabel.text=passed?@"Runtime profile probe completed":@"Runtime profile probe baseline or output failed";});});return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunFavoritesProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;[UIColorFavoritesValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"favorites-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunReviewRepairsProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;[UIColorPanelUIFidelityValidation runReviewRepairsWithOutputURL:[documents URLByAppendingPathComponent:@"ui-review-repairs-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunEyedropperProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;if([NSUserDefaults.standardUserDefaults stringForKey:@"UIEyedropperInterfaceOrientation"].length)[UIEyedropperValidation runOrientationWithOutputURL:[documents URLByAppendingPathComponent:@"eyedropper-orientation-validation.json"]];else [UIEyedropperValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"eyedropper-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunLocaleProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;[UIColorPanelUIFidelityValidation runLocaleInputWithOutputURL:[documents URLByAppendingPathComponent:@"locale-input-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunWindowProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;[UIColorPanelUIFidelityValidation runWindowEditingWithOutputURL:[documents URLByAppendingPathComponent:@"window-editing-validation.json"]];return;}
    if(!self.didAutoOpen && [NSUserDefaults.standardUserDefaults boolForKey:@"UIRunFidelityProbe"]){self.didAutoOpen=YES;NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;BOOL passed=[UIColorPanelUIFidelityValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"ui-fidelity-validation.json"]];passed=[UIColorFavoritesValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"favorites-validation.json"]]&&passed;
#if UICOLORPANEL_ENABLE_PENCILS
        passed=[PencilValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"pencil-validation.json"]]&&passed;
#endif
        passed=[UIEyedropperValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"eyedropper-validation.json"]]&&passed;NSDictionary *polish=runPolishValidation();[[NSJSONSerialization dataWithJSONObject:polish options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil]writeToURL:[documents URLByAppendingPathComponent:@"polish-validation.json"] atomically:YES];passed=[polish[@"passed"]boolValue]&&passed;self.componentLabel.text=passed?@"UI fidelity validation passed":@"UI fidelity validation failed";return;}
    if(!self.didAutoOpen && [[NSUserDefaults standardUserDefaults]boolForKey:@"UIRunAPIProbe"]){
        self.didAutoOpen=YES;
        NSURL *documents=[[NSFileManager defaultManager]URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        BOOL passed=[UIColorPanelAPIValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"panel-api-validation.json"]];
        BOOL matchPassed=[UIColorColorMatchTests runWithOutputURL:[documents URLByAppendingPathComponent:@"color-match-tests.json"]];
        BOOL persistencePassed=[UIColorProfilePersistenceTests runWithOutputURL:[documents URLByAppendingPathComponent:@"profile-persistence-tests.json"]];
        NSData *spaces=[NSJSONSerialization dataWithJSONObject:[UIColorColorSpaceProbe environmentState] options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];
        [spaces writeToURL:[documents URLByAppendingPathComponent:@"color-space-capabilities.json"] atomically:YES];
        passed=passed&&matchPassed&&persistencePassed;
        self.componentLabel.text=passed?@"Panel API validation passed":@"Panel API validation failed";
        return;
    }
    if(!self.didAutoOpen && [[NSUserDefaults standardUserDefaults]boolForKey:@"UIRunLazyListProbe"]){
        self.didAutoOpen=YES;NSURL *documents=[[NSFileManager defaultManager]URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        BOOL passed=[UIColorPanelLazySelectionValidation runWithOutputURL:[documents URLByAppendingPathComponent:@"lazy-list-validation.json"] unmatchedP3:[[NSUserDefaults standardUserDefaults]boolForKey:@"UILazyP3Probe"]];
        self.componentLabel.text=passed?@"Lazy color-list validation passed":@"Lazy color-list validation failed";return;
    }
    if (!self.didAutoOpen && [[NSUserDefaults standardUserDefaults] boolForKey:@"UIShowPanel"]) {
        self.didAutoOpen = YES;
        [self openCustomPanel];
    }
    if (!self.didAutoOpen && [[NSUserDefaults standardUserDefaults] boolForKey:@"UIShowSharedPanel"]) {self.didAutoOpen=YES;[self openSharedPanel];}
    if([NSUserDefaults.standardUserDefaults objectForKey:@"UIFidelityMode"])UIColorPanel.sharedColorPanel.mode=[NSUserDefaults.standardUserDefaults integerForKey:@"UIFidelityMode"];
    NSString *preview=[NSUserDefaults.standardUserDefaults stringForKey:@"UIShowElement"];
    if(preview.length){dispatch_async(dispatch_get_main_queue(),^{UIColorPanelViewController *panel=(UIColorPanelViewController *)((UINavigationController *)UIColorPanel.sharedColorPanel.window.rootViewController).topViewController;NSString *key=[@{@"model":@"modelMenuButton",@"options":@"optionsMenuButton",@"favorites":@"savedColorsButton",@"sampler":@"sampleButton"}objectForKey:preview];UIButton *button=key?[panel valueForKey:key]:nil;if(button)[button sendActionsForControlEvents:UIControlEventTouchUpInside];});}

    if([NSUserDefaults.standardUserDefaults boolForKey:@"UIFidelitySeedSwatches"]){UIColorPanelViewController *controller=[UIColorPanel.sharedColorPanel valueForKey:@"pickerController"];UIColorPickerSwatchesView *swatches=[controller valueForKey:@"swatchesView"];swatches.persistenceKey=nil;swatches.favoritesStore=nil;[swatches setColor:self.color forSlot:0];[swatches setColor:[self.color copyWithAlpha:1] forSlot:1];[swatches setColor:[self.color copyWithAlpha:0] forSlot:2];
#if UICOLORPANEL_ENABLE_PENCILS
        if(controller.mode==UIColorPanelModePencils){UIColorPickerPencils *pencils=[controller valueForKey:@"pencilsPicker"];NSArray<UIColoredPencil *> *items=[pencils.pencilView _pencils];if(items.count>13)UIColorPanel.sharedColorPanel.colorValue=[items[13]color];}
#endif
    }

}

- (void)updatePreview {
    self.colorWell.layer.backgroundColor = self.color.CGColor;
    self.classicWell.colorValue=self.color;
    self.recoveredWell.selectedColor=self.color.UIColor;
    self.appearanceWell.selectedColor=self.color.UIColor;
    CGFloat alpha=CGColorGetAlpha(self.color.CGColor);
    self.wellAlphaPresets.selectedSegmentIndex=alpha==0?0:alpha==.35?1:alpha==1?2:UISegmentedControlNoSegment;
    if(@available(iOS 14.0,*))((UIColorWell *)self.systemWell).selectedColor=self.color.UIColor;
    CGColorSpaceRef space = CGColorGetColorSpace(self.color.CGColor);
    CFStringRef name = space ? CGColorSpaceCopyName(space) : NULL;
    NSMutableArray<NSString *> *components = [NSMutableArray array];
    const CGFloat *values = CGColorGetComponents(self.color.CGColor);
    for (NSUInteger i = 0; i < CGColorGetNumberOfComponents(self.color.CGColor); i++) {
        [components addObject:[NSString stringWithFormat:@"%.8g", (double)values[i]]];
    }
    self.componentLabel.text = [NSString stringWithFormat:@"%@\nComponents: %@", name ? (__bridge NSString *)name : @"Custom color space", [components componentsJoinedByString:@", "]];
    if (name) CFRelease(name);
    NSDictionary *archive = [self.color propertyListRepresentationWithError:NULL];
    if (archive) [[NSUserDefaults standardUserDefaults] setObject:archive forKey:@"UIDemo.SelectedColor.v1"];
}

- (void)openCustomPanel {
    NSDictionary *arguments = [NSUserDefaults.standardUserDefaults volatileDomainForName:NSArgumentDomain];
    BOOL touchFixture = [arguments[@"UIFavoritesTouchFixture"] boolValue];
    UIColorPanelConfiguration *configuration = [UIColorPanelConfiguration new];
    configuration.showsAlpha = YES;
    if (touchFixture) {
        configuration.favoritesStore = [[UIColorPickerFavoritesStore alloc] initWithKey:@"UIDemo.TouchFixture"];
    } else {
        configuration.savedColorsKey = @"UIDemo.SavedColors.v1";
    }
    configuration.samplingImage = self.samplingImage;configuration.allowsApplicationSampling=YES;configuration.use_spi=[NSUserDefaults.standardUserDefaults boolForKey:@"UIUseSPI"];
    NSInteger requested = [[NSUserDefaults standardUserDefaults] integerForKey:@"UIMode"];
    if (requested >= UIColorPanelModeGray && requested <= UIColorPanelModeGrid && [[NSUserDefaults standardUserDefaults]objectForKey:@"UIMode"]) configuration.initialMode = requested;
    UIColorValue *initialColor = self.color;
    if (touchFixture) {
        UIColor *cyan = [UIColor colorWithDisplayP3Red:.16 green:.68 blue:.92 alpha:.42];
        initialColor = [[UIColorValue alloc] initWithCGColor:cyan.CGColor];
    }
    UIColorPanelViewController *panel = [[UIColorPanelViewController alloc] initWithColor:initialColor configuration:configuration];
    if (!touchFixture) panel.delegate = self;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:panel];
    navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigation animated:YES completion:^{
        if (!touchFixture) return;
        UIColorPickerSwatchesView *swatches = [panel valueForKey:@"swatchesView"];
        swatches.favoritesStore = nil;
        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"UIDemo.TouchFixture"];
        // The second page makes horizontal movement visible and places Add after the saved colors.
        [swatches setColor:initialColor forSlot:0];
        [swatches setColor:initialColor forSlot:1];
        NSArray<UIColor *> *colors = @[UIColor.redColor, UIColor.orangeColor, UIColor.yellowColor,
                                      UIColor.greenColor, UIColor.blueColor, UIColor.purpleColor,
                                      UIColor.magentaColor, UIColor.brownColor, UIColor.grayColor,
                                      UIColor.blackColor, UIColor.whiteColor, UIColor.cyanColor,
                                      UIColor.lightGrayColor];
        for (NSUInteger index = 0; index < colors.count; index++) {
            UIColorValue *color = [[UIColorValue alloc] initWithCGColor:colors[index].CGColor];
            [swatches setColor:color forSlot:index + 2];
        }
    }];
}

- (void)openSharedPanel {
    UIColorPanel *panel=[UIColorPanel sharedColorPanel];panel.use_spi=[NSUserDefaults.standardUserDefaults boolForKey:@"UIUseSPI"];panel.allowsApplicationSampling=YES;panel.samplingImage=self.samplingImage;
    [panel setShowsAlpha:YES];
    [panel setColor:self.color.UIColor];
    [panel setTarget:self];
    [panel setAction:@selector(changeColor:)];
    if([NSUserDefaults.standardUserDefaults boolForKey:@"UIAXFixture"]){UINavigationController *nav=(UINavigationController *)panel.window.rootViewController;[nav setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge] forChildViewController:nav.topViewController];}
    [panel orderFront:self];
}

- (void)changeColor:(UIColorPanel *)sender {self.color=sender.colorValue;[self updatePreview];}
- (void)changeWellColor:(UIColorPanelWell *)sender {self.color=sender.colorValue;[self updatePreview];}
- (void)changePickerWellColor:(id)sender {UIColor *color=[sender selectedColor];if(color){self.color=[[UIColorValue alloc]initWithCGColor:color.CGColor];[self updatePreview];}}
- (void)changeWellShape:(UISwitch *)sender {self.appearanceWell.shape=sender.on?UIColorPickerWellShapeRoundedRectangle:UIColorPickerWellShapeCircle;}
- (void)changeWellAlphaAppearance:(UISegmentedControl *)sender {self.appearanceWell.centerAlphaAppearance=(UIColorPickerWellCenterAlphaAppearance)sender.selectedSegmentIndex;}
- (void)changeWellAlphaPreset:(UISegmentedControl *)sender {CGFloat values[]={0,.35,1};self.color=[self.color copyWithAlpha:values[sender.selectedSegmentIndex]];[self updatePreview];}

- (void)openSystemPicker {
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *picker = [UIColorPickerViewController new];
        picker.selectedColor = self.color.UIColor;
        picker.supportsAlpha = YES;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color {
    self.color = color;
    [self updatePreview];
}

- (void)colorPanelDidFinish:(UIColorPanelViewController *)panel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController API_AVAILABLE(ios(14.0)) {
    self.color = [[UIColorValue alloc] initWithCGColor:viewController.selectedColor.CGColor];
    [self updatePreview];
}
@end

@interface UIDemoAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end
@implementation UIDemoAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Only the explicitly private demo opts in by default; the reusable library remains NO.
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"UIUseSPI":@(UICOLORPANEL_ENABLE_PRIVATE_API)}];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[UIDemoViewController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(UIDemoAppDelegate.class)); }
}
