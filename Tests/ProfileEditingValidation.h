#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface UIColorPanelProfileEditingValidation : NSObject
/// Finite, main-thread checks of production profile APIs and numeric controls.
+ (BOOL)runWithOutputURL:(NSURL *)outputURL;
@end
NS_ASSUME_NONNULL_END
