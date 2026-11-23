#import "UIColorPanelChoiceController.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelLifecycle.h"
#import <math.h>

@interface UIColorPanelChoiceItem ()
@property(nonatomic, copy, readwrite) NSString *title;
@property(nonatomic, readwrite, getter=isSelected) BOOL selected;
@property(nonatomic, readwrite, getter=isEnabled) BOOL enabled;
@property(nonatomic, readwrite, getter=isDestructive) BOOL destructive;
@property(nonatomic, copy, readwrite, nullable) void (^handler)(void);
@end

@implementation UIColorPanelChoiceItem
// BINMAP-ADAPT: UIColorPanelChoiceItem.itemWithTitle:selected:enabled:destructive:handler:
+ (instancetype)itemWithTitle:(NSString *)title selected:(BOOL)selected enabled:(BOOL)enabled destructive:(BOOL)destructive handler:(void (^)(void))handler {
    UIColorPanelChoiceItem *item=[self new];item.title=title;item.selected=selected;item.enabled=enabled;item.destructive=destructive;item.handler=handler;return item;
}
@end

@interface UIColorPanelChoiceSection ()
@property(nonatomic, copy, readwrite, nullable) NSString *title;
@property(nonatomic, copy, readwrite) NSArray<UIColorPanelChoiceItem *> *items;
@end

@implementation UIColorPanelChoiceSection
// BINMAP-ADAPT: UIColorPanelChoiceSection.sectionWithTitle:items:
+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<UIColorPanelChoiceItem *> *)items {
    UIColorPanelChoiceSection *section=[self new];section.title=title;section.items=items;return section;
}
@end

@interface UIColorPanelChoiceController () <UIPopoverPresentationControllerDelegate>
@property(nonatomic, copy, readwrite) NSArray<UIColorPanelChoiceSection *> *sections;
@property(nonatomic, weak) UIView *sourceView;
@property(nonatomic, weak) UIViewController *sourceController;
@property(nonatomic, weak) id<UIColorPanelTransientOwner> transientOwner;
@property(nonatomic) BOOL ownedPresentation;
@property(nonatomic) BOOL finished;
- (void)finishWithHandler:(void (^ _Nullable)(void))handler;
@end

