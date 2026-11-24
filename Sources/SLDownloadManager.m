#import "SLDownloadManager.h"
#import "SLAPI.h"
#import "SLStore.h"
static NSOperationQueue *SLDownloadQueue(void){static NSOperationQueue *q=nil;if(!q){q=[[NSOperationQueue alloc]init];q.maxConcurrentOperationCount=[[NSUserDefaults standardUserDefaults]boolForKey:@"SLEnergySaving"]?1:3;}return q;}
@implementation SLDownloadManager
+ (SLDownloadManager *)shared { static SLDownloadManager *s=nil;if(!s)s=[[SLDownloadManager alloc]init];return s; }
- (NSString *)safe:(NSString *)s { NSString *v=[s stringByReplacingOccurrencesOfString:@"/" withString:@"_"];v=[v stringByReplacingOccurrencesOfString:@".." withString:@"_"];return v?:@"item"; }
- (NSString *)localPathForSlug:(NSString *)slug chapter:(NSDictionary *)ch { NSString *base=[NSString stringWithFormat:@"%@/SlashlibOffline/%@_%@_%@",[SLStore documents],[self safe:slug],[self safe:[[ch objectForKey:@"volume"]description]?:@"0"],[self safe:[[ch objectForKey:@"number"]description]?:@"0"]];return base; }
- (NSArray *)downloads { return [[NSUserDefaults standardUserDefaults]objectForKey:@"SLDownloaded"]?:[NSArray array]; }
- (NSDictionary *)downloadedChapterForSlug:(NSString *)slug chapterID:(id)chapterID { for(NSDictionary *d in [self downloads])if([[d objectForKey:@"slug"]isEqualToString:slug]&&[[[d objectForKey:@"chapter"]objectForKey:@"id"]description]&&[[[[d objectForKey:@"chapter"]objectForKey:@"id"]description]isEqualToString:[chapterID description]])return d;return nil; }
- (void)downloadChapter:(NSDictionary *)ch slug:(NSString *)slug title:(NSString *)title site:(NSInteger)site {
    [[SLAPI shared]pages:slug chapter:ch site:site completion:^(id root,NSError *err){
        NSArray *pages=[[root objectForKey:@"data"]objectForKey:@"pages"];if(err||![pages isKindOfClass:[NSArray class]]||![pages count])return;
        NSString *dir=[self localPathForSlug:slug chapter:ch];[[NSFileManager defaultManager]createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        NSOperationQueue *queue=SLDownloadQueue();NSMutableArray *names=[NSMutableArray array];NSUInteger idx=0;
        for(NSDictionary *page in pages){NSString *u=[page objectForKey:@"url"];if(![u isKindOfClass:[NSString class]])continue;if([u rangeOfString:@"http"].location!=0)u=[@"https:" stringByAppendingString:u];NSString *name=[NSString stringWithFormat:@"%03lu.jpg",(unsigned long)idx++];[names addObject:name];NSString *path=[dir stringByAppendingPathComponent:name];[queue addOperationWithBlock:^{NSURLRequest *req=[NSURLRequest requestWithURL:[NSURL URLWithString:u] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:90];NSURLResponse *response=nil;NSError *e=nil;NSData *data=[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&e];if(data&&[data length]>0)[data writeToFile:path atomically:YES];}];}
        if(![names count])return;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{[queue waitUntilAllOperationsAreFinished];NSUInteger valid=0;for(NSString *n in names)if([[NSFileManager defaultManager]fileExistsAtPath:[dir stringByAppendingPathComponent:n]])valid++;if(!valid)return;
            NSMutableDictionary *record=[NSMutableDictionary dictionaryWithObjectsAndKeys:slug,@"slug",title?:slug,@"title",ch,@"chapter",dir,@"path",names,@"pages",[NSNumber numberWithDouble:[[NSDate date]timeIntervalSince1970]],@"date",nil];
            NSMutableArray *all=[NSMutableArray arrayWithArray:[self downloads]];BOOL replaced=NO;for(NSUInteger i=0;i<[all count];i++){NSDictionary *old=[all objectAtIndex:i];if([[old objectForKey:@"slug"]isEqualToString:slug]&&[[[[old objectForKey:@"chapter"]objectForKey:@"id"]description]isEqualToString:[[ch objectForKey:@"id"]description]]){[all replaceObjectAtIndex:i withObject:record];replaced=YES;break;}}if(!replaced)[all insertObject:record atIndex:0];[SLStore saveArray:all key:@"SLDownloaded"];
        });
    }];
}
- (void)removeAll { for(NSDictionary *d in [self downloads])[[NSFileManager defaultManager]removeItemAtPath:[d objectForKey:@"path"] error:nil];[[NSUserDefaults standardUserDefaults]removeObjectForKey:@"SLDownloaded"];[[NSUserDefaults standardUserDefaults]synchronize]; }
@end
