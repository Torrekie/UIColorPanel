#import <UIKit/UIKit.h>
#import "UIEyedropperColor.h"
NS_ASSUME_NONNULL_BEGIN
@class UIEyedropperLensView;
@protocol UIEyedropperLensViewDelegate <NSObject>
- (void)lensView:(UIEyedropperLensView *)lens didSelectColor:(UIColor *)color;
- (void)lensViewDidDismiss:(UIEyedropperLensView *)lens;
@end

@interface UIEyedropperGridView : UIView
@property(nonatomic,strong) UIColor *strokeColor;
- (instancetype)initWithWithCellCount:(NSInteger)count;
@end

/// Recovered lens/grid geometry; display-capture, input and animation imports use public adapters.
@interface UIEyedropperLensView : UIView
@property(nonatomic,weak,nullable) id<UIEyedropperLensViewDelegate> delegate;
@property(nonatomic) BOOL floatingMode;
@property(nonatomic) CGPoint lastPosition;
@property(nonatomic,strong,nullable) UIEyedropperSample *sample;
@property(nonatomic,copy,nullable) UIEyedropperSample * _Nullable (^samplingHandler)(CGPoint point);
@property(nonatomic,readonly) NSInteger lensState;
- (void)updateLensState:(NSInteger)state;
- (void)presentAtLocation:(CGPoint)location;
- (void)dismiss;
- (void)_dismissAndRemoveAlpha:(BOOL)removeAlpha;
- (void)_displayLinkFired;
- (NSInteger)_lensPosition;
@end
NS_ASSUME_NONNULL_END
