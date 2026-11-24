#import <Foundation/Foundation.h>
@interface SLSyncService : NSObject
+ (void)syncWithToken:(NSString *)token completion:(void (^)(NSString *message))completion;
@end
