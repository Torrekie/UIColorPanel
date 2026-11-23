#import "UIColorPanelMenuButton.h"
#import "UIColorPanelAppearance.h"
#import "UIColorPanelLifecycle.h"
#import <math.h>

API_AVAILABLE(ios(13.0))
@interface UIColorPanelMenuInteractionDelegate : NSObject <UIContextMenuInteractionDelegate>
@property(nonatomic, weak) UIColorPanelMenuButton *button;
@end

@implementation UIColorPanelMenuInteractionDelegate
// BINMAP-ADAPT: UIColorPanelMenuInteractionDelegate.contextMenuInteraction:configurationForMenuAtLocation:
- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    UIColorPanelMenuButton *button=self.button;
    if(!button.enabled || !button.menuProvider)return nil;
    id<UIColorPanelTransientOwner> owner=nil;
    for(UIResponder *responder=button;responder&&!owner;responder=responder.nextResponder)if([responder isKindOfClass:UIViewController.class])for(UIViewController *context=(id)responder;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    if(owner&&![owner prepareForTransientPresentation])return nil;
    BOOL owned=owner!=nil;NSUInteger generation=owner.transientGeneration;__weak id<UIColorPanelTransientOwner> weakOwner=owner;
    __weak UIColorPanelMenuButton *weakButton=button;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> *suggestedActions){
        UIColorPanelMenuButton *target=weakButton;
        id<UIColorPanelTransientOwner> currentOwner=weakOwner;if(owned&&(!currentOwner||currentOwner.transientGeneration!=generation||![currentOwner prepareForTransientPresentation]))return nil;
        return target.enabled && target.menuProvider ? target.menuProvider() : nil;
    }];
}
@end

@interface UIColorPanelMenuButton ()
@property(nonatomic, strong) NSObject *longPressMenuDelegate;
@property(nonatomic) CGFloat lastLayoutWidth;
@property(nonatomic, strong) UIStackView *contentStack;
@property(nonatomic, strong) UILabel *menuTitle;
@property(nonatomic, strong) UIImageView *menuImage;
@property(nonatomic, strong) NSLayoutConstraint *imageWidth;
@property(nonatomic, strong) NSLayoutConstraint *imageHeight;
@end

@implementation UIColorPanelMenuButton
@synthesize menuProvider = _menuProvider;

// BINMAP-ADAPT: UIColorPanelMenuButton.initWithFrame:
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeading;
        self.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.titleLabel.adjustsFontForContentSizeCategory=YES;self.titleLabel.numberOfLines=2;self.titleLabel.lineBreakMode=NSLineBreakByTruncatingTail;self.titleLabel.textAlignment=NSTextAlignmentNatural;
        self.contentEdgeInsets=UIEdgeInsetsMake(8,12,8,12);
        self.menuTitle=[UILabel new];self.menuTitle.numberOfLines=2;self.menuTitle.lineBreakMode=NSLineBreakByTruncatingTail;self.menuTitle.textAlignment=NSTextAlignmentNatural;self.menuTitle.adjustsFontForContentSizeCategory=YES;
        self.menuImage=[UIImageView new];self.menuImage.contentMode=UIViewContentModeScaleAspectFit;
        self.contentStack=[[UIStackView alloc]initWithArrangedSubviews:@[self.menuTitle,self.menuImage]];self.contentStack.spacing=6;self.contentStack.alignment=UIStackViewAlignmentCenter;self.contentStack.userInteractionEnabled=NO;self.contentStack.isAccessibilityElement=NO;self.contentStack.accessibilityElementsHidden=YES;self.contentStack.translatesAutoresizingMaskIntoConstraints=NO;[self addSubview:self.contentStack];
        self.imageWidth=[self.menuImage.widthAnchor constraintEqualToConstant:13];self.imageHeight=[self.menuImage.heightAnchor constraintEqualToConstant:13];
        [NSLayoutConstraint activateConstraints:@[[self.contentStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],[self.contentStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],[self.contentStack.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],[self.contentStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],self.imageWidth,self.imageHeight]];
        self.displaysMoreActions=NO;
        if (@available(iOS 14.0, *)) {
            // UIButton creates and owns its menu interaction on this version.
        } else if (@available(iOS 13.0, *)) {
            UIColorPanelMenuInteractionDelegate *delegate=[UIColorPanelMenuInteractionDelegate new];
            delegate.button=self;
            self.longPressMenuDelegate=delegate;
            UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:delegate];
            [self addInteraction:interaction];
        }
    }
    return self;
}

// BINMAP-ADAPT: UIColorPanelMenuButton.setMenuProvider:
- (void)setMenuProvider:(UIMenu * _Nullable (^)(void))menuProvider API_AVAILABLE(ios(13.0)) {
    _menuProvider = [menuProvider copy];
    if (@available(iOS 14.0, *)) {
        self.showsMenuAsPrimaryAction = (_menuProvider != nil);
    } else if (@available(iOS 13.0, *)) {
        NSString *hint = [UIColorPanelAppearance localizedString:@"Touch and hold to show options."];
        if (_menuProvider && !self.accessibilityHint.length) {
            self.accessibilityHint = hint;
        } else if (!_menuProvider && [self.accessibilityHint isEqualToString:hint]) {
            self.accessibilityHint = nil;
        }
    }
    [self reloadMenu];
}

