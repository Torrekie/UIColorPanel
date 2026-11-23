#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Research-only application-process capability probe. Optional capability
/// failures are recorded separately from the baseline execution result.
@interface UIColorPanelRuntimeProfileProbe : NSObject
+ (BOOL)runWithOutputURL:(NSURL *)outputURL;
@end
NS_ASSUME_NONNULL_END
