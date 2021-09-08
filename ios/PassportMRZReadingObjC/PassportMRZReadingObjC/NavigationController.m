
#import "NavigationController.h"

@interface NavigationController ()

@end

@implementation NavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)controllerWillPopHandler {
    
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *vc = self.topViewController;
    if ([vc respondsToSelector:@selector(controllerWillPopHandler)]) {
        [vc performSelector:@selector(controllerWillPopHandler)];
    }
    return [super popViewControllerAnimated:animated];
}

@end
