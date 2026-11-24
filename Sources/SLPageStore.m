#import "SLPageStore.h"
#import <ImageIO/ImageIO.h>
#import <CommonCrypto/CommonDigest.h>
#import <dispatch/dispatch.h>
#import <string.h>


static NSMutableSet *SLActivePageDownloads = nil;
@interface SLPageStreamDownload : NSObject <NSURLConnectionDataDelegate> {
    NSURLConnection *_connection; NSOutputStream *_stream; NSString *_path;
    void (^_completion)(NSString *, NSError *); NSError *_failure; long long _received; BOOL _finished;
}
- (id)initWithRequest:(NSURLRequest *)request path:(NSString *)path completion:(void (^)(NSString *, NSError *))completion;
- (void)start;
@end
@implementation SLPageStreamDownload
- (id)initWithRequest:(NSURLRequest *)request path:(NSString *)path completion:(void (^)(NSString *, NSError *))completion {
    if ((self=[super init])) {
        _path=[path copy]; _completion=[completion copy];
        NSString *tmp=[path stringByAppendingString:@".download"];
        [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil];
        _stream=[[NSOutputStream outputStreamToFileAtPath:tmp append:NO] retain]; [_stream open];
        _connection=[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        if (!_connection || _stream.streamStatus==NSStreamStatusError) { _failure=[[_stream streamError] retain]; if(!_failure) _failure=[[NSError errorWithDomain:@"SLPageStore" code:4 userInfo:nil] retain]; }
    }
    return self;
}
- (void)start { if(!_connection || _failure) { [self finish:NO]; return; } [_connection start]; }
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger status=[(NSHTTPURLResponse *)response statusCode];
        if(status<200 || status>=300) { _failure=[[NSError errorWithDomain:@"SLPageStore" code:status userInfo:[NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:status] forKey:NSLocalizedDescriptionKey]] retain]; [_connection cancel]; [self finish:NO]; }
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    const uint8_t *bytes=(const uint8_t *)[data bytes]; NSUInteger left=[data length];
    while(left) { NSInteger n=[_stream write:bytes maxLength:left]; if(n<=0) { _failure=[[_stream streamError] retain]; [_connection cancel]; [self finish:NO]; return; } bytes+=n; left-=(NSUInteger)n; _received+=n; }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection { [self finish:(_received>0)]; }
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error { if(!_failure) _failure=[error retain]; [self finish:NO]; }
- (void)finish:(BOOL)success {
    if(_finished) return; _finished=YES;
    [[self retain] autorelease];
    [_stream close];
    NSString *tmp=[_path stringByAppendingString:@".download"];
    NSError *error=_failure;
    if(success) {
        [[NSFileManager defaultManager] removeItemAtPath:_path error:nil];
        if(![[NSFileManager defaultManager] moveItemAtPath:tmp toPath:_path error:&error]) success=NO;
    }
    if(!success) [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil];
    if(!success && !error) error=[NSError errorWithDomain:@"SLPageStore" code:5 userInfo:[NSDictionary dictionaryWithObject:@"Не удалось получить данные страницы" forKey:NSLocalizedDescriptionKey]];
    if(_completion) { _completion(success?_path:nil,error); [_completion release]; _completion=nil; }
    [_connection cancel]; [_connection release]; _connection=nil;
    [_stream release]; _stream=nil;
    [SLActivePageDownloads removeObject:self];
}
- (void)dealloc { [_connection release]; [_stream release]; [_path release]; [_completion release]; [_failure release]; [super dealloc]; }
@end

