#import <UIKit/UIKit.h>
@interface SLTitleViewController : UITableViewController { NSDictionary *_titleInfo; NSMutableArray *_chapters; UILabel *_summaryLabel; }
- (id)initWithTitle:(NSDictionary *)info;
@end
