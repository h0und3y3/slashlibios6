#import <UIKit/UIKit.h>

/* A page container that displays a long image as independently decoded strips. */
@interface SLTiledPageView : UIView {
    UIImageView *_singleImageView;
    NSMutableArray *_tileImageViews;
    NSArray *_tilePaths;
    CGFloat _pageHeight;
}
- (void)setSingleImage:(UIImage *)image sourcePath:(NSString *)path;
- (void)setTilePaths:(NSArray *)paths pageWidth:(CGFloat)pageWidth sourcePath:(NSString *)sourcePath;
- (CGFloat)contentHeightForWidth:(CGFloat)width;
- (BOOL)hasRenderedContent;
- (void)purgeDecodedImages;
- (void)reloadDecodedImages;
@end
