#import <UIKit/UIKit.h>
typedef enum { SLLibraryFavorites=0, SLLibraryBookmarks=1, SLLibraryHistory=2, SLLibraryDownloads=3 } SLLibraryKind;
@interface SLLibraryViewController : UITableViewController { SLLibraryKind _kind; NSMutableArray *_rows; }
- (id)initWithKind:(SLLibraryKind)kind;
@end
