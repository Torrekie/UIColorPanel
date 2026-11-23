#import <UIKit/UIKit.h>
#import "UIColorValue.h"
NS_ASSUME_NONNULL_BEGIN
/// Image/application sources are frozen on iOS12+. The optional SPI source samples live.
/// All calls occur on the main thread. completionHandler is called once (nil means cancel).
@interface UIEyedropperViewController : UIViewController
- (instancetype)initWithSourceView:(UIView *)sourceView;
- (instancetype)initWithImage:(UIImage *)image;
/// Optional live display source; requires a private-enabled build and useSPI=YES.
/// Use presentLiveFromViewController: to begin. The host hides its panel surface first.
/// Failure is reported through sampleError; no frozen or application-view substitution occurs.
- (instancetype)initWithSystemScreen:(UIScreen *)screen useSPI:(BOOL)useSPI;
/// Source identity, including before presentation; public image/view sources return NO.
@property(nonatomic,readonly) BOOL liveSystemSampling;
/// Owns a transparent window on the host's screen/scene; does not change the host window.
- (void)presentLiveFromViewController:(UIViewController *)controller;
/// Stops capture and releases the owned window. An unfinished session completes as cancel.
- (void)dismissLiveWithCompletion:(nullable void (^)(void))completion;
@property(nonatomic,copy,nullable) void (^completionHandler)(UIColorValue * _Nullable color);
@property(nonatomic) BOOL use_spi;
@property(nonatomic,readonly) BOOL samplingAvailable;
@property(nonatomic,strong,readonly,nullable) NSError *sampleError;
@property(nonatomic,strong,readonly,nullable) UIColorValue *selectedColor;
/// Stable English scope key; user-facing text is localized through UIColorPanelAppearance.
@property(nonatomic,copy,readonly) NSString *sourceKind;
/// Empty for public sources. Live receipt describes the latest tile and capture backend.
@property(nonatomic,copy,readonly) NSDictionary *systemCaptureDetails;
/// Checks runtime support and the physical host's authorization for display-wide capture.
/// An individual capture can still fail after this preflight.
+ (BOOL)supportsSystemCapture;
/// Root-view coordinates; the host may forward its original TouchDown/drag through conversion.
/// Releasing that initiating touch leaves the live lens floating; commit remains explicit.
- (void)moveToPoint:(CGPoint)point;
- (void)commit;
- (void)cancel;
@end
NS_ASSUME_NONNULL_END
