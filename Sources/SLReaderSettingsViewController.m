#import "SLReaderSettingsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SLTheme.h"
@implementation SLReaderSettingsViewController {
    UISegmentedControl *_mode, *_background; UISlider *_dim; UISwitch *_rtl, *_autoHide, *_awake; UIView *_panel;
}
@synthesize delegate=_delegate;
- (UILabel *)label:(NSString *)text y:(CGFloat)y { UILabel *l=[[[UILabel alloc]initWithFrame:CGRectMake(14,y,250,25)]autorelease]; l.text=text; l.font=[UIFont systemFontOfSize:14]; l.backgroundColor=[UIColor clearColor]; l.textColor=[SLTheme textColor]; return l; }
- (void)addSwitch:(NSString *)title key:(NSString *)key y:(CGFloat)y target:(UISwitch **)target { UILabel *l=[self label:title y:y]; [_panel addSubview:l]; *target=[[UISwitch alloc]initWithFrame:CGRectMake(_panel.bounds.size.width-68,y-4,0,0)]; (*target).on=[[NSUserDefaults standardUserDefaults]boolForKey:key]; (*target).autoresizingMask=UIViewAutoresizingFlexibleLeftMargin; [_panel addSubview:*target]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"Настройки чтения"; self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:0.45];
    _panel=[[UIView alloc]initWithFrame:CGRectMake(10,20,self.view.bounds.size.width-20,430)]; _panel.autoresizingMask=UIViewAutoresizingFlexibleWidth; _panel.backgroundColor=[SLTheme isDark]?[UIColor colorWithWhite:0.13 alpha:1]:[UIColor whiteColor]; _panel.layer.cornerRadius=10; [self.view addSubview:_panel];
    CGFloat y=12; [_panel addSubview:[self label:@"Режим чтения" y:y]]; y+=27;
    _mode=[[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"Лента",@"Страницы",nil]]; _mode.frame=CGRectMake(12,y,_panel.bounds.size.width-24,32); _mode.autoresizingMask=UIViewAutoresizingFlexibleWidth; _mode.selectedSegmentIndex=[[NSUserDefaults standardUserDefaults]integerForKey:@"SLReadMode"]?1:0; [_panel addSubview:_mode]; y+=42;
    [_panel addSubview:[self label:@"Фон страниц" y:y]]; y+=27;
    _background=[[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"Чёрный",@"Серый",@"Белый",nil]]; _background.frame=CGRectMake(12,y,_panel.bounds.size.width-24,32); _background.autoresizingMask=UIViewAutoresizingFlexibleWidth; _background.selectedSegmentIndex=[[NSUserDefaults standardUserDefaults]integerForKey:@"SLPageBackground"]; [_panel addSubview:_background]; y+=42;
    [_panel addSubview:[self label:@"Затемнение страницы" y:y]]; y+=27;
    _dim=[[UISlider alloc]initWithFrame:CGRectMake(12,y,_panel.bounds.size.width-24,30)]; _dim.minimumValue=0; _dim.maximumValue=0.6; _dim.value=[[NSUserDefaults standardUserDefaults]floatForKey:@"SLReaderDim"]; _dim.autoresizingMask=UIViewAutoresizingFlexibleWidth; [_panel addSubview:_dim]; y+=40;
    [self addSwitch:@"Справа налево (RTL)" key:@"SLReadRTL" y:y target:&_rtl]; y+=38;
    [self addSwitch:@"Прятать панели при листании" key:@"SLReaderAutoHide" y:y target:&_autoHide]; y+=38;
    [self addSwitch:@"Не гасить экран" key:@"SLKeepAwake" y:y target:&_awake]; y+=45;
    UIButton *save=[UIButton buttonWithType:UIButtonTypeRoundedRect]; save.frame=CGRectMake(12,y,_panel.bounds.size.width-24,38); save.autoresizingMask=UIViewAutoresizingFlexibleWidth; [save setTitle:@"Готово" forState:UIControlStateNormal]; [save addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside]; [_panel addSubview:save];
    _panel.frame=CGRectMake(10,MAX(10,(self.view.bounds.size.height-y-70)/2),self.view.bounds.size.width-20,y+62);
}
- (void)save { NSUserDefaults *d=[NSUserDefaults standardUserDefaults]; [d setInteger:_mode.selectedSegmentIndex forKey:@"SLReadMode"]; [d setInteger:_background.selectedSegmentIndex forKey:@"SLPageBackground"]; [d setFloat:_dim.value forKey:@"SLReaderDim"]; [d setBool:_rtl.on forKey:@"SLReadRTL"]; [d setBool:_autoHide.on forKey:@"SLReaderAutoHide"]; [d setBool:_awake.on forKey:@"SLKeepAwake"]; [d synchronize]; if([_delegate respondsToSelector:@selector(readerSettingsDidChange)])[_delegate readerSettingsDidChange]; [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)dealloc { [_mode release]; [_background release]; [_dim release]; [_rtl release]; [_autoHide release]; [_awake release]; [_panel release]; [super dealloc]; }
@end
