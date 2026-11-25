#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface SLMemoryMonitor : NSObject
+ (unsigned long long)residentBytes;
+ (unsigned long long)physicalBytes;
+ (void)purgeCaches;
@end
@interface SLDiagnostics : NSObject
+ (void)install;
+ (void)log:(NSString *)message;
+ (NSArray *)recentEvents;
+ (NSString *)report;
+ (NSString *)lastCrashReport;
+ (void)clear;
+ (void)markCleanExit;
@end
@interface SLDiagnosticsViewController : UIViewController
@end