// BINMAP-ADAPT: UIColorPanelMenuButton.setDisplaysMoreActions:
- (void)setDisplaysMoreActions:(BOOL)displaysMoreActions {
    _displaysMoreActions=displaysMoreActions;
    self.menuImage.image=[UIColorPanelAppearance imageForSymbol:displaysMoreActions?@"ellipsis.circle":@"chevron.down" size:displaysMoreActions?22:13];
    self.menuTitle.hidden=displaysMoreActions;self.imageWidth.constant=displaysMoreActions?20:13;self.imageHeight.constant=displaysMoreActions?20:13;
    if(displaysMoreActions)[self setTitle:nil forState:UIControlStateNormal];
    [self invalidateIntrinsicContentSize];[self setNeedsLayout];
}

// BINMAP-ADAPT: UIColorPanelMenuButton.setTitle:forState:
- (void)setTitle:(NSString *)title forState:(UIControlState)state {[super setTitle:title forState:state];self.menuTitle.text=self.currentTitle;self.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];self.menuTitle.font=self.titleLabel.font;[self invalidateIntrinsicContentSize];[self setNeedsLayout];}

// BINMAP-ADAPT: UIColorPanelMenuButton.intrinsicContentSize
- (CGSize)intrinsicContentSize {
    if(self.displaysMoreActions)return CGSizeMake(44,44);
    CGSize text=[self.menuTitle sizeThatFits:CGSizeMake(self.bounds.size.width>0?MAX(1,self.bounds.size.width-43):320,CGFLOAT_MAX)];
    return CGSizeMake(ceil(text.width)+43,MAX(44,ceil(text.height)+16));
}
// BINMAP-ADAPT: UIColorPanelMenuButton.layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.hidden=YES;self.imageView.hidden=YES;
    self.menuTitle.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];self.menuTitle.text=self.currentTitle;self.menuTitle.textColor=self.currentTitleColor;
    self.contentStack.alpha=!self.enabled?.35:(self.highlighted?.5:1);
    self.contentStack.semanticContentAttribute=self.semanticContentAttribute;
    if(self.lastLayoutWidth!=self.bounds.size.width){self.lastLayoutWidth=self.bounds.size.width;[self invalidateIntrinsicContentSize];}
}
// BINMAP-ADAPT: UIColorPanelMenuButton.setHighlighted:
- (void)setHighlighted:(BOOL)highlighted {[super setHighlighted:highlighted];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanelMenuButton.setEnabled:
- (void)setEnabled:(BOOL)enabled {[super setEnabled:enabled];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanelMenuButton.tintColorDidChange
- (void)tintColorDidChange {[super tintColorDidChange];[self setNeedsLayout];}
// BINMAP-ADAPT: UIColorPanelMenuButton.headerWithSelectionButton:actionsButton:
+ (UIStackView *)headerWithSelectionButton:(UIColorPanelMenuButton *)selection actionsButton:(UIColorPanelMenuButton *)actions {
    UIStackView *header=[[UIStackView alloc]initWithArrangedSubviews:@[selection,actions]];
    header.spacing=4;header.alignment=UIStackViewAlignmentCenter;header.layoutMarginsRelativeArrangement=YES;header.directionalLayoutMargins=NSDirectionalEdgeInsetsMake(6,12,6,12);
    [actions.widthAnchor constraintEqualToConstant:44].active=YES;
    [selection setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [header setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return header;
}

// BINMAP-ADAPT: UIColorPanelMenuButton.traitCollectionDidChange:
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];self.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.traitCollection];self.menuTitle.font=self.titleLabel.font;[self invalidateIntrinsicContentSize];[self setNeedsLayout];
}

// BINMAP-ADAPT: UIColorPanelMenuButton.usesPrimaryMenu
- (BOOL)usesPrimaryMenu {
    if (@available(iOS 14.0, *)) {
        return _menuProvider != nil;
    }
    return NO;
}

// BINMAP-ADAPT: UIColorPanelMenuButton.reloadMenu
- (void)reloadMenu {
    if (@available(iOS 14.0, *)) {
        self.menu = _menuProvider ? _menuProvider() : nil;
        self.showsMenuAsPrimaryAction = (_menuProvider != nil);
    }
}

// BINMAP-ADAPT: UIColorPanelMenuButton.contextMenuInteraction:configurationForMenuAtLocation:
- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(14.0)) {
    id<UIColorPanelTransientOwner> owner=nil;
    for(UIResponder *responder=self;responder&&!owner;responder=responder.nextResponder)if([responder isKindOfClass:UIViewController.class])for(UIViewController *context=(id)responder;context;context=context.parentViewController)if([context conformsToProtocol:@protocol(UIColorPanelTransientOwner)]){owner=(id)context;break;}
    if(owner&&![owner prepareForTransientPresentation])return nil;
    [self reloadMenu];
    return [super contextMenuInteraction:interaction configurationForMenuAtLocation:location];
}

@end
