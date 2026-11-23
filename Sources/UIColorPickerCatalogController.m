#import "UIColorPickerCatalogController.h"
#import "UIColorPickerColorMatch.h"
#import "UIColorValue+AppKitEquality.h"
#import "UIColorSurface.h"
#import "UIColorPanelMenuButton.h"
#import "UIColorPanelChoiceController.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelLifecycle.h"
@interface UIColorList (UIColorPickerCatalogPersistence)
- (void)removeFilePreservingList:(UIColorList *)list;
- (BOOL)writeColorsWithKeys:(NSArray<NSString *> *)keys values:(NSArray<UIColorValue *> *)values error:(NSError **)error;
@end
@interface UIColorPickerCatalogController () <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UIDocumentPickerDelegate>
@property(nonatomic, copy, readwrite) NSArray<UIColorList *> *colorLists;
@property(nonatomic, strong, readwrite) UIColorList *currentColorList;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSLayoutConstraint *minimumTableHeight;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) UIColorPanelMenuButton *listButton;
@property(nonatomic, strong) UIColorPanelMenuButton *actionsButton;
@property(nonatomic, strong) UIStackView *headerStack;
@property(nonatomic, strong) UIView *emptyView;
@property(nonatomic, strong) UILabel *emptyLabel;
@property(nonatomic, strong) UIButton *clearSearchButton;
@property(nonatomic, strong) UIButton *emptyAddButton;
@property(nonatomic, copy) NSArray<NSString *> *visibleKeys;
@property(nonatomic, copy) NSString *selectedKey;
@property(nonatomic) NSInteger selectedRowIndex;
@property(nonatomic, strong) NSMutableDictionary<NSString *,UIColorList *> *attachedLists;
@property(nonatomic, weak) id<UIColorPanelTransientOwner> documentOwner;
@property(nonatomic, weak) UIDocumentPickerViewController *documentPresentation;
@property(nonatomic) BOOL documentOwnedPresentation;
@property(nonatomic) BOOL documentResultConsumed;
- (UIMenu *)menuForColorLists API_AVAILABLE(ios(13.0));
- (UIMenu *)menuForColorListActions API_AVAILABLE(ios(13.0));
@end
@implementation UIColorPickerCatalogController
// BINMAP-ADAPT: UIColorPickerCatalogController.presentViewController:animated:completion: manifest=reimpl/ui_ux_repairs_extras.json
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    if(owner){if(![owner prepareForTransientPresentation])return;for(UIViewController *context=self;context;context=context.parentViewController)if(context.presentedViewController&&!context.presentedViewController.isBeingDismissed)return;[owner registerTransientPresentation:controller];}
    if([controller isKindOfClass:UIDocumentPickerViewController.class]){self.documentOwner=owner;self.documentOwnedPresentation=owner!=nil;self.documentPresentation=(id)controller;self.documentResultConsumed=NO;}
    [super presentViewController:controller animated:animated completion:completion];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.initWithColorLists:selectedColor:
