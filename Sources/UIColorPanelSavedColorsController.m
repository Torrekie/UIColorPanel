#import "UIColorPanelSavedColorsController.h"
#import "UIColorPickerSwatchesView.h"
#import "UIColorPanelFavoriteSwatchLayout.h"
#import "UIColorPanelAppearance.h"

@interface UIColorPanelSavedColorsController ()
@property(nonatomic, strong) UIColorPickerSwatchesView *swatches;
@property(nonatomic, strong) UIBarButtonItem *clipboardItem, *deleteItem;
@end
@implementation UIColorPanelSavedColorsController
// BINMAP-ADAPT: UIColorPanelSavedColorsController.initWithSwatchesView: manifest=reimpl/polish_shell_extras.json
- (instancetype)initWithSwatchesView:(UIColorPickerSwatchesView *)view {
    if((self=[super initWithNibName:nil bundle:nil]))_swatches=view;
    return self;
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.viewDidLoad manifest=reimpl/polish_shell_extras.json
- (void)viewDidLoad {
    [super viewDidLoad];self.title=[UIColorPanelAppearance localizedString:@"Saved colors"];
    if(@available(iOS 13.0,*))self.view.backgroundColor=UIColor.secondarySystemBackgroundColor;else self.view.backgroundColor=[UIColor colorWithWhite:.95 alpha:1];
    [self.swatches removeFromSuperview];self.swatches.userInteractionEnabled=YES;self.swatches.accessibilityElementsHidden=NO;self.swatches.hidden=NO;
    self.swatches.logicalScale=1;self.swatches.usesCircularManagerPresentation=YES;self.swatches.favoriteLayout.itemSize=CGSizeMake(44,44);self.swatches.favoriteLayout.itemSpacing=8;self.swatches.favoriteLayout.sectionInset=UIEdgeInsetsMake(16,16,16,16);
    [self.view addSubview:self.swatches];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(save:)];
    self.navigationItem.leftBarButtonItem.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Save Current Color"];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
    self.clipboardItem=[[UIBarButtonItem alloc]initWithTitle:[UIColorPanelAppearance localizedString:@"Copy"] style:UIBarButtonItemStylePlain target:self action:@selector(copy:)];
    self.deleteItem=[[UIBarButtonItem alloc]initWithTitle:[UIColorPanelAppearance localizedString:@"Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(remove:)];
    UIBarButtonItem *space=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    self.toolbarItems=@[self.clipboardItem,space,self.deleteItem];self.navigationController.toolbarHidden=NO;
    [self refreshActions];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.viewDidLayoutSubviews manifest=reimpl/polish_shell_extras.json
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];self.swatches.frame=UIEdgeInsetsInsetRect(self.view.bounds,self.view.safeAreaInsets);[self.swatches layoutIfNeeded];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.viewDidDisappear: manifest=reimpl/polish_shell_extras.json
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if(self.isBeingDismissed||self.navigationController.isBeingDismissed||!self.navigationController.presentingViewController){
        [self.swatches cancelPendingDrops];
        void (^restore)(void)=self.restorationHandler;self.restorationHandler=nil;if(restore)restore();
    }
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.refreshActions manifest=reimpl/polish_shell_extras.json
- (void)refreshActions {
    self.navigationItem.leftBarButtonItem.enabled=self.swatches.favoritesEditable;
    self.clipboardItem.enabled=[self.swatches canPerformAction:@selector(copy:) withSender:self];
    self.deleteItem.enabled=[self.swatches canPerformAction:@selector(delete:) withSender:self];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.save: manifest=reimpl/polish_shell_extras.json
- (void)save:(id)sender {
    if([self.swatches saveCurrentColor])UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,[UIColorPanelAppearance localizedString:@"Color saved"]);
    else if(self.swatches.favoritesEditable&&!self.presentedViewController){
        UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Saved colors"] message:[UIColorPanelAppearance localizedString:@"This color cannot be saved."] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"OK"] style:UIAlertActionStyleDefault handler:nil]];[self presentViewController:alert animated:YES completion:nil];
    }
    [self refreshActions];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.copy: manifest=reimpl/polish_shell_extras.json
- (void)copy:(id)sender {
    if([self.swatches canPerformAction:@selector(copy:) withSender:self])[self.swatches copy:self];[self refreshActions];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.remove: manifest=reimpl/polish_shell_extras.json
- (void)remove:(id)sender {
    if([self.swatches canPerformAction:@selector(delete:) withSender:self])[self.swatches delete:self];[self refreshActions];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.close: manifest=reimpl/polish_shell_extras.json
- (void)close:(id)sender {
    [self.swatches cancelPendingDrops];
    void (^restore)(void)=self.restorationHandler;
    self.restorationHandler=nil;
    [self dismissViewControllerAnimated:YES completion:restore];
}
// BINMAP-ADAPT: UIColorPanelSavedColorsController.traitCollectionDidChange: manifest=reimpl/polish_shell_extras.json
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];[self.view setNeedsLayout];
}
@end
