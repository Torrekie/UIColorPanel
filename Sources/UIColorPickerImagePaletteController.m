#import "UIColorPickerImagePaletteController.h"
#import "UIColorPanelMenuButton.h"
#import "UIColorPanelChoiceController.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelLifecycle.h"
#import <math.h>
static NSNotificationName const UIColorPickerImagePalettesDidChangeNotification=@"UIColorPickerImagePalettesDidChangeNotification";
@interface UIColorPickerImagePaletteController () <UIDocumentPickerDelegate>
@property(nonatomic, weak) id<UIColorPanelTransientOwner> documentOwner;
@property(nonatomic, weak) UIDocumentPickerViewController *documentPresentation;
@property(nonatomic) BOOL documentOwnedPresentation;
@property(nonatomic) BOOL documentResultConsumed;
@property(nonatomic, strong) UIImage *spectrum;
@property(nonatomic, strong, readwrite) UIImage *currentImage;
@property(nonatomic, strong) NSURL *directoryURL;
@property(nonatomic, copy) NSArray<NSDictionary *> *palettes;
@property(nonatomic) NSInteger selectedIndex;
@property(nonatomic, strong) UIColorPanelMenuButton *chooseButton;
@property(nonatomic, strong) UIColorPanelMenuButton *manageButton;
@property(nonatomic, strong) UIStackView *headerStack;
- (NSArray<NSDictionary *> *)readMetadata;
- (void)refreshMetadata;
- (NSUInteger)indexForPaletteFile:(NSString *)file;
- (void)selectPaletteWithFile:(NSString *)file;
- (void)renamePaletteWithFile:(NSString *)file;
- (void)removePaletteWithFile:(NSString *)file;
- (UIMenu *)menuForImagePalettes API_AVAILABLE(ios(13.0));
- (UIMenu *)menuForImagePaletteActions API_AVAILABLE(ios(13.0));
@end
@implementation UIColorPickerImagePaletteController
// BINMAP-ADAPT: UIColorPickerImagePaletteController.defaultSpectrumImage manifest=reimpl/discrete_spectrum_host_api_manifest.json
+ (UIImage *)defaultSpectrumImage {
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // The AppKit image-palette reference is an opaque 612 × 152 sRGB bitmap.
        // Its horizontal channel envelopes dip slightly below white on the tint
        // side and rise above black on the shade side. Fit both with quartic Béziers.
        enum { width = 612, height = 152 };
        static const unsigned char envelopes[2][5][2] = {
            {{255,255}, {211,240}, {57,206}, {2,252}, {0,255}},
            {{0,255}, {0,255}, {50,203}, {16,47}, {0,0}}
        };
        double low[width], range[width], redOffset[width];
        for (NSUInteger x = 0; x < width; x++) {
            NSUInteger half = x / (width / 2);
            double t = (double)(x % (width / 2)) / (width / 2 - 1), s = 1 - t;
            double weights[5] = {s*s*s*s, 4*s*s*s*t, 6*s*s*t*t, 4*s*t*t*t, t*t*t*t};
            double minimum = 0, maximum = 0;
            for (NSUInteger i = 0; i < 5; i++) {
                minimum += weights[i] * envelopes[half][i][0];
                maximum += weights[i] * envelopes[half][i][1];
            }
            low[x] = minimum;
            range[x] = maximum - minimum;
            // All hues converge on the same warm black (4, 0, 0) at the right edge.
            redOffset[x] = half ? 4*t*t : 0;
        }

        static const double hueRows[] = {0, 24.3, 50.25, 78.6, 101.85, 129.05, 152.05};
        static const unsigned char hues[][3] = {
            {1,0,0}, {1,1,0}, {0,1,0}, {0,1,1}, {0,0,1}, {1,0,1}, {1,0,0}
        };
        NSMutableData *data = [NSMutableData dataWithLength:width * height * 3];
        uint8_t *pixel = data.mutableBytes;
        NSUInteger sector = 0;
        for (NSUInteger y = 0; y < height; y++) {
            if (y >= hueRows[sector + 1]) sector++;
            double t = (y - hueRows[sector]) / (hueRows[sector + 1] - hueRows[sector]);
            // Blend linear interpolation and smoothstep between hue primaries.
            double blend = 0.5 * (t + t*t*(3 - 2*t));
            double hue[3];
            for (NSUInteger c = 0; c < 3; c++)
                hue[c] = hues[sector][c] + blend * (hues[sector + 1][c] - hues[sector][c]);
            for (NSUInteger x = 0; x < width; x++)
                for (NSUInteger c = 0; c < 3; c++)
                    *pixel++ = (uint8_t)lround(low[x] + range[x] * hue[c] + (c == 0 ? redOffset[x] : 0));
        }
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGImageRef bitmap = CGImageCreate(width, height, 8, 24, width * 3, space,
                                          (CGBitmapInfo)kCGImageAlphaNone, provider, NULL, true, kCGRenderingIntentDefault);
        image = [UIImage imageWithCGImage:bitmap];
        CGImageRelease(bitmap);
        CGColorSpaceRelease(space);
        CGDataProviderRelease(provider);
    });
    return image;
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.isBuiltInSpectrumSelected manifest=reimpl/discrete_spectrum_host_api_manifest.json
- (BOOL)isBuiltInSpectrumSelected {return self.selectedIndex==0;}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.presentViewController:animated:completion: manifest=reimpl/ui_ux_repairs_extras.json
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    if(owner){if(![owner prepareForTransientPresentation])return;for(UIViewController *context=self;context;context=context.parentViewController)if(context.presentedViewController&&!context.presentedViewController.isBeingDismissed)return;[owner registerTransientPresentation:controller];}
    if([controller isKindOfClass:UIDocumentPickerViewController.class]){self.documentOwner=owner;self.documentOwnedPresentation=owner!=nil;self.documentPresentation=(id)controller;self.documentResultConsumed=NO;}
    [super presentViewController:controller animated:animated completion:completion];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.initWithSpectrum:
