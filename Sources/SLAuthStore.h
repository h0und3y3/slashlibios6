#import <Foundation/Foundation.h>
@interface SLAuthStore : NSObject
+ (NSString *)token;
+ (void)setToken:(NSString *)token;
+ (NSString *)siteToken;
+ (void)setSiteToken:(NSString *)token;
@end
