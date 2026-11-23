#import <Foundation/Foundation.h>

@interface UIColorPanelAPIValidation : NSObject
/// Focused embedded-controller cases for the independent SDK host. Invoke on the main thread.
+ (NSArray<NSDictionary *> *)configurationSnapshotCases;
/// Invoke on the main thread after UIApplication has launched.
+ (BOOL)runWithOutputURL:(NSURL *)outputURL;
@end
