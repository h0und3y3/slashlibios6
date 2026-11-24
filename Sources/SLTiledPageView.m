#import "SLTiledPageView.h"

@implementation SLTiledPageView
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        _singleImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _singleImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _singleImageView.contentMode = UIViewContentModeScaleAspectFit;
        _singleImageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_singleImageView];
        _tileImageViews = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)removeTiles {
    for (UIImageView *view in _tileImageViews) [view removeFromSuperview];
    [_tileImageViews removeAllObjects];
}
- (void)setSingleImage:(UIImage *)image sourcePath:(NSString *)path {
    [self removeTiles];
    [_tilePaths release]; _tilePaths = nil;
    _singleImageView.hidden = NO;
    _singleImageView.image = image;
    _singleImageView.accessibilityIdentifier = path;
    self.accessibilityIdentifier = path;
    if (image && image.size.width > 0) _pageHeight = self.bounds.size.width * image.size.height / image.size.width;
    else _pageHeight = self.bounds.size.width * 1.45f;
}
- (void)setTilePaths:(NSArray *)paths pageWidth:(CGFloat)pageWidth sourcePath:(NSString *)sourcePath {
    [self removeTiles];
    _singleImageView.image = nil;
    _singleImageView.hidden = YES;
    [_tilePaths release]; _tilePaths = [paths copy];
    self.accessibilityIdentifier = sourcePath;
    CGFloat y = 0;
    NSUInteger i;
    for (i = 0; i < [_tilePaths count]; i++) {
        NSString *path = [_tilePaths objectAtIndex:i];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (!image || image.size.width <= 0) continue;
        CGFloat h = pageWidth * image.size.height / image.size.width;
        UIImageView *tile = [[[UIImageView alloc] initWithFrame:CGRectMake(0, y, pageWidth, h)] autorelease];
        tile.contentMode = UIViewContentModeScaleToFill;
        tile.image = image;
        tile.accessibilityIdentifier = path;
        tile.backgroundColor = [UIColor clearColor];
        [self addSubview:tile];
        [_tileImageViews addObject:tile];
        y += h;
    }
    _pageHeight = y;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, pageWidth, MAX(y, pageWidth));
}
- (CGFloat)contentHeightForWidth:(CGFloat)width {
    if ([_tilePaths count] && _pageHeight > 0) return _pageHeight * (width / MAX(self.bounds.size.width, 1));
    if (_singleImageView.image && _singleImageView.image.size.width > 0) return width * _singleImageView.image.size.height / _singleImageView.image.size.width;
    if (_pageHeight > 0) return width * (_pageHeight / MAX(self.bounds.size.width, 1));
    return width * 1.45f;
}
- (BOOL)hasRenderedContent {
    if (_singleImageView.image) return YES;
    for (UIImageView *tile in _tileImageViews) if (tile.image) return YES;
    return NO;
}
- (void)purgeDecodedImages {
    _singleImageView.image = nil;
    for (UIImageView *tile in _tileImageViews) tile.image = nil;
}
- (void)reloadDecodedImages {
    if ([_tilePaths count]) {
        NSUInteger i = 0;
        for (UIImageView *tile in _tileImageViews) {
            if (i < [_tilePaths count]) tile.image = [UIImage imageWithContentsOfFile:[_tilePaths objectAtIndex:i]];
            i++;
        }
    } else if (self.accessibilityIdentifier) {
        _singleImageView.image = [UIImage imageWithContentsOfFile:self.accessibilityIdentifier];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _singleImageView.frame = self.bounds;
    if ([_tileImageViews count]) {
        CGFloat y = 0;
        for (UIImageView *tile in _tileImageViews) {
            CGFloat oldWidth = MAX(tile.frame.size.width, 1);
            CGFloat h = tile.frame.size.height * (self.bounds.size.width / oldWidth);
            tile.frame = CGRectMake(0, y, self.bounds.size.width, h);
            y += h;
        }
        _pageHeight = y;
    }
}
- (void)dealloc {
    [_singleImageView release]; [_tileImageViews release]; [_tilePaths release];
    [super dealloc];
}
@end
