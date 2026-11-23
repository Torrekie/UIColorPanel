#import "UIColorPanelViewController.h"
#import "UIColorPanel.h"
#import "UIColorSurface.h"
#import "UIColorPickerCatalogController.h"
#import "UIColorPickerImagePaletteController.h"
#import "UIColorPickerSwatchesView+Internal.h"
#import "UIColorPickerFavoritesStore+Internal.h"
#import "UIColorPanelFavoriteSwatchLayout.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import "UIColorPickerPencils.h"
#import "UIColorPickerPencilView.h"
#endif
#import "UIColorPanelMenuButton.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelChoiceController.h"
#import "UIColorPanelSavedColorsController.h"
#import "UIEyedropperViewController.h"
#import "UIColorPanelLifecycle.h"
#import "UIColorPanelProfileLibrary.h"
#import "RecoveredElements/UIColorPickerSpectrum.h"
#import "RecoveredElements/UIColorPickerGridView.h"
#import "RecoveredElements/UIColorPickerColorPreview.h"
#import <QuartzCore/QuartzCore.h>

@interface UIColorPanelModeControl : UISegmentedControl
@property(nonatomic,strong) CAShapeLayer *keyboardFocusLayer;
@property(nonatomic,copy) BOOL (^keyboardFocusNavigationHandler)(BOOL backwards);
@end
@implementation UIColorPanelModeControl
// BINMAP-ADAPT: UIColorPanelModeControl.canBecomeFirstResponder manifest=reimpl/touch_panel_extras.json
- (BOOL)canBecomeFirstResponder {return self.enabled&&!self.hidden&&self.numberOfSegments>0;}
// BINMAP-ADAPT: UIColorPanelModeControl.becomeFirstResponder manifest=reimpl/touch_panel_extras.json
- (BOOL)becomeFirstResponder {BOOL result=[super becomeFirstResponder];[self setNeedsLayout];return result;}
// BINMAP-ADAPT: UIColorPanelModeControl.resignFirstResponder manifest=reimpl/touch_panel_extras.json
- (BOOL)resignFirstResponder {BOOL result=[super resignFirstResponder];[self setNeedsLayout];return result;}
// BINMAP-ADAPT: UIColorPanelModeControl.layoutSubviews manifest=reimpl/touch_panel_extras.json
- (void)layoutSubviews {
    [super layoutSubviews];
    if(self.isFirstResponder&&!self.keyboardFocusLayer){self.keyboardFocusLayer=[CAShapeLayer layer];self.keyboardFocusLayer.fillColor=UIColor.clearColor.CGColor;self.keyboardFocusLayer.lineWidth=2;[self.layer addSublayer:self.keyboardFocusLayer];}
    [CATransaction begin];[CATransaction setDisableActions:YES];self.keyboardFocusLayer.hidden=!self.isFirstResponder;self.keyboardFocusLayer.frame=self.bounds;self.keyboardFocusLayer.strokeColor=self.tintColor.CGColor;self.keyboardFocusLayer.path=[UIColorPanelAppearance smoothPathForRect:CGRectInset(self.bounds,1,1) radius:8].CGPath;[CATransaction commit];
}
// BINMAP-ADAPT: UIColorPanelModeControl.keyCommands manifest=reimpl/touch_panel_extras.json
- (NSArray<UIKeyCommand *> *)keyCommands {
    return @[[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(handleKeyboardCommand:)],[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(handleKeyboardCommand:)],[UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:0 action:@selector(handleKeyboardCommand:)],[UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:UIKeyModifierShift action:@selector(handleKeyboardCommand:)]];
}
// BINMAP-ADAPT: UIColorPanelModeControl.handleKeyboardCommand: manifest=reimpl/touch_panel_extras.json
- (void)handleKeyboardCommand:(UIKeyCommand *)command {
    if([command.input isEqual:@"\t"]){if(self.keyboardFocusNavigationHandler)self.keyboardFocusNavigationHandler((command.modifierFlags&UIKeyModifierShift)!=0);return;}
    NSInteger direction=[command.input isEqual:UIKeyInputLeftArrow]?-1:1;
    if(self.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft)direction=-direction;
    for(NSInteger index=self.selectedSegmentIndex+direction;index>=0&&index<(NSInteger)self.numberOfSegments;index+=direction)if([self isEnabledForSegmentAtIndex:index]){self.selectedSegmentIndex=index;[self sendActionsForControlEvents:UIControlEventValueChanged];break;}
}
@end

@protocol UIColorPanelNumericSelection <NSObject>
- (void)constrainPercentageSelection:(UITextField *)field;
@end
@interface UIColorPanelNumericTextField : UITextField
@property(nonatomic,weak) id<UIColorPanelNumericSelection> selectionOwner;
@property(nonatomic) BOOL forwardingSelection;
@end
@implementation UIColorPanelNumericTextField
// BINMAP-ADAPT: UIColorPanelNumericTextField.tintColorDidChange manifest=reimpl/touch_panel_extras.json original15=0x10001AEA0
- (void)tintColorDidChange {[super tintColorDidChange];self.inputAccessoryView.tintColor=self.tintColor;}
// BINMAP-ADAPT: UIColorPanelNumericTextField.setSelectedTextRange: manifest=reimpl/touch_panel_extras.json
- (void)setSelectedTextRange:(UITextRange *)range {
    [super setSelectedTextRange:range];
    if(self.forwardingSelection)return;
    self.forwardingSelection=YES;[self.selectionOwner constrainPercentageSelection:self];self.forwardingSelection=NO;
}
@end

@interface UIColorPanelNumericField : UIControl
@property(nonatomic,strong) UIColorPanelNumericTextField *textField;
@property(nonatomic) CGFloat fieldWidth;
@property(nonatomic) BOOL hex;
@property(nonatomic,weak) UILabel *captionLabel;
- (instancetype)initWithWidth:(CGFloat)width hex:(BOOL)hex;
- (void)refreshFont;
@end
@implementation UIColorPanelNumericField
// BINMAP-ADAPT: UIColorPanelNumericField.initWithWidth:hex: manifest=reimpl/touch_panel_extras.json original=0x100019610
- (instancetype)initWithWidth:(CGFloat)width hex:(BOOL)hex {
    if((self=[super initWithFrame:CGRectZero])){
        _fieldWidth=width;_hex=hex;_textField=[UIColorPanelNumericTextField new];
        _textField.borderStyle=UITextBorderStyleNone;_textField.textAlignment=NSTextAlignmentCenter;
        _textField.adjustsFontSizeToFitWidth=YES;
        // The owner refreshes a capped font on every trait change, including iOS12.
        _textField.adjustsFontForContentSizeCategory=NO;
        [_textField setContentCompressionResistancePriority:250 forAxis:UILayoutConstraintAxisHorizontal];
        [_textField setContentCompressionResistancePriority:250 forAxis:UILayoutConstraintAxisVertical];
        _textField.translatesAutoresizingMaskIntoConstraints=NO;[self addSubview:_textField];
        [NSLayoutConstraint activateConstraints:@[[_textField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],[_textField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],[_textField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],[_textField.heightAnchor constraintEqualToConstant:36]]];
        [self refreshFont];
    }return self;
}
// BINMAP-ADAPT: UIColorPanelNumericField.intrinsicContentSize manifest=reimpl/touch_panel_extras.json
- (CGSize)intrinsicContentSize {return CGSizeMake(self.fieldWidth,44);}
// BINMAP-ADAPT: UIColorPanelNumericField.refreshFont manifest=reimpl/touch_panel_extras.json original15=0x1000333A0,0x10000D1B0
- (void)refreshFont {
    NSArray *categories=@[UIContentSizeCategoryExtraSmall,UIContentSizeCategorySmall,UIContentSizeCategoryMedium,UIContentSizeCategoryLarge,UIContentSizeCategoryExtraLarge,UIContentSizeCategoryExtraExtraLarge,UIContentSizeCategoryExtraExtraExtraLarge,UIContentSizeCategoryAccessibilityMedium,UIContentSizeCategoryAccessibilityLarge,UIContentSizeCategoryAccessibilityExtraLarge,UIContentSizeCategoryAccessibilityExtraExtraLarge,UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];
    UIContentSizeCategory maximum=self.hex?UIContentSizeCategoryExtraExtraExtraLarge:UIContentSizeCategoryAccessibilityExtraLarge;
    UITraitCollection *traits=self.traitCollection;
    NSUInteger index=[categories indexOfObject:traits.preferredContentSizeCategory];
    if(index!=NSNotFound&&index>[categories indexOfObject:maximum])traits=[UITraitCollection traitCollectionWithTraitsFromCollections:@[traits,[UITraitCollection traitCollectionWithPreferredContentSizeCategory:maximum]]];
    UIFontDescriptor *font=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:traits];font=[font fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightMedium)}}];self.textField.font=[UIFont fontWithDescriptor:font size:0];
    self.captionLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:traits];
}
// BINMAP-ADAPT: UIColorPanelNumericField.layoutSubviews manifest=reimpl/touch_panel_extras.json
- (void)layoutSubviews {
    [super layoutSubviews];
    if(@available(iOS 13,*))self.textField.backgroundColor=UIColor.systemBackgroundColor;else self.textField.backgroundColor=UIColor.whiteColor;
    [UIColorPanelAppearance applyCornersToView:self.textField radius:8 useSPI:NO];
}
// BINMAP-ADAPT: UIColorPanelNumericField.traitCollectionDidChange: manifest=reimpl/touch_panel_extras.json original=0x100019610
- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    [self refreshFont];
}
@end

@implementation UIColorPalette
// BINMAP-ADAPT: UIColorPalette.initWithName:colors:names:
- (instancetype)initWithName:(NSString *)name colors:(NSArray<UIColorValue *> *)colors names:(NSArray<NSString *> *)names {
    NSParameterAssert(colors.count==names.count);
    if((self=[super init])){_name=[name copy];_colors=[colors copy];_names=[names copy];}return self;
}
@end

@implementation UIColorPanelConfiguration
// BINMAP-ADAPT: UIColorPanelConfiguration.init
- (instancetype)init {
    if((self=[super init])){_use_spi=NO;_showsAlpha=YES;_supportsAlpha=YES;_initialMode=UIColorPanelModeWheel;_palettes=@[];_colorProfiles=@[];}return self;
}
// BINMAP-ADAPT: UIColorPanelConfiguration.copyWithZone: manifest=reimpl/ui_extras.json
- (id)copyWithZone:(NSZone *)zone {
    UIColorPanelConfiguration *copy = [[[self class] allocWithZone:zone] init];
    copy.use_spi = self.use_spi;
    copy.showsAlpha = self.showsAlpha;
    copy.supportsAlpha = self.supportsAlpha;
    copy.initialMode = self.initialMode;
    copy.palettes = self.palettes;
    copy.savedColorsKey = self.savedColorsKey;
    copy.favoritesStore = self.favoritesStore;
    copy.samplingImage = self.samplingImage;
    copy.allowsApplicationSampling = self.allowsApplicationSampling;
    copy.samplingSourceView = self.samplingSourceView;
    copy.colorProfiles = self.colorProfiles;
    return copy;
}
@end

@interface UIColorPanelViewController () <UITextFieldDelegate,UIColorPanelNumericSelection,UIDocumentPickerDelegate,UIColorPickerCatalogControllerDelegate,UIColorPickerImagePaletteControllerDelegate,UIColorPickerSwatchesViewDelegate,UIColorPanelTransientOwner> {
    CGColorSpaceRef _originalSpace;
    CGFloat _hue,_saturation,_brightness;
    BOOL _sampling;
    BOOL _updating;
    BOOL _applyingEdit;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    BOOL _favoritesUseSPI;
#endif
    CGRect _keyboardFrame;
}
@property(nonatomic,strong) UIColorPanelConfiguration *configuration;
@property(nonatomic,strong) UIView *opacityRow,*hostAccessoryView;
@property(nonatomic,strong) UIColorPickerCatalogController *catalogController;
@property(nonatomic,strong) UIColorPickerImagePaletteController *imagePaletteController;
@property(nonatomic,strong) NSMutableDictionary<NSString *,UIColorList *> *attachedColorLists;
@property(nonatomic,strong) UIView *rootStack,*footer,*providerHost,*pencilContainer;
@property(nonatomic,strong) UIStackView *workspace;
@property(nonatomic,strong) UIStackView *favoritesRow;
@property(nonatomic,strong) UIView *footerDivider;
@property(nonatomic,strong) NSLayoutConstraint *nativeFavoritesHeight;
@property(nonatomic,strong) UISegmentedControl *modeControl;
@property(nonatomic,strong) UISegmentedControl *discreteModeControl;
@property(nonatomic) UIColorPanelMode discreteMode;
@property(nonatomic,copy) NSArray<NSNumber *> *modeSegmentModes;
@property(nonatomic,strong) UIColorPanelMenuButton *modelMenuButton,*optionsMenuButton;
@property(nonatomic,strong) UIButton *sampleButton,*savedColorsButton;
@property(nonatomic,strong) UIBarButtonItem *savedColorsItem;
@property(nonatomic,strong) UIColorPanelSavedColorsController *savedColorsController;
@property(nonatomic,strong) UILabel *pencilNameLabel;
@property(nonatomic,strong) NSLayoutConstraint *imageHeaderHeight;
@property(nonatomic,strong) NSMutableArray<NSLayoutConstraint *> *componentFullWidths;
#if UICOLORPANEL_ENABLE_PENCILS
@property(nonatomic,strong) UIColorPickerPencils *pencilsPicker;
#endif
@property(nonatomic,strong) UIScrollView *scroll,*overflowScroll;
@property(nonatomic,weak) UITextField *invalidField;
@property(nonatomic,strong) UIAlertController *inputErrorAlert;
@property(nonatomic,strong) NSHashTable<UIViewController *> *transientPresentations;
@property(nonatomic) NSUInteger transientGeneration,samplingGeneration;
@property(nonatomic,strong) UIEyedropperViewController *activeSamplingController;
@property(nonatomic,strong) UIView *samplingSurface;
@property(nonatomic,strong) UIView *samplingUnderlay;
@property(nonatomic,weak) UIWindow *samplingUnderlayWindow;
@property(nonatomic,weak) UIView *samplingUnderlaySuperview;
@property(nonatomic) NSUInteger samplingUnderlayIndex;
@property(nonatomic) CGRect samplingUnderlayBounds;
@property(nonatomic) CGPoint samplingUnderlayCenter;
@property(nonatomic) CGAffineTransform samplingUnderlayTransform;
@property(nonatomic) UIViewTintAdjustmentMode samplingUnderlayTintMode;
@property(nonatomic) CGFloat samplingSurfaceAlpha;
@property(nonatomic) float samplingSurfaceOpacity;
@property(nonatomic) NSUInteger samplingSurfaceGeneration;
@property(nonatomic,strong) NSValue *pendingSamplingPoint;
@property(nonatomic) BOOL ownsSamplingSurface,endingTransientInteractions;
@property(nonatomic) BOOL submittingEdits;
@property(nonatomic,copy) BOOL (^samplingIdentityValid)(void);
@property(nonatomic,strong) UISegmentedControl *sliderModel,*spaces,*precision,*palettePicker;
@property(nonatomic,strong) UIColorValue *sampleOriginalColor;
@property(nonatomic) UIColorPanelMode sampleOriginalMode;
@property(nonatomic,strong) UIColorPickerWheelView *wheel;
@property(nonatomic,strong) UIGradientSlider *brightnessSlider,*opacitySlider;
@property(nonatomic,strong) UITextField *opacityField,*hexField;
@property(nonatomic,strong) UILabel *spaceLabel,*selectionLabel,*hexLabel;
@property(nonatomic,strong) UIColorPickerColorPreview *currentWell;
@property(nonatomic,strong) UIColorPickerUserView *imageSampler;
@property(nonatomic,strong) UIColorPickerSpectrum *spectrum;
@property(nonatomic,strong) UIColorPickerGridView *grid;
@property(nonatomic,strong) UIImage *paletteImage;
@property(nonatomic,strong) NSArray<UIGradientSlider *> *componentSliders;
@property(nonatomic,strong) NSArray<UITextField *> *componentFields;
@property(nonatomic,copy) NSArray<UIColorPanelColorWell *> *grayShortcutButtons;
@property(nonatomic,strong) NSMutableDictionary<NSNumber *,UIColorPanelNumericField *> *fieldContainers;
@property(nonatomic,strong) UIColorPickerSwatchesView *swatchesView;
@property(nonatomic,strong) NSHashTable<UITextField *> *editedFields;
@property(nonatomic,strong) NSMutableSet<UIControl *> *activeEditingControls;
@property(nonatomic,strong) NSHashTable<UILabel *> *ownedLabels;
@property(nonatomic,strong) NSHashTable<UILabel *> *componentLabels;
@property(nonatomic,strong) NSArray<UIColorPalette *> *palettes;
@property(nonatomic) NSInteger sliderIndex,spaceIndex,precisionIndex,paletteIndex;
@property(nonatomic,strong) UIColorPanelProfileLibrary *profileLibrary;
@property(nonatomic,strong) NSMutableDictionary<NSNumber *,UIColorPanelColorProfile *> *workingProfiles;
@property(nonatomic) NSUInteger profileGeneration;
@end

