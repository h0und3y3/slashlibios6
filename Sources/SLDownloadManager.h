#import <Foundation/Foundation.h>
@interface SLDownloadManager : NSObject
+ (SLDownloadManager *)shared;
- (void)downloadChapter:(NSDictionary *)chapter slug:(NSString *)slug title:(NSString *)title site:(NSInteger)site;
- (NSArray *)downloads;
- (void)removeAll;
- (NSString *)localPathForSlug:(NSString *)slug chapter:(NSDictionary *)chapter;
@end