- (instancetype)initWithColorLists:(NSArray<UIColorList *> *)lists selectedColor:(UIColorValue *)color {
    if((self=[super initWithNibName:nil bundle:nil])) {NSMutableArray<UIColorList *> *unique=[NSMutableArray new];for(UIColorList *list in lists){NSUInteger position=NSNotFound;for(NSUInteger n=0;n<unique.count;n++)if([unique[n].name isEqualToString:list.name]){position=n;break;}if(position==NSNotFound)[unique addObject:list];else unique[position]=list;}_colorLists=unique;_currentColorList=unique.firstObject;NSString *last=[NSUserDefaults.standardUserDefaults stringForKey:@"UIColorPickerCatalog.SelectedList.v1"];for(UIColorList *list in unique)if([list.name isEqualToString:last]){_currentColorList=list;break;}_selectedColor=color;_selectedRowIndex=-1;_visibleKeys=@[];_attachedLists=[NSMutableDictionary new];[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(colorListDidChange:) name:UIColorListDidChangeNotification object:nil];}return self;
}
// BINMAP-ADAPT: UIColorPickerCatalogController.setCurrentColorList: — app-local counterpart of the native last-used named-list preference.
- (void)setCurrentColorList:(UIColorList *)list { _currentColorList=list;if(list.name)[NSUserDefaults.standardUserDefaults setObject:list.name forKey:@"UIColorPickerCatalog.SelectedList.v1"];else[NSUserDefaults.standardUserDefaults removeObjectForKey:@"UIColorPickerCatalog.SelectedList.v1"]; }
// BINMAP-ADAPT: UIColorPickerCatalogController.dealloc
- (void)dealloc {[NSNotificationCenter.defaultCenter removeObserver:self];}
// BINMAP-ADAPT: UIColorPickerCatalogController.colorListDidChange:
- (void)colorListDidChange:(NSNotification *)notification {if([self.colorLists indexOfObjectIdenticalTo:notification.object]==NSNotFound)return;if(NSThread.isMainThread)[self reloadCatalog];else dispatch_async(dispatch_get_main_queue(),^{[self reloadCatalog];});}
// BINMAP-ADAPT: UIColorPickerCatalogController.viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;
    self.listButton=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];self.listButton.accessibilityIdentifier=@"ui.catalog.choose";
    self.actionsButton=[UIColorPanelMenuButton buttonWithType:UIButtonTypeSystem];self.actionsButton.displaysMoreActions=YES;self.actionsButton.accessibilityLabel=[UIColorPanelAppearance localizedString:@"Manage Color Palette"];self.actionsButton.accessibilityIdentifier=@"ui.catalog.manage";
    if(@available(iOS 13.0,*)){__weak typeof(self) weakSelf=self;self.listButton.menuProvider=^UIMenu *{return[weakSelf menuForColorLists];};self.actionsButton.menuProvider=^UIMenu *{return[weakSelf menuForColorListActions];};}
    if(!self.listButton.usesPrimaryMenu)[self.listButton addTarget:self action:@selector(chooseList:) forControlEvents:UIControlEventTouchUpInside];
    if(!self.actionsButton.usesPrimaryMenu)[self.actionsButton addTarget:self action:@selector(showActions:) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *header=[UIColorPanelMenuButton headerWithSelectionButton:self.listButton actionsButton:self.actionsButton];self.headerStack=header;
    self.searchBar=[UISearchBar new];self.searchBar.searchBarStyle=UISearchBarStyleMinimal;self.searchBar.delegate=self;self.searchBar.placeholder=[UIColorPanelAppearance localizedString:@"Search Colors"];self.searchBar.accessibilityLabel=self.searchBar.placeholder;self.searchBar.returnKeyType=UIReturnKeySearch;self.searchBar.autocorrectionType=UITextAutocorrectionTypeNo;self.searchBar.autocapitalizationType=UITextAutocapitalizationTypeNone;self.searchBar.accessibilityIdentifier=@"ui.catalog.search";
    self.tableView=[[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];self.tableView.backgroundColor=UIColor.clearColor;self.tableView.dataSource=self;self.tableView.delegate=self;self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=44;self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;self.tableView.tableFooterView=[UIView new];self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;self.tableView.accessibilityIdentifier=@"ui.catalog.colors";
    self.minimumTableHeight=[self.tableView.heightAnchor constraintGreaterThanOrEqualToConstant:44];self.minimumTableHeight.active=YES;
    self.emptyView=[UIView new];self.emptyLabel=[UILabel new];self.emptyLabel.numberOfLines=0;self.emptyLabel.textAlignment=NSTextAlignmentCenter;self.emptyLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.emptyLabel.adjustsFontForContentSizeCategory=YES;self.emptyLabel.accessibilityIdentifier=@"ui.catalog.empty";
    self.clearSearchButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.clearSearchButton setTitle:[UIColorPanelAppearance localizedString:@"Clear Search"] forState:UIControlStateNormal];[self.clearSearchButton addTarget:self action:@selector(clearSearch:) forControlEvents:UIControlEventTouchUpInside];self.clearSearchButton.accessibilityIdentifier=@"ui.catalog.clearSearch";
    self.emptyAddButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.emptyAddButton setTitle:[UIColorPanelAppearance localizedString:@"Add Color"] forState:UIControlStateNormal];[self.emptyAddButton addTarget:self action:@selector(addColor:) forControlEvents:UIControlEventTouchUpInside];
    for(UIButton *button in @[self.clearSearchButton,self.emptyAddButton]){button.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];button.titleLabel.adjustsFontForContentSizeCategory=YES;button.titleLabel.numberOfLines=0;NSLayoutConstraint *minimumHeight=[button.heightAnchor constraintGreaterThanOrEqualToConstant:44];minimumHeight.priority=UILayoutPriorityRequired-1;minimumHeight.active=YES;}
    UIStackView *emptyStack=[[UIStackView alloc]initWithArrangedSubviews:@[self.emptyLabel,self.clearSearchButton,self.emptyAddButton]];emptyStack.axis=UILayoutConstraintAxisVertical;emptyStack.spacing=8;emptyStack.translatesAutoresizingMaskIntoConstraints=NO;[self.emptyView addSubview:emptyStack];
    [NSLayoutConstraint activateConstraints:@[[emptyStack.leadingAnchor constraintEqualToAnchor:self.emptyView.layoutMarginsGuide.leadingAnchor],[emptyStack.trailingAnchor constraintEqualToAnchor:self.emptyView.layoutMarginsGuide.trailingAnchor],[emptyStack.topAnchor constraintEqualToAnchor:self.emptyView.layoutMarginsGuide.topAnchor],[emptyStack.bottomAnchor constraintEqualToAnchor:self.emptyView.layoutMarginsGuide.bottomAnchor]]];
    UIStackView *stack=[[UIStackView alloc]initWithArrangedSubviews:@[header,self.searchBar,self.tableView]];stack.axis=UILayoutConstraintAxisVertical;stack.spacing=4;stack.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:stack];
    [header setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];[self.searchBar setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[stack.topAnchor constraintEqualToAnchor:self.view.topAnchor],[stack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[header.heightAnchor constraintGreaterThanOrEqualToConstant:44],[self.searchBar.heightAnchor constraintGreaterThanOrEqualToConstant:44],[self.actionsButton.widthAnchor constraintEqualToConstant:44]]];[self reloadCatalog];
    [self selectMatchingColorAndNotify:YES];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.viewDidLayoutSubviews — size the list viewport and propagate the owning surface's direction.
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // The table's nested stack may still have its initial zero width here.
    // Its constraints fill the provider width, which is already assigned.
    CGFloat width=self.view.bounds.size.width,minimumHeight=44;
    if(width>0){
        if(self.tableView.tableHeaderView==self.emptyView){
            CGSize fitting=[self.emptyView systemLayoutSizeFittingSize:CGSizeMake(width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
            CGSize size=CGSizeMake(width,ceil(fitting.height));if(!CGSizeEqualToSize(size,self.emptyView.bounds.size)){self.emptyView.frame=(CGRect){CGPointZero,size};self.tableView.tableHeaderView=self.emptyView;}
            minimumHeight=MAX(minimumHeight,size.height);
        }else if(self.visibleKeys.count){
            UILabel *label=[UILabel new];label.numberOfLines=0;label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];label.text=[self.currentColorList localizedColorNameWithKey:self.visibleKeys.firstObject];
            // Match the row's 20-point swatch, 4/6/4 horizontal spacing and 5-point vertical padding.
            minimumHeight=MAX(minimumHeight,ceil([label sizeThatFits:CGSizeMake(MAX(1,width-34),CGFLOAT_MAX)].height)+10);
        }
        if(self.minimumTableHeight.constant!=minimumHeight){self.minimumTableHeight.constant=minimumHeight;[self.parentViewController.view setNeedsLayout];}
    }
    UISemanticContentAttribute direction=self.view.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;
    self.headerStack.semanticContentAttribute=direction;self.listButton.semanticContentAttribute=direction;self.actionsButton.semanticContentAttribute=direction;self.searchBar.semanticContentAttribute=direction;self.tableView.semanticContentAttribute=direction;for(UITableViewCell *cell in self.tableView.visibleCells){cell.semanticContentAttribute=direction;cell.contentView.semanticContentAttribute=direction;[cell setNeedsLayout];}[self.headerStack setNeedsLayout];[self.headerStack layoutIfNeeded];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.setSelectedColor:
- (void)setSelectedColor:(UIColorValue *)color {NSParameterAssert(color);_selectedColor=color;if(self.isViewLoaded)[self selectMatchingColorAndNotify:NO];}
// BINMAP-ADAPT: UIColorPickerCatalogController.selectMatchingColorAndNotify: — UIKit row selection bridges the recovered matching kernels and native lazy-load callback order.
- (void)selectMatchingColorAndNotify:(BOOL)notify {
    NSMutableArray<UIColorValue *> *colors=[NSMutableArray array];
    for(NSString *key in self.visibleKeys){UIColorValue *value=[self.currentColorList colorValueWithKey:key];if(!value)return;[colors addObject:value];}
    // The source table retains a row index across reloads; a key may move or vanish.
    NSInteger oldIndex=self.selectedRowIndex;
    UIColorPickerColorMatch *match=[[UIColorPickerColorMatch alloc]initWithColors:colors color:self.selectedColor selectedIndex:oldIndex];
    if(!match.profileAvailable)return; // No substitute profile or speculative nearest-color choice.
    NSInteger index=[match _colorIndexInTableView];
    self.selectedRowIndex=index;
    self.selectedKey=index>=0?self.visibleKeys[(NSUInteger)index]:nil;
    [self reloadCatalog];
    if(index>=0){
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        UIColorValue *value=colors[(NSUInteger)index];
        if(notify && index!=oldIndex && ![value isEqualForColorPanel:self.selectedColor]){_selectedColor=value;[self.delegate colorPickerCatalog:self didSelectColorValue:value];}
    }
}
// BINMAP-ADAPT: UIColorPickerCatalogController.reloadCatalog
- (void)reloadCatalog {
    NSString *filter=self.searchBar.text?:@"";NSMutableArray *keys=[NSMutableArray new];for(NSString *key in self.currentColorList.allKeys)if(!filter.length||[[self.currentColorList localizedColorNameWithKey:key]rangeOfString:filter options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location!=NSNotFound||[key rangeOfString:filter options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location!=NSNotFound)[keys addObject:key];self.visibleKeys=keys;
    [self.listButton setTitle:self.currentColorList.localizedName?:[UIColorPanelAppearance localizedString:@"Choose Palette"] forState:UIControlStateNormal];self.listButton.accessibilityLabel=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Color Palette, %@"],self.currentColorList.localizedName?:[UIColorPanelAppearance localizedString:@"None"]];
    [self.listButton reloadMenu];[self.actionsButton reloadMenu];[self.tableView reloadData];
    BOOL filtering=filter.length>0;
    self.emptyLabel.text=[UIColorPanelAppearance localizedString:filtering?@"No matching colors":@"This palette has no colors."];
    self.clearSearchButton.hidden=!filtering;self.emptyAddButton.hidden=filtering||!self.currentColorList.isEditable;
    self.tableView.tableHeaderView=keys.count?nil:self.emptyView;[self.view setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.clearSearch:
- (void)clearSearch:(id)sender {
    self.searchBar.text=@"";[self reloadCatalog];[self selectMatchingColorAndNotify:NO];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,self.searchBar);
}
// BINMAP-ADAPT: UIColorPickerCatalogController.menuForColorLists — native UIMenu selection invokes the existing list-switch path without eagerly loading colors.
- (UIMenu *)menuForColorLists {
    NSMutableArray<UIMenuElement *> *items=[NSMutableArray new];__weak typeof(self) weakSelf=self;
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    BOOL owned=owner!=nil;NSUInteger generation=owner.transientGeneration;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    BOOL (^canPerform)(void)=^BOOL{id<UIColorPanelTransientOwner> currentOwner=weakOwner;return !owned||(currentOwner&&currentOwner.transientGeneration==generation&&[currentOwner prepareForTransientPresentation]);};
    for(NSUInteger index=0;index<self.colorLists.count;index++){UIColorList *list=self.colorLists[index];UIAction *action=[UIAction actionWithTitle:list.localizedName image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf selectListAtIndex:index];}];action.state=list==self.currentColorList?UIMenuElementStateOn:UIMenuElementStateOff;[items addObject:action];}
    return[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Color Palettes"] children:items];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.menuForColorListActions — native menu presentation of the established management routes and editability.
- (UIMenu *)menuForColorListActions {
    __weak typeof(self) weakSelf=self;
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    BOOL owned=owner!=nil;NSUInteger generation=owner.transientGeneration;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    BOOL (^canPerform)(void)=^BOOL{id<UIColorPanelTransientOwner> currentOwner=weakOwner;return !owned||(currentOwner&&currentOwner.transientGeneration==generation&&[currentOwner prepareForTransientPresentation]);};
    UIAction *create=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"New"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf newList:action];}];
    UIAction *open=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Open…"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf openList:action];}];
    UIAction *rename=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Rename…"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf renameList:action];}];rename.attributes=self.currentColorList.editable?0:UIMenuElementAttributesDisabled;
    UIAction *remove=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Remove"] image:nil identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf removeList:action];}];remove.attributes=UIMenuElementAttributesDestructive|(self.currentColorList.editable?0:UIMenuElementAttributesDisabled);
    UIAction *addColor=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Add Color…"] image:[UIColorPanelAppearance imageForSymbol:@"plus" size:18] identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf addColor:action];}];addColor.attributes=self.currentColorList.editable?0:UIMenuElementAttributesDisabled;
    UIAction *deleteColor=[UIAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Delete Color…"] image:[UIColorPanelAppearance imageForSymbol:@"trash" size:18] identifier:nil handler:^(UIAction *action){if(canPerform())[weakSelf confirmDeleteColor:action];}];deleteColor.attributes=UIMenuElementAttributesDestructive|((self.currentColorList.editable&&[self.currentColorList.allKeys containsObject:self.selectedKey?:@""])?0:UIMenuElementAttributesDisabled);
    return[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Manage Color Palette"] children:@[[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Palette"] image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[create,open,rename,remove]],[UIMenu menuWithTitle:[UIColorPanelAppearance localizedString:@"Colors"] image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[addColor,deleteColor]]]];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.attachColorList:
