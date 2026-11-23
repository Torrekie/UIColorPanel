#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class UIColorPickerImagePaletteController;
@protocol UIColorPickerImagePaletteControllerDelegate <NSObject>
- (void)colorPickerImagePalette:(UIColorPickerImagePaletteController *)controller didSelectImage:(UIImage *)image;
@end
/// Compact selector/action row for named app-private image palettes.
/// Embed above the panel's single sampler at preferredContentSize.height (a fitting height of at least 44 points after loading).
/// currentImage and the delegate supply that sampler; this controller draws no duplicate preview.
@interface UIColorPickerImagePaletteController : UIViewController
@property(nonatomic, weak, nullable) id<UIColorPickerImagePaletteControllerDelegate> delegate;
@property(nonatomic, strong, readonly) UIImage *currentImage;
/// Distinguishes the analytic Spectrum from user-supplied image palettes.
@property(nonatomic, readonly, getter=isBuiltInSpectrumSelected) BOOL builtInSpectrumSelected;
/// Opaque sRGB image used for the built-in image palette and its Copy action.
+ (UIImage *)defaultSpectrumImage;
- (instancetype)initWithSpectrum:(UIImage *)spectrum NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
