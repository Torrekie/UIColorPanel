#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Plain SwiftUI ColorTextField's public UIKit port. It owns a string only;
/// validation/Hex conversion remains the containing color model's decision.
@interface UIColorPickerColorTextField : UIControl
@property(nonatomic, copy) NSString *text;
@property(nonatomic, strong, readonly) UITextField *textField;
- (instancetype)initWithTitle:(NSString *)title width:(CGFloat)width text:(NSString *)text;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