- (void)attachColorList:(UIColorList *)list {
    NSParameterAssert(list);NSMutableArray<UIColorList *> *lists=[self.colorLists mutableCopy];NSUInteger index=NSNotFound;for(NSUInteger n=0;n<lists.count;n++)if([lists[n].name isEqualToString:list.name]){index=n;break;}
    self.attachedLists[list.name]=list;if(index==NSNotFound)[lists addObject:list];else lists[index]=list;BOOL replaceCurrent=[self.currentColorList.name isEqualToString:list.name];self.colorLists=lists;if(replaceCurrent||!self.currentColorList)self.currentColorList=list;[self reloadCatalog];if(self.isViewLoaded)[self selectMatchingColorAndNotify:YES];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.detachColorList:
- (void)detachColorList:(UIColorList *)list {
    if(!list)return;NSString *name=list.name;BOOL wasActive=self.currentColorList==list;
    if(self.attachedLists[name])[self.attachedLists removeObjectForKey:name];else[list removeFile];
    NSMutableArray<UIColorList *> *lists=[self.colorLists mutableCopy];for(NSInteger n=(NSInteger)lists.count-1;n>=0;n--)if([lists[(NSUInteger)n].name isEqualToString:name])[lists removeObjectAtIndex:(NSUInteger)n];self.colorLists=lists;
    if(wasActive){self.currentColorList=lists.firstObject;self.selectedKey=nil;}[self reloadCatalog];if(wasActive&&self.isViewLoaded)[self selectMatchingColorAndNotify:YES];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.chooseList:
- (void)chooseList:(id)sender {
    NSMutableArray<UIColorPanelChoiceItem *> *items=[NSMutableArray new];__weak typeof(self) weakSelf=self;
    for(NSUInteger index=0;index<self.colorLists.count;index++){UIColorList *list=self.colorLists[index];[items addObject:[UIColorPanelChoiceItem itemWithTitle:list.localizedName selected:list==self.currentColorList enabled:YES destructive:NO handler:^{[weakSelf selectListAtIndex:index];}]];}
    [UIColorPanelChoiceController presentFromViewController:self title:[UIColorPanelAppearance localizedString:@"Color Palettes"] sections:@[[UIColorPanelChoiceSection sectionWithTitle:nil items:items]] sourceView:[sender isKindOfClass:UIView.class]?sender:self.listButton];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.selectListAtIndex:
- (void)selectListAtIndex:(NSUInteger)index {if(index>=self.colorLists.count)return;self.currentColorList=self.colorLists[index];self.selectedKey=nil;self.searchBar.text=@"";[self reloadCatalog];[self selectMatchingColorAndNotify:YES];}
// BINMAP-ADAPT: UIColorPickerCatalogController.showActions:
- (void)showActions:(id)sender {
    __weak typeof(self) weakSelf=self;BOOL editable=self.currentColorList.editable;BOOL canDelete=editable&&[self.currentColorList.allKeys containsObject:self.selectedKey?:@""];
    NSArray *palette=@[[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"New"] selected:NO enabled:YES destructive:NO handler:^{[weakSelf newList:nil];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Open…"] selected:NO enabled:YES destructive:NO handler:^{[weakSelf openList:nil];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Rename…"] selected:NO enabled:editable destructive:NO handler:^{[weakSelf renameList:nil];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Remove"] selected:NO enabled:editable destructive:YES handler:^{[weakSelf removeList:nil];}]];
    NSArray *colors=@[[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Add Color…"] selected:NO enabled:editable destructive:NO handler:^{[weakSelf addColor:nil];}],[UIColorPanelChoiceItem itemWithTitle:[UIColorPanelAppearance localizedString:@"Delete Color…"] selected:NO enabled:canDelete destructive:YES handler:^{[weakSelf confirmDeleteColor:nil];}]];
    [UIColorPanelChoiceController presentFromViewController:self title:[UIColorPanelAppearance localizedString:@"Manage Color Palette"] sections:@[[UIColorPanelChoiceSection sectionWithTitle:[UIColorPanelAppearance localizedString:@"Palette"] items:palette],[UIColorPanelChoiceSection sectionWithTitle:[UIColorPanelAppearance localizedString:@"Colors"] items:colors]] sourceView:[sender isKindOfClass:UIView.class]?sender:self.actionsButton];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.uniqueName:
- (NSString *)uniqueName:(NSString *)base {NSString *name=base.length?base:[UIColorPanelAppearance localizedString:@"Unnamed"];NSUInteger suffix=2;BOOL collision=YES;while(collision){collision=NO;for(UIColorList *list in self.colorLists)if([list.name isEqualToString:name]){collision=YES;name=[NSString stringWithFormat:@"%@ %lu",base.length?base:[UIColorPanelAppearance localizedString:@"Unnamed"],(unsigned long)suffix++];break;}}return name;}
// BINMAP-ADAPT: UIColorPickerCatalogController.replacementForList:withName:
- (UIColorList *)replacementForList:(UIColorList *)old withName:(NSString *)name {UIColorList *list=[[UIColorList alloc]initWithName:name];for(NSString *key in old.allKeys){UIColorValue *value=[old colorValueWithKey:key];if(value)[list setColorValue:value forKey:key];}return list;}
// BINMAP-ADAPT: UIColorPickerCatalogController.installList:replacing:
- (void)installList:(UIColorList *)list replacing:(UIColorList *)old {
    NSMutableArray<UIColorList *> *lists=[self.colorLists mutableCopy];NSUInteger index=old?[lists indexOfObjectIdenticalTo:old]:NSNotFound;if(index==NSNotFound)[lists addObject:list];else lists[index]=list;self.colorLists=lists;self.currentColorList=list;
    if(!old)self.searchBar.text=@"";
    [self reloadCatalog];
    NSUInteger selectedIndex=self.selectedKey?[self.visibleKeys indexOfObject:self.selectedKey]:NSNotFound;
    self.selectedRowIndex=selectedIndex==NSNotFound?-1:(NSInteger)selectedIndex;
    [self.tableView selectRowAtIndexPath:selectedIndex==NSNotFound?nil:[NSIndexPath indexPathForRow:self.selectedRowIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self notifyListsChanged];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.saveList:keys:values: manifest=reimpl/catalog_ui_extras.json
- (BOOL)saveList:(UIColorList *)list keys:(NSArray<NSString *> *)keys values:(NSArray<UIColorValue *> *)values {NSError *error=nil;BOOL saved=keys?[list writeColorsWithKeys:keys values:values error:&error]:[list writeToURL:nil error:&error];if(saved)return YES;UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Couldn’t Save Palette"] message:error.localizedDescription?:[UIColorPanelAppearance localizedString:@"The palette could not be saved."] preferredStyle:UIAlertControllerStyleAlert];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"OK"] style:UIAlertActionStyleDefault handler:nil]];[self presentAlert:alert];return NO;}
// BINMAP-ADAPT: UIColorPickerCatalogController.newList:
- (void)newList:(id)sender {UIColorList *list=[[UIColorList alloc]initWithName:[self uniqueName:[UIColorPanelAppearance localizedString:@"Unnamed"]]];[list setColorValue:self.selectedColor forKey:[UIColorPanelAppearance localizedString:@"Unnamed"]];if([self saveList:list keys:nil values:nil]){self.selectedKey=[UIColorPanelAppearance localizedString:@"Unnamed"];[self installList:list replacing:nil];}}
// BINMAP-ADAPT: UIColorPickerCatalogController.openList:
- (void)openList:(id)sender {UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];picker.delegate=self;picker.allowsMultipleSelection=NO;[self presentViewController:picker animated:YES completion:nil];}
// BINMAP-ADAPT: UIColorPickerCatalogController.renameList:
- (void)renameList:(id)sender {
    __weak id<UIColorPanelTransientOwner> actionOwner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){actionOwner=(id)context;break;}BOOL ownedAlert=actionOwner!=nil;
    UIColorList *old=self.currentColorList;if(!old.editable)return;UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Rename Color Palette"] message:[UIColorPanelAppearance localizedString:@"New name for color palette:"] preferredStyle:UIAlertControllerStyleAlert];[alert addTextFieldWithConfigurationHandler:^(UITextField *f){f.text=old.name;f.autocapitalizationType=UITextAutocapitalizationTypeWords;}];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Rename"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){id<UIColorPanelTransientOwner> currentOwner=actionOwner;if(ownedAlert&&(!currentOwner||![currentOwner isTransientPresentationCurrent:alert]))return;NSString *name=[alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!name.length||[name isEqualToString:old.name])return;UIColorList *list=[self replacementForList:old withName:[self uniqueName:name]];if([self saveList:list keys:nil values:nil]){if(self.attachedLists[old.name])[self.attachedLists removeObjectForKey:old.name];else[old removeFilePreservingList:list];[self installList:list replacing:old];}}]];[self presentAlert:alert];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.removeList:
- (void)removeList:(id)sender {
    __weak id<UIColorPanelTransientOwner> actionOwner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){actionOwner=(id)context;break;}BOOL ownedAlert=actionOwner!=nil;
    UIColorList *old=self.currentColorList;if(!old.editable)return;UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Remove Color Palette"] message:[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Remove the entire ‘%@’ palette?"],old.name] preferredStyle:UIAlertControllerStyleAlert];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil]];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Remove"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){id<UIColorPanelTransientOwner> currentOwner=actionOwner;if(ownedAlert&&(!currentOwner||![currentOwner isTransientPresentationCurrent:alert]))return;[self detachColorList:old];[self notifyListsChanged];}]];[self presentAlert:alert];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.addColor:
- (void)addColor:(id)sender {
    __weak id<UIColorPanelTransientOwner> actionOwner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){actionOwner=(id)context;break;}BOOL ownedAlert=actionOwner!=nil;
    UIColorList *old=self.currentColorList;if(!old.editable)return;UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Add Color"] message:[UIColorPanelAppearance localizedString:@"Name for the selected color:"] preferredStyle:UIAlertControllerStyleAlert];[alert addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=[UIColorPanelAppearance localizedString:@"Unnamed"];}];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil]];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Add"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){id<UIColorPanelTransientOwner> currentOwner=actionOwner;if(ownedAlert&&(!currentOwner||![currentOwner isTransientPresentationCurrent:alert]))return;NSString *base=[alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!base.length)base=[UIColorPanelAppearance localizedString:@"Unnamed"];NSString *key=base;NSUInteger n=2;while([old.allKeys containsObject:key])key=[NSString stringWithFormat:@"%@ %lu",base,(unsigned long)n++];
        NSMutableArray<NSString *> *keys=[old.allKeys mutableCopy];NSMutableArray<UIColorValue *> *values=[NSMutableArray arrayWithCapacity:keys.count+1];for(NSString *existingKey in keys)[values addObject:[old colorValueWithKey:existingKey]];[keys addObject:key];[values addObject:self.selectedColor];
        if([self saveList:old keys:keys values:values]){
            self.selectedKey=key;[self reloadCatalog];
            NSUInteger selectedIndex=[self.visibleKeys indexOfObject:key];self.selectedRowIndex=selectedIndex==NSNotFound?-1:(NSInteger)selectedIndex;
            [self.tableView selectRowAtIndexPath:selectedIndex==NSNotFound?nil:[NSIndexPath indexPathForRow:self.selectedRowIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self notifyListsChanged];
        }
    }]];[self presentAlert:alert];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.confirmDeleteColor: — menu-only confirmation retains the established delete/save action after an explicit choice.
