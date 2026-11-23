#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface UIColorPickerCPTextField : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@property(nonatomic, strong, readonly) UITextField *view;
@property(nonatomic, copy) double (^getter)(void);
@property(nonatomic, copy) void (^setter)(double value);
@property(nonatomic, copy) NSString *(^conversionToString)(double value);
@property(nonatomic, copy) NSNumber * _Nullable (^conversionToValue)(NSString *text);
@property(nonatomic, copy) BOOL (^shouldChangeCharacters)(NSString *text,NSRange range,NSString *replacement);
@property(nonatomic) BOOL allowUpdatesWhileEditing, selectionOnNumber;
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic, readonly, getter=isEditing) BOOL editing;
- (instancetype)initWithGetter:(double (^)(void))getter setter:(void (^)(double value))setter allowUpdatesWhileEditing:(BOOL)allow selectionOnNumber:(BOOL)selection keyboardType:(UIKeyboardType)keyboard toString:(NSString *(^)(double value))toString toValue:(NSNumber * _Nullable (^)(NSString *text))toValue shouldChange:(BOOL (^)(NSString *text,NSRange range,NSString *replacement))shouldChange;
- (void)updateView;
- (void)refreshFont;
@end
NS_ASSUME_NONNULL_END
