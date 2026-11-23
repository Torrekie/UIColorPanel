#import <Foundation/Foundation.h>
#import "UIColorValue.h"

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSNotificationName const UIColorListDidChangeNotification;
FOUNDATION_EXPORT NSExceptionName const UIColorListNotEditableException;

/// An ordered color list. Native keyed .clr files are the interchange format.
@interface UIColorList : NSObject
@property(class, nonatomic, readonly, copy) NSArray<UIColorList *> *availableColorLists;
+ (nullable UIColorList *)colorListNamed:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;
- (nullable instancetype)initWithName:(NSString *)name fromFile:(nullable NSString *)path;
@property(nonatomic, readonly, copy) NSString *name;
/// Presentation-only macOS translations for original built-ins; user names/keys remain exact.
@property(nonatomic, readonly, copy) NSString *localizedName;
- (NSString *)localizedColorNameWithKey:(NSString *)key;
@property(nonatomic, readonly, copy) NSArray<NSString *> *allKeys;
@property(nonatomic, readonly, getter=isEditable) BOOL editable;
#if TARGET_OS_IOS
- (void)setColor:(UIColor *)color forKey:(NSString *)key;
- (void)insertColor:(UIColor *)color key:(NSString *)key atIndex:(NSUInteger)index;
- (nullable UIColor *)colorWithKey:(NSString *)key;
#endif
- (void)setColorValue:(UIColorValue *)color forKey:(NSString *)key;
- (void)insertColorValue:(UIColorValue *)color key:(NSString *)key atIndex:(NSUInteger)index;
- (nullable UIColorValue *)colorValueWithKey:(NSString *)key;
- (void)removeColorWithKey:(NSString *)key;
/// nil saves into this application's Library/Colors directory and registers the list.
- (BOOL)writeToURL:(nullable NSURL *)url error:(NSError * _Nullable * _Nullable)error;
/// Removes an app-private saved list; imported source files are not deleted.
- (void)removeFile;
@end
NS_ASSUME_NONNULL_END
