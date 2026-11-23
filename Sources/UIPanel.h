#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Public UIKit analogue of the small NSPanel window surface used by NSColorPanel.
/// Its owned window floats above its host; controls outside its rectangle remain usable.
@interface UIPanel : UIResponder
/// Actual UIKit presentation surface. Its UIView alpha is independent of color alpha.
@property(nonatomic, strong, readonly) UIWindow *window;
@property(nonatomic) CGRect frame;
/// Returns the owning panel for one of this library's windows, otherwise nil.
+ (nullable UIPanel *)panelForWindow:(nullable UIWindow *)window;
/// Optional private appearance/capture policy; default NO, additionally controlled by the build macro.
@property(nonatomic) BOOL use_spi;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, copy) NSString *title;
/// During an appearance transition this reports its target visibility.
@property(nonatomic, readonly, getter=isVisible) BOOL visible;
/// The panel owns its appearance animation; its frame and nonmodal scope stay unchanged.
@property(nonatomic, readonly, getter=isTransitioning) BOOL transitioning;
/// Optional explicit scene/position anchor. Set this before ordering the panel front.
@property(nonatomic, weak, nullable) UIViewController *presentationViewController;
- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithContentRect:(CGRect)contentRect;
- (void)orderFront:(nullable id)sender;
- (void)orderOut:(nullable id)sender;
- (void)close;
@end
NS_ASSUME_NONNULL_END
