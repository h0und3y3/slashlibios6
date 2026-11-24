#import <Foundation/Foundation.h>
typedef void (^SLAPICompletion)(id result, NSError *error);
@interface SLAPI : NSObject
+ (SLAPI *)shared;
- (void)get:(NSString *)path query:(NSDictionary *)query site:(NSInteger)site completion:(SLAPICompletion)completion;
- (void)search:(NSString *)query page:(NSInteger)page completion:(SLAPICompletion)completion;
- (void)chapters:(NSString *)slug site:(NSInteger)site completion:(SLAPICompletion)completion;
- (void)pages:(NSString *)slug chapter:(NSDictionary *)chapter site:(NSInteger)site completion:(SLAPICompletion)completion;
- (void)details:(NSString *)slug site:(NSInteger)site completion:(SLAPICompletion)completion;
- (void)me:(SLAPICompletion)completion;
- (void)catalogPage:(NSInteger)page genreID:(NSNumber *)genreID completion:(SLAPICompletion)completion;
- (void)genres:(SLAPICompletion)completion;
@end
