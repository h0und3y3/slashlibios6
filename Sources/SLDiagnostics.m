#import "SLDiagnostics.h"
#import "SLPageStore.h"
#import "SLImageLoader.h"
#import <mach/mach.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import <signal.h>
static NSMutableArray *SLLogLines=nil; static NSLock *SLLogLock=nil;
static char *SLCrashFilePath = NULL;
static void SLSignalHandler(int sig) {
    if (SLCrashFilePath) { int fd=open(SLCrashFilePath,O_WRONLY|O_CREAT|O_TRUNC,0600); if(fd>=0){ const char *msg="Slashlib terminated by fatal POSIX signal. Full stack is unavailable in async signal context.\n"; write(fd,msg,strlen(msg));  close(fd); } }
    signal(sig,SIG_DFL); raise(sig);
}
static NSString *SLDocPath(NSString *n){return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)objectAtIndex:0] stringByAppendingPathComponent:n];}
static void SLExceptionHandler(NSException *e){NSString *s=[NSString stringWithFormat:@"Uncaught exception: %@\nReason: %@\n%@",[e name],[e reason],[[e callStackSymbols] componentsJoinedByString:@"\n"]];[s writeToFile:SLDocPath(@"last-crash.txt") atomically:YES encoding:NSUTF8StringEncoding error:nil];}
@implementation SLMemoryMonitor
+ (unsigned long long)residentBytes { struct mach_task_basic_info i; mach_msg_type_number_t c=MACH_TASK_BASIC_INFO_COUNT; kern_return_t k=task_info(mach_task_self(),MACH_TASK_BASIC_INFO,(task_info_t)&i,&c); return k==KERN_SUCCESS?(unsigned long long)i.resident_size:0; }
+ (unsigned long long)physicalBytes { unsigned long long size=0; size_t len=sizeof(size); sysctlbyname("hw.memsize", &size, &len, NULL, 0); return size; }
+ (void)purgeCaches { [[NSURLCache sharedURLCache] removeAllCachedResponses]; [[SLImageLoader shared] clear]; [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMemoryWarning" object:nil]; }
@end
@implementation SLDiagnostics
+ (void)install { if(!SLLogLines) SLLogLines=[[NSMutableArray alloc]init]; if(!SLLogLock) SLLogLock=[[NSLock alloc]init]; NSSetUncaughtExceptionHandler(&SLExceptionHandler); if(!SLCrashFilePath) SLCrashFilePath=strdup([SLDocPath(@"last-crash.txt") UTF8String]); signal(SIGABRT,SLSignalHandler); signal(SIGSEGV,SLSignalHandler); signal(SIGBUS,SLSignalHandler); signal(SIGILL,SLSignalHandler); signal(SIGFPE,SLSignalHandler); signal(SIGTRAP,SLSignalHandler); signal(SIGPIPE,SIG_IGN); [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil]; NSUserDefaults *d=[NSUserDefaults standardUserDefaults]; if([d objectForKey:@"SLPreviousRunClean"] && ![d boolForKey:@"SLPreviousRunClean"]) [self log:@"Previous run ended without clean-exit marker (crash or forced termination)"]; [d setBool:NO forKey:@"SLPreviousRunClean"]; [d synchronize]; [self log:@"Diagnostics initialized"]; }
+ (void)memoryWarning:(NSNotification *)n { [self log:@"iOS memory warning; purging transient caches"]; [SLMemoryMonitor purgeCaches]; }
+ (void)log:(NSString *)m { if(![m isKindOfClass:[NSString class]]) return; if(!SLLogLock) SLLogLock=[[NSLock alloc]init]; if(!SLLogLines) SLLogLines=[[NSMutableArray alloc]init]; [SLLogLock lock]; NSString *line=[NSString stringWithFormat:@"%@ | %@ | RSS %.1f MB",[NSDate date],m,(double)[SLMemoryMonitor residentBytes]/1048576.0]; [SLLogLines addObject:line]; while([SLLogLines count]>120)[SLLogLines removeObjectAtIndex:0]; NSString *body=[[SLLogLines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"]; [body writeToFile:SLDocPath(@"diagnostics.log") atomically:YES encoding:NSUTF8StringEncoding error:nil]; [SLLogLock unlock]; }
+ (NSArray *)recentEvents { [SLLogLock lock]; NSArray *a=[[SLLogLines copy] autorelease]; [SLLogLock unlock]; return a?:[NSArray array]; }
+ (NSString *)report { struct utsname u; uname(&u); NSString *model=[NSString stringWithUTF8String:u.machine]; NSString *v=[[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleShortVersionString"]?:@"?"; return [NSString stringWithFormat:@"Slashlib %@\nDevice: %@\niOS: %@\nPhysical RAM: %.0f MB\nResident: %.1f MB\nPage cache: %.1f MB\n\nEvents:\n%@",v,model,[[UIDevice currentDevice]systemVersion],(double)[SLMemoryMonitor physicalBytes]/1048576.0,(double)[SLMemoryMonitor residentBytes]/1048576.0,(double)[SLPageStore cacheSize]/1048576.0,[[self recentEvents]componentsJoinedByString:@"\n"]]; }
+ (NSString *)lastCrashReport { NSString *s=[NSString stringWithContentsOfFile:SLDocPath(@"last-crash.txt") encoding:NSUTF8StringEncoding error:nil]; return s?:@"Сбоев не записано."; }
+ (void)clear { [SLLogLock lock]; [SLLogLines removeAllObjects]; [SLLogLock unlock]; [[NSFileManager defaultManager]removeItemAtPath:SLDocPath(@"diagnostics.log") error:nil]; [[NSFileManager defaultManager]removeItemAtPath:SLDocPath(@"last-crash.txt") error:nil]; }
+ (void)markCleanExit { NSUserDefaults *d=[NSUserDefaults standardUserDefaults]; [d setBool:YES forKey:@"SLPreviousRunClean"]; [d synchronize]; }
@end
@implementation SLDiagnosticsViewController { UITextView *_textView; }
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"Диагностика"; self.view.backgroundColor=[UIColor whiteColor]; _textView=[[UITextView alloc]initWithFrame:self.view.bounds]; _textView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; _textView.editable=NO; _textView.font=[UIFont fontWithName:@"Menlo" size:11]?:[UIFont systemFontOfSize:12]; [self.view addSubview:_textView]; self.navigationItem.rightBarButtonItems=[NSArray arrayWithObjects:[[[UIBarButtonItem alloc]initWithTitle:@"Поделиться" style:UIBarButtonItemStylePlain target:self action:@selector(share)]autorelease],[[[UIBarButtonItem alloc]initWithTitle:@"Очистить" style:UIBarButtonItemStylePlain target:self action:@selector(clear)]autorelease],nil]; [self reload]; }
- (void)reload { _textView.text=[NSString stringWithFormat:@"%@\n\nПоследний сбой:\n%@",[SLDiagnostics report],[SLDiagnostics lastCrashReport]]; }
- (void)share { [UIPasteboard generalPasteboard].string=_textView.text?:@""; UIAlertView *a=[[[UIAlertView alloc]initWithTitle:@"Диагностика скопирована" message:@"Текст отчёта скопирован в буфер обмена." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease]; [a show]; }
- (void)clear { [SLDiagnostics clear]; [self reload]; }
- (void)dealloc { [_textView release]; [super dealloc]; }
@end