@implementation UIColorPanelChoiceController
// BINMAP-ADAPT: UIColorPanelChoiceController.initWithTitle:sections:
- (instancetype)initWithTitle:(NSString *)title sections:(NSArray<UIColorPanelChoiceSection *> *)sections {
    if((self=[super initWithStyle:UITableViewStyleGrouped])){self.title=title;_sections=[sections copy];}return self;
}
// BINMAP-ADAPT: UIColorPanelChoiceController.presentFromViewController:title:sections:sourceView:
+ (instancetype)presentFromViewController:(UIViewController *)presenter title:(NSString *)title sections:(NSArray<UIColorPanelChoiceSection *> *)sections sourceView:(UIView *)sourceView {
    if(presenter.presentedViewController)return nil;
    id<UIColorPanelTransientOwner> owner=nil;for(UIViewController *context=presenter;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    if(owner){if(![owner prepareForTransientPresentation])return nil;}else[presenter.view endEditing:YES];
    if(presenter.presentedViewController)return nil;
    UIColorPanelChoiceController *controller=[[self alloc]initWithTitle:title sections:sections];controller.sourceView=sourceView?:presenter.view;controller.sourceController=presenter;
    controller.transientOwner=owner;controller.ownedPresentation=owner!=nil;
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:controller];
    navigation.modalPresentationStyle=UIModalPresentationPopover;
    UIPopoverPresentationController *popover=navigation.popoverPresentationController;popover.delegate=controller;popover.sourceView=controller.sourceView;popover.sourceRect=controller.sourceView.bounds;
    UIView *container=presenter.view;
    CGRect availableBounds=UIEdgeInsetsInsetRect(UIEdgeInsetsInsetRect(container.bounds,container.safeAreaInsets),popover.popoverLayoutMargins);
    controller.preferredContentSize=CGSizeMake(MIN(350,CGRectGetWidth(availableBounds)),MAX(0,MIN(540,CGRectGetHeight(availableBounds))-navigation.navigationBar.bounds.size.height));
    if(owner)[owner registerTransientPresentation:navigation];[presenter presentViewController:navigation animated:YES completion:nil];return controller;
}
// BINMAP-ADAPT: UIColorPanelChoiceController.viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=44;self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
    // Suppress empty grouped padding; named section headers retain UIKit sizing.
    self.tableView.tableHeaderView=[[UIView alloc]initWithFrame:CGRectMake(0,0,0,.01)];self.tableView.tableFooterView=[[UIView alloc]initWithFrame:CGRectMake(0,0,0,.01)];self.tableView.sectionFooterHeight=.01;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:[UIColorPanelAppearance localizedString:@"Cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.tableView.accessibilityIdentifier=@"ui.choices.list";
}
// BINMAP-ADAPT: UIColorPanelChoiceController.viewDidLayoutSubviews
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if(self.navigationController.modalPresentationStyle==UIModalPresentationPopover){
        [self.tableView layoutIfNeeded];
        UIPopoverPresentationController *popover=self.navigationController.popoverPresentationController;
        UIView *container=popover.containerView?:self.sourceController.view;
        CGRect availableBounds=UIEdgeInsetsInsetRect(UIEdgeInsetsInsetRect(container.bounds,container.safeAreaInsets),popover.popoverLayoutMargins);
        CGFloat maximumHeight=MIN(540,CGRectGetHeight(availableBounds));
        CGFloat height=MIN(MAX(0,maximumHeight-self.navigationController.navigationBar.bounds.size.height),ceil(self.tableView.contentSize.height));
        // UINavigationController adds its bar to the child's preferred size.
        CGSize size=CGSizeMake(MIN(350,CGRectGetWidth(availableBounds)),height);
        if(!CGSizeEqualToSize(self.preferredContentSize,size)){
            self.preferredContentSize=size;
            // iOS 12 caches the initial navigation size across child updates.
            self.navigationController.preferredContentSize=CGSizeZero;
        }
    }
}
// BINMAP-ADAPT: UIColorPanelChoiceController.adaptivePresentationStyleForPresentationController:traitCollection:
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}
// BINMAP-ADAPT: UIColorPanelChoiceController.popoverPresentationController:willRepositionPopoverToRect:inView:
- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    [self.sourceController.view layoutIfNeeded];
    UIView *source=self.sourceView.window?self.sourceView:self.sourceController.view;
    if(source){*view=source;*rect=source.bounds;}
    [self.view setNeedsLayout];
}
// BINMAP-ADAPT: UIColorPanelChoiceController.numberOfSectionsInTableView:
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {return self.sections.count;}
// BINMAP-ADAPT: UIColorPanelChoiceController.tableView:numberOfRowsInSection:
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {return self.sections[section].items.count;}
// BINMAP-ADAPT: UIColorPanelChoiceController.tableView:titleForHeaderInSection:
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {return self.sections[section].title;}
// BINMAP-ADAPT: UIColorPanelChoiceController.tableView:cellForRowAtIndexPath:
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Choice"];if(!cell)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Choice"];
    UIColorPanelChoiceItem *item=self.sections[indexPath.section].items[indexPath.row];cell.textLabel.text=item.title;cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.textLabel.adjustsFontForContentSizeCategory=YES;cell.textLabel.numberOfLines=0;cell.textLabel.textAlignment=NSTextAlignmentNatural;
    if(!item.enabled){if(@available(iOS 13.0,*))cell.textLabel.textColor=UIColor.secondaryLabelColor;else cell.textLabel.textColor=UIColor.grayColor;}
    else if(item.destructive)cell.textLabel.textColor=UIColor.redColor;
    else {if(@available(iOS 13.0,*))cell.textLabel.textColor=UIColor.labelColor;else cell.textLabel.textColor=UIColor.blackColor;}
    cell.accessoryType=item.selected?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;cell.selectionStyle=item.enabled?UITableViewCellSelectionStyleDefault:UITableViewCellSelectionStyleNone;
    cell.accessibilityTraits=UIAccessibilityTraitButton|(item.selected?UIAccessibilityTraitSelected:0)|(!item.enabled?UIAccessibilityTraitNotEnabled:0);return cell;
}
// BINMAP-ADAPT: UIColorPanelChoiceController.tableView:shouldHighlightRowAtIndexPath:
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {return self.sections[indexPath.section].items[indexPath.row].enabled;}
// BINMAP-ADAPT: UIColorPanelChoiceController.tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];UIColorPanelChoiceItem *item=self.sections[indexPath.section].items[indexPath.row];if(item.enabled)[self finishWithHandler:item.handler];
}
// BINMAP-ADAPT: UIColorPanelChoiceController.cancel:
- (void)cancel:(id)sender {[self finishWithHandler:nil];}
// BINMAP-ADAPT: UIColorPanelChoiceController.finishWithHandler:
- (void)finishWithHandler:(void (^)(void))handler {
    if(self.finished)return;self.finished=YES;UINavigationController *navigation=self.navigationController;id<UIColorPanelTransientOwner> owner=self.transientOwner;BOOL owned=self.ownedPresentation;
    if(owned&&(!owner||!navigation||![owner isTransientPresentationCurrent:navigation]))return;
    __weak id<UIColorPanelTransientOwner> weakOwner=owner;__weak UIView *weakSource=self.sourceView;__weak UIViewController *weakController=self.sourceController;NSString *identifier=[self.sourceView.accessibilityIdentifier copy];void (^completion)(void)=[handler copy];
    [navigation dismissViewControllerAnimated:YES completion:^{
        id<UIColorPanelTransientOwner> currentOwner=weakOwner;if(owned&&(!currentOwner||![currentOwner isTransientPresentationCurrent:navigation]))return;
        if(completion)completion();
        if(owned&&(!weakOwner||![weakOwner isTransientPresentationCurrent:navigation]))return;
        UIViewController *controller=weakController;for(UIViewController *context=controller;context;context=context.parentViewController)if(context.presentedViewController&&!context.presentedViewController.isBeingDismissed)return;
        UIView *source=weakSource;
        if((!source.window||source.hidden)&&identifier.length&&controller.isViewLoaded){
            NSMutableArray<UIView *> *pending=[NSMutableArray arrayWithObject:controller.view];source=nil;
            while(pending.count){UIView *candidate=pending.lastObject;[pending removeLastObject];if(candidate.window&&!candidate.hidden&&[candidate.accessibilityIdentifier isEqualToString:identifier]){source=candidate;break;}[pending addObjectsFromArray:candidate.subviews];}
        }
        if(source.window&&!source.window.hidden&&!source.hidden)UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,source);
    }];
}
// BINMAP-ADAPT: UIColorPanelChoiceController.popoverPresentationControllerDidDismissPopover:
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    if(self.finished)return;self.finished=YES;if(self.ownedPresentation&&(!self.transientOwner||![self.transientOwner isTransientPresentationCurrent:popoverPresentationController.presentedViewController]))return;if(self.sourceView.window&&!self.sourceView.hidden)UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,self.sourceView);
}
@end
