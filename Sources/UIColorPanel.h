#import "UIPanel.h"
#import "UIColorPanelTypes.h"
#import "UIColorValue.h"
#import "UIColorList.h"
#import "UIColorPanelColorProfile.h"

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSNotificationName const UIColorPanelColorDidChangeNotification;
FOUNDATION_EXPORT NSNotificationName const UIPanelWillCloseNotification;

/// UIKit counterpart of NSColorPanel. Use on the main thread, like UIKit controls.
@interface UIColorPanel : UIPanel
@property(class, nonatomic, readonly, strong) UIColorPanel *sharedColorPanel;
@property(class, nonatomic, readonly) BOOL sharedColorPanelExists;
+ (void)setPickerMask:(UIColorPanelOptions)mask;
+ (void)setPickerMode:(UIColorPanelMode)mode;
@property(nonatomic, strong) UIColor *color;
/// Exact CGColor-backed alternative to the UIColor surface.
@property(nonatomic, strong) UIColorValue *colorValue;
@property(nonatomic) BOOL showsAlpha;
@property(nonatomic, readonly) CGFloat alpha;
@property(nonatomic, getter=isContinuous) BOOL continuous;
/// Zeroing weak is the UIKit ARC lifetime adaptation of AppKit's unretained target.
@property(nonatomic, weak, nullable) id target;
@property(nonatomic, nullable) SEL action;
@property(nonatomic) UIColorPanelMode mode;
@property(nonatomic, readonly) UIColorPanelOptions pickerMask;
@property(nonatomic, strong, nullable) UIView *accessoryView;
/// Opt-in for a caller-supplied image or app-owned view; default NO.
@property(nonatomic) BOOL allowsApplicationSampling;
@property(nonatomic, weak, nullable) UIView *samplingSourceView;
@property(nonatomic, strong, nullable) UIImage *samplingImage;
@property(nonatomic, copy) NSArray<UIColorPanelColorProfile *> *colorProfiles;
@property(nonatomic, copy, readonly) NSArray<UIColorPanelColorProfile *> *availableColorProfiles;
@property(nonatomic, strong, readonly, nullable) UIColorPanelColorProfile *activeColorProfile;
/// Converts to a compatible descriptor without prior registration. Valid pending edits
/// commit first. Reentrant requests during color delivery return SelectionSuppressed;
/// a callback that changes mode/source or closes the panel aborts the obsolete request.
- (BOOL)selectColorProfile:(UIColorPanelColorProfile *)profile error:(NSError * _Nullable * _Nullable)error;
- (void)refreshColorProfiles;
- (void)attachColorList:(UIColorList *)colorList;
- (void)detachColorList:(UIColorList *)colorList;
@end

/// Compatibility with the macOS 13 NSColor global alpha policy.
@interface UIColor (UIColorPanelSupport)
@property(class, nonatomic) BOOL ignoresAlpha;
@end

@interface UIApplication (UIColorPanelSupport)
- (void)orderFrontColorPanel:(nullable id)sender;
@end
NS_ASSUME_NONNULL_END
