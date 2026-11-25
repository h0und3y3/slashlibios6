#import <UIKit/UIKit.h>
#import "SLAppDelegate.h"
int main(int argc, char *argv[]) { NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; int ret = UIApplicationMain(argc, argv, nil, NSStringFromClass([SLAppDelegate class])); [pool drain]; return ret; }