@implementation UIColorPanelViewController
// BINMAP-ADAPT: UIColorPanelViewController.initWithColor:configuration:
- (instancetype)initWithColor:(UIColorValue *)color configuration:(UIColorPanelConfiguration *)configuration {
    NSParameterAssert(color);NSParameterAssert(configuration);
    if((self=[super initWithNibName:nil bundle:nil])){
        _selectedColor=color;_configuration=[configuration copy];
        UIColorPanelMode initialMode = _configuration.initialMode;
        _mode=initialMode>=UIColorPanelModeGray&&initialMode<=UIColorPanelModeGrid?initialMode:UIColorPanelModeWheel;_pickerMask=UIColorPanelAllModesMask;
#if !UICOLORPANEL_ENABLE_PENCILS
        _pickerMask &= ~UIColorPanelCrayonModeMask;
        if (_mode == UIColorPanelModePencils) _mode = UIColorPanelModeGrid;
#endif
        _discreteMode=_mode==UIColorPanelModeGrid?UIColorPanelModeGrid:UIColorPanelModePencils;
        _originalSpace=CGColorSpaceRetain(CGColorGetColorSpace(color.CGColor));
        _sliderIndex=_mode>=UIColorPanelModeGray&&_mode<=UIColorPanelModeHSB?_mode:1;_precisionIndex=0;_spaceIndex=2;
        if(CGColorSpaceGetModel(_originalSpace)!=kCGColorSpaceModelRGB)_spaceIndex=0;
        _profileLibrary=[UIColorPanelProfileLibrary new];_workingProfiles=[NSMutableDictionary new];
        [self profileForMode:_mode];
        _keyboardFrame=CGRectNull;
        self.preferredContentSize=UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPhone?CGSizeZero:CGSizeMake(336,645);
    }return self;
}
// BINMAP-ADAPT: UIColorPanelViewController.dealloc
- (void)dealloc {[self.profileLibrary cancelPendingDiscovery];[self restoreSamplingSurfaceForGeneration:self.samplingGeneration];CGColorSpaceRelease(_originalSpace);[[NSNotificationCenter defaultCenter]removeObserver:self];}
// BINMAP-ADAPT: UIColorPanelViewController.setSelectedColor:
- (void)setSelectedColor:(UIColorValue *)selectedColor {
    NSParameterAssert(selectedColor);UIColorPanelMode previousMode=self.mode;_selectedColor=selectedColor;
    if(!_applyingEdit){
        // RGB black has no saturation; only internal HSB edits retain one.
        _saturation=0;
        [self.editedFields removeAllObjects];self.invalidField=nil;
        NSMutableArray *fields=[self.componentFields mutableCopy]?:[NSMutableArray new];if(self.hexField)[fields addObject:self.hexField];if(self.opacityField)[fields addObject:self.opacityField];
        for(UITextField *field in fields)if(field.isFirstResponder){
            [field resignFirstResponder];
            // Ending actual editing can synchronously install a newer source.
            // Its complete state wins; never adopt this stale setter's profile.
            if(_selectedColor!=selectedColor)return;
        }
    }
    CGColorSpaceRef incoming=CGColorGetColorSpace(selectedColor.CGColor);
    BOOL sourceChanged=!_applyingEdit && incoming && (!CFEqual(incoming,_originalSpace)||self.spaceIndex!=2);
    if(sourceChanged){CGColorSpaceRelease(_originalSpace);_originalSpace=CGColorSpaceRetain(incoming);self.spaceIndex=CGColorSpaceGetModel(incoming)==kCGColorSpaceModelRGB?2:0;}
    if(!_applyingEdit){++self.profileGeneration;[self acceptSourceProfile:selectedColor];}
    self.catalogController.selectedColor=selectedColor;
    if(self.isViewLoaded){if((sourceChanged||previousMode!=self.mode) && self.mode>=UIColorPanelModeGray && self.mode<=UIColorPanelModeHSB)[self buildMode];[self updateControls];}
}
// BINMAP-ADAPT: UIColorPanelViewController.colorProfiles manifest=reimpl/slider_profile_extras.json
- (NSArray<UIColorPanelColorProfile *> *)colorProfiles {return self.configuration.colorProfiles?:@[];}
// BINMAP-ADAPT: UIColorPanelViewController.setColorProfiles: manifest=reimpl/slider_profile_extras.json
- (void)setColorProfiles:(NSArray<UIColorPanelColorProfile *> *)profiles {
    NSMutableArray *valid=[NSMutableArray new];for(id profile in profiles)if([profile isKindOfClass:UIColorPanelColorProfile.class])[valid addObject:profile];
    self.configuration.colorProfiles=valid;[self updateProfileMenus];
}
// BINMAP-ADAPT: UIColorPanelViewController.availableColorProfiles manifest=reimpl/slider_profile_extras.json
- (NSArray<UIColorPanelColorProfile *> *)availableColorProfiles {
    UIColorPanelColorProfile *source=_originalSpace?[[UIColorPanelColorProfile alloc]initWithColorSpace:_originalSpace displayName:nil]:nil;
    return[UIColorPanelProfileLibrary profilesByCombiningProfiles:@[self.colorProfiles,source?@[source]:@[],[UIColorPanelProfileLibrary standardProfiles],self.use_spi?self.profileLibrary.systemProfiles:@[],self.workingProfiles.allValues?:@[]]];
}
// BINMAP-ADAPT: UIColorPanelViewController.profilesForMode: manifest=reimpl/slider_profile_extras.json
- (NSArray<UIColorPanelColorProfile *> *)profilesForMode:(UIColorPanelMode)mode {
    if(mode<UIColorPanelModeGray||mode>UIColorPanelModeHSB)return @[];
    CGColorSpaceModel model=mode==UIColorPanelModeGray?kCGColorSpaceModelMonochrome:mode==UIColorPanelModeCMYK?kCGColorSpaceModelCMYK:kCGColorSpaceModelRGB;
    NSMutableArray *profiles=[NSMutableArray new];for(UIColorPanelColorProfile *profile in self.availableColorProfiles)if(profile.model==model)[profiles addObject:profile];return profiles;
}
// BINMAP-ADAPT: UIColorPanelViewController.profileForMode: manifest=reimpl/slider_profile_extras.json
- (UIColorPanelColorProfile *)profileForMode:(UIColorPanelMode)mode {
    if(mode<UIColorPanelModeGray||mode>UIColorPanelModeHSB)return nil;
    UIColorPanelColorProfile *profile=self.workingProfiles[@(mode)];if(profile)return profile;
    CGColorSpaceModel model=mode==UIColorPanelModeGray?kCGColorSpaceModelMonochrome:mode==UIColorPanelModeCMYK?kCGColorSpaceModelCMYK:kCGColorSpaceModelRGB;
    CGColorSpaceRef source=CGColorGetColorSpace(self.selectedColor.CGColor),space=NULL;
    if(source&&CGColorSpaceGetModel(source)==model)space=CGColorSpaceRetain(source);
    else {space=CGColorSpaceCreateWithName(mode==UIColorPanelModeGray?kCGColorSpaceGenericGrayGamma2_2:mode==UIColorPanelModeCMYK?kCGColorSpaceGenericCMYK:kCGColorSpaceGenericRGB);if(!space&&model==kCGColorSpaceModelRGB)space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);}
    if(space){profile=[[UIColorPanelColorProfile alloc]initWithColorSpace:space displayName:nil];CGColorSpaceRelease(space);if(profile)self.workingProfiles[@(mode)]=profile;}return profile;
}
// BINMAP-ADAPT: UIColorPanelViewController.activeColorProfile manifest=reimpl/slider_profile_extras.json
- (UIColorPanelColorProfile *)activeColorProfile {return[self profileForMode:self.mode];}
// BINMAP-ADAPT: UIColorPanelViewController.acceptSourceProfile: manifest=reimpl/slider_profile_extras.json
- (void)acceptSourceProfile:(UIColorValue *)color {
    if(self.mode<UIColorPanelModeGray||self.mode>UIColorPanelModeHSB)return;
    CGColorSpaceRef space=CGColorGetColorSpace(color.CGColor);CGColorSpaceModel model=space?CGColorSpaceGetModel(space):kCGColorSpaceModelUnknown;
    if(model<kCGColorSpaceModelMonochrome||model>kCGColorSpaceModelCMYK)return;
    UIColorPanelMode desired=model==kCGColorSpaceModelMonochrome?UIColorPanelModeGray:model==kCGColorSpaceModelCMYK?UIColorPanelModeCMYK:self.mode==UIColorPanelModeHSB?UIColorPanelModeHSB:UIColorPanelModeRGB;
    if(self.pickerMask&(1UL<<desired)){_mode=desired;self.sliderIndex=desired;}
    CGColorSpaceModel current=self.mode==UIColorPanelModeGray?kCGColorSpaceModelMonochrome:self.mode==UIColorPanelModeCMYK?kCGColorSpaceModelCMYK:kCGColorSpaceModelRGB;
    if(model==current){UIColorPanelColorProfile *profile=[[UIColorPanelColorProfile alloc]initWithColorSpace:space displayName:nil];if(profile)self.workingProfiles[@(self.mode)]=profile;}
}
// BINMAP-ADAPT: UIColorPanelViewController.regularColor:profile: manifest=reimpl/slider_profile_extras.json
- (UIColorValue *)regularColor:(UIColorValue *)color profile:(UIColorPanelColorProfile *)profile {
    // Native NSColorSpaceSliders regularColorIfPossible: normalizes DeviceGray
    // to Gamma2.2 with the same white/alpha; Gray shortcut buttons bypass it.
    CGColorSpaceRef device=CGColorSpaceCreateDeviceGray();BOOL normalize=profile&&CFEqual(device,profile.CGColorSpace);CGColorSpaceRelease(device);
    if(!normalize||!color)return color;
    CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGrayGamma2_2);CGColorRef cg=space?CGColorCreate(space,CGColorGetComponents(color.CGColor)):NULL;
    UIColorValue *result=cg?[[UIColorValue alloc]initWithCGColor:cg]:nil;if(cg)CGColorRelease(cg);if(space)CGColorSpaceRelease(space);return result;
}
// BINMAP-ADAPT: UIColorPanelViewController.selectColorProfile:error: manifest=reimpl/slider_profile_extras.json
- (BOOL)selectColorProfile:(UIColorPanelColorProfile *)profile error:(NSError **)error {
    return[self selectColorProfile:profile error:error animated:NO];
}
// BINMAP-ADAPT: UIColorPanelViewController.performAnimatedColorUpdates:expectedColor: manifest=reimpl/slider_animation_extras.json
- (void)performAnimatedColorUpdates:(void (^)(void))updates expectedColor:(UIColorValue *)expected {
    NSMutableArray *sliders=[self.componentSliders mutableCopy]?:[NSMutableArray new];
    if(self.opacitySlider)[sliders addObject:self.opacitySlider];if(self.brightnessSlider)[sliders addObject:self.brightnessSlider];
    NSUInteger generation=self.transientGeneration;
    [UIColorPickerColorSlider animateChangesToSliders:sliders updates:updates];
    // A synchronous host callback can override the result or close the panel.
    // It owns the final state and must not inherit this operation's animation.
    if(self.transientGeneration!=generation||!CGColorEqualToColor(self.selectedColor.CGColor,expected.CGColor))for(UIColorPickerColorSlider *slider in sliders)[slider cancelPresentationAnimation];
}
// BINMAP-ADAPT: UIColorPanelViewController.selectColorProfile:error:animated: manifest=reimpl/slider_animation_extras.json
- (BOOL)selectColorProfile:(UIColorPanelColorProfile *)profile error:(NSError **)error animated:(BOOL)animated {
    if(error)*error=nil;
    UIColorPanelMode mode=self.mode;NSUInteger generation=self.profileGeneration,transientGeneration=self.transientGeneration;
    CGColorSpaceModel model=mode==UIColorPanelModeGray?kCGColorSpaceModelMonochrome:mode==UIColorPanelModeCMYK?kCGColorSpaceModelCMYK:kCGColorSpaceModelRGB;
    BOOL compatible=mode>=UIColorPanelModeGray&&mode<=UIColorPanelModeHSB&&[profile isKindOfClass:UIColorPanelColorProfile.class]&&profile.model==model;
    if(!compatible){if(error)*error=[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorIncompatibleModel userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"This color profile is unavailable."]}];return NO;}
    if(![self commitPendingEdits]){if(error)*error=[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorInvalidICC userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"Enter a finite number."]}];return NO;}
    if(self.mode!=mode||self.profileGeneration!=generation||self.transientGeneration!=transientGeneration){if(error)*error=[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorSelectionSuppressed userInfo:@{NSLocalizedDescriptionKey:@"The panel changed while committing the color edit."}];return NO;}
    UIColorPanelColorProfile *previous=self.activeColorProfile;
    if(self.mode!=UIColorPanelModeCMYK&&[previous isEqual:profile])return YES;
    UIColorValue *converted=[self.selectedColor colorByConvertingToSpace:profile.CGColorSpace error:error];converted=[self regularColor:converted profile:profile];if(!converted){if(error&&!*error)*error=[NSError errorWithDomain:UIColorPanelColorProfileErrorDomain code:UIColorPanelColorProfileErrorInvalidICC userInfo:@{NSLocalizedDescriptionKey:[UIColorPanelAppearance localizedString:@"This color profile is unavailable."]}];return NO;}
    self.workingProfiles[@(self.mode)]=profile;
    self.spaceIndex=_originalSpace&&CFEqual(_originalSpace,profile.CGColorSpace)?2:0;
    CGColorSpaceRef p3=CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);if(self.spaceIndex!=2&&p3&&CFEqual(p3,profile.CGColorSpace))self.spaceIndex=1;if(p3)CGColorSpaceRelease(p3);
    BOOL changed=!CGColorEqualToColor(converted.CGColor,self.selectedColor.CGColor);
    if(animated)[self performAnimatedColorUpdates:^{[self applyColor:converted notify:changed];} expectedColor:converted];else[self applyColor:converted notify:changed];
    [self updateProfileMenus];return YES;
}
// BINMAP-ADAPT: UIColorPanelViewController.refreshColorProfiles manifest=reimpl/slider_profile_extras.json
- (void)refreshColorProfiles {
    __weak typeof(self) weakSelf=self;
    // Discovery is independent of the current color. The library rejects superseded
    // requests and close cancels it; changing source must not strand its menu refresh.
    [self.profileLibrary refreshSystemProfilesUsingSPI:self.use_spi completion:^(UIColorPanelProfileLibrary *library){[weakSelf updateProfileMenus];}];
}
// BINMAP-ADAPT: UIColorPanelViewController.profileMenuTitle:profiles: manifest=reimpl/slider_profile_extras.json
- (NSString *)profileMenuTitle:(UIColorPanelColorProfile *)profile profiles:(NSArray<UIColorPanelColorProfile *> *)profiles {
    NSUInteger count=0;for(UIColorPanelColorProfile *other in profiles)if([other.displayName isEqualToString:profile.displayName])count++;
    // Native menus truncate long titles at the tail; keep the distinguishing
    // identity visible even when two profiles have the same long ICC name.
    return count>1?[NSString stringWithFormat:@"[%@] %@",[profile.identifier substringToIndex:MIN((NSUInteger)8,profile.identifier.length)],profile.displayName]:profile.displayName;
}
// BINMAP-ADAPT: UIColorPanelViewController.updateProfileMenus manifest=reimpl/slider_profile_extras.json
- (void)updateProfileMenus {
    if(!self.isViewLoaded)return;
    UIColorPanelColorProfile *profile=self.activeColorProfile;self.optionsMenuButton.accessibilityValue=profile.displayName;
    self.optionsMenuButton.hidden=self.sliderIndex!=1&&[self profilesForMode:self.mode].count==0;
    if(@available(iOS 13.0,*)){[(UIColorPanelMenuButton *)self.modelMenuButton reloadMenu];[(UIColorPanelMenuButton *)self.optionsMenuButton reloadMenu];}
}
// BINMAP-ADAPT: UIColorPanelViewController.viewWillAppear: manifest=reimpl/slider_profile_extras.json
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshColorProfiles];
    [self refreshFavorites];
}
// BINMAP-ADAPT: UIColorPanelViewController.refreshFavorites manifest=reimpl/favorites_controller_refresh_extras.json
- (void)refreshFavorites {
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(self.swatchesView && _favoritesUseSPI != self.configuration.use_spi)
        [self configureFavoritesStore];
#endif
    [self.swatchesView refreshFavorites];
}
// BINMAP-ADAPT: UIColorPanelViewController.configureFavoritesStore manifest=reimpl/favorites_sharing_api_manifest.json
- (void)configureFavoritesStore {
    UIColorPickerFavoritesStore *store = self.configuration.favoritesStore;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    _favoritesUseSPI = self.configuration.use_spi;
    if (@available(iOS 14.0, *)) {
        if (!store && _favoritesUseSPI)
            store = [UIColorPickerFavoritesStore systemPickerStoreIfAccessible];
    }
#endif
    if (!store) {
        NSString *key = self.configuration.savedColorsKey;
        store = [[UIColorPickerFavoritesStore alloc] initWithKey:key.length ? key : UIColorPanelLocalFavoritesKey];
    }
    self.swatchesView.favoritesStore = store;
}
// BINMAP-ADAPT: UIColorPanelViewController.makeLabel:
- (UILabel *)makeLabel:(NSString *)text {
    UILabel *label=[UILabel new];label.text=[UIColorPanelAppearance localizedString:text];label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];label.adjustsFontForContentSizeCategory=YES;label.numberOfLines=0;if(!self.ownedLabels)self.ownedLabels=[NSHashTable weakObjectsHashTable];[self.ownedLabels addObject:label];return label;
}
// BINMAP-ADAPT: UIColorPanelViewController.makeRow:control:
- (UIStackView *)makeRow:(NSString *)title control:(UIView *)control {
    UILabel *label=[self makeComponentLabel:title];
    UIStackView *row=[[UIStackView alloc]initWithArrangedSubviews:@[label,control]];row.axis=UILayoutConstraintAxisVertical;row.spacing=5;row.alignment=UIStackViewAlignmentFill;row.layoutMarginsRelativeArrangement=YES;row.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(0,12,0,12);
    return row;
}
// BINMAP-ADAPT: UIColorPanelViewController.makeComponentLabel: manifest=reimpl/touch_panel_extras.json
- (UILabel *)makeComponentLabel:(NSString *)title {
    UILabel *label=[self makeLabel:title];label.isAccessibilityElement=NO;label.text=[label.text uppercaseStringWithLocale:NSLocale.currentLocale];
    UIFontDescriptor *font=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote compatibleWithTraitCollection:self.traitCollection];font=[font fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightSemibold)}}];label.font=[UIFont fontWithDescriptor:font size:0];
    if(@available(iOS 13.0,*))label.textColor=UIColor.secondaryLabelColor;else label.textColor=[UIColor colorWithRed:60/255.0 green:60/255.0 blue:67/255.0 alpha:.6];
    if(!self.componentLabels)self.componentLabels=[NSHashTable weakObjectsHashTable];[self.componentLabels addObject:label];return label;
}
// BINMAP-ADAPT: UIColorPanelViewController.makeSlider:action:
- (UIGradientSlider *)makeSlider:(NSString *)title action:(SEL)action {UIGradientSlider *slider=[UIGradientSlider new];slider.accessibilityLabel=[UIColorPanelAppearance localizedString:title];[slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];[slider addTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventEditingDidBegin];[slider addTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventEditingDidEnd];[slider.heightAnchor constraintEqualToConstant:36].active=YES;return slider;}
// BINMAP-ADAPT: UIColorPanelViewController.makeField:tag:
- (UITextField *)makeField:(NSString *)title tag:(NSInteger)tag {
    UIColorPanelNumericField *container=[[UIColorPanelNumericField alloc]initWithWidth:tag==20?100:76 hex:tag==20];container.semanticContentAttribute=UISemanticContentAttributeForceLeftToRight;
    if(!self.fieldContainers)self.fieldContainers=[NSMutableDictionary new];self.fieldContainers[@(tag)]=container;
    UITextField *field=container.textField;container.textField.selectionOwner=self;field.keyboardType=self.sliderIndex==1&&tag!=10?UIKeyboardTypeNumbersAndPunctuation:UIKeyboardTypeDecimalPad;field.returnKeyType=UIReturnKeyDone;field.delegate=self;field.accessibilityLabel=[UIColorPanelAppearance localizedString:title];field.semanticContentAttribute=UISemanticContentAttributeForceLeftToRight;field.tag=tag;
    // BINMAP-ADAPT: CPTextField presentation (0x100019610); production owns drafts and commits.
    field.autocorrectionType=UITextAutocorrectionTypeNo;
    if(field.keyboardType==UIKeyboardTypeDecimalPad&&UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPhone){
        UIToolbar *toolbar=[UIToolbar new];UIBarButtonItem *done=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(numericKeyboardDone:)];done.tag=tag;
        toolbar.items=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],done];[toolbar sizeToFit];field.inputAccessoryView=toolbar;toolbar.tintColor=field.tintColor;
    }
    if(tag!=10){NSLayoutConstraint *width=[container.widthAnchor constraintEqualToConstant:tag==20?100:76];width.identifier=@"ui.numeric.width";width.priority=999;width.active=YES;}
    NSLayoutConstraint *height=[container.heightAnchor constraintGreaterThanOrEqualToConstant:44];height.identifier=@"ui.numeric.height";height.active=YES;
    [container addTarget:field action:@selector(becomeFirstResponder) forControlEvents:UIControlEventTouchUpInside];
    [field addTarget:self action:@selector(textEdited:) forControlEvents:UIControlEventEditingChanged];return field;
}
// BINMAP-ADAPT: UIColorPanelViewController.viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];self.title=self.title?:[UIColorPanelAppearance localizedString:@"Colors"];
    if(@available(iOS 13.0,*))self.view.backgroundColor=UIColor.secondarySystemBackgroundColor;else self.view.backgroundColor=[UIColor colorWithWhite:.95 alpha:1];
    UIBarButtonItem *done=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.savedColorsItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(showSavedColors:)];self.savedColorsItem.accessibilityIdentifier=@"ui.saved.colors.manage";
    self.navigationItem.rightBarButtonItems=@[done,self.savedColorsItem];
    _overflowScroll=[UIScrollView new];_overflowScroll.showsHorizontalScrollIndicator=NO;_overflowScroll.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;_overflowScroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;[self.view addSubview:_overflowScroll];
    _rootStack=[UIView new];[_overflowScroll addSubview:_rootStack];self.transientPresentations=[NSHashTable weakObjectsHashTable];
    _modeControl=[[UIColorPanelModeControl alloc]initWithItems:@[]];_modeControl.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Color picker mode"];_modeControl.accessibilityIdentifier=@"ui.mode.control";
    __weak typeof(self) keyboardOwner=self;
    ((UIColorPanelModeControl *)_modeControl).keyboardFocusNavigationHandler=^BOOL(BOOL backwards){
        UIColorPanelViewController *owner=keyboardOwner;if(!owner)return NO;
#if UICOLORPANEL_ENABLE_PENCILS
        if(!backwards&&owner.mode==UIColorPanelModePencils)return[owner.pencilsPicker.pencilView becomeFirstResponder];
#endif
        if(!backwards&&owner.componentFields.count)return[owner.componentFields.firstObject becomeFirstResponder];
        if(owner.supportsAlpha&&owner.showsAlpha&&owner.opacityField.enabled)return[owner.opacityField becomeFirstResponder];
        return NO;
    };
    [_modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];[_rootStack addSubview:_modeControl];
    _providerHost=[UIView new];_providerHost.clipsToBounds=YES;[_rootStack addSubview:_providerHost];
    _scroll=[UIScrollView new];_scroll.alwaysBounceVertical=NO;_scroll.showsHorizontalScrollIndicator=NO;_scroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    _workspace=[UIStackView new];_workspace.axis=UILayoutConstraintAxisVertical;_workspace.spacing=7;
    _footer=[UIView new];_footer.backgroundColor=self.view.backgroundColor;[_rootStack addSubview:_footer];
    _opacitySlider=[self makeSlider:@"Opacity" action:@selector(opacityChanged:)];((UIGradientSlider *)_opacitySlider).showsOpacityBackground=YES;_opacityField=[self makeField:@"Opacity percent" tag:10];[_opacityField addTarget:self action:@selector(opacityEdited:) forControlEvents:UIControlEventEditingDidEnd];
    _opacityRow=[UIView new];_opacityRow.backgroundColor=self.view.backgroundColor;[_rootStack addSubview:_opacityRow];[_opacityRow addSubview:[self makeComponentLabel:@"Opacity"]];[_opacityRow addSubview:_opacitySlider];[_opacityRow addSubview:self.fieldContainers[@10]];_opacityRow.hidden=!(self.supportsAlpha&&self.showsAlpha);
    _currentWell=[[UIColorPickerColorPreview alloc]initWithFrame:CGRectZero];_currentWell.color=self.selectedColor;
    _currentWell.accessibilityCustomActions=@[[[UIAccessibilityCustomAction alloc]initWithName:[UIColorPanelAppearance localizedString:@"Manage Saved Colors"] target:self selector:@selector(accessibilityManageSavedColors:)]];
    [_currentWell addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showSavedColors:)]];
    _currentWell.accessibilityTraits=UIAccessibilityTraitButton;_currentWell.accessibilityHint=[UIColorPanelAppearance localizedString:@"Choose and manage saved colors"];
    _sampleButton=[UIButton buttonWithType:UIButtonTypeSystem];_sampleButton.frame=CGRectMake(0,0,44,44);[_sampleButton setImage:[UIColorPanelAppearance imageForSymbol:@"eyedropper" size:22] forState:UIControlStateNormal];_sampleButton.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Application image sampling"];_sampleButton.accessibilityHint=[UIColorPanelAppearance localizedString:@"Samples only the supplied image or application view."];
    [_sampleButton addTarget:self action:@selector(samplePressed:event:) forControlEvents:UIControlEventTouchDown];[_sampleButton addTarget:self action:@selector(sampleDragged:event:) forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragOutside];[_sampleButton addTarget:self action:@selector(sampleReleased:event:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    _savedColorsButton=[UIButton buttonWithType:UIButtonTypeSystem];_savedColorsButton.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];_savedColorsButton.titleLabel.adjustsFontForContentSizeCategory=YES;_savedColorsButton.titleLabel.numberOfLines=0;_savedColorsButton.titleLabel.lineBreakMode=NSLineBreakByWordWrapping;_savedColorsButton.accessibilityIdentifier=@"ui.saved.colors";[_savedColorsButton addTarget:self action:@selector(showSavedColors:) forControlEvents:UIControlEventTouchUpInside];[_footer addSubview:_savedColorsButton];
    self.swatchesView=[[UIColorPickerSwatchesView alloc]initWithFrame:CGRectZero];self.swatchesView.supportsAlpha=self.supportsAlpha;self.swatchesView.currentColor=self.selectedColor;
    self.swatchesView.usesNativeDefaultColors=YES;
    [self configureFavoritesStore];
    self.swatchesView.delegate=self;self.swatchesView.currentColorSourceView=_currentWell;self.swatchesView.usesNativePickerPresentation=YES;
    __weak typeof(self) favoritesOwner=self;
    self.swatchesView.managementHandler=^{
        id focused=UIAccessibilityFocusedElement(UIAccessibilityNotificationVoiceOverIdentifier);
        [favoritesOwner showSavedColors:focused];
    };
    self.savedColorsButton.hidden=YES;
    self.favoritesRow=[[UIStackView alloc]initWithArrangedSubviews:@[_currentWell,self.swatchesView]];self.favoritesRow.spacing=24;self.favoritesRow.alignment=UIStackViewAlignmentTop;self.favoritesRow.translatesAutoresizingMaskIntoConstraints=NO;[_footer addSubview:self.favoritesRow];
    self.footerDivider=[UIView new];self.footerDivider.translatesAutoresizingMaskIntoConstraints=NO;[_footer addSubview:self.footerDivider];
    if(@available(iOS 13.0,*))self.footerDivider.backgroundColor=UIColor.separatorColor;else self.footerDivider.backgroundColor=[UIColor colorWithWhite:.75 alpha:1];
    self.nativeFavoritesHeight=[self.swatchesView.heightAnchor constraintEqualToConstant:88];
    [NSLayoutConstraint activateConstraints:@[[self.footerDivider.leadingAnchor constraintEqualToAnchor:_footer.leadingAnchor constant:12],[self.footerDivider.trailingAnchor constraintEqualToAnchor:_footer.trailingAnchor constant:-12],[self.footerDivider.topAnchor constraintEqualToAnchor:_footer.topAnchor constant:4],[self.footerDivider.heightAnchor constraintEqualToConstant:1/UIScreen.mainScreen.scale],[self.favoritesRow.leadingAnchor constraintEqualToAnchor:_footer.leadingAnchor constant:12],[self.favoritesRow.trailingAnchor constraintEqualToAnchor:_footer.trailingAnchor constant:-12],[self.favoritesRow.topAnchor constraintEqualToAnchor:self.footerDivider.bottomAnchor constant:16],[self.favoritesRow.bottomAnchor constraintEqualToAnchor:_footer.bottomAnchor constant:-8],[_currentWell.widthAnchor constraintEqualToConstant:64],[_currentWell.heightAnchor constraintEqualToConstant:64],self.nativeFavoritesHeight]];
    [self updateFavoritesSummary];
    if(self.hostAccessoryView)[_rootStack addSubview:self.hostAccessoryView];
    NSMutableArray *palettes=[NSMutableArray array];NSString *path=[[UIColorPanelAppearance resourceBundle]pathForResource:@"UIBuiltInPalettes" ofType:@"json"]?:[[NSBundle bundleForClass:self.class]pathForResource:@"UIBuiltInPalettes" ofType:@"json"]?:[NSBundle.mainBundle pathForResource:@"UIBuiltInPalettes" ofType:@"json"];
    NSDictionary *data=path?[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:0 error:NULL]:nil;
    for(NSDictionary *palette in data[@"palettes"]){NSMutableArray *colors=[NSMutableArray array],*names=[NSMutableArray array];
        for(NSDictionary *entry in palette[@"colors"]){NSArray *components=entry[@"cgComponents"]?:entry[@"components"];CGFloat rgba[4];for(int i=0;i<4;i++)rgba[i]=[components[i]doubleValue];
            CGColorSpaceRef space=CGColorSpaceCreateWithName(entry[@"cgSpaceName"]?(__bridge CFStringRef)entry[@"cgSpaceName"]:([palette[@"name"]isEqual:@"Web Safe Colors"]?kCGColorSpaceGenericRGB:kCGColorSpaceSRGB));
            if(!space)space=CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
            CGColorRef cg=CGColorCreate(space,rgba);[colors addObject:[[UIColorValue alloc]initWithCGColor:cg]];[names addObject:entry[@"name"]];CGColorRelease(cg);CGColorSpaceRelease(space);}
        [palettes addObject:[[UIColorPalette alloc]initWithName:palette[@"name"] colors:colors names:names]];}
    [palettes addObjectsFromArray:self.configuration.palettes];_palettes=palettes;
    NSMutableArray<UIColorList *> *lists=[UIColorList.availableColorLists mutableCopy];
    for(UIColorPalette *palette in self.configuration.palettes){UIColorList *list=[[UIColorList alloc]initWithName:palette.name];for(NSUInteger i=0;i<palette.colors.count;i++)[list setColorValue:palette.colors[i] forKey:palette.names[i]];[lists addObject:list];}
    self.catalogController=[[UIColorPickerCatalogController alloc]initWithColorLists:lists selectedColor:self.selectedColor];self.catalogController.delegate=self;
    for(UIColorList *list in self.attachedColorLists.allValues)[self.catalogController attachColorList:list];
    [self addChildViewController:self.catalogController];[self.catalogController didMoveToParentViewController:self];
    self.paletteImage=[UIColorPickerImagePaletteController defaultSpectrumImage];
    self.imagePaletteController=[[UIColorPickerImagePaletteController alloc]initWithSpectrum:self.paletteImage];self.imagePaletteController.delegate=self;
    [self addChildViewController:self.imagePaletteController];[self.imagePaletteController didMoveToParentViewController:self];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationDeactivated:) name:UIApplicationWillResignActiveNotification object:nil];
    if(@available(iOS 13.0,*))[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationDeactivated:) name:UISceneWillDeactivateNotification object:nil];
    [self buildMode];[self updateControls];
}
// BINMAP-ADAPT: UIColorPanelViewController.viewDidLayoutSubviews
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect usable=UIEdgeInsetsInsetRect(self.view.bounds,self.view.safeAreaInsets);
    if(!CGRectIsNull(_keyboardFrame)){
        CGRect overlap=CGRectIntersection(usable,_keyboardFrame);
        if(!CGRectIsNull(overlap)&&overlap.size.width>=usable.size.width*.8&&CGRectGetMaxY(overlap)>=CGRectGetMaxY(usable)-1)usable.size.height=MAX(0,CGRectGetMinY(overlap)-usable.origin.y);
    }
    // Public controls remain in native points. Only the pencil artwork has a local fit transform.
    self.overflowScroll.frame=usable;self.rootStack.transform=CGAffineTransformIdentity;
    CGFloat width=usable.size.width,height=usable.size.height,margin=12;
    BOOL rtl=self.view.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft;
    UISemanticContentAttribute direction=rtl?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;
    self.modeControl.semanticContentAttribute=direction;self.modelMenuButton.semanticContentAttribute=direction;self.optionsMenuButton.semanticContentAttribute=direction;self.modelMenuButton.superview.semanticContentAttribute=direction;
    for(UIViewController *provider in @[self.catalogController,self.imagePaletteController])if(provider.isViewLoaded&&provider.view.semanticContentAttribute!=direction){provider.view.semanticContentAttribute=direction;[provider.view setNeedsLayout];}
    CGRect (^logicalFrame)(CGFloat,CGFloat,CGFloat,CGFloat)=^CGRect(CGFloat x,CGFloat y,CGFloat w,CGFloat h){return CGRectMake(rtl?width-x-w:x,y,MAX(0,w),MAX(0,h));};
    self.modeControl.frame=CGRectMake(margin,4,MAX(0,width-2*margin),44);
    BOOL requestsScreenSampler=UICOLORPANEL_ENABLE_PRIVATE_API&&self.configuration.use_spi;
    BOOL systemSampler=requestsScreenSampler&&[UIEyedropperViewController supportsSystemCapture];
    BOOL sampler=requestsScreenSampler?systemSampler:(self.configuration.allowsApplicationSampling&&(self.configuration.samplingImage||self.configuration.samplingSourceView));
    self.sampleButton.accessibilityLabel=[UIColorPanelAppearance localizedString:systemSampler?@"Screen color sampling":@"Application image sampling"];
    self.sampleButton.accessibilityHint=[UIColorPanelAppearance localizedString:systemSampler?@"Samples the live system display.":@"Samples only the supplied image or application view."];
    self.sampleButton.hidden=!sampler;
    BOOL large=UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory);
    if(sampler){if(self.navigationItem.leftBarButtonItem.customView!=self.sampleButton)self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:self.sampleButton];}else self.navigationItem.leftBarButtonItem=nil;
    CGFloat footerHeight=117;
    UILabel *opacityLabel=(UILabel *)self.opacityRow.subviews.firstObject;
    CGFloat labelHeight=ceil([opacityLabel sizeThatFits:CGSizeMake(MAX(1,width-2*margin),CGFLOAT_MAX)].height);
    CGFloat fieldHeight=44;
    CGFloat alphaHeight=self.supportsAlpha&&self.showsAlpha?labelHeight+fieldHeight+14:0;
    CGFloat bodyTop=52;
    if(self.hostAccessoryView){CGFloat h=[self.hostAccessoryView systemLayoutSizeFittingSize:CGSizeMake(width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;if(h<=0)h=CGRectGetHeight(self.hostAccessoryView.bounds);self.hostAccessoryView.frame=CGRectMake(0,bodyTop,width,h);bodyTop+=h;}
    CGFloat providerMinimumHeight=120;
    if(self.mode==UIColorPanelModePalettes){
        CGSize fitting=[self.catalogController.view systemLayoutSizeFittingSize:CGSizeMake(width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        providerMinimumHeight=MAX(providerMinimumHeight,ceil(fitting.height));
    }else if(self.mode==UIColorPanelModePencils){
        CGFloat nameHeight=MAX(24,ceil([self.pencilNameLabel sizeThatFits:CGSizeMake(MAX(0,width-2*margin),CGFLOAT_MAX)].height));
        CGFloat minimumScale=MIN(1,MAX(0,width-2*margin)/228);
        CGFloat switchHeight=0;
        if(self.discreteModeControl){
            switchHeight=[self.discreteModeControl.superview systemLayoutSizeFittingSize:CGSizeMake(width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height+self.workspace.spacing;
        }
        // Preserve the original artwork's usable size; the common shell scrolls
        // when a short host cannot fit the name, artwork and shared footer.
        providerMinimumHeight=MAX(providerMinimumHeight,ceil(switchHeight+4+nameHeight+8+214*minimumScale+8));
    }
    height=MAX(height,bodyTop+providerMinimumHeight+alphaHeight+footerHeight);
    self.rootStack.frame=CGRectMake(0,0,width,height);self.overflowScroll.contentSize=CGSizeMake(width,height);
    self.overflowScroll.scrollEnabled=height>usable.size.height;
    if(!self.overflowScroll.scrollEnabled)self.overflowScroll.contentOffset=CGPointZero;
    CGFloat footerTop=height-footerHeight;
    self.footer.frame=CGRectMake(0,footerTop,width,footerHeight);
    self.favoritesRow.semanticContentAttribute=direction;
    // BINMAP-ADAPT: 0x100039D30 sets useLandscapeLayout from the host frame;
    // 0x100031850 selects 60/76, independently of the text and keyboard.
    CGSize hostSize=self.view.frame.size;
    CGFloat fieldWidth=hostSize.width>hostSize.height&&hostSize.width>450?60:76;
    self.swatchesView.nativeLandscapeLayout=fieldWidth==60;
    self.opacityRow.frame=CGRectMake(0,footerTop-alphaHeight,width,alphaHeight);
    opacityLabel.frame=logicalFrame(margin,2,width-2*margin,labelHeight);
    self.fieldContainers[@10].frame=logicalFrame(width-margin-fieldWidth,labelHeight+6,fieldWidth,fieldHeight);
    self.opacitySlider.frame=logicalFrame(margin,labelHeight+6+(fieldHeight-36)/2,MAX(0,width-2*margin-fieldWidth-16),36);
    self.providerHost.frame=CGRectMake(0,bodyTop,width,MAX(0,CGRectGetMinY(self.opacityRow.frame)-bodyTop));
    BOOL numeric=self.mode>=UIColorPanelModeGray&&self.mode<=UIColorPanelModeHSB;
    if(numeric){
        CGFloat available=MAX(0,width-24);
        for(UITextField *field in [self.componentFields arrayByAddingObjectsFromArray:self.hexField?@[self.hexField]:@[]]){
            UIColorPanelNumericField *container=self.fieldContainers[@(field.tag)];
            // RGBA Hex uses its own 100-point CPTextField frame (0x10001AF10).
            CGFloat w=field==self.hexField?100:fieldWidth;
            BOOL vertical=large||available<w+120;
            for(NSLayoutConstraint *c in container.constraints)if([c.identifier isEqual:@"ui.numeric.width"]){c.constant=MIN(w,available);}
            if([container.superview isKindOfClass:UIStackView.class]&&field!=self.hexField){UIStackView *values=(UIStackView *)container.superview;values.semanticContentAttribute=direction;values.axis=vertical?UILayoutConstraintAxisVertical:UILayoutConstraintAxisHorizontal;values.alignment=vertical?UIStackViewAlignmentTrailing:UIStackViewAlignmentCenter;
                self.componentFullWidths[field.tag].active=vertical;
            }
            if(field==self.hexField&&[container.superview isKindOfClass:UIStackView.class]){UIStackView *row=(UIStackView *)container.superview;row.semanticContentAttribute=direction;UILabel *label=(UILabel *)row.arrangedSubviews[1];BOOL stacked=large||available<w+[label sizeThatFits:CGSizeMake(CGFLOAT_MAX,CGFLOAT_MAX)].width+16;row.axis=stacked?UILayoutConstraintAxisVertical:UILayoutConstraintAxisHorizontal;row.alignment=stacked?UIStackViewAlignmentTrailing:UIStackViewAlignmentCenter;row.arrangedSubviews.firstObject.hidden=stacked;label.numberOfLines=0;}
        }
        self.scroll.frame=self.providerHost.bounds;
        CGSize fitting=[self.workspace systemLayoutSizeFittingSize:CGSizeMake(width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        self.workspace.frame=CGRectMake(0,0,width,MAX(fitting.height,self.providerHost.bounds.size.height));self.scroll.contentSize=self.workspace.bounds.size;self.scroll.scrollEnabled=fitting.height>self.scroll.bounds.size.height;
        for(UITextField *field in self.componentFields)if(field.isFirstResponder)[self.scroll scrollRectToVisible:[field convertRect:field.bounds toView:self.workspace] animated:NO];
        if(self.hexField.isFirstResponder)[self.scroll scrollRectToVisible:[self.hexField convertRect:self.hexField.bounds toView:self.workspace] animated:NO];
    }else self.workspace.frame=self.providerHost.bounds;
    if(self.mode==UIColorPanelModeCustomPalette&&self.imageHeaderHeight){self.imageHeaderHeight.active=NO;CGFloat h=[self.imagePaletteController.view systemLayoutSizeFittingSize:CGSizeMake(width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;self.imageHeaderHeight.constant=MAX(44,h);self.imageHeaderHeight.active=YES;}
    [self.workspace layoutIfNeeded];
#if UICOLORPANEL_ENABLE_PENCILS
    if(self.mode==UIColorPanelModePencils){UIView *host=self.pencilContainer.superview;CGFloat nameHeight=ceil([self.pencilNameLabel sizeThatFits:CGSizeMake(MAX(0,width-24),CGFLOAT_MAX)].height);self.pencilNameLabel.frame=CGRectMake(12,4,MAX(0,width-24),MAX(24,nameHeight));CGFloat top=CGRectGetMaxY(self.pencilNameLabel.frame)+8,room=MAX(0,host.bounds.size.height-top-8),scale=MAX(.01,MIN(1.8,MIN(MAX(0,width-24)/228,room/214)));self.pencilContainer.transform=CGAffineTransformIdentity;self.pencilContainer.bounds=CGRectMake(0,0,228,214);self.pencilContainer.center=CGPointMake(width/2,top+room/2);self.pencilContainer.transform=CGAffineTransformMakeScale(scale,scale);}
#endif
    UIView *editor=nil;NSMutableArray *views=[NSMutableArray arrayWithObject:self.rootStack];
    while(views.count){UIView *candidate=views.lastObject;[views removeLastObject];if(candidate.isFirstResponder){editor=candidate;break;}[views addObjectsFromArray:candidate.subviews];}
    CGRect keyboardOverlap=CGRectIsNull(_keyboardFrame)?CGRectNull:CGRectIntersection(usable,_keyboardFrame);
    BOOL floating=editor&&!CGRectIsNull(keyboardOverlap)&&keyboardOverlap.size.width<usable.size.width*.8;
    self.overflowScroll.contentInset=UIEdgeInsetsMake(0,0,floating?keyboardOverlap.size.height:0,0);
    self.overflowScroll.scrollEnabled=height>usable.size.height||floating;
    if(editor){
        CGRect content=[editor convertRect:editor.bounds toView:self.rootStack];
        [self.overflowScroll scrollRectToVisible:CGRectInset(content,-4,-8) animated:NO];
        CGRect visible=[editor convertRect:editor.bounds toView:self.view];
        if(floating&&CGRectIntersectsRect(visible,_keyboardFrame)){
            CGFloat delta=CGRectGetMaxY(visible)-CGRectGetMinY(_keyboardFrame)+8;
            CGFloat limit=MAX(0,height-usable.size.height+self.overflowScroll.contentInset.bottom);
            [self.overflowScroll setContentOffset:CGPointMake(0,MIN(limit,MAX(0,self.overflowScroll.contentOffset.y+delta))) animated:NO];
        }
    }

}
// BINMAP-ADAPT: UIColorPanelViewController.keyboardChanged:
- (void)keyboardChanged:(NSNotification *)notification {
    [self.view layoutIfNeeded];
    _keyboardFrame=self.view.window?[self.view convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey]CGRectValue] fromCoordinateSpace:self.view.window.screen.coordinateSpace]:CGRectNull;
    [self.view setNeedsLayout];NSTimeInterval duration=[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]doubleValue];
    if(duration>0){UIViewAnimationOptions curve=(UIViewAnimationOptions)([notification.userInfo[UIKeyboardAnimationCurveUserInfoKey]unsignedIntegerValue]<<16);[UIView animateWithDuration:duration delay:0 options:curve|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{[self.view layoutIfNeeded];} completion:nil];}
    else [self.view layoutIfNeeded];
}
// BINMAP-ADAPT: UIColorPanelViewController.setMode:
- (void)setMode:(UIColorPanelMode)mode {
#if !UICOLORPANEL_ENABLE_PENCILS
    if (mode == UIColorPanelModePencils) mode = UIColorPanelModeGrid;
#endif
    if(mode<UIColorPanelModeGray||mode>UIColorPanelModeGrid)return;
    if(!(self.pickerMask & (1UL<<mode)))return;
    UIColorPanelMode previousMode=_mode;NSUInteger generation=self.transientGeneration;
    [self cancelControlTrackingInView:self.workspace];
    if(self.transientGeneration!=generation||_mode!=previousMode||!(self.pickerMask&(1UL<<mode)))return;
    if(mode==UIColorPanelModeColorList && self.isViewLoaded && !self.catalogController.isViewLoaded)[self.catalogController loadViewIfNeeded];
    BOOL changed=mode!=_mode;if(changed)++self.profileGeneration;_mode=mode;if(mode<=UIColorPanelModeHSB){self.sliderIndex=mode;
        CGColorSpaceRef source=CGColorGetColorSpace(self.selectedColor.CGColor);CGColorSpaceModel model=mode==UIColorPanelModeGray?kCGColorSpaceModelMonochrome:mode==UIColorPanelModeCMYK?kCGColorSpaceModelCMYK:kCGColorSpaceModelRGB;
        if(changed&&CGColorSpaceGetModel(source)==model)self.workingProfiles[@(mode)]=[[UIColorPanelColorProfile alloc]initWithColorSpace:source displayName:nil];
        [self profileForMode:mode];
    }
    if(mode==UIColorPanelModePencils||mode==UIColorPanelModeGrid)self.discreteMode=mode;
    if(self.isViewLoaded){[self buildMode];[self updateControls];}
}
// BINMAP-ADAPT: UIColorPanelViewController.setPickerMask: — UIKit mode availability is configured before provider construction.
- (void)setPickerMask:(UIColorPanelOptions)pickerMask {
#if !UICOLORPANEL_ENABLE_PENCILS
    if (pickerMask & UIColorPanelCrayonModeMask)
        pickerMask = (pickerMask & ~UIColorPanelCrayonModeMask) | UIColorPanelGridModeMask;
#endif
    _pickerMask=pickerMask;++self.profileGeneration;
    if(_mode<0 || !(pickerMask&(1UL<<_mode))){
        UIColorPanelMode nextMode=UIColorPanelModeNone;for(NSInteger mode=0;mode<=UIColorPanelModeGrid;mode++)if(pickerMask&(1UL<<mode)){nextMode=mode;break;}
        if(nextMode!=UIColorPanelModeNone){self.mode=nextMode;return;}
        _mode=UIColorPanelModeNone;
    }
    if(self.isViewLoaded){[self buildMode];[self updateControls];}
}
// BINMAP-ADAPT: UIColorPanelViewController.showsAlpha — embedded configuration and shared-panel views use the same opacity row.
- (BOOL)showsAlpha { return self.configuration.showsAlpha; }
// BINMAP-ADAPT: UIColorPanelViewController.setShowsAlpha: — UIKit visibility update without a second color model.
- (void)setShowsAlpha:(BOOL)showsAlpha { self.configuration.showsAlpha=showsAlpha;[self setSupportsAlpha:self.supportsAlpha]; }
// BINMAP-ADAPT: UIColorPanelViewController.supportsAlpha manifest=reimpl/native_favorites_chrome_api_manifest.json
- (BOOL)supportsAlpha {return self.configuration.supportsAlpha;}
// BINMAP-ADAPT: UIColorPanelViewController.setSupportsAlpha: manifest=reimpl/native_favorites_chrome_api_manifest.json
- (void)setSupportsAlpha:(BOOL)supportsAlpha {
    self.configuration.supportsAlpha=supportsAlpha;
    if(!self.isViewLoaded)return;
    if(!(self.supportsAlpha&&self.showsAlpha)){
        [self.editedFields removeObject:self.opacityField];
        if(self.invalidField==self.opacityField){
            self.invalidField=nil;UIAlertController *alert=self.inputErrorAlert;self.inputErrorAlert=nil;
            if(alert){[self.transientPresentations removeObject:alert];[alert dismissViewControllerAnimated:NO completion:nil];}
        }
        [self.opacityField resignFirstResponder];
        [self cancelControlTrackingInView:self.opacityRow];
    }
    self.swatchesView.supportsAlpha=self.supportsAlpha;
    self.opacityRow.hidden=!(self.supportsAlpha&&self.showsAlpha);
    [self updateControls];[self.viewIfLoaded setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelViewController.alphaEditingEnabled — expose native opacity capability to the shared panel.
- (BOOL)alphaEditingEnabled { return self.opacitySlider.enabled; }
// BINMAP-ADAPT: UIColorPanelViewController.setAlphaEditingEnabled: — keep opacity text and slider enabled together.
- (void)setAlphaEditingEnabled:(BOOL)enabled { self.opacitySlider.enabled=enabled;self.opacityField.enabled=enabled; }
// BINMAP-ADAPT: UIColorPanelViewController.accessoryView — retain caller-owned view identity.
- (UIView *)accessoryView { return self.hostAccessoryView; }
// BINMAP-ADAPT: UIColorPanelViewController.setAccessoryView: — UIKit stack layout hosts the public AppKit-style accessory surface.
- (void)setAccessoryView:(UIView *)view { if(view==self.hostAccessoryView)return;[self.hostAccessoryView removeFromSuperview];self.hostAccessoryView=view;if(view&&self.isViewLoaded)[self.rootStack addSubview:view];[self.view setNeedsLayout]; }
// BINMAP-ADAPT: UIColorPanelViewController.trackingBegan: — aggregate distinct UIKit controls before their first value mutation.
- (void)trackingBegan:(UIControl *)sender {
    if(self.endingTransientInteractions||[self.activeEditingControls containsObject:sender])return;
    if(!self.activeEditingControls)self.activeEditingControls=[NSMutableSet new];
    BOOL first=self.activeEditingControls.count==0;[self.activeEditingControls addObject:sender];
    if(first&&[self.delegate respondsToSelector:@selector(colorPanelWillBeginEditing:)])[self.delegate colorPanelWillBeginEditing:self];
}
// BINMAP-ADAPT: UIColorPanelViewController.trackingEnded: — only the final active control ends the shared continuous edit.
- (void)trackingEnded:(UIControl *)sender {
    if(![self.activeEditingControls containsObject:sender])return;
    [self.activeEditingControls removeObject:sender];
    if(self.activeEditingControls.count==0&&[self.delegate respondsToSelector:@selector(colorPanelDidEndEditing:)])[self.delegate colorPanelDidEndEditing:self];
}
// BINMAP-ADAPT: UIColorPanelViewController.cancelControlTrackingInView: manifest=reimpl/ui_ux_repairs_extras.json
- (void)cancelControlTrackingInView:(UIView *)view {
    // A mode rebuild leaves the persistent opacity control in place. A nil
    // subtree ends every owned edit when the panel closes, including detached controls.
    for(UIControl *control in self.activeEditingControls.allObjects)if([self.activeEditingControls containsObject:control]&&(!view||[control isDescendantOfView:view])){
        [control cancelTrackingWithEvent:nil];
        // UIControl subclasses differ in whether their cancellation hook emits
        // a target/action end event. End this identity once in either case.
        [self trackingEnded:control];
    }
}
// BINMAP-ADAPT: UIColorPanelViewController.modeChanged:
- (void)modeChanged:(UISegmentedControl *)sender {
    NSInteger index=sender.selectedSegmentIndex;if(index<0||index>=(NSInteger)self.modeSegmentModes.count)return;
    UIColorPanelMode mode=self.modeSegmentModes[index].integerValue;
    if(![self commitPendingEdits]){[self updateControls];return;}if(!sender.isFirstResponder)[self.view endEditing:YES];_sampling=NO;self.sampleOriginalColor=nil;
    if(mode==UIColorPanelModeRGB){mode=self.sliderIndex;if(!(self.pickerMask&(1UL<<mode)))for(NSInteger candidate=0;candidate<=3;candidate++)if(self.pickerMask&(1UL<<candidate)){mode=candidate;break;}}
    if(mode==UIColorPanelModePencils){mode=self.discreteMode;if(!(self.pickerMask&(1UL<<mode)))mode=(self.pickerMask&UIColorPanelCrayonModeMask)?UIColorPanelModePencils:UIColorPanelModeGrid;}
    self.mode=mode;
}
// BINMAP-ADAPT: UIColorPanelViewController.discreteModeChanged: manifest=reimpl/discrete_spectrum_host_api_manifest.json
- (void)discreteModeChanged:(UISegmentedControl *)sender {
    UIColorPanelMode mode=sender.selectedSegmentIndex==1?UIColorPanelModeGrid:UIColorPanelModePencils;
    if(![self commitPendingEdits]){sender.selectedSegmentIndex=self.mode==UIColorPanelModeGrid?1:0;return;}
    [self.view endEditing:YES];self.mode=mode;
}
// BINMAP-ADAPT: UIColorPanelViewController.buildMode
- (void)buildMode {
    [self cancelControlTrackingInView:self.workspace];
    self.imageHeaderHeight.active=NO;self.imageHeaderHeight=nil;
    for(UIView *v in self.workspace.arrangedSubviews){[self.workspace removeArrangedSubview:v];[v removeFromSuperview];}
    [self.workspace removeFromSuperview];[self.scroll removeFromSuperview];
    for(NSNumber *tag in self.fieldContainers.allKeys)if(tag.integerValue!=10)[self.fieldContainers removeObjectForKey:tag];
    BOOL numeric=self.mode>=UIColorPanelModeGray&&self.mode<=UIColorPanelModeHSB;
    if(numeric){[self.providerHost addSubview:self.scroll];[self.scroll addSubview:self.workspace];}else[self.providerHost addSubview:self.workspace];
    self.workspace.layoutMargins=UIEdgeInsetsZero;self.workspace.layoutMarginsRelativeArrangement=YES;self.workspace.spacing=7;
    self.wheel=nil;self.brightnessSlider=nil;self.componentSliders=@[];self.componentFields=@[];self.grayShortcutButtons=@[];self.componentFullWidths=[NSMutableArray new];self.sliderModel=nil;self.spaces=nil;self.precision=nil;self.hexField=nil;self.hexLabel=nil;self.spaceLabel=nil;self.imageSampler=nil;self.selectionLabel=nil;self.modelMenuButton=nil;self.optionsMenuButton=nil;
    self.spectrum=nil;self.grid=nil;self.discreteModeControl=nil;
    UIColorPanelMode discreteToolbarMode = UICOLORPANEL_ENABLE_PENCILS ? UIColorPanelModePencils : UIColorPanelModeGrid;
    NSArray *toolbarModes=@[@(UIColorPanelModeWheel),@(UIColorPanelModeRGB),@(UIColorPanelModeColorList),@(UIColorPanelModeCustomPalette),@(discreteToolbarMode)];
    NSArray *modeNames=@[@"Color Wheel",@"Color Sliders",@"Color Palettes",@"Image Palette",UICOLORPANEL_ENABLE_PENCILS ? @"Pencils" : @"Grid"];
    NSMutableArray *visibleModes=[NSMutableArray new],*images=[NSMutableArray new];NSInteger selected=UISegmentedControlNoSegment;
    for(NSUInteger index=0;index<toolbarModes.count;index++){
        UIColorPanelMode mode=[toolbarModes[index]integerValue];BOOL enabled=mode==UIColorPanelModeRGB?(self.pickerMask&0xf)!=0:mode==UIColorPanelModePencils?(self.pickerMask&(UIColorPanelCrayonModeMask|UIColorPanelGridModeMask))!=0:(self.pickerMask&(1UL<<mode))!=0;if(!enabled)continue;
        UIImage *image=[UIColorPanelAppearance imageForSymbol:@[@"wheel",@"sliders",@"palette",@"image",UICOLORPANEL_ENABLE_PENCILS ? @"pencils" : @"grid"][index] size:25];image.accessibilityLabel=[UIColorPanelAppearance localizedString:modeNames[index]];
        [images addObject:image];
        if(mode==self.mode||(mode==UIColorPanelModeRGB&&numeric)||(mode==UIColorPanelModePencils&&self.mode==UIColorPanelModeGrid))selected=visibleModes.count;
        [visibleModes addObject:@(mode)];
    }
    if(![self.modeSegmentModes isEqualToArray:visibleModes]){[self.modeControl removeAllSegments];for(NSUInteger index=0;index<images.count;index++)[self.modeControl insertSegmentWithImage:images[index] atIndex:index animated:NO];}
    self.modeSegmentModes=visibleModes;self.modeControl.selectedSegmentIndex=selected;self.modeControl.hidden=visibleModes.count==0;
    if(self.mode==UIColorPanelModeNone){[self.workspace addArrangedSubview:[self makeLabel:@"No color picker is enabled."]];}
    else if(self.mode==UIColorPanelModeWheel){
        // Leave room for the33pt lens and shadow without shifting its color point.
        self.workspace.layoutMargins=UIEdgeInsetsMake(20,20,3,20);self.workspace.spacing=20;
        self.wheel=[[UIColorPickerWheelView alloc]initWithFrame:CGRectZero];[self.wheel addTarget:self action:@selector(wheelChanged:) forControlEvents:UIControlEventValueChanged];[self.wheel addTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventEditingDidBegin];[self.wheel addTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        UIView *container=[UIView new];[self.workspace addArrangedSubview:container];self.wheel.translatesAutoresizingMaskIntoConstraints=NO;[container addSubview:self.wheel];
        NSLayoutConstraint *width=[self.wheel.widthAnchor constraintEqualToAnchor:container.widthAnchor];width.priority=999;NSLayoutConstraint *height=[self.wheel.heightAnchor constraintEqualToAnchor:container.heightAnchor];height.priority=998;
        [NSLayoutConstraint activateConstraints:@[width,height,[self.wheel.widthAnchor constraintLessThanOrEqualToAnchor:container.widthAnchor],[self.wheel.heightAnchor constraintLessThanOrEqualToAnchor:container.heightAnchor],[self.wheel.heightAnchor constraintEqualToAnchor:self.wheel.widthAnchor],[self.wheel.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],[self.wheel.centerYAnchor constraintEqualToAnchor:container.centerYAnchor]]];
        self.brightnessSlider=[self makeSlider:@"Brightness" action:@selector(brightnessChanged:)];self.brightnessSlider.accessibilityValueReversed=YES;
        UIStackView *track=[[UIStackView alloc]initWithArrangedSubviews:@[self.brightnessSlider]];track.axis=UILayoutConstraintAxisVertical;track.layoutMarginsRelativeArrangement=YES;track.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(4,0,4,0);[self.workspace addArrangedSubview:track];
    }else if(numeric){
        self.workspace.layoutMargins=UIEdgeInsetsZero;self.workspace.spacing=16;
        self.sliderModel=[[UISegmentedControl alloc]initWithItems:@[@"Gray",@"RGB",@"CMYK",@"HSB"]];self.sliderModel.selectedSegmentIndex=self.sliderIndex;
        for(NSUInteger i=0;i<4;i++)[self.sliderModel setEnabled:(self.pickerMask&(1UL<<i))!=0 forSegmentAtIndex:i];
        self.spaces=[[UISegmentedControl alloc]initWithItems:@[@"sRGB",@"Display P3",@"Original"]];self.spaces.selectedSegmentIndex=self.spaceIndex;
        self.precision=[[UISegmentedControl alloc]initWithItems:@[@"8-bit",@"Float"]];self.precision.selectedSegmentIndex=self.precisionIndex;
        UIColorPanelMenuButton *model=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];[model setTitle:[UIColorPanelAppearance localizedString:@[@"Gray Sliders",@"RGB Sliders",@"CMYK Sliders",@"HSB Sliders"][self.sliderIndex]] forState:UIControlStateNormal];model.accessibilityIdentifier=@"ui.sliders.model";
        UIColorPanelMenuButton *options=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];options.displaysMoreActions=YES;options.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Slider options"];options.accessibilityIdentifier=@"ui.sliders.options";[options.widthAnchor constraintEqualToConstant:44].active=YES;
        self.modelMenuButton=model;self.optionsMenuButton=options;
        if(@available(iOS 13.0,*)){__weak typeof(self) weakSelf=self;model.menuProvider=^UIMenu *{return[weakSelf sliderModelMenu];};options.menuProvider=^UIMenu *{return[weakSelf sliderOptionsMenu];};[model reloadMenu];[options reloadMenu];}
        if(!model.usesPrimaryMenu)[model addTarget:self action:@selector(chooseSliderModel:) forControlEvents:UIControlEventTouchUpInside];
        if(!options.usesPrimaryMenu)[options addTarget:self action:@selector(chooseSliderOptions:) forControlEvents:UIControlEventTouchUpInside];
        UIStackView *header=[UIColorPanelMenuButton headerWithSelectionButton:model actionsButton:options];[header.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;[self.workspace addArrangedSubview:header];
        NSArray *labels=@[@[@"White"],@[@"Red",@"Green",@"Blue"],@[@"Cyan",@"Magenta",@"Yellow",@"Black"],@[@"Hue",@"Saturation",@"Brightness"]][self.sliderIndex];
        NSMutableArray *sliders=[NSMutableArray array],*fields=[NSMutableArray array];
        for(NSUInteger i=0;i<labels.count;i++){UIGradientSlider *slider=[self makeSlider:labels[i] action:@selector(componentChanged:)];slider.tag=i;UITextField *field=[self makeField:labels[i] tag:i];[field addTarget:self action:@selector(componentEdited:) forControlEvents:UIControlEventEditingDidEnd];
            UIStackView *track=[[UIStackView alloc]initWithArrangedSubviews:@[slider]];track.axis=UILayoutConstraintAxisVertical;track.layoutMarginsRelativeArrangement=YES;track.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(4,0,4,0);
            UIStackView *values=[[UIStackView alloc]initWithArrangedSubviews:@[track,self.fieldContainers[@(i)]]];values.spacing=16;values.alignment=UIStackViewAlignmentCenter;[self.componentFullWidths addObject:[track.widthAnchor constraintEqualToAnchor:values.widthAnchor]];[values.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;[self.workspace addArrangedSubview:[self makeRow:labels[i] control:values]];[sliders addObject:slider];[fields addObject:field];}
        self.componentSliders=sliders;self.componentFields=fields;
        if(self.sliderIndex==0){UIStackView *presets=[UIStackView new];presets.distribution=UIStackViewDistributionFillEqually;presets.spacing=0;[presets.heightAnchor constraintEqualToConstant:44].active=YES;NSMutableArray *buttons=[NSMutableArray new];
            for(NSUInteger i=0;i<5;i++){CGColorSpaceRef space=CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);CGFloat values[]={i/4.0,1};CGColorRef cg=CGColorCreate(space,values);UIColorPanelColorWell *button=(UIColorPanelColorWell *)[self makeSwatch:[[UIColorValue alloc]initWithCGColor:cg] index:i pencil:NO];button.usesCircularPresentation=YES;button.accessibilityLabel=[NSString stringWithFormat:@"%@: %@%%",[UIColorPanelAppearance localizedString:@"White"],[UIColorPanelAppearance formatNumber:i*25.0 significantDigits:0]];[button addTarget:self action:@selector(grayShortcut:) forControlEvents:UIControlEventTouchUpInside];[presets addArrangedSubview:button];[buttons addObject:button];CGColorRelease(cg);CGColorSpaceRelease(space);}self.grayShortcutButtons=buttons;[self.workspace addArrangedSubview:presets];}
        if(self.sliderIndex==1){self.hexField=[self makeField:@"Hex RGB" tag:20];self.hexField.autocapitalizationType=UITextAutocapitalizationTypeAllCharacters;self.hexField.keyboardType=UIKeyboardTypeASCIICapable;[self.hexField addTarget:self action:@selector(hexEdited:) forControlEvents:UIControlEventEditingDidEnd];UIView *spacer=[UIView new];[spacer setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisHorizontal];UILabel *hexLabel=[self makeLabel:@"Hex Color #"];self.hexLabel=hexLabel;hexLabel.adjustsFontForContentSizeCategory=NO;self.fieldContainers[@20].captionLabel=hexLabel;[self.fieldContainers[@20] refreshFont];hexLabel.numberOfLines=1;UIStackView *hex=[[UIStackView alloc]initWithArrangedSubviews:@[spacer,hexLabel,self.fieldContainers[@20]]];hex.spacing=4;hex.alignment=UIStackViewAlignmentCenter;hex.layoutMarginsRelativeArrangement=YES;hex.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(0,12,0,12);[self.workspace addArrangedSubview:hex];}
        self.spaceLabel=[self makeLabel:@""];self.spaceLabel.accessibilityIdentifier=@"ui.sliders.profile";UIStackView *status=[[UIStackView alloc]initWithArrangedSubviews:@[self.spaceLabel]];status.layoutMarginsRelativeArrangement=YES;status.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(0,12,0,12);[self.workspace addArrangedSubview:status];
        UIView *spacer=[UIView new];[spacer setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisVertical];[self.workspace addArrangedSubview:spacer];
    }else if(self.mode==UIColorPanelModeColorList){
        self.catalogController.selectedColor=self.selectedColor;[self.workspace addArrangedSubview:self.catalogController.view];
    }else if(self.mode==UIColorPanelModePencils||self.mode==UIColorPanelModeGrid){
#if UICOLORPANEL_ENABLE_PENCILS
        if((self.pickerMask&(UIColorPanelCrayonModeMask|UIColorPanelGridModeMask))==(UIColorPanelCrayonModeMask|UIColorPanelGridModeMask)){
            self.discreteModeControl=[[UISegmentedControl alloc]initWithItems:@[[UIColorPanelAppearance localizedString:@"Pencils"],[UIColorPanelAppearance localizedString:@"Grid"]]];
            self.discreteModeControl.selectedSegmentIndex=self.mode==UIColorPanelModeGrid?1:0;self.discreteModeControl.accessibilityIdentifier=@"ui.discrete.mode";
            [self.discreteModeControl addTarget:self action:@selector(discreteModeChanged:) forControlEvents:UIControlEventValueChanged];
            UIStackView *switchRow=[[UIStackView alloc]initWithArrangedSubviews:@[self.discreteModeControl]];switchRow.layoutMarginsRelativeArrangement=YES;switchRow.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(4,12,4,12);[self.workspace addArrangedSubview:switchRow];
        }
#endif
        if(self.mode==UIColorPanelModeGrid){
            self.grid=[[UIColorPickerGridView alloc]initWithFrame:CGRectZero];self.grid.selectedColor=self.selectedColor;self.grid.accessibilityIdentifier=@"ui.grid";
            [self.grid addTarget:self action:@selector(gridChanged:) forControlEvents:UIControlEventValueChanged];[self.grid addTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventEditingDidBegin];[self.grid addTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventEditingDidEnd];
            UIStackView *gridHost=[[UIStackView alloc]initWithArrangedSubviews:@[self.grid]];gridHost.axis=UILayoutConstraintAxisVertical;gridHost.layoutMarginsRelativeArrangement=YES;gridHost.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(12,12,12,12);[self.workspace addArrangedSubview:gridHost];
#if UICOLORPANEL_ENABLE_PENCILS
        }else{
        if(!self.pencilsPicker){self.pencilsPicker=[[UIColorPickerPencils alloc]initWithPickerMask:self.pickerMask colorPanel:nil];__weak typeof(self) weakSelf=self;self.pencilsPicker.selectionHandler=^(UIColorValue *color){ // BINMAP-ADAPT-BLOCK: UIKit embedded provider selection transport.
            [weakSelf applySourceColor:color notify:YES];
        };}
        UIView *host=[UIView new];[self.workspace addArrangedSubview:host];[self.pencilsPicker provideNewView:self.pencilsPicker.containerView==nil];
        [NSLayoutConstraint deactivateConstraints:self.pencilsPicker.containerView.constraints];self.pencilNameLabel=self.pencilsPicker.colorNameTextField;self.pencilNameLabel.translatesAutoresizingMaskIntoConstraints=YES;self.pencilNameLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];self.pencilNameLabel.adjustsFontForContentSizeCategory=YES;self.pencilNameLabel.numberOfLines=0;[host addSubview:self.pencilNameLabel];self.pencilContainer=self.pencilsPicker.pencilView;self.pencilContainer.translatesAutoresizingMaskIntoConstraints=YES;[host addSubview:self.pencilContainer];
        __weak typeof(self) keyboardOwner=self;self.pencilsPicker.pencilView.keyboardFocusNavigationHandler=^BOOL(BOOL backwards){
            UIColorPanelViewController *owner=keyboardOwner;if(!owner||owner.mode!=UIColorPanelModePencils)return NO;
            if(!backwards&&owner.supportsAlpha&&owner.showsAlpha&&owner.opacityField.enabled)return[owner.opacityField becomeFirstResponder];
            return[owner.modeControl becomeFirstResponder];
        };
        [self.pencilsPicker.pencilView removeTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventTouchDown];[self.pencilsPicker.pencilView removeTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        [self.pencilsPicker.pencilView addTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventTouchDown];[self.pencilsPicker.pencilView addTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];self.pencilsPicker.pencilView.use_spi=self.configuration.use_spi;[self.pencilsPicker setColor:self.selectedColor];
#endif
        }
    }else{
        self.workspace.layoutMargins=UIEdgeInsetsZero;self.workspace.spacing=4;
        if(!_sampling){[self.workspace addArrangedSubview:self.imagePaletteController.view];self.imageHeaderHeight=[self.imagePaletteController.view.heightAnchor constraintEqualToConstant:44];self.imageHeaderHeight.priority=999;self.imageHeaderHeight.active=YES;}
        if(!_sampling&&self.imagePaletteController.isBuiltInSpectrumSelected){
            self.spectrum=[[UIColorPickerSpectrum alloc]initWithFrame:CGRectZero];self.spectrum.selectedColor=self.selectedColor;self.spectrum.accessibilityIdentifier=@"ui.spectrum";
            [self.spectrum addTarget:self action:@selector(spectrumChanged:) forControlEvents:UIControlEventValueChanged];[self.spectrum addTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventEditingDidBegin];[self.spectrum addTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventEditingDidEnd];
            UIStackView *spectrumHost=[[UIStackView alloc]initWithArrangedSubviews:@[self.spectrum]];spectrumHost.axis=UILayoutConstraintAxisVertical;spectrumHost.layoutMarginsRelativeArrangement=YES;spectrumHost.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(20,20,20,20);[self.workspace addArrangedSubview:spectrumHost];
        }else{
        self.imageSampler=[[UIColorPickerUserView alloc]initWithFrame:CGRectZero];self.imageSampler.contentMode=UIViewContentModeScaleAspectFit;self.imageSampler.backgroundColor=self.view.backgroundColor;self.imageSampler.image=_sampling?(self.configuration.samplingImage?:self.paletteImage):self.paletteImage;self.imageSampler.selectedColor=self.selectedColor;
        [self.imageSampler addTarget:self action:@selector(imageChanged:) forControlEvents:UIControlEventValueChanged];[self.imageSampler addTarget:self action:@selector(trackingBegan:) forControlEvents:UIControlEventEditingDidBegin];[self.imageSampler addTarget:self action:@selector(trackingEnded:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];UIStackView *imageHost=[[UIStackView alloc]initWithArrangedSubviews:@[self.imageSampler]];imageHost.axis=UILayoutConstraintAxisVertical;imageHost.layoutMarginsRelativeArrangement=YES;imageHost.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(20,20,20,20);[self.workspace addArrangedSubview:imageHost];
        }
        if(_sampling){UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem];[cancel setTitle:@"Cancel Sampling" forState:UIControlStateNormal];[cancel.heightAnchor constraintEqualToConstant:28].active=YES;[cancel addTarget:self action:@selector(cancelSample:) forControlEvents:UIControlEventTouchUpInside];[self.workspace addArrangedSubview:cancel];}
    }
    [self.view setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelViewController.chooseSliderModel:
- (void)chooseSliderModel:(UIButton *)sender {
    NSArray *names=@[@"Gray Sliders",@"RGB Sliders",@"CMYK Sliders",@"HSB Sliders"];NSMutableArray *items=[NSMutableArray new];__weak typeof(self) weakSelf=self;
    for(NSInteger index=0;index<4;index++)if(self.pickerMask&(1UL<<index))[items addObject:[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:names[index]] selected:index==self.sliderIndex enabled:YES destructive:NO handler:^{if([weakSelf commitPendingEdits]){[weakSelf.view endEditing:YES];weakSelf.mode=index;}}]];
    [UIColorPanelChoiceController presentFromViewController:self title:[UIColorPanelAppearance localizedString:@"Color model"] sections:@[[UIColorPanelChoiceSection sectionWithTitle:nil items:items]] sourceView:sender];
}
// BINMAP-ADAPT: UIColorPanelViewController.sliderModelMenu manifest=reimpl/native_panel_extras.json
- (UIMenu *)sliderModelMenu API_AVAILABLE(ios(13.0)) {
    NSUInteger generation=self.transientGeneration;
    NSArray *names=@[@"Gray Sliders",@"RGB Sliders",@"CMYK Sliders",@"HSB Sliders"];NSMutableArray *actions=[NSMutableArray new];__weak typeof(self) weakSelf=self;
    for(NSInteger index=0;index<4;index++)if(self.pickerMask&(1UL<<index)){
        UIAction *action=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:names[index]] image:nil identifier:nil handler:^(UIAction *action){if(weakSelf.transientGeneration==generation&&[weakSelf prepareForTransientPresentation]){[weakSelf.view endEditing:YES];weakSelf.mode=index;}}];
        action.state=index==self.sliderIndex?UIMenuElementStateOn:UIMenuElementStateOff;[actions addObject:action];
    }
    return[UIMenu menuWithTitle:@"" children:actions];
}
// BINMAP-ADAPT: UIColorPanelViewController.sliderOptionsMenu manifest=reimpl/native_panel_extras.json
- (UIMenu *)sliderOptionsMenu API_AVAILABLE(ios(13.0)) {
    NSUInteger generation=self.transientGeneration;__weak typeof(self) weakSelf=self;NSMutableArray *sections=[NSMutableArray new];
    if(self.sliderIndex==1){NSMutableArray *precision=[NSMutableArray new];for(NSInteger index=0;index<2;index++){
        UIAction *action=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@[@"8-bit values",@"Floating point values"][index]] image:nil identifier:nil handler:^(UIAction *action){UIColorPanelViewController *controller=weakSelf;if(!controller||controller.transientGeneration!=generation||![controller prepareForTransientPresentation])return;controller.precision.selectedSegmentIndex=index;[controller precisionChanged:controller.precision];}];
        action.state=self.precisionIndex==index?UIMenuElementStateOn:UIMenuElementStateOff;[precision addObject:action];}
        [sections addObject:[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:precision]];
    }
    NSArray *profiles=[self profilesForMode:self.mode];NSMutableArray *actions=[NSMutableArray new];
    for(UIColorPanelColorProfile *profile in profiles){UIAction *action=[UIAction actionWithTitle:[self profileMenuTitle:profile profiles:profiles] image:nil identifier:profile.identifier handler:^(UIAction *action){UIColorPanelViewController *controller=weakSelf;if(!controller||controller.transientGeneration!=generation||![controller prepareForTransientPresentation])return;NSError *error=nil;if(![controller selectColorProfile:profile error:&error animated:YES]&&error)[controller showError:error.localizedDescription];}];action.state=[profile isEqual:self.activeColorProfile]?UIMenuElementStateOn:UIMenuElementStateOff;[actions addObject:action];}
    if(actions.count)[sections addObject:[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Color profile"] image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions]];
    CGColorSpaceRef source=CGColorGetColorSpace(self.selectedColor.CGColor);
    if(source&&self.activeColorProfile&&CGColorSpaceGetModel(source)!=self.activeColorProfile.model){UIColorPanelColorProfile *info=[[UIColorPanelColorProfile alloc]initWithColorSpace:source displayName:nil];UIAction *row=[UIAction actionWithTitle:info.displayName image:nil identifier:nil handler:^(UIAction *action){}];row.attributes=UIMenuElementAttributesDisabled;row.state=UIMenuElementStateOn;[sections addObject:[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Current color"] image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[row]]];}
    return[UIMenu menuWithTitle:@"" children:sections];
}
// BINMAP-ADAPT: UIColorPanelViewController.profileChoiceSections manifest=reimpl/slider_profile_extras.json
- (NSArray<UIColorPanelChoiceSection *> *)profileChoiceSections {
    NSMutableArray *sections=[NSMutableArray new];__weak typeof(self) weakSelf=self;NSUInteger generation=self.transientGeneration;
    if(self.sliderIndex==1){NSMutableArray *items=[NSMutableArray new];for(NSInteger index=0;index<2;index++)[items addObject:[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@[@"8-bit values",@"Floating point values"][index]] selected:self.precisionIndex==index enabled:YES destructive:NO handler:^{UIColorPanelViewController *controller=weakSelf;if(controller&&controller.transientGeneration==generation){controller.precision.selectedSegmentIndex=index;[controller precisionChanged:controller.precision];}}]];[sections addObject:[UIColorPanelChoiceSection sectionWithTitle:[UIColorPanelAppearance localizedString:@"Precision"] items:items]];}
    NSArray *profiles=[self profilesForMode:self.mode];NSMutableArray *items=[NSMutableArray new];
    for(UIColorPanelColorProfile *profile in profiles)[items addObject:[UIColorPanelChoiceItem itemWithTitle:[self profileMenuTitle:profile profiles:profiles] selected:[profile isEqual:self.activeColorProfile] enabled:YES destructive:NO handler:^{UIColorPanelViewController *controller=weakSelf;if(!controller||controller.transientGeneration!=generation)return;NSError *error=nil;if(![controller selectColorProfile:profile error:&error animated:YES]&&error)[controller showError:error.localizedDescription];}]];
    if(items.count)[sections addObject:[UIColorPanelChoiceSection sectionWithTitle:[UIColorPanelAppearance localizedString:@"Color profile"] items:items]];
    CGColorSpaceRef source=CGColorGetColorSpace(self.selectedColor.CGColor);
    if(source&&self.activeColorProfile&&CGColorSpaceGetModel(source)!=self.activeColorProfile.model){UIColorPanelColorProfile *info=[[UIColorPanelColorProfile alloc]initWithColorSpace:source displayName:nil];[sections addObject:[UIColorPanelChoiceSection sectionWithTitle:[UIColorPanelAppearance localizedString:@"Current color"] items:@[[UIColorPanelChoiceItem itemWithTitle:info.displayName selected:YES enabled:NO destructive:NO handler:^{}]]]];}
    return sections;
}
// BINMAP-ADAPT: UIColorPanelViewController.chooseSliderOptions:
- (void)chooseSliderOptions:(UIButton *)sender {
    [UIColorPanelChoiceController presentFromViewController:self title:[UIColorPanelAppearance localizedString:@"Slider options"] sections:[self profileChoiceSections] sourceView:sender];
}
// BINMAP-ADAPT: UIColorPanelViewController.sliderModelChanged:
- (void)sliderModelChanged:(UISegmentedControl *)sender {if(![self commitPendingEdits]){sender.selectedSegmentIndex=self.sliderIndex;return;}[self.view endEditing:YES];self.mode=sender.selectedSegmentIndex;}
// BINMAP-ADAPT: UIColorPanelViewController.precisionChanged:
- (void)precisionChanged:(UISegmentedControl *)sender {if(![self commitPendingEdits]){sender.selectedSegmentIndex=self.precisionIndex;return;}[self.view endEditing:YES];self.precisionIndex=sender.selectedSegmentIndex;[self updateControls];[self.view setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanelViewController.spaceChanged:
- (void)spaceChanged:(UISegmentedControl *)sender {
    // Compatibility transport for existing callers/tests of the former internal
    // 3-segment model. Menus and current working spaces use profile identities.
    NSInteger index=sender.selectedSegmentIndex;CGColorSpaceRef space=index==2&&_originalSpace?CGColorSpaceRetain(_originalSpace):CGColorSpaceCreateWithName(index==1?kCGColorSpaceDisplayP3:kCGColorSpaceSRGB);
    if(!space)return;UIColorPanelColorProfile *profile=[[UIColorPanelColorProfile alloc]initWithColorSpace:space displayName:nil];CGColorSpaceRelease(space);
    NSError *error=nil;if(![self selectColorProfile:profile error:&error animated:YES]){sender.selectedSegmentIndex=self.spaceIndex;if(error)[self showError:error.localizedDescription];}
}
// BINMAP-ADAPT: UIColorPanelViewController.updateControls
- (void)updateControls {
    if(_updating)return;_updating=YES;
    NSUInteger selectedMode=[self.modeSegmentModes indexOfObject:@(self.mode<=UIColorPanelModeHSB?UIColorPanelModeRGB:UICOLORPANEL_ENABLE_PENCILS&&self.mode==UIColorPanelModeGrid?UIColorPanelModePencils:self.mode)];self.modeControl.selectedSegmentIndex=selectedMode==NSNotFound?UISegmentedControlNoSegment:(NSInteger)selectedMode;
    self.grid.selectedColor=self.selectedColor;self.spectrum.selectedColor=self.selectedColor;self.imageSampler.selectedColor=self.selectedColor;
    CGFloat alpha=CGColorGetAlpha(self.selectedColor.CGColor);self.opacitySlider.value=alpha;self.opacitySlider.selectedColor=self.selectedColor.UIColor;
    NSNumberFormatter *spokenPercent=[NSNumberFormatter new];spokenPercent.numberStyle=NSNumberFormatterPercentStyle;spokenPercent.maximumFractionDigits=3;spokenPercent.usesGroupingSeparator=NO;
    self.opacitySlider.accessibilityValue=[spokenPercent stringFromNumber:@(alpha)];
    if(!self.opacityField.isFirstResponder&&![self.editedFields containsObject:self.opacityField]){NSNumberFormatter *formatter=[NSNumberFormatter new];formatter.numberStyle=NSNumberFormatterPercentStyle;formatter.minimumFractionDigits=0;formatter.maximumFractionDigits=0;formatter.usesGroupingSeparator=NO;self.opacityField.text=[formatter stringFromNumber:@(alpha)];}
    self.currentWell.color=self.selectedColor;[self.currentWell setNeedsDisplay];UIColorValue *opaque=[self.selectedColor copyWithAlpha:1];((UIGradientSlider *)self.opacitySlider).gradientColors=@[UIColor.clearColor,opaque.UIColor];[self.opacitySlider setNeedsLayout];
    UIColorPanelColorProfile *sourceProfile=[[UIColorPanelColorProfile alloc]initWithColorSpace:CGColorGetColorSpace(self.selectedColor.CGColor) displayName:nil];
    NSMutableArray *spoken=[NSMutableArray arrayWithObject:sourceProfile.displayName?:[UIColorPanelAppearance localizedString:@"Original ICC profile"]];const CGFloat *originalComponents=CGColorGetComponents(self.selectedColor.CGColor);NSUInteger componentCount=CGColorGetNumberOfComponents(self.selectedColor.CGColor);for(NSUInteger i=0;i+1<componentCount;i++)[spoken addObject:[UIColorPanelAppearance formatNumber:originalComponents[i] significantDigits:6]];[spoken addObject:[NSString stringWithFormat:@"%@: %@",[UIColorPanelAppearance localizedString:@"Opacity"],[spokenPercent stringFromNumber:@(alpha)]]];self.currentWell.accessibilityValue=[spoken componentsJoinedByString:@", "];
    CGColorSpaceRef effective=NULL;UIColorPanelColorProfile *rgbProfile=self.mode==UIColorPanelModeHSB?[self profileForMode:UIColorPanelModeHSB]:self.mode==UIColorPanelModeRGB?[self profileForMode:UIColorPanelModeRGB]:nil;
    if(rgbProfile)effective=CGColorSpaceRetain(rgbProfile.CGColorSpace);
    else {CGColorSpaceRef source=CGColorGetColorSpace(self.selectedColor.CGColor);effective=CGColorSpaceGetModel(source)==kCGColorSpaceModelRGB?CGColorSpaceRetain(source):CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);}
    UIColorValue *working=effective?[self.selectedColor colorByConvertingToSpace:effective error:NULL]:nil;if(effective)CGColorSpaceRelease(effective);BOOL valid=working!=nil;
    if(valid){
        const CGFloat *components=CGColorGetComponents(working.CGColor);
        CGFloat r=MAX(0,MIN(1,components[0])),g=MAX(0,MIN(1,components[1])),b=MAX(0,MIN(1,components[2]));
        CGFloat maximum=MAX(r,MAX(g,b)),minimum=MIN(r,MIN(g,b)),delta=maximum-minimum,h=_hue;
        if(delta>0){if(maximum==r)h=fmod((g-b)/delta+6,6)/6;else if(maximum==g)h=((b-r)/delta+2)/6;else h=((r-g)/delta+4)/6;}
        _hue=h;_saturation=maximum>0?delta/maximum:_saturation;_brightness=maximum;
        self.wheel.colorValue=working;self.wheel.hue=_hue;self.wheel.saturation=_saturation;self.wheel.brightness=_brightness;
        [self.wheel setNeedsDisplay];self.wheel.enabled=YES;self.brightnessSlider.enabled=YES;self.brightnessSlider.value=1-_brightness;self.brightnessSlider.accessibilityValue=[spokenPercent stringFromNumber:@(_brightness)];
        UIGradientSlider *track=self.brightnessSlider;track.selectedColor=self.selectedColor.UIColor;
        CGFloat brightComponents[4]={0};for(int i=0;i<3;i++)brightComponents[i]=maximum>0?components[i]/maximum:1;brightComponents[3]=1;
        CGColorRef bright=CGColorCreate(CGColorGetColorSpace(working.CGColor),brightComponents);track.gradientColors=@[[UIColor colorWithCGColor:bright],UIColor.blackColor];CGColorRelease(bright);[track setNeedsLayout];
    }else {self.wheel.enabled=NO;self.brightnessSlider.enabled=NO;}
    if((self.mode>=UIColorPanelModeGray&&self.mode<=UIColorPanelModeHSB)){
        UIColorPanelColorProfile *profile=self.activeColorProfile;CGColorSpaceRef target=profile?CGColorSpaceRetain(profile.CGColorSpace):NULL;
        NSError *error;UIColorValue *converted=target?[self.selectedColor colorByConvertingToSpace:target error:&error]:nil;
        CGFloat channels[4]={0};BOOL editable=converted!=nil;
        if(converted){const CGFloat *p=CGColorGetComponents(converted.CGColor);for(NSUInteger i=0;i<MIN((NSUInteger)4,CGColorGetNumberOfComponents(converted.CGColor)-1);i++)channels[i]=p[i];}
        for(UIColorPanelColorWell *button in self.grayShortcutButtons){
            if(target){CGFloat components[]={button.tag/4.0,1};CGColorRef color=CGColorCreate(target,components);button.color=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);}
            button.enabled=target!=NULL;button.selected=converted&&[converted isEqual:button.color];
        }
        if(self.sliderIndex==3){channels[0]=_hue;channels[1]=_saturation;channels[2]=_brightness;editable=valid;}
        for(NSUInteger i=0;i<self.componentSliders.count;i++){
            CGFloat multiplier=self.sliderIndex==1?(self.precisionIndex==0?255:1):(self.sliderIndex==3&&i==0?360:100);
            UIGradientSlider *slider=self.componentSliders[i];slider.value=channels[i];slider.enabled=editable;slider.selectedColor=self.selectedColor.UIColor;
            double displayValue=self.sliderIndex==1&&self.precisionIndex==0?trunc(channels[i]*multiplier):channels[i]*multiplier;
            slider.accessibilityValue=self.sliderIndex==1?[UIColorPanelAppearance formatNumber:displayValue significantDigits:self.precisionIndex==0?0:9]:(self.sliderIndex==3&&i==0?[NSString stringWithFormat:@"%@°",[UIColorPanelAppearance formatNumber:channels[i]*360 significantDigits:6]]:[spokenPercent stringFromNumber:@(channels[i])]);
            UIGradientSlider *gradient=(UIGradientSlider *)slider;
            NSMutableArray *colors=[NSMutableArray new];
            if(target&&converted){NSUInteger steps=self.sliderIndex==3&&i==0?6:1;for(NSUInteger j=0;j<=steps;j++){
                CGFloat components[5]={channels[0],channels[1],channels[2],channels[3],1};
                if(self.sliderIndex==3){CGFloat h=channels[0],sat=MAX(.05,channels[1]),bright=MAX(.01,channels[2]);if(i==0)h=j/(CGFloat)steps;else if(i==1)sat=j;else bright=j;
                    CGFloat sector=fmod(h,1)*6,chroma=bright*sat,x=chroma*(1-fabs(fmod(sector,2)-1)),m=bright-chroma;CGFloat red=0,green=0,blue=0;
                    switch((NSInteger)sector%6){case 0:red=chroma;green=x;break;case 1:red=x;green=chroma;break;case 2:green=chroma;blue=x;break;case 3:green=x;blue=chroma;break;case 4:red=x;blue=chroma;break;case 5:red=chroma;blue=x;break;}
                    components[0]=red+m;components[1]=green+m;components[2]=blue+m;components[3]=1;
                }else {components[i]=j;components[CGColorSpaceGetNumberOfComponents(target)]=1;}
                CGColorRef cg=CGColorCreate(target,components);if(cg){[colors addObject:[UIColor colorWithCGColor:cg]];CGColorRelease(cg);}
            }}
            gradient.gradientColors=colors;[gradient setNeedsLayout];
            UITextField *field=self.componentFields[i];field.enabled=editable;
            if(!field.isFirstResponder&&![self.editedFields containsObject:field])field.text=[UIColorPanelAppearance formatNumber:displayValue significantDigits:self.sliderIndex==1&&self.precisionIndex==0?0:9];
        }
        self.hexField.enabled=editable;
        if(self.hexField&&!self.hexField.isFirstResponder&&![self.editedFields containsObject:self.hexField]){NSInteger bytes[3];for(int i=0;i<3;i++){bytes[i]=lroundf((float)(MAX(0,MIN(1,channels[i]))*255));}self.hexField.text=[NSString stringWithFormat:@"%02lX%02lX%02lX",(long)bytes[0],(long)bytes[1],(long)bytes[2]];}
        self.spaceLabel.text=editable?(profile.displayName?:[UIColorPanelAppearance localizedString:@"Original ICC profile"]):[UIColorPanelAppearance localizedString:@"This color cannot be converted to the selected profile. The original selection is preserved."];
        self.spaceLabel.hidden=editable&&self.hexField!=nil;
        self.hexLabel.text=[NSString stringWithFormat:@"%@ %@",profile.displayName?:[UIColorPanelAppearance localizedString:@"Original ICC profile"],[UIColorPanelAppearance localizedString:@"Hex Color #"]];
        self.hexField.accessibilityLabel=self.hexLabel.text;
        if(target)CGColorSpaceRelease(target);

    }
#if UICOLORPANEL_ENABLE_PENCILS
    [self.pencilsPicker setColor:self.selectedColor];
#endif
    self.swatchesView.currentColor=self.selectedColor;
    [self updateFavoritesSummary];[self updateProfileMenus];[self.view setNeedsLayout];
    _updating=NO;
}
// BINMAP-ADAPT: UIColorPanelViewController.applyColor:notify:
- (void)applyColor:(UIColorValue *)color notify:(BOOL)notify {
    if(!color)return;BOOL wasApplying=_applyingEdit;_applyingEdit=YES;
    @try{self.selectedColor=color;if(notify)[self.delegate colorPanel:self didSelectColor:color];
        // A host may synchronously replace the color while receiving the edit.
        // Adopt that override as a new source after the internal round-trip ends;
        // unchanged Shared-panel synchronization must retain its original source.
        if(notify&&!CGColorEqualToColor(self.selectedColor.CGColor,color.CGColor)){UIColorValue *override=self.selectedColor;_applyingEdit=NO;self.selectedColor=override;}
    }
    @finally{_applyingEdit=wasApplying;}
}
// BINMAP-ADAPT: UIColorPanelViewController.applySourceColor:notify: manifest=reimpl/ui_ux_repairs_extras.json
// Native NSRGBSliders accepts a newly selected source profile even after an explicit working-profile choice.
- (void)applySourceColor:(UIColorValue *)color notify:(BOOL)notify {
    if(!color)return;BOOL wasApplying=_applyingEdit;_applyingEdit=NO;
    @try {
        self.spaceIndex=CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor))==kCGColorSpaceModelRGB?2:0;
        self.selectedColor=color;
        if(notify&&[self.delegate respondsToSelector:@selector(colorPanel:didSelectColor:)])[self.delegate colorPanel:self didSelectColor:color];
        if([self.delegate isKindOfClass:UIColorPanel.class])self.selectedColor=[(UIColorPanel *)self.delegate colorValue];
    } @finally {_applyingEdit=wasApplying;}
}
// BINMAP-ADAPT: UIColorPanelViewController.wheelChanged:
- (void)wheelChanged:(UIColorPickerWheelView *)wheel {
    [self applyColor:wheel.colorValue notify:YES];
}
// BINMAP-ADAPT: UIColorPanelViewController.brightnessChanged:
- (void)brightnessChanged:(UIGradientSlider *)sender {
    _brightness=1-sender.value;
    UIColorValue *working=self.wheel.colorValue?:self.selectedColor;
    CGColorSpaceRef space=CGColorGetColorSpace(working.CGColor);
    CGFloat sector=_hue*6,chroma=_brightness*_saturation,x=chroma*(1-fabs(fmod(sector,2)-1)),m=_brightness-chroma;
    CGFloat values[4]={m,m,m,CGColorGetAlpha(self.selectedColor.CGColor)};
    switch((int)sector%6){case 0:values[0]+=chroma;values[1]+=x;break;case 1:values[0]+=x;values[1]+=chroma;break;case 2:values[1]+=chroma;values[2]+=x;break;case 3:values[1]+=x;values[2]+=chroma;break;case 4:values[0]+=x;values[2]+=chroma;break;case 5:values[0]+=chroma;values[2]+=x;break;}
    CGColorRef cg=CGColorCreate(space,values);[self applyColor:[[UIColorValue alloc]initWithCGColor:cg] notify:YES];CGColorRelease(cg);
}
// BINMAP-ADAPT: UIColorPanelViewController.componentChanged:
- (void)componentChanged:(UIGradientSlider *)sender {
    if(_updating || sender.tag<0 || sender.tag>=(NSInteger)self.componentFields.count)return;
    UITextField *field=self.componentFields[sender.tag];CGFloat multiplier=self.sliderIndex==1?(self.precisionIndex==0?255:1):(self.sliderIndex==3&&sender.tag==0?360:100);
    double value=sender.value;
    double displayValue=self.sliderIndex==1&&self.precisionIndex==0?trunc(value*multiplier):value*multiplier;
    field.text=[UIColorPanelAppearance formatNumber:displayValue significantDigits:self.sliderIndex==1&&self.precisionIndex==0?0:9];[self textEdited:field];
    // The formatted field is a display value, not the slider's color precision.
    [self applyComponentValue:value field:field];
}
// BINMAP-ADAPT: UIColorPanelViewController.commitField: manifest=reimpl/ui_ux_repairs_extras.json
- (BOOL)commitField:(UITextField *)field {
    if(![self.editedFields containsObject:field])return YES;
    if(field==self.opacityField)[self opacityEdited:field];
    else if(field==self.hexField)[self hexEdited:field];
    else [self componentEdited:field];
    return ![self.editedFields containsObject:field];
}
// BINMAP-ADAPT: UIColorPanelViewController.commitPendingEdits manifest=reimpl/ui_ux_repairs_extras.json
- (BOOL)commitPendingEdits {
    if(self.endingTransientInteractions)return NO;
    if(self.submittingEdits)return NO;
    self.submittingEdits=YES;
    @try {
        for(UITextField *field in self.editedFields.allObjects)if(![self commitField:field])return NO;
        return YES;
    } @finally {self.submittingEdits=NO;}
}
// BINMAP-ADAPT: UIColorPanelViewController.reportInputError:field: manifest=reimpl/ui_ux_repairs_extras.json
- (void)reportInputError:(NSString *)message field:(UITextField *)field {
    self.invalidField=field;
    if(self.inputErrorAlert||self.endingTransientInteractions)return;
    UITextRange *selection=field.selectedTextRange;NSUInteger generation=self.transientGeneration;
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Colors"] message:[UIColorPanelAppearance localizedString:message] preferredStyle:UIAlertControllerStyleAlert];
    self.inputErrorAlert=alert;__weak typeof(self) weakSelf=self;__weak UITextField *weakField=field;
    [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        UIColorPanelViewController *controller=weakSelf;controller.inputErrorAlert=nil;
        dispatch_async(dispatch_get_main_queue(),^{
            UITextField *editor=weakField;UIWindow *window=editor.window;
            if(!controller||controller.transientGeneration!=generation||!window||window.hidden||([UIPanel panelForWindow:window]&&![UIPanel panelForWindow:window].visible)||(editor==controller.opacityField&&!(controller.supportsAlpha&&controller.showsAlpha)))return;
            [editor becomeFirstResponder];if(selection)editor.selectedTextRange=selection;
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,editor);
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-EDIT-01 manifest=reimpl/color_model_extras.json
- (void)textEdited:(UITextField *)sender {
    if (!self.editedFields) self.editedFields = [NSHashTable weakObjectsHashTable];
    [self.editedFields addObject:sender];
}
// BINMAP-ADAPT: UIColorPanelViewController.componentEdited:
- (void)componentEdited:(UITextField *)sender {
    if(_updating || ![self.editedFields containsObject:sender])return;
    if(sender.tag<0 || sender.tag>=(NSInteger)self.componentFields.count)return;
    NSNumber *parsed=[UIColorPanelAppearance parseNumber:sender.text?:@""];double input=parsed.doubleValue;
    if(!parsed){[self reportInputError:@"Enter a finite number." field:sender];return;}
    CGFloat divisor=self.sliderIndex==1?(self.precisionIndex==0?255:1):(self.sliderIndex==3&&sender.tag==0?360:100);
    [self applyComponentValue:input/divisor field:sender];
}
// BINMAP-ADAPT: UIColorPanelViewController.applyComponentValue:field: manifest=reimpl/touch_panel_extras.json
- (void)applyComponentValue:(double)value field:(UITextField *)sender {
    CGFloat channels[5]={0,0,0,0,CGColorGetAlpha(self.selectedColor.CGColor)};
    UIColorPanelColorProfile *profile=self.activeColorProfile;CGColorSpaceRef target=profile?CGColorSpaceRetain(profile.CGColorSpace):NULL;
    if(!target){[self reportInputError:@"This color profile is unavailable." field:sender];return;}
    if(self.sliderIndex==3){channels[0]=_hue;channels[1]=_saturation;channels[2]=_brightness;}
    else{
        UIColorValue *converted=[self.selectedColor colorByConvertingToSpace:target error:NULL];
        if(!converted){CGColorSpaceRelease(target);[self reportInputError:@"This color cannot be converted to the selected profile." field:sender];return;}
        const CGFloat *p=CGColorGetComponents(converted.CGColor);
        for(NSUInteger i=0;i<CGColorGetNumberOfComponents(converted.CGColor)-1;i++)channels[i]=p[i];
    }
    if(self.sliderIndex!=1&&(value<0||value>1)){CGColorSpaceRelease(target);[self reportInputError:@"Enter a value within the displayed range (0–100%, or 0–360° for hue)." field:sender];return;}
    channels[sender.tag]=value;
    UIColorValue *newColor=nil;
    if(self.sliderIndex==3){
        CGFloat sector=fmod(channels[0],1)*6, chroma=channels[2]*channels[1], secondary=chroma*(1-fabs(fmod(sector,2)-1));
        CGFloat r=0,g=0,b=0,m=channels[2]-chroma;
        switch((NSInteger)sector%6){case 0:r=chroma;g=secondary;break;case 1:r=secondary;g=chroma;break;case 2:g=chroma;b=secondary;break;case 3:g=secondary;b=chroma;break;case 4:r=secondary;b=chroma;break;case 5:r=chroma;b=secondary;break;}
        CGFloat components[]={r+m,g+m,b+m,channels[4]};
        CGColorRef color=CGColorCreate(target,components);
        if(color){newColor=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);}
    }else{
        NSUInteger count=CGColorSpaceGetNumberOfComponents(target);channels[count]=channels[4];
        CGColorRef color=CGColorCreate(target,channels);if(color){newColor=[[UIColorValue alloc]initWithCGColor:color];CGColorRelease(color);}
    }
    CGColorSpaceRelease(target);newColor=[self regularColor:newColor profile:profile];if(!newColor){[self reportInputError:@"This color profile is unavailable." field:sender];return;}
    // Hue at zero saturation and H/S at zero brightness cannot round-trip
    // through RGB. Keep the user's edit until another source supplies a color.
    if(self.sliderIndex==3){_hue=channels[0];_saturation=channels[1];_brightness=channels[2];}
    [self.editedFields removeObject:sender];self.invalidField=nil;[self applyColor:newColor notify:YES];
}
// BINMAP-ADAPT: UIColorPanelViewController.hexEdited:
- (void)hexEdited:(UITextField *)sender {
    if(![self.editedFields containsObject:sender])return;
    NSString *string=[sender.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if([string hasPrefix:@"#"])string=[string substringFromIndex:1];
    unsigned int value=0;BOOL valid=string.length==3||string.length==6;
    for(NSUInteger i=0;valid&&i<string.length;i++){unichar c=[string characterAtIndex:i];unsigned int digit;if(c>='0'&&c<='9')digit=c-'0';else if(c>='A'&&c<='F')digit=c-'A'+10;else if(c>='a'&&c<='f')digit=c-'a'+10;else{valid=NO;break;}value=string.length==3?(value<<8)|(digit*17):(value<<4)|digit;}
    if(!valid){[self reportInputError:@"Enter three or six hexadecimal digits, for example F80 or FF8800." field:sender];return;}
    UIColorPanelColorProfile *profile=[self profileForMode:UIColorPanelModeRGB];CGColorSpaceRef space=profile?CGColorSpaceRetain(profile.CGColorSpace):NULL;if(!space){[self reportInputError:@"This color profile is unavailable." field:sender];return;}
    [self.editedFields removeObject:sender];self.invalidField=nil;
    CGFloat components[]={((value>>16)&255)/255.0,((value>>8)&255)/255.0,(value&255)/255.0,CGColorGetAlpha(self.selectedColor.CGColor)};CGColorRef cg=CGColorCreate(space,components);[self applyColor:[[UIColorValue alloc]initWithCGColor:cg] notify:YES];CGColorRelease(cg);CGColorSpaceRelease(space);
}
// BINMAP-ADAPT: UIColorPanelViewController.textFieldShouldReturn:
- (BOOL)textFieldShouldReturn:(UITextField *)field {if(![self commitField:field])return NO;[field resignFirstResponder];return YES;}
// BINMAP-ADAPT: UIColorPanelViewController.numericKeyboardDone: manifest=reimpl/touch_panel_extras.json
- (void)numericKeyboardDone:(UIBarButtonItem *)sender {[self textFieldShouldReturn:self.fieldContainers[@(sender.tag)].textField];}
// BINMAP-ADAPT: UIColorPanelViewController.constrainPercentageSelection: manifest=reimpl/touch_panel_extras.json original=0x10001AA70
- (void)constrainPercentageSelection:(UITextField *)field {
    if(field!=self.opacityField)return;
    UITextRange *selection=field.selectedTextRange;
    if(!selection||![selection.start isEqual:selection.end])return;
    NSRange first=[field.text rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet];
    if(first.location==NSNotFound)return;
    NSRange last=[field.text rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet options:NSBackwardsSearch];
    NSInteger caret=[field offsetFromPosition:field.beginningOfDocument toPosition:selection.start];
    NSInteger clamped=MAX((NSInteger)first.location,MIN((NSInteger)NSMaxRange(last),caret));
    if(clamped==caret)return;
    UITextPosition *position=[field positionFromPosition:field.beginningOfDocument offset:clamped];
    field.selectedTextRange=[field textRangeFromPosition:position toPosition:position];
}
// BINMAP-ADAPT: UIColorPanelViewController.textFieldDidChangeSelection: manifest=reimpl/touch_panel_extras.json
- (void)textFieldDidChangeSelection:(UITextField *)field {[self constrainPercentageSelection:field];}
// BINMAP-ADAPT: UIColorPanelViewController.textFieldDidBeginEditing: manifest=reimpl/touch_panel_extras.json
- (void)textFieldDidBeginEditing:(UITextField *)field {
    if(field==self.opacityField&&![self.editedFields containsObject:field]){
        // Expose the existing fractional-alpha extension only while editing.
        NSNumberFormatter *formatter=[NSNumberFormatter new];formatter.numberStyle=NSNumberFormatterPercentStyle;formatter.usesSignificantDigits=YES;formatter.minimumSignificantDigits=1;formatter.maximumSignificantDigits=6;formatter.usesGroupingSeparator=NO;
        field.text=[formatter stringFromNumber:@(CGColorGetAlpha(self.selectedColor.CGColor))];
        [self constrainPercentageSelection:field];
    }
}
// BINMAP-ADAPT: UIColorPanelViewController.textFieldDidEndEditing: manifest=reimpl/touch_panel_extras.json
- (void)textFieldDidEndEditing:(UITextField *)field {
    if(field==self.opacityField&&![self.editedFields containsObject:field])[self updateControls];
}
// BINMAP-ADAPT: UIColorPanelViewController.opacityChanged:
- (void)opacityChanged:(UIGradientSlider *)sender {
    [self.editedFields removeObject:self.opacityField];if(self.invalidField==self.opacityField)self.invalidField=nil;
    NSNumberFormatter *formatter=[NSNumberFormatter new];formatter.numberStyle=NSNumberFormatterPercentStyle;formatter.minimumFractionDigits=0;formatter.maximumFractionDigits=0;formatter.usesGroupingSeparator=NO;
    self.opacityField.text=[formatter stringFromNumber:@(sender.value)];[self applyColor:[self.selectedColor copyWithAlpha:sender.value] notify:YES];
}
// BINMAP-ADAPT: UIColorPanelViewController.opacityEdited:
- (void)opacityEdited:(UITextField *)sender {
    if(![self.editedFields containsObject:sender])return;
    NSMutableString *text=[(sender.text?:@"") mutableCopy];for(NSString *mark in @[@"\u200e",@"\u200f",@"\u061c"])[text replaceOccurrencesOfString:mark withString:@"" options:0 range:NSMakeRange(0,text.length)];
    NSString *trimmed=[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];NSNumberFormatter *formatter=[NSNumberFormatter new];formatter.numberStyle=NSNumberFormatterPercentStyle;NSString *symbol=formatter.percentSymbol;for(NSString *mark in @[@"\u200e",@"\u200f",@"\u061c"])symbol=[symbol stringByReplacingOccurrencesOfString:mark withString:@""];symbol=[symbol stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(symbol.length&&[trimmed hasSuffix:symbol])trimmed=[trimmed substringToIndex:trimmed.length-symbol.length];else if(symbol.length&&[trimmed hasPrefix:symbol])trimmed=[trimmed substringFromIndex:symbol.length];else if([trimmed hasSuffix:@"%"]||[trimmed hasPrefix:@"%"])trimmed=[trimmed hasSuffix:@"%"]?[trimmed substringToIndex:trimmed.length-1]:[trimmed substringFromIndex:1];
    NSNumber *parsed=[UIColorPanelAppearance parseNumber:trimmed];double value=parsed.doubleValue;
    if(!parsed||value<0||value>100){[self reportInputError:@"Enter opacity from 0 to 100 percent." field:sender];return;}[self.editedFields removeObject:sender];self.invalidField=nil;[self applyColor:[self.selectedColor copyWithAlpha:value/100] notify:YES];
}
// BINMAP-ADAPT: UIColorPanelViewController.done:
- (void)done:(id)sender {if(![self commitPendingEdits])return;[self.view endEditing:YES];[self endTransientInteractionsForClose:YES];_sampling=NO;self.sampleOriginalColor=nil;if([self.delegate respondsToSelector:@selector(colorPanelDidFinish:)])[self.delegate colorPanelDidFinish:self];else[self dismissViewControllerAnimated:YES completion:nil];}
// BINMAP-ADAPT: UIColorPanelViewController.makeSwatch:index:pencil:
- (UIButton *)makeSwatch:(UIColorValue *)color index:(NSUInteger)index pencil:(BOOL)pencil {
    UIColorPanelColorWell *button=[UIColorPanelColorWell buttonWithType:UIButtonTypeCustom];button.color=color;button.tag=index;button.layer.cornerRadius=0;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:pencil?72:44].active=YES;
    button.pencil=pencil;
    return button;
}
// BINMAP-ADAPT: UIColorPanelViewController.paletteChanged:
- (void)paletteChanged:(UISegmentedControl *)sender {self.paletteIndex=sender.selectedSegmentIndex;[self buildMode];[self updateControls];}
// BINMAP-ADAPT: UIColorPanelViewController.swatchSelected:
- (void)swatchSelected:(UIButton *)sender {
    UIColorPalette *palette=nil;if(self.mode==UIColorPanelModePalettes)palette=self.palettes[self.paletteIndex];else for(UIColorPalette *p in self.palettes)if([p.name isEqual:@"Crayons"]){palette=p;break;}
    if(sender.tag<(NSInteger)palette.colors.count){self.selectionLabel.text=palette.names[sender.tag];[self applyColor:palette.colors[sender.tag] notify:YES];
        for(UIStackView *row in self.workspace.arrangedSubviews)if([row isKindOfClass:UIStackView.class])for(UIView *view in row.arrangedSubviews)if([view isKindOfClass:UIColorPanelColorWell.class]){UIButton *b=(UIButton *)view;b.selected=b==sender;b.accessibilityTraits=UIAccessibilityTraitButton|(b.selected?UIAccessibilityTraitSelected:0);[b setNeedsDisplay];}
    }
}
// BINMAP-ADAPT: UIColorPanelViewController.saveColor:
- (void)saveColor:(id)sender {
    NSError *error;if(![self.selectedColor propertyListRepresentationWithError:&error]){[self showError:error.localizedDescription];return;}
    if([self.swatchesView saveCurrentColor])UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"Color saved"]);
}
// BINMAP-ADAPT: UIColorPanelViewController.importImage:
- (void)importImage:(UIButton *)sender {
    UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeImport];
    picker.delegate=self;picker.allowsMultipleSelection=NO;picker.modalPresentationStyle=UIModalPresentationFormSheet;
    [self presentViewController:picker animated:YES completion:nil];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-IMPORT-01 manifest=reimpl/color_model_extras.json
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url=urls.firstObject;BOOL scoped=url?[url startAccessingSecurityScopedResource]:NO;
    NSError *error=nil;NSData *data=nil;
    @try{if(url)data=[NSData dataWithContentsOfURL:url options:0 error:&error];}
    @finally{if(scoped)[url stopAccessingSecurityScopedResource];}
    UIImage *image=data?[UIImage imageWithData:data]:nil;
    [controller dismissViewControllerAnimated:YES completion:^{
        // BINMAP-ADAPT-BLOCK: parent=BINMAP-ADAPT-IMPORT-01 UIKit dismissal completion.
        if(![self isTransientPresentationCurrent:controller])return;
        if(!image){[self showError:error.localizedDescription?:@"Choose an image file that iOS can open."];return;}
        self.paletteImage=image;self->_sampling=NO;self.sampleOriginalColor=nil;[self buildMode];[self updateControls];
    }];
}
// BINMAP-ADAPT: id=BINMAP-ADAPT-IMPORT-02 manifest=reimpl/color_model_extras.json
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}
// BINMAP-ADAPT: UIColorPanelViewController.imageChanged:
- (void)imageChanged:(UIColorPickerUserView *)sender {[self applySourceColor:sender.sampledColor notify:YES];}
// BINMAP-ADAPT: UIColorPanelViewController.spectrumChanged: manifest=reimpl/discrete_spectrum_host_api_manifest.json
- (void)spectrumChanged:(UIColorPickerSpectrum *)sender {[self applySourceColor:sender.sampledColor notify:YES];}
// BINMAP-ADAPT: UIColorPanelViewController.gridChanged: manifest=reimpl/discrete_spectrum_host_api_manifest.json
- (void)gridChanged:(UIColorPickerGridView *)sender {[self applySourceColor:sender.sampledColor notify:YES];}
// BINMAP-ADAPT: UIColorPanelViewController.samplePressed:event: manifest=reimpl/native_preview_api_manifest.json
- (void)samplePressed:(UIButton *)sender event:(UIEvent *)event {
    if(self.configuration.use_spi&&[UIEyedropperViewController supportsSystemCapture]){[self sample:sender];UITouch *touch=event.allTouches.anyObject;if(self.ownsSamplingSurface&&touch)self.pendingSamplingPoint=[NSValue valueWithCGPoint:[touch locationInView:self.view.window]];}
}
// BINMAP-ADAPT: UIColorPanelViewController.sampleDragged:event: manifest=reimpl/native_preview_api_manifest.json
- (void)sampleDragged:(UIButton *)sender event:(UIEvent *)event {
    UIEyedropperViewController *picker=self.activeSamplingController;UITouch *touch=event.allTouches.anyObject;
    if(self.ownsSamplingSurface&&touch)self.pendingSamplingPoint=[NSValue valueWithCGPoint:[touch locationInView:self.view.window]];
    if(picker.liveSystemSampling&&touch)[picker moveToPoint:[touch locationInView:picker.view]];
}
// BINMAP-ADAPT: UIColorPanelViewController.sampleReleased:event: manifest=reimpl/native_preview_api_manifest.json
- (void)sampleReleased:(UIButton *)sender event:(UIEvent *)event {
    // Native button-up enters floating mode; a new lens tap confirms the color.
    if(self.configuration.use_spi&&[UIEyedropperViewController supportsSystemCapture]){UITouch *touch=event.allTouches.anyObject;if(touch.phase==UITouchPhaseCancelled){[self invalidateSamplingSession];return;}if(self.ownsSamplingSurface&&touch)self.pendingSamplingPoint=[NSValue valueWithCGPoint:[touch locationInView:self.view.window]];if(!event&&!self.activeSamplingController)[self sample:sender];return;}
    UITouch *touch=event.allTouches.anyObject;if(touch.phase==UITouchPhaseCancelled)return;if(!touch||CGRectContainsPoint(sender.bounds,[touch locationInView:sender]))[self sample:sender];
}
// BINMAP-ADAPT: UIColorPanelViewController.sample:
- (void)sample:(id)sender {
    BOOL systemSampler=self.configuration.use_spi&&[UIEyedropperViewController supportsSystemCapture];
    if(UICOLORPANEL_ENABLE_PRIVATE_API&&self.configuration.use_spi&&!systemSampler)return;
    UIWindow *window=self.view.window;
    if((!systemSampler&&!self.configuration.allowsApplicationSampling)||self.presentedViewController||!self.sampleButton.enabled||self.ownsSamplingSurface||self.activeSamplingController||!window||window.hidden)return;
    if([UIPanel panelForWindow:window]&&(![UIPanel panelForWindow:window].visible||[UIPanel panelForWindow:window].transitioning))return;
    if(![self prepareForTransientPresentation])return;
    [self invalidateSamplingSession];NSUInteger generation=self.samplingGeneration;
    self.pendingSamplingPoint=[NSValue valueWithCGPoint:[self.sampleButton convertPoint:CGPointMake(CGRectGetMidX(self.sampleButton.bounds),CGRectGetMidY(self.sampleButton.bounds)) toView:window]];
    __weak typeof(self) weakSelf=self;__weak id priorDelegate=self.delegate;
    UIColorPanel *panel=[self.delegate isKindOfClass:UIColorPanel.class]?(UIColorPanel *)self.delegate:nil;
    __weak UIColorPanel *weakPanel=panel;__weak id priorTarget=panel.target;BOOL hadTarget=panel.target!=nil;SEL priorAction=panel.action;
    self.samplingIdentityValid=^BOOL{
        UIColorPanelViewController *controller=weakSelf;UIColorPanel *shared=weakPanel;UIWindow *current=controller.viewIfLoaded.window;
        UIEyedropperViewController *active=controller.activeSamplingController;
        BOOL covered=active&&[controller isTransientPresentationCurrent:active]&&active.viewIfLoaded.window==window;
        if(!controller||controller.samplingGeneration!=generation||controller.delegate!=priorDelegate||(!covered&&current!=window)||window.hidden||controller.isBeingDismissed||controller.navigationController.isBeingDismissed)return NO;
        if([UIPanel panelForWindow:window]&&![UIPanel panelForWindow:window].visible)return NO;
        if(shared&&(shared.target!=priorTarget||(hadTarget&&!priorTarget)||shared.action!=priorAction))return NO;
        if(UIApplication.sharedApplication.applicationState!=UIApplicationStateActive)return NO;
        if(@available(iOS 13.0,*))if(window.windowScene&&window.windowScene.activationState!=UISceneActivationStateForegroundActive)return NO;
        return YES;
    };
    if(systemSampler){
        UIScreen *screen=window.screen?:UIScreen.mainScreen;
        UIView *surface=[UIPanel panelForWindow:window]?window:(self.navigationController.view?:self.view);
        self.samplingSurface=surface;
        // The owned UIWindow carries visual opacity independently of panel color alpha.
        self.samplingSurfaceAlpha=surface.alpha;self.samplingSurfaceOpacity=surface.layer.opacity;
        self.samplingSurfaceGeneration=generation;self.ownsSamplingSurface=YES;
        // Lift the live presenter above UIKit's sheet dimming/scale. Full-screen
        // presentations can instead leave this view detached on iOS12.
        UIViewController *presenter=(self.navigationController?:self).presentingViewController;
        UIView *underlay=presenter.viewIfLoaded;
        if(surface!=window&&underlay){
            self.samplingUnderlay=underlay;self.samplingUnderlayWindow=window;
            self.samplingUnderlaySuperview=underlay.superview;self.samplingUnderlayIndex=[underlay.superview.subviews indexOfObjectIdenticalTo:underlay];
            self.samplingUnderlayBounds=underlay.bounds;self.samplingUnderlayCenter=underlay.center;self.samplingUnderlayTransform=underlay.transform;self.samplingUnderlayTintMode=underlay.tintAdjustmentMode;
            underlay.transform=CGAffineTransformIdentity;[window addSubview:underlay];
            underlay.frame=window.bounds;underlay.tintAdjustmentMode=UIViewTintAdjustmentModeNormal;[underlay layoutIfNeeded];
        }
        surface.alpha=0;[CATransaction flush];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.1*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ // BINMAP-ADAPT-BLOCK: generation-scoped compositor wait.
            UIColorPanelViewController *controller=weakSelf;UIEyedropperViewController *picker=nil;
            @try{if(controller.samplingGeneration==generation&&controller.samplingIdentityValid&&controller.samplingIdentityValid()&&controller.configuration.use_spi&&!controller.presentedViewController)picker=[[UIEyedropperViewController alloc]initWithSystemScreen:screen useSPI:YES];}
            @finally{if(!picker.liveSystemSampling)[controller restoreSamplingSurfaceForGeneration:generation];}
            if(picker&&controller.samplingGeneration==generation&&controller.samplingIdentityValid&&controller.samplingIdentityValid()&&!controller.presentedViewController)[controller presentSamplingController:picker];
            else if(controller.samplingGeneration==generation)[controller invalidateSamplingSession];
        });return;
    }
    UIImage *image=self.configuration.samplingImage;UIView *source=self.configuration.samplingSourceView;
    UIEyedropperViewController *picker=image?[[UIEyedropperViewController alloc]initWithImage:image]:(source?[[UIEyedropperViewController alloc]initWithSourceView:source]:nil);
    [self presentSamplingController:picker];
}
// BINMAP-ADAPT: UIColorPanelViewController.presentSamplingController: manifest=reimpl/ui_corrections_extras.json
- (void)presentSamplingController:(UIEyedropperViewController *)picker {
    if(!picker){[self invalidateSamplingSession];[self.view setNeedsLayout];[self showError:[UIColorPanelAppearance localizedString:@"Sampling is unavailable"]];return;}
    picker.use_spi=self.configuration.use_spi;
    if(!picker.samplingAvailable){[self invalidateSamplingSession];[self showError:picker.sampleError.localizedDescription?:[UIColorPanelAppearance localizedString:@"Sampling is unavailable"]];return;}
    NSUInteger generation=self.samplingGeneration,transient=self.transientGeneration;
    self.activeSamplingController=picker;__weak typeof(self) weakSelf=self;__weak UIEyedropperViewController *weakPicker=picker;
    picker.completionHandler=^(UIColorValue *color){
        UIColorPanelViewController *controller=weakSelf;UIEyedropperViewController *active=weakPicker;
        if(!controller||controller.activeSamplingController!=active||controller.samplingGeneration!=generation)return;
        BOOL valid=controller.samplingIdentityValid&&controller.samplingIdentityValid();
        // An ancestor may already be dismissing the fullscreen picker. UIKit12
        // need not deliver another dismissal completion for that same picker.
        if(!valid){[controller endTransientInteractionsForClose:NO];return;}
        controller.activeSamplingController=nil;active.completionHandler=nil;
        if(active.liveSystemSampling){
            [active dismissLiveWithCompletion:^{
                if(controller.samplingGeneration!=generation||controller.transientGeneration!=transient)return;
                [controller restoreSamplingSurfaceForGeneration:generation];
                if(color&&controller.samplingIdentityValid&&controller.samplingIdentityValid())[controller performAnimatedColorUpdates:^{[controller applySourceColor:color notify:YES];} expectedColor:color];
                if(controller.samplingGeneration!=generation||controller.transientGeneration!=transient)return;
                [controller.transientPresentations removeObject:active];[controller invalidateSamplingSession];
                if(active.sampleError)[controller showError:active.sampleError.localizedDescription];
                else UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,controller.sampleButton);
            }];return;
        }
        if(!color){
            // Cancellation owns no color to submit. Release it immediately,
            // including when an ancestor has already begun removing the picker.
            [controller.transientPresentations removeObject:active];
            [controller invalidateSamplingSession];NSUInteger resolved=controller.samplingGeneration;
            [active dismissViewControllerAnimated:YES completion:^{
                if(controller.samplingGeneration==resolved&&controller.transientGeneration==transient&&controller.sampleButton.window&&!controller.sampleButton.window.hidden)
                    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,controller.sampleButton);
            }];return;
        }
        [active dismissViewControllerAnimated:YES completion:^{
            if(controller.samplingGeneration!=generation||controller.transientGeneration!=transient)return;
            if(valid&&controller.samplingIdentityValid&&controller.samplingIdentityValid()){
                if(color)[controller performAnimatedColorUpdates:^{[controller applySourceColor:color notify:YES];} expectedColor:color];
                // Host callbacks may synchronously start another sampling session.
                if(controller.samplingGeneration!=generation||controller.transientGeneration!=transient)return;
                if(controller.sampleButton.window&&!controller.sampleButton.window.hidden)UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,controller.sampleButton);
            }
            [controller invalidateSamplingSession];
        }];
    };
    if(picker.liveSystemSampling){
        [self registerTransientPresentation:picker];[picker presentLiveFromViewController:self];
        if(self.activeSamplingController==picker)[picker moveToPoint:[self.view.window convertPoint:self.pendingSamplingPoint.CGPointValue toView:picker.view]];
    }else{picker.modalPresentationStyle=UIModalPresentationFullScreen;[self presentViewController:picker animated:YES completion:nil];}
}
// BINMAP-ADAPT: UIColorPanelViewController.cancelSample:
- (void)cancelSample:(id)sender {
    UIColorValue *original=self.sampleOriginalColor;UIColorPanelMode priorMode=self.sampleOriginalMode;
    _sampling=NO;self.sampleOriginalColor=nil;self.mode=priorMode;[self buildMode];
    if(original)[self applyColor:original notify:YES];else[self updateControls];
}
// BINMAP-ADAPT: UIColorPanelViewController.grayShortcut:
- (void)grayShortcut:(UIButton *)sender {
    CGFloat values[]={sender.tag/4.0,1};UIColorPanelColorProfile *profile=[self profileForMode:UIColorPanelModeGray];CGColorSpaceRef space=profile?profile.CGColorSpace:NULL;CGColorRef cg=space?CGColorCreate(space,values):NULL;if(cg){[self applyColor:[[UIColorValue alloc]initWithCGColor:cg] notify:YES];CGColorRelease(cg);}
}
// BINMAP-ADAPT: UIColorPanelViewController.paletteSearchChanged:
- (void)paletteSearchChanged:(UITextField *)sender {
    NSString *query=[sender.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    for(UIView *view in self.workspace.arrangedSubviews)if([view isKindOfClass:UIStackView.class]){UIStackView *row=(UIStackView *)view;BOOL visible=NO;
        for(UIView *child in row.arrangedSubviews)if([child isKindOfClass:UIColorPanelColorWell.class]){BOOL match=!query.length||[child.accessibilityLabel rangeOfString:query options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location!=NSNotFound;child.hidden=!match;visible|=match;}row.hidden=!visible;
    }
}
// BINMAP-ADAPT: UIColorPanelViewController.showError:
- (void)showError:(NSString *)message {
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Unable to Change Color"] message:[UIColorPanelAppearance localizedString:message] preferredStyle:UIAlertControllerStyleAlert];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"OK"] style:UIAlertActionStyleDefault handler:nil]];if(!self.presentedViewController)[self presentViewController:alert animated:YES completion:nil];
}
// BINMAP-ADAPT: UIColorPanelViewController.attachColorList: — retain pre-load attachments and forward name identity to the catalog provider.
- (void)attachColorList:(UIColorList *)colorList {
    if(!self.attachedColorLists)self.attachedColorLists=[NSMutableDictionary dictionary];self.attachedColorLists[colorList.name]=colorList;
    [self.catalogController attachColorList:colorList];
}
// BINMAP-ADAPT: UIColorPanelViewController.detachColorList: — detach only the attached identity, or remove a file-backed catalog through the provider.
- (void)detachColorList:(UIColorList *)colorList {
    BOOL attached=self.attachedColorLists[colorList.name]!=nil;[self.attachedColorLists removeObjectForKey:colorList.name];
    if(self.catalogController)[self.catalogController detachColorList:colorList];else if(!attached)[colorList removeFile];
}
// BINMAP-ADAPT: UIColorPanelViewController.colorPickerCatalog:didSelectColorValue: — named colors use the same canonical selection route.
- (void)colorPickerCatalog:(UIColorPickerCatalogController *)catalog didSelectColorValue:(UIColorValue *)color {
    [self applySourceColor:color notify:YES];
    // Native table selection requests panel.setColor: without replacing panel state.
    // A callback made during action dispatch may be rejected by its suppression guard.
    if([self.delegate isKindOfClass:UIColorPanel.class])self.selectedColor=[(UIColorPanel *)self.delegate colorValue];
}
// BINMAP-ADAPT: UIColorPanelViewController.colorPickerCatalogDidChangeLists: — the catalog retains and persists its managed list collection.
- (void)colorPickerCatalogDidChangeLists:(UIColorPickerCatalogController *)catalog { }
// BINMAP-ADAPT: UIColorPanelViewController.colorPickerImagePalette:didSelectImage: — image selection replaces the sampler source without changing the current color.
- (void)colorPickerImagePalette:(UIColorPickerImagePaletteController *)picker didSelectImage:(UIImage *)image { self.paletteImage=image;if(self.mode==UIColorPanelModeCustomPalette){[self buildMode];[self updateControls];} }
// BINMAP-ADAPT: UIColorPanelViewController.colorPickerSwatches:didSelectColorValue: — fixed-slot favorites share the canonical editing path.
- (void)colorPickerSwatches:(UIColorPickerSwatchesView *)view didSelectColorValue:(UIColorValue *)color { [self applySourceColor:color notify:YES];[self updateFavoritesSummary]; }
// BINMAP-ADAPT: UIColorPanelViewController.showSavedColors: manifest=reimpl/polish_shell_extras.json
- (void)showSavedColors:(id)sender {
    if([sender isKindOfClass:UILongPressGestureRecognizer.class]&&[(UIGestureRecognizer *)sender state]!=UIGestureRecognizerStateBegan)return;
    if(self.presentedViewController||![self prepareForTransientPresentation])return;

    id focusTarget=[sender isKindOfClass:UIGestureRecognizer.class]?[(UIGestureRecognizer *)sender view]:sender;
    if(focusTarget==self.savedColorsItem){
        id focused=UIAccessibilityFocusedElement(UIAccessibilityNotificationVoiceOverIdentifier);
        if([focused respondsToSelector:@selector(accessibilityIdentifier)]&&
           [[focused accessibilityIdentifier] isEqualToString:self.savedColorsItem.accessibilityIdentifier])focusTarget=focused;
    }
    NSString *identifier=[focusTarget respondsToSelector:@selector(accessibilityIdentifier)]?[focusTarget accessibilityIdentifier]:nil;
    NSString *slotPrefix=@"ui.saved.slot.";
    BOOL returnsToSwatch=[identifier hasPrefix:slotPrefix]||[identifier isEqualToString:@"ui.saved.add"];
    NSNumber *slot=[identifier hasPrefix:slotPrefix]?@([[identifier substringFromIndex:slotPrefix.length] integerValue]):nil;
    if(returnsToSwatch)focusTarget=nil; // Changing presentation replaces reusable cells.

    self.nativeFavoritesHeight.active=NO;self.swatchesView.usesNativePickerPresentation=NO;
    UIColorPanelSavedColorsController *manager=[[UIColorPanelSavedColorsController alloc]initWithSwatchesView:self.swatchesView];
    self.savedColorsController=manager;
    __weak typeof(self) weakSelf=self;
    __weak UIColorPanelSavedColorsController *weakManager=manager;
    manager.restorationHandler=^{
        UIColorPanelViewController *controller=weakSelf;
        if(!weakManager||controller.savedColorsController!=weakManager)return;
        [controller restoreSavedColors];
        if(!controller.view.window)return;
        [controller.view layoutIfNeeded];

        id target=focusTarget?:controller.currentWell;
        if(returnsToSwatch&&controller.swatchesView.favoritesEditable){
            UIColorPickerSwatchesView *swatches=controller.swatchesView;
            UICollectionView *collection=swatches.collectionView;
            NSUInteger count=swatches.presentedColors.count;
            NSUInteger index=slot?0:count;
            while(index<count&&[swatches storeIndexForColorIndex:index]!=slot.integerValue)index++;
            NSIndexPath *path=[NSIndexPath indexPathForItem:index inSection:0];
            if(![collection.indexPathsForVisibleItems containsObject:path]){
                CGRect frame=[collection layoutAttributesForItemAtIndexPath:path].frame;
                [collection scrollRectToVisible:frame animated:NO];
                [collection layoutIfNeeded];
            }
            target=[collection cellForItemAtIndexPath:path];
        }
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,target);
    };
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:manager];navigation.modalPresentationStyle=UIModalPresentationFormSheet;[self presentViewController:navigation animated:YES completion:nil];
}
// BINMAP-ADAPT: UIColorPanelViewController.restoreSavedColors manifest=reimpl/polish_shell_extras.json
- (void)restoreSavedColors {
    [self.swatchesView cancelPendingDrops];
    self.swatchesView.logicalScale=1;self.swatchesView.usesNativePickerPresentation=YES;self.swatchesView.userInteractionEnabled=YES;self.swatchesView.accessibilityElementsHidden=NO;self.swatchesView.hidden=NO;[self.favoritesRow addArrangedSubview:self.swatchesView];self.nativeFavoritesHeight.active=YES;self.savedColorsController=nil;[self updateFavoritesSummary];[self.view setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelViewController.accessibilityManageSavedColors: manifest=reimpl/native_preview_api_manifest.json
- (BOOL)accessibilityManageSavedColors:(UIAccessibilityCustomAction *)action {[self showSavedColors:self.currentWell];return YES;}
// BINMAP-ADAPT: UIColorPanelViewController.updateFavoritesSummary manifest=reimpl/polish_shell_extras.json
- (void)updateFavoritesSummary {
    [self.savedColorsButton setTitle:[UIColorPanelAppearance localizedString:@"Saved colors"] forState:UIControlStateNormal];self.savedColorsButton.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Open saved colors"];self.savedColorsButton.accessibilityHint=[UIColorPanelAppearance localizedString:@"Choose and manage saved colors"];self.savedColorsButton.accessibilityValue=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Saved colors, %lu colors"],(unsigned long)self.swatchesView.presentedColors.count];[self.savedColorsController refreshActions];
    self.savedColorsItem.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Manage Saved Colors"];self.savedColorsItem.accessibilityHint=self.savedColorsButton.accessibilityHint;self.savedColorsItem.accessibilityValue=self.savedColorsButton.accessibilityValue;
}
// BINMAP-ADAPT: UIColorPanelViewController.traitCollectionDidChange: manifest=reimpl/polish_shell_extras.json
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];if(!self.isViewLoaded||!self.workspace)return;
    for(UILabel *label in self.ownedLabels.allObjects)label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    UIFontDescriptor *componentFont=[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote compatibleWithTraitCollection:self.traitCollection];componentFont=[componentFont fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightSemibold)}}];
    for(UILabel *label in self.componentLabels.allObjects)label.font=[UIFont fontWithDescriptor:componentFont size:0];
    NSMutableArray *fields=[self.componentFields mutableCopy]?:[NSMutableArray new];if(self.hexField)[fields addObject:self.hexField];if(self.opacityField)[fields addObject:self.opacityField];
    for(UITextField *field in fields)[self.fieldContainers[@(field.tag)] refreshFont];
    self.pencilNameLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    self.savedColorsButton.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];
    self.footer.backgroundColor=self.view.backgroundColor;self.opacityRow.backgroundColor=self.view.backgroundColor;[self.view setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelViewController.prepareForTransientPresentation manifest=reimpl/ui_ux_repairs_extras.json
- (BOOL)prepareForTransientPresentation {
    if(self.endingTransientInteractions||self.isBeingDismissed||self.navigationController.isBeingDismissed)return NO;
    UIWindow *window=self.viewIfLoaded.window;
    if([UIPanel panelForWindow:window]&&![UIPanel panelForWindow:window].visible)return NO;
    NSUInteger generation=self.transientGeneration,profileGeneration=self.profileGeneration;
    if(![self commitPendingEdits])return NO;
    if(generation!=self.transientGeneration||profileGeneration!=self.profileGeneration||self.endingTransientInteractions)return NO;
    [self.view endEditing:YES];
    // Editing-end observers are application callbacks too; they may close the
    // panel or replace its source after the dirty-field commit has finished.
    if(generation!=self.transientGeneration||profileGeneration!=self.profileGeneration||self.endingTransientInteractions||self.isBeingDismissed||self.navigationController.isBeingDismissed)return NO;
    if([UIPanel panelForWindow:window]&&![UIPanel panelForWindow:window].visible)return NO;
    return YES;
}
// BINMAP-ADAPT: UIColorPanelViewController.registerTransientPresentation: manifest=reimpl/ui_ux_repairs_extras.json
- (void)registerTransientPresentation:(UIViewController *)controller {
    if(!self.transientPresentations)self.transientPresentations=[NSHashTable weakObjectsHashTable];
    [self.transientPresentations addObject:controller];
}
// BINMAP-ADAPT: UIColorPanelViewController.isTransientPresentationCurrent: manifest=reimpl/ui_ux_repairs_extras.json
- (BOOL)isTransientPresentationCurrent:(UIViewController *)controller {
    return !self.endingTransientInteractions&&[self.transientPresentations containsObject:controller];
}
// BINMAP-ADAPT: UIColorPanelViewController.presentViewController:animated:completion: manifest=reimpl/ui_ux_repairs_extras.json
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
    if(self.endingTransientInteractions)return;
    if(controller!=self.inputErrorAlert&&![self prepareForTransientPresentation])return;
    if(self.presentedViewController&&!self.presentedViewController.isBeingDismissed)return;
    [self registerTransientPresentation:controller];
    [super presentViewController:controller animated:animated completion:completion];
}
// BINMAP-ADAPT: UIColorPanelViewController.restoreSamplingSurfaceForGeneration: manifest=reimpl/ui_ux_repairs_extras.json
- (void)restoreSamplingSurfaceForGeneration:(NSUInteger)generation {
    if(!self.ownsSamplingSurface||self.samplingSurfaceGeneration!=generation)return;
    UIView *surface=self.samplingSurface;self.ownsSamplingSurface=NO;self.samplingSurface=nil;
    [CATransaction begin];[CATransaction setDisableActions:YES];
    UIView *underlay=self.samplingUnderlay,*parent=self.samplingUnderlaySuperview;UIWindow *underlayWindow=self.samplingUnderlayWindow;
    self.samplingUnderlay=nil;self.samplingUnderlayWindow=nil;self.samplingUnderlaySuperview=nil;
    if(underlay&&underlay.superview==underlayWindow){
        [underlay removeFromSuperview];
        if(parent)[parent insertSubview:underlay atIndex:MIN(self.samplingUnderlayIndex,parent.subviews.count)];
        underlay.transform=CGAffineTransformIdentity;underlay.bounds=self.samplingUnderlayBounds;underlay.center=self.samplingUnderlayCenter;underlay.transform=self.samplingUnderlayTransform;underlay.tintAdjustmentMode=self.samplingUnderlayTintMode;
    }
    surface.alpha=self.samplingSurfaceAlpha;surface.layer.opacity=self.samplingSurfaceOpacity;[CATransaction commit];
    self.sampleButton.enabled=YES;[CATransaction flush];
}
// BINMAP-ADAPT: UIColorPanelViewController.invalidateSamplingSession manifest=reimpl/ui_ux_repairs_extras.json
- (void)invalidateSamplingSession {
    [self restoreSamplingSurfaceForGeneration:self.samplingGeneration];++self.samplingGeneration;
    self.samplingIdentityValid=nil;self.pendingSamplingPoint=nil;
    UIEyedropperViewController *picker=self.activeSamplingController;self.activeSamplingController=nil;
    picker.completionHandler=nil;
    if(picker){[picker cancel];if(picker.liveSystemSampling)[picker dismissLiveWithCompletion:nil];else if(picker.presentingViewController)[picker dismissViewControllerAnimated:NO completion:nil];}
    self.sampleButton.enabled=YES;
}
// BINMAP-ADAPT: UIColorPanelViewController.endTransientInteractionsForClose: manifest=reimpl/ui_ux_repairs_extras.json
- (void)endTransientInteractionsForClose:(BOOL)closing {
    if(self.endingTransientInteractions)return;
    self.endingTransientInteractions=YES;++self.transientGeneration;
    [self cancelControlTrackingInView:nil];
    [self.editedFields removeAllObjects];self.invalidField=nil;[self.viewIfLoaded endEditing:YES];
    [self invalidateSamplingSession];[self.swatchesView cancelPendingDrops];++self.profileGeneration;[self.profileLibrary cancelPendingDiscovery];
    NSArray *owned=self.transientPresentations.allObjects;[self.transientPresentations removeAllObjects];self.inputErrorAlert=nil;
    for(UIViewController *controller in owned)if(controller.presentingViewController&&!controller.isBeingDismissed)[controller dismissViewControllerAnimated:NO completion:nil];
    if(self.savedColorsController){self.savedColorsController.restorationHandler=nil;[self restoreSavedColors];}
    _keyboardFrame=CGRectNull;_sampling=NO;self.sampleOriginalColor=nil;self.endingTransientInteractions=NO;
    [self updateControls];[self.viewIfLoaded setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelViewController.applicationDeactivated: manifest=reimpl/ui_ux_repairs_extras.json
- (void)applicationDeactivated:(NSNotification *)notification {
    if(@available(iOS 13.0,*))if([notification.object isKindOfClass:UIWindowScene.class]&&notification.object!=(self.viewIfLoaded.window?:self.activeSamplingController.viewIfLoaded.window).windowScene)return;
    [self invalidateSamplingSession];
}
// BINMAP-ADAPT: UIColorPanelViewController.viewDidDisappear: manifest=reimpl/ui_ux_repairs_extras.json
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // A fullscreen picker covers this VC too; only a true host dismissal ends its session.
    if(self.isBeingDismissed||self.navigationController.isBeingDismissed)[self endTransientInteractionsForClose:YES];
}
// BINMAP-ADAPT: UIColorPanelViewController.use_spi manifest=reimpl/ui_corrections_extras.json
- (BOOL)use_spi {return self.configuration.use_spi;}
// BINMAP-ADAPT: UIColorPanelViewController.setUse_spi: manifest=reimpl/ui_corrections_extras.json
- (void)setUse_spi:(BOOL)value {
    self.configuration.use_spi=value;
#if UICOLORPANEL_ENABLE_PRIVATE_API
    if(self.swatchesView && _favoritesUseSPI != value) [self configureFavoritesStore];
#endif
    if(!value)[self invalidateSamplingSession];++self.profileGeneration;[self updateProfileMenus];[self refreshColorProfiles];
#if UICOLORPANEL_ENABLE_PENCILS
    self.pencilsPicker.pencilView.use_spi=value;[self.pencilsPicker.pencilView setNeedsLayout];
#endif
    [self.viewIfLoaded setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelViewController.allowsApplicationSampling manifest=reimpl/polish_shell_extras.json
- (BOOL)allowsApplicationSampling {return self.configuration.allowsApplicationSampling;}
// BINMAP-ADAPT: UIColorPanelViewController.setAllowsApplicationSampling: manifest=reimpl/polish_shell_extras.json
- (void)setAllowsApplicationSampling:(BOOL)value {self.configuration.allowsApplicationSampling=value;[self.view setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanelViewController.samplingSourceView manifest=reimpl/polish_shell_extras.json
- (UIView *)samplingSourceView {return self.configuration.samplingSourceView;}
// BINMAP-ADAPT: UIColorPanelViewController.setSamplingSourceView: manifest=reimpl/polish_shell_extras.json
- (void)setSamplingSourceView:(UIView *)view {self.configuration.samplingSourceView=view;[self.view setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanelViewController.samplingImage manifest=reimpl/polish_shell_extras.json
- (UIImage *)samplingImage {return self.configuration.samplingImage;}
// BINMAP-ADAPT: UIColorPanelViewController.setSamplingImage: manifest=reimpl/polish_shell_extras.json
- (void)setSamplingImage:(UIImage *)image {self.configuration.samplingImage=image;[self.view setNeedsLayout];}

// BINMAP-ADAPT: UIColorPanelViewController.colorPickerSwatchesDidChangeSlots: manifest=reimpl/polish_shell_extras.json
- (void)colorPickerSwatchesDidChangeSlots:(UIColorPickerSwatchesView *)view {[self updateFavoritesSummary];}

@end
