#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Immutable presentation-only descriptor. Its handler retains the caller's
/// established model/action route; capture the owning controller weakly.
@interface UIColorPanelChoiceItem : NSObject
@property(nonatomic, copy, readonly) NSString *title;
@property(nonatomic, readonly, getter=isSelected) BOOL selected;
@property(nonatomic, readonly, getter=isEnabled) BOOL enabled;
@property(nonatomic, readonly, getter=isDestructive) BOOL destructive;
@property(nonatomic, copy, readonly, nullable) void (^handler)(void);
+ (instancetype)itemWithTitle:(NSString *)title selected:(BOOL)selected enabled:(BOOL)enabled destructive:(BOOL)destructive handler:(void (^ _Nullable)(void))handler;
@end

@interface UIColorPanelChoiceSection : NSObject
@property(nonatomic, copy, readonly, nullable) NSString *title;
@property(nonatomic, copy, readonly) NSArray<UIColorPanelChoiceItem *> *items;
+ (instancetype)sectionWithTitle:(nullable NSString *)title items:(NSArray<UIColorPanelChoiceItem *> *)items;
@end

/// Public UIKit alternative for iOS12/13 single-tap selection. Multiple sections
/// retain independent checkmarks (for example precision and color profile).
@interface UIColorPanelChoiceController : UITableViewController
@property(nonatomic, copy, readonly) NSArray<UIColorPanelChoiceSection *> *sections;
- (instancetype)initWithTitle:(NSString *)title sections:(NSArray<UIColorPanelChoiceSection *> *)sections;
/// Regular width: anchored popover. Compact width: a titled navigation page
/// with Cancel. Selecting dismisses before invoking one handler; Cancel invokes
/// none. Returns nil if the presenter already owns a presented controller.
+ (nullable instancetype)presentFromViewController:(UIViewController *)presenter title:(NSString *)title sections:(NSArray<UIColorPanelChoiceSection *> *)sections sourceView:(nullable UIView *)sourceView;
@end

NS_ASSUME_NONNULL_END