- (instancetype)initWithSpectrum:(UIImage *)spectrum {
    NSParameterAssert(spectrum);if((self=[super initWithNibName:nil bundle:nil])){
        _spectrum=spectrum;_currentImage=spectrum;_selectedIndex=0;
        NSURL *support=[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        _directoryURL=[[support URLByAppendingPathComponent:@"UIColorPanelKit" isDirectory:YES] URLByAppendingPathComponent:@"ImagePalettes" isDirectory:YES];
        _palettes=[self readMetadata];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(imagePalettesDidChange:) name:UIColorPickerImagePalettesDidChangeNotification object:nil];
    }return self;
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.dealloc manifest=reimpl/image_palette_ui_extras.json
- (void)dealloc {[NSNotificationCenter.defaultCenter removeObserver:self name:UIColorPickerImagePalettesDidChangeNotification object:nil];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.readMetadata manifest=reimpl/image_palette_ui_extras.json
- (NSArray<NSDictionary *> *)readMetadata {
    NSData *data=[NSData dataWithContentsOfURL:[self.directoryURL URLByAppendingPathComponent:@"palettes.json"]];id stored=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;NSMutableArray *items=[NSMutableArray arrayWithObject:@{@"name":@"Spectrum",@"builtin":@YES}];
    if([stored isKindOfClass:NSArray.class])for(id entry in stored){if(![entry isKindOfClass:NSDictionary.class])continue;NSString *file=entry[@"file"],*name=entry[@"name"];if([file isKindOfClass:NSString.class]&&[file.lastPathComponent isEqualToString:file]&&[file.pathExtension isEqualToString:@"png"]&&[name isKindOfClass:NSString.class]&&[NSFileManager.defaultManager fileExistsAtPath:[self.directoryURL URLByAppendingPathComponent:file].path])[items addObject:entry];}
    return items;
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.indexForPaletteFile: manifest=reimpl/image_palette_ui_extras.json
// The immutable file name identifies a palette across instances; nil identifies Spectrum.
- (NSUInteger)indexForPaletteFile:(NSString *)file {if(!file)return 0;for(NSUInteger index=1;index<self.palettes.count;index++)if([self.palettes[index][@"file"] isEqualToString:file])return index;return NSNotFound;}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.refreshMetadata manifest=reimpl/image_palette_ui_extras.json
- (void)refreshMetadata {
    NSString *file=self.palettes[self.selectedIndex][@"file"];self.palettes=[self readMetadata];NSUInteger index=[self indexForPaletteFile:file];
    // A metadata rename must not replace the sampler or emit an image-selection callback.
    if(index==NSNotFound)[self selectPaletteAtIndex:0];else{self.selectedIndex=index;[self reloadPalettes];}
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.imagePalettesDidChange: manifest=reimpl/image_palette_ui_extras.json
- (void)imagePalettesDidChange:(NSNotification *)notification {
    if(notification.object==self)return;if(!NSThread.isMainThread){__weak typeof(self) weakSelf=self;dispatch_async(dispatch_get_main_queue(),^{[weakSelf imagePalettesDidChange:notification];});return;}[self refreshMetadata];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.selectPaletteWithFile: manifest=reimpl/image_palette_ui_extras.json
- (void)selectPaletteWithFile:(NSString *)file {[self refreshMetadata];NSUInteger index=[self indexForPaletteFile:file];if(index!=NSNotFound)[self selectPaletteAtIndex:index];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;self.preferredContentSize=CGSizeMake(0,44);
    self.chooseButton=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];self.chooseButton.accessibilityIdentifier=@"ui.image.choose";
    self.manageButton=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];self.manageButton.displaysMoreActions=YES;self.manageButton.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Manage Image Palette"];self.manageButton.accessibilityIdentifier=@"ui.image.manage";
    if(@available(iOS 13.0,*)){__weak typeof(self) weakSelf=self;self.chooseButton.menuProvider=^UIMenu *{return[weakSelf menuForImagePalettes];};self.manageButton.menuProvider=^UIMenu *{return[weakSelf menuForImagePaletteActions];};}
    if(!self.chooseButton.usesPrimaryMenu)[self.chooseButton addTarget:self action:@selector(choosePalette:) forControlEvents:UIControlEventTouchUpInside];
    if(!self.manageButton.usesPrimaryMenu)[self.manageButton addTarget:self action:@selector(showActions:) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *header=[UIColorPanelMenuButton headerWithSelectionButton:self.chooseButton actionsButton:self.manageButton];self.headerStack=header;header.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:header];
    [NSLayoutConstraint activateConstraints:@[[header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[header.topAnchor constraintEqualToAnchor:self.view.topAnchor],[header.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[header.heightAnchor constraintGreaterThanOrEqualToConstant:44],[self.manageButton.widthAnchor constraintEqualToConstant:44]]];[self reloadPalettes];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.viewDidLayoutSubviews — mirror only native header chrome, never image sampling coordinates.
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];UISemanticContentAttribute direction=self.view.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;
    self.headerStack.semanticContentAttribute=direction;self.chooseButton.semanticContentAttribute=direction;self.manageButton.semanticContentAttribute=direction;[self.headerStack setNeedsLayout];[self.headerStack layoutIfNeeded];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.reloadPalettes
- (void)reloadPalettes {NSDictionary *item=self.palettes[self.selectedIndex];NSString *name=[item[@"builtin"]boolValue]?[UIColorPanelAppearance localizedString:@"Spectrum"]:item[@"name"];[self.chooseButton setTitle:name forState:UIControlStateNormal];self.chooseButton.accessibilityLabel=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Image Palette, %@"],name];[self.chooseButton reloadMenu];[self.manageButton reloadMenu];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.menuForImagePalettes — public native menu presentation of the existing image-selection route.
- (UIMenu *)menuForImagePalettes {
    NSMutableArray<UIMenuElement *> *items=[NSMutableArray new];__weak typeof(self) weakSelf=self;
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    BOOL owned=owner!=nil;NSUInteger generation=owner.transientGeneration;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    BOOL (^canPerform)(void)=^BOOL{id<UIColorPanelTransientOwner> currentOwner=weakOwner;return !owned||(currentOwner&&currentOwner.transientGeneration==generation&&[currentOwner prepareForTransientPresentation]);};
    for(NSUInteger index=0;index<self.palettes.count;index++){NSDictionary *palette=self.palettes[index];NSString *file=palette[@"file"];UIAction *action=[UIAction actionWithTitle:[palette[@"builtin"]boolValue]?[UIColorPanelAppearance localizedString:@"Spectrum"]:palette[@"name"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf selectPaletteWithFile:file];}];action.state=index==(NSUInteger)self.selectedIndex?UIMenuElementStateOn:UIMenuElementStateOff;[items addObject:action];}
    return[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Image Palettes"] children:items];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.menuForImagePaletteActions — retain action order, builtin protection and destructive confirmation through public UIMenu.
- (UIMenu *)menuForImagePaletteActions {
    __weak typeof(self) weakSelf=self;
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    BOOL owned=owner!=nil;NSUInteger generation=owner.transientGeneration;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    BOOL (^canPerform)(void)=^BOOL{id<UIColorPanelTransientOwner> currentOwner=weakOwner;return !owned||(currentOwner&&currentOwner.transientGeneration==generation&&[currentOwner prepareForTransientPresentation]);};
    UIAction *create=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"New from File…"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf importImage:action];}];
    NSString *file=self.palettes[self.selectedIndex][@"file"];
    UIAction *rename=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Rename…"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf renamePaletteWithFile:file];}];rename.attributes=file?0:UIMenuElementAttributesDisabled;
    UIAction *remove=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Remove"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf removePaletteWithFile:file];}];remove.attributes=UIMenuElementAttributesDestructive|(file?0:UIMenuElementAttributesDisabled);
    UIAction *copy=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Copy"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf copyPalette:action];}];
    UIAction *paste=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"New from Clipboard"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf pastePalette:action];}];
    return[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Manage Image Palette"] children:@[create,rename,remove,copy,paste]];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.choosePalette:
- (void)choosePalette:(id)sender {
    [self refreshMetadata];NSMutableArray<UIColorPanelChoiceItem *> *items=[NSMutableArray new];__weak typeof(self) weakSelf=self;
    for(NSUInteger index=0;index<self.palettes.count;index++){NSDictionary *palette=self.palettes[index];NSString *name=[palette[@"builtin"]boolValue]?[UIColorPanelAppearance localizedString:@"Spectrum"]:palette[@"name"],*file=palette[@"file"];[items addObject:[UIColorPanelChoiceItem itemWithTitle:name selected:index==(NSUInteger)self.selectedIndex enabled:YES destructive:NO handler:^{[weakSelf selectPaletteWithFile:file];}]];}
    [UIColorPanelChoiceController presentFromViewController:self title:[UIColorPanelAppearance localizedString:@"Image Palettes"] sections:@[[UIColorPanelChoiceSection sectionWithTitle:nil items:items]] sourceView:[sender isKindOfClass:UIView.class]?sender:self.chooseButton];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.showActions:
- (void)showActions:(id)sender {
    [self refreshMetadata];__weak typeof(self) weakSelf=self;NSString *file=self.palettes[self.selectedIndex][@"file"];
    NSArray *items=@[[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"New from File…"] selected:NO enabled:YES destructive:NO handler:^{[weakSelf importImage:nil];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Rename…"] selected:NO enabled:file!=nil destructive:NO handler:^{[weakSelf renamePaletteWithFile:file];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Remove"] selected:NO enabled:file!=nil destructive:YES handler:^{[weakSelf removePaletteWithFile:file];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Copy"] selected:NO enabled:YES destructive:NO handler:^{[weakSelf copyPalette:nil];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"New from Clipboard"] selected:NO enabled:YES destructive:NO handler:^{[weakSelf pastePalette:nil];}]];
    [UIColorPanelChoiceController presentFromViewController:self title:[UIColorPanelAppearance localizedString:@"Manage Image Palette"] sections:@[[UIColorPanelChoiceSection sectionWithTitle:nil items:items]] sourceView:[sender isKindOfClass:UIView.class]?sender:self.manageButton];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.selectPaletteAtIndex:
- (void)selectPaletteAtIndex:(NSUInteger)index {if(index>=self.palettes.count)return;UIImage *image=self.spectrum;if(index){NSDictionary *item=self.palettes[index];UIImage *decoded=[UIImage imageWithContentsOfFile:[self.directoryURL URLByAppendingPathComponent:item[@"file"]].path];if(!decoded.CGImage){[self showError:[UIColorPanelAppearance localizedString:@"The saved image could not be opened."]];return;}id orientation=item[@"orientation"];NSInteger value=[orientation isKindOfClass:NSNumber.class]?[orientation integerValue]:UIImageOrientationUp;if(value<UIImageOrientationUp||value>UIImageOrientationRightMirrored)value=UIImageOrientationUp;image=[UIImage imageWithCGImage:decoded.CGImage scale:decoded.scale orientation:value];}self.currentImage=image;self.selectedIndex=index;[self reloadPalettes];[self.delegate colorPickerImagePalette:self didSelectImage:image];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.importImage:
- (void)importImage:(id)sender {UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeImport];picker.delegate=self;picker.allowsMultipleSelection=NO;[self presentViewController:picker animated:YES completion:nil];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.documentPicker:didPickDocumentsAtURLs:
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    id<UIColorPanelTransientOwner> owner=self.documentOwner;BOOL owned=self.documentOwnedPresentation;if(owned&&(!owner||self.documentPresentation!=controller||![owner isTransientPresentationCurrent:controller]))return;
    NSURL *url=urls.firstObject;if(!url||(owned&&self.documentResultConsumed))return;if(owned)self.documentResultConsumed=YES;__weak typeof(self) weakSelf=self;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    [controller dismissViewControllerAnimated:YES completion:^{UIColorPickerImagePaletteController *provider=weakSelf;id<UIColorPanelTransientOwner> currentOwner=weakOwner;if(!provider||(owned&&(!currentOwner||provider.documentOwner!=currentOwner||provider.documentPresentation!=controller||![currentOwner isTransientPresentationCurrent:controller])))return;[provider importImageAtURL:url];}];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.importImageAtURL:
- (void)importImageAtURL:(NSURL *)url {BOOL scoped=[url startAccessingSecurityScopedResource];NSData *data=[NSData dataWithContentsOfURL:url];UIImage *image=data?[UIImage imageWithData:data]:nil;if(scoped)[url stopAccessingSecurityScopedResource];if(image)[self addImage:image name:[url.lastPathComponent stringByDeletingPathExtension]];else[self showError:[UIColorPanelAppearance localizedString:@"Choose an image file supported by this device."]];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.saveMetadata:
- (BOOL)saveMetadata:(NSArray<NSDictionary *> *)items {NSError *error=nil;if(![NSFileManager.defaultManager createDirectoryAtURL:self.directoryURL withIntermediateDirectories:YES attributes:nil error:&error]){[self showError:error.localizedDescription];return NO;}NSMutableArray *stored=[NSMutableArray new];for(NSDictionary *item in items)if(![item[@"builtin"] boolValue])[stored addObject:item];NSData *data=[NSJSONSerialization dataWithJSONObject:stored options:0 error:&error];BOOL saved=data&&[data writeToURL:[self.directoryURL URLByAppendingPathComponent:@"palettes.json"] options:NSDataWritingAtomic error:&error];if(!saved)[self showError:error.localizedDescription?:[UIColorPanelAppearance localizedString:@"The image palette could not be saved."]];return saved;}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.addImage:name:
- (void)addImage:(UIImage *)image name:(NSString *)name {NSData *data=UIImagePNGRepresentation(image);if(!data){[self showError:[UIColorPanelAppearance localizedString:@"This image cannot be saved as a palette."]];return;}NSError *error=nil;if(![NSFileManager.defaultManager createDirectoryAtURL:self.directoryURL withIntermediateDirectories:YES attributes:nil error:&error]){[self showError:error.localizedDescription];return;}NSString *file=[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"png"];NSURL *url=[self.directoryURL URLByAppendingPathComponent:file];if(![data writeToURL:url options:NSDataWritingAtomic error:&error]){[self showError:error.localizedDescription];return;}[self refreshMetadata];NSString *base=name.length?name:[UIColorPanelAppearance localizedString:@"Untitled"];NSString *title=base;NSUInteger n=2;BOOL exists=YES;while(exists){exists=NO;for(NSDictionary *item in self.palettes)if([item[@"name"] isEqualToString:title]){title=[NSString stringWithFormat:@"%@ %lu",base,(unsigned long)n++];exists=YES;break;}}
    NSMutableArray *items=[self.palettes mutableCopy];[items addObject:@{@"name":title,@"file":file,@"orientation":@(image.imageOrientation)}];if([self saveMetadata:items]){self.palettes=items;[self selectPaletteAtIndex:items.count-1];[NSNotificationCenter.defaultCenter postNotificationName:UIColorPickerImagePalettesDidChangeNotification object:self];}else[NSFileManager.defaultManager removeItemAtURL:url error:nil];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.renamePalette:
- (void)renamePalette:(id)sender {[self renamePaletteWithFile:self.palettes[self.selectedIndex][@"file"]];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.renamePaletteWithFile: manifest=reimpl/image_palette_ui_extras.json
- (void)renamePaletteWithFile:(NSString *)file {
    if(!file)return;[self refreshMetadata];NSUInteger index=[self indexForPaletteFile:file];if(index==NSNotFound)return;NSDictionary *palette=self.palettes[index];
    __weak id<UIColorPanelTransientOwner> actionOwner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){actionOwner=(id)context;break;}BOOL ownedAlert=actionOwner!=nil;
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Rename Image Palette"] message:[UIColorPanelAppearance localizedString:@"New name for image palette:"] preferredStyle:UIAlertControllerStyleAlert];[alert addTextFieldWithConfigurationHandler:^(UITextField *field){field.text=palette[@"name"];}];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Rename"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){
        id<UIColorPanelTransientOwner> currentOwner=actionOwner;if(ownedAlert&&(!currentOwner||![currentOwner isTransientPresentationCurrent:alert]))return;NSString *name=[alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!name.length)return;
        [self refreshMetadata];NSUInteger currentIndex=[self indexForPaletteFile:file];if(currentIndex==NSNotFound)return;
        for(NSUInteger n=0;n<self.palettes.count;n++)if(n!=currentIndex&&[self.palettes[n][@"name"] isEqualToString:name]){[self showError:[UIColorPanelAppearance localizedString:@"An image palette already has that name."]];return;}
        NSMutableArray *items=[self.palettes mutableCopy];NSMutableDictionary *item=[items[currentIndex] mutableCopy];item[@"name"]=name;items[currentIndex]=item;if([self saveMetadata:items]){self.palettes=items;[self reloadPalettes];[NSNotificationCenter.defaultCenter postNotificationName:UIColorPickerImagePalettesDidChangeNotification object:self];}
    }]];[self presentAlert:alert];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.removePalette:
- (void)removePalette:(id)sender {[self removePaletteWithFile:self.palettes[self.selectedIndex][@"file"]];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.removePaletteWithFile: manifest=reimpl/image_palette_ui_extras.json
- (void)removePaletteWithFile:(NSString *)file {
    if(!file)return;[self refreshMetadata];NSUInteger index=[self indexForPaletteFile:file];if(index==NSNotFound)return;NSDictionary *palette=self.palettes[index];
    __weak id<UIColorPanelTransientOwner> actionOwner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){actionOwner=(id)context;break;}BOOL ownedAlert=actionOwner!=nil;
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Remove Image Palette"] message:[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Remove ‘%@’?"],palette[@"name"]] preferredStyle:UIAlertControllerStyleAlert];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Remove"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){
        id<UIColorPanelTransientOwner> currentOwner=actionOwner;if(ownedAlert&&(!currentOwner||![currentOwner isTransientPresentationCurrent:alert]))return;[self refreshMetadata];NSUInteger currentIndex=[self indexForPaletteFile:file];if(currentIndex==NSNotFound)return;
        NSMutableArray *items=[self.palettes mutableCopy];[items removeObjectAtIndex:currentIndex];if([self saveMetadata:items]){self.palettes=items;[NSFileManager.defaultManager removeItemAtURL:[self.directoryURL URLByAppendingPathComponent:file] error:nil];[self selectPaletteAtIndex:0];[NSNotificationCenter.defaultCenter postNotificationName:UIColorPickerImagePalettesDidChangeNotification object:self];}
    }]];[self presentAlert:alert];
}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.copyPalette:
- (void)copyPalette:(id)sender {UIPasteboard.generalPasteboard.image=self.currentImage;}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.pastePalette:
- (void)pastePalette:(id)sender {UIImage *image=UIPasteboard.generalPasteboard.image;if(image)[self addImage:image name:[UIColorPanelAppearance localizedString:@"Clipboard"]];else[self showError:[UIColorPanelAppearance localizedString:@"The clipboard does not contain an image."]];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.presentAlert:
- (void)presentAlert:(UIAlertController *)alert {if(alert.preferredStyle==UIAlertControllerStyleActionSheet&&!alert.popoverPresentationController.sourceView){alert.popoverPresentationController.sourceView=self.manageButton;alert.popoverPresentationController.sourceRect=self.manageButton.bounds;}[self presentViewController:alert animated:YES completion:nil];}
// BINMAP-ADAPT: UIColorPickerImagePaletteController.showError:
- (void)showError:(NSString *)message {UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Image Palette"] message:message preferredStyle:UIAlertControllerStyleAlert];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"OK"] style:UIAlertActionStyleDefault handler:nil]];[self presentAlert:alert];}
@end