@implementation SLPageStore
+ (NSString *)cacheDirectory {
    static NSString *dir = nil;
    if (!dir) {
        NSString *base = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        dir = [[base stringByAppendingPathComponent:@"SlashlibPages"] copy];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}
+ (NSString *)keyForURL:(NSString *)url {
    const char *bytes = [url UTF8String]; unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(bytes, (CC_LONG)strlen(bytes), digest);
    NSMutableString *s = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    unsigned int i; for (i=0; i<CC_SHA1_DIGEST_LENGTH; i++) [s appendFormat:@"%02x", digest[i]];
    return s;
}
+ (NSString *)cachedPathForURL:(NSString *)url {
    if (![url isKindOfClass:[NSString class]] || ![url length]) return nil;
    return [[self cacheDirectory] stringByAppendingPathComponent:[self keyForURL:url]];
}
 + (void)fetchURL:(NSString *)url completion:(void (^)(NSString *, NSError *))completion {
    NSString *path=[self cachedPathForURL:url];
    if(!path) { if(completion) completion(nil,[NSError errorWithDomain:@"SLPageStore" code:1 userInfo:nil]); return; }
    NSDictionary *attrs=[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    if([[attrs objectForKey:NSFileSize] unsignedLongLongValue]>0) {
        [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:path error:nil];
        if(completion) completion(path,nil); return;
    }
    NSURL *u=[NSURL URLWithString:url]; if(!u && [url hasPrefix:@"//"]) u=[NSURL URLWithString:[@"https:" stringByAppendingString:url]];
    if(!u) { if(completion) completion(nil,[NSError errorWithDomain:@"SLPageStore" code:2 userInfo:nil]); return; }
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:u cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90];
    [req setValue:@"Slashlib-iOS6" forHTTPHeaderField:@"User-Agent"];
    [req setValue:@"https://slashlib.me/" forHTTPHeaderField:@"Referer"];
    [req setValue:@"image/jpeg,image/png,image/webp,image/*;q=0.8" forHTTPHeaderField:@"Accept"];
    if(!SLActivePageDownloads) SLActivePageDownloads=[[NSMutableSet alloc]init];
    SLPageStreamDownload *download=[[[SLPageStreamDownload alloc]initWithRequest:req path:path completion:completion] autorelease];
    if(download) { [SLActivePageDownloads addObject:download]; [download start]; }
}
+ (UIImage *)thumbnailAtPath:(NSString *)path maxPixelSize:(NSUInteger)maxPixelSize {
    if(!path) return nil;
    NSDictionary *srcOpts=[NSDictionary dictionaryWithObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceShouldCache];
    CGImageSourceRef source=CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path],(CFDictionaryRef)srcOpts);
    if(!source) return nil;
    NSDictionary *opts=[NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue,(id)kCGImageSourceCreateThumbnailFromImageAlways,(id)kCFBooleanTrue,(id)kCGImageSourceCreateThumbnailWithTransform,[NSNumber numberWithUnsignedInteger:MAX((NSUInteger)320,maxPixelSize)],(id)kCGImageSourceThumbnailMaxPixelSize,(id)kCFBooleanTrue,(id)kCGImageSourceShouldCache,nil];
    CGImageRef cg=CGImageSourceCreateThumbnailAtIndex(source,0,(CFDictionaryRef)opts); CFRelease(source);
    if(!cg) return nil; UIImage *image=[UIImage imageWithCGImage:cg]; CGImageRelease(cg); return image;
}
/*
 * iOS 6 has no public region-decoding API for ImageIO. We therefore create a
 * bounded ImageIO thumbnail first, then persist it as small JPEG strips.
 * This bounds the decoded working image on 512 MB-era devices and lets UIKit
 * decode individual strips on demand. maxPixelSize limits the longest edge.
 */
