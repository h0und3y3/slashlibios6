#import <UIKit/UIKit.h>
@interface SLImageLoader : NSObject { NSCache *_cache; }
+ (SLImageLoader *)shared;
- (void)load:(NSString *)url completion:(void (^)(UIImage *image))completion;
- (void)load:(NSString *)url site:(NSInteger)site completion:(void (^)(UIImage *image))completion;
- (void)clear;
@end
