#import <UIKit/UIKit.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN
/// Classic AppKit-style color well. UIColorWell is a different system UIKit class.
@interface UIColorPanelWell : UIControl
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColorValue *colorValue;
/// Zeroing-weak is the mobile lifetime adaptation of AppKit's unretained target.
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, nullable) SEL action;
@property (nonatomic, readonly, getter=isActive) BOOL active;
@property (nonatomic, getter=isContinuous) BOOL continuous;
@property (nonatomic, getter=isBordered) BOOL bordered;
@property (nonatomic) BOOL orderColorPanelOnActivate;
- (void)activate:(BOOL)exclusive;
- (void)deactivate;
- (void)takeColorFrom:(id)sender;
- (BOOL)sendAction:(nullable SEL)action to:(nullable id)target;
@end
NS_ASSUME_NONNULL_END
