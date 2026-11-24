#import <UIKit/UIKit.h>
@interface SLAppDelegate : NSObject <UIApplicationDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate> {
 UIWindow *_window; UINavigationController *_nav; UITableView *_table; UISearchBar *_search; NSMutableArray *_items; UILabel *_status; UIBarButtonItem *_favoritesButton; BOOL _showFavorites; NSInteger _searchPage; NSString *_lastQuery; BOOL _hasMore; BOOL _loadingMore;
}
@end
