#import <UIKit/UIKit.h>
@interface SLTheme : NSObject
+ (void)apply;
+ (UIColor *)backgroundColor;
+ (UIColor *)textColor;
+ (BOOL)isDark;
@end
