#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Finite main-thread checks. Returns JSON-compatible results without writing
/// files, presenting controllers, or changing system locale/text-size settings.
FOUNDATION_EXPORT NSDictionary *runPolishValidation(void);
NS_ASSUME_NONNULL_END
