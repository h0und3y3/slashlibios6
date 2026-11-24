#import "SLReaderViewController.h"
#import "SLStore.h"
#import "SLAPI.h"
#import "SLDownloadManager.h"
#import "SLPageStore.h"
#import "SLReaderSettingsViewController.h"
#import "SLDiagnostics.h"
#import "SLTiledPageView.h"
@implementation SLReaderViewController
- (id)initWithSlug:(NSString *)slug chapter:(NSDictionary *)chapter {return [self initWithSlug:slug chapter:chapter titleInfo:nil];}
- (id)initWithSlug:(NSString *)slug chapter:(NSDictionary *)chapter titleInfo:(NSDictionary *)titleInfo { if((self=[super init])){_slug=[slug copy];_chapter=[chapter copy];_titleInfo=[titleInfo copy];_images=[[NSMutableArray alloc]init];_pageData=[[NSMutableArray alloc]init];_paged=([[NSUserDefaults standardUserDefaults]integerForKey:@"SLReadMode"]!=0);_imagesRTL=NO;self.title=[NSString stringWithFormat:@"Глава %@",[chapter objectForKey:@"number"]?:@"?"];}return self; }
- (void)viewWillAppear:(BOOL)animated{[super viewWillAppear:animated];[UIApplication sharedApplication].idleTimerDisabled=[[NSUserDefaults standardUserDefaults]boolForKey:@"SLKeepAwake"]; }
- (void)viewWillDisappear:(BOOL)animated{[super viewWillDisappear:animated];[UIApplication sharedApplication].idleTimerDisabled=NO;}
- (void)viewDidLoad { [super viewDidLoad]; NSInteger bg=[[NSUserDefaults standardUserDefaults]integerForKey:@"SLPageBackground"];UIColor *pageBG=bg==1?[UIColor colorWithWhite:0.35 alpha:1]:(bg==2?[UIColor whiteColor]:[UIColor blackColor]);self.view.backgroundColor=pageBG;_scroll=[[UIScrollView alloc]initWithFrame:self.view.bounds];_scroll.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;_scroll.delegate=self;_scroll.backgroundColor=pageBG;_scroll.pagingEnabled=_paged;_scroll.showsHorizontalScrollIndicator=NO;_scroll.showsVerticalScrollIndicator=NO;[self.view addSubview:_scroll];_dimOverlay=[[UIView alloc]initWithFrame:self.view.bounds];_dimOverlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;_dimOverlay.backgroundColor=[UIColor blackColor];_dimOverlay.alpha=[[NSUserDefaults standardUserDefaults]floatForKey:@"SLReaderDim"];_dimOverlay.userInteractionEnabled=NO;[self.view addSubview:_dimOverlay];_barsTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleBars)];[self.view addGestureRecognizer:_barsTap];[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleReaderMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];_spinner=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];_spinner.center=CGPointMake(self.view.bounds.size.width/2,self.view.bounds.size.height/2);_spinner.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;[_spinner startAnimating];[self.view addSubview:_spinner];UIBarButtonItem *mode=[[[UIBarButtonItem alloc]initWithTitle:_paged?@"Лента":@"Страницы" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMode)]autorelease];UIBarButtonItem *bookmark=[[[UIBarButtonItem alloc]initWithTitle:[SLStore isBookmarked:_slug chapterID:[_chapter objectForKey:@"id"]]?@"★":@"☆" style:UIBarButtonItemStylePlain target:self action:@selector(toggleBookmark)]autorelease];UIBarButtonItem *settings=[[[UIBarButtonItem alloc]initWithTitle:@"Aa" style:UIBarButtonItemStylePlain target:self action:@selector(openReaderSettings)]autorelease];self.navigationItem.rightBarButtonItems=[NSArray arrayWithObjects:settings,mode,bookmark,nil];[self loadPages]; }
- (void)openReaderSettings { SLReaderSettingsViewController *v=[[[SLReaderSettingsViewController alloc]init]autorelease];v.delegate=self;v.modalPresentationStyle=UIModalPresentationCurrentContext;v.modalTransitionStyle=UIModalTransitionStyleCrossDissolve;self.definesPresentationContext=YES;[self presentViewController:v animated:YES completion:nil]; }
- (void)readerSettingsDidChange { NSUInteger current=_paged?(NSUInteger)(_scroll.contentOffset.x/MAX(_scroll.bounds.size.width,1)):[self visibleVerticalPage];_dimOverlay.alpha=[[NSUserDefaults standardUserDefaults]floatForKey:@"SLReaderDim"];NSInteger bg=[[NSUserDefaults standardUserDefaults]integerForKey:@"SLPageBackground"];UIColor *c=bg==1?[UIColor colorWithWhite:0.35 alpha:1]:(bg==2?[UIColor whiteColor]:[UIColor blackColor]);self.view.backgroundColor=c;_scroll.backgroundColor=c;BOOL newPaged=[[NSUserDefaults standardUserDefaults]integerForKey:@"SLReadMode"]!=0;BOOL shouldRTL=newPaged&&[[NSUserDefaults standardUserDefaults]boolForKey:@"SLReadRTL"];if(shouldRTL!=_imagesRTL){NSArray *rev=[[_images reverseObjectEnumerator]allObjects];[_images setArray:rev];if([_images count])current=(NSUInteger)[_images count]-1-MIN(current,(NSUInteger)[_images count]-1);_imagesRTL=shouldRTL;}_paged=newPaged;_scroll.pagingEnabled=_paged;if([self.navigationItem.rightBarButtonItems count]>1)((UIBarButtonItem *)[self.navigationItem.rightBarButtonItems objectAtIndex:1]).title=_paged?@"Лента":@"Страницы";[UIApplication sharedApplication].idleTimerDisabled=[[NSUserDefaults standardUserDefaults]boolForKey:@"SLKeepAwake"];[self layoutPages];if(_paged)_scroll.contentOffset=CGPointMake(current*_scroll.bounds.size.width,0);else{CGFloat y=0;for(NSUInteger i=0;i<current&&i<[_images count];i++)y+=((UIView *)[_images objectAtIndex:i]).frame.size.height;_scroll.contentOffset=CGPointMake(0,y);} }
- (void)toggleBars { if(![[NSUserDefaults standardUserDefaults]boolForKey:@"SLReaderAutoHide"])return; BOOL hidden=self.navigationController.navigationBarHidden; [self.navigationController setNavigationBarHidden:!hidden animated:YES]; }
- (void)hideBarsIfNeeded { if([[NSUserDefaults standardUserDefaults]boolForKey:@"SLReaderAutoHide"] && self.navigationController && !self.navigationController.navigationBarHidden) [self.navigationController setNavigationBarHidden:YES animated:YES]; }
- (void)toggleMode{NSUInteger current=_paged?(NSUInteger)(_scroll.contentOffset.x/MAX(_scroll.bounds.size.width,1)):[self visibleVerticalPage];BOOL newPaged=!_paged;BOOL shouldRTL=newPaged&&[[NSUserDefaults standardUserDefaults]boolForKey:@"SLReadRTL"];if(shouldRTL!=_imagesRTL){NSArray *rev=[[_images reverseObjectEnumerator]allObjects];[_images setArray:rev];if([_images count])current=(NSUInteger)[_images count]-1-MIN(current,(NSUInteger)[_images count]-1);_imagesRTL=shouldRTL;}_paged=newPaged;[[NSUserDefaults standardUserDefaults]setInteger:_paged?1:0 forKey:@"SLReadMode"];if([self.navigationItem.rightBarButtonItems count]>1)((UIBarButtonItem *)[self.navigationItem.rightBarButtonItems objectAtIndex:1]).title=_paged?@"Лента":@"Страницы";_scroll.pagingEnabled=_paged;[self layoutPages];if(_paged)_scroll.contentOffset=CGPointMake(current*_scroll.bounds.size.width,0);else{CGFloat y=0;for(NSUInteger i=0;i<current&&i<[_images count];i++)y+=((UIView *)[_images objectAtIndex:i]).frame.size.height;_scroll.contentOffset=CGPointMake(0,y);}}
- (void)loadPages {
    _restorePage=[[_chapter objectForKey:@"_startPage"]integerValue];
    if(![_chapter objectForKey:@"_startPage"]){for(NSDictionary *recent in [SLStore array:@"SLHistory"]){NSString *recentSlug=[recent objectForKey:@"slug_url"]?:[recent objectForKey:@"slug"];if([recentSlug isEqualToString:_slug]){NSDictionary *last=[recent objectForKey:@"_lastChapter"];if([[[last objectForKey:@"id"]description]isEqualToString:[[_chapter objectForKey:@"id"]description]])_restorePage=[[recent objectForKey:@"_lastPage"]integerValue];break;}}}
    NSDictionary *offline=[[SLDownloadManager shared]downloadedChapterForSlug:_slug chapterID:[_chapter objectForKey:@"id"]?:@"0"];
    if(offline){NSArray *names=[offline objectForKey:@"pages"];NSString *dir=[offline objectForKey:@"path"];for(NSString *name in names){NSString *path=[dir stringByAppendingPathComponent:name];if([[NSFileManager defaultManager]fileExistsAtPath:path])[_pageData addObject:[NSDictionary dictionaryWithObject:path forKey:@"localPath"]];}if([_pageData count]){[self showPageData];return;}}
    [[SLAPI shared]pages:_slug chapter:_chapter site:[[_chapter objectForKey:@"site"]integerValue] completion:^(id root,NSError *err){NSArray *pages=[[root objectForKey:@"data"]objectForKey:@"pages"];if(err||![pages isKindOfClass:[NSArray class]]||![pages count]){dispatch_async(dispatch_get_main_queue(),^{[_spinner stopAnimating];[self showError:err?[err localizedDescription]:@"Страницы не найдены"];});return;}[_pageData addObjectsFromArray:pages];[self showPageData];}];
}
- (void)showPageData {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_spinner stopAnimating];
        UIColor *pageBG=_scroll.backgroundColor;
        NSArray *displayData=_pageData;
        if(_paged && [[NSUserDefaults standardUserDefaults] boolForKey:@"SLReadRTL"]) displayData=[[_pageData reverseObjectEnumerator] allObjects];
        _imagesRTL=(_paged && [[NSUserDefaults standardUserDefaults] boolForKey:@"SLReadRTL"]);
        CGFloat w=self.view.bounds.size.width, y=0; NSUInteger i=0;
        for(NSDictionary *page in displayData) {
            SLTiledPageView *iv=[[[SLTiledPageView alloc] initWithFrame:CGRectMake(_paged?i*w:0,_paged?0:y,w,_paged?self.view.bounds.size.height:w*1.45)] autorelease];
            iv.backgroundColor=pageBG; iv.tag=(NSInteger)i;
            NSString *local=[page objectForKey:@"localPath"];
            if([local isKindOfClass:[NSString class]]) iv.accessibilityIdentifier=local;
            else {
                NSString *url=[page objectForKey:@"url"];
                if([url isKindOfClass:[NSString class]]) {
                    if([url rangeOfString:@"http"].location!=0) url=[@"https:" stringByAppendingString:url];
                    iv.accessibilityHint=url;
                }
            }
            [_scroll addSubview:iv]; [_images addObject:iv];
            if(!_paged) y+=iv.frame.size.height;
            i++;
        }
        _scroll.contentSize=_paged?CGSizeMake(w*[_images count],self.view.bounds.size.height):CGSizeMake(w,y);
        if(_restorePage>=(NSInteger)[_images count]) _restorePage=(NSInteger)[_images count]-1;
        if(_restorePage<0) _restorePage=0;
        if(_paged) _scroll.contentOffset=CGPointMake(w*_restorePage,0);
        else _scroll.contentOffset=CGPointMake(0,_restorePage*w*1.45);
        if([_pageData count]) { [SLStore markRead:_slug chapter:[_chapter objectForKey:@"id"]?:@"0"]; [self saveProgress:(NSUInteger)_restorePage]; }
        if(![_images count]) [self showError:@"Не удалось открыть страницы"];
        [self loadVisibleImages];
    });
}
- (void)renderPageAtIndex:(NSUInteger)index path:(NSString *)path {
    if (index >= [_images count] || ![path length]) return;
    SLTiledPageView *pageView = [_images objectAtIndex:index];
    if ([pageView.accessibilityHint isEqualToString:@"__SL_RENDERING__"]) return;
    pageView.accessibilityHint = @"__SL_RENDERING__";
    BOOL shouldCreateTiles = !_paged;
    NSUInteger maxPixels = [[NSUserDefaults standardUserDefaults] boolForKey:@"SLEnergySaving"] ? 3072 : 4096;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSArray *tiles = shouldCreateTiles ? [[SLPageStore tilePathsAtPath:path maxPixelSize:maxPixels tilePixelHeight:768] retain] : nil;
        UIImage *singleImage = nil;
        if (![tiles count] || !shouldCreateTiles) singleImage = [[SLPageStore thumbnailAtPath:path maxPixelSize:maxPixels] retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger liveIndex = [_images indexOfObjectIdenticalTo:pageView];
            if (liveIndex != NSNotFound && [pageView.accessibilityIdentifier isEqualToString:path]) {
                BOOL retryForModeChange = NO;
                pageView.accessibilityHint = nil;
                if (_paged) {
                    if (singleImage) [pageView setSingleImage:singleImage sourcePath:path];
                    else { retryForModeChange = YES; [self renderPageAtIndex:liveIndex path:path]; }
                } else if ([tiles count] > 1) {
                    [pageView setTilePaths:tiles pageWidth:self.view.bounds.size.width sourcePath:path];
                } else if (singleImage) {
                    [pageView setSingleImage:singleImage sourcePath:path];
                }
                if (!_paged && [pageView hasRenderedContent]) {
                    NSUInteger anchorIndex = [self visibleVerticalPage];
                    CGFloat oldOffset = _scroll.contentOffset.y;
                    CGFloat oldAnchorOrigin = anchorIndex < [_images count] ? ((UIView *)[_images objectAtIndex:anchorIndex]).frame.origin.y : 0;
                    CGRect frame = pageView.frame;
                    frame.size.height = [pageView contentHeightForWidth:self.view.bounds.size.width];
                    pageView.frame = frame;
                    [self recalculateVerticalContentPreservingPage:anchorIndex oldOffset:oldOffset oldOrigin:oldAnchorOrigin];
                }
                if (!retryForModeChange && ![pageView hasRenderedContent]) [SLDiagnostics log:[NSString stringWithFormat:@"Could not decode page image: %@", path]];
            }
            [tiles release];
            [singleImage release];
        });
        [pool drain];
    });
}
- (void)loadImageAtIndex:(NSUInteger)index {
    if (index >= [_images count]) return;
    SLTiledPageView *pageView = [_images objectAtIndex:index];
    if ([pageView hasRenderedContent]) return;
    NSString *local = pageView.accessibilityIdentifier;
    if ([local length] && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
        [self renderPageAtIndex:index path:local];
        return;
    }
    NSString *url = pageView.accessibilityHint;
    if (![url length]) return;
    pageView.accessibilityHint = nil;
    [SLPageStore fetchURL:url completion:^(NSString *path, NSError *error) {
        if (!path) {
            [SLDiagnostics log:[NSString stringWithFormat:@"Page download failed: %@", [error localizedDescription]]];
            pageView.accessibilityHint = url;
            return;
        }
        pageView.accessibilityIdentifier = path;
        [self renderPageAtIndex:index path:path];
        [SLPageStore trimCacheToBytes:96ULL * 1024ULL * 1024ULL];
    }];
}
- (void)loadVisibleImages {
    if(![_images count]) return;
    NSUInteger current=_paged?(NSUInteger)(_scroll.contentOffset.x/MAX(_scroll.bounds.size.width,1)):[self visibleVerticalPage];
    [self loadImageAtIndex:current];
    if(current>0) [self loadImageAtIndex:current-1];
    [self loadImageAtIndex:current+1];
}
- (void)handleReaderMemoryWarning:(NSNotification *)notification {
    NSUInteger current=_paged?(NSUInteger)(_scroll.contentOffset.x/MAX(_scroll.bounds.size.width,1)):[self visibleVerticalPage];
    for(NSUInteger i=0;i<[_images count];i++) if(i!=current) [(SLTiledPageView *)[_images objectAtIndex:i] purgeDecodedImages];
    [SLDiagnostics log:@"Reader dropped off-screen decoded pages after memory warning"];
}
- (void)recalculateVerticalContentPreservingPage:(NSUInteger)page oldOffset:(CGFloat)oldOffset oldOrigin:(CGFloat)oldOrigin {
    CGFloat y = 0, newAnchorOrigin = 0;
    NSUInteger index = 0;
    for (UIView *view in _images) {
        CGRect frame = view.frame;
        frame.origin.y = y;
        view.frame = frame;
        if (index == page) newAnchorOrigin = y;
        y += frame.size.height;
        index++;
    }
    _scroll.contentSize = CGSizeMake(self.view.bounds.size.width, y);
    CGFloat relativeOffset = oldOffset - oldOrigin;
    CGFloat newOffset = MAX(0, newAnchorOrigin + relativeOffset);
    CGFloat maxOffset = MAX(0, y - _scroll.bounds.size.height);
    _scroll.contentOffset = CGPointMake(0, MIN(newOffset, maxOffset));
}
- (void)layoutPages{CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;NSUInteger i=0;CGFloat y=0;for(SLTiledPageView *iv in _images){iv.backgroundColor=_scroll.backgroundColor;CGFloat ih=[iv contentHeightForWidth:w];iv.frame=CGRectMake(_paged?i*w:0,_paged?0:y,w,_paged?h:ih);if(!_paged)y+=ih;i++;} _scroll.contentSize=_paged?CGSizeMake(w*[_images count],h):CGSizeMake(w,y);}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{NSUInteger page=_paged?(NSUInteger)(scrollView.contentOffset.x/MAX(scrollView.bounds.size.width,1)):[self visibleVerticalPage];[self saveProgress:page];[self loadVisibleImages];[self hideBarsIfNeeded];}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{if(!decelerate){NSUInteger page=_paged?(NSUInteger)(scrollView.contentOffset.x/MAX(scrollView.bounds.size.width,1)):[self visibleVerticalPage];[self saveProgress:page];[self loadVisibleImages];[self hideBarsIfNeeded];}}
- (NSUInteger)visibleVerticalPage{CGFloat y=_scroll.contentOffset.y;NSUInteger idx=0;for(UIView *iv in _images){if(CGRectGetMaxY(iv.frame)>y){return idx;}idx++;}return idx?idx-1:0;}
- (void)saveProgress:(NSUInteger)page {if(page>=[_pageData count])page=[_pageData count]?[_pageData count]-1:0;NSDictionary *title=_titleInfo?:[NSDictionary dictionaryWithObjectsAndKeys:_slug,@"slug_url",_slug,@"slug",nil];[SLStore updateRecent:title chapter:_chapter page:page pageCount:[_pageData count]];}
- (void)toggleBookmark {id chapterID=[_chapter objectForKey:@"id"]?:@"0";if([SLStore isBookmarked:_slug chapterID:chapterID])[SLStore removeBookmark:_slug chapterID:chapterID];else{NSMutableArray *branchIDs=[NSMutableArray array];for(NSDictionary *branch in [_chapter objectForKey:@"branches"]?:[NSArray array]){id bid=[branch objectForKey:@"branch_id"];if(bid)[branchIDs addObject:bid];}if(![branchIDs count]&&[_chapter objectForKey:@"branchIds"])[branchIDs addObjectsFromArray:[_chapter objectForKey:@"branchIds"]];NSMutableDictionary *b=[NSMutableDictionary dictionaryWithObjectsAndKeys:_slug,@"slug",chapterID,@"chapterId",[_chapter objectForKey:@"volume"]?:@"0",@"volume",[_chapter objectForKey:@"number"]?:@"0",@"number",[_chapter objectForKey:@"name"]?:@"",@"chapterName",branchIDs,@"branchIds",[NSNumber numberWithUnsignedInteger:_paged?(NSUInteger)(_scroll.contentOffset.x/MAX(_scroll.bounds.size.width,1)):[self visibleVerticalPage]],@"page",[NSNumber numberWithUnsignedInteger:[_pageData count]],@"pageCount",[NSNumber numberWithDouble:[[NSDate date]timeIntervalSince1970]],@"date",[_chapter objectForKey:@"site"]?:@2,@"site",nil];if(_titleInfo)[b setObject:_titleInfo forKey:@"titleInfo"];[SLStore saveBookmark:b];}((UIBarButtonItem *)[self.navigationItem.rightBarButtonItems lastObject]).title=[SLStore isBookmarked:_slug chapterID:chapterID]?@"★":@"☆";}
- (void)showError:(NSString *)message{UILabel *l=[[[UILabel alloc]initWithFrame:self.view.bounds]autorelease];l.text=message;l.textColor=[UIColor whiteColor];l.textAlignment=UITextAlignmentCenter;l.numberOfLines=3;l.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.view addSubview:l];}
- (void)dealloc{[_slug release];[_chapter release];[_titleInfo release];[_scroll release];[_spinner release];[_images release];[_pageData release];[_dimOverlay release];[_barsTap release];[[NSNotificationCenter defaultCenter]removeObserver:self];[super dealloc];}
@end
