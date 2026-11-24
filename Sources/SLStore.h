#import <Foundation/Foundation.h>
@interface SLStore : NSObject
+ (NSArray *)array:(NSString *)key;
+ (void)saveArray:(NSArray *)a key:(NSString *)key;
+ (BOOL)isFavorite:(NSDictionary *)title;
+ (void)toggleFavorite:(NSDictionary *)title;
+ (void)addHistory:(NSDictionary *)title chapter:(NSDictionary *)chapter;
+ (void)saveBookmark:(NSDictionary *)bookmark;
+ (void)updateRecent:(NSDictionary *)title chapter:(NSDictionary *)chapter page:(NSUInteger)page pageCount:(NSUInteger)pageCount;
+ (BOOL)isBookmarked:(NSString *)slug chapterID:(id)chapterID;
+ (void)removeBookmark:(NSString *)slug chapterID:(id)chapterID;
+ (void)markDeleted:(NSString *)kind record:(NSDictionary *)record;
+ (void)markRead:(NSString *)slug chapter:(id)chapterID;
+ (BOOL)isRead:(NSString *)slug chapter:(id)chapterID;
+ (NSString *)documents;
@end
