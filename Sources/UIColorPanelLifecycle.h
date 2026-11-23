#import <UIKit/UIKit.h>

/// Internal bridge shared by panel-owned temporary pages. No host presentation is adopted implicitly.
@protocol UIColorPanelTransientOwner <NSObject>
@property(nonatomic, readonly) NSUInteger transientGeneration;
- (BOOL)prepareForTransientPresentation;
- (void)registerTransientPresentation:(UIViewController *)controller;
- (BOOL)isTransientPresentationCurrent:(UIViewController *)controller;
@end