- (void)confirmDeleteColor:(id)sender {
    __weak id<UIColorPanelTransientOwner> actionOwner=nil;for(UIViewController *context=self;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){actionOwner=(id)context;break;}BOOL ownedAlert=actionOwner!=nil;
    if(!self.currentColorList.editable||![self.currentColorList.allKeys containsObject:self.selectedKey?:@""])return;
    NSString *key=self.selectedKey;UIColorList *list=self.currentColorList;UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Delete Color"] message:[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"Delete ‘%@’ from this palette?"],key] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"Delete"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){id<UIColorPanelTransientOwner> currentOwner=actionOwner;if(ownedAlert&&(!currentOwner||![currentOwner isTransientPresentationCurrent:alert]))return;if(self.currentColorList==list&&[self.selectedKey isEqualToString:key])[self deleteColor:action];}]];[self presentAlert:alert];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.deleteColor:
- (void)deleteColor:(id)sender {
    UIColorList *old=self.currentColorList;NSString *key=[sender isKindOfClass:NSString.class]?sender:self.selectedKey;if(!old.editable||![old.allKeys containsObject:key?:@""])return;
    NSMutableArray<NSString *> *keys=[old.allKeys mutableCopy];[keys removeObject:key];NSMutableArray<UIColorValue *> *values=[NSMutableArray arrayWithCapacity:keys.count];for(NSString *remainingKey in keys)[values addObject:[old colorValueWithKey:remainingKey]];
    if([self saveList:old keys:keys values:values]){self.selectedKey=nil;self.selectedRowIndex=-1;[self reloadCatalog];[self.tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];[self notifyListsChanged];}
}
// BINMAP-ADAPT: UIColorPickerCatalogController.notifyListsChanged
- (void)notifyListsChanged {if([self.delegate respondsToSelector:@selector(colorPickerCatalogDidChangeLists:)])[self.delegate colorPickerCatalogDidChangeLists:self];}
// BINMAP-ADAPT: UIColorPickerCatalogController.presentAlert:
- (void)presentAlert:(UIAlertController *)alert {if(alert.preferredStyle==UIAlertControllerStyleActionSheet&&!alert.popoverPresentationController.sourceView){alert.popoverPresentationController.sourceView=self.actionsButton;alert.popoverPresentationController.sourceRect=self.actionsButton.bounds;}[self presentViewController:alert animated:YES completion:nil];}
// BINMAP-ADAPT: UIColorPickerCatalogController.searchFieldChanged: — public UITextField event uses the existing native-equivalent filter and selection pipeline.
- (void)searchFieldChanged:(UITextField *)field {[self reloadCatalog];[self selectMatchingColorAndNotify:YES];}
// BINMAP-ADAPT: UIColorPickerCatalogController.searchBar:textDidChange:
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {[self reloadCatalog];[self selectMatchingColorAndNotify:text.length>0];}
// BINMAP-ADAPT: UIColorPickerCatalogController.searchBarSearchButtonClicked: — complete native search editing without changing the existing per-keystroke commit pipeline.
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {[searchBar resignFirstResponder];}
// BINMAP-ADAPT: UIColorPickerCatalogController.searchBarTextDidBeginEditing:
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {[searchBar setShowsCancelButton:YES animated:YES];}
// BINMAP-ADAPT: UIColorPickerCatalogController.searchBarTextDidEndEditing:
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {[searchBar setShowsCancelButton:NO animated:YES];}
// BINMAP-ADAPT: UIColorPickerCatalogController.searchBarCancelButtonClicked: — exit editing without clearing or reapplying the query.
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {[searchBar resignFirstResponder];}
// BINMAP-ADAPT: UIColorPickerCatalogController.tableView:numberOfRowsInSection:
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {return self.visibleKeys.count;}
// BINMAP-ADAPT: UIColorPickerCatalogController.tableView:cellForRowAtIndexPath:
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Color"];
    if(!cell){
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Color"];cell.backgroundColor=UIColor.clearColor;[cell.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
        UIColorPanelColorWell *swatch=[UIColorPanelColorWell buttonWithType:UIButtonTypeCustom];swatch.usesCircularPresentation=YES;swatch.tag=101;swatch.userInteractionEnabled=NO;swatch.isAccessibilityElement=NO;swatch.translatesAutoresizingMaskIntoConstraints=NO;swatch.layer.cornerRadius=0;swatch.clipsToBounds=YES;[cell.contentView addSubview:swatch];
        UILabel *label=[UILabel new];label.tag=102;label.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];label.textAlignment=NSTextAlignmentNatural;label.adjustsFontForContentSizeCategory=YES;label.numberOfLines=0;label.translatesAutoresizingMaskIntoConstraints=NO;[cell.contentView addSubview:label];
        [NSLayoutConstraint activateConstraints:@[[swatch.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:4],[swatch.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],[swatch.widthAnchor constraintEqualToConstant:20],[swatch.heightAnchor constraintEqualToConstant:20],[swatch.topAnchor constraintGreaterThanOrEqualToAnchor:cell.contentView.topAnchor constant:3],[swatch.bottomAnchor constraintLessThanOrEqualToAnchor:cell.contentView.bottomAnchor constant:-3],[label.leadingAnchor constraintEqualToAnchor:swatch.trailingAnchor constant:6],[label.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-4],[label.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:5],[label.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-5]]];
    }
    NSString *key=self.visibleKeys[indexPath.row];UIColorValue *color=[self.currentColorList colorValueWithKey:key];NSString *displayName=[self.currentColorList localizedColorNameWithKey:key];((UILabel *)[cell.contentView viewWithTag:102]).text=displayName;UIColorPanelColorWell *swatch=(UIColorPanelColorWell *)[cell.contentView viewWithTag:101];swatch.color=color;swatch.selected=[key isEqualToString:self.selectedKey];[swatch setNeedsDisplay];
    cell.semanticContentAttribute=self.view.effectiveUserInterfaceLayoutDirection==UIUserInterfaceLayoutDirectionRightToLeft?UISemanticContentAttributeForceRightToLeft:UISemanticContentAttributeForceLeftToRight;cell.contentView.semanticContentAttribute=cell.semanticContentAttribute;
    cell.accessoryView=nil;cell.accessibilityLabel=[NSString stringWithFormat:[UIColorPanelAppearance localizedString:@"%@, opacity %@ percent"],displayName,[UIColorPanelAppearance formatNumber:CGColorGetAlpha(color.CGColor)*100 significantDigits:0]];cell.accessibilityTraits=[key isEqualToString:self.selectedKey]?UIAccessibilityTraitSelected:UIAccessibilityTraitNone;return cell;
}
// BINMAP-ADAPT: UIColorPickerCatalogController.tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {NSString *key=self.visibleKeys[indexPath.row];self.selectedRowIndex=indexPath.row;self.selectedKey=key;UIColorValue *value=[self.currentColorList colorValueWithKey:key];if(value){self.selectedColor=value;[self.delegate colorPickerCatalog:self didSelectColorValue:value];}[self reloadCatalog];}
// BINMAP-ADAPT: UIColorPickerCatalogController.tableView:canEditRowAtIndexPath:
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {return self.currentColorList.editable;}
// BINMAP-ADAPT: UIColorPickerCatalogController.tableView:commitEditingStyle:forRowAtIndexPath:
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {if(style==UITableViewCellEditingStyleDelete)[self deleteColor:self.visibleKeys[indexPath.row]];}
// BINMAP-ADAPT: UIColorPickerCatalogController.documentPicker:didPickDocumentsAtURLs:
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    id<UIColorPanelTransientOwner> owner=self.documentOwner;BOOL owned=self.documentOwnedPresentation;if(owned&&(!owner||self.documentPresentation!=controller||![owner isTransientPresentationCurrent:controller]))return;
    NSURL *url=urls.firstObject;if(!url||(owned&&self.documentResultConsumed))return;if(owned)self.documentResultConsumed=YES;__weak typeof(self) weakSelf=self;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    [controller dismissViewControllerAnimated:YES completion:^{UIColorPickerCatalogController *provider=weakSelf;id<UIColorPanelTransientOwner> currentOwner=weakOwner;if(!provider||(owned&&(!currentOwner||provider.documentOwner!=currentOwner||provider.documentPresentation!=controller||![currentOwner isTransientPresentationCurrent:controller])))return;[provider importListAtURL:url];}];
}
// BINMAP-ADAPT: UIColorPickerCatalogController.importListAtURL:
- (void)importListAtURL:(NSURL *)url {
    BOOL scoped=[url startAccessingSecurityScopedResource];UIColorList *imported=[url.pathExtension.lowercaseString isEqualToString:@"clr"]?[[UIColorList alloc]initWithName:[url.lastPathComponent stringByDeletingPathExtension] fromFile:url.path]:nil;if(scoped)[url stopAccessingSecurityScopedResource];
    if(!imported){UIAlertController *alert=[UIAlertController alertControllerWithTitle:[UIColorPanelAppearance localizedString:@"Couldn’t Open Palette"] message:[UIColorPanelAppearance localizedString:@"Choose a valid .clr color palette. Unsupported color data is not imported."] preferredStyle:UIAlertControllerStyleAlert];[alert addAction:[UIAlertAction actionWithTitle:[UIColorPanelAppearance localizedString:@"OK"] style:UIAlertActionStyleDefault handler:nil]];[self presentAlert:alert];return;}
    UIColorList *list=[self replacementForList:imported withName:[self uniqueName:imported.name]];if([self saveList:list keys:nil values:nil]){self.selectedKey=nil;[self installList:list replacing:nil];}
}
@end
