#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface SLPageStore : NSObject
+ (NSString *)cacheDirectory;
+ (NSString *)cachedPathForURL:(NSString *)url;
+ (void)fetchURL:(NSString *)url completion:(void (^)(NSString *path, NSError *error))completion;
+ (UIImage *)thumbnailAtPath:(NSString *)path maxPixelSize:(NSUInteger)maxPixelSize;
+ (NSArray *)tilePathsAtPath:(NSString *)path maxPixelSize:(NSUInteger)maxPixelSize tilePixelHeight:(NSUInteger)tilePixelHeight;
+ (void)trimCacheToBytes:(unsigned long long)limit;
+ (unsigned long long)cacheSize;
+ (void)clearCache;
@end
