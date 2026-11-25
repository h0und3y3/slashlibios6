#import "SLAppDelegate.h"
#import "SLTitleViewController.h"
#import "SLSettingsViewController.h"
#import "SLStore.h"
#import "SLAPI.h"
#import "SLHomeViewController.h"
#import "SLLibraryViewController.h"
#import "SLTheme.h"
#import "SLImageLoader.h"
#import "SLDiagnostics.h"

@implementation SLAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SLDiagnostics install];
    _items = [[NSMutableArray alloc] init];
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];[SLTheme apply];
    UIViewController *root = [[[UIViewController alloc] init] autorelease]; root.title = @"Поиск"; root.view.backgroundColor = [SLTheme backgroundColor];
    _search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, root.view.bounds.size.width, 44)]; _search.delegate = self; _search.placeholder = @"Поиск манги"; _search.autocorrectionType = UITextAutocorrectionTypeNo; _search.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 78, root.view.bounds.size.width, root.view.bounds.size.height-78) style:UITableViewStylePlain]; _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; _table.backgroundColor=[SLTheme backgroundColor]; _table.dataSource = self; _table.delegate = self;
    _status = [[UILabel alloc] initWithFrame:CGRectMake(8, 44, root.view.bounds.size.width-16, 34)]; _status.autoresizingMask = UIViewAutoresizingFlexibleWidth; _status.text = @"Введите название для поиска"; _status.textAlignment = NSTextAlignmentCenter; _status.font = [UIFont systemFontOfSize:13]; _status.textColor = [UIColor grayColor]; _status.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    [root.view addSubview:_search]; [root.view addSubview:_table]; [root.view addSubview:_status];
    _nav = [[UINavigationController alloc] initWithRootViewController:root];
    UINavigationController *home = [[[UINavigationController alloc] initWithRootViewController:[[[SLHomeViewController alloc] initWithStyle:UITableViewStylePlain] autorelease]] autorelease];
    UINavigationController *favorites = [[[UINavigationController alloc] initWithRootViewController:[[[SLLibraryViewController alloc] initWithKind:SLLibraryFavorites] autorelease]] autorelease];
    UINavigationController *bookmarks = [[[UINavigationController alloc] initWithRootViewController:[[[SLLibraryViewController alloc] initWithKind:SLLibraryBookmarks] autorelease]] autorelease];
    SLSettingsViewController *settingsRoot = [[[SLSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    UINavigationController *settings = [[[UINavigationController alloc] initWithRootViewController:settingsRoot] autorelease];
    UITabBarController *tabs = [[[UITabBarController alloc] init] autorelease];
    home.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Главная" image:nil tag:0] autorelease];
    _nav.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Поиск" image:nil tag:1] autorelease];
    favorites.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Избранное" image:nil tag:2] autorelease];
    bookmarks.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Закладки" image:nil tag:3] autorelease];
    settings.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Аккаунт" image:nil tag:4] autorelease];
    tabs.viewControllers = [NSArray arrayWithObjects:home, _nav, favorites, bookmarks, settings, nil];
    _window.rootViewController = tabs; [_window makeKeyAndVisible]; return YES;
}
- (void)showSettings { SLSettingsViewController *v=[[[SLSettingsViewController alloc]initWithStyle:UITableViewStyleGrouped]autorelease]; [_nav pushViewController:v animated:YES]; }
- (NSArray *)favorites { NSArray *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"SLFavorites"]; return a ? a : [NSArray array]; }
- (void)toggleFavorites { _showFavorites = !_showFavorites; _favoritesButton.title = _showFavorites ? @"Поиск" : @"Избранное"; if (_showFavorites) { [_items setArray:[self favorites]]; _status.text = [NSString stringWithFormat:@"Избранное: %lu", (unsigned long)[_items count]]; } else { [_items removeAllObjects]; _status.text = @"Введите название для поиска"; } [_table reloadData]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; _showFavorites = NO; _favoritesButton.title = @"Избранное"; [self search:searchBar.text]; }
- (void)search:(NSString *)query {if(![query length])return;[_lastQuery release];_lastQuery=[query copy];_searchPage=1;_hasMore=NO;[_items removeAllObjects];[_table reloadData];_status.text=@"Загрузка…";[self loadSearchPage:YES];}
- (void)loadSearchPage:(BOOL)replace {if(_loadingMore||![_lastQuery length])return;_loadingMore=YES;[[SLAPI shared]search:_lastQuery page:_searchPage completion:^(id root,NSError *error){NSArray *rows=[root isKindOfClass:[NSDictionary class]]?[root objectForKey:@"data"]:nil;NSMutableArray *found=[NSMutableArray array];for(NSDictionary *row in rows){if(![row isKindOfClass:[NSDictionary class]])continue;NSString *name=[row objectForKey:@"rus_name"]?:[row objectForKey:@"name"]?:[row objectForKey:@"eng_name"];if(![name isKindOfClass:[NSString class]])continue;NSMutableDictionary *item=[NSMutableDictionary dictionaryWithDictionary:row];[item setObject:name forKey:@"_display"];if(![item objectForKey:@"site"]&&[item objectForKey:@"site_id"])[item setObject:[item objectForKey:@"site_id"] forKey:@"site"];[found addObject:item];}_loadingMore=NO;if(replace)[_items removeAllObjects];NSUInteger before=[_items count];for(NSDictionary *candidate in found){NSString *slug=[candidate objectForKey:@"slug_url"]?:[[candidate objectForKey:@"id"]description];BOOL exists=NO;for(NSDictionary *old in _items){NSString *oldSlug=[old objectForKey:@"slug_url"]?:[[old objectForKey:@"id"]description];if([slug isEqualToString:oldSlug]){exists=YES;break;}}if(!exists)[_items addObject:candidate];}_hasMore=([found count]>=15&&[_items count]>before);[_table reloadData];_status.text=error?[error localizedDescription]:([_items count]?[NSString stringWithFormat:@"Найдено: %lu",(unsigned long)[_items count]]:@"Ничего не найдено");}];}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [_items count]+(_hasMore?1:0); }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { static NSString *identifier = @"TitleCell"; UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier] autorelease]; if(indexPath.row>=[_items count]){cell.textLabel.text=_loadingMore?@"Загрузка…":@"Показать ещё";cell.detailTextLabel.text=@"";cell.textLabel.textAlignment=NSTextAlignmentCenter;return cell;}NSDictionary *item = [_items objectAtIndex:indexPath.row]; cell.textLabel.text = [item objectForKey:@"_display"] ?: [item objectForKey:@"rus_name"]; cell.textLabel.textAlignment=NSTextAlignmentLeft; cell.detailTextLabel.text = [item objectForKey:@"eng_name"];NSDictionary *cover=[item objectForKey:@"cover"];NSString *coverURL=[cover isKindOfClass:[NSDictionary class]]?([cover objectForKey:@"thumbnail"]?:[cover objectForKey:@"default"]):nil;cell.imageView.image=nil;cell.imageView.accessibilityIdentifier=coverURL;if([coverURL length])[[SLImageLoader shared]load:coverURL site:[[item objectForKey:@"site"]integerValue] completion:^(UIImage *image){if([cell.imageView.accessibilityIdentifier isEqualToString:coverURL]){cell.imageView.image=image;[cell setNeedsLayout];}}]; cell.textLabel.textColor=[SLTheme textColor];cell.detailTextLabel.textColor=[SLTheme textColor];cell.backgroundColor=[SLTheme backgroundColor]; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; return cell; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [tableView deselectRowAtIndexPath:indexPath animated:YES];if(indexPath.row>=[_items count]){_searchPage++;[self loadSearchPage:NO];[_table reloadData];return;}NSDictionary *item = [_items objectAtIndex:indexPath.row]; SLTitleViewController *vc = [[[SLTitleViewController alloc] initWithTitle:item] autorelease]; [_nav pushViewController:vc animated:YES]; }
- (void)dealloc { [_items release]; [_search release]; [_table release]; [_nav release]; [_window release]; [_status release]; [_favoritesButton release];[_lastQuery release]; [super dealloc]; }
@end

@implementation SLAppDelegate (SLDiagnosticsLifecycle)
- (void)applicationWillTerminate:(UIApplication *)application { [SLDiagnostics markCleanExit]; }
@end
