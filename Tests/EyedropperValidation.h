#import <Foundation/Foundation.h>
@class UIView;
@interface UIEyedropperValidation : NSObject
+ (BOOL)runWithOutputURL:(NSURL *)url;
/// Synchronous image-scoped pan-handler cases attached to the supplied host.
/// Programmatic recognizer states/coordinates, not real touch injection.
+ (NSArray<NSDictionary *> *)grabOffsetCasesInView:(UIView *)hostView;
/// Asynchronous private-test-only real interface rotation and screen sampling.
/// Keeps the frozen picker open through rotation and checks touch/AX mapping.
/// Left commits once; right cancels once. Writes after dismissal/restoration.
+ (void)runOrientationWithOutputURL:(NSURL *)url;
@end
