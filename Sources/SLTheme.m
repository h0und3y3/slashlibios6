#import "SLTheme.h"
@implementation SLTheme
+ (BOOL)isDark { NSInteger mode=[[NSUserDefaults standardUserDefaults]integerForKey:@"SLThemeMode"];if(mode==1)return YES;if(mode==2){NSDateComponents *c=[[NSCalendar currentCalendar]components:NSHourCalendarUnit fromDate:[NSDate date]];NSInteger h=[c hour];return h>=21||h<7;}return NO; }
+ (UIColor *)backgroundColor{return [self isDark]?[UIColor colorWithWhite:0.10 alpha:1.0]:[UIColor whiteColor];}
+ (UIColor *)textColor{return [self isDark]?[UIColor colorWithWhite:0.94 alpha:1.0]:[UIColor blackColor];}
+ (void)apply {UIColor *tint=[self isDark]?[UIColor colorWithRed:0.30 green:0.32 blue:0.36 alpha:1]:[UIColor colorWithRed:0.22 green:0.45 blue:0.72 alpha:1];[[UINavigationBar appearance]setTintColor:tint];[[UINavigationBar appearance]setBarStyle:[self isDark]?UIBarStyleBlack:UIBarStyleDefault];[[UITabBar appearance]setTintColor:tint];[[UITabBar appearance]setBarStyle:[self isDark]?UIBarStyleBlack:UIBarStyleDefault];[[UIToolbar appearance]setTintColor:tint];}
@end
