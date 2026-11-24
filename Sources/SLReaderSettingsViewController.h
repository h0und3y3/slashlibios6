#import <UIKit/UIKit.h>
@protocol SLReaderSettingsDelegate <NSObject>
- (void)readerSettingsDidChange;
@end
@interface SLReaderSettingsViewController : UIViewController {
    id<SLReaderSettingsDelegate> _delegate;
}
@property(nonatomic, assign) id<SLReaderSettingsDelegate> delegate;
@end
