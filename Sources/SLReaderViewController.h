#import <UIKit/UIKit.h>
@interface SLReaderViewController : UIViewController <UIScrollViewDelegate> { NSString *_slug; NSDictionary *_chapter; NSDictionary *_titleInfo; UIScrollView *_scroll; UIActivityIndicatorView *_spinner; NSMutableArray *_images; NSMutableArray *_pageData; NSOperationQueue *_imageQueue; BOOL _paged; NSInteger _restorePage; }
- (id)initWithSlug:(NSString *)slug chapter:(NSDictionary *)chapter;
- (id)initWithSlug:(NSString *)slug chapter:(NSDictionary *)chapter titleInfo:(NSDictionary *)titleInfo;
@end
