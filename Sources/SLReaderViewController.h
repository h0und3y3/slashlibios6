#import <UIKit/UIKit.h>
#import "SLReaderSettingsViewController.h"
@interface SLReaderViewController : UIViewController <UIScrollViewDelegate, SLReaderSettingsDelegate> { NSString *_slug; NSDictionary *_chapter; NSDictionary *_titleInfo; UIScrollView *_scroll; UIActivityIndicatorView *_spinner; NSMutableArray *_images; NSMutableArray *_pageData; BOOL _paged; NSInteger _restorePage; UIView *_dimOverlay; UITapGestureRecognizer *_barsTap; BOOL _imagesRTL; }
- (id)initWithSlug:(NSString *)slug chapter:(NSDictionary *)chapter;
- (id)initWithSlug:(NSString *)slug chapter:(NSDictionary *)chapter titleInfo:(NSDictionary *)titleInfo;
@end