+ (NSArray *)tilePathsAtPath:(NSString *)path maxPixelSize:(NSUInteger)maxPixelSize tilePixelHeight:(NSUInteger)tilePixelHeight {
    if (![path length] || ![[NSFileManager defaultManager] fileExistsAtPath:path]) return nil;
    if (tilePixelHeight < 256) tilePixelHeight = 1024;
    if (maxPixelSize < 1024) maxPixelSize = 4096;

    NSDictionary *sourceOptions = [NSDictionary dictionaryWithObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceShouldCache];
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], (CFDictionaryRef)sourceOptions);
    if (!source) return nil;
    NSDictionary *properties = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    NSUInteger sourceWidth = [[properties objectForKey:(NSString *)kCGImagePropertyPixelWidth] unsignedIntegerValue];
    NSUInteger sourceHeight = [[properties objectForKey:(NSString *)kCGImagePropertyPixelHeight] unsignedIntegerValue];
    [properties release];
    if (!sourceWidth || !sourceHeight) { CFRelease(source); return nil; }

    /* Ordinary pages are better represented by one cached image. */
    if (sourceHeight <= sourceWidth * 2 || sourceHeight <= tilePixelHeight) {
        CFRelease(source);
        return [NSArray array];
    }

    NSString *tileKey = [NSString stringWithFormat:@"%@-%lu-%lu", [self keyForURL:path], (unsigned long)maxPixelSize, (unsigned long)tilePixelHeight];
    NSString *tileDir = [[self cacheDirectory] stringByAppendingPathComponent:[tileKey stringByAppendingString:@".strips"]];
    NSArray *existing = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tileDir error:nil];
    if ([existing count] > 0) {
        NSMutableArray *paths = [NSMutableArray array];
        NSUInteger index;
        for (index = 0; index < [existing count]; index++) {
            NSString *name = [NSString stringWithFormat:@"%05lu.jpg", (unsigned long)index];
            NSString *candidate = [tileDir stringByAppendingPathComponent:name];
            if (![[NSFileManager defaultManager] fileExistsAtPath:candidate]) break;
            [paths addObject:candidate];
        }
        if ([paths count] && [paths count] == [existing count]) {
            for (NSString *cachedTile in paths) [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:cachedTile error:nil];
            CFRelease(source);
            return paths;
        }
        [[NSFileManager defaultManager] removeItemAtPath:tileDir error:nil];
    }

    NSDictionary *thumbOptions = [NSDictionary dictionaryWithObjectsAndKeys:
        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
        [NSNumber numberWithUnsignedInteger:maxPixelSize], (id)kCGImageSourceThumbnailMaxPixelSize,
        (id)kCFBooleanTrue, (id)kCGImageSourceShouldCache, nil];
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (CFDictionaryRef)thumbOptions);
    CFRelease(source);
    if (!thumbnail) return nil;

    size_t width = CGImageGetWidth(thumbnail), height = CGImageGetHeight(thumbnail);
    if (!width || !height) { CGImageRelease(thumbnail); return nil; }
    [[NSFileManager defaultManager] createDirectoryAtPath:tileDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger y;
    BOOL failed = NO;
    for (y = 0; y < height; y += tilePixelHeight) {
        NSAutoreleasePool *tilePool = [[NSAutoreleasePool alloc] init];
        size_t stripHeight = MIN((size_t)tilePixelHeight, height - y);
        CGRect rect = CGRectMake(0, y, width, stripHeight);
        CGImageRef strip = CGImageCreateWithImageInRect(thumbnail, rect);
        if (!strip) { failed = YES; [tilePool drain]; break; }
        UIImage *image = [UIImage imageWithCGImage:strip];
        CGImageRelease(strip);
        NSData *jpeg = UIImageJPEGRepresentation(image, 0.88f);
        if (![jpeg length]) { failed = YES; [tilePool drain]; break; }
        NSString *tilePath = [tileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%05lu.jpg", (unsigned long)[result count]]];
        NSError *writeError = nil;
        if (![jpeg writeToFile:tilePath options:NSDataWritingAtomic error:&writeError]) { failed = YES; [tilePool drain]; break; }
        [result addObject:tilePath];
        [tilePool drain];
    }
    CGImageRelease(thumbnail);
    if (failed || ![result count]) {
        [[NSFileManager defaultManager] removeItemAtPath:tileDir error:nil];
        return nil;
    }
    return result;
}

 + (NSArray *)entries {
    NSMutableArray *entries = [NSMutableArray array];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[self cacheDirectory]];
    NSString *name;
    while ((name = [enumerator nextObject])) {
        if ([name hasSuffix:@".tmp"] || [name hasSuffix:@".download"]) continue;
        NSString *path = [[self cacheDirectory] stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) continue;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        if (attributes) {
            [entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path",
                [attributes objectForKey:NSFileSize] ?: [NSNumber numberWithInt:0], @"size",
                [attributes objectForKey:NSFileModificationDate] ?: [NSDate distantPast], @"date", nil]];
        }
    }
    return entries;
}
+ (unsigned long long)cacheSize { unsigned long long n=0; for(NSDictionary *e in [self entries]) n += [[e objectForKey:@"size"] unsignedLongLongValue]; return n; }
+ (void)trimCacheToBytes:(unsigned long long)limit {
    NSArray *sorted=[[self entries] sortedArrayUsingComparator:^NSComparisonResult(id a,id b){return [[a objectForKey:@"date"] compare:[b objectForKey:@"date"]];}];
    unsigned long long total=[self cacheSize]; for(NSDictionary *e in sorted) { if(total<=limit) break; [[NSFileManager defaultManager] removeItemAtPath:[e objectForKey:@"path"] error:nil]; total -= [[e objectForKey:@"size"] unsignedLongLongValue]; }
}
+ (void)clearCache { for(NSDictionary *e in [self entries]) [[NSFileManager defaultManager] removeItemAtPath:[e objectForKey:@"path"] error:nil]; }
@end
