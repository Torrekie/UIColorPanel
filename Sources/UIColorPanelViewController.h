#import <UIKit/UIKit.h>
#import "UIColorValue.h"
#import "UIColorPanelTypes.h"
#import "UIColorList.h"
#import "UIColorPanelColorProfile.h"

NS_ASSUME_NONNULL_BEGIN
@class UIColorPickerFavoritesStore;

@interface UIColorPalette : NSObject
@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, copy, readonly) NSArray<UIColorValue *> *colors;
@property(nonatomic, copy, readonly) NSArray<NSString *> *names;
- (instancetype)initWithName:(NSString *)name colors:(NSArray<UIColorValue *> *)colors names:(NSArray<NSString *> *)names;
@end

@interface UIColorPanelConfiguration : NSObject <NSCopying>
/// Default NO. Enables compiled private features, including accessible system picker favorites on iOS 14+.
@property(nonatomic) BOOL use_spi;
@property(nonatomic) BOOL showsAlpha;
/// Default YES. Hides opacity editing and translucent favorites when NO; retains the selected color and stored favorites.
@property(nonatomic) BOOL supportsAlpha;
@property(nonatomic) UIColorPanelMode initialMode;
@property(nonatomic, copy) NSArray<UIColorPalette *> *palettes;
/// Key in the app's standard defaults when automatic storage uses the app-local library.
/// An unspecified key selects the same library as the shared panel.
@property(nonatomic, copy, nullable) NSString *savedColorsKey;
/// An explicit store takes precedence over automatic system and app-local favorites, including when SPI is enabled.
@property(nonatomic, strong, nullable) UIColorPickerFavoritesStore *favoritesStore;
/// Caller-authorized image. The optional Import action uses Files on iOS12+; no Photos permission key is required.
@property(nonatomic, strong, nullable) UIImage *samplingImage;
/// Explicit public sampling opt-in. Never captures other apps or the system display.
@property(nonatomic) BOOL allowsApplicationSampling;
@property(nonatomic, weak, nullable) UIView *samplingSourceView;
/// Additional ICC/working profiles. Standard and current-source profiles remain available.
@property(nonatomic, copy) NSArray<UIColorPanelColorProfile *> *colorProfiles;
@end

@class UIColorPanelViewController;
@protocol UIColorPanelViewControllerDelegate <NSObject>
- (void)colorPanel:(UIColorPanelViewController *)panel didSelectColor:(UIColorValue *)color;
@optional
- (void)colorPanelDidFinish:(UIColorPanelViewController *)panel;
- (void)colorPanelWillBeginEditing:(UIColorPanelViewController *)panel;
- (void)colorPanelDidEndEditing:(UIColorPanelViewController *)panel;
@end

/// Main-thread UIKit controller. Delegate callbacks are delivered on that thread.
@interface UIColorPanelViewController : UIViewController
/// Optional private features require both this runtime switch and UICOLORPANEL_ENABLE_PRIVATE_API=1.
@property(nonatomic) BOOL use_spi;
@property(nonatomic, weak, nullable) id<UIColorPanelViewControllerDelegate> delegate;
@property(nonatomic, strong) UIColorValue *selectedColor;
@property(nonatomic) UIColorPanelMode mode;
@property(nonatomic) UIColorPanelOptions pickerMask;
@property(nonatomic) BOOL showsAlpha;
/// Independent of showsAlpha. NO hides opacity editing and translucent favorites without changing selectedColor.
@property(nonatomic) BOOL supportsAlpha;
@property(nonatomic) BOOL alphaEditingEnabled;
@property(nonatomic, strong, nullable) UIView *accessoryView;
@property(nonatomic) BOOL allowsApplicationSampling;
@property(nonatomic, weak, nullable) UIView *samplingSourceView;
@property(nonatomic, strong, nullable) UIImage *samplingImage;
@property(nonatomic, copy) NSArray<UIColorPanelColorProfile *> *colorProfiles;
/// All known profiles; each numeric model's menu filters by its compatible color-space model.
@property(nonatomic, copy, readonly) NSArray<UIColorPanelColorProfile *> *availableColorProfiles;
/// Current numeric model's working space; nil outside the four slider modes.
@property(nonatomic, strong, readonly, nullable) UIColorPanelColorProfile *activeColorProfile;
/// Converts to any compatible descriptor; prior registration is not required.
/// Commits valid pending edits first. A failed conversion leaves that committed color
/// and working profile unchanged. If a commit callback changes mode/source or closes
/// the panel, the obsolete request returns SelectionSuppressed without conversion.
- (BOOL)selectColorProfile:(UIColorPanelColorProfile *)profile error:(NSError * _Nullable * _Nullable)error;
/// Refreshes optional system discovery when compiled and runtime-enabled; never blocks the UI.
- (void)refreshColorProfiles;
/// Re-reads the configured favorites backing on the main thread, without changing selectedColor or sending a selection callback.
/// An unloaded controller reads its backing when its view loads. An in-memory favorites library is unaffected.
- (void)refreshFavorites;
- (void)attachColorList:(UIColorList *)colorList;
- (void)detachColorList:(UIColorList *)colorList;
/// Takes a configuration snapshot at initialization. An explicit favorites store and
/// sampling image retain their identity, and the sampling source view stays weak.
- (instancetype)initWithColor:(UIColorValue *)color configuration:(UIColorPanelConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
