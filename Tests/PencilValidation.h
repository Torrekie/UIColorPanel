#import "UIColorPanelTypes.h"
#if UICOLORPANEL_ENABLE_PENCILS
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface PencilValidation : NSObject
/// Runs on the main thread after application startup; writes finite native comparison results.
+ (BOOL)runWithOutputURL:(NSURL *)url;
@end
NS_ASSUME_NONNULL_END
#endif
