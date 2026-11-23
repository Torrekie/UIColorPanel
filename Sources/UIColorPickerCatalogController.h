#import <UIKit/UIKit.h>
#import "UIColorList.h"
NS_ASSUME_NONNULL_BEGIN
@class UIColorPickerCatalogController;
@protocol UIColorPickerCatalogControllerDelegate <NSObject>
- (void)colorPickerCatalog:(UIColorPickerCatalogController *)catalog didSelectColorValue:(UIColorValue *)color;
@optional
- (void)colorPickerCatalogDidChangeLists:(UIColorPickerCatalogController *)catalog;
@end
/// Embeddable named-color provider with compact chooser/search/actions and one scrolling list.
/// Use Auto Layout fitting at the available width to preserve the header, search and one color row.
/// Layout updates the minimum list height for the current first result or empty state and text size.
/// Existing document and list-management routes are available from the ellipsis action.
@interface UIColorPickerCatalogController : UIViewController
@property(nonatomic, weak, nullable) id<UIColorPickerCatalogControllerDelegate> delegate;
@property(nonatomic, strong) UIColorValue *selectedColor;
@property(nonatomic, copy, readonly) NSArray<UIColorList *> *colorLists;
@property(nonatomic, strong, readonly, nullable) UIColorList *currentColorList;
- (instancetype)initWithColorLists:(NSArray<UIColorList *> *)lists selectedColor:(UIColorValue *)color;
- (void)reloadCatalog;
/// Synchronizes the highlighted row. User-driven list changes may choose a near match.
- (void)selectMatchingColorAndNotify:(BOOL)notify;
- (void)attachColorList:(UIColorList *)list;
- (void)detachColorList:(UIColorList *)list;
@end
NS_ASSUME_NONNULL_END
